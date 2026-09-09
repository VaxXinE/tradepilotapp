import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../../core/market/market_sessions.dart';
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
import '../../../widgets/app_footer.dart';
import '../../../widgets/market_mini_chart.dart';
import '../../../widgets/cooling_off_breathing_dialog.dart';
import '../../../widgets/analysis_quota_dialog.dart';
import '../../analysis/analysis_detail_screen.dart';
import '../../../widgets/price_alert/price_alert_sheet.dart';
import '../../topup/topup_screen.dart';
import '../../progression/progression_screen.dart';
import '../../../widgets/progression/progression_emblem.dart';

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
  const AnalyzeTab({super.key});

  @override
  State<AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<AnalyzeTab> {
  final TextEditingController _contextController = TextEditingController();
  Analysis? _resultAnalysis;
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

      unawaited(context.read<WatchlistProvider>().loadWatchlist());
    });
  }

  @override
  void dispose() {
    _contextController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<void> _refresh() async {
    final market = context.read<MarketProvider>();

    final analysis = context.read<AnalysisProvider>();

    final watchlist = context.read<WatchlistProvider>();

    await Future.wait([
      market.loadSelectedMarketData(force: true),
      market.loadQuotes(force: true),
      watchlist.loadWatchlist(),
      analysis.loadQuota(),
    ]);
  }

  // ===========================================================================
  // WATCHLIST
  // ===========================================================================

  Future<void> _toggleWatchlist(String instrument) async {
    final watchlist = context.read<WatchlistProvider>();

    if (watchlist.isWatchlisted(instrument)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.removeFromWatchlist),
          content: Text(context.l10n.removeInstrumentConfirmation(instrument)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.remove),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    final ok = await watchlist.toggleInstrument(instrument);

    if (!mounted) {
      return;
    }

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(watchlist.error ?? context.l10n.watchlistUpdateFailed),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.watchlistUpdated(instrument))),
      );
    }
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

    final userMode = auth.user?.selectedMode == UserSelectedModeEnum.pro
        ? CreateAnalysisBodyModeEnum.pro
        : CreateAnalysisBodyModeEnum.beginner;

    final note = _contextController.text.trim();

    for (final signal in _guardrails) {
      unawaited(_logGuardrailProceed(auth, signal, market.selectedInstrument));
    }

    final result = await analysisProvider.createAnalysis(
      instrument: market.selectedInstrument,
      timeframe: _analysisTimeframe(market.selectedTimeframe),
      mode: userMode,
      userInputContext: note.isEmpty ? null : note,
    );

    if (!mounted) return;

    if (result == null) {
      final limit = analysisProvider.quotaLimit;
      if (limit != null) {
        final openTopUp = await showAnalysisQuotaDialog(context, limit);
        if (openTopUp && mounted) {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const TopUpScreen()));
          if (mounted) {
            unawaited(analysisProvider.loadQuota());
          }
        }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

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

    if (_resultAnalysis case final result?) {
      return Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.analyzeTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const Key('new-analysis-button'),
                      onPressed: () => setState(() => _resultAnalysis = null),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: Text(l10n.analyzeTitle),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnalysisDetailScreen(
                  key: ValueKey('embedded-analysis-${result.id}'),
                  analysisId: result.id,
                  preloaded: result,
                  embedded: true,
                  onAnalysisCreated: (created) =>
                      setState(() => _resultAnalysis = created),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _AnalyzeHeader(title: l10n.analyzeTitle, quota: analysis.quota),
              const SizedBox(height: 14),
              ErrorBanner(message: analysis.errorMessage),

              ErrorBanner(message: market.marketError),

              // ---------------------------------------------------------------
              // INSTRUMENT
              // ---------------------------------------------------------------
              _SectionTitle(
                title: l10n.selectInstrument,
                subtitle: l10n.selectMarketDescription,
              ),

              const SizedBox(height: 10),

              _InstrumentSelector(
                selected: instrument,
                isCustom: market.isCustomInstrument,
                onSelected: market.selectInstrument,
                onSelectedCustom: (symbol) =>
                    market.selectInstrument(symbol, allowUnsupported: true),
              ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(_openPriceAlert(instrument, quote));
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(
                  quote == null
                      ? l10n.priceAlertUnavailable
                      : l10n.createPriceAlert,
                ),
              ),

              if (quote == null) ...[
                const SizedBox(height: 7),
                Text(
                  l10n.instrumentHasNoLiveFeed,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 11.5),
                ),
              ],

              const SizedBox(height: 22),

              _MarketOverviewCard(
                market: market,
                onToggleWatchlist: () {
                  unawaited(_toggleWatchlist(instrument));
                },
              ),

              const SizedBox(height: 22),

              // ---------------------------------------------------------------
              // HIGH IMPACT PRE-TRADE WARNING
              // ---------------------------------------------------------------
              if (highImpactSoon != null) ...[
                _PreTradeWarning(event: highImpactSoon),

                const SizedBox(height: 14),
              ],

              if (mentalChecklist.enabled) ...[
                _MentalChecklistCard(
                  checked: _checkedMentalItems,
                  isSaving: _isAwardingChecklist,
                  onToggle: _toggleMentalItem,
                ),
                const SizedBox(height: 14),
              ],

              // ---------------------------------------------------------------
              // CTA
              // ---------------------------------------------------------------
              ElevatedButton.icon(
                onPressed: analysis.isSubmitting ? null : _submit,
                icon: analysis.isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  analysis.isSubmitting
                      ? l10n.analyzingMarket
                      : l10n.getAiAnalysis,
                ),
              ),

              if (analysis.quota != null && !analysis.quota!.unlimited) ...[
                const SizedBox(height: 10),
                _QuotaSummaryCard(
                  summary: l10n.analysisQuotaBalances(
                    analysis.quota!.hourly.remaining,
                    analysis.quota!.daily.remaining,
                    analysis.quota!.credits.balance,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Text(
                l10n.aiAnalysisDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 11, height: 1.4),
              ),

              const AppFooter(),
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
                  style: const TextStyle(fontWeight: FontWeight.w800),
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
                  style: TextStyle(
                    fontSize: 12.5,
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

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

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
                          Text(
                            instrument,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LiveStatusChip(isLive: quote != null),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${market.selectedTimeframe} • ${quote != null ? context.l10n.livePrice : context.l10n.referencePrice}',
                        style: TextStyle(color: muted, fontSize: 11.5),
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
                    style: const TextStyle(
                      fontSize: 28,
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

            const SizedBox(height: 12),

            _MarketSessionPill(instrument: instrument),

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
                style: TextStyle(color: muted, fontSize: 10.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
        borderRadius: BorderRadius.circular(14),
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
                  style: TextStyle(
                    color: error,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.event}'
                  '${minutes == null ? '' : context.l10n.eventStartsInMinutes(minutes)}. '
                  '${context.l10n.highImpactRisk}',
                  style: const TextStyle(fontSize: 11.5, height: 1.4),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(color: muted, fontSize: 11.5)),
      ],
    );
  }
}

class _QuotaSummaryCard extends StatelessWidget {
  const _QuotaSummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.analysisQuota,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// INSTRUMENT SELECTOR
// =============================================================================

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
                    label: category,
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
          decoration: InputDecoration(
            hintText: context.l10n.otherInstrument,
            prefixIcon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isOpen ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(10),
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

class _InstrumentOption extends StatelessWidget {
  const _InstrumentOption({
    required this.instrument,
    required this.selected,
    required this.onTap,
  });

  final String instrument;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.1)
                : colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Text(
            instrument,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? colors.primary : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ANALYZE HEADER
// =============================================================================

/// Baris judul Analyze mengikuti mobile web: judul di kiri, lalu chip
/// progression dan chip kuota di kanan.
class _AnalyzeHeader extends StatelessWidget {
  const _AnalyzeHeader({required this.title, required this.quota});

  final String title;
  final AnalysisQuota? quota;

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ProgressionProvider>().summary;
    final showQuota = quota != null && !quota!.unlimited;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        // Chip dibungkus Wrap agar turun baris pada layar sempit, sama seperti
        // `flex-wrap` pada header web.
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (summary != null) _ProgressionChip(summary: summary),
              if (showQuota) _QuotaChip(quota: quota!),
            ],
          ),
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
          constraints: const BoxConstraints(maxWidth: 176),
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
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
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      levelLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.1,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.progressionRank(summary.rank),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.15,
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
    final hourly = quota.hourly;
    final daily = quota.daily;

    final (background, border, foreground) = switch ((
      hourly.remaining,
      daily.remaining,
    )) {
      (0, _) || (_, 0) => (
        colors.error.withValues(alpha: 0.1),
        colors.error.withValues(alpha: 0.4),
        colors.error,
      ),
      (final h, final d) when h <= 1 || d <= 3 => (
        const Color(0xFFF59E0B).withValues(alpha: 0.1),
        const Color(0xFFF59E0B).withValues(alpha: 0.4),
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFB45309),
      ),
      _ => (
        colors.primary.withValues(alpha: 0.1),
        colors.primary.withValues(alpha: 0.3),
        colors.primary,
      ),
    };

    return Tooltip(
      message:
          '${l10n.quotaHour}: ${hourly.remaining}/${hourly.limit} • '
          '${l10n.quotaDay}: ${daily.remaining}/${daily.limit}',
      child: Container(
        key: const Key('analyze-quota-chip'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          '${hourly.remaining}/${hourly.limit}${l10n.quotaHourShort} · '
          '${daily.remaining}/${daily.limit}${l10n.quotaDayShort}',
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
