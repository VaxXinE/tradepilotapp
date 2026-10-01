import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/market/market_sessions.dart';
import '../../../core/market/technical_summary_engine.dart';
import '../../../core/preferences/mental_checklist_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../models/market_models.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/credit_provider.dart';
import '../../../providers/market_provider.dart';
import '../../../providers/progression_provider.dart';
import '../../../providers/watchlist_provider.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/market_mini_chart.dart';
import '../../../widgets/cooling_off_breathing_dialog.dart';
import '../../../widgets/analysis_quota_dialog.dart';
import '../../analysis/analysis_detail_screen.dart';
import '../../../widgets/price_alert/price_alert_sheet.dart';
import '../../progression/progression_screen.dart';
import '../../../widgets/progression/progression_emblem.dart';
import '../../../core/market/analysis_instruments.dart';
import '../../../widgets/adaptive_plan_common.dart';
import '../../../widgets/context/context_indicator.dart';

// =============================================================================
// TIMEFRAMES
// =============================================================================

CreateAnalysisBodyTimeframeEnum _analysisTimeframe(String timeframe) {
  switch (timeframe) {
    case '1m':
      return CreateAnalysisBodyTimeframeEnum.n1m;

    case '5m':
      return CreateAnalysisBodyTimeframeEnum.n5m;

    case '15m':
      return CreateAnalysisBodyTimeframeEnum.n15m;

    case '30m':
      return CreateAnalysisBodyTimeframeEnum.n30m;

    case '1h':
      return CreateAnalysisBodyTimeframeEnum.n1h;

    case '4h':
      return CreateAnalysisBodyTimeframeEnum.n4h;

    case '1D':
      return CreateAnalysisBodyTimeframeEnum.n1d;

    case '1W':
      return CreateAnalysisBodyTimeframeEnum.n1w;

    default:
      return CreateAnalysisBodyTimeframeEnum.n1h;
  }
}

// =============================================================================
// ANALYZE TAB
// =============================================================================

class AnalyzeTab extends StatefulWidget {
  const AnalyzeTab({super.key, this.onNewAnalysis});

  final VoidCallback? onNewAnalysis;

  @override
  State<AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<AnalyzeTab> {
  final TextEditingController _contextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultSectionKey = GlobalKey();
  Analysis? _resultAnalysis;
  String? _analysisSubmitError;
  int _resultRevision = 0;
  String? _guardrailInstrument;
  List<Map<String, dynamic>> _guardrails = const [];
  final Map<String, int> _guardrailTelemetryIds = {};
  String? _checklistContext;
  final Set<int> _checkedMentalItems = {};
  String? _checklistEvidenceToken;
  DateTime? _checklistMinimumCompleteAt;
  bool _isAwardingChecklist = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final market = context.read<MarketProvider>();

      unawaited(market.loadSelectedMarketData());

      unawaited(market.loadQuotes());
    });
  }

  @override
  void dispose() {
    _contextController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<void> _refresh() async {
    final market = context.read<MarketProvider>();

    final analysis = context.read<AnalysisProvider>();

    await Future.wait([
      market.loadSelectedMarketData(force: true),
      market.loadQuotes(force: true),
      analysis.loadQuota(),
    ]);
  }

  // ===========================================================================
  // PRICE ALERT
  // ===========================================================================

  Future<void> _openPriceAlert(
    String instrument,
    LiveMarketQuote? quote,
  ) async {
    if (quote == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.alertNeedsLivePrice)));

      return;
    }

    final created = await showPriceAlertSheet(
      context: context,
      instrument: instrument,
      currentPrice: quote.price,
    );

    if (created == true && mounted) {
      unawaited(
        context.read<AuthProvider>().telemetry.track(
          AnalyticsEventBodyEventTypeEnum.alertArmed,
          path: '/analyze',
          metadata: {'instrument': instrument},
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.priceAlertCreated(instrument))),
      );
    }
  }

  // ===========================================================================
  // SUBMIT ANALYSIS
  // ===========================================================================

  Future<void> _submit() async {
    // The server only accepts verified instruments; say so here instead of
    // spending a request on a guaranteed HTTP 400.
    if (!isVerifiedAnalysisInstrument(
      context.read<MarketProvider>().selectedInstrument,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.instrumentNotVerifiedTitle}. '
            '${context.l10n.instrumentNotVerifiedDesc}',
          ),
        ),
      );
      return;
    }
    Map<String, dynamic>? coolingOff;
    for (final signal in _guardrails) {
      if (signal['kind'] == 'cooling_off') {
        coolingOff = signal;
        break;
      }
    }
    if (coolingOff != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => CoolingOffBreathingDialog(
          lossPercent: coolingOff?['lossPnlPercent']?.toString(),
          onWait: () => Navigator.of(dialogContext).pop(),
          onContinue: () {
            Navigator.of(dialogContext).pop();
            unawaited(_runAnalysis());
          },
        ),
      );
      return;
    }

    await _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final auth = context.read<AuthProvider>();

    final analysisProvider = context.read<AnalysisProvider>();

    final market = context.read<MarketProvider>();

    final note = _contextController.text.trim();

    if (_analysisSubmitError != null) {
      setState(() => _analysisSubmitError = null);
    }

    for (final signal in _guardrails) {
      unawaited(_logGuardrailProceed(auth, signal, market.selectedInstrument));
    }

    final result = await analysisProvider.createAnalysis(
      instrument: market.selectedInstrument,
      timeframe: _analysisTimeframe(market.selectedTimeframe),
      mode: CreateAnalysisBodyModeEnum.pro,
      userInputContext: note.isEmpty ? null : note,
    );

    if (!mounted) return;

    if (result == null) {
      final limit = analysisProvider.quotaLimit;
      if (limit != null) {
        setState(() => _analysisSubmitError = null);
        await showAnalysisQuotaDialog(context, limit);
      } else {
        setState(() => _analysisSubmitError = analysisProvider.errorMessage);
      }
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

    if (mounted) {
      unawaited(
        auth.telemetry.track(
          AnalyticsEventBodyEventTypeEnum.analysisCreated,
          path: '/analyze',
          metadata: {
            'instrument': result.instrument,
            'timeframe': market.selectedTimeframe,
          },
        ),
      );
      setState(() => _resultAnalysis = result);
      _scrollToResult();
    }
  }

  Future<void> _prepareChecklistEvidence(
    String instrument,
    String timeframe,
  ) async {
    if (mounted) {
      setState(() {
        _checkedMentalItems.clear();
        _checklistEvidenceToken = null;
        _checklistMinimumCompleteAt = null;
      });
    }
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .progression
          .startProgressionEvidence(
            progressionEvidenceStartInput: ProgressionEvidenceStartInput(
              (b) => b
                ..source_ = ProgressionEvidenceStartInputSource_Enum
                    .preAnalysisChecklist
                ..checklist.replace(
                  ProgressionEvidenceStartInputChecklist(
                    (c) => c
                      ..instrument = instrument
                      ..timeframe = timeframe,
                  ),
                ),
            ),
          );
      if (!mounted || _checklistContext != '$instrument|$timeframe') return;
      setState(() {
        _checklistEvidenceToken = response.data?.token;
        _checklistMinimumCompleteAt = response.data?.minimumCompleteAt;
      });
    } catch (_) {
      // Siklus yang sudah selesai/aktif tetap boleh memakai checklist tanpa XP.
    }
  }

  /// Mengubah pilihan tidak pernah membuat request analisis atau memakai
  /// kuota. Request hanya boleh berasal dari tombol submit yang eksplisit.
  Future<void> _selectInstrument(String symbol) =>
      context.read<MarketProvider>().selectInstrument(symbol);

  /// Membawa hasil ke layar, sama seperti `scrollIntoView` pada web.
  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = _resultSectionKey.currentContext;
      if (!mounted || anchor == null) return;
      unawaited(
        Scrollable.ensureVisible(
          anchor,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  /// Kembali ke form pemilihan instrumen.
  ///
  /// Reset lokal selalu dijalankan supaya form pasti muncul, lalu shell
  /// diberi tahu agar tab Analisis benar-benar dimulai dari state bersih
  /// (mis. ketika detail dibuka dari tab lain).
  void _openNewAnalysisForm() {
    FocusManager.instance.primaryFocus?.unfocus();
    _contextController.clear();
    setState(() {
      _resultRevision++;
      _resultAnalysis = null;
      _checkedMentalItems.clear();
      _checklistEvidenceToken = null;
      _checklistMinimumCompleteAt = null;
    });
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        ),
      );
    }
    widget.onNewAnalysis?.call();
  }

  // ignore: unused_element
  void _changeAnalysisSelection() {
    final result = _resultAnalysis;
    if (result != null) {
      unawaited(
        context.read<MarketProvider>().selectInstrument(
          result.instrument,
          timeframe: result.timeframe,
        ),
      );
    }
    setState(() {
      _resultRevision++;
      _resultAnalysis = null;
    });
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  Future<void> _toggleMentalItem(int index) async {
    final wasComplete = _checkedMentalItems.length == 4;
    setState(() {
      if (!_checkedMentalItems.add(index)) _checkedMentalItems.remove(index);
    });
    if (!wasComplete && _checkedMentalItems.length == 4) {
      await _completeMentalChecklist();
    }
  }

  Future<void> _completeMentalChecklist() async {
    final token = _checklistEvidenceToken;
    if (token == null || _isAwardingChecklist) return;
    final wait = _checklistMinimumCompleteAt?.difference(DateTime.now());
    if (wait != null && !wait.isNegative) await Future<void>.delayed(wait);
    if (!mounted || _checkedMentalItems.length != 4) return;
    setState(() => _isAwardingChecklist = true);
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .progression
          .recordProgressionActivity(
            progressionActivityInput: ProgressionActivityInput(
              (b) => b.token = token,
            ),
          );
      final award = response.data;
      if (mounted && award?.awarded == true) {
        unawaited(context.read<ProgressionProvider>().refresh(silent: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.xpAwarded(award!.xp, context.l10n.checklistActivity),
            ),
          ),
        );
      }
      _checklistEvidenceToken = null;
    } catch (_) {
      // Checklist adalah nudge; kegagalan XP tidak boleh memblokir analisis.
    } finally {
      if (mounted) setState(() => _isAwardingChecklist = false);
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisProvider>();

    final market = context.watch<MarketProvider>();
    final mentalChecklist = context.watch<MentalChecklistController>();
    final instrument = market.selectedInstrument;

    if (_guardrailInstrument != instrument) {
      _guardrailInstrument = instrument;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadGuardrails(instrument),
      );
    }

    final timeframe = market.selectedTimeframe;

    final checklistContext = mentalChecklist.enabled
        ? '$instrument|$timeframe'
        : null;
    if (_checklistContext != checklistContext) {
      _checklistContext = checklistContext;
      if (checklistContext == null) {
        _checkedMentalItems.clear();
        _checklistEvidenceToken = null;
      } else {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _prepareChecklistEvidence(instrument, timeframe),
        );
      }
    }

    final quote = market.selectedQuote;

    final highImpactSoon = _findHighImpactSoon(market.highImpactEvents);
    final l10n = context.l10n;

    final result = _resultAnalysis;
    final resultRevision = _resultRevision;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _AnalyzeHeader(
                title: l10n.analyzeTitle,
                quota: analysis.quota,
                onNewAnalysis: result == null ? null : _openNewAnalysisForm,
              ),
              const SizedBox(height: 12),
              _AnalyzeMarketSessionPill(
                key: const Key('analyze-market-session'),
                instrument: instrument,
              ),
              const SizedBox(height: 20),
              ErrorBanner(
                message: _analysisSubmitError,
                onRetry: analysis.isSubmitting
                    ? null
                    : () => unawaited(_submit()),
                retryLabel: l10n.tryAgain,
              ),

              ErrorBanner(
                message: market.marketError,
                onRetry: () =>
                    unawaited(market.loadSelectedMarketData(force: true)),
                retryLabel: l10n.tryAgain,
              ),
              _SectionTitle(title: l10n.selectInstrument),
              const SizedBox(height: 12),
              _AnalyzeInstrumentSelector(
                selected: instrument,
                isCustom: market.isCustomInstrument,
                onSelected: _selectInstrument,
                onSelectedCustom: (symbol) => market.selectInstrument(symbol),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('set-price-alert-button'),
                  onPressed: quote == null
                      ? null
                      : () => unawaited(_openPriceAlert(instrument, quote)),
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: Text(l10n.setAlertAction),
                ),
              ),
              if (result == null) ...[
                const SizedBox(height: 12),
                // Sama seperti web: tombol Analisis tepat di bawah pemilih
                // instrumen (dan tombol alert), sebelum peringatan dan
                // checklist mental.
                // Satu-satunya tombol dengan gradient + glow di halaman ini —
                // aksen sengaja disimpan untuk aksi paling penting (submit
                // analisis), bukan disebar ke elemen lain (dose cap R-13).
                _SubmitAnalysisButton(
                  isSubmitting: analysis.isSubmitting,
                  onPressed:
                      analysis.isSubmitting ||
                          !isVerifiedAnalysisInstrument(instrument)
                      ? null
                      : _submit,
                  label: analysis.isSubmitting
                      ? l10n.analyzingMarket
                      : l10n.analyzeAction,
                ),
              ],
              const SizedBox(height: 16),
              if (result == null) ...[
                if (highImpactSoon != null) ...[
                  _PreTradeWarning(event: highImpactSoon),
                  const SizedBox(height: 20),
                ],
                if (mentalChecklist.enabled) ...[
                  _MentalChecklistCard(
                    checked: _checkedMentalItems,
                    isSaving: _isAwardingChecklist,
                    onToggle: _toggleMentalItem,
                  ),
                  const SizedBox(height: 20),
                ],
              ],
              _AnalyzeMarketCard(market: market),
              if (result == null) ...[
                const SizedBox(height: 56),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.analyzeFooterDisclaimer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              if (result != null) ...[
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 30),
                KeyedSubtree(
                  key: _resultSectionKey,
                  child: AnalysisDetailScreen(
                    key: ValueKey('embedded-analysis-${result.id}'),
                    analysisId: result.id,
                    preloaded: result,
                    embedded: true,
                    onCreatePriceAlert: quote == null
                        ? null
                        : () => unawaited(
                            _openPriceAlert(result.instrument, quote),
                          ),
                    onAnalysisCreated: (created) {
                      if (!mounted || resultRevision != _resultRevision) {
                        return;
                      }
                      setState(() => _resultAnalysis = created);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadGuardrails(String instrument) async {
    try {
      final auth = context.read<AuthProvider>();
      final response = await auth.client.analyses.getGuardrails(
        instrument: instrument,
      );
      if (!mounted || _guardrailInstrument != instrument) return;
      final signals = (response.data?.signals?.toList() ?? const [])
          .map(
            (item) => <String, dynamic>{
              for (final entry in item.entries) entry.key: entry.value?.value,
            },
          )
          .where((item) => item['kind'] is String)
          .toList();
      setState(() {
        _guardrails = signals;
        _guardrailTelemetryIds.clear();
      });
      for (final signal in signals) {
        unawaited(_logGuardrailImpression(auth, signal, instrument));
      }
    } catch (_) {
      if (mounted && _guardrailInstrument == instrument) {
        setState(() => _guardrails = const []);
      }
    }
  }

  Future<void> _logGuardrailProceed(
    AuthProvider auth,
    Map<String, dynamic> signal,
    String instrument,
  ) async {
    try {
      await auth.client.analyses.recordGuardrailTelemetry(
        recordGuardrailTelemetryRequest: RecordGuardrailTelemetryRequest(
          (b) => b
            ..kind = signal['kind'] as String
            ..instrument = instrument
            ..proceeded = true,
        ),
      );
    } catch (_) {
      // Telemetry tidak boleh memblokir pembuatan analisis.
    }
  }

  String _guardrailKey(Map<String, dynamic> signal) =>
      signal['kind'] == 'overtrading'
      ? 'overtrading:${signal['scope']}'
      : signal['kind'] as String;

  Future<void> _logGuardrailImpression(
    AuthProvider auth,
    Map<String, dynamic> signal,
    String instrument,
  ) async {
    try {
      final response = await auth.client.analyses.recordGuardrailTelemetry(
        recordGuardrailTelemetryRequest: RecordGuardrailTelemetryRequest(
          (b) => b
            ..kind = signal['kind'] as String
            ..instrument = instrument
            ..proceeded = false,
        ),
      );
      if (mounted && _guardrailInstrument == instrument) {
        _guardrailTelemetryIds[_guardrailKey(signal)] = response.data!.id;
      }
    } catch (_) {
      // Guardrail tetap tampil walau pencatatan impresi gagal.
    }
  }
}

class _MentalChecklistCard extends StatelessWidget {
  const _MentalChecklistCard({
    required this.checked,
    required this.isSaving,
    required this.onToggle,
  });

  final Set<int> checked;
  final bool isSaving;
  final Future<void> Function(int) onToggle;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.mentalChecklistRisk,
      context.l10n.mentalChecklistPlan,
      context.l10n.mentalChecklistChase,
      context.l10n.mentalChecklistCalm,
    ];
    final complete = checked.length == labels.length;
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: (complete ? colors.tertiary : colors.primary).withValues(
        alpha: .06,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  complete
                      ? Icons.check_circle_outline_rounded
                      : Icons.psychology_alt_outlined,
                  size: 19,
                  color: complete ? colors.tertiary : colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.mentalChecklistTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (isSaving) ...[
                  const Spacer(),
                  const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(
              labels.length,
              (index) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: checked.contains(index),
                onChanged: (_) => unawaited(onToggle(index)),
                title: Text(
                  labels[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    decoration: checked.contains(index)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ),
            Text(
              context.l10n.mentalChecklistHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MARKET OVERVIEW
// =============================================================================

// Legacy result summary remains used by older snapshots during this redesign.
// ignore: unused_element
class _MarketOverviewCard extends StatelessWidget {
  const _MarketOverviewCard({
    required this.market,
    required this.onToggleWatchlist,
  });

  final MarketProvider market;

  final VoidCallback onToggleWatchlist;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    final bearish = isDark ? AppColors.bearishDark : AppColors.bearishLight;

    // // Glyph/teks memakai nada emas yang terbaca; isian tetap emas web.
    final primary = isDark
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;

    final watchlist = context.watch<WatchlistProvider>();

    final quote = market.selectedQuote;

    final technical = market.selectedTechnical;

    final fallbackPrice =
        technical?.lastClose ??
        (market.selectedCandles.isNotEmpty
            ? market.selectedCandles.last.close
            : null);

    final price = quote?.price ?? fallbackPrice;

    final change = quote?.changePercent ?? technical?.change1dPercent;

    final changeColor = (change ?? 0) >= 0 ? bullish : bearish;

    final instrument = market.selectedInstrument;

    final watchlisted = watchlist.isWatchlisted(instrument);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              instrument,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LiveStatusChip(isLive: quote != null),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${market.selectedTimeframe} • ${quote != null ? context.l10n.livePrice : context.l10n.referencePrice}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: watchlisted
                      ? context.l10n.removeFromWatchlist
                      : context.l10n.addToWatchlist,
                  onPressed: watchlist.isUpdating ? null : onToggleWatchlist,
                  icon: watchlist.isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          watchlisted
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: watchlisted ? primary : null,
                        ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    price == null
                        ? '--'
                        : _formatMarketPrice(instrument, price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),

                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          change >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: changeColor,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: changeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Trend bias dari indikator teknikal live — cuma tampil kalau
            // datanya benar-benar ada (bukan placeholder), edukatif saja,
            // bukan sinyal beli/jual (lihat TechnicalSummaryEngine).
            if (TechnicalSummaryEngine.build(technical)
                case final summary?) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${context.l10n.trend}: ',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  ContextIndicator(trend: summary.trend),
                ],
              ),
            ],

            const SizedBox(height: 18),

            MarketMiniChart(
              candles: market.selectedCandles,
              technical: market.selectedTechnical,
              currentPrice: quote?.price,
              error: market.marketError == null
                  ? null
                  : context.l10n.partialChartUnavailable,
              isLoading: market.isLoadingSelectedMarket,
            ),

            if (quote != null && market.quotesUpdatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.pricesUpdatedAt(
                  DateFormat(
                    'HH:mm:ss',
                  ).format(market.quotesUpdatedAt!.toLocal()),
                ),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalyzeMarketCard extends StatelessWidget {
  const _AnalyzeMarketCard({required this.market});

  final MarketProvider market;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;
    final bearish = isDark ? AppColors.bearishDark : AppColors.bearishLight;
    final quote = market.selectedQuote;
    final technical = market.selectedTechnical;
    final candles = market.selectedCandles;
    final instrument = market.selectedInstrument;
    final candle = candles.lastOrNull;
    final price = quote?.price ?? technical?.lastClose ?? candle?.close;
    final change = quote?.changePercent ?? technical?.change1dPercent;
    final changeColor = (change ?? 0) >= 0 ? bullish : bearish;

    return Container(
      key: const Key('analyze-market-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnalyzeMarketRow(label: context.l10n.instrument, value: instrument),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${context.l10n.currentPriceLabel}:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                price == null ? '--' : _formatMarketPrice(instrument, price),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (change != null) ...[
                const SizedBox(width: 5),
                Icon(
                  change >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 15,
                  color: changeColor,
                ),
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.area_chart_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              _marketDisplayName(instrument),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (candle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'O ${_formatMarketPrice(instrument, candle.open)}  '
                          'H ${_formatMarketPrice(instrument, candle.high)}  '
                          'L ${_formatMarketPrice(instrument, candle.low)}  '
                          'C ${_formatMarketPrice(instrument, candle.close)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: candle.close >= candle.open
                                ? bullish
                                : bearish,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: MarketMiniChart(
                    candles: candles,
                    technical: technical,
                    currentPrice: quote?.price,
                    error: market.marketError == null
                        ? null
                        : context.l10n.partialChartUnavailable,
                    isLoading: market.isLoadingSelectedMarket,
                    showDetails: false,
                  ),
                ),
                InkWell(
                  onTap: () => _openTradingView(instrument),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: Center(
                      child: Text(
                        context.l10n.trackMarketsTradingView,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _AnalyzeMarketRow(
            label: context.l10n.timeframe,
            value: market.selectedTimeframe,
          ),
        ],
      ),
    );
  }

  Future<void> _openTradingView(String instrument) async {
    final symbol = switch (instrument.toUpperCase()) {
      'XAU/USD' => 'OANDA:XAUUSD',
      'XAG/USD' => 'OANDA:XAGUSD',
      'BRENT' => 'TVC:UKOIL',
      'HSI' => 'HSI:HSI',
      'NIKKEI' => 'TVC:NI225',
      _ => instrument.replaceAll('/', ''),
    };
    await launchUrl(
      Uri.https('www.tradingview.com', '/chart/', {'symbol': symbol}),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _AnalyzeMarketRow extends StatelessWidget {
  const _AnalyzeMarketRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '$label:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

String _marketDisplayName(String instrument) => switch (instrument) {
  'XAU/USD' => 'Gold Spot / U.S. Dollar',
  'XAG/USD' => 'Silver Spot / U.S. Dollar',
  'BRENT' => 'Brent Crude Oil',
  'HSI' => 'Hang Seng Index',
  'NIKKEI' => 'Nikkei 225',
  _ => instrument,
};

// =============================================================================
// LIVE STATUS
// =============================================================================

class _LiveStatusChip extends StatelessWidget {
  const _LiveStatusChip({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    final neutral = isDark ? AppColors.neutralDark : AppColors.neutralLight;

    final color = isLive ? bullish : neutral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        boxShadow: AppColors.signalGlow(color, enabled: isDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            isLive ? 'LIVE' : 'REFERENCE',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MARKET SESSION
// =============================================================================

// ignore: unused_element
class _MarketSessionPill extends StatelessWidget {
  const _MarketSessionPill({required this.instrument});

  final String instrument;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final bullish = isDark ? AppColors.bullishDark : AppColors.bullishLight;

    if (isCryptoMarketInstrument(instrument)) {
      return _SessionContainer(
        color: bullish,
        title: context.l10n.cryptoMarketAlwaysOpen,
        subtitle: context.l10n.cryptoNoForexSessions,
      );
    }

    final status = getMarketSessionStatus();

    if (status.openSessions.isEmpty) {
      return _SessionContainer(
        color: muted,
        title: status.isWeekendClosed
            ? context.l10n.marketClosedWeekend
            : context.l10n.noMainSessionActive,
        subtitle: status.next == null
            ? null
            : _nextSessionText(context, status.next!),
      );
    }

    final names = status.openSessions.map(marketSessionLabel).join(' • ');

    return _SessionContainer(
      color: bullish,
      title: names,
      subtitle: status.isOverlap
          ? context.l10n.sessionOverlap
          : status.next == null
          ? context.l10n.marketSessionActive
          : _nextSessionText(context, status.next!),
    );
  }

  String _nextSessionText(
    BuildContext context,
    MarketSessionTransition transition,
  ) {
    final session = marketSessionLabel(transition.session);
    final duration = formatMarketDuration(transition.until);
    return transition.type == 'open'
        ? context.l10n.sessionOpensIn(session, duration)
        : context.l10n.sessionClosesIn(session, duration);
  }
}

class _SessionContainer extends StatelessWidget {
  const _SessionContainer({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: AppColors.signalGlow(
          color,
          enabled: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 10.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzeMarketSessionPill extends StatefulWidget {
  const _AnalyzeMarketSessionPill({super.key, required this.instrument});

  final String instrument;

  @override
  State<_AnalyzeMarketSessionPill> createState() =>
      _AnalyzeMarketSessionPillState();
}

class _AnalyzeMarketSessionPillState extends State<_AnalyzeMarketSessionPill> {
  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCrypto = isCryptoMarketInstrument(widget.instrument);
    final status = getMarketSessionStatus();
    final color = isCrypto || status.openSessions.isNotEmpty
        ? (Theme.of(context).brightness == Brightness.dark
              ? AppColors.bullishDark
              : AppColors.bullishLight)
        : colors.onSurfaceVariant;
    final text = isCrypto
        ? context.l10n.cryptoMarketAlwaysOpen
        : status.openSessions.isEmpty
        ? '${status.isWeekendClosed ? context.l10n.marketClosedWeekend : context.l10n.noMainSessionActive}'
              '${status.next == null ? '' : ' · ${_transitionText(context, status.next!)}'}'
        : '${status.openSessions.map(marketSessionLabel).join(' • ')}'
              '${status.next == null ? '' : ' · ${_transitionText(context, status.next!)}'}';

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: _anchorKey,
          borderRadius: BorderRadius.circular(999),
          onTap: _showInfo,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _transitionText(
    BuildContext context,
    MarketSessionTransition transition,
  ) {
    final session = marketSessionLabel(transition.session);
    final duration = formatMarketDuration(transition.until);
    return transition.type == 'open'
        ? context.l10n.sessionOpensIn(session, duration)
        : context.l10n.sessionClosesIn(session, duration);
  }

  Future<void> _showInfo() async {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final size = MediaQuery.sizeOf(context);
    final width = math.min(size.width - 32, 430.0);
    final left = origin.dx.clamp(16.0, size.width - width - 16);
    final top = origin.dy + box.size.height + 8;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, _, _) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: width,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size.height - top - 16),
              child: const _MarketSessionInfoCard(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketSessionInfoCard extends StatelessWidget {
  const _MarketSessionInfoCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const sessions = [
      ('Sydney', '05:00–14:00'),
      ('Tokyo', '07:00–16:00'),
      ('London', '15:00–00:00'),
      ('New York', '20:00–05:00'),
    ];

    return Material(
      color: colors.surfaceContainerLowest,
      elevation: 12,
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.marketSessionsAboutTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              Text(context.l10n.marketSessionsAboutBody),
              const SizedBox(height: 12),
              Text(
                context.l10n.marketSessionsOverlapBody,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Divider(color: colors.outlineVariant),
              const SizedBox(height: 10),
              Text(
                context.l10n.typicalSessionHours,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.shownInJakarta,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < sessions.length; index += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      for (final item in sessions.skip(index).take(2)) ...[
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.$1,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item != sessions.skip(index).take(2).last)
                          const SizedBox(width: 16),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                context.l10n.marketSessionContextDisclaimer,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PRE TRADE WARNING
// =============================================================================

EconomicCalendarEvent? _findHighImpactSoon(List<EconomicCalendarEvent> events) {
  final now = DateTime.now();

  final candidates = events.where((event) {
    if (!event.isHighImpact || event.actual.trim().isNotEmpty) {
      return false;
    }

    final date = event.eventDateTime;

    if (date == null) {
      return false;
    }

    final difference = date.difference(now);

    return !difference.isNegative && difference <= const Duration(minutes: 30);
  }).toList();

  candidates.sort((a, b) {
    final aDate = a.eventDateTime!;

    final bDate = b.eventDateTime!;

    return aDate.compareTo(bDate);
  });

  if (candidates.isEmpty) {
    return null;
  }

  return candidates.first;
}

class _PreTradeWarning extends StatelessWidget {
  const _PreTradeWarning({required this.event});

  final EconomicCalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    final eventDate = event.eventDateTime;

    final minutes = eventDate?.difference(DateTime.now()).inMinutes;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.highImpactEventSoon,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: error),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.event}'
                  '${minutes == null ? '' : context.l10n.eventStartsInMinutes(minutes)}. '
                  '${context.l10n.highImpactRisk}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMMON UI
// =============================================================================

/// Tombol utama halaman Analyze.
class _SubmitAnalysisButton extends StatelessWidget {
  const _SubmitAnalysisButton({
    required this.isSubmitting,
    required this.onPressed,
    required this.label,
  });

  final bool isSubmitting;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    const foreground = AppColors.lightPrimaryForeground;

    return Opacity(
      opacity: disabled && !isSubmitting ? 0.6 : 1,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('submit-analysis-button'),
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSubmitting) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  // Flexible + ellipsis: label terjemahan yang lebih panjang
                  // atau text scale besar tidak boleh meluap dari tombol.
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Judul seksi form, menyalin `h2 text-sm font-semibold` pada web — yang di
/// sana berdiri sendiri tanpa baris penjelas.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}

// ignore: unused_element
class _AnalysisSelectionSummary extends StatelessWidget {
  const _AnalysisSelectionSummary({
    required this.instrument,
    required this.timeframe,
    required this.onChange,
    required this.onNew,
  });

  final String instrument;
  final String timeframe;
  final VoidCallback onChange;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.selectedAnalysisMarket,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$instrument · $timeframe',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('change-analysis-selection-button'),
                onPressed: onChange,
                child: Text(context.l10n.changeSelection),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('new-analysis-button'),
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: Text(context.l10n.analyzeTitle),
            ),
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// INSTRUMENT SELECTOR
// =============================================================================

class _AnalyzeInstrumentSelector extends StatefulWidget {
  const _AnalyzeInstrumentSelector({
    required this.selected,
    required this.isCustom,
    required this.onSelected,
    required this.onSelectedCustom,
  });

  final String selected;
  final bool isCustom;
  final Future<void> Function(String instrument) onSelected;
  final Future<void> Function(String instrument) onSelectedCustom;

  @override
  State<_AnalyzeInstrumentSelector> createState() =>
      _AnalyzeInstrumentSelectorState();
}

class _AnalyzeInstrumentSelectorState
    extends State<_AnalyzeInstrumentSelector> {
  static const _featured = analysisCoreInstruments;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_featured.contains(widget.selected)) {
      _controller.text = widget.selected;
    }
  }

  @override
  void didUpdateWidget(covariant _AnalyzeInstrumentSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.text = _featured.contains(widget.selected)
        ? ''
        : widget.selected;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Picking only changes the selection. An analysis always needs the explicit
  /// Analyze button, and a code that is not verified can only be requested.
  Future<void> _openOtherInstrumentPicker() async {
    final selected = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => const _OtherInstrumentDialog(),
    );
    if (!mounted || selected == null || selected == widget.selected) return;
    _controller.text = selected;
    await widget.onSelectedCustom(selected);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          for (final instrument in _featured) ...[
            Expanded(
              child: _InstrumentOption(
                key: ValueKey('analyze-instrument-$instrument'),
                instrument: instrument,
                assetTypeLabel: null,
                selected: !widget.isCustom && widget.selected == instrument,
                onTap: () {
                  _controller.clear();
                  unawaited(widget.onSelected(instrument));
                },
              ),
            ),
            if (instrument != _featured.last) const SizedBox(width: 8),
          ],
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('custom-instrument-field'),
        controller: _controller,
        readOnly: true,
        onTap: _openOtherInstrumentPicker,
        decoration: InputDecoration(
          hintText: context.l10n.otherInstrument,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ),
      if (!isVerifiedAnalysisInstrument(widget.selected)) ...[
        const SizedBox(height: 8),
        Text(
          context.l10n.instrumentLegacyUnsupported,
          key: const Key('unsupported-restored-instrument'),
          style: TextStyle(
            color: context.adaptiveAmber,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ],
  );
}

/// Pemilih instrumen inline seperti mobile web: tiga kategori yang dapat
/// dibuka-tutup, lalu grid dua kolom berisi instrumen kategori tersebut.
class _InstrumentSelector extends StatefulWidget {
  const _InstrumentSelector({
    required this.selected,
    required this.isCustom,
    required this.onSelected,
    required this.onSelectedCustom,
  });

  final String selected;

  /// True ketika [selected] berasal dari input bebas, bukan dari grid.
  final bool isCustom;
  final Future<void> Function(String instrument) onSelected;
  final Future<void> Function(String instrument) onSelectedCustom;

  @override
  State<_InstrumentSelector> createState() => _InstrumentSelectorState();
}

class _InstrumentSelectorState extends State<_InstrumentSelector> {
  static final _groups = MarketProvider.analyzeInstrumentGroups;

  late String? _openCategory = _categoryOf(widget.selected);
  final TextEditingController _customController = TextEditingController();
  Timer? _customDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.isCustom) _customController.text = widget.selected;
  }

  @override
  void dispose() {
    _customDebounce?.cancel();
    _customController.dispose();
    super.dispose();
  }

  static String? _categoryOf(String instrument) {
    for (final entry in _groups.entries) {
      if (entry.value.contains(instrument)) return entry.key;
    }
    return _groups.keys.isEmpty ? null : _groups.keys.first;
  }

  @override
  void didUpdateWidget(covariant _InstrumentSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    if (!widget.isCustom && _customController.text.isNotEmpty) {
      _customController.clear();
    }
    final category = _categoryOf(widget.selected);
    if (category != null && category != _openCategory) {
      setState(() => _openCategory = category);
    }
  }

  void _onCustomChanged(String value) {
    _customDebounce?.cancel();
    _customDebounce = Timer(
      const Duration(milliseconds: 600),
      () => _applyCustom(value),
    );
  }

  void _applyCustom(String value) {
    final symbol = value.trim().toUpperCase();
    if (symbol.isEmpty || symbol == widget.selected) return;
    unawaited(widget.onSelectedCustom(symbol));
  }

  void _selectFromGrid(String instrument) {
    _customDebounce?.cancel();
    if (_customController.text.isNotEmpty) _customController.clear();
    unawaited(widget.onSelected(instrument));
  }

  @override
  Widget build(BuildContext context) {
    // Web hanya menampilkan tab kategori ketika lebih dari satu kategori punya
    // instrumen yang terlihat; kalau hanya satu, gridnya langsung ditampilkan.
    final showCategories = _groups.length > 1;
    final open = showCategories ? _openCategory : _groups.keys.firstOrNull;
    final instruments = open == null
        ? const <String>[]
        : _groups[open] ?? const [];
    final gridSelection = widget.isCustom ? null : widget.selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCategories) ...[
          Row(
            children: [
              for (final category in _groups.keys) ...[
                Expanded(
                  child: _CategoryTab(
                    label: MarketProvider.instrumentCategoryLabel(
                      context.l10n,
                      category,
                    ),
                    isOpen: open == category,
                    onTap: () => setState(
                      () => _openCategory = open == category ? null : category,
                    ),
                  ),
                ),
                if (category != _groups.keys.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (instruments.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final width = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in instruments)
                    SizedBox(
                      width: width,
                      child: _InstrumentOption(
                        instrument: item,
                        assetTypeLabel: _assetTypeLabel(context.l10n, item),
                        selected: item == gridSelection,
                        onTap: () => _selectFromGrid(item),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('custom-instrument-field'),
          controller: _customController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          onChanged: _onCustomChanged,
          onSubmitted: (value) {
            _customDebounce?.cancel();
            _applyCustom(value);
          },
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: context.l10n.otherInstrument,
            prefixIcon: const Icon(Icons.edit_outlined, size: 18),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog "Instrumen lain…": kode terverifikasi (atau aliasnya) langsung
/// dipilih; kode lain yang bentuknya valid berubah menjadi tombol "Request"
/// yang mencatat minat ke server tanpa memulai analisis.
class _OtherInstrumentDialog extends StatefulWidget {
  const _OtherInstrumentDialog();

  @override
  State<_OtherInstrumentDialog> createState() => _OtherInstrumentDialogState();
}

class _OtherInstrumentDialogState extends State<_OtherInstrumentDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _query => _controller.text;

  void _submit() {
    final exact = exactAnalysisInstrument(_query);
    if (exact != null) {
      Navigator.pop(context, exact.code);
      return;
    }
    final code = instrumentRequestCode(_query);
    if (code != null) unawaited(_request(code));
  }

  Future<void> _request(String code) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) => _InstrumentRequestDialog(code: code),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final isTyping = _query.trim().isNotEmpty;
    final matches = matchAnalysisInstruments(_query);
    final requestCode = instrumentRequestCode(_query);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      l10n.otherInstrument,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: l10n.close,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.instrumentPickerHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('other-instrument-search-field'),
                controller: _controller,
                autofocus: true,
                maxLength: 25,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: l10n.searchOrEnterInstrumentCode,
                  counterText: '',
                  suffixIcon: isTyping
                      ? IconButton(
                          key: const Key('other-instrument-clear'),
                          tooltip: l10n.clear,
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              if (matches.isNotEmpty)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 4.1,
                  children: [
                    for (final option in matches)
                      OutlinedButton(
                        key: ValueKey('other-instrument-${option.code}'),
                        onPressed: () => Navigator.pop(context, option.code),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: Text(option.code),
                      ),
                  ],
                )
              else if (isTyping && requestCode == null)
                Text(
                  l10n.instrumentNoMatch,
                  key: const Key('other-instrument-no-match'),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              if (requestCode != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('other-instrument-request-button'),
                    onPressed: _submit,
                    child: Text(l10n.requestInstrument(requestCode)),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                l10n.instrumentSourceLimitations,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Records interest in an unsupported code (`POST /instrument-requests`).
/// Sending never starts an analysis or uses quota / credits.
class _InstrumentRequestDialog extends StatefulWidget {
  const _InstrumentRequestDialog({required this.code});

  final String code;

  @override
  State<_InstrumentRequestDialog> createState() =>
      _InstrumentRequestDialogState();
}

enum _RequestStatus { sending, success, error }

class _InstrumentRequestDialogState extends State<_InstrumentRequestDialog> {
  _RequestStatus _status = _RequestStatus.sending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_send()));
  }

  Future<void> _send() async {
    setState(() => _status = _RequestStatus.sending);
    try {
      await context
          .read<AuthProvider>()
          .client
          .analyses
          .submitInstrumentRequest(
            instrumentRequestInput: InstrumentRequestInput(
              (b) => b..code = widget.code,
            ),
          );
      if (mounted) setState(() => _status = _RequestStatus.success);
    } catch (_) {
      if (mounted) setState(() => _status = _RequestStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final sending = _status == _RequestStatus.sending;
    final title = switch (_status) {
      _RequestStatus.sending => l10n.instrumentRequestSending,
      _RequestStatus.error => l10n.instrumentRequestError,
      _RequestStatus.success => l10n.instrumentNotAvailableTitle(widget.code),
    };
    return PopScope(
      canPop: !sending,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: const Key('instrument-unavailable-title'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (sending)
                const LinearProgressIndicator()
              else if (_status == _RequestStatus.success) ...[
                Text(
                  l10n.instrumentNotAvailableBody,
                  style: TextStyle(color: muted, height: 1.6, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.instrumentRequestNoCredit,
                  style: TextStyle(color: muted, height: 1.5, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_status == _RequestStatus.error)
                      OutlinedButton(
                        key: const Key('instrument-request-retry'),
                        onPressed: _send,
                        child: Text(l10n.tryAgain),
                      ),
                    FilledButton(
                      key: const Key('instrument-unavailable-close'),
                      onPressed: sending ? null : () => Navigator.pop(context),
                      child: Text(l10n.close),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.isOpen,
    required this.onTap,
  });

  final String label;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      expanded: isOpen,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isOpen ? colors.primary : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(
              color: isOpen ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOpen ? colors.onPrimary : colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                isOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isOpen ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label tipe aset untuk instrumen yang muncul di grid Analyze.
///
/// Fakta tetap tentang instrumen itu sendiri (XAU/USD selalu emas, BRENT
/// selalu minyak), bukan data live — jadi aman ditampilkan tanpa provider.
/// `null` untuk instrumen yang belum dipetakan, supaya tidak ada tag
/// asal-asalan kalau daftar instrumen bertambah nanti.
String? _assetTypeLabel(AppLocalizations l10n, String instrument) {
  switch (instrument.toUpperCase()) {
    case 'XAU/USD':
    case 'XAG/USD':
      return l10n.assetTypeGold;
    case 'BRENT':
      return l10n.assetTypeOil;
    case 'HSI':
    case 'NIKKEI':
    case 'DJIA':
    case 'NASDAQ':
      return l10n.assetTypeIndex;
    default:
      return null;
  }
}

class _InstrumentOption extends StatelessWidget {
  const _InstrumentOption({
    super.key,
    required this.instrument,
    required this.assetTypeLabel,
    required this.selected,
    required this.onTap,
  });

  final String instrument;
  final String? assetTypeLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            // Web memakai `bg-primary/10` saat terpilih dan `bg-background`
            // ketika tidak — bukan warna kartu.
            color: selected
                ? colors.primary.withValues(alpha: 0.1)
                : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
            // Glow cuma di instrumen yang sedang dipilih — satu titik fokus
            // di grid ini, bukan dipakai di semua opsi (dose cap R-13).
            boxShadow: AppColors.signalGlow(
              colors.primary,
              enabled: selected && isDark,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  instrument,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
              ),
              if (assetTypeLabel case final label?) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    border: selected
                        ? Border.all(
                            color: colors.primary.withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? colors.primary : colors.outline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ANALYZE HEADER
// =============================================================================

/// Header ringkas satu baris: judul, progression, lalu kuota.
class _AnalyzeHeader extends StatelessWidget {
  const _AnalyzeHeader({
    required this.title,
    required this.quota,
    this.onNewAnalysis,
  });

  final String title;
  final AnalysisQuota? quota;
  final VoidCallback? onNewAnalysis;

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ProgressionProvider>().summary;
    final showQuota = quota != null && !quota!.unlimited;

    final status = <Widget>[
      if (summary != null) _ProgressionChip(summary: summary),
      if (showQuota) _QuotaChip(quota: quota!),
    ];
    final titleWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );

    if (onNewAnalysis == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleWidget),
          for (final item in status) ...[const SizedBox(width: 6), item],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleWidget,
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const Key('new-analysis-button'),
              onPressed: onNewAnalysis,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.analyzeTitle),
            ),
            ...status,
          ],
        ),
      ],
    );
  }
}

class _ProgressionChip extends StatelessWidget {
  const _ProgressionChip({required this.summary});

  final ProgressionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final levelLabel = summary.masteryLevel > 0
        ? l10n.progressionMastery(summary.masteryLevel)
        : l10n.progressionLevel(summary.level);

    return Semantics(
      button: true,
      label:
          '${l10n.progressionTitle}: $levelLabel, '
          '${l10n.progressionRank(summary.rank)}',
      child: InkWell(
        key: const Key('analyze-progression-chip'),
        borderRadius: BorderRadius.circular(999),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProgressionScreen())),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 132),
          padding: const EdgeInsets.fromLTRB(3, 3, 8, 3),
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressionEmblem(
                level: summary.level,
                masteryLevel: summary.masteryLevel,
                size: 28,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      summary.rank,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuotaChip extends StatelessWidget {
  const _QuotaChip({required this.quota});

  final AnalysisQuota quota;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final daily = quota.daily;

    final (background, border, foreground) = switch (daily.remaining) {
      0 => (
        colors.error.withValues(alpha: 0.1),
        colors.error.withValues(alpha: 0.4),
        colors.error,
      ),
      final remaining when remaining <= 3 => (
        const Color(0xFFF59E0B).withValues(alpha: 0.1),
        const Color(0xFFF59E0B).withValues(alpha: 0.4),
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.warningDark
            : AppColors.warningLight,
      ),
      _ => (
        colors.primary.withValues(alpha: 0.1),
        colors.primary.withValues(alpha: 0.3),
        colors.primary,
      ),
    };

    return Tooltip(
      message: '${l10n.quotaDay}: ${daily.remaining}/${daily.limit}',
      child: Container(
        key: const Key('analyze-quota-chip'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          '${daily.remaining}${l10n.quotaDayShort}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FORMATTERS
// =============================================================================

String _formatMarketPrice(String instrument, double value) {
  if (instrument == 'USD/IDR') {
    return NumberFormat('#,##0').format(value);
  }

  if (instrument == 'USD/JPY') {
    return value.toStringAsFixed(2);
  }

  if (value >= 1000) {
    return NumberFormat('#,##0.00').format(value);
  }

  if (value >= 100) {
    return value.toStringAsFixed(2);
  }

  if (value >= 1) {
    return value.toStringAsFixed(4);
  }

  return value.toStringAsFixed(6);
}
