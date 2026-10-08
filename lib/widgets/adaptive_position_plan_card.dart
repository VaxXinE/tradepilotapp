import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/analysis/adaptive_position_plan.dart';
import '../core/analysis/adaptive_tier_comparison.dart';
import '../l10n/l10n.dart';
import '../models/market_models.dart';
import '../providers/auth_provider.dart';
import 'adaptive_plan_common.dart';
import 'adaptive_plan_details_sheet.dart';
import 'adaptive_plan_result.dart';

class AdaptivePositionPlanCard extends StatefulWidget {
  const AdaptivePositionPlanCard({
    required this.analysis,
    required this.candles,
    required this.onLearn,
    this.onShareSummary,
    super.key,
  });

  final Analysis analysis;

  /// Live candles for the chart shown inside the details sheet. The Adaptive
  /// calculation itself only ever uses the analysis' saved market snapshot.
  final List<MarketCandle> candles;
  final VoidCallback onLearn;

  /// Copy / save one side's plan summary as an image.
  final Future<void> Function(
    String action,
    AdaptiveSidePlan plan,
    AdaptiveCalculation calculation,
  )?
  onShareSummary;

  @override
  State<AdaptivePositionPlanCard> createState() =>
      _AdaptivePositionPlanCardState();
}

class _AdaptivePositionPlanCardState extends State<AdaptivePositionPlanCard> {
  final _margin = TextEditingController();
  final _loss = TextEditingController();
  final _marginFocus = FocusNode();
  final _lossFocus = FocusNode();
  StandardTradingRuleInstrument? _rule;
  AdaptiveAccountTier _tier = AdaptiveAccountTier.mini;
  AdaptiveRiskStyle _style = AdaptiveRiskStyle.conservative;
  AdaptiveCalculation? _calculation;
  bool _loading = false;
  String? _loadError;
  Timer? _expiryTimer;

  late _SnapshotInput _snapshot = _SnapshotInput.from(widget.analysis);

  @override
  void initState() {
    super.initState();
    _margin.addListener(_onMoneyChanged);
    _loss.addListener(_onMoneyChanged);
    _scheduleExpiry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadRule());
    });
  }

  @override
  void didUpdateWidget(covariant AdaptivePositionPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysis.id != widget.analysis.id ||
        oldWidget.analysis.marketSnapshot != widget.analysis.marketSnapshot ||
        oldWidget.analysis.validUntil != widget.analysis.validUntil) {
      _snapshot = _SnapshotInput.from(widget.analysis);
      _calculation = null;
      _scheduleExpiry();
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _margin.removeListener(_onMoneyChanged);
    _loss.removeListener(_onMoneyChanged);
    _margin.dispose();
    _loss.dispose();
    _marginFocus.dispose();
    _lossFocus.dispose();
    super.dispose();
  }

  bool get _expired => !widget.analysis.validUntil.isAfter(DateTime.now());

  /// A saved plan must vanish the moment its analysis stops being valid.
  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final remaining = widget.analysis.validUntil.difference(DateTime.now());
    if (remaining <= Duration.zero) return;
    // Timer durations are capped so a far-future validity cannot overflow.
    final wait = remaining > const Duration(days: 30)
        ? const Duration(days: 30)
        : remaining;
    _expiryTimer = Timer(wait, () {
      if (!mounted) return;
      if (_expired) {
        setState(() => _calculation = null);
      } else {
        _scheduleExpiry();
      }
    });
  }

  void _onMoneyChanged() {
    if (mounted) setState(() => _calculation = null);
  }

  Future<void> _loadRule() async {
    if (_loading || _rule != null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .tradingRules
          .getStandardTradingRules();
      if (!mounted || response.data == null) return;
      setState(() {
        _rule = adaptiveRuleFor(response.data!, widget.analysis.instrument);
        if (_rule == null) _loadError = context.l10n.instrumentRulesUnavailable;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = context.l10n.tradingRulesLoadFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  AdaptiveRule? get _selectedRule =>
      adaptiveMarketRule(widget.analysis.instrument, _rule, _tier);

  AdaptiveAnalysisContext get _context =>
      AdaptiveAnalysisContext.fromAnalysis(widget.analysis);

  Map<String, List<double>> _candidates(AdaptiveRule rule) =>
      adaptiveChartCandidates(
        _snapshot.candles,
        widget.analysis.tradePlan!,
        rule.minMovement,
      );

  Future<void> _calculate() async {
    final rule = _selectedRule;
    final tradePlan = widget.analysis.tradePlan;
    if (rule == null || tradePlan == null || _expired) return;
    final funds = _number(_margin.text);
    final loss = _number(_loss.text);
    final checkpoints = _candidates(rule);
    final now = DateTime.now();
    final recommendation = buildAdaptiveRecommendation(
      instrument: widget.analysis.instrument,
      tradePlan: tradePlan,
      availableMargin: funds,
      maximumLoss: loss,
      existingExposure: 0,
      standardRule: _rule,
      context: _context,
      checkpointPrices: checkpoints,
      candles: _snapshot.candles,
      accountTier: _tier,
      riskStyle: _style,
      now: now,
    );
    final tiers = compareAdaptiveAccountTiers(
      instrument: widget.analysis.instrument,
      tradePlan: tradePlan,
      availableMargin: funds,
      maximumLoss: loss,
      existingExposure: 0,
      standardRule: _rule,
      context: _context,
      checkpointPrices: checkpoints,
      candles: _snapshot.candles,
      riskStyle: _style,
      now: now,
    );
    final calculation = AdaptiveCalculation(
      recommendation: recommendation,
      tiers: tiers,
      tier: _tier,
      style: _style,
      availableFunds: funds ?? 0,
      maximumLoss: loss ?? 0,
    );
    setState(() => _calculation = calculation);
    final block = calculation.financialBlock;
    if (block != null) {
      final edit = await showAdaptiveFinancialBlockDialog(context, block);
      if (!mounted) return;
      if (edit == AdaptiveBlockedEdit.loss) _lossFocus.requestFocus();
      if (edit == AdaptiveBlockedEdit.funds) _marginFocus.requestFocus();
    }
  }

  Future<void> _showDetails() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AdaptivePlanDetailsSheet(
      analysis: widget.analysis,
      candles: widget.candles,
      standardRule: _rule,
      tier: _tier,
      style: _style,
      calculation: _expired ? null : _calculation,
      expired: _expired,
      snapshotCandleCount: _snapshot.candles.length,
      snapshotCandidates: _selectedRule == null
          ? const {'buy': [], 'sell': []}
          : _candidates(_selectedRule!),
      snapshotBasisIsLevelsOnly: _snapshot.candles.isEmpty,
      onLearn: widget.onLearn,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!isAdaptivePositionInstrument(widget.analysis.instrument) ||
        widget.analysis.tradePlan == null) {
      return const SizedBox.shrink();
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.adaptiveTradingPlan,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.l10n.adaptiveTradingPlanSubtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(18), child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (_loading) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          Text(l10n.adaptiveRulesLoading, style: TextStyle(color: muted)),
          const SizedBox(height: 12),
          _detailsTile(),
        ],
      );
    }
    if (_loadError != null || _rule == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveNotice(
            _loadError ?? l10n.adaptiveRulesError,
            warning: true,
            key: const ValueKey('adaptive-plan-rules-unavailable'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _loadRule,
              child: Text(l10n.adaptiveRefreshRules),
            ),
          ),
          const SizedBox(height: 18),
          _detailsTile(),
        ],
      );
    }
    final expired = _expired;
    final showResult = _calculation != null && !expired;
    final fetchedAt = _snapshot.sourceFetchedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expired) ...[
          AdaptiveNotice(
            l10n.adaptiveAnalysisExpired,
            warning: true,
            key: const ValueKey('adaptive-analysis-expired'),
          ),
          const SizedBox(height: 14),
        ] else if (_snapshot.candles.isEmpty) ...[
          AdaptiveNotice(
            l10n.adaptiveSnapshotLevelsOnlyDetail,
            warning: true,
            key: const ValueKey('adaptive-snapshot-warning'),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          l10n.fixedAccountRulesProfile,
          style: TextStyle(color: muted, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        AdaptiveOptionRow<AdaptiveAccountTier>(
          options: [
            for (final tier in AdaptiveAccountTier.values)
              (tier, adaptiveTierLabel(context, tier)),
          ],
          selected: _tier,
          onSelected: (tier) => setState(() {
            _tier = tier;
            _calculation = null;
          }),
        ),
        const SizedBox(height: 18),
        _MoneyRow(
          fieldKey: const ValueKey('adaptive-trading-capital'),
          label: l10n.tradingCapital,
          controller: _margin,
          focusNode: _marginFocus,
        ),
        const SizedBox(height: 12),
        _MoneyRow(
          fieldKey: const ValueKey('adaptive-loss-limit'),
          label: l10n.lossLimit,
          controller: _loss,
          focusNode: _lossFocus,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.riskStyle.toUpperCase(),
          style: TextStyle(color: muted, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        AdaptiveOptionRow<AdaptiveRiskStyle>(
          options: [
            for (final style in AdaptiveRiskStyle.values)
              (style, adaptiveRiskStyleLabel(context, style)),
          ],
          selected: _style,
          onSelected: (style) => setState(() {
            _style = style;
            _calculation = null;
          }),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.adaptiveIntradayOnly,
          style: TextStyle(color: muted, height: 1.5),
        ),
        if (fetchedAt != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.analysisCandleSnapshotFetched(
              DateFormat.yMd().add_jms().format(fetchedAt.toLocal()),
            ),
            key: const ValueKey('adaptive-candle-source-time'),
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const ValueKey('create-adaptive-recommendation'),
            onPressed: expired || _selectedRule == null ? null : _calculate,
            icon: const Icon(Icons.shield_outlined),
            label: Text(l10n.createRecommendation),
          ),
        ),
        if (showResult) ...[
          const SizedBox(height: 18),
          AdaptivePlanResult(
            calculation: _calculation!,
            instrument: widget.analysis.instrument,
            analysisPreferredSide:
                widget.analysis.tradePlan?.preferredSide.name ?? 'wait',
            onShare: widget.onShareSummary == null
                ? null
                : (action, plan) =>
                      widget.onShareSummary!(action, plan, _calculation!),
          ),
        ],
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 10),
        _detailsTile(),
      ],
    );
  }

  Widget _detailsTile() => _DetailsTile(
    title: context.l10n.understandDetails,
    count: adaptiveInvalidationRuleCount(
      widget.analysis.mode == AnalysisModeEnum.pro
          ? widget.analysis.invalidationConditions
          : widget.analysis.failureConditions,
    ),
    onTap: _showDetails,
  );
}

/// The saved market candles Adaptive may use: only a fresh snapshot for the
/// same instrument and timeframe as the analysis (web `matchingSnapshot`).
class _SnapshotInput {
  const _SnapshotInput(this.candles, this.sourceFetchedAt);

  factory _SnapshotInput.from(Analysis analysis) {
    final snapshot = analysis.marketSnapshot;
    if (snapshot == null ||
        snapshot.instrument != analysis.instrument ||
        snapshot.timeframe.toLowerCase() != analysis.timeframe.toLowerCase() ||
        snapshot.sourceStatus != MarketSnapshotSourceStatusEnum.fresh ||
        snapshot.sourceFetchedAt == null) {
      return const _SnapshotInput([], null);
    }
    bool valid(MarketSnapshotCandle c) {
      final open = c.open.toDouble();
      final high = c.high.toDouble();
      final low = c.low.toDouble();
      final close = c.close.toDouble();
      return high.isFinite &&
          low.isFinite &&
          low > 0 &&
          high >= low &&
          open.isFinite &&
          open >= low &&
          open <= high &&
          close.isFinite &&
          close >= low &&
          close <= high;
    }

    final candles =
        snapshot.candles.where(valid).map(AdaptiveCandle.fromSnapshot).toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));
    return _SnapshotInput(
      candles,
      candles.isEmpty ? null : snapshot.sourceFetchedAt,
    );
  }

  final List<AdaptiveCandle> candles;
  final DateTime? sourceFetchedAt;
}

int adaptiveInvalidationRuleCount(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return 0;
  return text
      .split(RegExp(r'(?:\r?\n)+|[•●]\s*'))
      .where((item) => item.trim().isNotEmpty)
      .length;
}

double? _number(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.focusNode,
  });
  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
      ],
      decoration: const InputDecoration(prefixText: r'$ ', hintText: '0'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              field,
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: field),
          ],
        );
      },
    );
  }
}

class _DetailsTile extends StatelessWidget {
  const _DetailsTile({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      ),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
    ),
    child: InkWell(
      key: const ValueKey('adaptive-plan-details'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (count > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count'),
              ),
              const SizedBox(width: 12),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// "Why can't I enter?" dialog
// ---------------------------------------------------------------------------

enum AdaptiveBlockedEdit { loss, funds }

Future<AdaptiveBlockedEdit?> showAdaptiveFinancialBlockDialog(
  BuildContext context,
  AdaptiveFinancialBlock block,
) => showDialog<AdaptiveBlockedEdit>(
  context: context,
  builder: (dialogContext) => _FinancialBlockDialog(block: block),
);

class _FinancialBlockDialog extends StatelessWidget {
  const _FinancialBlockDialog({required this.block});
  final AdaptiveFinancialBlock block;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final description = block.reason == AdaptiveTierActionReason.both
        ? l10n.adaptiveBlockedBoth
        : block.riskBlocked
        ? l10n.adaptiveBlockedRisk
        : l10n.adaptiveBlockedFunds;
    final next = block.reason == AdaptiveTierActionReason.both
        ? l10n.adaptiveBlockedBothNext
        : block.riskBlocked
        ? l10n.adaptiveBlockedRiskNext
        : l10n.adaptiveBlockedFundsNext;
    return AlertDialog(
      key: const ValueKey('adaptive-blocked-dialog'),
      title: Text(l10n.adaptiveBlockedTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 14),
            AdaptivePanel(
              key: const ValueKey('adaptive-blocked-figures'),
              children: [
                if (block.riskBlocked)
                  AdaptiveMetricRows([
                    AdaptiveMetric(
                      l10n.hardLossMaximum,
                      fmt.money(block.maximumLoss, 4),
                    ),
                    AdaptiveMetric(
                      l10n.minimumRiskAtStop,
                      fmt.requiredFunds(block.riskAtStop),
                    ),
                    AdaptiveMetric(
                      l10n.adaptiveBlockedRiskGap,
                      fmt.requiredFunds(block.riskAtStop - block.maximumLoss),
                      color: context.adaptiveAmber,
                    ),
                  ]),
                if (block.riskBlocked && block.fundsBlocked)
                  const Divider(height: 22),
                if (block.fundsBlocked)
                  AdaptiveMetricRows([
                    AdaptiveMetric(
                      l10n.tradingCapital,
                      fmt.money(block.availableMargin, 4),
                    ),
                    AdaptiveMetric(
                      l10n.brokerFundsAtStop,
                      fmt.requiredFunds(block.fundsAtStop),
                    ),
                    AdaptiveMetric(
                      l10n.adaptiveBlockedFundsGap,
                      fmt.requiredFunds(
                        block.fundsAtStop - block.availableMargin,
                      ),
                      color: context.adaptiveAmber,
                    ),
                  ]),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              next,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (block.riskBlocked)
                FilledButton(
                  key: const ValueKey('adaptive-blocked-edit-loss'),
                  onPressed: () =>
                      Navigator.pop(context, AdaptiveBlockedEdit.loss),
                  child: Text(l10n.adaptiveBlockedEditLoss),
                ),
              if (block.riskBlocked && block.fundsBlocked)
                const SizedBox(height: 8),
              if (block.fundsBlocked)
                FilledButton(
                  key: const ValueKey('adaptive-blocked-edit-funds'),
                  onPressed: () =>
                      Navigator.pop(context, AdaptiveBlockedEdit.funds),
                  child: Text(l10n.adaptiveBlockedEditFunds),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('adaptive-blocked-dismiss'),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.adaptiveBlockedDismiss),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
