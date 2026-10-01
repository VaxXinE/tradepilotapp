import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/analysis/adaptive_position_plan.dart';
import '../l10n/l10n.dart';
import '../models/market_models.dart';
import '../services/adaptive_plan_report.dart';
import 'adaptive_plan_common.dart';
import 'adaptive_plan_result.dart';
import 'analysis_levels_chart.dart';

/// "Understand the details": why the analysis said what it said, how Adaptive
/// turned it into a plan, the account rules used, and a printable guide.
class AdaptivePlanDetailsSheet extends StatelessWidget {
  const AdaptivePlanDetailsSheet({
    required this.analysis,
    required this.candles,
    required this.standardRule,
    required this.tier,
    required this.style,
    required this.calculation,
    required this.expired,
    required this.snapshotCandleCount,
    required this.snapshotCandidates,
    required this.snapshotBasisIsLevelsOnly,
    required this.onLearn,
    super.key,
  });

  final Analysis analysis;
  final List<MarketCandle> candles;
  final StandardTradingRuleInstrument? standardRule;
  final AdaptiveAccountTier tier;
  final AdaptiveRiskStyle style;
  final AdaptiveCalculation? calculation;
  final bool expired;
  final int snapshotCandleCount;
  final Map<String, List<double>> snapshotCandidates;
  final bool snapshotBasisIsLevelsOnly;
  final VoidCallback onLearn;

  AdaptiveRule? get _rule =>
      adaptiveMarketRule(analysis.instrument, standardRule, tier);

  String? get _invalidationConditions => analysis.mode == AnalysisModeEnum.pro
      ? analysis.invalidationConditions
      : analysis.failureConditions;

  Set<String> get _sources => {
    ...?analysis.fundamentalCitations?.newsTitles,
    ...?analysis.fundamentalCitations?.calendarEvents,
  };

  /// Candles up to the moment of analysis, never today's live chart.
  List<MarketCandle> get _chartCandles => candles
      .where((candle) => !candle.date.isAfter(analysis.createdAt))
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final rule = _rule;
    final calc = calculation;
    final rec = calc?.recommendation;
    final chartCandles = _chartCandles;
    final invalidation = _invalidationConditions;

    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        color: scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.understandDetails,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.understandDetailsSubtitle,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _sectionTitle(l10n.whyThisAnalysis),
                  if (adaptiveHas(invalidation)) ...[
                    _WarningBlock(
                      title: l10n.analysisInvalidWhen,
                      body: invalidation!.trim(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (adaptiveHas(analysis.opportunity)) ...[
                    _DetailSection(
                      title: l10n.opportunity,
                      body: analysis.opportunity!.trim(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (adaptiveHas(analysis.risk)) ...[
                    _DetailSection(
                      title: l10n.riskTitle,
                      body: analysis.risk!.trim(),
                      titleColor: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AdaptiveDetailsExpansion(
                    title: l10n.scenariosSupportingFactors,
                    children: [
                      _sectionTitle(l10n.scenarios),
                      _optionalDetail(l10n.scenarioMain, analysis.mainScenario),
                      _optionalDetail(
                        l10n.scenarioAlternative,
                        analysis.alternativeScenario,
                      ),
                      _DetailSection(
                        title: l10n.scenarioWait,
                        body: l10n.executionScenarioCBody,
                      ),
                      _optionalDetail(
                        l10n.technicalDrivers,
                        analysis.keyDriversTechnical,
                      ),
                      _optionalDetail(
                        l10n.fundamentalDrivers,
                        analysis.keyDriversFundamental,
                      ),
                      if (_sources.isNotEmpty) _SourceChips(sources: _sources),
                      _optionalDetail(
                        l10n.marketContext,
                        analysis.marketContext,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 14),
                  Container(
                    key: const ValueKey('adaptive-education-chart'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.chartShareTitle} · ${analysis.instrument} · ${analysis.timeframe}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (chartCandles.length >= 2)
                          AnalysisLevelsChart(
                            candles: chartCandles,
                            tradePlan: analysis.tradePlan,
                            tradingBias: analysis.tradingBias,
                          )
                        else
                          Text(
                            l10n.adaptiveGuideChartUnavailable,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.adaptiveGuideChartCaption,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rec != null) ...[
                    const SizedBox(height: 24),
                    _reasoning(context, rec),
                  ],
                  const SizedBox(height: 24),
                  _sectionTitle(l10n.wherePlanComesFrom),
                  AdaptiveNotice(_candidateStatusText(context)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.adaptiveScenariosReviewHelp,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AdaptiveDetailsExpansion(
                    title: l10n.sourceLayeredPlan,
                    children: [
                      Text(
                        l10n.adaptiveAnalysisBasis,
                        style: const TextStyle(height: 1.55),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.adaptiveChartConfirmation,
                        style: const TextStyle(height: 1.55),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.adaptiveDirectionHelp,
                        style: const TextStyle(height: 1.55),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: context.adaptiveAmber,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.adaptiveDisclaimer,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 14),
                  _sectionTitle(l10n.adaptiveAccountTitle),
                  Text(switch (tier) {
                    AdaptiveAccountTier.micro => l10n.adaptiveAccountMicroDesc,
                    AdaptiveAccountTier.mini => l10n.adaptiveAccountMiniDesc,
                    AdaptiveAccountTier.regular =>
                      l10n.adaptiveAccountRegularDesc,
                  }, style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  AdaptiveNotice(l10n.adaptiveSupportedInstruments),
                  if (rule != null) ...[
                    const SizedBox(height: 12),
                    _accountRule(context, rule),
                  ],
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: l10n.tradingCapital,
                    body: l10n.tradingCapitalHelp,
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: l10n.lossLimit,
                    body: l10n.lossLimitHelp,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 14),
                  _sectionTitle(l10n.riskStyle),
                  Text(
                    adaptiveRiskStyleLabel(context, style),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _riskStyleDescription(context, rule),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.riskStyleHelp,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  if (rec != null && calc != null) ...[
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 14),
                    _insights(context, calc),
                  ],
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onLearn();
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(l10n.learn),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  key: const ValueKey('adaptive-print-details'),
                  onPressed: () => unawaited(_printReport(context)),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(l10n.printSavePdf),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- pieces ---------------------------------------------------------------

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    ),
  );

  Widget _optionalDetail(String title, String? body) => adaptiveHas(body)
      ? Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _DetailSection(title: title, body: body!.trim()),
        )
      : const SizedBox.shrink();

  String _candidateStatusText(BuildContext context) {
    final l10n = context.l10n;
    if (expired) return l10n.adaptiveAnalysisExpired;
    if (snapshotBasisIsLevelsOnly) return l10n.adaptiveSnapshotLevelsOnly;
    return l10n.planCandidateSummary(
      snapshotCandidates['buy']?.length ?? 0,
      snapshotCandidates['sell']?.length ?? 0,
    );
  }

  String _postureText(BuildContext context, AdaptivePosture posture) =>
      switch (posture) {
        AdaptivePosture.scalingAllowed =>
          context.l10n.adaptivePostureScalingAllowed,
        AdaptivePosture.entryOnly => context.l10n.adaptivePostureEntryOnly,
        AdaptivePosture.notRecommended =>
          context.l10n.adaptivePostureNotRecommended,
      };

  String _reasonText(
    BuildContext context,
    String code,
    AdaptivePlanContext ctx,
  ) {
    final l10n = context.l10n;
    final technical = ctx.technical;
    return switch (code) {
      'context_unavailable' => l10n.adaptiveReasonContextUnavailable,
      'short_timeframe' => l10n.adaptiveReasonShortTimeframe(
        ctx.timeframe ?? '—',
      ),
      'high_risk' => l10n.adaptiveReasonHighRisk,
      'volatile_market' => l10n.adaptiveReasonVolatileMarket,
      'low_confidence' => l10n.adaptiveReasonLowConfidence(
        '${ctx.confidenceMax ?? '—'}',
      ),
      'range_supports_scaling' => l10n.adaptiveReasonRangeSupportsScaling,
      'trend_favors_buy' => l10n.adaptiveReasonTrendFavorsBuy,
      'trend_favors_sell' => l10n.adaptiveReasonTrendFavorsSell,
      'trend_opposes_buy' => l10n.adaptiveReasonTrendOpposesBuy,
      'trend_opposes_sell' => l10n.adaptiveReasonTrendOpposesSell,
      'technical_supports_buy' => l10n.adaptiveReasonTechnicalSupportsBuy(
        '${technical?.buy ?? 0}',
        '${technical?.sell ?? 0}',
      ),
      'technical_supports_sell' => l10n.adaptiveReasonTechnicalSupportsSell(
        '${technical?.buy ?? 0}',
        '${technical?.sell ?? 0}',
      ),
      'technical_mixed' => l10n.adaptiveReasonTechnicalMixed,
      'technical_unavailable' => l10n.adaptiveReasonTechnicalUnavailable,
      'neutral_bias' => l10n.adaptiveReasonNeutralBias,
      'fundamental_high_impact' => l10n.adaptiveReasonFundamentalHighImpact(
        '${ctx.fundamental.highImpactCount}',
      ),
      'fundamental_present' => l10n.adaptiveReasonFundamentalPresent(
        '${ctx.fundamental.eventCount}',
        '${ctx.fundamental.newsCount}',
      ),
      'fundamental_clear' => l10n.adaptiveReasonFundamentalClear,
      'fundamental_unavailable' => l10n.adaptiveReasonFundamentalUnavailable,
      'directional_conflict' => l10n.adaptiveReasonDirectionalConflict,
      'staged_add_condition' => l10n.adaptiveReasonStagedAddCondition,
      _ => code,
    };
  }

  List<String> _reasonLines(BuildContext context, AdaptiveRecommendation rec) =>
      [
        for (final code in rec.reasonCodes.toSet())
          _reasonText(context, code, rec.context),
      ];

  String _technicalLine(BuildContext context, AdaptivePlanContext ctx) =>
      context.l10n.adaptiveContextTechnical(
        '${ctx.technical?.buy ?? '—'}',
        '${ctx.technical?.neutral ?? '—'}',
        '${ctx.technical?.sell ?? '—'}',
      );

  String _fundamentalLine(BuildContext context, AdaptivePlanContext ctx) =>
      ctx.fundamental.available
      ? context.l10n.adaptiveContextFundamental(
          '${ctx.fundamental.eventCount}',
          '${ctx.fundamental.highImpactCount}',
          '${ctx.fundamental.newsCount}',
        )
      : context.l10n.adaptiveContextFundamentalUnavailable;

  Widget _reasoning(BuildContext context, AdaptiveRecommendation rec) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('adaptive-plan-reasoning'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .05),
        border: Border.all(color: scheme.primary.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adaptiveReasoningTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _postureText(context, rec.posture),
                  style: const TextStyle(height: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Chip(
                label: Text(
                  rec.context.timeframe ?? l10n.adaptiveContextMissing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final line in _reasonLines(context, rec))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $line',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
              ),
            ),
          const Divider(height: 22),
          Text(
            _technicalLine(context, rec.context),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Text(
            _fundamentalLine(context, rec.context),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _accountRule(BuildContext context, AdaptiveRule rule) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tierLabel = adaptiveTierLabel(context, tier);
    final text = rule.maximumLot == null
        ? l10n.adaptiveAccountRuleUncapped(
            fmt.money(rule.marginAtMinimumLot),
            fmt.number(rule.minimumLot),
            fmt.number(rule.contractSize),
            tierLabel,
            rule.contractUnit,
          )
        : l10n.adaptiveAccountRule(
            fmt.money(rule.marginAtMinimumLot),
            fmt.number(rule.minimumLot),
            fmt.number(rule.maximumLot),
            fmt.number(rule.contractSize),
            tierLabel,
            rule.contractUnit,
          );
    final tierRules = [
      for (final t in AdaptiveAccountTier.values)
        adaptiveMarketRule(analysis.instrument, standardRule, t),
    ];
    return AdaptivePanel(
      key: const ValueKey('adaptive-account-rule'),
      children: [
        Text(text, style: const TextStyle(height: 1.5)),
        if (tierRules.every((r) => r != null)) ...[
          const SizedBox(height: 10),
          AdaptiveDetailsExpansion(
            key: const ValueKey('adaptive-contract-table'),
            title: l10n.adaptiveContractTableTitle,
            children: [
              Text(
                l10n.adaptiveContractMinimumBasis(fmt.number(rule.minimumLot)),
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
              ),
              const SizedBox(height: 8),
              AdaptiveMetricRows([
                AdaptiveMetric(
                  l10n.adaptiveContractTier,
                  l10n.adaptiveContractValue,
                ),
                for (final r in tierRules)
                  AdaptiveMetric(
                    adaptiveTierLabel(context, r!.accountTier),
                    '${fmt.number(r.contractSize)} ${r.contractUnit}',
                  ),
              ]),
              const SizedBox(height: 6),
              Text(
                l10n.adaptiveContractMicroAssumption,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
        if (rule.minimumOpeningFunds != null) ...[
          const SizedBox(height: 10),
          Text(
            l10n.adaptiveAccountOpeningMinimum(
              fmt.money(rule.minimumOpeningFunds),
            ),
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
        ],
      ],
    );
  }

  String _riskStyleDescription(BuildContext context, AdaptiveRule? rule) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final maximum = rule?.maximumLot == null
        ? l10n.adaptiveNoFixedCap
        : fmt.number(rule!.maximumLot);
    return switch (style) {
      AdaptiveRiskStyle.conservative => l10n.adaptiveRiskStyleConservativeDesc,
      AdaptiveRiskStyle.balanced => l10n.adaptiveRiskStyleBalancedDesc,
      AdaptiveRiskStyle.aggressive =>
        rule?.maximumLot == null
            ? l10n.adaptiveRiskStyleAggressiveDescUncapped
            : l10n.adaptiveRiskStyleAggressiveDesc(maximum),
    };
  }

  String _sideStatusText(
    BuildContext context,
    AdaptiveRecommendation rec,
    String side,
  ) {
    final l10n = context.l10n;
    final name = side.toUpperCase();
    return switch (rec.evaluationFor(side).status) {
      AdaptiveSideStatus.viable => l10n.adaptiveSideReady(name),
      AdaptiveSideStatus.blocked => l10n.adaptiveSideBlocked(name),
      AdaptiveSideStatus.notAligned =>
        rec.preferredSide == 'none'
            ? l10n.adaptiveSideConditional(name)
            : l10n.adaptiveSideNotAligned(name),
      AdaptiveSideStatus.unavailable => l10n.adaptiveSideUnavailable(name),
    };
  }

  String? _blockerText(BuildContext context, AdaptiveMinimumLotDiagnostic? d) {
    if (d == null) return null;
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    return switch (d.blocker) {
      AdaptiveBlocker.margin => l10n.adaptiveMinimumBlockerMargin(
        fmt.requiredFunds(d.marginShortfall),
      ),
      AdaptiveBlocker.risk => l10n.adaptiveMinimumBlockerRisk(
        fmt.money(d.effectiveLossBudget),
        fmt.money(d.riskAtStop),
      ),
      AdaptiveBlocker.marginAndRisk => l10n.adaptiveMinimumBlockerBoth(
        fmt.money(d.effectiveLossBudget),
        fmt.requiredFunds(d.marginShortfall),
        fmt.money(d.riskAtStop),
      ),
      AdaptiveBlocker.direction => l10n.adaptiveMinimumBlockerDirection,
      AdaptiveBlocker.analysis => l10n.adaptiveMinimumBlockerAnalysis,
    };
  }

  String? _actionText(BuildContext context, AdaptiveMinimumLotDiagnostic? d) {
    if (d == null) return null;
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    return switch (d.nextAction) {
      AdaptiveNextAction.funds => l10n.adaptiveMinimumActionFunds(
        fmt.requiredFunds(d.marginShortfall),
      ),
      AdaptiveNextAction.lossBudget => l10n.adaptiveMinimumActionLoss(
        fmt.money(d.maximumLossShortfall),
      ),
      AdaptiveNextAction.fundsAndLossBudget => l10n.adaptiveMinimumActionBoth(
        fmt.requiredFunds(d.marginShortfall),
        fmt.money(d.maximumLossShortfall),
      ),
      AdaptiveNextAction.reanalysis => l10n.adaptiveMinimumActionReanalysis,
      AdaptiveNextAction.wait => l10n.entryDirectionUnconfirmedNextAction,
    };
  }

  String _alternativeText(BuildContext context, AdaptiveCalculation calc) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final alt = calc.recommendation.candleAlternative;
    if (!alt.available) {
      return calc.financialOnlyBlock
          ? l10n.adaptiveCompareFinancialNoAlternative
          : l10n.adaptiveAlternativeNoLevels;
    }
    final rule = calc.rule;
    final profit =
        (alt.takeProfit! - alt.entry!).abs() *
        (rule == null ? 0 : rule.contractSize * alt.lot! / rule.minimumLot);
    return l10n.adaptiveAlternativeBasis(
      fmt.number(alt.entry, 4),
      fmt.money(alt.estimatedLoss),
      fmt.number(alt.lot),
      fmt.money(alt.dayMargin),
      fmt.money(profit),
      fmt.number(alt.riskReward),
      alt.side!.toUpperCase(),
      fmt.number(alt.stopLoss, 4),
      fmt.number(alt.takeProfit, 4),
    );
  }

  Widget _insights(BuildContext context, AdaptiveCalculation calc) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rec = calc.recommendation;
    final volatility = rec.volatility;
    return Column(
      key: const ValueKey('adaptive-insights'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(l10n.adaptiveInsightsTitle),
        if (!rec.valid) ...[
          Text(
            calc.hasConditionalScenarios
                ? l10n.adaptiveConditionalOverviewHelp
                : l10n.adaptiveInvalidDescription,
            style: TextStyle(color: context.adaptiveAmber, height: 1.45),
          ),
          const SizedBox(height: 12),
        ],
        AdaptivePanel(
          key: const ValueKey('adaptive-timeframe-volatility'),
          children: [
            Text(
              l10n.adaptiveVolatilityTitle(rec.context.timeframe ?? '—'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            if (volatility.observedRange == null)
              Text(
                l10n.adaptiveVolatilityUnavailable,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
              )
            else ...[
              Text(
                l10n.adaptiveVolatilityObserved(
                  '${volatility.candleCount}',
                  fmt.number(volatility.observedRange, 4),
                ),
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
              ),
              for (final side in calc.tightStops)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.adaptiveVolatilityTight(
                      fmt.number(
                        side == 'buy'
                            ? volatility.buyStopDistance
                            : volatility.sellStopDistance,
                        4,
                      ),
                      side.toUpperCase(),
                    ),
                    style: TextStyle(
                      color: context.adaptiveAmber,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
            ],
          ],
        ),
        if (calc.showAlternative) ...[
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('adaptive-alternative'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.adaptiveAmber.withValues(alpha: .09),
              border: Border.all(
                color: context.adaptiveAmber.withValues(alpha: .4),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adaptiveAlternativeTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  _alternativeText(context, calc),
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adaptiveAlternativeUnchanged,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rec.candleAlternative.available
                      ? l10n.adaptiveAlternativeAvailableShort
                      : calc.financialOnlyBlock
                      ? l10n.adaptiveCompareNoCredit
                      : l10n.adaptiveAlternativeUnavailableShort,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final side in const ['buy', 'sell']) ...[
          _sideEvaluation(context, rec, side),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _sideEvaluation(
    BuildContext context,
    AdaptiveRecommendation rec,
    String side,
  ) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final scheme = Theme.of(context).colorScheme;
    final evaluation = rec.evaluationFor(side);
    final diagnostic = evaluation.diagnostic;
    final viable = evaluation.status == AdaptiveSideStatus.viable;
    final rule = rec.result.rule;
    final blocker = _blockerText(context, diagnostic);
    final action = _actionText(context, diagnostic);
    return Container(
      key: ValueKey('adaptive-side-status-$side'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: viable
            ? context.adaptiveBuyColor.withValues(alpha: .08)
            : scheme.surfaceContainerHighest.withValues(alpha: .5),
        border: Border.all(
          color: viable
              ? context.adaptiveBuyColor.withValues(alpha: .4)
              : scheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sideStatusText(context, rec, side),
            style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
          ),
          if (diagnostic != null && rule != null) ...[
            const SizedBox(height: 6),
            Text(
              l10n.adaptiveMinimumTier(
                fmt.number(diagnostic.lot),
                adaptiveTierLabel(context, rule.accountTier),
              ),
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            Text(
              l10n.adaptiveMinimumNumbers(
                fmt.money(diagnostic.effectiveLossBudget),
                fmt.money(diagnostic.marginRequired),
                fmt.money(diagnostic.riskAtStop),
                fmt.money(diagnostic.fundsRequiredAtStop),
              ),
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            if (blocker != null) ...[
              const SizedBox(height: 4),
              Text(
                blocker,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 4),
              Text(
                action,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // -- printing -------------------------------------------------------------

  AdaptivePlanReport _buildReport(BuildContext context) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final locale = Localizations.localeOf(context);
    final rule = _rule;
    final calc = calculation;
    final rec = calc?.recommendation;
    ReportBlock? detail(String title, String? body) => adaptiveHas(body)
        ? ReportBlock.paragraph('**$title**\n${body!.trim()}')
        : null;
    List<ReportBlock> blocks(Iterable<ReportBlock?> items) =>
        items.whereType<ReportBlock>().toList();

    // The plan currently under review, exactly as the on-screen result shows.
    final primarySide = calc?.preferredSide(
      analysis.tradePlan?.preferredSide.name ?? 'wait',
    );
    final primaryPlan = primarySide == null ? null : calc?.planFor(primarySide);
    final actionable =
        !expired &&
        calc != null &&
        primaryPlan != null &&
        rec!.valid &&
        rec.evaluationFor(primaryPlan.side).status ==
            AdaptiveSideStatus.viable &&
        rec.result.sideOf(primaryPlan.side) != null;
    final budget = primaryPlan == null
        ? null
        : calc?.budgetFor(primaryPlan.side);
    final planBlocks = actionable && budget != null
        ? <ReportBlock>[
            ReportBlock.paragraph(
              '${l10n.adaptiveGuideReviewStatus(primaryPlan.side.toUpperCase())} · '
              '${adaptiveRiskStyleLabel(context, budget.riskStyle)}',
            ),
            ReportBlock.subheading(l10n.adaptiveLayerPlanTitle),
            for (final layer in primaryPlan.layers)
              ReportBlock.item(
                '${layer.level + 1}. ${fmt.number(layer.price, 4)} · '
                '${fmt.number(layer.lot)} ${l10n.adaptiveLot}',
              ),
            ReportBlock.paragraph(
              'SL: ${fmt.number(primaryPlan.stopLoss, 4)}'
              '${primaryPlan.takeProfit1 == null ? '' : ' · TP1: ${fmt.number(primaryPlan.takeProfit1, 4)}'}'
              '${primaryPlan.takeProfit2 == null ? '' : ' · TP2: ${fmt.number(primaryPlan.takeProfit2, 4)}'}',
            ),
            ReportBlock.paragraph(
              '${l10n.adaptiveSnapshotTotalLots}: ${fmt.number(primaryPlan.totalLots)} ${l10n.adaptiveLot}',
            ),
            ReportBlock.subheading(l10n.riskContext),
            ReportBlock.paragraph(
              '${l10n.adaptiveMarginRequired}: ${fmt.money(primaryPlan.marginRequired)} · '
              '${l10n.estimatedMaximumLoss}: ${fmt.money(primaryPlan.estimatedLoss)} · '
              '${l10n.usableRiskBudget}: ${fmt.money(budget.usableRiskBudget)}',
            ),
            ReportBlock.paragraph(l10n.adaptiveCopyManualContext),
          ]
        : [
            ReportBlock.paragraph(
              expired
                  ? l10n.adaptiveAnalysisExpired
                  : calc == null
                  ? l10n.adaptiveGuideNoPlan
                  : calc.hasConditionalScenarios
                  ? l10n.entryDirectionUnconfirmedBody
                  : l10n.adaptiveInvalidDescription,
            ),
          ];

    final decision = expired
        ? l10n.adaptiveAnalysisExpired
        : calc == null
        ? l10n.adaptiveReady
        : !rec!.valid
        ? (calc.hasConditionalScenarios
              ? l10n.entryDirectionUnconfirmedBody
              : l10n.adaptiveInvalidDescription)
        : l10n.planReadyToReview;
    final invalidationCount = adaptiveInvalidationRuleCount(
      _invalidationConditions,
    );

    return AdaptivePlanReport(
      title: l10n.adaptiveGuideTitle,
      instrument: analysis.instrument,
      timeframe: analysis.timeframe,
      analyzedAt: DateFormat.yMMMd(
        locale.toString(),
      ).add_Hm().format(analysis.createdAt.toLocal()),
      summary: [
        l10n.adaptiveGuideOpening(analysis.instrument, analysis.timeframe),
        decision,
        if (invalidationCount > 0)
          l10n.adaptiveShareInvalidation('$invalidationCount'),
        l10n.adaptiveShareSnapshotNote,
      ].join('\n'),
      briefLabel: l10n.reportBriefingTitle,
      sections: [
        ReportSection(
          l10n.whyThisAnalysis,
          blocks([
            if (adaptiveHas(_invalidationConditions))
              ReportBlock.paragraph(
                '**${l10n.analysisInvalidWhen}**\n${_invalidationConditions!.trim()}',
              ),
            detail(l10n.opportunity, analysis.opportunity),
            detail(l10n.riskTitle, analysis.risk),
          ]),
        ),
        ReportSection(
          l10n.scenarios,
          blocks([
            detail(l10n.scenarioMain, analysis.mainScenario),
            detail(l10n.scenarioAlternative, analysis.alternativeScenario),
            ReportBlock.paragraph(
              '**${l10n.scenarioWait}**\n${l10n.executionScenarioCBody}',
            ),
            detail(l10n.technicalDrivers, analysis.keyDriversTechnical),
            detail(l10n.fundamentalDrivers, analysis.keyDriversFundamental),
            detail(l10n.marketContext, analysis.marketContext),
          ]),
        ),
        if (rec != null)
          ReportSection(l10n.adaptiveReasoningTitle, [
            ReportBlock.paragraph(_postureText(context, rec.posture)),
            for (final line in _reasonLines(context, rec))
              ReportBlock.item(line),
            ReportBlock.paragraph(_technicalLine(context, rec.context)),
            ReportBlock.paragraph(_fundamentalLine(context, rec.context)),
          ]),
        ReportSection(l10n.adaptiveGuideDirectionTitle, planBlocks),
        ReportSection(l10n.wherePlanComesFrom, [
          ReportBlock.paragraph(_candidateStatusText(context)),
          ReportBlock.paragraph(l10n.adaptiveScenariosReviewHelp),
          ReportBlock.paragraph(
            '**${l10n.sourceLayeredPlan}**\n${l10n.adaptiveAnalysisBasis}\n'
            '${l10n.adaptiveChartConfirmation}\n${l10n.adaptiveDirectionHelp}',
          ),
        ]),
        ReportSection(l10n.adaptiveAccountTitle, [
          ReportBlock.paragraph(switch (tier) {
            AdaptiveAccountTier.micro => l10n.adaptiveAccountMicroDesc,
            AdaptiveAccountTier.mini => l10n.adaptiveAccountMiniDesc,
            AdaptiveAccountTier.regular => l10n.adaptiveAccountRegularDesc,
          }),
          ReportBlock.paragraph(l10n.adaptiveSupportedInstruments),
          if (rule != null)
            ReportBlock.paragraph(
              rule.maximumLot == null
                  ? l10n.adaptiveAccountRuleUncapped(
                      fmt.money(rule.marginAtMinimumLot),
                      fmt.number(rule.minimumLot),
                      fmt.number(rule.contractSize),
                      adaptiveTierLabel(context, tier),
                      rule.contractUnit,
                    )
                  : l10n.adaptiveAccountRule(
                      fmt.money(rule.marginAtMinimumLot),
                      fmt.number(rule.minimumLot),
                      fmt.number(rule.maximumLot),
                      fmt.number(rule.contractSize),
                      adaptiveTierLabel(context, tier),
                      rule.contractUnit,
                    ),
            ),
          ReportBlock.paragraph(
            '**${l10n.tradingCapital}**\n${l10n.tradingCapitalHelp}',
          ),
          ReportBlock.paragraph('**${l10n.lossLimit}**\n${l10n.lossLimitHelp}'),
        ]),
        ReportSection(l10n.riskStyle, [
          ReportBlock.paragraph(
            '**${adaptiveRiskStyleLabel(context, style)}**\n'
            '${_riskStyleDescription(context, rule)}\n${l10n.riskStyleHelp}',
          ),
        ]),
        if (rec != null && calc != null)
          ReportSection(l10n.adaptiveInsightsTitle, [
            ReportBlock.paragraph(
              l10n.adaptiveVolatilityTitle(rec.context.timeframe ?? '—'),
            ),
            ReportBlock.paragraph(
              rec.volatility.observedRange == null
                  ? l10n.adaptiveVolatilityUnavailable
                  : l10n.adaptiveVolatilityObserved(
                      '${rec.volatility.candleCount}',
                      fmt.number(rec.volatility.observedRange, 4),
                    ),
            ),
            if (calc.showAlternative)
              ReportBlock.paragraph(
                '**${l10n.adaptiveAlternativeTitle}**\n${_alternativeText(context, calc)}',
              ),
            for (final side in const ['buy', 'sell'])
              ReportBlock.paragraph(_sideStatusText(context, rec, side)),
          ]),
      ],
      sourcesTitle: l10n.citationsLabel,
      sources: _sources.toList(),
      disclaimer:
          '${l10n.adaptiveGuideDisclaimer} ${l10n.adaptiveShareAudienceNote}',
      referenceId: 'Analysis #${analysis.id}',
    );
  }

  Future<void> _printReport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = context.l10n.printableReportOpenFailed;
    try {
      await printAdaptivePlanReport(_buildReport(context));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }
}

int adaptiveInvalidationRuleCount(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return 0;
  return text
      .split(RegExp(r'(?:\r?\n)+|[•●]\s*'))
      .where((item) => item.trim().isNotEmpty)
      .length;
}

class _WarningBlock extends StatelessWidget {
  const _WarningBlock({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.error.withValues(alpha: .1),
      border: Border.all(color: Theme.of(context).colorScheme.error),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(height: 1.5)),
      ],
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.body,
    this.titleColor,
  });
  final String title;
  final String body;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w900, color: titleColor),
      ),
      const SizedBox(height: 6),
      Text(body, style: const TextStyle(height: 1.55)),
    ],
  );
}

class _SourceChips extends StatelessWidget {
  const _SourceChips({required this.sources});
  final Set<String> sources;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final source in sources)
          Chip(
            avatar: const Icon(Icons.article_outlined, size: 16),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(source, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    ),
  );
}
