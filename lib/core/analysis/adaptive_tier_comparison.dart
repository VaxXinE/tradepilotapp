import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import 'adaptive_position_plan.dart';

// Port of the web `adaptive-tier-comparison.ts`.

enum AdaptiveTierFit {
  withinTarget('within_target'),
  limited('limited'),
  blockedRisk('blocked_risk'),
  blockedFunds('blocked_funds'),
  blockedBoth('blocked_both'),
  unavailable('unavailable');

  const AdaptiveTierFit(this.wire);
  final String wire;
}

enum AdaptiveTierActionReason {
  ready('ready'),
  marketConflict('market_conflict'),
  marketUnconfirmed('market_unconfirmed'),
  limited('limited'),
  hardRisk('hard_risk'),
  funds('funds'),
  both('both'),
  unavailable('unavailable');

  const AdaptiveTierActionReason(this.wire);
  final String wire;
}

class AdaptiveTierSide {
  const AdaptiveTierSide({
    required this.fit,
    required this.lot,
    required this.margin,
    required this.riskAtStop,
    required this.fundsAtStop,
    required this.effectiveBudget,
    required this.marketAligned,
    required this.entry,
  });

  final AdaptiveTierFit fit;
  final double? lot;
  final double? margin;
  final double? riskAtStop;
  final double? fundsAtStop;
  final double? effectiveBudget;
  final bool marketAligned;
  final double? entry;
}

class AdaptiveTierRow {
  const AdaptiveTierRow({
    required this.tier,
    required this.recommendation,
    required this.buy,
    required this.sell,
    required this.action,
    required this.actionReason,
    required this.preferredSide,
  });

  final AdaptiveAccountTier tier;
  final AdaptiveRecommendation recommendation;
  final AdaptiveTierSide buy;
  final AdaptiveTierSide sell;

  /// `buy` | `sell` | `wait` | `skip`.
  final String action;
  final AdaptiveTierActionReason actionReason;

  /// `buy` | `sell` | null.
  final String? preferredSide;

  AdaptiveTierSide sideOf(String side) => side == 'buy' ? buy : sell;
}

/// Compares the same saved analysis at all three contract sizes. The entered
/// loss is always the hard ceiling; the style utilisation is only a target.
/// Purely local: never requests another AI analysis.
Map<AdaptiveAccountTier, AdaptiveTierRow> compareAdaptiveAccountTiers({
  required String instrument,
  required TradePlan tradePlan,
  required double? availableMargin,
  required double? maximumLoss,
  required double? existingExposure,
  required StandardTradingRuleInstrument? standardRule,
  AdaptiveAnalysisContext? context,
  Map<String, List<double>>? checkpointPrices,
  List<AdaptiveCandle>? candles,
  AdaptiveRiskStyle riskStyle = AdaptiveRiskStyle.conservative,
  DateTime? now,
}) {
  AdaptiveTierRow rowFor(AdaptiveAccountTier tier) {
    final recommendation = buildAdaptiveRecommendation(
      instrument: instrument,
      tradePlan: tradePlan,
      availableMargin: availableMargin,
      maximumLoss: maximumLoss,
      existingExposure: existingExposure,
      standardRule: standardRule,
      context: context,
      checkpointPrices: checkpointPrices,
      candles: candles,
      accountTier: tier,
      riskStyle: riskStyle,
      now: now,
    );
    final rule = recommendation.result.rule;
    final preferred = recommendation.preferredSide;
    final preferredSide = preferred == 'buy' || preferred == 'sell'
        ? preferred
        : null;
    final marketConflict = recommendation.reasonCodes.contains(
      'directional_conflict',
    );
    final marketSupported =
        preferredSide != null &&
        !marketConflict &&
        !recommendation.reasonCodes.contains('context_unavailable');

    AdaptiveTierSide evaluate(String side) {
      final aligned = marketSupported && preferredSide == side;
      final empty = AdaptiveTierSide(
        fit: AdaptiveTierFit.unavailable,
        lot: null,
        margin: null,
        riskAtStop: null,
        fundsAtStop: null,
        effectiveBudget: null,
        marketAligned: aligned,
        entry: null,
      );
      if (rule == null ||
          availableMargin == null ||
          availableMargin <= 0 ||
          maximumLoss == null ||
          maximumLoss <= 0 ||
          existingExposure == null ||
          existingExposure < 0 ||
          maximumLoss > availableMargin) {
        return empty;
      }
      final minimum = buildAdaptivePositionPlan(
        AdaptivePositionPlanInput(
          instrument: instrument,
          tradePlan: tradePlan,
          standardRule: standardRule,
          accountTier: tier,
          availableFunds: availableMargin,
          maximumLoss: maximumLoss,
          existingExposure: existingExposure,
          initialLot: rule.minimumLot,
          levels: 0,
          includedBuy: side == 'buy',
          includedSell: side == 'sell',
        ),
      ).sideOf(side);
      if (minimum == null ||
          !minimum.estimatedLoss.isFinite ||
          minimum.estimatedLoss <= 0 ||
          !minimum.fundsAtStop.isFinite) {
        return empty;
      }

      // The diagnostic exists even when the style target rejects the minimum
      // plan; it already includes market-context reductions.
      final budget =
          recommendation.evaluationFor(side).diagnostic?.effectiveLossBudget ??
          recommendation.budget?.usableRiskBudget;
      if (budget == null || !budget.isFinite || budget <= 0) return empty;
      final exceedsRisk = minimum.estimatedLoss > maximumLoss;
      final exceedsFunds = minimum.fundsAtStop > availableMargin;
      final fit = exceedsRisk && exceedsFunds
          ? AdaptiveTierFit.blockedBoth
          : exceedsRisk
          ? AdaptiveTierFit.blockedRisk
          : exceedsFunds
          ? AdaptiveTierFit.blockedFunds
          : minimum.estimatedLoss > budget
          ? AdaptiveTierFit.limited
          : AdaptiveTierFit.withinTarget;
      return AdaptiveTierSide(
        fit: fit,
        lot: rule.minimumLot,
        margin: minimum.marginRequired,
        riskAtStop: minimum.estimatedLoss,
        fundsAtStop: minimum.fundsAtStop,
        effectiveBudget: budget,
        marketAligned: aligned,
        entry: minimum.entry,
      );
    }

    final buy = evaluate('buy');
    final sell = evaluate('sell');
    final selected = preferredSide == null
        ? null
        : (preferredSide == 'buy' ? buy : sell);
    final actionable =
        preferredSide != null &&
        recommendation.valid &&
        recommendation.evaluationFor(preferredSide).status ==
            AdaptiveSideStatus.viable;
    var action = 'wait';
    var reason = AdaptiveTierActionReason.marketUnconfirmed;
    if (marketConflict) {
      action = 'skip';
      reason = AdaptiveTierActionReason.marketConflict;
    } else if (actionable) {
      action = preferredSide;
      reason = AdaptiveTierActionReason.ready;
    } else if (marketSupported && selected != null) {
      switch (selected.fit) {
        case AdaptiveTierFit.limited:
          reason = AdaptiveTierActionReason.limited;
        case AdaptiveTierFit.blockedRisk || AdaptiveTierFit.blockedBoth:
          action = 'skip';
          reason = selected.fit == AdaptiveTierFit.blockedBoth
              ? AdaptiveTierActionReason.both
              : AdaptiveTierActionReason.hardRisk;
        case AdaptiveTierFit.blockedFunds:
          action = 'skip';
          reason = AdaptiveTierActionReason.funds;
        case AdaptiveTierFit.unavailable:
          reason = AdaptiveTierActionReason.unavailable;
        case AdaptiveTierFit.withinTarget:
          reason = AdaptiveTierActionReason.marketUnconfirmed;
      }
    }
    return AdaptiveTierRow(
      tier: tier,
      recommendation: recommendation,
      buy: buy,
      sell: sell,
      action: action,
      actionReason: reason,
      preferredSide: preferredSide,
    );
  }

  return {for (final tier in AdaptiveAccountTier.values) tier: rowFor(tier)};
}
