import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/market/analysis_instruments.dart';
import '../notifications/notifications_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../models/market_models.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/progression_provider.dart';
import '../../services/adaptive_plan_share.dart';
import '../../services/export_watermark.dart';
import '../../core/analysis/adaptive_position_plan.dart';
import '../../widgets/adaptive_plan_common.dart';
import '../../widgets/adaptive_plan_result.dart';
import '../../services/native_push_service.dart';
import '../../widgets/adaptive_position_plan_card.dart';
import '../../widgets/analysis_levels_chart.dart';
import '../../widgets/analysis_note_card.dart';
import '../../widgets/analysis_quota_dialog.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/product_state_view.dart';
import '../../widgets/risk/risk_tools_section.dart';
import '../journal/trade_journal_screen.dart';
import '../mindset/mindset_screen.dart';

const _analysisTimeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1D', '1W'];
const _reasoningClipboard = MethodChannel('id.tradepilot.app/clipboard');

const _tradingViewSymbols = <String, String>{
  'XAU/USD': 'OANDA:XAUUSD',
  'XAG/USD': 'OANDA:XAGUSD',
  'BRENT': 'BLACKBULL:BRENT',
  'HSI': 'VANTAGE:HK50',
  'NIKKEI': 'SPREADEX:NIKKEI',
  'DJIA': 'TVC:DJI',
  'NASDAQ': 'TVC:NDX',
  'DXY': 'TVC:DXY',
  'USD/IDR': 'FX_IDC:USDIDR',
  'BTC/USD': 'BINANCE:BTCUSDT',
  'ETH/USD': 'BINANCE:ETHUSDT',
  'SOL/USD': 'BINANCE:SOLUSDT',
  'BNB/USD': 'BINANCE:BNBUSDT',
  'XRP/USD': 'BINANCE:XRPUSDT',
};

String _tradingViewSymbol(String instrument) {
  final normalized = instrument.trim().toUpperCase();
  return _tradingViewSymbols[normalized] ??
      'OANDA:${normalized.replaceAll(RegExp(r'[\s/]+'), '')}';
}

CreateAnalysisBodyTimeframeEnum _timeframeEnum(String value) => switch (value) {
  '1m' => CreateAnalysisBodyTimeframeEnum.n1m,
  '5m' => CreateAnalysisBodyTimeframeEnum.n5m,
  '15m' => CreateAnalysisBodyTimeframeEnum.n15m,
  '30m' => CreateAnalysisBodyTimeframeEnum.n30m,
  '4h' => CreateAnalysisBodyTimeframeEnum.n4h,
  '1D' => CreateAnalysisBodyTimeframeEnum.n1d,
  '1W' => CreateAnalysisBodyTimeframeEnum.n1w,
  _ => CreateAnalysisBodyTimeframeEnum.n1h,
};

class AnalysisDetailScreen extends StatefulWidget {
  const AnalysisDetailScreen({
    super.key,
    required this.analysisId,
    this.preloaded,
    this.embedded = false,
    this.onAnalysisCreated,
    this.onNewAnalysis,
    this.onCreatePriceAlert,
  });

  final int analysisId;
  final Analysis? preloaded;
  final bool embedded;
  final ValueChanged<Analysis>? onAnalysisCreated;
  final VoidCallback? onNewAnalysis;
  final VoidCallback? onCreatePriceAlert;

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  Analysis? _analysis;

  List<MarketCandle> _candles = const [];
  BeginnerTechnicalSnapshot? _technical;
  RefreshFundamentalsResponse? _fundamentalRefresh;

  bool _loading = true;
  bool _submittingFeedback = false;
  bool _detailRequestInFlight = false;
  bool _marketRequestInFlight = false;
  bool _marketLoading = false;
  bool _reanalyzing = false;
  bool _refreshingFundamentals = false;
  bool _alertStatusLoading = true;
  bool _alertBusy = false;
  bool _journalLoading = true;
  String? _selectedTimeframe;

  String? _marketError;
  String? _alertError;
  String? _journalError;
  AlertStatus? _alertStatus;
  JournalEntry? _journalEntry;

  Timer? _pollTimer;

  /// Debounce ganti timeframe, menyamai web: tap langsung memicu analisis
  /// baru tanpa tombol konfirmasi terpisah, tapi ditunda 650ms supaya
  /// ketuk-ketuk cepat antar timeframe cuma memicu satu request (untuk
  /// pilihan terakhir), bukan satu request per ketukan.
  Timer? _quickTimeframeTimer;

  @override
  void initState() {
    super.initState();

    _analysis = widget.preloaded;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final telemetry = context.read<AuthProvider?>()?.telemetry;
        if (telemetry != null) {
          unawaited(telemetry.pageView('/analyses/${widget.analysisId}'));
        }
        unawaited(_loadAlertStatus());
        unawaited(_loadJournalEntry());
      }
    });

    _load();
    _startOutcomePolling();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analysis = _analysis;

      if (!mounted || analysis == null) {
        return;
      }

      unawaited(_loadMarketData(analysis));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _quickTimeframeTimer?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // OUTCOME POLLING
  // ===========================================================================

  void _startOutcomePolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_analysis?.outcomeStatus == AnalysisOutcomeStatusEnum.pending) {
        unawaited(_load(silent: true));
      }
    });
  }

  void _stopOutcomePollingIfResolved(Analysis analysis) {
    final status = analysis.outcomeStatus;

    if (status == null || status == AnalysisOutcomeStatusEnum.pending) {
      return;
    }

    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ===========================================================================
  // LOAD ANALYSIS
  // ===========================================================================

  Future<void> _load({bool silent = false}) async {
    if (_detailRequestInFlight) {
      return;
    }

    _detailRequestInFlight = true;

    try {
      final provider = context.read<AnalysisProvider>();

      final previous = _analysis;

      final result = await provider.getAnalysis(
        widget.analysisId,
        silent: silent,
      );

      if (!mounted) {
        return;
      }

      if (result != null) {
        _stopOutcomePollingIfResolved(result);
      }

      setState(() {
        if (result != null) {
          _analysis = result;
        }

        _loading = false;
      });

      if (result != null &&
          (_candles.isEmpty ||
              previous?.instrument != result.instrument ||
              previous?.timeframe != result.timeframe)) {
        unawaited(_loadMarketData(result));
      }
    } finally {
      _detailRequestInFlight = false;
    }
  }

  // ===========================================================================
  // MARKET DATA
  // ===========================================================================

  Future<void> _loadMarketData(Analysis analysis, {bool force = false}) async {
    if (_marketRequestInFlight) {
      return;
    }

    _marketRequestInFlight = true;

    if (mounted) {
      setState(() {
        _marketLoading = true;
        _marketError = null;
      });
    }

    try {
      final provider = context.read<MarketProvider>();

      final results = await Future.wait<Object?>([
        provider.getCandlesFor(
          analysis.instrument,
          analysis.timeframe,
          force: force,
        ),
        provider.getTechnicalFor(
          analysis.instrument,
          analysis.timeframe,
          force: force,
        ),
      ]);
      final candles = results[0] as List<MarketCandle>;
      final technical = results[1] as BeginnerTechnicalSnapshot?;

      // Price alert membutuhkan quote live,
      // tetapi kegagalan quote tidak boleh
      // membuat seluruh detail error.
      unawaited(provider.loadQuotes(force: force, silent: true));

      if (!mounted) {
        return;
      }

      setState(() {
        _candles = candles;
        _technical = technical;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _marketError = context.l10n.marketChartUnavailable;
      });
    } finally {
      _marketRequestInFlight = false;

      if (mounted) {
        setState(() {
          _marketLoading = false;
        });
      }
    }
  }

  Future<void> _reanalyze([String? timeframe]) async {
    final analysis = _analysis;
    if (analysis == null ||
        _reanalyzing ||
        !isVerifiedAnalysisInstrument(analysis.instrument)) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final selected = timeframe ?? analysis.timeframe;
    setState(() {
      _reanalyzing = true;
      _selectedTimeframe = selected;
    });
    final analysisProvider = context.read<AnalysisProvider>();
    final created = await analysisProvider.createAnalysis(
      instrument: analysis.instrument,
      timeframe: _timeframeEnum(selected),
      mode: analysis.mode == AnalysisModeEnum.pro
          ? CreateAnalysisBodyModeEnum.pro
          : CreateAnalysisBodyModeEnum.beginner,
      userInputContext: analysis.userInputContext,
    );
    if (!mounted) return;
    setState(() => _reanalyzing = false);
    if (created == null) {
      final limit = analysisProvider.quotaLimit;
      if (limit != null) {
        await showAnalysisQuotaDialog(context, limit);
        return;
      }
      // The server explains why (unverified price data, unsupported code, ...).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            analysisProvider.errorMessage ?? context.l10n.analysisCreateFailed,
          ),
        ),
      );
      return;
    }

    if (analysisProvider.lastAnalysisConsumedCredit) {
      final balance = analysisProvider.lastAnalysisCreditBalance;
      unawaited(context.read<CreditProvider>().loadBalance(silent: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            balance == null
                ? context.l10n.analysisCreditConsumedUnknownBalance
                : context.l10n.analysisCreditConsumed(balance),
          ),
        ),
      );
    }

    unawaited(
      auth.telemetry.track(
        AnalyticsEventBodyEventTypeEnum.analysisCreated,
        path: '/analyses/${widget.analysisId}',
        metadata: {'instrument': created.instrument, 'timeframe': selected},
      ),
    );
    if (widget.onAnalysisCreated case final callback?) {
      callback(created);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              AnalysisDetailScreen(analysisId: created.id, preloaded: created),
        ),
      );
    }
  }

  void _selectTimeframe(String timeframe) {
    final analysis = _analysis;
    if (analysis == null || _reanalyzing) return;

    _quickTimeframeTimer?.cancel();

    if (timeframe == analysis.timeframe) {
      setState(() => _selectedTimeframe = null);
      return;
    }

    setState(() => _selectedTimeframe = timeframe);
    _quickTimeframeTimer = Timer(const Duration(milliseconds: 650), () {
      _quickTimeframeTimer = null;
      if (!mounted || _reanalyzing || _selectedTimeframe != timeframe) return;
      unawaited(_reanalyze(timeframe));
    });
  }

  /// Copies or saves one Adaptive side as a watermarked summary image. Only
  /// the saved analysis time and the plan's own numbers go into it.
  Future<void> _shareAdaptiveSummary(
    Analysis analysis,
    String action,
    AdaptiveSidePlan plan,
    AdaptiveCalculation calculation,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    void notify(String message) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    final locale = Localizations.localeOf(context).toString();
    final fmt = AdaptiveFormat.of(context);
    final stamp = DateFormat.yMMMd(locale).add_Hm();
    final rec = calculation.recommendation;
    final actionable =
        rec.valid &&
        rec.evaluationFor(plan.side).status == AdaptiveSideStatus.viable &&
        rec.result.sideOf(plan.side) != null;
    final budget = calculation.budgetFor(plan.side);
    final rule = calculation.rule;
    try {
      if (plan.layers.isEmpty) throw StateError('Adaptive plan unavailable');
      final data = AdaptivePlanShareData(
        title: l10n.adaptiveShareSummaryTitle,
        instrument: analysis.instrument,
        timeframe: analysis.timeframe,
        analyzedAt:
            '${l10n.chartShareAnalyzed}: ${stamp.format(analysis.createdAt.toLocal())}',
        generatedLabel:
            '${l10n.chartShareMade}: ${stamp.format(DateTime.now())}',
        sideLabel: plan.side == 'buy'
            ? l10n.priceRiseScenario
            : l10n.priceFallScenario,
        status: actionable
            ? l10n.planReadyToReview
            : l10n.conditionalScenarioNotActionable,
        actionable: actionable,
        statusDetail: actionable
            ? l10n.objectiveScenario
            : l10n.referenceNumbersOnly,
        account: rule == null
            ? ''
            : adaptiveTierLabel(context, rule.accountTier),
        style: l10n.adaptiveRiskStyleActive(
          adaptiveRiskStyleLabel(context, calculation.style),
        ),
        positionsTitle: l10n.entryLotPerPosition,
        positions: [
          for (final layer in plan.layers)
            (
              label:
                  '${l10n.adaptiveLevel} ${layer.level + 1} · ${layer.level == 0 ? l10n.initialEntry : l10n.additionalPosition}',
              value:
                  '${fmt.number(layer.price, 4)} · ${fmt.number(layer.lot)} ${l10n.adaptiveLot}',
            ),
        ],
        metrics: [
          (
            label: l10n.adaptiveSnapshotTotalLots,
            value: '${fmt.number(plan.totalLots)} ${l10n.adaptiveLot}',
            detail: null,
          ),
          (
            label: l10n.oneFinalStopLoss,
            value: fmt.number(plan.stopLoss, 4),
            detail: null,
          ),
          (
            label: l10n.estimatedMaximumLoss,
            value: fmt.money(plan.estimatedLoss),
            detail: null,
          ),
          if (budget != null) ...[
            (
              label: l10n.usableRiskBudget,
              value: fmt.money(budget.usableRiskBudget),
              detail: l10n.adaptiveRiskBudgetRate(
                fmt.number(budget.riskUtilizationRate * 100, 0),
              ),
            ),
            (
              label: l10n.reservedLossCeiling,
              value: fmt.money(budget.unusedRiskBuffer),
              detail: null,
            ),
          ],
          (
            label: l10n.adaptiveMarginRequired,
            value: fmt.money(plan.marginRequired),
            detail: null,
          ),
          if (plan.takeProfit1 != null)
            (
              label: l10n.takeProfit1,
              value: fmt.number(plan.takeProfit1, 4),
              detail:
                  '${l10n.adaptiveTpProfit}: ${fmt.profit(plan.profitToTp1)}',
            ),
          if (plan.takeProfit2 != null)
            (
              label: l10n.takeProfit2,
              value: fmt.number(plan.takeProfit2, 4),
              detail:
                  '${l10n.adaptiveTpProfit}: ${fmt.profit(plan.profitToTp2)}',
            ),
        ],
        notes: [l10n.adaptiveShareSummaryWarning],
      );
      final png = await watermarkPng(
        await renderAdaptivePlanSharePng(data),
        attribution: exportAttribution(
          instrument: analysis.instrument,
          timeframe: analysis.timeframe,
          analysisId: analysis.id,
        ),
      );
      if (action == 'copy') {
        await _reasoningClipboard.invokeMethod<void>('copyImage', png);
        notify(l10n.adaptiveShareSummaryCopied);
      } else {
        final stem =
            'tradepilot-adaptive-${analysis.instrument.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}-${plan.side}-${analysis.timeframe}';
        await Gal.putImageBytes(png, name: stem);
        notify(l10n.adaptiveShareSummaryDownloaded);
      }
    } catch (_) {
      notify(l10n.adaptiveShareSummaryFailed);
    }
  }

  Future<void> _refreshFundamentals() async {
    if (_refreshingFundamentals) return;
    setState(() => _refreshingFundamentals = true);
    final result = await context.read<AnalysisProvider>().refreshFundamentals(
      widget.analysisId,
    );
    if (!mounted) return;
    setState(() {
      _fundamentalRefresh = result;
      _refreshingFundamentals = false;
    });
    if (result != null) await _load(silent: true);
  }

  Future<void> _openExternalUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !{'https', 'http'}.contains(uri.scheme)) return;
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.linkOpenFailed)));
    }
  }

  Future<void> _openFullReasoning(Analysis analysis, bool isPro) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FullReasoningSheet(
        analysis: analysis,
        isPro: isPro,
        onOpenUrl: _openExternalUrl,
      ),
    );
  }

  void _openGuide(ProgressionEvidenceStartInputGuideIdEnum guideId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MindsetScreen(initialGuideId: guideId)),
    );
  }

  Future<void> _openRiskMap(Analysis analysis) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .9,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: RiskMapCard(
              instrument: analysis.instrument,
              selectedTimeframe: _selectedTimeframe ?? analysis.timeframe,
              initiallyExpanded: true,
              sheetMode: true,
              onSelectTimeframe: (timeframe) {
                Navigator.of(sheetContext).pop();
                _selectTimeframe(timeframe);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([_load(), _loadAlertStatus(), _loadJournalEntry()]);

    final analysis = _analysis;

    if (analysis != null) {
      await _loadMarketData(analysis, force: true);
    }
  }

  Future<void> _loadJournalEntry() async {
    if (!mounted) return;
    setState(() {
      _journalLoading = true;
      _journalError = null;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .tradeJournal
          .getJournalEntryForAnalysis(analysisId: widget.analysisId);
      if (!mounted) return;
      setState(() => _journalEntry = response.data);
    } on DioException catch (error) {
      if (!mounted) return;
      if (error.response?.statusCode == 404) {
        setState(() => _journalEntry = null);
      } else {
        setState(() => _journalError = context.l10n.journalCheckFailed);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _journalError = context.l10n.journalCheckFailed);
      }
    } finally {
      if (mounted) setState(() => _journalLoading = false);
    }
  }

  Future<void> _openJournal(Analysis analysis) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TradeJournalScreen(analysis: analysis, initialEntry: _journalEntry),
      ),
    );
    if (mounted) await _loadJournalEntry();
  }

  // ===========================================================================
  // ANALYSIS LEVEL ALERTS
  // ===========================================================================

  Future<void> _loadAlertStatus() async {
    if (!mounted) return;
    setState(() {
      _alertStatusLoading = true;
      _alertError = null;
    });
    final status = await context.read<AnalysisProvider>().getAnalysisAlerts(
      widget.analysisId,
    );
    if (!mounted) return;
    setState(() {
      _alertStatus = status;
      _alertStatusLoading = false;
      _alertError = status == null ? context.l10n.alertStatusLoadFailed : null;
    });
  }

  Future<void> _setAnalysisAlerts(bool enabled) async {
    if (_alertBusy) return;
    final analysisProvider = context.read<AnalysisProvider>();
    setState(() => _alertBusy = true);

    if (enabled) {
      final push = context.read<NativePushService?>();
      if (push != null &&
          (!push.isEnabled || !push.isRegistered) &&
          !await push.enable()) {
        if (!mounted) return;
        setState(() => _alertBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(push.errorMessage ?? context.l10n.alertsNoPush),
            action: SnackBarAction(
              label: context.l10n.alertsEnableNotifications,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
          ),
        );
        return;
      }
    }

    final status = await analysisProvider.setAnalysisAlerts(
      widget.analysisId,
      enabled: enabled,
    );
    if (!mounted) return;
    setState(() {
      _alertBusy = false;
      if (status != null) _alertStatus = status;
    });

    if (status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !enabled
                ? context.l10n.alertDisableFailed
                : analysisProvider.lastAlertFailure == AlertFailure.unsupported
                ? context.l10n.alertsArmError
                : context.l10n.alertsRetryError,
          ),
        ),
      );
      return;
    }

    if (enabled) {
      unawaited(
        context.read<AuthProvider>().telemetry.track(
          AnalyticsEventBodyEventTypeEnum.alertArmed,
          path: '/analyses/${widget.analysisId}',
          metadata: {'analysisId': widget.analysisId},
        ),
      );
    }
  }

  // ===========================================================================
  // FEEDBACK
  // ===========================================================================

  Future<void> _openFeedback(FeedbackBodyFeedbackTypeEnum type) async {
    var outcome = FeedbackBodyOutcomeEnum.unknown;
    final noteController = TextEditingController();
    final result = await showDialog<(FeedbackBodyOutcomeEnum, String?)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.analysisFeedbackTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.analysisFeedbackQuestion),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                children: [
                  for (final item in [
                    (
                      FeedbackBodyOutcomeEnum.correct,
                      context.l10n.feedbackCorrect,
                    ),
                    (FeedbackBodyOutcomeEnum.wrong, context.l10n.feedbackWrong),
                    (
                      FeedbackBodyOutcomeEnum.unknown,
                      context.l10n.feedbackUnknown,
                    ),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: outcome == item.$1,
                      onSelected: (_) =>
                          setDialogState(() => outcome = item.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLength: 1000,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.feedbackNoteOptional,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                outcome,
                noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
              )),
              child: Text(context.l10n.send),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (result != null && mounted) {
      await _sendFeedback(type, outcome: result.$1, note: result.$2);
    }
  }

  Future<void> _sendFeedback(
    FeedbackBodyFeedbackTypeEnum type, {
    FeedbackBodyOutcomeEnum? outcome,
    String? note,
  }) async {
    if (_submittingFeedback) {
      return;
    }

    setState(() {
      _submittingFeedback = true;
    });

    final ok = await context.read<AnalysisProvider>().submitFeedback(
      analysisId: widget.analysisId,
      type: type,
      outcome: outcome,
      note: note,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      unawaited(context.read<ProgressionProvider>().refresh(silent: true));
      unawaited(
        context.read<AuthProvider>().telemetry.track(
          AnalyticsEventBodyEventTypeEnum.feedbackSubmitted,
          path: '/analyses/${widget.analysisId}',
          metadata: {'analysisId': widget.analysisId},
        ),
      );
    }

    setState(() {
      _submittingFeedback = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? context.l10n.feedbackThanks : context.l10n.feedbackSendFailed,
        ),
      ),
    );
  }

  Future<bool> _saveNote(String note) async {
    final current = _analysis;
    if (current == null) return false;
    final provider = context.read<AnalysisProvider>();
    final updated = await provider.saveAnalysisNote(
      analysis: current,
      note: note,
    );
    if (!mounted) return false;
    if (updated != null) {
      setState(() => _analysis = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.hasNote == true
                ? context.l10n.noteSaved
                : context.l10n.noteDeleted,
          ),
        ),
      );
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? context.l10n.noteSaveFailed),
      ),
    );
    return false;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    if (_loading && _analysis == null) {
      const loading = Center(child: CircularProgressIndicator());
      return widget.embedded ? loading : const Scaffold(body: loading);
    }

    final analysis = _analysis;

    if (analysis == null) {
      final missing = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ProductStateView(
              kind: ProductStateKind.error,
              title: context.l10n.analysisNotFound,
              actionLabel: context.l10n.tryAgain,
              onAction: () => unawaited(_load()),
            ),
          ],
        ),
      );
      return widget.embedded
          ? missing
          : Scaffold(appBar: AppBar(), body: missing);
    }

    final bias = (analysis.tradingBias ?? '').toLowerCase();

    final isPro = analysis.mode == AnalysisModeEnum.pro;
    final isBullish =
        bias.contains('bull') || bias == 'buy' || bias == 'strong_buy';
    final isBearish =
        bias.contains('bear') || bias == 'sell' || bias == 'strong_sell';

    final biasColor = isBullish
        ? (isDark ? AppColors.bullishDark : AppColors.bullishLight)
        : isBearish
        ? (isDark ? AppColors.bearishDark : AppColors.bearishLight)
        : (isDark ? AppColors.neutralDark : AppColors.neutralLight);

    final biasLabel = isBullish
        ? context.l10n.bullishBias
        : isBearish
        ? context.l10n.bearishBias
        : context.l10n.neutral;

    final isExpired = analysis.validUntil.isBefore(DateTime.now());
    // Dipakai oleh Scenarios/Opportunity/Risk/invalidation yang sekarang
    // dinonaktifkan di bawah (lihat komentar di reading order) karena tidak
    // ada padanannya di web.
    // final mainScenario = isPro ? analysis.baseCase : analysis.mainScenario;
    // final alternativeScenario = isPro
    //     ? (isBearish ? analysis.bullishScenario : analysis.bearishScenario)
    //     : analysis.alternativeScenario;
    // final invalidation = isPro
    //     ? analysis.invalidationConditions
    //     : analysis.failureConditions;

    // Saat embedded, detail ini menjadi bagian dari ListView halaman Analisis,
    // jadi ia tidak boleh menggulir (atau menarik-untuk-refresh) sendiri.
    final content = ListView(
      shrinkWrap: widget.embedded,
      physics: widget.embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.all(16),
      // Urutan mengikuti reading order web (Aset/Timeframe -> Bias -> Sinyal
      // -> Chart -> Saran Level -> Fundamental -> Ringkasan Konteks Pasar ->
      // Ukuran Posisi -> Indikator Teknikal -> Alert -> panel batal/peluang/
      // risiko/skenario/pro/eksekusi), supaya mobile terasa sama dengan web.
      // Seksi yang cuma ada di mobile (outcome, beginner explainer, catatan
      // konteks pengguna, jurnal, catatan, panduan) ditaruh di ekor, setelah
      // konten inti, sebelum disclaimer & feedback penutup yang juga menutup
      // halaman di web.
      children: [
        _DetailTimeframeCard(
          analysis: analysis,
          current: analysis.timeframe,
          selected: _selectedTimeframe,
          loading: _reanalyzing,
          onSelect: _selectTimeframe,
          onOpenRiskMap: supportsRiskMap(analysis.instrument)
              ? () => _openRiskMap(analysis)
              : null,
        ),

        const SizedBox(height: 14),
        _HeaderCard(
          analysis: analysis,
          biasColor: biasColor,
          biasLabel: biasLabel,
          isExpired: isExpired,
          muted: muted,
          isPro: isPro,
          onLearn: () => _openGuide(
            ProgressionEvidenceStartInputGuideIdEnum.biasConfidenceValidity,
          ),
          onOpenReasoning: () => _openFullReasoning(analysis, isPro),
        ),

        const SizedBox(height: 14),
        _ChartCard(
          analysis: analysis,
          candles: _candles,
          isLoading: _marketLoading,
          error: _marketError,
          onRetry: () => _loadMarketData(analysis, force: true),
          onOpenTradingView: () => _openExternalUrl(
            Uri.https('www.tradingview.com', '/chart/', {
              'symbol': _tradingViewSymbol(analysis.instrument),
            }).toString(),
          ),
        ),

        if (analysis.tradePlan != null) ...[
          const SizedBox(height: 14),
          _TradePlanCard(
            plan: analysis.tradePlan!,
            isDark: isDark,
            onLearn: () => _openGuide(
              ProgressionEvidenceStartInputGuideIdEnum.standardPlan,
            ),
          ),
        ],

        // Ringkasan "Bukti pasar" disembunyikan atas permintaan produk.
        // const SizedBox(height: 14),
        // _EvidenceSummary(analysis: analysis),
        if (analysis.fundamentalContext != null) ...[
          const SizedBox(height: 14),
          _FundamentalSnapshotCard(
            key: const ValueKey('analysis-fundamental-context'),
            analysis: analysis,
            refreshed: _fundamentalRefresh,
            refreshing: _refreshingFundamentals,
            onRefresh: _refreshFundamentals,
            onLearn: () => _openGuide(
              ProgressionEvidenceStartInputGuideIdEnum.technicalFundamental,
            ),
            onOpenUrl: _openExternalUrl,
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 14),
        _MarketSnapshotCard(
          key: const ValueKey('analysis-market-snapshot'),
          analysis: analysis,
        ),

        if (analysis.tradePlan != null) ...[
          const SizedBox(height: 14),
          AdaptivePositionPlanCard(
            analysis: analysis,
            candles: _candles,
            onShareSummary: (action, plan, calculation) =>
                _shareAdaptiveSummary(analysis, action, plan, calculation),
            onLearn: () => _openGuide(
              ProgressionEvidenceStartInputGuideIdEnum.adaptivePositionPlan,
            ),
          ),
        ],

        if (_technical != null) ...[
          const SizedBox(height: 14),
          Card(
            child: ExpansionTile(
              key: const ValueKey('analysis-technical-indicators'),
              initiallyExpanded: true,
              leading: Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                context.l10n.technicalDetails,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(context.l10n.technicalDetailsDescription),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                _TechnicalIndicatorsCard(
                  technical: _technical!,
                  timeframe: analysis.timeframe,
                  showRawSignals: isPro,
                  showSummary: true,
                ),
              ],
            ),
          ),
        ],

        if (analysis.tradePlan != null) ...[
          const SizedBox(height: 14),
          _AnalysisAlertsCard(
            status: _alertStatus,
            loading: _alertStatusLoading,
            busy: _alertBusy,
            error: _alertError,
            onToggle: _setAnalysisAlerts,
            onRetry: _loadAlertStatus,
          ),
        ],

        if (widget.onCreatePriceAlert case final onCreatePriceAlert?) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCreatePriceAlert,
            icon: const Icon(Icons.notifications_active_outlined, size: 17),
            label: Text(context.l10n.createPriceAlert),
          ),
        ],

        // Invalidation, Opportunity/Risk, Scenarios, Pro details, dan
        // Execution insight disembunyikan: tidak ada padanannya di web
        // (dicek langsung, termasuk di dalam modal "See full reasoning"),
        // jadi tampil di mobile saja akan memecah paritas layout dengan web.
        // if (invalidation?.trim().isNotEmpty == true) ...[
        //   const SizedBox(height: 14),
        //   _InfoPanel(
        //     key: const ValueKey('analysis-invalidation'),
        //     title: context.l10n.analysisInvalidationTitle,
        //     body: invalidation!,
        //     icon: Icons.report_gmailerrorred_outlined,
        //     color: Theme.of(context).colorScheme.error,
        //   ),
        // ],
        //
        // if (analysis.opportunity?.trim().isNotEmpty == true ||
        //     analysis.risk?.trim().isNotEmpty == true) ...[
        //   const SizedBox(height: 10),
        //   _OpportunityRiskCard(analysis: analysis),
        // ],
        //
        // const SizedBox(height: 14),
        // _ScenariosCard(
        //   mainScenario: mainScenario,
        //   alternativeScenario: alternativeScenario,
        // ),
        //
        // if (isPro &&
        //     (analysis.keyDriversTechnical?.trim().isNotEmpty == true ||
        //         analysis.keyDriversFundamental?.trim().isNotEmpty == true ||
        //         analysis.marketContext?.trim().isNotEmpty == true)) ...[
        //   const SizedBox(height: 10),
        //   _ProAnalysisDetailsCard(analysis: analysis),
        // ],
        //
        // const SizedBox(height: 12),
        // _ExecutionInsightCard(analysis: analysis),

        // ---------------------------------------------------------------
        // Seksi berikut ini spesifik mobile (belum ada di web), jadi
        // ditaruh setelah konten inti yang urutannya menyamai web.
        // ---------------------------------------------------------------
        if (analysis.outcomeStatus != null) ...[
          const SizedBox(height: 14),
          _OutcomeCard(analysis: analysis),
        ],

        if (!isPro) ...[
          const SizedBox(height: 14),
          _BeginnerMeaningCard(
            analysis: analysis,
            biasLabel: biasLabel,
            biasColor: biasColor,
          ),
        ],

        if (analysis.userInputContext?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 14),
          _SectionCard(
            title: context.l10n.providedContext,
            body: analysis.userInputContext!,
            icon: Icons.chat_bubble_outline,
          ),
        ],

        const SizedBox(height: 14),
        Text(
          context.l10n.notesAndJournal,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.notesAndJournalDescription,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 10),

        _AnalysisJournalCard(
          entry: _journalEntry,
          loading: _journalLoading,
          error: _journalError,
          onOpen: () => _openJournal(analysis),
          onRetry: _loadJournalEntry,
        ),

        const SizedBox(height: 14),

        Consumer<AnalysisProvider>(
          builder: (context, provider, _) => AnalysisNoteCard(
            note: analysis.userNote,
            isSaving: provider.isSavingNote(analysis.id),
            onSave: _saveNote,
          ),
        ),

        const SizedBox(height: 14),
        ExpansionTile(
          key: const ValueKey('analysis-guides'),
          leading: Icon(
            Icons.menu_book_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            context.l10n.learnAnalysisBasics,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            _AnalysisGuideLink(
              label: context.l10n.learnBiasConfidence,
              onPressed: () => _openGuide(
                ProgressionEvidenceStartInputGuideIdEnum.biasConfidenceValidity,
              ),
            ),
            _AnalysisGuideLink(
              label: context.l10n.learnTechnicalFundamental,
              onPressed: () => _openGuide(
                ProgressionEvidenceStartInputGuideIdEnum.technicalFundamental,
              ),
            ),
            _AnalysisGuideLink(
              onPressed: () => _openGuide(
                ProgressionEvidenceStartInputGuideIdEnum.standardPlan,
              ),
            ),
            _AnalysisGuideLink(
              label: context.l10n.learnAdaptivePosition,
              onPressed: () => _openGuide(
                ProgressionEvidenceStartInputGuideIdEnum.adaptivePositionPlan,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Container(
          key: const ValueKey('analysis-safety-disclaimer'),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppColors.radius),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.analysisSafetyDisclaimerTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.analysisSafetyDisclaimer,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          context.l10n.analysisHelpfulQuestion,
          style: Theme.of(context).textTheme.titleSmall,
        ),

        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final stackActions =
                constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final helpful = OutlinedButton.icon(
              onPressed: _submittingFeedback
                  ? null
                  : () => _openFeedback(FeedbackBodyFeedbackTypeEnum.useful),
              icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
              label: Text(context.l10n.helpful),
            );
            final notHelpful = OutlinedButton.icon(
              onPressed: _submittingFeedback
                  ? null
                  : () => _openFeedback(FeedbackBodyFeedbackTypeEnum.notUseful),
              icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
              label: Text(context.l10n.notHelpful),
            );

            if (stackActions) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [helpful, const SizedBox(height: 8), notHelpful],
              );
            }
            return Row(
              children: [
                Expanded(child: helpful),
                const SizedBox(width: 10),
                Expanded(child: notHelpful),
              ],
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );

    if (widget.embedded) return content;

    final body = RefreshIndicator(onRefresh: _refresh, child: content);
    final compactAppBarAction =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Scaffold(
      appBar: AppBar(
        title: Text(analysis.instrument),
        actions: [
          if (widget.onNewAnalysis case final onNewAnalysis?)
            if (compactAppBarAction)
              IconButton(
                key: const Key('detail-new-analysis-button'),
                tooltip: context.l10n.analyzeTitle,
                onPressed: onNewAnalysis,
                icon: const Icon(Icons.add_rounded),
              )
            else
              TextButton.icon(
                key: const Key('detail-new-analysis-button'),
                onPressed: onNewAnalysis,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(context.l10n.analyzeTitle),
              ),
          if (isExpired)
            IconButton(
              tooltip: context.l10n.reanalyze,
              onPressed: _reanalyzing ? null : _reanalyze,
              icon: _reanalyzing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _AnalysisGuideLink extends StatelessWidget {
  const _AnalysisGuideLink({required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.menu_book_outlined, size: 17),
      label: Text(label ?? context.l10n.openFullExplanation),
    ),
  );
}

// ignore: unused_element
class _AnalysisSectionHeading extends StatelessWidget {
  const _AnalysisSectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

class _AnalysisJournalCard extends StatelessWidget {
  const _AnalysisJournalCard({
    required this.entry,
    required this.loading,
    required this.error,
    required this.onOpen,
    required this.onRetry,
  });

  final JournalEntry? entry;
  final bool loading;
  final String? error;
  final VoidCallback onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final journal = entry;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(
          journal == null
              ? context.l10n.journalCreateForTrade
              : context.l10n.journalEntryForTrade,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: loading
            ? const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              )
            : error != null
            ? Text(error!)
            : journal == null
            ? Text(context.l10n.journalReflectionHint)
            : Text(
                [
                  journal.side.name.toUpperCase(),
                  journal.outcome.name,
                  if (journal.mood?.trim().isNotEmpty == true) journal.mood!,
                  if (journal.note?.trim().isNotEmpty == true) journal.note!,
                ].join(' · '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: error != null
            ? IconButton(
                tooltip: context.l10n.tryAgain,
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: loading || error != null ? null : onOpen,
      ),
    );
  }
}

// =============================================================================
// ANALYSIS LEVEL ALERTS
// =============================================================================

class _AnalysisAlertsCard extends StatelessWidget {
  const _AnalysisAlertsCard({
    required this.status,
    required this.loading,
    required this.busy,
    required this.error,
    required this.onToggle,
    required this.onRetry,
  });

  final AlertStatus? status;
  final bool loading;
  final bool busy;
  final String? error;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = status?.enabled ?? false;
    final activeColor = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    return Card(
      key: const ValueKey('analysis-level-alert-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  enabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  size: 20,
                  color: enabled ? activeColor : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.priceLevelAlerts,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      Text(
                        context.l10n.priceLevelAlertsDescription,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading || busy)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Switch.adaptive(
                    key: const ValueKey('analysis-level-alert-switch'),
                    value: enabled,
                    activeTrackColor: activeColor,
                    onChanged: error == null ? onToggle : null,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (error != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(color: colors.error, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(context.l10n.tryAgain),
                  ),
                ],
              )
            else ...[
              if (status?.levels.isNotEmpty == true)
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: const ValueKey('analysis-alert-levels'),
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      enabled
                          ? context.l10n.priceLevelAlertsOn(
                              status?.armedCount ?? 0,
                            )
                          : context.l10n.priceLevelAlertsOff,
                      style: TextStyle(
                        color: enabled ? activeColor : colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    children: [
                      for (final row in status!.levels)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_alertLevelLabel(row.level)} · ${row.side.name.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '@ ${row.price}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _AlertStatusBadge(row: row),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              else
                Text(
                  enabled
                      ? context.l10n.priceLevelAlertsOn(status?.armedCount ?? 0)
                      : context.l10n.priceLevelAlertsOff,
                  style: TextStyle(
                    color: enabled ? activeColor : colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _alertLevelLabel(AlertLevelRowLevelEnum level) => switch (level) {
  AlertLevelRowLevelEnum.entry => 'Entry',
  AlertLevelRowLevelEnum.sl => 'Stop Loss',
  AlertLevelRowLevelEnum.tp1 => 'Take Profit 1',
  _ => 'Take Profit 2',
};

class _AlertStatusBadge extends StatelessWidget {
  const _AlertStatusBadge({required this.row});

  final AlertLevelRow row;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color) = row.triggeredAt != null
        ? (
            context.l10n.triggered,
            isDark ? AppColors.bullishDark : AppColors.bullishLight,
          )
        : row.cancelledAt != null
        ? (
            context.l10n.cancelled,
            Theme.of(context).colorScheme.onSurfaceVariant,
          )
        : (
            context.l10n.monitored,
            isDark ? AppColors.bullishDark : AppColors.bullishLight,
          );

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _DetailTimeframeCard extends StatelessWidget {
  const _DetailTimeframeCard({
    required this.analysis,
    required this.current,
    required this.selected,
    required this.loading,
    required this.onSelect,
    this.onOpenRiskMap,
  });

  final Analysis analysis;
  final String current;
  final String? selected;
  final bool loading;
  final ValueChanged<String> onSelect;
  final VoidCallback? onOpenRiskMap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurfaceVariant;
    final condition = _marketConditionMeta(context, analysis.marketCondition);
    final remaining = analysis.validUntil.difference(DateTime.now());
    final hours = remaining.isNegative ? 0 : math.max(1, remaining.inHours);
    final outcome = _outcomeBadgeMeta(context, analysis.outcomeStatus);
    // Older analyses can carry an instrument that is no longer verified; their
    // saved result stays readable but cannot be submitted again.
    final canReanalyze = isVerifiedAnalysisInstrument(analysis.instrument);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              analysis.instrument,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            _StatusChip(label: analysis.timeframe, color: colors.onSurface),
            if (condition != null)
              _StatusChip(
                label: condition.$1,
                color: condition.$2,
                icon: condition.$3,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.schedule_rounded, color: colors.tertiary, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                context.l10n.relevantForHours(hours),
                style: TextStyle(
                  color: colors.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (outcome != null)
              _StatusChip(
                label: outcome.$1,
                color: outcome.$2,
                icon: outcome.$3,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.analysisCreatedAt(
            DateFormat(
              'd MMM yyyy, HH:mm',
            ).format(analysis.createdAt.toLocal()),
          ),
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 6.0;
                    final width = (constraints.maxWidth - gap * 6) / 7;
                    return Wrap(
                      spacing: gap,
                      runSpacing: 8,
                      children: [
                        for (final timeframe in _analysisTimeframes)
                          SizedBox(
                            width: timeframe == '1W' ? width : width,
                            child: _TimeframeOption(
                              key: Key('timeframe-option-$timeframe'),
                              timeframe: timeframe,
                              selected: (selected ?? current) == timeframe,
                              onTap: loading || !canReanalyze
                                  ? null
                                  : () => onSelect(timeframe),
                            ),
                          ),
                        if (onOpenRiskMap != null)
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              key: const Key('timeframe-risk-map-button'),
                              onPressed: loading ? null : onOpenRiskMap,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.primary,
                                side: BorderSide(color: colors.primary),
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.monitor_heart_outlined,
                                size: 19,
                              ),
                              label: Text(context.l10n.riskMapButton),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  canReanalyze
                      ? context.l10n.changeTimeframeDescription
                      : context.l10n.instrumentLegacyUnsupported,
                  key: canReanalyze
                      ? null
                      : const Key('legacy-instrument-unsupported'),
                  style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                ),
                if (loading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

(String, Color, IconData)? _outcomeBadgeMeta(
  BuildContext context,
  AnalysisOutcomeStatusEnum? status,
) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final positive = dark ? AppColors.bullishDark : AppColors.bullishLight;
  final negative = dark ? AppColors.bearishDark : AppColors.bearishLight;
  final neutral = Theme.of(context).colorScheme.onSurfaceVariant;

  return switch (status) {
    AnalysisOutcomeStatusEnum.pending => (
      context.l10n.outcomePendingLabel,
      neutral,
      Icons.hourglass_empty_rounded,
    ),
    AnalysisOutcomeStatusEnum.tp1Hit => (
      context.l10n.outcomeTp1Label,
      positive,
      Icons.check_circle_outline_rounded,
    ),
    AnalysisOutcomeStatusEnum.tp2Hit => (
      context.l10n.outcomeTp2Label,
      positive,
      Icons.check_circle_outline_rounded,
    ),
    AnalysisOutcomeStatusEnum.slHit => (
      context.l10n.outcomeSlLabel,
      negative,
      Icons.cancel_outlined,
    ),
    AnalysisOutcomeStatusEnum.expired => (
      context.l10n.outcomeExpiredLabel,
      Theme.of(context).colorScheme.primary,
      Icons.schedule_outlined,
    ),
    AnalysisOutcomeStatusEnum.invalidated => (
      context.l10n.outcomeInvalidatedLabel,
      negative,
      Icons.warning_amber_rounded,
    ),
    null => null,
    _ => null,
  };
}

// ignore: unused_element
class _TimeframeCard extends StatelessWidget {
  const _TimeframeCard({
    required this.instrument,
    required this.current,
    required this.selected,
    required this.loading,
    required this.onSelect,
    // ignore: unused_element_parameter
    this.onOpenRiskMap,
    // ignore: unused_element_parameter
    this.onChangeInstrument,
  });

  final String instrument;
  final String current;
  final String? selected;
  final bool loading;
  final ValueChanged<String> onSelect;
  final VoidCallback? onChangeInstrument;

  /// Peta risiko membandingkan timeframe satu sama lain, jadi tempatnya di
  /// kartu ini — bukan sebagai tombol lepas di dasar halaman. `null` ketika
  /// instrumen belum didukung.
  final VoidCallback? onOpenRiskMap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final asset = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.analysis,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      instrument,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                );
                if (onChangeInstrument == null) return asset;

                final action = OutlinedButton(
                  onPressed: loading ? null : onChangeInstrument,
                  child: Text(
                    context.l10n.analyzeTitle,
                    textAlign: TextAlign.center,
                  ),
                );
                final stack =
                    constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [asset, const SizedBox(height: 10), action],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: asset),
                    const SizedBox(width: 12),
                    action,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(
              context.l10n.changeTimeframe,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.changeTimeframeDescription,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            // Kisi berkolom tetap, bukan Wrap bebas: delapan timeframe jadi
            // dua baris rata dengan lebar tombol seragam, sehingga tidak ada
            // baris kedua yang menggantung dan tidak ada tombol yang melebar
            // hanya karena labelnya lebih panjang.
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3
                    ? 2
                    : 4;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _analysisTimeframes
                      .map(
                        (timeframe) => SizedBox(
                          width: width,
                          child: _TimeframeOption(
                            key: Key('timeframe-option-$timeframe'),
                            timeframe: timeframe,
                            selected: (selected ?? current) == timeframe,
                            onTap: loading ? null : () => onSelect(timeframe),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            // Tidak ada tombol konfirmasi terpisah — menyamai web, memilih
            // timeframe lain langsung memicu analisis baru (lihat debounce
            // 650ms di _selectTimeframe). LinearProgressIndicator di bawah
            // sudah cukup sebagai indikator "sedang memproses".
            if (onOpenRiskMap case final onOpenRiskMap?) ...[
              // Aksi sekunder, dipisahkan dari kontrol pemilihan di atasnya.
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('timeframe-risk-map-button'),
                  onPressed: loading ? null : onOpenRiskMap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                  label: Text(context.l10n.riskMapButton),
                ),
              ),
            ],
            if (loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Satu tombol timeframe.
///
/// Mengikuti tombol timeframe web (`px-4 py-2 rounded-lg border`): terisi
/// penuh warna brand ketika terpilih, berbingkai ketika tidak. Tidak ada
/// centang, supaya lebar setiap tombol tetap sama di kedua keadaan.
class _TimeframeOption extends StatelessWidget {
  const _TimeframeOption({
    super.key,
    required this.timeframe,
    required this.selected,
    required this.onTap,
  });

  final String timeframe;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabled = onTap == null;

    return Semantics(
      button: true,
      selected: selected,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Text(
              timeframe,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? colors.onPrimary : colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.analysis,
    required this.biasColor,
    required this.biasLabel,
    required this.isExpired,
    required this.muted,
    required this.isPro,
    required this.onLearn,
    required this.onOpenReasoning,
  });

  final Analysis analysis;
  final Color biasColor;
  final String biasLabel;
  final bool isExpired;
  final Color muted;
  final bool isPro;
  final VoidCallback onLearn;
  final VoidCallback onOpenReasoning;

  @override
  Widget build(BuildContext context) {
    final rawBias = (analysis.tradingBias ?? '').toLowerCase();
    final gaugeValue = rawBias.contains('bear') || rawBias == 'sell'
        ? .18
        : rawBias.contains('bull') || rawBias == 'buy'
        ? .82
        : .5;
    final confidenceMin = analysis.confidenceMin ?? 0;
    final confidenceMax = analysis.confidenceMax ?? 0;
    final confidenceReason =
        (isPro ? analysis.uncertaintyNotes : analysis.whyReason)?.trim();
    final risk = (analysis.riskLevel ?? '').toLowerCase();
    final riskLabel = risk.contains('high') || risk.contains('tinggi')
        ? context.l10n.riskHighLabel
        : risk.contains('low') || risk.contains('rendah')
        ? context.l10n.riskLowLabel
        : context.l10n.riskModerateLabel;
    final riskBars = risk.contains('high') || risk.contains('tinggi')
        ? 3
        : risk.contains('low') || risk.contains('rendah')
        ? 1
        : 2;

    return Card(
      key: const ValueKey('analysis-result-header'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.directionalBias,
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.trending_down_rounded, color: biasColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    biasLabel,
                    style: TextStyle(
                      color: biasColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusChip(label: analysis.timeframe, color: muted),
              ],
            ),
            const SizedBox(height: 8),
            AdaptiveInfoNote(
              context.l10n.biasRiskDisclaimer,
              key: const ValueKey('bias-risk-disclaimer'),
              fontSize: 11.5,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 138,
              width: double.infinity,
              child: CustomPaint(painter: _DirectionalGaugePainter(gaugeValue)),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.strongBearishBias,
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    context.l10n.neutralWait,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    context.l10n.strongBullishBias,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.biasNotInstruction,
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const Divider(height: 32),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.aiConfidence,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$confidenceMin% – $confidenceMax%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.l10n.riskTitle,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      riskLabel,
                      key: const ValueKey('analysis-risk-chip'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            AdaptiveInfoNote(
              context.l10n.riskOverallNote,
              key: const ValueKey('risk-overall-note'),
              fontSize: 11.5,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onLearn,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: Text(context.l10n.learn),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
            // Same two bars as the web: risk level on top, AI confidence below.
            _RiskLevelBars(level: riskBars, semanticLabel: riskLabel),
            _ConfidenceRange(
              minimum: confidenceMin / 100,
              maximum: confidenceMax / 100,
            ),
            if (confidenceReason?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                key: const ValueKey('analysis-confidence-reason'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.whyNotHigherConfidence.toUpperCase(),
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      confidenceReason!,
                      style: const TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      key: const ValueKey('analysis-full-reasoning-button'),
                      onPressed: onOpenReasoning,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(
                        context.l10n.seeFullReasoning,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FullReasoningSheet extends StatefulWidget {
  const _FullReasoningSheet({
    required this.analysis,
    required this.isPro,
    required this.onOpenUrl,
  });

  final Analysis analysis;
  final bool isPro;
  final ValueChanged<String> onOpenUrl;

  @override
  State<_FullReasoningSheet> createState() => _FullReasoningSheetState();
}

class _FullReasoningSheetState extends State<_FullReasoningSheet> {
  final _imageKey = GlobalKey();
  bool _copyingImage = false;
  Timer? _noticeTimer;
  String? _notice;
  bool _noticeIsError = false;

  String? _value(String? value) {
    final trimmed = value?.trim();
    return trimmed?.isNotEmpty == true ? trimmed : null;
  }

  List<String> get _conditions {
    final raw = _value(
      widget.isPro
          ? widget.analysis.invalidationConditions
          : widget.analysis.failureConditions,
    );
    if (raw == null) return const [];
    final parts = raw
        .split(RegExp(r'(?:\r?\n|[•;])'))
        .map((item) => item.replaceFirst(RegExp(r'^\s*[-*]\s*'), '').trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return parts.isEmpty ? [raw] : parts;
  }

  List<(String, String?)> get _citations {
    final cited = widget.analysis.fundamentalCitations;
    if (cited == null) return const [];
    final news = widget.analysis.fundamentalContext?.newsItems;
    return [
      for (final title in cited.newsTitles)
        (
          title,
          news
              ?.where(
                (item) =>
                    item.title.trim().toLowerCase() ==
                    title.trim().toLowerCase(),
              )
              .firstOrNull
              ?.url,
        ),
      for (final event in cited.calendarEvents) (event, null),
    ];
  }

  String _copyableText(BuildContext context) {
    final l10n = context.l10n;
    final reason = _value(
      widget.isPro
          ? widget.analysis.uncertaintyNotes
          : widget.analysis.whyReason,
    );
    final technical = _value(widget.analysis.keyDriversTechnical);
    final fundamental = _value(widget.analysis.keyDriversFundamental);
    final risk = _value(widget.analysis.risk);
    final sections = <String>[
      l10n.whyNotHigherConfidence,
      l10n.analysisBasis(widget.analysis.instrument, widget.analysis.timeframe),
      ?reason,
      ?technical == null ? null : '${l10n.technicalEvidence}: $technical',
      ?fundamental == null ? null : '${l10n.newsCalendarContext}: $fundamental',
      if (_citations.isNotEmpty)
        '${l10n.citedSources}: ${_citations.map((item) => item.$1).join(', ')}',
      ?risk == null ? null : '${l10n.mainRisk}: $risk',
      if (_conditions.isNotEmpty)
        '${l10n.reassessIf}:\n${_conditions.map((item) => '• $item').join('\n')}',
      exportAttribution(
        instrument: widget.analysis.instrument,
        timeframe: widget.analysis.timeframe,
        analysisId: widget.analysis.id,
      ),
    ];
    return sections.join('\n\n');
  }

  void _showMessage(String message, {bool isError = false}) {
    _noticeTimer?.cancel();
    setState(() {
      _notice = message;
      _noticeIsError = isError;
    });
    _noticeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  Future<void> _copyText() async {
    try {
      await Clipboard.setData(ClipboardData(text: _copyableText(context)));
      if (mounted) _showMessage(context.l10n.fullReasoningCopied);
    } catch (_) {
      if (mounted) {
        _showMessage(context.l10n.fullReasoningCopyFailed, isError: true);
      }
    }
  }

  Future<void> _copyImage() async {
    if (_copyingImage) return;
    final pixelRatio = MediaQuery.devicePixelRatioOf(
      context,
    ).clamp(1, 2).toDouble();
    setState(() => _copyingImage = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _imageKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Reasoning image is unavailable');
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Reasoning image encoding failed');
      final marked = await watermarkPng(
        data.buffer.asUint8List(),
        attribution: exportAttribution(
          instrument: widget.analysis.instrument,
          timeframe: widget.analysis.timeframe,
          analysisId: widget.analysis.id,
        ),
      );
      await _reasoningClipboard.invokeMethod<void>('copyImage', marked);
      if (mounted) _showMessage(context.l10n.reasoningImageCopied);
    } catch (_) {
      if (mounted) {
        _showMessage(context.l10n.reasoningImageCopyFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _copyingImage = false);
    }
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurfaceVariant;
    final reason = _value(
      widget.isPro
          ? widget.analysis.uncertaintyNotes
          : widget.analysis.whyReason,
    );
    final technical = _value(widget.analysis.keyDriversTechnical);
    final fundamental = _value(widget.analysis.keyDriversFundamental);
    final risk = _value(widget.analysis.risk);

    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.outlineVariant),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                      child: RepaintBoundary(
                        key: _imageKey,
                        child: ColoredBox(
                          color: colors.surface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.l10n.whyNotHigherConfidence,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).closeButtonTooltip,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                              Text(
                                context.l10n.analysisBasis(
                                  widget.analysis.instrument,
                                  widget.analysis.timeframe,
                                ),
                                style: TextStyle(color: muted),
                              ),
                              if (reason != null) ...[
                                const SizedBox(height: 18),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                      AppColors.radiusMd,
                                    ),
                                  ),
                                  child: Text(
                                    reason,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                              if (technical != null)
                                _ReasoningParagraph(
                                  label: context.l10n.technicalEvidence,
                                  value: technical,
                                ),
                              if (fundamental != null)
                                _ReasoningParagraph(
                                  label: context.l10n.newsCalendarContext,
                                  value: fundamental,
                                ),
                              if (_citations.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${context.l10n.citedSources.toUpperCase()}:',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    for (final citation in _citations)
                                      ActionChip(
                                        avatar: const Icon(
                                          Icons.article_outlined,
                                          size: 16,
                                        ),
                                        label: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 240,
                                          ),
                                          child: Text(
                                            citation.$1,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        onPressed: citation.$2 == null
                                            ? null
                                            : () => widget.onOpenUrl(
                                                citation.$2!,
                                              ),
                                      ),
                                  ],
                                ),
                              ],
                              if (risk != null)
                                _ReasoningParagraph(
                                  label: context.l10n.mainRisk,
                                  value: risk,
                                ),
                              if (_conditions.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                Text(
                                  '${context.l10n.reassessIf}:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                for (final condition in _conditions)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '• ',
                                          style: TextStyle(color: muted),
                                        ),
                                        Expanded(
                                          child: Text(
                                            condition,
                                            style: TextStyle(
                                              color: muted,
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey('copy-full-reasoning-text'),
                            onPressed: _copyText,
                            icon: const Icon(Icons.copy_rounded),
                            label: Text(context.l10n.copyText),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey('copy-full-reasoning-image'),
                            onPressed: _copyingImage ? null : _copyImage,
                            icon: _copyingImage
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.image_outlined),
                            label: Text(context.l10n.copyImage),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _notice == null
                      ? const SizedBox.shrink()
                      : _CopyNotice(
                          key: ValueKey(_notice),
                          message: _notice!,
                          isError: _noticeIsError,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyNotice extends StatelessWidget {
  const _CopyNotice({super.key, required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isError ? colors.error : colors.primary;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.surfaceContainerHigh,
        elevation: 8,
        shadowColor: Colors.black54,
        child: Container(
          key: const ValueKey('copy-reasoning-popup'),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_rounded,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasoningParagraph extends StatelessWidget {
  const _ReasoningParagraph({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Text.rich(
      TextSpan(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.55,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

/// Track color for the risk and confidence meters. The plain muted surface is
/// almost the same as the card in dark mode, so the range looked like it was
/// floating; a light tint of the text color keeps it visible in both themes.
Color _meterTrackColor(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    colors.onSurface.withValues(alpha: .10),
    colors.surfaceContainerHighest,
  );
}

/// Three-segment risk meter shown above the confidence range, as on the web:
/// 1 green = low, 2 yellow = moderate, 3 red = high; unused segments are muted.
class _RiskLevelBars extends StatelessWidget {
  const _RiskLevelBars({required this.level, required this.semanticLabel});

  final int level;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final filled = switch (level) {
      1 => const Color(0xFF22C55E),
      2 => const Color(0xFFEAB308),
      _ => const Color(0xFFEF4444),
    };
    final empty = _meterTrackColor(context);
    return Semantics(
      key: const ValueKey('analysis-risk-bars'),
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        children: [
          for (var n = 1; n <= 3; n++) ...[
            if (n > 1) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: n <= level ? filled : empty,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceRange extends StatelessWidget {
  const _ConfidenceRange({required this.minimum, required this.maximum});

  final double minimum;
  final double maximum;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final start = minimum.clamp(0.0, 1.0);
          final end = maximum.clamp(start, 1.0);
          return SizedBox(
            height: 20,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _meterTrackColor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * start,
                  width: constraints.maxWidth * (end - start),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('0%', style: TextStyle(fontSize: 10)),
          Text('100%', style: TextStyle(fontSize: 10)),
        ],
      ),
    ],
  );
}

class _DirectionalGaugePainter extends CustomPainter {
  const _DirectionalGaugePainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 12);
    final radius = math.min(size.width / 2 - 28, size.height - 24);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gauge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      // Saturated at both ends so the extremes read as unambiguously
      // bearish / bullish (web: deep red -> vivid green, not pastel).
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFB91C1C),
          Color(0xFFF97316),
          Color(0xFFFACC15),
          Color(0xFF4ADE80),
          Color(0xFF15803D),
        ],
      ).createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi, false, gauge);

    final angle = math.pi + math.pi * value.clamp(0.0, 1.0);
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius - 18);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 12, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF111318));
  }

  @override
  bool shouldRepaint(covariant _DirectionalGaugePainter oldDelegate) =>
      oldDelegate.value != value;
}

// ignore: unused_element
class _LegacyHeaderCard extends StatelessWidget {
  const _LegacyHeaderCard({
    required this.analysis,
    required this.biasColor,
    required this.biasLabel,
    required this.isExpired,
    required this.muted,
    required this.isPro,
  });

  final Analysis analysis;
  final Color biasColor;
  final String biasLabel;
  final bool isExpired;
  final Color muted;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final condition = _marketConditionMeta(context, analysis.marketCondition);
    final confidenceReason =
        (isPro ? analysis.uncertaintyNotes : analysis.whyReason)?.trim();
    final risk = (analysis.riskLevel ?? '').trim().toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (
      riskLabel,
      riskColor,
    ) = risk.contains('high') || risk.contains('tinggi')
        ? (
            context.l10n.riskHighLabel,
            isDark ? AppColors.bearishDark : AppColors.bearishLight,
          )
        : risk.contains('low') || risk.contains('rendah')
        ? (
            context.l10n.riskLowLabel,
            isDark ? AppColors.bullishDark : AppColors.bullishLight,
          )
        : (
            context.l10n.riskModerateLabel,
            isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          );
    return Card(
      key: const ValueKey('analysis-result-header'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusChip(label: biasLabel, color: biasColor, glow: isDark),
                _StatusChip(
                  key: const ValueKey('analysis-risk-chip'),
                  label: riskLabel,
                  color: riskColor,
                ),
                _StatusChip(label: analysis.timeframe, color: muted),
                if (condition != null)
                  _StatusChip(
                    label: condition.$1,
                    color: condition.$2,
                    icon: condition.$3,
                  ),
              ],
            ),

            if (analysis.confidenceMin != null &&
                analysis.confidenceMax != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.aiConfidence,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        Text(
                          '${analysis.confidenceMin}% – '
                          '${analysis.confidenceMax}%',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ((analysis.confidenceMax ?? 0) / 100)
                            .clamp(0, 1)
                            .toDouble(),
                        minHeight: 8,
                        backgroundColor: muted.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(biasColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: isExpired
                      ? Theme.of(context).colorScheme.error
                      : muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isExpired
                        ? context.l10n.analysisPeriodEnded
                        : context.l10n.analysisWindowActiveUntil(
                            DateFormat(
                              'd MMM yyyy, HH:mm',
                            ).format(analysis.validUntil.toLocal()),
                          ),
                    style: TextStyle(
                      color: isExpired
                          ? Theme.of(context).colorScheme.error
                          : muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              context.l10n.analysisCreatedAt(
                DateFormat(
                  'd MMM yyyy, HH:mm',
                ).format(analysis.createdAt.toLocal()),
              ),
              style: TextStyle(color: muted, fontSize: 12),
            ),

            if (confidenceReason?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              const Divider(),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: const ValueKey('analysis-confidence-reason'),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  leading: Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    context.l10n.whyNotHigherConfidence,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        confidenceReason!,
                        style: const TextStyle(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.glow = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.38)),
      boxShadow: AppColors.signalGlow(color, enabled: glow),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

(String, Color, IconData)? _marketConditionMeta(
  BuildContext context,
  String? value,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (value?.trim().toLowerCase()) {
    'trending_up' => (
      context.l10n.trendingUp,
      isDark ? AppColors.bullishDark : AppColors.bullishLight,
      Icons.trending_up_rounded,
    ),
    'trending_down' => (
      context.l10n.trendingDown,
      isDark ? AppColors.bearishDark : AppColors.bearishLight,
      Icons.trending_down_rounded,
    ),
    'ranging' => (
      context.l10n.rangingMarket,
      isDark ? AppColors.neutralDark : AppColors.neutralLight,
      Icons.swap_horiz_rounded,
    ),
    'volatile' => (
      context.l10n.volatileMarket,
      isDark ? AppColors.neutralDark : AppColors.neutralLight,
      Icons.bolt_rounded,
    ),
    _ => null,
  };
}

// =============================================================================
// BEGINNER EXPLANATION
// =============================================================================

class _BeginnerMeaningCard extends StatelessWidget {
  const _BeginnerMeaningCard({
    required this.analysis,
    required this.biasLabel,
    required this.biasColor,
  });

  final Analysis analysis;
  final String biasLabel;
  final Color biasColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final bias = (analysis.tradingBias ?? '').toLowerCase();
    final direction = bias.contains('bull') || bias == 'buy'
        ? context.l10n.directionUp
        : bias.contains('bear') || bias == 'sell'
        ? context.l10n.directionDown
        : context.l10n.directionNeutral;

    final preferred = analysis.tradePlan?.preferredSide;

    late final String action;

    if (preferred == TradePlanPreferredSideEnum.buy) {
      action = context.l10n.beginnerBuyAction;
    } else if (preferred == TradePlanPreferredSideEnum.sell) {
      action = context.l10n.beginnerSellAction;
    } else {
      action = context.l10n.beginnerWaitAction;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, size: 19),
              SizedBox(width: 8),
              Text(
                context.l10n.whatDoesItMean,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: biasColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.l10n.biasMeaning(biasLabel, direction),
                  style: const TextStyle(fontSize: 12.5, height: 1.45),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            action,
            style: TextStyle(color: muted, fontSize: 12.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _EvidenceSummary extends StatelessWidget {
  const _EvidenceSummary({required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final evidence = <(IconData, String, String)>[];
    final fundamental = analysis.keyDriversFundamental?.trim();
    final contextSnapshot = analysis.fundamentalContext;
    if (fundamental?.isNotEmpty == true) {
      evidence.add((
        Icons.calendar_month_outlined,
        l10n.fundamentalDrivers,
        fundamental!,
      ));
    } else if (contextSnapshot != null) {
      evidence.add((
        Icons.calendar_month_outlined,
        l10n.fundamentalDrivers,
        l10n.fundamentalEvidenceSummary(
          contextSnapshot.newsItems.length,
          contextSnapshot.calendarEvents.length,
        ),
      ));
    }

    final technical = analysis.keyDriversTechnical?.trim();
    if (technical?.isNotEmpty == true) {
      evidence.add((
        Icons.analytics_outlined,
        l10n.technicalDrivers,
        technical!,
      ));
    } else if (analysis.techBuyCount != null ||
        analysis.techNeutralCount != null ||
        analysis.techSellCount != null) {
      evidence.add((
        Icons.analytics_outlined,
        l10n.technicalDrivers,
        '${l10n.buy} ${analysis.techBuyCount ?? 0} · '
            '${l10n.neutral} ${analysis.techNeutralCount ?? 0} · '
            '${l10n.sell} ${analysis.techSellCount ?? 0}',
      ));
    }

    final marketContext = analysis.marketContext?.trim();
    final reason = analysis.whyReason?.trim();
    final third = marketContext?.isNotEmpty == true ? marketContext : reason;
    if (third?.isNotEmpty == true) {
      evidence.add((Icons.public_rounded, l10n.marketContext, third!));
    }

    return Card(
      key: const ValueKey('analysis-evidence-summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.marketEvidence,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 10),
            if (evidence.isEmpty)
              Text(
                l10n.marketEvidenceDescription,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final item in evidence.take(3)) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$1, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${item.$2}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: item.$3),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
                if (item != evidence.take(3).last) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MARKET SNAPSHOT
// =============================================================================

class _MarketSnapshotCard extends StatelessWidget {
  const _MarketSnapshotCard({super.key, required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final bullish = analysis.techBuyCount ?? 0;
    final bearish = analysis.techSellCount ?? 0;
    final neutral = analysis.techNeutralCount ?? 0;
    final total = bullish + bearish + neutral;
    final rawBias = (analysis.tradingBias ?? '').toLowerCase();
    final isBullish = total > 0
        ? bullish > bearish && bullish > neutral
        : rawBias.contains('bull') || rawBias == 'buy';
    final isBearish = total > 0
        ? bearish > bullish && bearish > neutral
        : rawBias.contains('bear') || rawBias == 'sell';
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = isBullish
        ? (dark ? AppColors.bullishDark : AppColors.bullishLight)
        : isBearish
        ? (dark ? AppColors.bearishDark : AppColors.bearishLight)
        : Theme.of(context).colorScheme.primary;
    final direction = isBullish
        ? context.l10n.marketContextLeaningBullish
        : isBearish
        ? context.l10n.marketContextLeaningBearish
        : context.l10n.marketContextLeaningNeutral;
    final side = isBullish
        ? context.l10n.buy.toUpperCase()
        : isBearish
        ? context.l10n.sell.toUpperCase()
        : context.l10n.waitLabel.toUpperCase();
    final summary = total == 0
        ? (analysis.marketContext?.trim().isNotEmpty == true
              ? analysis.marketContext!.trim()
              : context.l10n.analysisSnapshotDescription)
        : isBullish
        ? context.l10n.marketContextIndicatorSummaryBullish(
            bullish,
            total,
            bearish,
            neutral,
          )
        : isBearish
        ? context.l10n.marketContextIndicatorSummaryBearish(
            bearish,
            total,
            bullish,
            neutral,
          )
        : context.l10n.marketContextIndicatorSummaryNeutral(
            total,
            bullish,
            bearish,
            neutral,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: dark ? 0.16 : 0.08),
          Theme.of(context).colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.explore_outlined, color: accent, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.marketContextSummaryTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 7,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          direction,
                          style: TextStyle(
                            color: accent,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '($side)',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.55,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CHART
// =============================================================================

class _ChartCard extends StatefulWidget {
  const _ChartCard({
    required this.analysis,
    required this.candles,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onOpenTradingView,
  });

  final Analysis analysis;
  final List<MarketCandle> candles;

  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onOpenTradingView;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

enum _ChartShareAction { copy, save, share }

class _ChartCardState extends State<_ChartCard> {
  final _captureKey = GlobalKey();
  bool _busy = false;

  Analysis get analysis => widget.analysis;
  List<MarketCandle> get candles => widget.candles;
  bool get isLoading => widget.isLoading;
  String? get error => widget.error;
  VoidCallback get onRetry => widget.onRetry;
  VoidCallback get onOpenTradingView => widget.onOpenTradingView;

  Future<Uint8List> _capturePng() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('Chart is unavailable');
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('Chart encoding failed');
    return watermarkPng(
      data.buffer.asUint8List(),
      attribution: exportAttribution(
        instrument: analysis.instrument,
        timeframe: analysis.timeframe,
        analysisId: analysis.id,
      ),
    );
  }

  String get _fileStem {
    final instrument = analysis.instrument.replaceAll(
      RegExp(r'[^A-Za-z0-9]'),
      '',
    );
    return 'tradepilot-$instrument-${analysis.timeframe}';
  }

  Future<void> _handleShare(_ChartShareAction action, Rect shareOrigin) async {
    if (_busy) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    void notify(String message) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    setState(() => _busy = true);
    try {
      final bytes = await _capturePng();
      switch (action) {
        case _ChartShareAction.copy:
          await _reasoningClipboard.invokeMethod<void>('copyImage', bytes);
          notify(l10n.chartImageCopied);
        case _ChartShareAction.save:
          await Gal.putImageBytes(bytes, name: _fileStem);
          notify(l10n.chartImageSaved);
        case _ChartShareAction.share:
          final file = File('${Directory.systemTemp.path}/$_fileStem.png');
          await file.writeAsBytes(bytes, flush: true);
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'image/png')],
              sharePositionOrigin: shareOrigin,
            ),
          );
      }
    } catch (_) {
      notify(l10n.chartImageFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = context.watch<MarketProvider>().quotes[analysis.instrument];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(
              key: _captureKey,
              child: ColoredBox(
                color:
                    Theme.of(context).cardTheme.color ??
                    colors.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.candlestick_chart_rounded,
                            size: 19,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.priceChart,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    '${analysis.instrument} • ${analysis.timeframe}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (quote != null)
                                    Text(
                                      '${quote.price.toStringAsFixed(2)} '
                                      '${quote.changePercent >= 0 ? '+' : ''}'
                                      '${quote.changePercent.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: quote.changePercent >= 0
                                            ? (isDark
                                                  ? AppColors.bullishDark
                                                  : AppColors.bullishLight)
                                            : (isDark
                                                  ? AppColors.bearishDark
                                                  : AppColors.bearishLight),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.openFullChart,
                          onPressed: onOpenTradingView,
                          icon: const Icon(Icons.open_in_new_rounded, size: 19),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (error != null && candles.isEmpty)
                      ErrorBanner(
                        message: error,
                        onRetry: onRetry,
                        retryLabel: context.l10n.tryAgain,
                      )
                    else
                      AnalysisLevelsChart(
                        candles: candles,
                        tradePlan: analysis.tradePlan,
                        tradingBias: analysis.tradingBias,
                        currentPrice: quote?.price,
                        isLoading: isLoading,
                      ),
                  ],
                ),
              ),
            ),
            if (candles.length >= 2) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (buttonContext) =>
                      PopupMenuButton<_ChartShareAction>(
                        enabled: !_busy,
                        tooltip: context.l10n.shareChart,
                        onSelected: (action) {
                          final box =
                              buttonContext.findRenderObject() as RenderBox;
                          _handleShare(
                            action,
                            box.localToGlobal(Offset.zero) & box.size,
                          );
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _ChartShareAction.copy,
                            child: ListTile(
                              leading: const Icon(Icons.copy_rounded),
                              title: Text(context.l10n.copyAnalysisImage),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: _ChartShareAction.save,
                            child: ListTile(
                              leading: const Icon(Icons.download_rounded),
                              title: Text(context.l10n.savePng),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: _ChartShareAction.share,
                            child: ListTile(
                              leading: const Icon(Icons.ios_share_rounded),
                              title: Text(context.l10n.shareImage),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        child: IgnorePointer(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: _busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.image_outlined, size: 18),
                            label: Text(context.l10n.shareChart),
                            iconAlignment: IconAlignment.start,
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FUNDAMENTAL SNAPSHOT
// =============================================================================

enum _FundamentalView { news, calendar }

class _FundamentalSnapshotCard extends StatefulWidget {
  const _FundamentalSnapshotCard({
    super.key,
    required this.analysis,
    required this.refreshed,
    required this.refreshing,
    required this.onRefresh,
    required this.onLearn,
    required this.onOpenUrl,
  });

  final Analysis analysis;
  final RefreshFundamentalsResponse? refreshed;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onLearn;
  final ValueChanged<String> onOpenUrl;

  @override
  State<_FundamentalSnapshotCard> createState() =>
      _FundamentalSnapshotCardState();
}

class _FundamentalSnapshotCardState extends State<_FundamentalSnapshotCard> {
  _FundamentalView? _selected;

  @override
  Widget build(BuildContext context) {
    final contextData = widget.analysis.fundamentalContext;

    if (contextData == null) {
      return const SizedBox.shrink();
    }

    final news = contextData.newsItems.take(5).toList();
    final events = contextData.calendarEvents.take(5).toList();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.newspaper_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.l10n.fundamentalContext,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                );
                final refresh = OutlinedButton.icon(
                  onPressed: widget.refreshing ? null : widget.onRefresh,
                  icon: widget.refreshing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(context.l10n.refreshFundamentals),
                );
                final actions = Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    refresh,
                    TextButton.icon(
                      key: const ValueKey('fundamental-learn'),
                      onPressed: widget.onLearn,
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(context.l10n.learn),
                    ),
                  ],
                );
                if (constraints.maxWidth < 350 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 10), actions],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 10),
                    actions,
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.fundamentalContextDescription,
              style: TextStyle(color: muted, fontSize: 12),
            ),
            if (widget.refreshed != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.refreshed!.drift.missingCitations.isEmpty
                      ? context.l10n.fundamentalDriftNone
                      : context.l10n.fundamentalDriftSome(
                          widget.refreshed!.drift.missingCitations.length,
                          widget.refreshed!.drift.totalCitations,
                        ),
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttons = [
                  _viewButton(
                    context,
                    view: _FundamentalView.news,
                    label: context.l10n.recentNews,
                    icon: Icons.article_outlined,
                  ),
                  _viewButton(
                    context,
                    view: _FundamentalView.calendar,
                    label: context.l10n.economicCalendar,
                    icon: Icons.event_available_outlined,
                  ),
                ];
                if (constraints.maxWidth < 330 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buttons[0],
                      const SizedBox(height: 8),
                      buttons[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 8),
                    Expanded(child: buttons[1]),
                  ],
                );
              },
            ),
            if (_selected == _FundamentalView.news) ...[
              const SizedBox(height: 14),
              if (news.isEmpty)
                Text(context.l10n.latestDataUnavailable)
              else
                for (final item in news)
                  _FundamentalRow(
                    title: item.title,
                    meta: '${item.source_}  ${_publishedAgo(item.publishedAt)}',
                    onTap: item.url?.trim().isNotEmpty == true
                        ? () => widget.onOpenUrl(item.url!)
                        : null,
                  ),
            ],
            if (_selected == _FundamentalView.calendar) ...[
              const SizedBox(height: 14),
              if (events.isEmpty)
                Text(
                  context.l10n.noUpcomingEconomicEvents,
                  style: TextStyle(color: muted),
                )
              else
                for (final event in events)
                  _FundamentalRow(
                    title: event.event,
                    meta:
                        '${event.currency} • ${event.date}'
                        ' ${event.time}'
                        ' • ${event.impact}',
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _viewButton(
    BuildContext context, {
    required _FundamentalView view,
    required String label,
    required IconData icon,
  }) {
    final selected = _selected == view;
    final primary = Theme.of(context).colorScheme.primary;
    return OutlinedButton(
      key: ValueKey('fundamental-${view.name}'),
      onPressed: () => setState(() => _selected = selected ? null : view),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        alignment: Alignment.centerLeft,
        backgroundColor: selected ? primary.withValues(alpha: .18) : null,
        side: BorderSide(
          color: selected
              ? primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Icon(
            selected ? Icons.keyboard_arrow_down : Icons.chevron_right,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _publishedAgo(DateTime value) {
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inDays > 0) {
      return context.l10n.publishedDaysAgo(difference.inDays);
    }
    if (difference.inHours > 0) {
      return context.l10n.publishedHoursAgo(difference.inHours);
    }
    if (difference.inMinutes > 0) {
      return context.l10n.publishedMinutesAgo(difference.inMinutes);
    }
    return context.l10n.publishedJustNow;
  }
}

class _FundamentalRow extends StatelessWidget {
  const _FundamentalRow({required this.title, required this.meta, this.onTap});

  final String title;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(meta, style: TextStyle(color: muted, fontSize: 11)),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new_rounded, size: 15),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// OUTCOME
// =============================================================================

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    final bearish = isDark ? AppColors.bearishDark : AppColors.bearishLight;

    final neutral = isDark ? AppColors.neutralDark : AppColors.neutralLight;

    final status = analysis.outcomeStatus;

    late final String label;
    late final String explanation;
    late final IconData icon;
    late final Color color;

    if (status == AnalysisOutcomeStatusEnum.pending) {
      label = context.l10n.outcomePendingLabel;
      explanation = context.l10n.outcomePendingBody;
      icon = Icons.schedule_rounded;
      color = neutral;
    } else if (status == AnalysisOutcomeStatusEnum.tp1Hit) {
      label = context.l10n.outcomeTp1Label;
      explanation = context.l10n.outcomeTp1Body;
      icon = Icons.trending_up_rounded;
      color = bullish;
    } else if (status == AnalysisOutcomeStatusEnum.tp2Hit) {
      label = context.l10n.outcomeTp2Label;
      explanation = context.l10n.outcomeTp2Body;
      icon = Icons.rocket_launch_outlined;
      color = bullish;
    } else if (status == AnalysisOutcomeStatusEnum.slHit) {
      label = context.l10n.outcomeSlLabel;
      explanation = context.l10n.outcomeSlBody;
      icon = Icons.trending_down_rounded;
      color = bearish;
    } else if (status == AnalysisOutcomeStatusEnum.expired) {
      label = context.l10n.outcomeExpiredLabel;
      explanation = context.l10n.outcomeExpiredBody;
      icon = Icons.timer_off_outlined;
      color = neutral;
    } else if (status == AnalysisOutcomeStatusEnum.invalidated) {
      label = context.l10n.outcomeInvalidatedLabel;
      explanation = context.l10n.outcomeInvalidatedBody;
      icon = Icons.warning_amber_rounded;
      color = bearish;
    } else {
      label = context.l10n.outcomeUnknownLabel;
      explanation = context.l10n.outcomeUnknownBody;
      icon = Icons.info_outline;
      color = muted;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    explanation,
                    style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
                  ),
                  if (analysis.outcomeResolvedAt != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      DateFormat(
                        'd MMM yyyy, HH:mm',
                      ).format(analysis.outcomeResolvedAt!.toLocal()),
                      style: TextStyle(color: muted, fontSize: 10.5),
                    ),
                  ],
                ],
              ),
            ),

            if (status == AnalysisOutcomeStatusEnum.pending)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

Color _signalColor(BuildContext context, String signal) {
  final value = signal.toLowerCase();
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (value.contains('buy') || value.contains('bull')) {
    return dark ? AppColors.bullishDark : AppColors.bullishLight;
  }
  if (value.contains('sell') || value.contains('bear')) {
    return dark ? AppColors.bearishDark : AppColors.bearishLight;
  }
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

String _number(double? value, {int decimals = 2}) =>
    value == null ? '—' : value.toStringAsFixed(decimals);

String _summarySignal(int buy, int neutral, int sell) {
  if (buy > sell && buy > neutral) return 'Leaning Bullish';
  if (sell > buy && sell > neutral) return 'Leaning Bearish';
  return 'Neutral';
}

class _TechnicalIndicatorsCard extends StatelessWidget {
  const _TechnicalIndicatorsCard({
    required this.technical,
    required this.timeframe,
    required this.showRawSignals,
    required this.showSummary,
  });

  final BeginnerTechnicalSnapshot technical;
  final String timeframe;
  final bool showRawSignals;
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    final movingAverages = [...technical.movingAverages]
      ..sort((a, b) {
        final byType = a.type.compareTo(b.type);
        return byType != 0 ? byType : a.period.compareTo(b.period);
      });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.liveTechnicalIndicators,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(
            context.l10n.liveTechnicalDisclaimer,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: context.l10n.currentPrice(''),
                value: _number(technical.lastClose),
              ),
              _MetricChip(
                label: context.l10n.lastBar,
                value: '${technical.change1dPercent.toStringAsFixed(2)}%',
              ),
              _MetricChip(
                label: context.l10n.twentyBars,
                value: '${technical.change20dPercent.toStringAsFixed(2)}%',
              ),
            ],
          ),
          if (showSummary) ...[
            const SizedBox(height: 14),
            _SignalSummary(
              title: context.l10n.signalSummary,
              signal: technical.overallSignal,
              buy: technical.buyCount,
              neutral: technical.neutralCount,
              sell: technical.sellCount,
              showRawSignal: showRawSignals,
            ),
            const SizedBox(height: 8),
            _SignalSummary(
              title: 'Oscillator',
              signal: _summarySignal(
                technical.oscillatorBuyCount,
                technical.oscillatorNeutralCount,
                technical.oscillatorSellCount,
              ),
              buy: technical.oscillatorBuyCount,
              neutral: technical.oscillatorNeutralCount,
              sell: technical.oscillatorSellCount,
              showRawSignal: showRawSignals,
            ),
            const SizedBox(height: 8),
            _SignalSummary(
              title: 'Moving Average',
              signal: _summarySignal(
                technical.movingAverageBuyCount,
                technical.movingAverageNeutralCount,
                technical.movingAverageSellCount,
              ),
              buy: technical.movingAverageBuyCount,
              neutral: technical.movingAverageNeutralCount,
              sell: technical.movingAverageSellCount,
              showRawSignal: showRawSignals,
            ),
          ],
          const Divider(height: 28),
          ExpansionTile(
            key: const ValueKey('oscillator-indicators'),
            initiallyExpanded: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'Oscillator · $timeframe',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _SignalScaleBar(
                buy: technical.oscillatorBuyCount,
                neutral: technical.oscillatorNeutralCount,
                sell: technical.oscillatorSellCount,
              ),
            ),
            children: [
              _IndicatorRow(
                label: 'RSI (14)',
                value: _number(technical.rsi),
                signal: technical.rsiSignal,
                showSignal: showRawSignals,
              ),
              _IndicatorRow(
                label: 'MACD (12,26)',
                value: _number(technical.macdValue, decimals: 4),
                signal: technical.macdAction,
                showSignal: showRawSignals,
              ),
              _IndicatorRow(
                label: 'Stochastic %K',
                value: _number(technical.stochasticK),
                signal: technical.stochasticSignal,
                showSignal: showRawSignals,
              ),
              _IndicatorRow(
                label: 'Bollinger',
                value:
                    '${_number(technical.bollingerLower)}–${_number(technical.bollingerUpper)}',
                signal: technical.bollingerSignal,
                showSignal: showRawSignals,
              ),
            ],
          ),
          if (movingAverages.isNotEmpty) ...[
            const Divider(height: 28),
            ExpansionTile(
              key: const ValueKey('moving-average-indicators'),
              initiallyExpanded: true,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Text(
                'Moving Averages',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _SignalScaleBar(
                  buy: technical.movingAverageBuyCount,
                  neutral: technical.movingAverageNeutralCount,
                  sell: technical.movingAverageSellCount,
                ),
              ),
              children: [
                for (final average in movingAverages)
                  _IndicatorRow(
                    label: '${average.type.toUpperCase()} (${average.period})',
                    value: _number(average.value),
                    signal: average.signal,
                    showSignal: showRawSignals,
                  ),
              ],
            ),
          ],
          if (technical.dataPoints > 0) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.technicalDataPoints(timeframe, technical.dataPoints),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _SignalSummary extends StatelessWidget {
  const _SignalSummary({
    required this.title,
    required this.signal,
    required this.buy,
    required this.neutral,
    required this.sell,
    required this.showRawSignal,
  });
  final String title;
  final String signal;
  final int buy;
  final int neutral;
  final int sell;
  final bool showRawSignal;

  @override
  Widget build(BuildContext context) {
    final normalized = signal.toLowerCase();
    final signalColor = _signalColor(context, signal);
    final displaySignal = showRawSignal
        ? signal
        : normalized.contains('buy') || normalized.contains('bull')
        ? context.l10n.beginnerBullish
        : normalized.contains('sell') || normalized.contains('bear')
        ? context.l10n.beginnerBearish
        : context.l10n.beginnerWait;
    final signalBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: signalColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: signalColor.withValues(alpha: 0.32)),
      ),
      child: Text(
        displaySignal,
        style: TextStyle(
          color: signalColor,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: signalColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: signalColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 6), signalBadge],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 8),
                  signalBadge,
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _SignalScaleBar(buy: buy, neutral: neutral, sell: sell),
        ],
      ),
    );
  }
}

class _SignalScaleBar extends StatelessWidget {
  const _SignalScaleBar({
    required this.buy,
    required this.neutral,
    required this.sell,
  });

  final int buy;
  final int neutral;
  final int sell;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bullish = dark ? AppColors.bullishDark : AppColors.bullishLight;
    final bearish = dark ? AppColors.bearishDark : AppColors.bearishLight;
    final neutralColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final total = buy + neutral + sell;
    final position = total == 0 ? 0.5 : ((buy - sell) / total + 1) / 2;

    return Semantics(
      label: '$sell Bearish, $neutral Neutral, $buy Bullish',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              key: const ValueKey('signal-scale-bar'),
              height: 18,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: ColoredBox(color: bearish)),
                            Expanded(
                              child: ColoredBox(
                                color: bearish.withValues(alpha: 0.45),
                              ),
                            ),
                            Expanded(
                              child: ColoredBox(
                                color: neutralColor.withValues(alpha: 0.35),
                              ),
                            ),
                            Expanded(
                              child: ColoredBox(
                                color: bullish.withValues(alpha: 0.45),
                              ),
                            ),
                            Expanded(child: ColoredBox(color: bullish)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - 14) * position,
                    top: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Bearish ($sell)',
                style: TextStyle(color: bearish, fontSize: 10.5),
              ),
              Text(
                'Neutral ($neutral)',
                style: TextStyle(color: neutralColor, fontSize: 10.5),
              ),
              Text(
                'Bullish ($buy)',
                style: TextStyle(color: bullish, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({
    required this.label,
    required this.value,
    required this.signal,
    required this.showSignal,
  });
  final String label;
  final String value;
  final String signal;
  final bool showSignal;

  @override
  Widget build(BuildContext context) {
    final color = _signalColor(context, signal);
    return Semantics(
      label: '$label, $value, $signal',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              key: ValueKey('indicator-signal-$label'),
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            if (showSignal) ...[
              const SizedBox(width: 8),
              Text(
                signal,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _OpportunityRiskCard extends StatelessWidget {
  const _OpportunityRiskCard({required this.analysis});
  final Analysis analysis;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cards = <Widget>[
        if (analysis.opportunity?.trim().isNotEmpty == true)
          _InfoPanel(
            key: const ValueKey('analysis-opportunity'),
            title: context.l10n.opportunity,
            body: analysis.opportunity!,
            color: Theme.of(context).colorScheme.tertiary,
            icon: Icons.adjust_rounded,
          ),
        if (analysis.risk?.trim().isNotEmpty == true)
          _InfoPanel(
            key: const ValueKey('analysis-risk'),
            title: context.l10n.riskTitle,
            body: analysis.risk!,
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.shield_outlined,
          ),
      ];
      if (constraints.maxWidth >= 620 && cards.length == 2) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      }
      return Column(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            cards[index],
            if (index < cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    super.key,
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });
  final String title;
  final String body;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(AppColors.radius),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        iconColor: color,
        collapsedIconColor: color.withValues(alpha: 0.75),
        leading: Icon(icon, color: color, size: 19),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(body, style: const TextStyle(height: 1.45)),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
class _ExecutionInsightCard extends StatelessWidget {
  const _ExecutionInsightCard({required this.analysis});
  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final bias = (analysis.tradingBias ?? '').toLowerCase();
    final scenarioA = bias.contains('bull') || bias == 'buy'
        ? context.l10n.executionScenarioABullish
        : bias.contains('bear') || bias == 'sell'
        ? context.l10n.executionScenarioABearish
        : context.l10n.executionScenarioANeutral;

    return Card(
      child: ExpansionTile(
        key: const ValueKey('analysis-execution-insight'),
        initiallyExpanded: false,
        leading: Icon(
          Icons.lightbulb_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          context.l10n.executionInsight,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(context.l10n.executionInsightDescription),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          _scenario(context, context.l10n.executionScenarioALabel, scenarioA),
          _scenario(
            context,
            context.l10n.executionScenarioBLabel,
            context.l10n.executionScenarioBBody,
          ),
          _scenario(
            context,
            context.l10n.executionScenarioCLabel,
            context.l10n.executionScenarioCBody,
          ),
        ],
      ),
    );
  }

  Widget _scenario(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
            body,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
class _ScenariosCard extends StatelessWidget {
  const _ScenariosCard({
    // ignore: unused_element_parameter
    this.mainScenario,
    // ignore: unused_element_parameter
    this.alternativeScenario,
  });

  final String? mainScenario;
  final String? alternativeScenario;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: const ValueKey('analysis-scenarios'),
      initiallyExpanded: false,
      leading: Icon(
        Icons.route_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        context.l10n.scenariosTitle,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (mainScenario?.trim().isNotEmpty == true)
          _scenario(context, context.l10n.mainScenario, mainScenario!),
        if (alternativeScenario?.trim().isNotEmpty == true)
          _scenario(
            context,
            context.l10n.alternativeScenario,
            alternativeScenario!,
          ),
        _scenario(
          context,
          context.l10n.waitScenario,
          context.l10n.waitScenarioBody,
        ),
      ],
    ),
  );

  Widget _scenario(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
            body,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
class _ProAnalysisDetailsCard extends StatelessWidget {
  const _ProAnalysisDetailsCard({required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: const ValueKey('analysis-pro-details'),
      initiallyExpanded: false,
      leading: Icon(
        Icons.psychology_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        context.l10n.proAnalysisDetailsTitle,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(context.l10n.proAnalysisDetailsDescription),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (analysis.keyDriversTechnical?.trim().isNotEmpty == true)
          _detail(
            context,
            context.l10n.technicalDrivers,
            analysis.keyDriversTechnical!,
            Icons.query_stats_rounded,
          ),
        if (analysis.keyDriversFundamental?.trim().isNotEmpty == true)
          _detail(
            context,
            context.l10n.fundamentalDrivers,
            analysis.keyDriversFundamental!,
            Icons.newspaper_outlined,
          ),
        if (analysis.marketContext?.trim().isNotEmpty == true)
          _detail(
            context,
            context.l10n.marketContext,
            analysis.marketContext!,
            Icons.public_rounded,
          ),
      ],
    ),
  );

  Widget _detail(
    BuildContext context,
    String title,
    String body,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                body,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// =============================================================================
// GENERIC SECTION
// =============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TRADE PLAN
// =============================================================================

class _TradePlanCard extends StatelessWidget {
  const _TradePlanCard({
    required this.plan,
    required this.isDark,
    required this.onLearn,
  });

  final TradePlan plan;
  final bool isDark;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    final preferBuy = plan.preferredSide == TradePlanPreferredSideEnum.buy;

    final preferSell = plan.preferredSide == TradePlanPreferredSideEnum.sell;

    final wait = plan.preferredSide == TradePlanPreferredSideEnum.wait;

    final preferredLabel = preferBuy
        ? context.l10n.buy
        : preferSell
        ? context.l10n.sell
        : context.l10n.waitLabel;

    return Card(
      key: const ValueKey('suggested-levels-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final intro = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.adjust_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.l10n.tradingPlanTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.tradingPlanDisclaimer,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                );
                final actions = Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusChip(
                      label: context.l10n.suggestedSide(preferredLabel),
                      color: preferBuy
                          ? (isDark
                                ? AppColors.bullishDark
                                : AppColors.bullishLight)
                          : preferSell
                          ? (isDark
                                ? AppColors.bearishDark
                                : AppColors.bearishLight)
                          : Theme.of(context).colorScheme.primary,
                    ),
                    TextButton.icon(
                      key: const ValueKey('suggested-levels-learn'),
                      onPressed: onLearn,
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(context.l10n.learn),
                    ),
                  ],
                );
                final stack =
                    constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [intro, const SizedBox(height: 10), actions],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: intro),
                    const SizedBox(width: 12),
                    actions,
                  ],
                );
              },
            ),
            if (wait) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.awaitConfirmationNotice,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _SideCard(
              side: plan.buy,
              label: context.l10n.buyScenario,
              color: isDark ? AppColors.bullishDark : AppColors.bullishLight,
              icon: Icons.trending_up_rounded,
              highlighted: preferBuy,
            ),
            const SizedBox(height: 10),
            _SideCard(
              side: plan.sell,
              label: context.l10n.sellScenario,
              color: isDark ? AppColors.bearishDark : AppColors.bearishLight,
              icon: Icons.trending_down_rounded,
              highlighted: preferSell,
            ),
          ],
        ),
      ),
    );
  }
}

class _SideCard extends StatefulWidget {
  const _SideCard({
    required this.side,
    required this.label,
    required this.color,
    required this.icon,
    required this.highlighted,
  });

  final TradeSide side;
  final String label;
  final Color color;
  final IconData icon;
  final bool highlighted;

  @override
  State<_SideCard> createState() => _SideCardState();
}

class _SideCardState extends State<_SideCard> {
  bool _showRationale = false;

  static final _unavailablePattern = RegExp(
    r'^(?:n/a|na|—|-)$',
    caseSensitive: false,
  );
  static final _waitingWords = RegExp(
    r'\b(menunggu|tunggu|belum|pending|await|wait for|not available)\b',
    caseSensitive: false,
  );
  static final _riskRewardPattern = RegExp(r'\b1:\d+(?:\.\d+)?\b');

  bool _isUnavailable(String raw) => _unavailablePattern.hasMatch(raw.trim());

  /// A side whose levels are not usable yet (n/a, no digits, "wait for ..."
  /// or no R:R). It shows a placeholder instead of the raw text and cannot be
  /// copied as if it were an entry plan.
  bool get _pending {
    final side = widget.side;
    final fields = [
      side.entryZone,
      side.stopLoss,
      side.takeProfit1,
      side.takeProfit2,
    ];
    return fields.any(
          (raw) =>
              _isUnavailable(raw) ||
              !RegExp(r'\d').hasMatch(raw) ||
              _waitingWords.hasMatch(raw),
        ) ||
        _isUnavailable(side.riskRewardRatio) ||
        !_riskRewardPattern.hasMatch(side.riskRewardRatio);
  }

  String _shown(String raw, String replacement) =>
      _isUnavailable(raw) ? replacement : raw;

  Future<void> _copyLevels() async {
    final l10n = context.l10n;
    final text = [
      widget.label,
      '${l10n.entryZone}: ${widget.side.entryZone}',
      'Stop Loss: ${widget.side.stopLoss}',
      '${l10n.takeProfit1}: ${widget.side.takeProfit1}',
      '${l10n.takeProfit2}: ${widget.side.takeProfit2}',
      '${l10n.riskReward}: ${widget.side.riskRewardRatio}',
    ].join('\n');
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.levelsCopied)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.levelsCopyFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(
          color: widget.highlighted
              ? Theme.of(context).colorScheme.primary
              : border,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: ColoredBox(
              color: widget.color,
              child: const SizedBox(width: 3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, size: 18, color: widget.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_pending) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${context.l10n.fastPlanWaitTitle} ${context.l10n.fastPlanEntryPending}',
                      key: ValueKey('trade-plan-${widget.label}-pending'),
                      style: TextStyle(
                        color: context.adaptiveAmber,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                _PlanLevelRow(
                  label: context.l10n.entryZone,
                  value: _shown(
                    widget.side.entryZone,
                    context.l10n.fastPlanEntryPending,
                  ),
                ),
                _PlanLevelRow(
                  label: 'Stop Loss',
                  value: _shown(
                    widget.side.stopLoss,
                    context.l10n.fastPlanSlPending,
                  ),
                  valueColor: Theme.of(context).colorScheme.error,
                ),
                _PlanLevelRow(
                  label: context.l10n.takeProfit1,
                  value: _shown(
                    widget.side.takeProfit1,
                    context.l10n.fastPlanTp1Pending,
                  ),
                  valueColor: widget.color,
                ),
                _PlanLevelRow(
                  label: context.l10n.takeProfit2,
                  value: _shown(
                    widget.side.takeProfit2,
                    context.l10n.fastPlanTp2Pending,
                  ),
                  valueColor: widget.color,
                ),
                _PlanLevelRow(
                  label: context.l10n.riskReward,
                  value: _shown(
                    widget.side.riskRewardRatio,
                    context.l10n.fastPlanRrPending,
                  ),
                ),
                const Divider(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showRationale = !_showRationale),
                      style: TextButton.styleFrom(
                        foregroundColor: muted,
                        padding: EdgeInsets.zero,
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: Icon(
                        _showRationale
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      ),
                      label: Text(context.l10n.rationale),
                    ),
                    if (!_pending)
                      TextButton.icon(
                        key: ValueKey('copy-${widget.label}-levels'),
                        onPressed: _copyLevels,
                        style: TextButton.styleFrom(foregroundColor: muted),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text(context.l10n.copyLevels),
                      ),
                  ],
                ),
                if (_showRationale) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.side.rationale,
                    style: TextStyle(color: muted, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanLevelRow extends StatelessWidget {
  const _PlanLevelRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
