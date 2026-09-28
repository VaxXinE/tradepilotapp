import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../models/market_models.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/progression_provider.dart';
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
    if (analysis == null || _reanalyzing) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.analysisCreateFailed)),
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

  void _openGuide(ProgressionEvidenceStartInputGuideIdEnum guideId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MindsetScreen(initialGuideId: guideId)),
    );
  }

  Future<void> _openRiskMap(Analysis analysis) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .85,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: RiskMapCard(
              instrument: analysis.instrument,
              selectedTimeframe: _selectedTimeframe ?? analysis.timeframe,
              initiallyExpanded: true,
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
            content: Text(
              push.errorMessage ??
                  context.l10n.alertNeedsNotificationPermission,
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
            enabled
                ? context.l10n.alertEnableFailed
                : context.l10n.alertDisableFailed,
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
    final mainScenario = isPro ? analysis.baseCase : analysis.mainScenario;
    final alternativeScenario = isPro
        ? (isBearish ? analysis.bullishScenario : analysis.bearishScenario)
        : analysis.alternativeScenario;
    final invalidation = isPro
        ? analysis.invalidationConditions
        : analysis.failureConditions;

    // Saat embedded, detail ini menjadi bagian dari ListView halaman Analisis,
    // jadi ia tidak boleh menggulir (atau menarik-untuk-refresh) sendiri.
    final content = ListView(
      shrinkWrap: widget.embedded,
      physics: widget.embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.all(16),
      // Urutan mengikuti reading order web (Aset/Timeframe -> Bias -> Sinyal
      // -> Chart -> Saran Level -> Ukuran Posisi -> Alert -> Fundamental ->
      // Ringkasan Konteks Pasar -> Indikator Teknikal -> panel batal/peluang/
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
          Text(
            context.l10n.tradingPlanTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            context.l10n.tradingPlanDisclaimer,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),
          _TradePlanCard(plan: analysis.tradePlan!, isDark: isDark),
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
            onOpenUrl: _openExternalUrl,
          ),
          const SizedBox(height: 10),
        ],
        Card(
          child: ExpansionTile(
            key: const ValueKey('analysis-market-snapshot'),
            initiallyExpanded: true,
            leading: Icon(
              Icons.query_stats_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              context.l10n.analysisSnapshotTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: Text(context.l10n.analysisSnapshotDescription),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [_MarketSnapshotCard(analysis: analysis)],
          ),
        ),

        if (analysis.tradePlan != null) ...[
          const SizedBox(height: 14),
          AdaptivePositionPlanCard(analysis: analysis, candles: _candles),
        ],

        if (_technical != null) ...[
          const SizedBox(height: 10),
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

        if (invalidation?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 14),
          _InfoPanel(
            key: const ValueKey('analysis-invalidation'),
            title: context.l10n.analysisInvalidationTitle,
            body: invalidation!,
            icon: Icons.report_gmailerrorred_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
        ],

        if (analysis.opportunity?.trim().isNotEmpty == true ||
            analysis.risk?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          _OpportunityRiskCard(analysis: analysis),
        ],

        const SizedBox(height: 14),
        _ScenariosCard(
          mainScenario: mainScenario,
          alternativeScenario: alternativeScenario,
        ),

        if (isPro &&
            (analysis.keyDriversTechnical?.trim().isNotEmpty == true ||
                analysis.keyDriversFundamental?.trim().isNotEmpty == true ||
                analysis.marketContext?.trim().isNotEmpty == true)) ...[
          const SizedBox(height: 10),
          _ProAnalysisDetailsCard(analysis: analysis),
        ],

        const SizedBox(height: 12),
        _ExecutionInsightCard(analysis: analysis),

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
            _StatusChip(
              label: context.l10n.pending,
              color: muted,
              icon: Icons.hourglass_empty_rounded,
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
                              onTap: loading ? null : () => onSelect(timeframe),
                            ),
                          ),
                        if (onOpenRiskMap != null)
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              key: const Key('timeframe-risk-map-button'),
                              onPressed: loading ? null : onOpenRiskMap,
                              icon: const Icon(
                                Icons.monitor_heart_outlined,
                                size: 17,
                              ),
                              label: Text(context.l10n.riskMapTitle),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.changeTimeframeDescription,
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
                  icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                  label: Text(context.l10n.riskMapTitle),
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
  });

  final Analysis analysis;
  final Color biasColor;
  final String biasLabel;
  final bool isExpired;
  final Color muted;
  final bool isPro;
  final VoidCallback onLearn;

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
            const SizedBox(height: 4),
            Text(
              context.l10n.forTimeframe(analysis.timeframe),
              style: TextStyle(color: muted, fontSize: 12),
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
                      context.l10n.risk,
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
            const SizedBox(height: 16),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF8FA3), Color(0xFFFFE082), Color(0xFF6EE7B7)],
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
  const _MarketSnapshotCard({required this.analysis});

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final buy = analysis.techBuyCount;

    final sell = analysis.techSellCount;

    final neutral = analysis.techNeutralCount;

    final hasCounts = buy != null || sell != null || neutral != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 19),
              SizedBox(width: 8),
              Text(
                context.l10n.analysisSnapshotTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            context.l10n.analysisSnapshotDescription,
            style: TextStyle(color: muted, fontSize: 11),
          ),

          if (hasCounts) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CountTile(
                    label: context.l10n.buy,
                    value: buy ?? 0,
                    icon: Icons.north_east_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountTile(
                    label: context.l10n.sell,
                    value: sell ?? 0,
                    icon: Icons.south_east_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountTile(
                    label: context.l10n.neutral,
                    value: neutral ?? 0,
                    icon: Icons.remove_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

// =============================================================================
// CHART
// =============================================================================

class _ChartCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final quote = context.watch<MarketProvider>().quotes[analysis.instrument];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
    required this.onOpenUrl,
  });

  final Analysis analysis;
  final RefreshFundamentalsResponse? refreshed;
  final bool refreshing;
  final VoidCallback onRefresh;
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
                if (constraints.maxWidth < 350 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 10), refresh],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 10),
                    refresh,
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
                        '${event.time == null ? '' : ' ${event.time}'}'
                        '${event.impact == null ? '' : ' • ${event.impact}'}',
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
  if (buy > sell && buy > neutral) return 'Bullish';
  if (sell > buy && sell > neutral) return 'Bearish';
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
      label: '$sell Bearish, $neutral Netral, $buy Bullish',
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
                'Netral ($neutral)',
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
            title: context.l10n.risk,
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

class _ScenariosCard extends StatelessWidget {
  const _ScenariosCard({this.mainScenario, this.alternativeScenario});

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
  const _TradePlanCard({required this.plan, required this.isDark});

  final TradePlan plan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final preferBuy = plan.preferredSide == TradePlanPreferredSideEnum.buy;

    final preferSell = plan.preferredSide == TradePlanPreferredSideEnum.sell;

    final wait = plan.preferredSide == TradePlanPreferredSideEnum.wait;

    return Column(
      children: [
        if (wait) ...[
          Container(
            width: double.infinity,
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
          const SizedBox(height: 10),
        ],

        _SideCard(
          side: plan.buy,
          label: context.l10n.buy,
          color: isDark ? AppColors.bullishDark : AppColors.bullishLight,
          icon: Icons.trending_up_rounded,
          highlighted: preferBuy,
        ),

        const SizedBox(height: 10),

        _SideCard(
          side: plan.sell,
          label: context.l10n.sell,
          color: isDark ? AppColors.bearishDark : AppColors.bearishLight,
          icon: Icons.trending_down_rounded,
          highlighted: preferSell,
        ),
      ],
    );
  }
}

class _SideCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radius),
        side: BorderSide(
          color: highlighted ? color : border,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w900, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (highlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      context.l10n.primaryScenario,
                      style: TextStyle(
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _planRiskRewardLabel(side.riskRewardRatio),
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    constraints.maxWidth < 290 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final width = stack
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: width,
                      child: _LevelTile(
                        label: context.l10n.entryZone,
                        value: side.entryZone,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _LevelTile(
                        label: 'Stop Loss',
                        value: side.stopLoss,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _LevelTile(
                        label: 'TP1',
                        value: side.takeProfit1,
                        color: color,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _LevelTile(
                        label: 'TP2',
                        value: side.takeProfit2,
                        color: color,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            Text(
              side.rationale,
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

String _planRiskRewardLabel(String value) => value.trim().isEmpty
    ? 'R:R -'
    : value.toUpperCase().startsWith('R:R')
    ? value
    : 'R:R $value';

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 64),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: color.withValues(alpha: 0.28)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}
