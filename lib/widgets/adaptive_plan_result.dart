import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/analysis/adaptive_position_plan.dart';
import '../core/analysis/adaptive_tier_comparison.dart';
import '../l10n/l10n.dart';
import 'adaptive_plan_common.dart';

/// Budget figures shown next to a side plan (web `AdaptiveSnapshotBudget`).
class AdaptiveSnapshotBudget {
  const AdaptiveSnapshotBudget({
    required this.marginBudget,
    required this.maximumLoss,
    required this.usableRiskBudget,
    required this.riskUtilizationRate,
    required this.unusedRiskBuffer,
    required this.riskStyle,
  });

  final double marginBudget;
  final double maximumLoss;
  final double usableRiskBudget;
  final double riskUtilizationRate;
  final double unusedRiskBuffer;
  final AdaptiveRiskStyle riskStyle;
}

/// When the chosen tier cannot even afford the minimum lot (web
/// `FinancialBlock`): drives the "Why can't I enter?" dialog.
class AdaptiveFinancialBlock {
  const AdaptiveFinancialBlock({
    required this.reason,
    required this.riskAtStop,
    required this.fundsAtStop,
    required this.maximumLoss,
    required this.availableMargin,
  });

  final AdaptiveTierActionReason reason;
  final double riskAtStop;
  final double fundsAtStop;
  final double maximumLoss;
  final double availableMargin;

  bool get riskBlocked =>
      reason == AdaptiveTierActionReason.hardRisk ||
      reason == AdaptiveTierActionReason.both;
  bool get fundsBlocked =>
      reason == AdaptiveTierActionReason.funds ||
      reason == AdaptiveTierActionReason.both;
}

/// One completed calculation: the recommendation, the tier comparison and the
/// inputs that produced them.
class AdaptiveCalculation {
  const AdaptiveCalculation({
    required this.recommendation,
    required this.tiers,
    required this.tier,
    required this.style,
    required this.availableFunds,
    required this.maximumLoss,
  });

  final AdaptiveRecommendation recommendation;
  final Map<AdaptiveAccountTier, AdaptiveTierRow> tiers;
  final AdaptiveAccountTier tier;
  final AdaptiveRiskStyle style;
  final double availableFunds;
  final double maximumLoss;

  AdaptiveTierRow get selectedRow => tiers[tier]!;
  AdaptiveRule? get rule => recommendation.result.rule;

  AdaptiveSidePlan? planFor(String side) =>
      recommendation.result.sideOf(side) ??
      recommendation.evaluationFor(side).conditionalPlan;

  bool get hasConditionalScenarios =>
      recommendation.buyEvaluation.conditionalPlan != null ||
      recommendation.sellEvaluation.conditionalPlan != null;

  bool sideAvailable(String side) =>
      !recommendation.valid ||
      recommendation.result.sideOf(side) != null ||
      recommendation.evaluationFor(side).conditionalPlan != null;

  /// Which direction to open first (web `preferredAvailableSide`).
  String preferredSide(String analysisPreferred) {
    final decision = recommendation.preferredSide;
    if ((decision == 'buy' || decision == 'sell') && sideAvailable(decision)) {
      return decision;
    }
    if ((analysisPreferred == 'buy' || analysisPreferred == 'sell') &&
        sideAvailable(analysisPreferred)) {
      return analysisPreferred;
    }
    return sideAvailable('buy') ? 'buy' : 'sell';
  }

  AdaptiveSnapshotBudget? budgetFor(String side) {
    final budget = recommendation.budget;
    if (recommendation.valid &&
        recommendation.result.sideOf(side) != null &&
        budget != null) {
      return AdaptiveSnapshotBudget(
        marginBudget: budget.marginBudget,
        maximumLoss: budget.maximumLoss,
        usableRiskBudget: budget.usableRiskBudget,
        riskUtilizationRate: budget.riskUtilizationRate,
        unusedRiskBuffer: budget.unusedRiskBuffer,
        riskStyle: budget.riskStyle,
      );
    }
    final effective = recommendation
        .evaluationFor(side)
        .diagnostic
        ?.effectiveLossBudget;
    if (effective == null ||
        !effective.isFinite ||
        effective <= 0 ||
        maximumLoss <= 0 ||
        availableFunds <= 0 ||
        effective > maximumLoss) {
      return null;
    }
    return AdaptiveSnapshotBudget(
      marginBudget: availableFunds,
      maximumLoss: maximumLoss,
      usableRiskBudget: effective,
      riskUtilizationRate: effective / maximumLoss,
      unusedRiskBuffer: maximumLoss - effective,
      riskStyle: style,
    );
  }

  bool get showAlternative {
    final volatility = recommendation.volatility;
    final preferred = recommendation.preferredSide;
    return (preferred == 'buy' && volatility.stopLooksTight('buy')) ||
        (preferred == 'sell' && volatility.stopLooksTight('sell')) ||
        !recommendation.valid;
  }

  List<String> get tightStops => [
    for (final side in const ['buy', 'sell'])
      if (recommendation.volatility.stopLooksTight(side) &&
          recommendation.preferredSide == side)
        side,
  ];

  bool get financialOnlyBlock => const {
    AdaptiveTierActionReason.limited,
    AdaptiveTierActionReason.hardRisk,
    AdaptiveTierActionReason.funds,
    AdaptiveTierActionReason.both,
  }.contains(selectedRow.actionReason);

  /// The dialog shown right after calculating when funds / hard loss block it.
  AdaptiveFinancialBlock? get financialBlock {
    final row = selectedRow;
    final reason = row.actionReason;
    if (reason != AdaptiveTierActionReason.hardRisk &&
        reason != AdaptiveTierActionReason.funds &&
        reason != AdaptiveTierActionReason.both) {
      return null;
    }
    final side = row.preferredSide;
    final minimum = side == null ? null : row.sideOf(side);
    final risk = minimum?.riskAtStop;
    final funds = minimum?.fundsAtStop;
    if (risk == null ||
        !risk.isFinite ||
        funds == null ||
        !funds.isFinite ||
        !maximumLoss.isFinite ||
        !availableFunds.isFinite) {
      return null;
    }
    return AdaptiveFinancialBlock(
      reason: reason,
      riskAtStop: risk,
      fundsAtStop: funds,
      maximumLoss: maximumLoss,
      availableMargin: availableFunds,
    );
  }
}

/// Plain-text plan (web `buildAdaptivePlanCopyText`).
String adaptivePlanCopyText(
  BuildContext context, {
  required String instrument,
  required AdaptiveSidePlan plan,
  required AdaptiveSnapshotBudget budget,
}) {
  final l10n = context.l10n;
  final fmt = AdaptiveFormat.of(context);
  final lines = <String>[
    l10n.adaptiveCopyTitle,
    '${l10n.instrument}: $instrument',
    '${l10n.positionDirection}: ${plan.side.toUpperCase()}',
    '${l10n.riskStyle}: ${adaptiveRiskStyleLabel(context, budget.riskStyle)}',
    '',
    '${l10n.adaptiveLayerPlanTitle}:',
    for (final layer in plan.layers)
      '${layer.level + 1}. ${fmt.number(layer.price, 4)} · '
          '${fmt.number(layer.lot)} ${l10n.adaptiveLot}',
    'SL: ${fmt.number(plan.stopLoss, 4)}',
    if (plan.takeProfit1 != null) 'TP1: ${fmt.number(plan.takeProfit1, 4)}',
    if (plan.takeProfit2 != null) 'TP2: ${fmt.number(plan.takeProfit2, 4)}',
    '${l10n.adaptiveSnapshotTotalLots}: ${fmt.number(plan.totalLots)} '
        '${l10n.adaptiveLot}',
    '',
    '${l10n.riskContext}:',
    '${l10n.adaptiveMarginRequired}: ${fmt.money(plan.marginRequired)}',
    '${l10n.estimatedMaximumLoss}: ${fmt.money(plan.estimatedLoss)}',
    '${l10n.usableRiskBudget}: ${fmt.money(budget.usableRiskBudget)}',
    l10n.adaptiveCopyManualContext,
  ];
  return lines.join('\n');
}

String adaptiveRejectedReasonText(
  BuildContext context,
  AdaptiveRejectReason reason,
) => switch (reason) {
  AdaptiveRejectReason.analysisLimit => context.l10n.adaptiveRejectedAnalysis,
  AdaptiveRejectReason.dayMargin => context.l10n.adaptiveRejectedMargin,
  AdaptiveRejectReason.lossCeiling => context.l10n.adaptiveRejectedLoss,
  AdaptiveRejectReason.tierLimit => context.l10n.adaptiveRejectedTier,
};

String adaptiveStageReasonText(BuildContext context, AdaptiveLayer layer) {
  final l10n = context.l10n;
  final fmt = AdaptiveFormat.of(context);
  if (layer.level == 0) return l10n.adaptiveStageInitialReason;
  final basis = layer.basis == AdaptiveLayerBasis.entryZoneEdge
      ? l10n.adaptiveStageBasisEntryEdge
      : l10n.adaptiveStageBasisRiskCheckpoint(
          fmt.number(layer.invalidationProgress * 100, 0),
        );
  return l10n.adaptiveStageAddReason(
    basis,
    fmt.number(layer.distanceFromEntry, 4),
    '${layer.level + 1}',
    fmt.number(layer.lot),
    fmt.number(layer.price, 4),
    fmt.money(layer.riskThisPosition),
  );
}

// ---------------------------------------------------------------------------
// Decision summary
// ---------------------------------------------------------------------------

class AdaptiveDecisionSummary extends StatelessWidget {
  const AdaptiveDecisionSummary({
    required this.row,
    required this.maximumLoss,
    required this.availableMargin,
    super.key,
  });

  final AdaptiveTierRow row;
  final double? maximumLoss;
  final double? availableMargin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final scheme = Theme.of(context).colorScheme;
    final preferredSide = row.preferredSide;
    final preferred = preferredSide == null ? null : row.sideOf(preferredSide);
    final ready =
        (row.action == 'buy' || row.action == 'sell') &&
        preferred?.fit == AdaptiveTierFit.withinTarget &&
        preferred!.marketAligned &&
        row.recommendation.evaluationFor(row.action).status ==
            AdaptiveSideStatus.viable;
    final action = ready
        ? row.action
        : row.action == 'skip'
        ? 'skip'
        : 'wait';
    final label = switch (action) {
      'buy' => l10n.priceRiseScenario,
      'sell' => l10n.priceFallScenario,
      'skip' => l10n.adaptiveCompareSkip,
      _ => l10n.adaptiveCompareWait,
    };
    final sideName = preferredSide == 'buy'
        ? l10n.priceRiseScenario
        : l10n.priceFallScenario;
    final fundsShortfall =
        preferred?.fundsAtStop != null && availableMargin != null
        ? (preferred!.fundsAtStop! - availableMargin!).clamp(0, double.infinity)
        : 0.0;
    final hardRiskShortfall =
        preferred?.riskAtStop != null && maximumLoss != null
        ? (preferred!.riskAtStop! - maximumLoss!).clamp(0, double.infinity)
        : 0.0;
    final String detail;
    if (ready) {
      detail = l10n.scenarioFitsRisk(sideName);
    } else if (row.actionReason == AdaptiveTierActionReason.marketConflict) {
      detail = l10n.adaptiveCompareConflict;
    } else if (preferred == null || !preferred.marketAligned) {
      detail = l10n.adaptiveWaitDecisionBody;
    } else {
      detail = switch (preferred.fit) {
        AdaptiveTierFit.limited => l10n.adaptiveCompareLimited,
        AdaptiveTierFit.blockedBoth => l10n.adaptiveCompareBoth(
          fmt.requiredFunds(fundsShortfall.toDouble()),
          fmt.requiredFunds(hardRiskShortfall.toDouble()),
        ),
        AdaptiveTierFit.blockedRisk => l10n.adaptiveCompareRisk(
          fmt.requiredFunds(hardRiskShortfall.toDouble()),
        ),
        AdaptiveTierFit.blockedFunds => l10n.adaptiveCompareFunds(
          fmt.requiredFunds(fundsShortfall.toDouble()),
        ),
        _ => l10n.adaptiveCompareUnavailable,
      };
    }
    final color = ready ? context.adaptiveBuyColor : context.adaptiveAmber;
    return Column(
      key: const ValueKey('adaptive-selected-decision'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              label,
              key: const ValueKey('adaptive-selected-action'),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (preferred?.fit == AdaptiveTierFit.limited)
              Text(
                l10n.adaptiveCompareLimitedBadge,
                style: TextStyle(
                  color: context.adaptiveAmber,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(detail, style: const TextStyle(height: 1.5)),
        if (ready && preferred.entry != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.watchEntry(fmt.number(preferred.entry, 2)),
            style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
          ),
        ],
        if (preferred?.fit == AdaptiveTierFit.limited) ...[
          const SizedBox(height: 8),
          Text(
            l10n.adaptiveCompareLimitedNext(
              fmt.money(preferred!.effectiveBudget),
            ),
            style: TextStyle(
              color: context.adaptiveAmber,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
        if (preferred?.riskAtStop != null ||
            preferred?.fundsAtStop != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (preferred?.riskAtStop != null)
                Expanded(
                  child: _Figure(
                    l10n.minimumRiskAtStop,
                    fmt.money(preferred!.riskAtStop),
                  ),
                ),
              if (preferred?.riskAtStop != null &&
                  preferred?.fundsAtStop != null)
                const SizedBox(width: 12),
              if (preferred?.fundsAtStop != null)
                Expanded(
                  child: _Figure(
                    l10n.brokerFundsAtStop,
                    fmt.requiredFunds(preferred!.fundsAtStop),
                  ),
                ),
            ],
          ),
        ],
        Divider(height: 28, color: scheme.outlineVariant),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

// ---------------------------------------------------------------------------
// Direction switch
// ---------------------------------------------------------------------------

class AdaptiveDirectionSwitch extends StatelessWidget {
  const AdaptiveDirectionSwitch({
    required this.activeSide,
    required this.hasBuy,
    required this.hasSell,
    required this.onChanged,
    super.key,
  });

  final String activeSide;
  final bool hasBuy;
  final bool hasSell;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('adaptive-direction-tabs'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.reviewOneDirection,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        AdaptiveOptionRow<String>(
          options: [
            ('buy', l10n.priceRiseScenario),
            ('sell', l10n.priceFallScenario),
          ],
          selected: activeSide,
          enabled: (side) => side == 'buy' ? hasBuy : hasSell,
          onSelected: onChanged,
        ),
        if (!hasBuy || !hasSell) ...[
          const SizedBox(height: 6),
          Text(
            l10n.adaptiveDirectionUnavailable(
              !hasBuy ? l10n.priceRiseScenario : l10n.priceFallScenario,
            ),
            style: TextStyle(color: context.adaptiveAmber, height: 1.4),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

class AdaptivePlanResult extends StatefulWidget {
  const AdaptivePlanResult({
    required this.calculation,
    required this.instrument,
    required this.analysisPreferredSide,
    this.onShare,
    super.key,
  });

  final AdaptiveCalculation calculation;
  final String instrument;
  final String analysisPreferredSide;

  /// Copy / save the side summary as an image. Null hides the menu.
  final Future<void> Function(String action, AdaptiveSidePlan plan)? onShare;

  @override
  State<AdaptivePlanResult> createState() => _AdaptivePlanResultState();
}

class _AdaptivePlanResultState extends State<AdaptivePlanResult> {
  late String _side = widget.calculation.preferredSide(
    widget.analysisPreferredSide,
  );

  @override
  void didUpdateWidget(covariant AdaptivePlanResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.calculation, widget.calculation)) {
      _side = widget.calculation.preferredSide(widget.analysisPreferredSide);
    }
  }

  Future<void> _copy(AdaptiveSidePlan plan) async {
    final budget = widget.calculation.budgetFor(plan.side);
    if (budget == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final text = adaptivePlanCopyText(
      context,
      instrument: widget.instrument,
      plan: plan,
      budget: budget,
    );
    try {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(SnackBar(content: Text(l10n.adaptiveCopySuccess)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.adaptiveCopyFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = widget.calculation;
    final rec = calc.recommendation;
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final plan = calc.planFor(_side);
    final viable = rec.evaluationFor(_side).status == AdaptiveSideStatus.viable;

    return Column(
      key: const ValueKey('adaptive-recommendation-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveDecisionSummary(
          row: calc.selectedRow,
          maximumLoss: calc.maximumLoss,
          availableMargin: calc.availableFunds,
        ),
        for (final side in calc.tightStops)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              l10n.adaptiveVolatilityTightShort(side.toUpperCase()),
              style: TextStyle(
                color: context.adaptiveAmber,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        if (rec.volatility.observedRange == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              l10n.adaptiveVolatilityUnavailableShort,
              style: TextStyle(
                color: context.adaptiveAmber,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        if (!rec.valid) ...[
          const SizedBox(height: 6),
          AdaptiveNotice(
            calc.hasConditionalScenarios
                ? '${l10n.entryDirectionUnconfirmedTitle}\n'
                      '${l10n.entryDirectionUnconfirmedBody}\n'
                      '${l10n.entryDirectionUnconfirmedNextAction}'
                : '${l10n.adaptiveInvalidTitle}\n${l10n.adaptiveInvalidDescription}',
            warning: true,
            key: const ValueKey('adaptive-plan-invalid'),
          ),
          const SizedBox(height: 16),
        ],
        AdaptiveDirectionSwitch(
          activeSide: _side,
          hasBuy: calc.sideAvailable('buy'),
          hasSell: calc.sideAvailable('sell'),
          onChanged: (side) => setState(() => _side = side),
        ),
        const SizedBox(height: 14),
        if (plan != null) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                key: const ValueKey('adaptive-plan-status-chip'),
                label: Text(
                  viable && rec.valid
                      ? l10n.planReadyToReview
                      : l10n.conditionalScenarioNotActionable,
                ),
                side: BorderSide(
                  color: viable && rec.valid
                      ? Theme.of(context).colorScheme.primary
                      : context.adaptiveAmber,
                ),
              ),
              OutlinedButton.icon(
                onPressed: viable && rec.valid
                    ? () => unawaited(_copy(plan))
                    : null,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(
                  viable && rec.valid
                      ? l10n.adaptiveCopy
                      : l10n.adaptiveCopyBlocked,
                ),
              ),
            ],
          ),
          if (!(viable && rec.valid)) ...[
            const SizedBox(height: 8),
            Text(
              l10n.entryDirectionUnconfirmedBody,
              style: TextStyle(color: context.adaptiveAmber, height: 1.45),
            ),
          ],
          const SizedBox(height: 10),
          AdaptivePlanSideView(
            key: ValueKey('adaptive-plan-$_side'),
            plan: plan,
            calculation: calc,
            conditional: !(viable && rec.valid),
            onShare: widget.onShare,
          ),
        ] else if (!rec.valid)
          _SnapshotUnavailable(calculation: calc, side: _side, fmt: fmt),
        if (rec.valid && plan != null) ...[
          const SizedBox(height: 14),
          AdaptiveDetailsExpansion(
            key: const ValueKey('adaptive-risk-details'),
            title: l10n.howUseRecommendation,
            children: [
              for (final step in [
                l10n.adaptiveStepChoose,
                l10n.adaptiveStepEntry,
                l10n.adaptiveStepAdd,
                l10n.adaptiveStepStop,
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${step.$1 + 1}. ${step.$2}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              if (rec.result.assumptions.isNotEmpty) ...[
                const Divider(height: 22),
                for (final assumption in rec.result.assumptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $assumption',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.manualExecutionDisclaimer,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.adaptiveExternalLiquidation,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SnapshotUnavailable extends StatelessWidget {
  const _SnapshotUnavailable({
    required this.calculation,
    required this.side,
    required this.fmt,
  });

  final AdaptiveCalculation calculation;
  final String side;
  final AdaptiveFormat fmt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final diagnostic = calculation.recommendation
        .evaluationFor(side)
        .diagnostic;
    final String reason;
    if (diagnostic != null &&
        diagnostic.marginShortfall > 0 &&
        diagnostic.riskShortfall > 0) {
      reason = l10n.adaptiveMinimumBlockerBoth(
        fmt.money(diagnostic.effectiveLossBudget),
        fmt.requiredFunds(diagnostic.marginShortfall),
        fmt.money(diagnostic.riskAtStop),
      );
    } else if (diagnostic != null && diagnostic.marginShortfall > 0) {
      reason = l10n.adaptiveMinimumBlockerMargin(
        fmt.requiredFunds(diagnostic.marginShortfall),
      );
    } else if (diagnostic != null && diagnostic.riskShortfall > 0) {
      reason = l10n.adaptiveMinimumBlockerRisk(
        fmt.money(diagnostic.effectiveLossBudget),
        fmt.money(diagnostic.riskAtStop),
      );
    } else {
      reason = l10n.adaptiveSnapshotUnavailable;
    }
    return AdaptivePanel(
      key: ValueKey('adaptive-plan-snapshot-unavailable-$side'),
      children: [
        Text(
          l10n.answerAtGlance,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          reason,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// One side's plan
// ---------------------------------------------------------------------------

class AdaptivePlanSideView extends StatelessWidget {
  const AdaptivePlanSideView({
    required this.plan,
    required this.calculation,
    required this.conditional,
    this.onShare,
    super.key,
  });

  final AdaptiveSidePlan plan;
  final AdaptiveCalculation calculation;
  final bool conditional;
  final Future<void> Function(String action, AdaptiveSidePlan plan)? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isBuy = plan.side == 'buy';
    final accent = isBuy ? context.adaptiveBuyColor : context.adaptiveSellColor;
    final budget = calculation.budgetFor(plan.side);
    final rec = calculation.recommendation;
    final first = plan.layers.first;
    final nextCandidate = plan.rejectedLayers.isEmpty
        ? null
        : plan.rejectedLayers.first;
    final fundsOnly =
        !conditional &&
            nextCandidate != null &&
            nextCandidate.reason == AdaptiveRejectReason.dayMargin &&
            (nextCandidate.additionalFundsRequired ?? 0) > 0 &&
            (nextCandidate.additionalLossBudgetRequired ?? 1) <= 0.001 &&
            budget != null &&
            nextCandidate.layer.cumulativeRisk <=
                budget.usableRiskBudget + 0.001
        ? nextCandidate
        : null;
    final scenarioPreferred =
        rec.preferredSide == 'both' || rec.preferredSide == plan.side;
    final stageGuidance = conditional
        ? l10n.conditionalScenarioNotActionable
        : plan.layers.length > 1 && scenarioPreferred
        ? l10n.extraLayersManual
        : l10n.adaptiveSideEntryOnly;

    String fill(
      int positions,
      double lots,
      double margin,
      double loss,
      double? profit,
    ) => l10n.adaptiveFillValues(
      fmt.money(loss),
      fmt.number(
        budget != null && budget.marginBudget > 0
            ? loss / budget.marginBudget * 100
            : null,
      ),
      fmt.number(lots),
      fmt.money(margin),
      fmt.number(positions.toDouble(), 0),
      fmt.money(profit),
      fmt.number(
        budget != null && budget.marginBudget > 0 && profit != null
            ? profit / budget.marginBudget * 100
            : null,
      ),
    );

    final unusedReason =
        plan.rejectedLayers.any(
          (r) => r.reason == AdaptiveRejectReason.dayMargin,
        )
        ? l10n.adaptiveUnusedReasonMargin
        : plan.rejectedLayers.any(
            (r) => r.reason == AdaptiveRejectReason.tierLimit,
          )
        ? l10n.adaptiveUnusedReasonTier
        : plan.layers.length == 1 && plan.rejectedLayers.isEmpty
        ? l10n.adaptiveUnusedReasonLevels
        : budget != null &&
              budget.riskUtilizationRate < 1 &&
              plan.rejectedLayers.isEmpty
        ? l10n.adaptiveUnusedReasonPolicy
        : l10n.lossCeilingUnusedBody;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isBuy ? l10n.priceRiseScenario : l10n.priceFallScenario,
            style: TextStyle(
              color: accent,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          AdaptivePanel(
            children: [
              Text(
                l10n.answerAtGlance,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              AdaptiveValueCard(
                conditional
                    ? l10n.conditionalScenarioNotActionable
                    : l10n.planReadyToReview,
                borderColor: conditional
                    ? context.adaptiveAmber
                    : scheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                conditional
                    ? l10n.referenceNumbersOnly
                    : l10n.objectiveScenario,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              if (budget != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      l10n.adaptiveRiskStyleActive(
                        adaptiveRiskStyleLabel(context, budget.riskStyle),
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 28),
              Text(
                l10n.entryLotPerPosition,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              for (final layer in plan.layers) _EntryRow(layer: layer),
              const SizedBox(height: 6),
              Text(
                '${l10n.adaptiveIfAllFilled}: ${plan.layers.length} '
                '${plan.layers.length == 1 ? l10n.adaptivePositionSingular : l10n.adaptiveSnapshotLayers} · '
                '${fmt.number(plan.totalLots)} ${l10n.adaptiveLot}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              AdaptiveValueCard(
                l10n.oneFinalStopLoss,
                value: fmt.number(plan.stopLoss, 4),
                valueColor: context.adaptiveSellColor,
              ),
              const SizedBox(height: 10),
              AdaptiveValueCard(
                l10n.estimatedMaximumLoss,
                value: fmt.money(plan.estimatedLoss),
              ),
              if (budget != null) ...[
                const Divider(height: 28),
                Text(
                  l10n.riskContext,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                AdaptiveValueCard(
                  l10n.usableRiskBudget,
                  value: fmt.money(budget.usableRiskBudget),
                  detail: l10n.adaptiveRiskBudgetRate(
                    fmt.number(budget.riskUtilizationRate * 100, 0),
                  ),
                ),
                const SizedBox(height: 10),
                AdaptiveValueCard(
                  l10n.reservedLossCeiling,
                  value: fmt.money(budget.unusedRiskBuffer),
                ),
              ],
              if (plan.takeProfit1 != null || plan.takeProfit2 != null) ...[
                const Divider(height: 28),
                Text(
                  l10n.profitTargets,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (plan.takeProfit1 != null) ...[
                  const SizedBox(height: 10),
                  AdaptiveValueCard(
                    l10n.takeProfit1,
                    value: fmt.number(plan.takeProfit1, 4),
                    detail:
                        '${l10n.adaptiveTpProfit}: ${fmt.profit(plan.profitToTp1)}',
                    detailColor: context.adaptiveBuyColor,
                  ),
                ],
                if (plan.takeProfit2 != null) ...[
                  const SizedBox(height: 10),
                  AdaptiveValueCard(
                    l10n.takeProfit2,
                    value: fmt.number(plan.takeProfit2, 4),
                    detail:
                        '${l10n.adaptiveTpProfit}: ${fmt.profit(plan.profitToTp2)}',
                    detailColor: context.adaptiveBuyColor,
                  ),
                ],
              ],
              if (onShare != null) ...[
                const Divider(height: 28),
                Align(
                  alignment: Alignment.centerRight,
                  child: _ShareMenu(plan: plan, onShare: onShare!),
                ),
              ],
            ],
          ),
          if (!conditional) ...[
            const SizedBox(height: 12),
            Text(
              plan.layers.length == 1
                  ? stageGuidance
                  : l10n.extraPositionsManual,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
          ],
          if (!conditional && nextCandidate != null) ...[
            const SizedBox(height: 12),
            Container(
              key: ValueKey('adaptive-next-layer-${plan.side}'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.adaptiveAmber.withValues(alpha: .08),
                border: Border.all(
                  color: context.adaptiveAmber.withValues(alpha: .4),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: fundsOnly != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adaptiveNextFunds(
                            fmt.requiredFunds(
                              fundsOnly.additionalFundsRequired,
                            ),
                            fmt.number(fundsOnly.layer.lot),
                            '${fundsOnly.layer.level + 1}',
                            fmt.number(fundsOnly.layer.price, 4),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.adaptiveNextFundsNote,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '${l10n.adaptiveNextBlocked('${nextCandidate.layer.level + 1}', adaptiveRejectedReasonText(context, nextCandidate.reason))}'
                      '${(nextCandidate.additionalLossBudgetRequired ?? 0) > 0 ? ' ${l10n.adaptiveNextFundsNotEnough}' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
            ),
          ],
          const SizedBox(height: 12),
          AdaptiveDetailsExpansion(
            key: ValueKey('adaptive-ladder-${plan.side}'),
            title: l10n.viewPlanDetails,
            children: [
              Text(
                stageGuidance,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 14),
              if (budget != null)
                AdaptivePanel(
                  children: [
                    Text(
                      l10n.ifEntriesFill,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    _Fill(
                      l10n.firstEntryOnly,
                      fill(
                        1,
                        first.lot,
                        first.marginThisPosition,
                        first.riskThisPosition,
                        first.profitToTp2,
                      ),
                    ),
                    if (plan.layers.length > 1) ...[
                      const SizedBox(height: 10),
                      _Fill(
                        l10n.allPlannedEntries,
                        fill(
                          plan.layers.length,
                          plan.totalLots,
                          plan.marginRequired,
                          plan.estimatedLoss,
                          plan.profitToTp2,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      l10n.adaptiveFillUncertain,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    if (budget.maximumLoss - plan.estimatedLoss > 0.01) ...[
                      const Divider(height: 24),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${l10n.whyLossCeilingUnused}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(text: unusedReason),
                          ],
                        ),
                        style: const TextStyle(height: 1.45),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                l10n.layerExplanation,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              for (final layer in plan.layers)
                _LayerDetails(
                  layer: layer,
                  fmt: fmt,
                  caption: layer.level == 0
                      ? l10n.adaptiveStageInitialReason
                      : '${l10n.adaptiveLayerCheckpoint} ${adaptiveStageReasonText(context, layer)}',
                ),
              if (plan.rejectedLayers.isNotEmpty) ...[
                const SizedBox(height: 4),
                AdaptiveDetailsExpansion(
                  key: ValueKey('adaptive-rejected-${plan.side}'),
                  title: l10n.adaptiveRejectedTitle,
                  titleColor: context.adaptiveAmber,
                  children: [
                    Text(
                      l10n.adaptiveRejectedHelp,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final rejected in plan.rejectedLayers)
                      _RejectedLayer(rejected: rejected, fmt: fmt),
                  ],
                ),
              ],
              const Divider(height: 28),
              Text(
                l10n.moreCalculationDetails,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              AdaptiveMetricRows([
                AdaptiveMetric(
                  l10n.weightedAverageEntry,
                  fmt.number(plan.weightedAverageEntry, 4),
                ),
                AdaptiveMetric(
                  l10n.adaptiveMarginRequired,
                  fmt.money(plan.marginRequired),
                ),
                AdaptiveMetric(
                  l10n.dayMarginPlusLoss,
                  fmt.money(plan.fundsAtStop),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$title\n',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        TextSpan(text: body),
      ],
    ),
    style: const TextStyle(height: 1.45),
  );
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.layer});
  final AdaptiveLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = AdaptiveFormat.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${l10n.adaptiveLevel} ${layer.level + 1} · '
              '${layer.level == 0 ? l10n.initialEntry : l10n.additionalPosition}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${fmt.number(layer.price, 4)} · ${fmt.number(layer.lot)} ${l10n.adaptiveLot}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _LayerDetails extends StatelessWidget {
  const _LayerDetails({
    required this.layer,
    required this.fmt,
    required this.caption,
  });
  final AdaptiveLayer layer;
  final AdaptiveFormat fmt;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.adaptiveLevel} ${layer.level + 1}'
                  '${layer.level == 0 ? ' · ${l10n.initialEntry}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${fmt.number(layer.price, 4)} · ${fmt.number(layer.lot)} ${l10n.adaptiveLot}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          AdaptivePanel(
            children: [_LayerFinancials(layer: layer, fmt: fmt)],
          ),
        ],
      ),
    );
  }
}

class _LayerFinancials extends StatelessWidget {
  const _LayerFinancials({
    required this.layer,
    required this.fmt,
    this.rejected = false,
  });
  final AdaptiveLayer layer;
  final AdaptiveFormat fmt;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = layer.remainingFundsAtStop;
    final exceeds = remaining != null && remaining < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveMetricRows([
          AdaptiveMetric(
            l10n.marginThisPosition,
            fmt.money(layer.marginThisPosition),
          ),
          AdaptiveMetric(
            l10n.marginUsedSoFar,
            fmt.money(layer.cumulativeMargin),
          ),
          AdaptiveMetric(
            l10n.riskThisPosition,
            fmt.money(layer.riskThisPosition),
          ),
          AdaptiveMetric(l10n.riskAtStopSoFar, fmt.money(layer.cumulativeRisk)),
          AdaptiveMetric(
            l10n.fundsNeededAtStop,
            rejected
                ? fmt.requiredFunds(layer.cumulativeFundsAtStop)
                : fmt.money(layer.cumulativeFundsAtStop),
          ),
          AdaptiveMetric(
            l10n.fundsRemaining,
            exceeds
                ? l10n.adaptiveLayerExceedsFunds
                : fmt.money(remaining?.clamp(0, double.infinity).toDouble()),
            color: exceeds ? context.adaptiveAmber : null,
          ),
          if (layer.cumulativeProfitToTp1 != null)
            AdaptiveMetric(
              l10n.cumulativeProfitTp1,
              fmt.profit(layer.cumulativeProfitToTp1),
            ),
          if (layer.cumulativeProfitToTp2 != null)
            AdaptiveMetric(
              l10n.cumulativeProfitTp2,
              fmt.profit(layer.cumulativeProfitToTp2),
            ),
        ]),
        if (exceeds)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.adaptiveLayerShortfall(fmt.requiredFunds(remaining.abs())),
              style: TextStyle(
                color: context.adaptiveAmber,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _RejectedLayer extends StatelessWidget {
  const _RejectedLayer({required this.rejected, required this.fmt});
  final AdaptiveRejectedLayer rejected;
  final AdaptiveFormat fmt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final layer = rejected.layer;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.adaptiveAmber.withValues(alpha: .07),
        border: Border.all(color: context.adaptiveAmber.withValues(alpha: .45)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.adaptiveLevel} ${layer.level} · ${fmt.number(layer.price, 4)} · '
                  '${fmt.number(layer.lot)} ${l10n.adaptiveLot}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                l10n.adaptiveRejectedBadge,
                style: TextStyle(
                  color: context.adaptiveAmber,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            adaptiveRejectedReasonText(context, rejected.reason),
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          if (rejected.additionalFundsRequired != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.adaptiveConditionalTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.adaptiveConditionalHelp,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            AdaptiveMetricRows([
              AdaptiveMetric(
                l10n.adaptiveConditionalAdditionalFunds,
                fmt.requiredFunds(rejected.additionalFundsRequired),
              ),
              AdaptiveMetric(
                l10n.adaptiveConditionalAdditionalLoss,
                fmt.money(rejected.additionalLossBudgetRequired),
              ),
              AdaptiveMetric(
                l10n.adaptiveConditionalTotalRisk,
                fmt.money(layer.cumulativeRisk),
              ),
              AdaptiveMetric(
                l10n.adaptiveConditionalTotalFunds,
                fmt.requiredFunds(layer.cumulativeFundsAtStop),
              ),
            ]),
            Text(
              l10n.adaptiveConditionalManual,
              style: TextStyle(
                color: scheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _LayerFinancials(layer: layer, fmt: fmt, rejected: true),
        ],
      ),
    );
  }
}

class _ShareMenu extends StatelessWidget {
  const _ShareMenu({required this.plan, required this.onShare});
  final AdaptiveSidePlan plan;
  final Future<void> Function(String action, AdaptiveSidePlan plan) onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      key: ValueKey('adaptive-share-summary-menu-${plan.side}'),
      tooltip: l10n.adaptiveShareSummaryMenu,
      onSelected: (action) => unawaited(onShare(action, plan)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy',
          child: Text(l10n.adaptiveShareSummaryCopy),
        ),
        PopupMenuItem(value: 'download', child: Text(l10n.savePng)),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          label: Text(l10n.adaptiveShareSummaryMenu),
        ),
      ),
    );
  }
}
