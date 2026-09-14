import 'dart:math' as math;

import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../models/market_models.dart';
import '../../l10n/app_messages.dart';

enum AdaptiveAccountTier { micro, mini, regular }

enum AdaptiveRiskStyle { conservative, balanced, aggressive }

enum AdaptivePosture { scalingAllowed, entryOnly, notRecommended }

class AdaptiveLayer {
  const AdaptiveLayer({
    required this.price,
    required this.lot,
    required this.cumulativeLots,
    required this.cumulativeMargin,
    required this.cumulativeRisk,
    required this.cumulativeFundsAtStop,
    required this.profitToTp1,
    required this.profitToTp2,
  });

  final double price;
  final double lot;
  final double cumulativeLots;
  final double cumulativeMargin;
  final double cumulativeRisk;
  final double cumulativeFundsAtStop;
  final double? profitToTp1;
  final double? profitToTp2;
}

class AdaptiveSidePlan {
  const AdaptiveSidePlan({
    required this.side,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.layers,
  });

  final String side;
  final double entry;
  final double stopLoss;
  final double? takeProfit1;
  final double? takeProfit2;
  final List<AdaptiveLayer> layers;

  double get totalLots => layers.last.cumulativeLots;
  double get marginRequired => layers.last.cumulativeMargin;
  double get estimatedLoss => layers.last.cumulativeRisk;
  double get fundsAtStop => layers.last.cumulativeFundsAtStop;
  double? get profitToTp1 => layers.last.profitToTp1;
  double? get profitToTp2 => layers.last.profitToTp2;
}

class AdaptiveRecommendation {
  const AdaptiveRecommendation({
    required this.valid,
    required this.errors,
    required this.posture,
    required this.preferredSide,
    required this.reasonCodes,
    required this.usableRisk,
    required this.unusedRisk,
    required this.buy,
    required this.sell,
  });

  final bool valid;
  final List<String> errors;
  final AdaptivePosture posture;
  final String preferredSide;
  final List<String> reasonCodes;
  final double usableRisk;
  final double unusedRisk;
  final AdaptiveSidePlan? buy;
  final AdaptiveSidePlan? sell;
}

class _TierRule {
  const _TierRule(this.minimumLot, this.maximumLot, this.step, this.multiplier);
  final double minimumLot;
  final double maximumLot;
  final double step;
  final double multiplier;
}

const _tiers = {
  AdaptiveAccountTier.micro: _TierRule(.01, .09, .01, .1),
  AdaptiveAccountTier.mini: _TierRule(.1, .9, .1, 1),
  AdaptiveAccountTier.regular: _TierRule(1, 50, 1, 10),
};

const _ruleCodes = {
  'XAU/USD': 'XUL10',
  'BRENT': 'BCO10_BBJ',
  'HSI': 'HKK50_BBJ',
  'NIKKEI': 'JPK50_BBJ',
};

bool supportsAdaptivePositionPlan(String instrument) =>
    _ruleCodes.containsKey(instrument);

StandardTradingRuleInstrument? adaptiveRuleFor(
  StandardTradingRules rules,
  String instrument,
) {
  final code = _ruleCodes[instrument];
  if (code == null) return null;
  for (final rule in rules.instruments) {
    if (rule.code.name == code) return rule;
  }
  return null;
}

List<double> _numbers(String value) => RegExp(r'-?\d+(?:\.\d+)?')
    .allMatches(
      value
          .replaceAll(',', '')
          .replaceAll(RegExp(r'\b[HMDWhmdw]\d{1,3}\b'), ' ')
          .replaceAll(RegExp(r'\b\d{1,3}[mhdwMHDW]\b'), ' '),
    )
    .map((match) => double.parse(match.group(0)!))
    .toList();

double? _price(TradeSide side, String field) {
  final values = _numbers(switch (field) {
    'entry' => side.entryZone,
    'stop' => side.stopLoss,
    'tp1' => side.takeProfit1,
    _ => side.takeProfit2,
  });
  if (values.isEmpty) return null;
  return field == 'entry' && values.length > 1
      ? (values[0] + values[1]) / 2
      : values[0];
}

double _roundTo(double value, double step) {
  final decimals = math.max(0, step.toString().split('.').last.length);
  return double.parse(
    ((value / step).round() * step).toStringAsFixed(decimals),
  );
}

double _floorLot(double value, double step) =>
    double.parse(((value / step + 1e-12).floor() * step).toStringAsFixed(2));

Map<String, List<double>> adaptiveChartCandidates(
  List<MarketCandle> candles,
  TradePlan tradePlan,
  double minimumMovement,
) {
  final recent = candles.length > 160
      ? candles.sublist(candles.length - 160)
      : candles;
  List<double> collect(String sideName, TradeSide side) {
    final entry = _price(side, 'entry');
    final stop = _price(side, 'stop');
    if (recent.length < 5 || entry == null || stop == null) return const [];
    final distance = (entry - stop).abs();
    final separation = math.max(minimumMovement * 2, distance * .025);
    final raw = <double>[];
    for (var i = 2; i < recent.length - 2; i++) {
      final candle = recent[i];
      final neighbors = [
        recent[i - 2],
        recent[i - 1],
        recent[i + 1],
        recent[i + 2],
      ];
      final buy = sideName == 'buy';
      final swing = neighbors.every(
        (neighbor) =>
            buy ? candle.low <= neighbor.low : candle.high >= neighbor.high,
      );
      final price = buy ? candle.low : candle.high;
      final inside = buy
          ? price > stop && price < entry
          : price < stop && price > entry;
      if (swing && inside) raw.add(_roundTo(price, minimumMovement));
    }
    raw.sort((a, b) => sideName == 'buy' ? b.compareTo(a) : a.compareTo(b));
    final accepted = <double>[];
    for (final price in raw) {
      if (accepted.every((other) => (other - price).abs() >= separation)) {
        accepted.add(price);
        if (accepted.length == 6) break;
      }
    }
    return accepted;
  }

  return {
    'buy': collect('buy', tradePlan.buy),
    'sell': collect('sell', tradePlan.sell),
  };
}

AdaptiveRecommendation buildAdaptiveRecommendation({
  required Analysis analysis,
  required StandardTradingRuleInstrument? standardRule,
  required double? availableMargin,
  required double? maximumLoss,
  required double existingExposure,
  required AdaptiveAccountTier accountTier,
  required AdaptiveRiskStyle riskStyle,
  Map<String, List<double>> checkpointPrices = const {},
}) {
  final errors = <String>[];
  if (!supportsAdaptivePositionPlan(analysis.instrument)) {
    errors.add(AppMessages.l10n.appErrInstrumentUnsupported);
  }
  if (analysis.tradePlan == null || standardRule == null) {
    errors.add(AppMessages.l10n.appErrNoStandardPlan);
  }
  if (availableMargin == null || availableMargin <= 0) {
    errors.add(AppMessages.l10n.appErrFundsPositive);
  }
  if (maximumLoss == null || maximumLoss <= 0) {
    errors.add(AppMessages.l10n.appErrMaxLossPositive);
  } else if (availableMargin != null && maximumLoss > availableMargin) {
    errors.add(AppMessages.l10n.appErrMaxLossExceedsFunds);
  }
  if (existingExposure < 0) {
    errors.add(AppMessages.l10n.appErrExposureNegative);
  }
  if (errors.isNotEmpty) return _invalid(errors);

  final tier = _tiers[accountTier]!;
  final movementValues = _numbers(standardRule!.minimumPriceMovement);
  if (standardRule.code.name != _ruleCodes[analysis.instrument] ||
      movementValues.isEmpty ||
      standardRule.contractSize <= 0 ||
      standardRule.initialMarginUsdPerLot <= 0) {
    return _invalid([AppMessages.l10n.appErrTpRulesInvalid]);
  }
  final movement = movementValues.first;
  final contractSize = standardRule.contractSize.toDouble() * tier.multiplier;
  final marginAtMinimum =
      standardRule.initialMarginUsdPerLot.toDouble() * tier.multiplier;
  final marginPerLot = marginAtMinimum / tier.minimumLot;

  final fundamental = analysis.fundamentalContext;
  final contextComplete =
      analysis.marketCondition != null &&
      analysis.riskLevel != null &&
      analysis.tradingBias != null &&
      analysis.confidenceMin != null &&
      analysis.confidenceMax != null &&
      analysis.techBuyCount != null &&
      analysis.techSellCount != null &&
      analysis.techNeutralCount != null &&
      fundamental != null;
  final reasons = <String>[];
  var posture = AdaptivePosture.scalingAllowed;
  var levels = 2;
  var preferred = 'both';
  var softWarning = false;

  final bias = _bias(analysis.tradingBias);
  if (!contextComplete) {
    posture = AdaptivePosture.entryOnly;
    preferred = 'none';
    levels = 0;
    reasons.add('context_unavailable');
  } else {
    if (['1m', '5m', '15m'].contains(analysis.timeframe)) {
      softWarning = true;
      reasons.add('short_timeframe');
    }
    if (analysis.riskLevel == 'high') {
      softWarning = true;
      reasons.add('high_risk');
    }
    if (analysis.marketCondition == 'volatile') {
      softWarning = true;
      reasons.add('volatile_market');
    }
    if (analysis.confidenceMax! < 70) {
      softWarning = true;
      reasons.add('low_confidence');
    }
    final marketDirection = analysis.marketCondition == 'trending_up'
        ? 'buy'
        : analysis.marketCondition == 'trending_down'
        ? 'sell'
        : null;
    final biasDirection = bias == 'bullish'
        ? 'buy'
        : bias == 'bearish'
        ? 'sell'
        : null;
    var conflict =
        marketDirection != null &&
        biasDirection != null &&
        marketDirection != biasDirection;
    if (biasDirection != null) preferred = biasDirection;
    if (bias == 'neutral') {
      softWarning = true;
      preferred = analysis.tradePlan!.preferredSide.name == 'wait'
          ? 'none'
          : analysis.tradePlan!.preferredSide.name;
      reasons.add('neutral_bias');
    }
    final buy = analysis.techBuyCount!;
    final sell = analysis.techSellCount!;
    final directional = buy + sell;
    final imbalance = directional == 0 ? 0 : (buy - sell).abs() / directional;
    if (directional == 0 || imbalance < .2) {
      softWarning = true;
      reasons.add('technical_mixed');
    } else {
      final technicalSide = buy > sell ? 'buy' : 'sell';
      if (preferred != 'both' && preferred != technicalSide) {
        conflict = true;
      } else {
        preferred = technicalSide;
      }
    }
    if (fundamental.calendarEvents.any((event) => event.impact == '★★★')) {
      softWarning = true;
      reasons.add('fundamental_high_impact');
    }
    if (conflict) {
      posture = AdaptivePosture.notRecommended;
      preferred = 'none';
      levels = 0;
      reasons.add('directional_conflict');
    } else if (softWarning) {
      posture = AdaptivePosture.entryOnly;
      levels = 0;
    }
  }

  final utilization = switch (riskStyle) {
    AdaptiveRiskStyle.conservative => .5,
    AdaptiveRiskStyle.balanced => .75,
    AdaptiveRiskStyle.aggressive => 1.0,
  };
  final contextMultiplier =
      reasons.any(
        (reason) =>
            reason == 'high_risk' || reason == 'fundamental_high_impact',
      )
      ? .5
      : reasons.any(
          (reason) => const {
            'short_timeframe',
            'volatile_market',
            'low_confidence',
            'technical_mixed',
          }.contains(reason),
        )
      ? .75
      : 1.0;
  final usableRisk = maximumLoss! * utilization * contextMultiplier;
  final weights = switch (riskStyle) {
    AdaptiveRiskStyle.conservative => const [.4, .35, .25],
    AdaptiveRiskStyle.balanced => const [.5, .3, .2],
    AdaptiveRiskStyle.aggressive => const [.6, .25, .15],
  };
  final buyAvailable = _hasValidGeometry('buy', analysis.tradePlan!.buy);
  final sellAvailable = _hasValidGeometry('sell', analysis.tradePlan!.sell);
  if (!buyAvailable && !sellAvailable) {
    return _invalid([AppMessages.l10n.appErrLevelsInvalid]);
  }

  for (var candidateLevels = levels; candidateLevels >= 0; candidateLevels--) {
    for (var scale = 100; scale >= 1; scale--) {
      final budget = usableRisk * scale / 100;
      final buy = buyAvailable
          ? _sidePlan(
              'buy',
              analysis.tradePlan!.buy,
              preferred == 'buy' || preferred == 'both' ? candidateLevels : 0,
              checkpointPrices['buy'] ?? const [],
              movement,
              contractSize,
              marginPerLot,
              tier,
              budget,
              availableMargin!,
              weights,
            )
          : null;
      final sell = sellAvailable
          ? _sidePlan(
              'sell',
              analysis.tradePlan!.sell,
              preferred == 'sell' || preferred == 'both' ? candidateLevels : 0,
              checkpointPrices['sell'] ?? const [],
              movement,
              contractSize,
              marginPerLot,
              tier,
              budget,
              availableMargin!,
              weights,
            )
          : null;
      if ((buy != null || !buyAvailable) && (sell != null || !sellAvailable)) {
        return AdaptiveRecommendation(
          valid: posture != AdaptivePosture.notRecommended,
          errors: posture == AdaptivePosture.notRecommended
              ? [AppMessages.l10n.appErrSnapshotConflict]
              : const [],
          posture: posture,
          preferredSide: preferred,
          reasonCodes: reasons,
          usableRisk: usableRisk,
          unusedRisk: maximumLoss - usableRisk,
          buy: buy,
          sell: sell,
        );
      }
    }
  }
  return _invalid([AppMessages.l10n.appErrBelowMinimumLot]);
}

bool _hasValidGeometry(String sideName, TradeSide side) {
  final entry = _price(side, 'entry');
  final stop = _price(side, 'stop');
  return entry != null &&
      stop != null &&
      (sideName == 'buy' ? stop < entry : stop > entry);
}

AdaptiveSidePlan? _sidePlan(
  String sideName,
  TradeSide side,
  int levels,
  List<double> checkpoints,
  double movement,
  double contractSize,
  double marginPerLot,
  _TierRule tier,
  double riskBudget,
  double funds,
  List<double> weights,
) {
  final entryValues = _numbers(side.entryZone);
  final entry = _price(side, 'entry');
  final stop = _price(side, 'stop');
  if (entry == null ||
      stop == null ||
      (sideName == 'buy' ? stop >= entry : stop <= entry)) {
    return null;
  }
  final roundedEntry = _roundTo(entry, movement);
  final roundedStop = _roundTo(stop, movement);
  final candidates = <double>[];
  if (entryValues.length > 1) {
    final edge = sideName == 'buy'
        ? entryValues.reduce(math.min)
        : entryValues.reduce(math.max);
    if (edge != roundedEntry && edge != roundedStop) candidates.add(edge);
  }
  candidates.addAll(
    checkpoints.where(
      (price) => sideName == 'buy'
          ? price > roundedStop && price < roundedEntry
          : price < roundedStop && price > roundedEntry,
    ),
  );
  final prices = [
    roundedEntry,
    ...candidates.take(levels).map((p) => _roundTo(p, movement)),
  ];
  final activeWeights = weights.take(prices.length).toList();
  final totalWeight = activeWeights.fold<double>(
    0,
    (sum, value) => sum + value,
  );
  var cumulativeLots = 0.0;
  var cumulativeMargin = 0.0;
  var cumulativeRisk = 0.0;
  var cumulativeTp1 = 0.0;
  var cumulativeTp2 = 0.0;
  final tp1 = _price(side, 'tp1');
  final tp2 = _price(side, 'tp2');
  final result = <AdaptiveLayer>[];
  for (var i = 0; i < prices.length; i++) {
    final price = prices[i];
    final riskPerLot = (price - roundedStop).abs() * contractSize;
    if (riskPerLot <= 0) return null;
    final requested = riskBudget * activeWeights[i] / totalWeight / riskPerLot;
    final lot = math.max(
      tier.minimumLot,
      _floorLot(math.min(requested, tier.maximumLot), tier.step),
    );
    cumulativeLots = _roundTo(cumulativeLots + lot, tier.step);
    cumulativeMargin += lot * marginPerLot;
    cumulativeRisk += riskPerLot * lot;
    if (tp1 != null) {
      cumulativeTp1 +=
          math.max(0, (tp1 - price) * (sideName == 'buy' ? 1 : -1)) *
          contractSize *
          lot;
    }
    if (tp2 != null) {
      cumulativeTp2 +=
          math.max(0, (tp2 - price) * (sideName == 'buy' ? 1 : -1)) *
          contractSize *
          lot;
    }
    result.add(
      AdaptiveLayer(
        price: price,
        lot: lot,
        cumulativeLots: cumulativeLots,
        cumulativeMargin: cumulativeMargin,
        cumulativeRisk: cumulativeRisk,
        cumulativeFundsAtStop: cumulativeMargin + cumulativeRisk,
        profitToTp1: tp1 == null ? null : cumulativeTp1,
        profitToTp2: tp2 == null ? null : cumulativeTp2,
      ),
    );
  }
  if (cumulativeRisk > riskBudget + 1e-7 ||
      cumulativeMargin > funds ||
      cumulativeMargin + cumulativeRisk > funds) {
    return null;
  }
  return AdaptiveSidePlan(
    side: sideName,
    entry: roundedEntry,
    stopLoss: roundedStop,
    takeProfit1: tp1 == null ? null : _roundTo(tp1, movement),
    takeProfit2: tp2 == null ? null : _roundTo(tp2, movement),
    layers: result,
  );
}

String? _bias(String? value) {
  final normalized = value?.toLowerCase();
  if (const {
    'strong_sell',
    'bearish',
    'bearish_strong',
    'sell',
  }.contains(normalized)) {
    return 'bearish';
  }
  if (const {
    'strong_buy',
    'bullish',
    'bullish_strong',
    'buy',
  }.contains(normalized)) {
    return 'bullish';
  }
  return normalized == 'neutral' ? 'neutral' : null;
}

AdaptiveRecommendation _invalid(List<String> errors) => AdaptiveRecommendation(
  valid: false,
  errors: errors,
  posture: AdaptivePosture.entryOnly,
  preferredSide: 'none',
  reasonCodes: const [],
  usableRisk: 0,
  unusedRisk: 0,
  buy: null,
  sell: null,
);
