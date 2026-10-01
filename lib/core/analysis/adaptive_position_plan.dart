import 'dart:math' as math;

import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../models/market_models.dart';

// Port of the web `adaptive-position-plan.ts` engine (merge-devv-psr 4ef3a07).
// Keep the arithmetic identical: the plan is a financial calculation and the
// web app is the source of truth. `test/core/adaptive_reference_test.dart`
// replays fixtures produced by the original TypeScript.

enum AdaptiveAccountTier { micro, mini, regular }

enum AdaptiveRiskStyle { conservative, balanced, aggressive }

enum AdaptiveLotProfile { decreasing, mixed, increasing }

enum AdaptivePosture {
  scalingAllowed('scaling_allowed'),
  entryOnly('entry_only'),
  notRecommended('not_recommended');

  const AdaptivePosture(this.wire);
  final String wire;
}

enum AdaptiveLayerBasis {
  analysisEntry('analysis_entry'),
  entryZoneEdge('entry_zone_edge'),
  currentChartSwing('current_chart_swing');

  const AdaptiveLayerBasis(this.wire);
  final String wire;
}

enum AdaptiveRejectReason {
  dayMargin('day_margin'),
  lossCeiling('loss_ceiling'),
  tierLimit('tier_limit'),
  analysisLimit('analysis_limit');

  const AdaptiveRejectReason(this.wire);
  final String wire;
}

enum AdaptiveBlocker {
  margin,
  risk,
  marginAndRisk('margin_and_risk'),
  analysis,
  direction;

  const AdaptiveBlocker([this._wire]);
  final String? _wire;
  String get wire => _wire ?? name;
}

enum AdaptiveNextAction {
  funds,
  lossBudget('loss_budget'),
  fundsAndLossBudget('funds_and_loss_budget'),
  reanalysis,
  wait;

  const AdaptiveNextAction([this._wire]);
  final String? _wire;
  String get wire => _wire ?? name;
}

enum AdaptiveSideStatus {
  viable,
  blocked,
  notAligned('not_aligned'),
  unavailable;

  const AdaptiveSideStatus([this._wire]);
  final String? _wire;
  String get wire => _wire ?? name;
}

const int adaptiveMaxAdditionalLayers = 6;

// ---------------------------------------------------------------------------
// Rules
// ---------------------------------------------------------------------------

class AdaptiveRule {
  const AdaptiveRule({
    required this.market,
    required this.label,
    required this.accountTier,
    required this.contractSize,
    required this.contractUnit,
    required this.contractIsAssumption,
    required this.minMovement,
    required this.marginPerLot,
    required this.marginAtMinimumLot,
    required this.minimumLot,
    required this.maximumLot,
    required this.lotStep,
    required this.minimumOpeningFunds,
    required this.maxGapPercent,
  });

  final String market;
  final String label;
  final AdaptiveAccountTier accountTier;

  /// Contract value for ONE minimum-size position at this tier.
  final double contractSize;
  final String contractUnit;

  /// Micro is an estimate (1/10 of Mini), not an official broker contract.
  final bool contractIsAssumption;
  final double minMovement;
  final double marginPerLot;
  final double marginAtMinimumLot;
  final double minimumLot;
  final double? maximumLot;
  final double lotStep;
  final double? minimumOpeningFunds;
  final double? maxGapPercent;

  String get source => 'TP Standard Trading Rules';
}

class _TierSpec {
  const _TierSpec(
    this.minimumLot,
    this.maximumLot,
    this.lotStep,
    this.marginMultiplierFromMini,
    this.minimumOpeningFunds,
  );
  final double minimumLot;
  final double? maximumLot;
  final double lotStep;
  final double marginMultiplierFromMini;
  final double? minimumOpeningFunds;
}

const _tierSpecs = {
  AdaptiveAccountTier.micro: _TierSpec(0.01, 0.09, 0.01, 0.1, 50),
  AdaptiveAccountTier.mini: _TierSpec(0.1, 0.9, 0.1, 1, null),
  AdaptiveAccountTier.regular: _TierSpec(1, null, 1, 10, null),
};

class _ContractTier {
  const _ContractTier(this.size, {this.assumption = false});
  final double size;
  final bool assumption;
}

class _BrokerContract {
  const _BrokerContract(this.unit, this.micro, this.mini, this.regular);
  final String unit;
  final _ContractTier micro;
  final _ContractTier mini;
  final _ContractTier regular;

  _ContractTier of(AdaptiveAccountTier tier) => switch (tier) {
    AdaptiveAccountTier.micro => micro,
    AdaptiveAccountTier.mini => mini,
    AdaptiveAccountTier.regular => regular,
  };
}

/// Mirrors `BROKER_CONTRACT_TIERS`. Only Mini belongs to the API rule.
const _brokerContracts = {
  'XUL10': _BrokerContract(
    'troy ounce',
    _ContractTier(1, assumption: true),
    _ContractTier(10),
    _ContractTier(100),
  ),
  'BCO10_BBJ': _BrokerContract(
    'barrel',
    _ContractTier(10, assumption: true),
    _ContractTier(100),
    _ContractTier(1000),
  ),
  'HKK50_BBJ': _BrokerContract(
    'USD/point',
    _ContractTier(0.5, assumption: true),
    _ContractTier(5),
    _ContractTier(5),
  ),
  'JPK50_BBJ': _BrokerContract(
    'USD/point',
    _ContractTier(0.5, assumption: true),
    _ContractTier(5),
    _ContractTier(5),
  ),
};

const _marketByInstrument = {
  'XAU/USD': ('gold', 'XUL10', 'Gold', 1.0),
  'BRENT': ('brent', 'BCO10_BBJ', 'Brent Oil', 2.0),
  'HSI': ('hang_seng', 'HKK50_BBJ', 'Hang Seng Index', null),
  'NIKKEI': ('nikkei', 'JPK50_BBJ', 'Nikkei Index', null),
};

bool isAdaptivePositionInstrument(String instrument) =>
    _marketByInstrument.containsKey(instrument);

/// Kept for callers written against the previous port.
bool supportsAdaptivePositionPlan(String instrument) =>
    isAdaptivePositionInstrument(instrument);

String? adaptiveStandardRuleCode(String instrument) =>
    _marketByInstrument[instrument.trim().toUpperCase()]?.$2;

StandardTradingRuleInstrument? adaptiveRuleFor(
  StandardTradingRules rules,
  String instrument,
) {
  final code = adaptiveStandardRuleCode(instrument);
  if (code == null) return null;
  for (final rule in rules.instruments) {
    if (rule.code.name == code) return rule;
  }
  return null;
}

String _unitWire(StandardTradingRuleInstrumentContractUnitEnum unit) =>
    switch (unit) {
      StandardTradingRuleInstrumentContractUnitEnum.troyOunce => 'troy ounce',
      StandardTradingRuleInstrumentContractUnitEnum.barrel => 'barrel',
      _ => 'USD/point',
    };

AdaptiveRule? adaptiveMarketRule(
  String instrument,
  StandardTradingRuleInstrument? standardRule, [
  AdaptiveAccountTier accountTier = AdaptiveAccountTier.mini,
]) {
  final market = _marketByInstrument[instrument.trim().toUpperCase()];
  if (market == null || standardRule == null) return null;
  final code = market.$2;
  if (standardRule.code.name != code) return null;

  final movements = _numericValues(standardRule.minimumPriceMovement);
  final minMovement = movements.isEmpty ? double.nan : movements.first;
  final tier = _tierSpecs[accountTier]!;
  final contract = _brokerContracts[code]!;
  if (standardRule.contractSize != contract.mini.size ||
      _unitWire(standardRule.contractUnit) != contract.unit) {
    return null;
  }
  final marginAtMinimumLot =
      standardRule.initialMarginUsdPerLot.toDouble() *
      tier.marginMultiplierFromMini;
  final marginPerLot = marginAtMinimumLot / tier.minimumLot;
  final tierContract = contract.of(accountTier);
  final contractSize = tierContract.size;
  if (!contractSize.isFinite ||
      contractSize <= 0 ||
      !minMovement.isFinite ||
      minMovement <= 0 ||
      !marginAtMinimumLot.isFinite ||
      marginAtMinimumLot <= 0 ||
      !marginPerLot.isFinite ||
      marginPerLot <= 0) {
    return null;
  }
  return AdaptiveRule(
    market: market.$1,
    label: market.$3,
    accountTier: accountTier,
    contractSize: contractSize,
    contractUnit: contract.unit,
    contractIsAssumption: tierContract.assumption,
    minMovement: minMovement,
    marginPerLot: marginPerLot,
    marginAtMinimumLot: marginAtMinimumLot,
    minimumLot: tier.minimumLot,
    maximumLot: tier.maximumLot,
    lotStep: tier.lotStep,
    minimumOpeningFunds: tier.minimumOpeningFunds,
    maxGapPercent: market.$4,
  );
}

/// Largest lot the funds can carry at the account tier's minimum margin.
double adaptiveMarginCapacity(double? availableMargin, AdaptiveRule? rule) {
  if (availableMargin == null || availableMargin <= 0 || rule == null) {
    return 0;
  }
  final affordable = availableMargin / rule.marginPerLot;
  final capped = rule.maximumLot == null
      ? affordable
      : math.min(affordable, rule.maximumLot!);
  final units = ((capped + _epsilon) / rule.lotStep).floor();
  final lot = _roundLot(units * rule.lotStep, rule.lotStep);
  return lot >= rule.minimumLot ? lot : 0;
}

double _contractValueForLot(AdaptiveRule rule, double lot) =>
    rule.contractSize * (lot / rule.minimumLot);

// ---------------------------------------------------------------------------
// Number helpers (JS parity)
// ---------------------------------------------------------------------------

const double _epsilon = 2.220446049250313e-16;

final _stripTimeframeA = RegExp(r'\b[HMDWhmdw]\d{1,3}\b');
final _stripTimeframeB = RegExp(r'\b\d{1,3}[mhdwMHDW]\b');
final _numberPattern = RegExp(r'-?\d+(?:\.\d+)?');

List<double> _numericValues(String? value) {
  if (value == null) return const [];
  return _numberPattern
      .allMatches(
        value
            .replaceAll(',', '')
            .replaceAll(_stripTimeframeA, ' ')
            .replaceAll(_stripTimeframeB, ' '),
      )
      .map((match) => double.parse(match.group(0)!))
      .where((number) => number.isFinite)
      .toList();
}

/// `Math.round`: ties go toward +infinity.
double _jsRound(double x) {
  final floor = x.floorToDouble();
  return x - floor >= 0.5 ? floor + 1 : floor;
}

double _toFixed(double value, int digits) =>
    double.parse(value.toStringAsFixed(digits));

int _decimalPlaces(double value) {
  final text = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
  final parts = text.split('.');
  return parts.length > 1 ? parts[1].length : 0;
}

double _roundPrice(double value, double minMovement) => _toFixed(
  _jsRound(value / minMovement) * minMovement,
  _decimalPlaces(minMovement),
);

double _roundLot(double value, [double step = 0.01]) =>
    _toFixed(_jsRound(value / step) * step, 2);

double _floorLot(double value, [double step = 0.01]) =>
    _toFixed(((value + _epsilon) / step).floorToDouble() * step, 2);

bool _isLotAligned(double value, double step) {
  final scaled = value / step;
  return (scaled - _jsRound(scaled)).abs() < 1e-9;
}

// ---------------------------------------------------------------------------
// Trade plan parsing
// ---------------------------------------------------------------------------

enum _SideField { entryZone, stopLoss, takeProfit1, takeProfit2 }

double? _priceFromSide(TradeSide side, _SideField field) {
  final values = _numericValues(switch (field) {
    _SideField.entryZone => side.entryZone,
    _SideField.stopLoss => side.stopLoss,
    _SideField.takeProfit1 => side.takeProfit1,
    _SideField.takeProfit2 => side.takeProfit2,
  });
  if (values.isEmpty) return null;
  if (field == _SideField.entryZone && values.length > 1) {
    return (values[0] + values[1]) / 2;
  }
  return values[0];
}

class _EntryRange {
  const _EntryRange(this.low, this.high, this.midpoint);
  final double low;
  final double high;
  final double midpoint;
}

_EntryRange? _entryRange(TradeSide side) {
  final values = _numericValues(side.entryZone);
  if (values.isEmpty) return null;
  final second = values.length > 1 ? values[1] : values[0];
  final low = math.min(values[0], second);
  final high = math.max(values[0], second);
  return _EntryRange(low, high, (low + high) / 2);
}

TradeSide _tradeSide(TradePlan plan, String side) =>
    side == 'buy' ? plan.buy : plan.sell;

String? _sideGeometryError(String side, TradeSide tradeSide) {
  final entry = _priceFromSide(tradeSide, _SideField.entryZone);
  final stopLoss = _priceFromSide(tradeSide, _SideField.stopLoss);
  if (entry == null || stopLoss == null || entry == stopLoss) {
    return '${side == 'buy' ? 'Buy' : 'Sell'} levels are incomplete in the Standard Plan.';
  }
  if (side == 'buy' && stopLoss >= entry) {
    return 'Buy stop loss must be below the Standard Plan entry.';
  }
  if (side == 'sell' && stopLoss <= entry) {
    return 'Sell stop loss must be above the Standard Plan entry.';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Candles
// ---------------------------------------------------------------------------

class AdaptiveCandle {
  const AdaptiveCandle({
    this.date,
    this.open,
    required this.high,
    required this.low,
    this.close,
  });

  factory AdaptiveCandle.fromMarket(MarketCandle candle) => AdaptiveCandle(
    date: candle.date,
    open: candle.open,
    high: candle.high,
    low: candle.low,
    close: candle.close,
  );

  factory AdaptiveCandle.fromSnapshot(MarketSnapshotCandle candle) =>
      AdaptiveCandle(
        date: candle.date,
        open: candle.open.toDouble(),
        high: candle.high.toDouble(),
        low: candle.low.toDouble(),
        close: candle.close.toDouble(),
      );

  final DateTime? date;
  final double? open;
  final double high;
  final double low;
  final double? close;
}

List<AdaptiveCandle> _validCandles(List<AdaptiveCandle>? candles) {
  final valid = (candles ?? const <AdaptiveCandle>[]).where(
    (candle) =>
        candle.high.isFinite &&
        candle.low.isFinite &&
        candle.low > 0 &&
        candle.high >= candle.low &&
        (candle.open == null ||
            (candle.open!.isFinite &&
                candle.open! >= candle.low &&
                candle.open! <= candle.high)) &&
        (candle.close == null ||
            (candle.close!.isFinite &&
                candle.close! >= candle.low &&
                candle.close! <= candle.high)),
  );
  final list = valid.toList();
  return list.length > 160 ? list.sublist(list.length - 160) : list;
}

const _supportedTimeframes = {'1m', '5m', '15m', '30m', '1h', '4h', '1d', '1w'};

/// Swing-low / swing-high prices inside each side's saved entry→stop path.
Map<String, List<double>> adaptiveChartCandidates(
  List<AdaptiveCandle> candles,
  TradePlan tradePlan,
  double minMovement,
) {
  final candidates = <String, List<double>>{'buy': [], 'sell': []};
  final recent = _validCandles(candles);
  if (recent.length < 5 || !minMovement.isFinite || minMovement <= 0) {
    return candidates;
  }

  List<double> collect(String side) {
    final tradeSide = _tradeSide(tradePlan, side);
    final entry = _priceFromSide(tradeSide, _SideField.entryZone);
    final stop = _priceFromSide(tradeSide, _SideField.stopLoss);
    if (entry == null || stop == null) return [];
    final distance = (entry - stop).abs();
    final minimumSeparation = math.max(minMovement * 2, distance * 0.025);
    final raw = <double>[];
    for (var index = 2; index < recent.length - 2; index++) {
      final candle = recent[index];
      final neighbors = [
        recent[index - 2],
        recent[index - 1],
        recent[index + 1],
        recent[index + 2],
      ];
      final isSwing = side == 'buy'
          ? neighbors.every((neighbor) => candle.low <= neighbor.low)
          : neighbors.every((neighbor) => candle.high >= neighbor.high);
      final price = side == 'buy' ? candle.low : candle.high;
      final insideSavedRiskPath = side == 'buy'
          ? price > stop && price < entry
          : price < stop && price > entry;
      if (isSwing && insideSavedRiskPath) {
        raw.add(_roundPrice(price, minMovement));
      }
    }
    final ordered = raw.toSet().toList()
      ..sort((a, b) => side == 'buy' ? b.compareTo(a) : a.compareTo(b));
    final kept = <double>[];
    for (var index = 0; index < ordered.length; index++) {
      final price = ordered[index];
      // Faithful to the web filter: every earlier ordered price counts.
      if (index == 0 ||
          ordered
              .take(index)
              .every((other) => (other - price).abs() >= minimumSeparation)) {
        kept.add(price);
      }
    }
    return kept.take(6).toList();
  }

  candidates['buy'] = collect('buy');
  candidates['sell'] = collect('sell');
  return candidates;
}

// ---------------------------------------------------------------------------
// Candle freshness
// ---------------------------------------------------------------------------

enum AdaptiveCandleFreshnessReason {
  barMissing('bar_missing'),
  barOld('bar_old'),
  sourceMissing('source_missing'),
  sourceOld('source_old'),
  feedUnavailable('feed_unavailable');

  const AdaptiveCandleFreshnessReason(this.wire);
  final String wire;
}

const _maxBarAgeMs = {
  '1m': 6 * 60 * 60000,
  '5m': 6 * 60 * 60000,
  '15m': 6 * 60 * 60000,
  '30m': 8 * 60 * 60000,
  '1h': 12 * 60 * 60000,
  '4h': 36 * 60 * 60000,
  '1d': 4 * 24 * 60 * 60000,
  '1w': 14 * 24 * 60 * 60000,
};

const _maxSourceAgeMs = {
  '1m': 30000,
  '5m': 60000,
  '15m': 3 * 60000,
  '30m': 4 * 60000,
  '1h': 5 * 60000,
  '4h': 15 * 60000,
  '1d': 60 * 60000,
  '1w': 60 * 60000,
};

class AdaptiveCandleFreshness {
  const AdaptiveCandleFreshness(this.reason, this.expiresAtMs);
  final AdaptiveCandleFreshnessReason? reason;
  final int? expiresAtMs;
}

AdaptiveCandleFreshness assessAdaptiveCandleFreshness(
  List<AdaptiveCandle> candles,
  String? timeframe, {
  DateTime? sourceFetchedAt,
  num? sourceMaxAgeMs,
  bool? isStale,
  String? staleReason,
  DateTime? now,
}) {
  final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final tf = timeframe?.toLowerCase() ?? '';
  final barAge = _maxBarAgeMs[tf];
  double barTime = double.nan;
  if (candles.isNotEmpty) {
    barTime = double.negativeInfinity;
    for (final candle in candles) {
      final ms = candle.date?.millisecondsSinceEpoch.toDouble();
      if (ms == null) {
        barTime = double.nan;
        break;
      }
      barTime = math.max(barTime, ms);
    }
  }
  if (barAge == null || !barTime.isFinite || barTime > nowMs + 60000) {
    return const AdaptiveCandleFreshness(
      AdaptiveCandleFreshnessReason.barMissing,
      null,
    );
  }
  if (barTime + barAge <= nowMs) {
    return const AdaptiveCandleFreshness(
      AdaptiveCandleFreshnessReason.barOld,
      null,
    );
  }

  final fetched = sourceFetchedAt?.millisecondsSinceEpoch;
  final localMaxAge = _maxSourceAgeMs[tf];
  if (fetched == null ||
      fetched > nowMs + 60000 ||
      localMaxAge == null ||
      sourceMaxAgeMs == null ||
      !sourceMaxAgeMs.isFinite ||
      sourceMaxAgeMs <= 0 ||
      isStale == null) {
    return const AdaptiveCandleFreshness(
      AdaptiveCandleFreshnessReason.sourceMissing,
      null,
    );
  }
  final sourceExpiry = fetched + math.min(localMaxAge, sourceMaxAgeMs);
  if (staleReason == 'feed_unavailable') {
    return const AdaptiveCandleFreshness(
      AdaptiveCandleFreshnessReason.feedUnavailable,
      null,
    );
  }
  if (isStale || staleReason != null || sourceExpiry <= nowMs) {
    return const AdaptiveCandleFreshness(
      AdaptiveCandleFreshnessReason.sourceOld,
      null,
    );
  }
  return AdaptiveCandleFreshness(
    null,
    math.min(sourceExpiry, barTime + barAge).toInt(),
  );
}

// ---------------------------------------------------------------------------
// Analysis context
// ---------------------------------------------------------------------------

class AdaptiveAnalysisContext {
  const AdaptiveAnalysisContext({
    this.timeframe,
    this.validUntil,
    this.marketCondition,
    this.riskLevel,
    this.tradingBias,
    this.confidenceMin,
    this.confidenceMax,
    this.techBuyCount,
    this.techSellCount,
    this.techNeutralCount,
    this.fundamentalContext,
  });

  factory AdaptiveAnalysisContext.fromAnalysis(Analysis analysis) =>
      AdaptiveAnalysisContext(
        timeframe: analysis.timeframe,
        validUntil: analysis.validUntil,
        marketCondition: analysis.marketCondition,
        riskLevel: analysis.riskLevel,
        tradingBias: analysis.tradingBias,
        confidenceMin: analysis.confidenceMin,
        confidenceMax: analysis.confidenceMax,
        techBuyCount: analysis.techBuyCount,
        techSellCount: analysis.techSellCount,
        techNeutralCount: analysis.techNeutralCount,
        fundamentalContext: analysis.fundamentalContext,
      );

  final String? timeframe;
  final DateTime? validUntil;
  final String? marketCondition;
  final String? riskLevel;
  final String? tradingBias;
  final int? confidenceMin;
  final int? confidenceMax;
  final int? techBuyCount;
  final int? techSellCount;
  final int? techNeutralCount;
  final FundamentalContext? fundamentalContext;
}

class AdaptiveTechnical {
  const AdaptiveTechnical(this.buy, this.sell, this.neutral);
  final int buy;
  final int sell;
  final int neutral;
}

class AdaptiveFundamental {
  const AdaptiveFundamental({
    required this.available,
    required this.newsCount,
    required this.eventCount,
    required this.highImpactCount,
  });
  final bool available;
  final int newsCount;
  final int eventCount;

  /// High-impact events within [-2h, +24h] of "now".
  final int highImpactCount;
}

class AdaptivePlanContext {
  const AdaptivePlanContext({
    required this.timeframe,
    required this.validUntil,
    required this.marketCondition,
    required this.riskLevel,
    required this.tradingBias,
    required this.confidenceMin,
    required this.confidenceMax,
    required this.technical,
    required this.fundamental,
  });
  final String? timeframe;
  final DateTime? validUntil;
  final String? marketCondition;
  final String? riskLevel;

  /// `bullish` | `bearish` | `neutral` | null.
  final String? tradingBias;
  final int? confidenceMin;
  final int? confidenceMax;
  final AdaptiveTechnical? technical;
  final AdaptiveFundamental fundamental;
}

String? _normalizeBias(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
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

AdaptivePlanContext _normalizeContext(
  AdaptiveAnalysisContext? input,
  int nowMs,
) {
  final hasTechnical =
      input?.techBuyCount != null &&
      input?.techSellCount != null &&
      input?.techNeutralCount != null &&
      input!.techBuyCount! >= 0 &&
      input.techSellCount! >= 0 &&
      input.techNeutralCount! >= 0;
  final fundamental = input?.fundamentalContext;
  final events = fundamental?.calendarEvents.toList() ?? const [];
  final upcoming = events.where((event) {
    if (event.impact != '★★★') return false;
    final time = event.time;
    final at = time == null
        ? null
        : DateTime.tryParse('${event.date}T$time:00Z')?.millisecondsSinceEpoch;
    return at != null &&
        at >= nowMs - 2 * 60 * 60 * 1000 &&
        at <= nowMs + 24 * 60 * 60 * 1000;
  }).length;
  return AdaptivePlanContext(
    timeframe: input?.timeframe,
    validUntil: input?.validUntil?.toUtc(),
    marketCondition: input?.marketCondition,
    riskLevel: input?.riskLevel,
    tradingBias: _normalizeBias(input?.tradingBias),
    confidenceMin: input?.confidenceMin,
    confidenceMax: input?.confidenceMax,
    technical: hasTechnical
        ? AdaptiveTechnical(
            input.techBuyCount!,
            input.techSellCount!,
            input.techNeutralCount!,
          )
        : null,
    fundamental: AdaptiveFundamental(
      available: fundamental != null,
      newsCount: fundamental?.newsItems.length ?? 0,
      eventCount: events.length,
      highImpactCount: upcoming,
    ),
  );
}

bool _hasCompleteContext(AdaptivePlanContext context, int nowMs) {
  final hasSupportedTimeframe =
      context.timeframe != null &&
      _supportedTimeframes.contains(context.timeframe!.toLowerCase());
  final validMarket = const {
    'trending_up',
    'trending_down',
    'ranging',
    'volatile',
  }.contains(context.marketCondition);
  final validRisk = const {'low', 'medium', 'high'}.contains(context.riskLevel);
  final validConfidence =
      context.confidenceMin != null &&
      context.confidenceMax != null &&
      context.confidenceMin! >= 0 &&
      context.confidenceMax! <= 100 &&
      context.confidenceMin! <= context.confidenceMax!;
  final fresh =
      context.validUntil != null &&
      context.validUntil!.millisecondsSinceEpoch > nowMs;
  return hasSupportedTimeframe &&
      validMarket &&
      validRisk &&
      context.tradingBias != null &&
      validConfidence &&
      context.technical != null &&
      context.fundamental.available &&
      fresh;
}

bool _timeframeIsShort(String? timeframe) =>
    timeframe != null &&
    const {'1m', '5m', '15m'}.contains(timeframe.toLowerCase());

// ---------------------------------------------------------------------------
// Risk policy
// ---------------------------------------------------------------------------

const _lotProfileFactors = {
  AdaptiveLotProfile.decreasing: [0.75, 0.5],
  AdaptiveLotProfile.mixed: [1.25, 0.75],
  AdaptiveLotProfile.increasing: [1.25, 1.5],
};

class _RiskPolicy {
  const _RiskPolicy(this.utilizationRate, this.layerRiskWeights);
  final double utilizationRate;
  final List<double> layerRiskWeights;
}

const _riskPolicies = {
  AdaptiveRiskStyle.conservative: _RiskPolicy(0.5, [0.4, 0.35, 0.25]),
  AdaptiveRiskStyle.balanced: _RiskPolicy(0.75, [0.5, 0.3, 0.2]),
  AdaptiveRiskStyle.aggressive: _RiskPolicy(1, [0.6, 0.25, 0.15]),
};

AdaptiveLotProfile adaptiveLotProfileFor(AdaptiveRiskStyle style) =>
    switch (style) {
      AdaptiveRiskStyle.conservative => AdaptiveLotProfile.decreasing,
      AdaptiveRiskStyle.balanced => AdaptiveLotProfile.mixed,
      AdaptiveRiskStyle.aggressive => AdaptiveLotProfile.increasing,
    };

AdaptiveLotProfile _resolveLotProfile(
  AdaptiveRiskStyle style,
  AdaptivePlanContext context,
  String preferredSide,
) {
  if (style == AdaptiveRiskStyle.conservative) {
    return AdaptiveLotProfile.decreasing;
  }
  if (context.marketCondition == 'ranging') return AdaptiveLotProfile.mixed;

  final buy = context.technical?.buy ?? 0;
  final sell = context.technical?.sell ?? 0;
  final trendAligned =
      (preferredSide == 'buy' &&
          context.marketCondition == 'trending_up' &&
          buy > sell) ||
      (preferredSide == 'sell' &&
          context.marketCondition == 'trending_down' &&
          sell > buy);
  final strongContext =
      trendAligned &&
      context.riskLevel == 'low' &&
      (context.confidenceMin ?? 0) >= 65 &&
      context.fundamental.highImpactCount == 0;
  if (!strongContext) return AdaptiveLotProfile.decreasing;
  return style == AdaptiveRiskStyle.aggressive
      ? AdaptiveLotProfile.increasing
      : AdaptiveLotProfile.mixed;
}

// ---------------------------------------------------------------------------
// Position plan
// ---------------------------------------------------------------------------

class AdaptiveLayer {
  const AdaptiveLayer({
    required this.level,
    required this.price,
    required this.lot,
    required this.cumulativeLots,
    required this.cumulativeRisk,
    required this.distanceFromEntry,
    required this.riskThisPosition,
    required this.marginThisPosition,
    required this.cumulativeMargin,
    required this.cumulativeFundsAtStop,
    required this.remainingFundsAtStop,
    required this.profitToTp1,
    required this.profitToTp2,
    required this.cumulativeProfitToTp1,
    required this.cumulativeProfitToTp2,
    required this.basis,
    required this.invalidationProgress,
  });

  final int level;
  final double price;
  final double lot;
  final double cumulativeLots;

  /// Loss if every entry up to and including this one hits the final stop.
  final double cumulativeRisk;
  final double distanceFromEntry;
  final double riskThisPosition;
  final double marginThisPosition;
  final double cumulativeMargin;
  final double cumulativeFundsAtStop;
  final double? remainingFundsAtStop;
  final double? profitToTp1;
  final double? profitToTp2;
  final double? cumulativeProfitToTp1;
  final double? cumulativeProfitToTp2;
  final AdaptiveLayerBasis basis;
  final double invalidationProgress;
}

class AdaptiveRejectedLayer {
  const AdaptiveRejectedLayer({
    required this.layer,
    required this.reason,
    required this.additionalFundsRequired,
    required this.additionalLossBudgetRequired,
  });
  final AdaptiveLayer layer;
  final AdaptiveRejectReason reason;

  /// Null unless [reason] is a financial one (margin / loss ceiling).
  final double? additionalFundsRequired;
  final double? additionalLossBudgetRequired;
}

class AdaptiveSidePlan {
  const AdaptiveSidePlan({
    required this.side,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.totalLots,
    required this.marginRequired,
    required this.estimatedLoss,
    required this.weightedAverageEntry,
    required this.fundsAtStop,
    required this.remainingFundsAtStop,
    required this.profitToTp1,
    required this.profitToTp2,
    required this.riskRewardToTp1,
    required this.riskRewardToTp2,
    required this.layers,
    this.rejectedLayers = const [],
  });

  final String side;
  final double entry;
  final double stopLoss;
  final double? takeProfit1;
  final double? takeProfit2;
  final double totalLots;
  final double marginRequired;
  final double estimatedLoss;
  final double weightedAverageEntry;
  final double fundsAtStop;
  final double? remainingFundsAtStop;
  final double? profitToTp1;
  final double? profitToTp2;
  final double? riskRewardToTp1;
  final double? riskRewardToTp2;
  final List<AdaptiveLayer> layers;
  final List<AdaptiveRejectedLayer> rejectedLayers;

  AdaptiveSidePlan withRejected(List<AdaptiveRejectedLayer> rejected) =>
      AdaptiveSidePlan(
        side: side,
        entry: entry,
        stopLoss: stopLoss,
        takeProfit1: takeProfit1,
        takeProfit2: takeProfit2,
        totalLots: totalLots,
        marginRequired: marginRequired,
        estimatedLoss: estimatedLoss,
        weightedAverageEntry: weightedAverageEntry,
        fundsAtStop: fundsAtStop,
        remainingFundsAtStop: remainingFundsAtStop,
        profitToTp1: profitToTp1,
        profitToTp2: profitToTp2,
        riskRewardToTp1: riskRewardToTp1,
        riskRewardToTp2: riskRewardToTp2,
        layers: layers,
        rejectedLayers: rejected,
      );
}

class AdaptivePositionPlanInput {
  const AdaptivePositionPlanInput({
    required this.instrument,
    required this.tradePlan,
    required this.standardRule,
    required this.availableFunds,
    required this.maximumLoss,
    required this.existingExposure,
    required this.initialLot,
    required this.accountTier,
    required this.levels,
    this.sideLevels,
    this.includedBuy = true,
    this.includedSell = true,
    this.layerLotFactors,
    this.layerRiskWeights,
    this.checkpointPrices,
  });

  final String instrument;
  final TradePlan tradePlan;
  final StandardTradingRuleInstrument? standardRule;
  final double? availableFunds;
  final double? maximumLoss;
  final double? existingExposure;
  final double? initialLot;
  final AdaptiveAccountTier accountTier;
  final int levels;
  final ({int? buy, int? sell})? sideLevels;
  final bool includedBuy;
  final bool includedSell;
  final List<double>? layerLotFactors;
  final List<double>? layerRiskWeights;
  final Map<String, List<double>>? checkpointPrices;
}

class AdaptivePositionPlanResult {
  const AdaptivePositionPlanResult({
    required this.valid,
    required this.market,
    required this.rule,
    required this.errors,
    required this.assumptions,
    required this.buy,
    required this.sell,
  });
  final bool valid;
  final String? market;
  final AdaptiveRule? rule;
  final List<String> errors;
  final List<String> assumptions;
  final AdaptiveSidePlan? buy;
  final AdaptiveSidePlan? sell;

  AdaptivePositionPlanResult copyWith({
    bool? valid,
    List<String>? errors,
    AdaptiveSidePlan? Function()? buy,
    AdaptiveSidePlan? Function()? sell,
  }) => AdaptivePositionPlanResult(
    valid: valid ?? this.valid,
    market: market,
    rule: rule,
    errors: errors ?? this.errors,
    assumptions: assumptions,
    buy: buy == null ? this.buy : buy(),
    sell: sell == null ? this.sell : sell(),
  );

  AdaptiveSidePlan? sideOf(String side) => side == 'buy' ? buy : sell;
}

class _Planned {
  _Planned(this.price, this.lot, this.basis, this.invalidationProgress);
  double price;
  double lot;
  AdaptiveLayerBasis basis;
  double invalidationProgress;
}

AdaptiveSidePlan? _sidePlan(
  String side,
  TradeSide tradeSide,
  AdaptivePositionPlanInput input,
  AdaptiveRule rule,
  int levels,
) {
  final entryRange = _entryRange(tradeSide);
  final rawEntry = entryRange?.midpoint;
  final rawStopLoss = _priceFromSide(tradeSide, _SideField.stopLoss);
  if (rawEntry == null ||
      rawStopLoss == null ||
      rawEntry == rawStopLoss ||
      input.initialLot == null) {
    return null;
  }
  final entry = _roundPrice(rawEntry, rule.minMovement);
  final stopLoss = _roundPrice(rawStopLoss, rule.minMovement);
  final tp1Value = _priceFromSide(tradeSide, _SideField.takeProfit1);
  final tp2Value = _priceFromSide(tradeSide, _SideField.takeProfit2);
  final takeProfit1 = tp1Value == null
      ? null
      : _roundPrice(tp1Value, rule.minMovement);
  final takeProfit2 = tp2Value == null
      ? null
      : _roundPrice(tp2Value, rule.minMovement);

  final distance = side == 'buy' ? entry - stopLoss : stopLoss - entry;
  final lotStep = rule.lotStep;
  final initialLot = _roundLot(input.initialLot!, lotStep);
  double? profitForLot(double price, double? target, double lot) {
    if (target == null) return null;
    final move = side == 'buy' ? target - price : price - target;
    return move > 0 ? move * _contractValueForLot(rule, lot) : null;
  }

  final checkpoints = <({double progress, AdaptiveLayerBasis basis})>[];
  final minimumSeparation = math.max(rule.minMovement * 2, distance * 0.025);
  double priceAtProgress(double progress) => _roundPrice(
    side == 'buy' ? entry - distance * progress : entry + distance * progress,
    rule.minMovement,
  );
  final adverseEdge = entryRange == null
      ? entry
      : _roundPrice(
          side == 'buy' ? entryRange.low : entryRange.high,
          rule.minMovement,
        );
  final edgeProgress = (entry - adverseEdge).abs() / distance;
  if (adverseEdge != entry &&
      adverseEdge != stopLoss &&
      edgeProgress > 0 &&
      edgeProgress < 1 &&
      (entry - adverseEdge).abs() >= minimumSeparation) {
    checkpoints.add((
      progress: edgeProgress,
      basis: AdaptiveLayerBasis.entryZoneEdge,
    ));
  }
  for (final price in input.checkpointPrices?[side] ?? const <double>[]) {
    final rounded = _roundPrice(price, rule.minMovement);
    final progress =
        (side == 'buy' ? entry - rounded : rounded - entry) / distance;
    if (!progress.isFinite ||
        progress <= 0 ||
        progress >= 1 ||
        (entry - rounded).abs() < minimumSeparation) {
      continue;
    }
    if (checkpoints.any(
      (candidate) =>
          (priceAtProgress(candidate.progress) - rounded).abs() <
          minimumSeparation,
    )) {
      continue;
    }
    checkpoints.add((
      progress: progress,
      basis: AdaptiveLayerBasis.currentChartSwing,
    ));
  }
  checkpoints.sort((a, b) => a.progress.compareTo(b.progress));

  final planned = <_Planned>[
    _Planned(entry, initialLot, AdaptiveLayerBasis.analysisEntry, 0),
  ];
  final additional = checkpoints.take(levels).toList();
  for (var index = 0; index < additional.length; index++) {
    final item = additional[index];
    final factors = input.layerLotFactors;
    final requestedFactor = factors != null && index < factors.length
        ? factors[index]
        : 1.0;
    final requestedLot = initialLot * math.max(0, requestedFactor);
    final cappedLot = rule.maximumLot == null
        ? requestedLot
        : math.min(requestedLot, rule.maximumLot!);
    planned.add(
      _Planned(
        priceAtProgress(item.progress),
        math.max(rule.minimumLot, _floorLot(cappedLot, lotStep)),
        item.basis,
        item.progress,
      ),
    );
  }

  final riskWeights = input.layerRiskWeights;
  if (riskWeights != null &&
      riskWeights.isNotEmpty &&
      input.maximumLoss != null) {
    final normalized = [
      for (var index = 0; index < planned.length; index++)
        math.max(0, index < riskWeights.length ? riskWeights[index] : 1.0),
    ];
    final totalWeight = normalized.fold<double>(0, (sum, w) => sum + w);
    if (totalWeight > 0) {
      for (var index = 0; index < planned.length; index++) {
        final item = planned[index];
        final riskPerLot =
            (side == 'buy' ? item.price - stopLoss : stopLoss - item.price) *
            rule.contractSize /
            rule.minimumLot;
        final allocatedRisk =
            input.maximumLoss! * (normalized[index] / totalWeight);
        final requestedLot = riskPerLot > 0 ? allocatedRisk / riskPerLot : 0.0;
        final cappedLot = rule.maximumLot == null
            ? requestedLot
            : math.min(requestedLot, rule.maximumLot!);
        item.lot = math.max(rule.minimumLot, _floorLot(cappedLot, lotStep));
      }
    }
  }

  var cumulativeLots = 0.0;
  var cumulativeRisk = 0.0;
  var cumulativeMargin = 0.0;
  double? cumulativeTp1 = takeProfit1 == null ? null : 0.0;
  double? cumulativeTp2 = takeProfit2 == null ? null : 0.0;
  var weightedEntryTotal = 0.0;
  final ladder = <AdaptiveLayer>[];
  for (var level = 0; level < planned.length; level++) {
    final item = planned[level];
    cumulativeLots = _roundLot(cumulativeLots + item.lot, lotStep);
    final riskForLot =
        (side == 'buy' ? item.price - stopLoss : stopLoss - item.price) *
        _contractValueForLot(rule, item.lot);
    final marginForLot = item.lot * rule.marginPerLot;
    final profit1 = profitForLot(item.price, takeProfit1, item.lot);
    final profit2 = profitForLot(item.price, takeProfit2, item.lot);
    cumulativeRisk += riskForLot;
    cumulativeMargin += marginForLot;
    final fundsAtStop = cumulativeMargin + cumulativeRisk;
    weightedEntryTotal += item.price * item.lot;
    cumulativeTp1 = cumulativeTp1 == null || profit1 == null
        ? null
        : cumulativeTp1 + profit1;
    cumulativeTp2 = cumulativeTp2 == null || profit2 == null
        ? null
        : cumulativeTp2 + profit2;
    ladder.add(
      AdaptiveLayer(
        level: level,
        price: item.price,
        lot: item.lot,
        cumulativeLots: cumulativeLots,
        cumulativeRisk: cumulativeRisk,
        distanceFromEntry: (entry - item.price).abs(),
        riskThisPosition: riskForLot,
        marginThisPosition: marginForLot,
        cumulativeMargin: cumulativeMargin,
        cumulativeFundsAtStop: fundsAtStop,
        remainingFundsAtStop: input.availableFunds == null
            ? null
            : input.availableFunds! - fundsAtStop,
        profitToTp1: profit1,
        profitToTp2: profit2,
        cumulativeProfitToTp1: cumulativeTp1,
        cumulativeProfitToTp2: cumulativeTp2,
        basis: item.basis,
        invalidationProgress: item.invalidationProgress,
      ),
    );
  }

  final weightedAverageEntry = weightedEntryTotal / cumulativeLots;
  final profitToTp1 = ladder.last.cumulativeProfitToTp1;
  final profitToTp2 = ladder.last.cumulativeProfitToTp2;
  return AdaptiveSidePlan(
    side: side,
    entry: entry,
    stopLoss: stopLoss,
    takeProfit1: takeProfit1,
    takeProfit2: takeProfit2,
    totalLots: cumulativeLots,
    marginRequired: cumulativeLots * rule.marginPerLot,
    estimatedLoss: cumulativeRisk,
    weightedAverageEntry: _roundPrice(weightedAverageEntry, rule.minMovement),
    fundsAtStop: cumulativeMargin + cumulativeRisk,
    remainingFundsAtStop: input.availableFunds == null
        ? null
        : input.availableFunds! - (cumulativeMargin + cumulativeRisk),
    profitToTp1: profitToTp1,
    profitToTp2: profitToTp2,
    riskRewardToTp1: profitToTp1 == null || cumulativeRisk <= 0
        ? null
        : profitToTp1 / cumulativeRisk,
    riskRewardToTp2: profitToTp2 == null || cumulativeRisk <= 0
        ? null
        : profitToTp2 / cumulativeRisk,
    layers: ladder,
  );
}

AdaptivePositionPlanResult buildAdaptivePositionPlan(
  AdaptivePositionPlanInput input,
) {
  final instrument = input.instrument.trim().toUpperCase();
  final market = _marketByInstrument[instrument]?.$1;
  final rule = adaptiveMarketRule(
    input.instrument,
    input.standardRule,
    input.accountTier,
  );
  final errors = <String>[];
  final includeBuy = input.includedBuy;
  final includeSell = input.includedSell;

  if (market == null) {
    errors.add(
      'Adaptive position planning is available only for supported canonical instruments.',
    );
  }
  if (rule == null) {
    errors.add(
      'TP Standard Trading Rules are unavailable for this instrument.',
    );
  }
  if (!includeBuy && !includeSell) {
    errors.add('At least one trade-plan side must be included.');
  }
  if (input.availableFunds == null || input.availableFunds! <= 0) {
    errors.add('Available trading funds are required.');
  }
  if (input.maximumLoss == null || input.maximumLoss! <= 0) {
    errors.add('Maximum acceptable loss is required.');
  }
  if (input.availableFunds != null &&
      input.maximumLoss != null &&
      input.maximumLoss! > input.availableFunds!) {
    errors.add(
      'Maximum acceptable loss cannot exceed available trading funds.',
    );
  }
  if (input.existingExposure == null || input.existingExposure! < 0) {
    errors.add('Existing exposure is required.');
  }
  if (input.initialLot == null || input.initialLot! <= 0) {
    errors.add('Initial lot is required.');
  }
  if (input.levels < 0 || input.levels > adaptiveMaxAdditionalLayers) {
    errors.add(
      'Number of additional levels must be between 0 and $adaptiveMaxAdditionalLayers.',
    );
  }
  final sideLevels = input.sideLevels;
  if (sideLevels != null) {
    for (final entry in [('buy', sideLevels.buy), ('sell', sideLevels.sell)]) {
      final level = entry.$2;
      if (level != null &&
          (level < 0 ||
              level > adaptiveMaxAdditionalLayers ||
              level > input.levels)) {
        errors.add(
          '${entry.$1 == 'buy' ? 'Buy' : 'Sell'} additional levels must be an integer between 0 and the requested level count (maximum $adaptiveMaxAdditionalLayers).',
        );
      }
    }
  }

  final spec = _tierSpecs[input.accountTier]!;
  final minimumLot = rule?.minimumLot ?? spec.minimumLot;
  final maximumLot = rule?.maximumLot ?? spec.maximumLot;
  final lotStep = rule?.lotStep ?? spec.lotStep;
  final tierName = input.accountTier.name;
  if (input.initialLot != null &&
      (input.initialLot! < minimumLot ||
          (maximumLot != null && input.initialLot! > maximumLot))) {
    errors.add('Initial lot must be within the $tierName tier range.');
  }
  if (input.initialLot != null &&
      input.initialLot! > 0 &&
      !_isLotAligned(input.initialLot!, lotStep)) {
    errors.add(
      'Initial lot must use ${lotStep.toStringAsFixed(2)} lot increments for the $tierName tier.',
    );
  }

  if (rule == null) {
    return AdaptivePositionPlanResult(
      valid: false,
      market: market,
      rule: null,
      errors: errors,
      assumptions: const [],
      buy: null,
      sell: null,
    );
  }

  final maxCycleLoss = input.maximumLoss ?? 0;
  final buyGeometryError = includeBuy
      ? _sideGeometryError('buy', input.tradePlan.buy)
      : null;
  final sellGeometryError = includeSell
      ? _sideGeometryError('sell', input.tradePlan.sell)
      : null;
  if (buyGeometryError != null) errors.add(buyGeometryError);
  if (sellGeometryError != null) errors.add(sellGeometryError);
  final buy = !includeBuy || buyGeometryError != null
      ? null
      : _sidePlan(
          'buy',
          input.tradePlan.buy,
          input,
          rule,
          sideLevels?.buy ?? input.levels,
        );
  final sell = !includeSell || sellGeometryError != null
      ? null
      : _sidePlan(
          'sell',
          input.tradePlan.sell,
          input,
          rule,
          sideLevels?.sell ?? input.levels,
        );

  final tierMax = rule.maximumLot;
  for (final plan in [buy, sell].whereType<AdaptiveSidePlan>()) {
    final word = plan.side == 'buy' ? 'Buy' : 'Sell';
    if (tierMax != null && plan.layers.any((layer) => layer.lot > tierMax)) {
      errors.add(
        '$word has a position above the $tierName per-position limit.',
      );
    }
    if (plan.marginRequired > (input.availableFunds ?? 0)) {
      errors.add('$word margin exceeds available trading funds.');
    }
    if (plan.estimatedLoss > maxCycleLoss) {
      errors.add(
        '$word loss at the final Stop Loss exceeds the entered maximum loss.',
      );
    }
    if (plan.fundsAtStop > (input.availableFunds ?? 0)) {
      errors.add(
        '$word day margin plus loss at the final Stop Loss exceeds available trading funds.',
      );
    }
    if (plan.layers.any((layer) => layer.price == plan.stopLoss)) {
      errors.add('$word ladder overlaps the Standard Plan stop loss.');
    }
  }

  final tierText = tierMax == null
      ? '${rule.minimumLot.toStringAsFixed(2)} lot and above'
      : '${rule.minimumLot.toStringAsFixed(2)}–${tierMax.toStringAsFixed(2)} lot';
  final movement = _jsNumber(rule.minMovement);
  final movementAssumption = rule.maxGapPercent == null
      ? 'Minimum movement from ${rule.source}: $movement; no percentage gap limit is assumed because the source rule does not provide one.'
      : 'Minimum movement from ${rule.source}: $movement; a gap above ${_jsNumber(rule.maxGapPercent!)}% is treated as an external execution risk.';
  final tierLabel = '${tierName[0].toUpperCase()}${tierName.substring(1)}';
  final assumptions = [
    '$tierLabel profile: USD ${_jsNumber(rule.marginAtMinimumLot)} margin for ${rule.minimumLot.toStringAsFixed(2)} lot; contract value ${_jsNumber(rule.contractSize)} ${rule.contractUnit} for one minimum-size position (${rule.minimumLot.toStringAsFixed(2)} lot). ${rule.contractIsAssumption ? 'Micro contract value is an assumption of 1/10 Mini, not an official broker rule.' : 'Contract value comes from the broker tier table; the API rule supplies Mini only.'}',
    movementAssumption,
    'Initial entry uses the Standard Plan; up to $adaptiveMaxAdditionalLayers manual additions are limited to distinct saved entry-zone or chart-swing prices. The $tierText range applies separately to each position, not to cumulative planned lots.',
    'The entered USD ${_jsNumber(maxCycleLoss)} maximum loss is a hard amount for every position in the complete plan.',
    'Available trading funds are used directly; the recommendation may reserve part of the entered loss ceiling according to risk style and market context.',
    'Current open ${input.instrument} $tierName exposure is ${_jsNumber(input.existingExposure ?? 0)} lot. It is not subtracted from the ${tierMax == null ? 'unlimited' : _jsNumber(tierMax)}-lot per-position cap; entered free funds must already exclude margin committed elsewhere.',
    'This Adaptive Position Plan is for day trading only: it uses the day/initial margin and excludes overnight holding, rollover, and overnight fees from every calculation.',
    'Broker auto-liquidation, spread, facility fee, VAT, slippage, and rejected orders are external risks and are not used to move ladder levels.',
  ];

  return AdaptivePositionPlanResult(
    valid: errors.isEmpty,
    market: market,
    rule: rule,
    errors: errors,
    assumptions: assumptions,
    buy: buy,
    sell: sell,
  );
}

/// JS `String(number)` for the values that appear in assumption text.
String _jsNumber(double value) {
  if (value == value.roundToDouble() && value.abs() < 1e21) {
    return value.toInt().toString();
  }
  return value.toString();
}

AdaptivePositionPlanResult _addRejectedCandidates(
  AdaptivePositionPlanResult accepted,
  AdaptivePositionPlanResult candidate,
  double marginBudget,
  double maximumLoss,
  int analysisLevelLimit,
) {
  AdaptiveSidePlan? decorate(
    AdaptiveSidePlan? acceptedSide,
    AdaptiveSidePlan? candidateSide,
  ) {
    if (acceptedSide == null || candidateSide == null) return acceptedSide;
    final rejected = candidateSide.layers.skip(acceptedSide.layers.length).map((
      layer,
    ) {
      final reason = layer.level > analysisLevelLimit
          ? AdaptiveRejectReason.analysisLimit
          : candidate.rule?.maximumLot != null &&
                layer.lot > candidate.rule!.maximumLot!
          ? AdaptiveRejectReason.tierLimit
          : layer.cumulativeFundsAtStop > marginBudget
          ? AdaptiveRejectReason.dayMargin
          : layer.cumulativeRisk > maximumLoss
          ? AdaptiveRejectReason.lossCeiling
          : AdaptiveRejectReason.analysisLimit;
      final financial =
          reason == AdaptiveRejectReason.dayMargin ||
          reason == AdaptiveRejectReason.lossCeiling;
      return AdaptiveRejectedLayer(
        layer: layer,
        reason: reason,
        additionalFundsRequired: financial
            ? math.max(0, layer.cumulativeFundsAtStop - marginBudget)
            : null,
        additionalLossBudgetRequired: financial
            ? math.max(0, layer.cumulativeRisk - maximumLoss)
            : null,
      );
    }).toList();
    return acceptedSide.withRejected(rejected);
  }

  return AdaptivePositionPlanResult(
    valid: accepted.valid,
    market: accepted.market,
    rule: accepted.rule,
    errors: accepted.errors,
    assumptions: accepted.assumptions,
    buy: decorate(accepted.buy, candidate.buy),
    sell: decorate(accepted.sell, candidate.sell),
  );
}

// ---------------------------------------------------------------------------
// Diagnostics
// ---------------------------------------------------------------------------

class AdaptiveVolatilityDiagnostic {
  const AdaptiveVolatilityDiagnostic({
    required this.status,
    required this.timeframe,
    required this.candleCount,
    required this.observedRange,
    required this.buyStopDistance,
    required this.sellStopDistance,
    required this.buyStopLooksTight,
    required this.sellStopLooksTight,
  });

  /// `unavailable` | `observed` | `tight_stop`.
  final String status;
  final String? timeframe;
  final int candleCount;
  final double? observedRange;
  final double? buyStopDistance;
  final double? sellStopDistance;
  final bool? buyStopLooksTight;
  final bool? sellStopLooksTight;

  bool stopLooksTight(String side) =>
      (side == 'buy' ? buyStopLooksTight : sellStopLooksTight) ?? false;
}

AdaptiveVolatilityDiagnostic _volatilityDiagnostic(
  List<AdaptiveCandle>? candles,
  String? timeframe,
  TradePlan tradePlan,
) {
  final normalized = timeframe?.toLowerCase();
  final recent = _validCandles(candles);
  if (normalized == null ||
      !_supportedTimeframes.contains(normalized) ||
      recent.length < 5) {
    return AdaptiveVolatilityDiagnostic(
      status: 'unavailable',
      timeframe: normalized,
      candleCount: recent.length,
      observedRange: null,
      buyStopDistance: null,
      sellStopDistance: null,
      buyStopLooksTight: null,
      sellStopLooksTight: null,
    );
  }
  final ranges = recent.map((c) => c.high - c.low).toList()..sort();
  final middle = ranges.length ~/ 2;
  final observedRange = ranges.length.isOdd
      ? ranges[middle]
      : (ranges[middle - 1] + ranges[middle]) / 2;
  double? stopDistance(String side) {
    final tradeSide = _tradeSide(tradePlan, side);
    final entry = _priceFromSide(tradeSide, _SideField.entryZone);
    final stop = _priceFromSide(tradeSide, _SideField.stopLoss);
    if (entry == null || stop == null || entry <= 0 || stop <= 0) return null;
    return (entry - stop).abs();
  }

  final buyDistance = stopDistance('buy');
  final sellDistance = stopDistance('sell');
  final buyTight = buyDistance == null ? null : buyDistance < observedRange;
  final sellTight = sellDistance == null ? null : sellDistance < observedRange;
  return AdaptiveVolatilityDiagnostic(
    status: (buyTight ?? false) || (sellTight ?? false)
        ? 'tight_stop'
        : 'observed',
    timeframe: normalized,
    candleCount: recent.length,
    observedRange: observedRange,
    buyStopDistance: buyDistance,
    sellStopDistance: sellDistance,
    buyStopLooksTight: buyTight,
    sellStopLooksTight: sellTight,
  );
}

class AdaptiveCandleAlternative {
  const AdaptiveCandleAlternative.available({
    required String this.side,
    required double this.entry,
    required double this.stopLoss,
    required double this.takeProfit,
    required double this.riskReward,
    required double this.lot,
    required double this.estimatedLoss,
    required double this.dayMargin,
  }) : available = true,
       reason = null;

  const AdaptiveCandleAlternative.needsReanalysis(String this.reason)
    : available = false,
      side = null,
      entry = null,
      stopLoss = null,
      takeProfit = null,
      riskReward = null,
      lot = null,
      estimatedLoss = null,
      dayMargin = null;

  final bool available;
  final String? reason;
  final String? side;
  final double? entry;
  final double? stopLoss;
  final double? takeProfit;
  final double? riskReward;
  final double? lot;
  final double? estimatedLoss;
  final double? dayMargin;
}

AdaptiveCandleAlternative _candleAlternative(
  List<AdaptiveCandle>? candles,
  String? timeframe,
  String side,
  TradePlan tradePlan,
  AdaptiveRule rule,
  double availableFunds,
  double usableRiskBudget,
) {
  final normalized = timeframe?.toLowerCase();
  final recent = _validCandles(candles);
  if (normalized == null ||
      !_supportedTimeframes.contains(normalized) ||
      recent.length < 7 ||
      side == 'none' ||
      side == 'both') {
    return const AdaptiveCandleAlternative.needsReanalysis(
      'A single supported direction and at least seven valid candles at the saved analysis timeframe are required to derive independent swing-based entry, stop, and target levels.',
    );
  }
  final lows = <double>[];
  final highs = <double>[];
  for (var index = 2; index < recent.length - 2; index++) {
    final candle = recent[index];
    final neighbors = [
      recent[index - 2],
      recent[index - 1],
      recent[index + 1],
      recent[index + 2],
    ];
    if (neighbors.every((n) => candle.low <= n.low)) lows.add(candle.low);
    if (neighbors.every((n) => candle.high >= n.high)) highs.add(candle.high);
  }
  final tradeSide = _tradeSide(tradePlan, side);
  final rawEntry = _priceFromSide(tradeSide, _SideField.entryZone);
  if (rawEntry == null || rawEntry <= 0) {
    return const AdaptiveCandleAlternative.needsReanalysis(
      'The saved entry is incomplete.',
    );
  }
  final savedStop = _priceFromSide(tradeSide, _SideField.stopLoss);
  if (savedStop == null) {
    return const AdaptiveCandleAlternative.needsReanalysis(
      'The saved stop is incomplete.',
    );
  }
  final savedRange = _entryRange(tradeSide);
  final tolerance = math.max(
    rule.minMovement * 2,
    (rawEntry - savedStop).abs() * 0.25,
  );
  final entryCandidates =
      (side == 'buy' ? lows : highs)
          .where(
            (price) => savedRange != null
                ? price >= savedRange.low && price <= savedRange.high
                : (price - rawEntry).abs() <= tolerance,
          )
          .toList()
        ..sort((a, b) => (a - rawEntry).abs().compareTo((b - rawEntry).abs()));
  for (final rawCandidate in entryCandidates) {
    final entry = _roundPrice(rawCandidate, rule.minMovement);
    final stopCandidates = side == 'buy'
        ? (lows.where((p) => p < entry - rule.minMovement * 2).toList()
            ..sort((a, b) => b.compareTo(a)))
        : (highs.where((p) => p > entry + rule.minMovement * 2).toList()
            ..sort((a, b) => a.compareTo(b)));
    final targetCandidates = side == 'buy'
        ? (highs.where((p) => p > entry + rule.minMovement * 2).toList()
            ..sort((a, b) => a.compareTo(b)))
        : (lows.where((p) => p < entry - rule.minMovement * 2).toList()
            ..sort((a, b) => b.compareTo(a)));
    for (final rawStop in stopCandidates) {
      for (final rawTarget in targetCandidates) {
        final stopLoss = _roundPrice(rawStop, rule.minMovement);
        final takeProfit = _roundPrice(rawTarget, rule.minMovement);
        final riskDistance = (entry - stopLoss).abs();
        final targetDistance = (takeProfit - entry).abs();
        final riskReward = riskDistance > 0 ? targetDistance / riskDistance : 0;
        if (riskReward < 1) continue;
        final lot = rule.minimumLot;
        final estimatedLoss = riskDistance * _contractValueForLot(rule, lot);
        final dayMargin = lot * rule.marginPerLot;
        if (estimatedLoss > usableRiskBudget ||
            estimatedLoss + dayMargin > availableFunds) {
          continue;
        }
        return AdaptiveCandleAlternative.available(
          side: side,
          entry: entry,
          stopLoss: stopLoss,
          takeProfit: takeProfit,
          riskReward: riskReward.toDouble(),
          lot: lot,
          estimatedLoss: estimatedLoss,
          dayMargin: dayMargin,
        );
      }
    }
  }
  return const AdaptiveCandleAlternative.needsReanalysis(
    'The candles do not provide independent swing entry, stop and target levels with at least 1:1 reward-to-risk that fit the current funds and loss ceiling.',
  );
}

int _availableLayerCount(
  String side,
  TradeSide tradeSide,
  Map<String, List<double>>? checkpointPrices,
  double minMovement,
) {
  final range = _entryRange(tradeSide);
  final stop = _priceFromSide(tradeSide, _SideField.stopLoss);
  if (range == null ||
      stop == null ||
      !minMovement.isFinite ||
      minMovement <= 0) {
    return 0;
  }
  final entry = _roundPrice(range.midpoint, minMovement);
  final roundedStop = _roundPrice(stop, minMovement);
  final distance = side == 'buy' ? entry - roundedStop : roundedStop - entry;
  if (distance <= 0) return 0;
  final prices = <double>{};
  final minimumSeparation = math.max(minMovement * 2, distance * 0.025);
  final adverseEdge = _roundPrice(
    side == 'buy' ? range.low : range.high,
    minMovement,
  );
  final edgeProgress =
      (side == 'buy' ? entry - adverseEdge : adverseEdge - entry) / distance;
  if (adverseEdge != entry &&
      adverseEdge != roundedStop &&
      edgeProgress > 0 &&
      edgeProgress < 1 &&
      (entry - adverseEdge).abs() >= minimumSeparation) {
    prices.add(adverseEdge);
  }
  for (final price in checkpointPrices?[side] ?? const <double>[]) {
    if (!price.isFinite) continue;
    final rounded = _roundPrice(price, minMovement);
    final progress =
        (side == 'buy' ? entry - rounded : rounded - entry) / distance;
    if (progress > 0 &&
        progress < 1 &&
        (entry - rounded).abs() >= minimumSeparation &&
        prices.every((other) => (other - rounded).abs() >= minimumSeparation)) {
      prices.add(rounded);
    }
  }
  return math.min(adaptiveMaxAdditionalLayers, prices.length);
}

// ---------------------------------------------------------------------------
// Recommendation
// ---------------------------------------------------------------------------

class AdaptiveMinimumLotDiagnostic {
  const AdaptiveMinimumLotDiagnostic({
    required this.lot,
    required this.marginRequired,
    required this.riskAtStop,
    required this.fundsRequiredAtStop,
    required this.effectiveLossBudget,
    required this.marginShortfall,
    required this.riskShortfall,
    required this.maximumLossShortfall,
    required this.blocker,
    required this.nextAction,
  });
  final double lot;
  final double marginRequired;
  final double riskAtStop;
  final double fundsRequiredAtStop;
  final double effectiveLossBudget;
  final double marginShortfall;
  final double riskShortfall;
  final double maximumLossShortfall;
  final AdaptiveBlocker blocker;
  final AdaptiveNextAction nextAction;
}

class AdaptiveSideEvaluation {
  const AdaptiveSideEvaluation(
    this.status, {
    this.diagnostic,
    this.conditionalPlan,
  });
  final AdaptiveSideStatus status;
  final AdaptiveMinimumLotDiagnostic? diagnostic;
  final AdaptiveSidePlan? conditionalPlan;

  AdaptiveSideEvaluation copyWith({
    AdaptiveSideStatus? status,
    AdaptiveSidePlan? conditionalPlan,
  }) => AdaptiveSideEvaluation(
    status ?? this.status,
    diagnostic: diagnostic,
    conditionalPlan: conditionalPlan ?? this.conditionalPlan,
  );
}

class AdaptiveBudget {
  const AdaptiveBudget({
    required this.initialLot,
    required this.levels,
    required this.positions,
    required this.marginBudget,
    required this.maximumLoss,
    required this.usableRiskBudget,
    required this.riskUtilizationRate,
    required this.contextRiskMultiplier,
    required this.unusedRiskBuffer,
    required this.riskStyle,
    required this.lotProfile,
  });
  final double initialLot;
  final int levels;
  final int positions;
  final double marginBudget;
  final double maximumLoss;
  final double usableRiskBudget;
  final double riskUtilizationRate;
  final double contextRiskMultiplier;
  final double unusedRiskBuffer;
  final AdaptiveRiskStyle riskStyle;
  final AdaptiveLotProfile lotProfile;
}

class AdaptiveRecommendation {
  const AdaptiveRecommendation({
    required this.result,
    required this.budget,
    required this.context,
    required this.posture,
    required this.preferredSide,
    required this.reasonCodes,
    required this.buyEvaluation,
    required this.sellEvaluation,
    required this.volatility,
    required this.candleAlternative,
  });

  final AdaptivePositionPlanResult result;

  /// Null when no side was viable.
  final AdaptiveBudget? budget;
  final AdaptivePlanContext context;
  final AdaptivePosture posture;

  /// `buy` | `sell` | `both` | `none`.
  final String preferredSide;
  final List<String> reasonCodes;
  final AdaptiveSideEvaluation buyEvaluation;
  final AdaptiveSideEvaluation sellEvaluation;
  final AdaptiveVolatilityDiagnostic volatility;
  final AdaptiveCandleAlternative candleAlternative;

  bool get valid => result.valid;
  List<String> get errors => result.errors;
  AdaptiveSidePlan? get buy => result.buy;
  AdaptiveSidePlan? get sell => result.sell;
  double get usableRisk => budget?.usableRiskBudget ?? 0;
  double get unusedRisk => budget?.unusedRiskBuffer ?? 0;

  AdaptiveSideEvaluation evaluationFor(String side) =>
      side == 'buy' ? buyEvaluation : sellEvaluation;
}

AdaptiveRecommendation _failed(
  AdaptivePositionPlanResult result,
  AdaptivePlanContext context,
  AdaptivePosture posture,
  AdaptiveVolatilityDiagnostic volatility,
  String reason,
) => AdaptiveRecommendation(
  result: result,
  budget: null,
  context: context,
  posture: posture,
  preferredSide: 'none',
  reasonCodes: const ['context_unavailable'],
  buyEvaluation: const AdaptiveSideEvaluation(AdaptiveSideStatus.unavailable),
  sellEvaluation: const AdaptiveSideEvaluation(AdaptiveSideStatus.unavailable),
  volatility: volatility,
  candleAlternative: AdaptiveCandleAlternative.needsReanalysis(reason),
);

AdaptiveRecommendation buildAdaptiveRecommendation({
  required String instrument,
  required TradePlan tradePlan,
  required double? availableMargin,
  required double? maximumLoss,
  required double? existingExposure,
  required StandardTradingRuleInstrument? standardRule,
  AdaptiveAnalysisContext? context,
  Map<String, List<double>>? checkpointPrices,
  List<AdaptiveCandle>? candles,
  AdaptiveAccountTier accountTier = AdaptiveAccountTier.mini,
  AdaptiveRiskStyle riskStyle = AdaptiveRiskStyle.conservative,
  DateTime? now,
}) {
  final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final market = _marketByInstrument[instrument.trim().toUpperCase()]?.$1;
  final rule = adaptiveMarketRule(instrument, standardRule, accountTier);
  final normalized = _normalizeContext(context, nowMs);
  final volatility = _volatilityDiagnostic(
    candles,
    normalized.timeframe,
    tradePlan,
  );
  AdaptiveCandleAlternative alternative(String preferred, double usableRisk) =>
      rule == null
      ? const AdaptiveCandleAlternative.needsReanalysis(
          'Instrument rule is unavailable.',
        )
      : _candleAlternative(
          candles,
          normalized.timeframe,
          preferred,
          tradePlan,
          rule,
          availableMargin ?? 0,
          usableRisk,
        );

  final reasons = <String>[];
  var posture = AdaptivePosture.scalingAllowed;
  var preferredSide = 'both';

  AdaptivePositionPlanResult emptyResult(List<String> errors) =>
      AdaptivePositionPlanResult(
        valid: false,
        market: market,
        rule: rule,
        errors: errors,
        assumptions: const [],
        buy: null,
        sell: null,
      );

  if (availableMargin == null ||
      availableMargin <= 0 ||
      maximumLoss == null ||
      maximumLoss <= 0 ||
      existingExposure == null ||
      existingExposure < 0) {
    final errors = <String>[];
    if (availableMargin == null || availableMargin <= 0) {
      errors.add('Available trading funds are required.');
    }
    if (maximumLoss == null || maximumLoss <= 0) {
      errors.add('Maximum acceptable loss is required.');
    }
    if (existingExposure == null || existingExposure < 0) {
      errors.add('Existing exposure is required.');
    }
    return _failed(
      emptyResult(errors),
      normalized,
      AdaptivePosture.entryOnly,
      volatility,
      'Account inputs are incomplete.',
    );
  }
  if (rule == null) {
    return _failed(
      AdaptivePositionPlanResult(
        valid: false,
        market: market,
        rule: null,
        errors: const [
          'TP Standard Trading Rules are unavailable for this instrument.',
        ],
        assumptions: const [],
        buy: null,
        sell: null,
      ),
      normalized,
      AdaptivePosture.entryOnly,
      volatility,
      'Instrument rule is unavailable.',
    );
  }
  if (maximumLoss > availableMargin) {
    return _failed(
      emptyResult(const [
        'Maximum acceptable loss cannot exceed available trading funds.',
      ]),
      normalized,
      AdaptivePosture.entryOnly,
      volatility,
      'Maximum loss exceeds available trading funds.',
    );
  }
  if (normalized.validUntil == null ||
      normalized.validUntil!.millisecondsSinceEpoch <= nowMs) {
    return _failed(
      emptyResult(const [
        'Saved analysis is expired or has no validUntil timestamp; reanalysis is required.',
      ]),
      normalized,
      AdaptivePosture.notRecommended,
      volatility,
      'The saved analysis is expired or lacks validUntil.',
    );
  }

  int layerCount(String side) => _availableLayerCount(
    side,
    _tradeSide(tradePlan, side),
    checkpointPrices,
    rule.minMovement,
  );

  var levels = math.max(layerCount('buy'), layerCount('sell'));

  if (!_hasCompleteContext(normalized, nowMs)) {
    posture = AdaptivePosture.entryOnly;
    levels = 0;
    preferredSide = 'none';
    reasons.add('context_unavailable');
    if (normalized.technical == null) reasons.add('technical_unavailable');
    if (!normalized.fundamental.available) {
      reasons.add('fundamental_unavailable');
    }
  } else {
    if (_timeframeIsShort(normalized.timeframe)) reasons.add('short_timeframe');
    if (normalized.riskLevel == 'high') reasons.add('high_risk');
    if (normalized.marketCondition == 'volatile') {
      reasons.add('volatile_market');
    }
    if (normalized.confidenceMax != null && normalized.confidenceMax! < 70) {
      reasons.add('low_confidence');
    }

    final marketDirection = normalized.marketCondition == 'trending_up'
        ? 'buy'
        : normalized.marketCondition == 'trending_down'
        ? 'sell'
        : null;
    final biasDirection = normalized.tradingBias == 'bullish'
        ? 'buy'
        : normalized.tradingBias == 'bearish'
        ? 'sell'
        : null;
    var conflict =
        marketDirection != null &&
        biasDirection != null &&
        marketDirection != biasDirection;

    if (normalized.tradingBias == 'neutral') {
      preferredSide = 'none';
      posture = AdaptivePosture.entryOnly;
      levels = 0;
      reasons.add('neutral_bias');
    } else if (biasDirection == 'buy') {
      preferredSide = 'buy';
      reasons.addAll(['trend_favors_buy', 'trend_opposes_sell']);
    } else if (biasDirection == 'sell') {
      preferredSide = 'sell';
      reasons.addAll(['trend_favors_sell', 'trend_opposes_buy']);
    }

    if (normalized.marketCondition == 'ranging') {
      reasons.add('range_supports_scaling');
    }

    final technical = normalized.technical;
    if (technical != null && normalized.tradingBias == 'neutral') {
      if (technical.buy > technical.sell) {
        reasons.add('technical_supports_buy');
      } else if (technical.sell > technical.buy) {
        reasons.add('technical_supports_sell');
      } else {
        reasons.add('technical_mixed');
      }
    } else if (technical != null && !conflict) {
      final directional = technical.buy + technical.sell;
      final imbalance = directional > 0
          ? (technical.buy - technical.sell).abs() / directional
          : 0;
      if (directional == 0 || imbalance < 0.2) {
        reasons.add('technical_mixed');
      } else if (technical.buy > technical.sell) {
        reasons.add('technical_supports_buy');
        if (preferredSide == 'sell') {
          conflict = true;
        } else {
          preferredSide = 'buy';
        }
      } else {
        reasons.add('technical_supports_sell');
        if (preferredSide == 'buy') {
          conflict = true;
        } else {
          preferredSide = 'sell';
        }
      }
    }
    if (conflict) {
      levels = 0;
      posture = AdaptivePosture.notRecommended;
      preferredSide = 'none';
      reasons.add('directional_conflict');
    }

    if (normalized.fundamental.highImpactCount > 0) {
      reasons.add('fundamental_high_impact');
    } else if (normalized.fundamental.newsCount +
            normalized.fundamental.eventCount >
        0) {
      reasons.add('fundamental_present');
    } else {
      reasons.add('fundamental_clear');
    }
  }

  if (posture != AdaptivePosture.notRecommended &&
      posture != AdaptivePosture.entryOnly) {
    if (preferredSide == 'buy') {
      levels = layerCount('buy');
    } else if (preferredSide == 'sell') {
      levels = layerCount('sell');
    } else if (preferredSide == 'both') {
      levels = math.max(layerCount('buy'), layerCount('sell'));
    } else {
      levels = 0;
    }
  }
  if (levels > 0) reasons.add('staged_add_condition');
  final lotProfile = _resolveLotProfile(riskStyle, normalized, preferredSide);
  final lotFactors = _lotProfileFactors[lotProfile]!;
  final policy = _riskPolicies[riskStyle]!;
  final contextMultiplier =
      reasons.contains('high_risk') ||
          reasons.contains('fundamental_high_impact')
      ? 0.5
      : reasons.any(
          (code) => const {
            'short_timeframe',
            'volatile_market',
            'low_confidence',
            'technical_mixed',
          }.contains(code),
        )
      ? 0.75
      : 1.0;
  final utilization = policy.utilizationRate * contextMultiplier;
  final usableRiskBudget = maximumLoss * utilization;
  final marginBudget = availableMargin;

  AdaptivePositionPlanInput sideInput(
    String side,
    int candidateLevels,
    double budget,
  ) => AdaptivePositionPlanInput(
    instrument: instrument,
    tradePlan: tradePlan,
    standardRule: standardRule,
    availableFunds: marginBudget,
    maximumLoss: budget,
    existingExposure: existingExposure,
    initialLot: rule.minimumLot,
    accountTier: accountTier,
    levels: candidateLevels,
    sideLevels: side == 'buy'
        ? (buy: candidateLevels, sell: 0)
        : (buy: 0, sell: candidateLevels),
    includedBuy: side == 'buy',
    includedSell: side == 'sell',
    layerLotFactors: lotFactors.take(candidateLevels).toList(),
    layerRiskWeights: policy.layerRiskWeights
        .take(candidateLevels + 1)
        .toList(),
    checkpointPrices: checkpointPrices,
  );

  final evaluations = <String, AdaptiveSideEvaluation>{
    'buy': const AdaptiveSideEvaluation(AdaptiveSideStatus.unavailable),
    'sell': const AdaptiveSideEvaluation(AdaptiveSideStatus.unavailable),
  };
  final sideResults =
      <
        String,
        ({
          AdaptivePositionPlanResult result,
          int levels,
          AdaptiveLotProfile profile,
        })?
      >{'buy': null, 'sell': null};
  bool isAligned(String side) => preferredSide == side;

  /// Steps the budget down 100%→1% (then fewer layers) until a plan is valid.
  ({
    AdaptivePositionPlanResult accepted,
    AdaptivePositionPlanResult full,
    int requested,
  })?
  acceptable(String side) {
    final requested = layerCount(side);
    final candidates = posture == AdaptivePosture.entryOnly
        ? [0]
        : [for (var i = 0; i <= requested; i++) requested - i];
    for (final candidateLevels in candidates) {
      AdaptivePositionPlanResult? accepted;
      for (var scale = 100; scale >= 1; scale--) {
        final candidate = buildAdaptivePositionPlan(
          sideInput(side, candidateLevels, usableRiskBudget * (scale / 100)),
        );
        if (candidate.valid) {
          accepted = candidate;
          break;
        }
      }
      if (accepted == null) continue;
      final full = candidateLevels < requested
          ? buildAdaptivePositionPlan(
              sideInput(side, requested, usableRiskBudget),
            )
          : accepted;
      return (accepted: accepted, full: full, requested: requested);
    }
    return null;
  }

  const analysisBlockCodes = {
    'context_unavailable',
    'short_timeframe',
    'high_risk',
    'volatile_market',
    'low_confidence',
    'neutral_bias',
    'fundamental_high_impact',
    'directional_conflict',
  };

  for (final side in const ['buy', 'sell']) {
    if (_sideGeometryError(side, _tradeSide(tradePlan, side)) != null) {
      evaluations[side] = const AdaptiveSideEvaluation(
        AdaptiveSideStatus.unavailable,
      );
      continue;
    }

    final minimumPlan = buildAdaptivePositionPlan(
      AdaptivePositionPlanInput(
        instrument: instrument,
        tradePlan: tradePlan,
        standardRule: standardRule,
        availableFunds: marginBudget,
        maximumLoss: usableRiskBudget,
        existingExposure: existingExposure,
        initialLot: rule.minimumLot,
        accountTier: accountTier,
        levels: 0,
        sideLevels: (buy: 0, sell: 0),
        includedBuy: side == 'buy',
        includedSell: side == 'sell',
        layerLotFactors: const [],
        layerRiskWeights: const [],
        checkpointPrices: checkpointPrices,
      ),
    );
    final minimumSidePlan = minimumPlan.sideOf(side);
    if (minimumSidePlan == null ||
        !minimumSidePlan.marginRequired.isFinite ||
        minimumSidePlan.marginRequired <= 0 ||
        !minimumSidePlan.estimatedLoss.isFinite ||
        minimumSidePlan.estimatedLoss <= 0 ||
        !minimumSidePlan.fundsAtStop.isFinite) {
      evaluations[side] = const AdaptiveSideEvaluation(
        AdaptiveSideStatus.unavailable,
      );
      continue;
    }
    final minMargin = minimumSidePlan.marginRequired;
    final minRisk = minimumSidePlan.estimatedLoss;
    final marginShortfall = math.max(
      0.0,
      minimumSidePlan.fundsAtStop - marginBudget,
    );
    final riskShortfall = math.max(0.0, minRisk - usableRiskBudget);
    final hasAnalysisBlock =
        posture == AdaptivePosture.notRecommended ||
        reasons.any(analysisBlockCodes.contains);
    final directionBlock =
        !isAligned(side) ||
        posture == AdaptivePosture.notRecommended ||
        reasons.contains('directional_conflict');
    final blocker = directionBlock
        ? AdaptiveBlocker.direction
        : hasAnalysisBlock
        ? AdaptiveBlocker.analysis
        : marginShortfall > 0 && riskShortfall > 0
        ? AdaptiveBlocker.marginAndRisk
        : marginShortfall > 0
        ? AdaptiveBlocker.margin
        : AdaptiveBlocker.risk;
    final diagnostic = AdaptiveMinimumLotDiagnostic(
      lot: rule.minimumLot,
      marginRequired: minMargin,
      riskAtStop: minRisk,
      fundsRequiredAtStop: minimumSidePlan.fundsAtStop,
      effectiveLossBudget: usableRiskBudget,
      marginShortfall: marginShortfall,
      riskShortfall: riskShortfall,
      maximumLossShortfall: math.max(0.0, minRisk / utilization - maximumLoss),
      blocker: blocker,
      nextAction: directionBlock
          ? AdaptiveNextAction.wait
          : hasAnalysisBlock
          ? AdaptiveNextAction.reanalysis
          : marginShortfall > 0 && riskShortfall > 0
          ? AdaptiveNextAction.fundsAndLossBudget
          : marginShortfall > 0
          ? AdaptiveNextAction.funds
          : AdaptiveNextAction.lossBudget,
    );
    evaluations[side] = AdaptiveSideEvaluation(
      AdaptiveSideStatus.blocked,
      diagnostic: diagnostic,
    );

    if (!isAligned(side)) {
      AdaptiveSidePlan? conditionalPlan;
      if (posture != AdaptivePosture.notRecommended) {
        final found = acceptable(side);
        if (found != null) {
          conditionalPlan = _addRejectedCandidates(
            found.accepted,
            found.full,
            marginBudget,
            usableRiskBudget,
            found.requested,
          ).sideOf(side);
        }
      }
      evaluations[side] = AdaptiveSideEvaluation(
        AdaptiveSideStatus.notAligned,
        diagnostic: diagnostic,
        conditionalPlan: conditionalPlan,
      );
      continue;
    }
    if (!minimumPlan.valid || posture == AdaptivePosture.notRecommended) {
      continue;
    }
    final found = acceptable(side);
    if (found == null) continue;
    final withRejected = _addRejectedCandidates(
      found.accepted,
      found.full,
      marginBudget,
      usableRiskBudget,
      found.requested,
    );
    sideResults[side] = (
      result: withRejected,
      levels: (withRejected.sideOf(side)?.layers.length ?? 1) - 1,
      profile: _resolveLotProfile(riskStyle, normalized, side),
    );
    evaluations[side] = const AdaptiveSideEvaluation(AdaptiveSideStatus.viable);
  }

  final selectedSide = preferredSide == 'buy' || preferredSide == 'sell'
      ? (sideResults[preferredSide] != null ? preferredSide : null)
      : null;
  if (selectedSide == null || posture == AdaptivePosture.notRecommended) {
    String word(String side) => side == 'buy' ? 'Buy' : 'Sell';
    final errors = [
      for (final side in const ['buy', 'sell'])
        if (isAligned(side) &&
            evaluations[side]!.status == AdaptiveSideStatus.blocked)
          '${word(side)} minimum lot exceeds the effective margin and/or Stop Loss risk budget.',
    ];
    if (errors.isEmpty) {
      errors.add(
        posture == AdaptivePosture.notRecommended
            ? 'The technical snapshot conflicts with the market direction.'
            : 'No directionally supported side has a safe minimum-lot plan.',
      );
    }
    return AdaptiveRecommendation(
      result: emptyResult(errors),
      budget: null,
      context: normalized,
      posture: posture == AdaptivePosture.scalingAllowed
          ? AdaptivePosture.notRecommended
          : posture,
      preferredSide: preferredSide,
      reasonCodes: reasons,
      buyEvaluation: evaluations['buy']!,
      sellEvaluation: evaluations['sell']!,
      volatility: volatility,
      candleAlternative: alternative('none', usableRiskBudget),
    );
  }

  final selected = sideResults[selectedSide]!;
  final acceptedLevels = selected.levels;
  final effectivePosture =
      acceptedLevels == 0 && posture == AdaptivePosture.scalingAllowed
      ? AdaptivePosture.entryOnly
      : posture;
  final effectiveReasons = acceptedLevels == 0
      ? reasons.where((code) => code != 'staged_add_condition').toList()
      : reasons;
  final result = AdaptivePositionPlanResult(
    valid: true,
    market: selected.result.market,
    rule: selected.result.rule,
    errors: const [],
    assumptions: selected.result.assumptions,
    buy: sideResults['buy']?.result.buy,
    sell: sideResults['sell']?.result.sell,
  );
  return AdaptiveRecommendation(
    result: result,
    budget: AdaptiveBudget(
      initialLot:
          selected.result.sideOf(selectedSide)?.layers.first.lot ??
          rule.minimumLot,
      levels: acceptedLevels,
      positions: acceptedLevels + 1,
      marginBudget: marginBudget,
      maximumLoss: maximumLoss,
      usableRiskBudget: usableRiskBudget,
      riskUtilizationRate: utilization,
      contextRiskMultiplier: contextMultiplier,
      unusedRiskBuffer: maximumLoss - usableRiskBudget,
      riskStyle: riskStyle,
      lotProfile: selected.profile,
    ),
    context: normalized,
    posture: effectivePosture,
    preferredSide: selectedSide,
    reasonCodes: effectiveReasons,
    buyEvaluation: evaluations['buy']!,
    sellEvaluation: evaluations['sell']!,
    volatility: volatility,
    candleAlternative: alternative(selectedSide, usableRiskBudget),
  );
}
