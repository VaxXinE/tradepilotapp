import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/analysis/adaptive_position_plan.dart';
import 'package:tradepilotapp/core/analysis/adaptive_tier_comparison.dart';

/// Replays fixtures produced by running the ORIGINAL web engine
/// (`adaptive-position-plan.ts` @ Trade-Pilot 4ef3a07) with a frozen clock.
/// The Dart engine must reproduce every number and every decision.
void main() {
  final reference =
      jsonDecode(
            utf8.decode(
              gzip.decode(
                File(
                  'test/fixtures/adaptive_reference.json.gz',
                ).readAsBytesSync(),
              ),
            ),
          )
          as Map<String, dynamic>;
  final now = DateTime.fromMillisecondsSinceEpoch(
    (reference['now'] as num).toInt(),
    isUtc: true,
  );

  test('fixture set exercises the interesting branches', () {
    final cases = (reference['cases'] as List).cast<Map<String, dynamic>>();
    bool has(bool Function(Map<String, dynamic>) test) => cases.any(test);
    Map<String, dynamic> rec(Map<String, dynamic> c) =>
        c['recommendation'] as Map<String, dynamic>;
    expect(has((c) => (rec(c)['result'] as Map)['valid'] == true), isTrue);
    expect(
      has((c) => ((rec(c)['recommendation'] as Map?)?['levels'] ?? 0) > 0),
      isTrue,
    );
    expect(
      has(
        (c) =>
            ((rec(c)['sideEvaluations'] as Map)['buy'] as Map)['status'] ==
            'not_aligned',
      ),
      isTrue,
    );
    expect(
      has((c) => (rec(c)['candleAlternative'] as Map)['status'] == 'available'),
      isTrue,
    );
  });

  group('recommendation', () {
    final cases = (reference['cases'] as List).cast<Map<String, dynamic>>();
    for (final entry in cases) {
      test('case ${entry['id']}', () {
        final input = entry['input'] as Map<String, dynamic>;
        final args = _RecommendationArgs.fromJson(input);
        final actual = buildAdaptiveRecommendation(
          instrument: args.instrument,
          tradePlan: args.tradePlan,
          availableMargin: args.availableMargin,
          maximumLoss: args.maximumLoss,
          existingExposure: args.existingExposure,
          standardRule: args.rule,
          context: args.context,
          checkpointPrices: args.checkpoints,
          candles: args.candles,
          accountTier: args.tier,
          riskStyle: args.style,
          now: now,
        );
        _expectMatch(
          _recommendationJson(actual),
          entry['recommendation'],
          'case ${entry['id']}.recommendation',
        );

        final tiers = compareAdaptiveAccountTiers(
          instrument: args.instrument,
          tradePlan: args.tradePlan,
          availableMargin: args.availableMargin,
          maximumLoss: args.maximumLoss,
          existingExposure: args.existingExposure,
          standardRule: args.rule,
          context: args.context,
          checkpointPrices: args.checkpoints,
          candles: args.candles,
          riskStyle: args.style,
          now: now,
        );
        _expectMatch(
          {
            for (final row in tiers.values)
              row.tier.name: {
                'buy': _tierSideJson(row.buy),
                'sell': _tierSideJson(row.sell),
                'action': row.action,
                'actionReason': row.actionReason.wire,
                'preferredSide': row.preferredSide,
              },
          },
          entry['tierSummary'],
          'case ${entry['id']}.tiers',
        );
      });
    }
  });

  group('position plan', () {
    final cases = (reference['planCases'] as List).cast<Map<String, dynamic>>();
    for (final entry in cases) {
      test('plan ${entry['id']}', () {
        final input = entry['input'] as Map<String, dynamic>;
        final rule = _rule(input['standardRule'] as Map<String, dynamic>);
        final actual = buildAdaptivePositionPlan(
          AdaptivePositionPlanInput(
            instrument: input['instrument'] as String,
            tradePlan: _tradePlan(input['tradePlan'] as Map<String, dynamic>),
            standardRule: rule,
            availableFunds: (input['availableFunds'] as num?)?.toDouble(),
            maximumLoss: (input['maximumLoss'] as num?)?.toDouble(),
            existingExposure: (input['existingExposure'] as num?)?.toDouble(),
            initialLot: (input['initialLot'] as num?)?.toDouble(),
            accountTier: _tier(input['accountTier'] as String),
            levels: input['levels'] as int,
            layerLotFactors: _doubles(input['layerLotFactors']),
            layerRiskWeights: _doubles(input['layerRiskWeights']),
            checkpointPrices: _checkpoints(input['checkpointPrices']),
          ),
        );
        _expectMatch(
          _resultJson(actual),
          entry['result'],
          'plan ${entry['id']}',
        );
      });
    }
  });

  group('helpers', () {
    final misc = reference['misc'] as Map<String, dynamic>;
    test('chart swing candidates', () {
      for (final entry in (misc['candidates'] as List)) {
        final data = entry as Map<String, dynamic>;
        final actual = adaptiveChartCandidates(
          _candles(data['candles'])!,
          _tradePlan(data['tradePlan'] as Map<String, dynamic>),
          (data['minMovement'] as num).toDouble(),
        );
        _expectMatch(actual, data['expected'], 'candidates');
      }
    });

    test('candle freshness', () {
      for (final entry in (misc['freshness'] as List)) {
        final data = entry as Map<String, dynamic>;
        final source = data['source'] as Map<String, dynamic>;
        final actual = assessAdaptiveCandleFreshness(
          _candles(data['candles'])!,
          data['timeframe'] as String,
          sourceFetchedAt: source['sourceFetchedAt'] == null
              ? null
              : DateTime.parse(source['sourceFetchedAt'] as String),
          sourceMaxAgeMs: source['sourceMaxAgeMs'] as num?,
          isStale: source['isStale'] as bool?,
          staleReason: source['staleReason'] as String?,
          now: now,
        );
        final expected = data['expected'] as Map<String, dynamic>;
        expect(actual.reason?.wire, expected['reason']);
        expect(actual.expiresAtMs, (expected['expiresAt'] as num?)?.toInt());
      }
    });

    test('margin capacity', () {
      for (final entry in (misc['capacity'] as List)) {
        final data = entry as Map<String, dynamic>;
        final rule = adaptiveMarketRule(
          data['instrument'] as String,
          _rule(data['standardRule'] as Map<String, dynamic>),
          _tier(data['tier'] as String),
        );
        expect(
          adaptiveMarginCapacity((data['funds'] as num?)?.toDouble(), rule),
          closeTo((data['expected'] as num).toDouble(), 1e-9),
          reason: '$data',
        );
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Fixture -> Dart inputs
// ---------------------------------------------------------------------------

class _RecommendationArgs {
  _RecommendationArgs({
    required this.instrument,
    required this.tradePlan,
    required this.availableMargin,
    required this.maximumLoss,
    required this.existingExposure,
    required this.rule,
    required this.context,
    required this.checkpoints,
    required this.candles,
    required this.tier,
    required this.style,
  });

  factory _RecommendationArgs.fromJson(Map<String, dynamic> input) =>
      _RecommendationArgs(
        instrument: input['instrument'] as String,
        tradePlan: _tradePlan(input['tradePlan'] as Map<String, dynamic>),
        availableMargin: (input['availableMargin'] as num?)?.toDouble(),
        maximumLoss: (input['maximumLoss'] as num?)?.toDouble(),
        existingExposure: (input['existingExposure'] as num?)?.toDouble(),
        rule: _rule(input['standardRule'] as Map<String, dynamic>),
        context: _context(input['context'] as Map<String, dynamic>),
        checkpoints: _checkpoints(input['checkpointPrices']),
        candles: _candles(input['candles']),
        tier: _tier(input['accountTier'] as String),
        style: AdaptiveRiskStyle.values.byName(input['riskStyle'] as String),
      );

  final String instrument;
  final TradePlan tradePlan;
  final double? availableMargin;
  final double? maximumLoss;
  final double? existingExposure;
  final StandardTradingRuleInstrument rule;
  final AdaptiveAnalysisContext context;
  final Map<String, List<double>>? checkpoints;
  final List<AdaptiveCandle>? candles;
  final AdaptiveAccountTier tier;
  final AdaptiveRiskStyle style;
}

AdaptiveAccountTier _tier(String name) =>
    AdaptiveAccountTier.values.byName(name);

List<double>? _doubles(Object? value) =>
    (value as List?)?.map((item) => (item as num).toDouble()).toList();

Map<String, List<double>>? _checkpoints(Object? value) {
  if (value == null) return null;
  final map = value as Map<String, dynamic>;
  return {
    'buy': _doubles(map['buy']) ?? const [],
    'sell': _doubles(map['sell']) ?? const [],
  };
}

List<AdaptiveCandle>? _candles(Object? value) => (value as List?)
    ?.map(
      (item) => AdaptiveCandle(
        date: DateTime.parse((item as Map)['date'] as String),
        open: (item['open'] as num).toDouble(),
        high: (item['high'] as num).toDouble(),
        low: (item['low'] as num).toDouble(),
        close: (item['close'] as num).toDouble(),
      ),
    )
    .toList();

TradePlan _tradePlan(Map<String, dynamic> json) =>
    standardSerializers.deserializeWith(TradePlan.serializer, json)!;

AdaptiveAnalysisContext _context(Map<String, dynamic> json) {
  final fundamental = json['fundamentalContext'];
  return AdaptiveAnalysisContext(
    timeframe: json['timeframe'] as String?,
    validUntil: json['validUntil'] == null
        ? null
        : DateTime.parse(json['validUntil'] as String),
    marketCondition: json['marketCondition'] as String?,
    riskLevel: json['riskLevel'] as String?,
    tradingBias: json['tradingBias'] as String?,
    confidenceMin: json['confidenceMin'] as int?,
    confidenceMax: json['confidenceMax'] as int?,
    techBuyCount: json['techBuyCount'] as int?,
    techSellCount: json['techSellCount'] as int?,
    techNeutralCount: json['techNeutralCount'] as int?,
    fundamentalContext: fundamental == null
        ? null
        : standardSerializers.deserializeWith(
            FundamentalContext.serializer,
            fundamental,
          ),
  );
}

StandardTradingRuleInstrument _rule(Map<String, dynamic> json) =>
    StandardTradingRuleInstrument(
      (builder) => builder
        ..code = StandardTradingRuleInstrumentCodeEnum.valueOf(
          json['code'] as String,
        )
        ..product = 'Fixture'
        ..contractSize = json['contractSize'] as num
        ..contractUnit = switch (json['contractUnit']) {
          'troy ounce' =>
            StandardTradingRuleInstrumentContractUnitEnum.troyOunce,
          'barrel' => StandardTradingRuleInstrumentContractUnitEnum.barrel,
          _ => StandardTradingRuleInstrumentContractUnitEnum.uSDSlashPoint,
        }
        ..tradingDays = 'Monday–Friday'
        ..tradingHours.update(
          (hours) => hours
            ..summer = '06:00–04:00'
            ..winter = '07:00–05:00',
        )
        ..initialMarginUsdPerLot = json['initialMarginUsdPerLot'] as num
        ..vatPercent = 11
        ..rolloverUsdPerLotPerNight = 3
        ..priceSource = 'Market feed'
        ..priceGuidance = 'Indicative'
        ..minimumSpread = '0.30'
        ..maximumSpread = '1.00'
        ..hecticSpread = 'May widen'
        ..minimumPriceMovement = json['minimumPriceMovement'] as String
        ..limitStopRange = 'Market dependent'
        ..deliveryBy = 'Cash',
    );

// ---------------------------------------------------------------------------
// Dart results -> the JSON shape produced by the web engine
// ---------------------------------------------------------------------------

Map<String, dynamic> _recommendationJson(AdaptiveRecommendation r) => {
  'result': _resultJson(r.result),
  'recommendation': r.budget == null
      ? null
      : {
          'initialLot': r.budget!.initialLot,
          'levels': r.budget!.levels,
          'positions': r.budget!.positions,
          'marginBudget': r.budget!.marginBudget,
          'maximumLoss': r.budget!.maximumLoss,
          'usableRiskBudget': r.budget!.usableRiskBudget,
          'riskUtilizationRate': r.budget!.riskUtilizationRate,
          'contextRiskMultiplier': r.budget!.contextRiskMultiplier,
          'unusedRiskBuffer': r.budget!.unusedRiskBuffer,
          'riskStyle': r.budget!.riskStyle.name,
          'lotProfile': r.budget!.lotProfile.name,
        },
  'context': {
    'timeframe': r.context.timeframe,
    'validUntil': r.context.validUntil?.toIso8601String(),
    'marketCondition': r.context.marketCondition,
    'riskLevel': r.context.riskLevel,
    'tradingBias': r.context.tradingBias,
    'confidenceMin': r.context.confidenceMin,
    'confidenceMax': r.context.confidenceMax,
    'technical': r.context.technical == null
        ? null
        : {
            'buy': r.context.technical!.buy,
            'sell': r.context.technical!.sell,
            'neutral': r.context.technical!.neutral,
          },
    'fundamental': {
      'available': r.context.fundamental.available,
      'newsCount': r.context.fundamental.newsCount,
      'eventCount': r.context.fundamental.eventCount,
      'highImpactCount': r.context.fundamental.highImpactCount,
      'upcomingHighImpactCount': r.context.fundamental.highImpactCount,
    },
  },
  'decision': {
    'posture': r.posture.wire,
    'preferredSide': r.preferredSide,
    'reasonCodes': r.reasonCodes,
  },
  'sideEvaluations': {
    'buy': _evaluationJson(r.buyEvaluation),
    'sell': _evaluationJson(r.sellEvaluation),
  },
  'volatilityDiagnostic': {
    'status': r.volatility.status,
    'timeframe': r.volatility.timeframe,
    'candleCount': r.volatility.candleCount,
    'observedRange': r.volatility.observedRange,
    'buyStopDistance': r.volatility.buyStopDistance,
    'sellStopDistance': r.volatility.sellStopDistance,
    'buyStopLooksTight': r.volatility.buyStopLooksTight,
    'sellStopLooksTight': r.volatility.sellStopLooksTight,
  },
  'candleAlternative': r.candleAlternative.available
      ? {
          'status': 'available',
          'side': r.candleAlternative.side,
          'entry': r.candleAlternative.entry,
          'stopLoss': r.candleAlternative.stopLoss,
          'takeProfit': r.candleAlternative.takeProfit,
          'riskReward': r.candleAlternative.riskReward,
          'lot': r.candleAlternative.lot,
          'estimatedLoss': r.candleAlternative.estimatedLoss,
          'dayMargin': r.candleAlternative.dayMargin,
        }
      : {'status': 'needs_reanalysis', 'reason': r.candleAlternative.reason},
};

Map<String, dynamic> _evaluationJson(AdaptiveSideEvaluation e) => {
  'status': e.status.wire,
  'diagnostic': e.diagnostic == null
      ? null
      : {
          'lot': e.diagnostic!.lot,
          'marginRequired': e.diagnostic!.marginRequired,
          'riskAtStop': e.diagnostic!.riskAtStop,
          'fundsRequiredAtStop': e.diagnostic!.fundsRequiredAtStop,
          'effectiveLossBudget': e.diagnostic!.effectiveLossBudget,
          'marginShortfall': e.diagnostic!.marginShortfall,
          'riskShortfall': e.diagnostic!.riskShortfall,
          'maximumLossShortfall': e.diagnostic!.maximumLossShortfall,
          'blocker': e.diagnostic!.blocker.wire,
          'nextAction': e.diagnostic!.nextAction.wire,
        },
  'conditionalPlan': e.conditionalPlan == null
      ? null
      : _sideJson(e.conditionalPlan!),
};

Map<String, dynamic> _resultJson(AdaptivePositionPlanResult r) => {
  'valid': r.valid,
  'market': r.market,
  'rule': r.rule == null
      ? null
      : {
          'market': r.rule!.market,
          'label': r.rule!.label,
          'accountTier': r.rule!.accountTier.name,
          'marginBasis': 'day',
          'contractSize': r.rule!.contractSize,
          'contractUnit': r.rule!.contractUnit,
          'contractSource': r.rule!.contractIsAssumption
              ? 'micro_assumption'
              : 'broker_document',
          'minMovement': r.rule!.minMovement,
          'marginPerLot': r.rule!.marginPerLot,
          'marginAtMinimumLot': r.rule!.marginAtMinimumLot,
          'minimumLot': r.rule!.minimumLot,
          'maximumLot': r.rule!.maximumLot,
          'lotStep': r.rule!.lotStep,
          'minimumOpeningFunds': r.rule!.minimumOpeningFunds,
          'maxGapPercent': r.rule!.maxGapPercent,
          'source': r.rule!.source,
        },
  'errors': r.errors,
  'assumptions': r.assumptions,
  'buy': r.buy == null ? null : _sideJson(r.buy!),
  'sell': r.sell == null ? null : _sideJson(r.sell!),
};

Map<String, dynamic> _layerJson(AdaptiveLayer l) => {
  'level': l.level,
  'price': l.price,
  'lot': l.lot,
  'cumulativeLots': l.cumulativeLots,
  'estimatedRiskToStop': l.cumulativeRisk,
  'distanceFromEntry': l.distanceFromEntry,
  'riskToStopForLot': l.riskThisPosition,
  'dayMarginForLot': l.marginThisPosition,
  'cumulativeDayMargin': l.cumulativeMargin,
  'cumulativeFundsAtStop': l.cumulativeFundsAtStop,
  'remainingFundsAtStop': l.remainingFundsAtStop,
  'profitToTakeProfit1': l.profitToTp1,
  'profitToTakeProfit2': l.profitToTp2,
  'cumulativeProfitToTakeProfit1': l.cumulativeProfitToTp1,
  'cumulativeProfitToTakeProfit2': l.cumulativeProfitToTp2,
  'basis': l.basis.wire,
  'invalidationProgress': l.invalidationProgress,
};

Map<String, dynamic> _sideJson(AdaptiveSidePlan p) => {
  'side': p.side,
  'entry': p.entry,
  'stopLoss': p.stopLoss,
  'takeProfit1': p.takeProfit1,
  'takeProfit2': p.takeProfit2,
  'totalLots': p.totalLots,
  'marginRequired': p.marginRequired,
  'estimatedCycleLoss': p.estimatedLoss,
  'weightedAverageEntry': p.weightedAverageEntry,
  'totalFundsAtStop': p.fundsAtStop,
  'remainingFundsAtStop': p.remainingFundsAtStop,
  'profitToTakeProfit1': p.profitToTp1,
  'profitToTakeProfit2': p.profitToTp2,
  'riskRewardToTakeProfit1': p.riskRewardToTp1,
  'riskRewardToTakeProfit2': p.riskRewardToTp2,
  'ladder': p.layers.map(_layerJson).toList(),
  'rejectedLadder': [
    for (final rejected in p.rejectedLayers)
      {
        ..._layerJson(rejected.layer),
        'rejectReason': rejected.reason.wire,
        'financialAlternative': rejected.additionalFundsRequired == null
            ? null
            : {
                'additionalFundsRequired': rejected.additionalFundsRequired,
                'additionalLossBudgetRequired':
                    rejected.additionalLossBudgetRequired,
              },
      },
  ],
};

Map<String, dynamic> _tierSideJson(AdaptiveTierSide s) => {
  'fit': s.fit.wire,
  'lot': s.lot,
  'margin': s.margin,
  'riskAtStop': s.riskAtStop,
  'fundsAtStop': s.fundsAtStop,
  'effectiveBudget': s.effectiveBudget,
  'marketAligned': s.marketAligned,
  'entry': s.entry,
};

// ---------------------------------------------------------------------------
// Comparison
// ---------------------------------------------------------------------------

/// Keys the Dart engine intentionally does not carry (pure display copy).
const _ignoredKeys = {'reason'};

void _expectMatch(Object? actual, Object? expected, String path) {
  if (expected is Map) {
    expect(actual, isA<Map>(), reason: '$path should be an object');
    final map = actual as Map;
    final keys = {...expected.keys, ...map.keys}
      ..removeWhere(
        (key) =>
            _ignoredKeys.contains(key) && path.toLowerCase().contains('ladder'),
      );
    for (final key in keys) {
      _expectMatch(map[key], expected[key], '$path.$key');
    }
  } else if (expected is List) {
    expect(actual, isA<List>(), reason: '$path should be a list');
    final list = actual as List;
    expect(list.length, expected.length, reason: '$path length');
    for (var i = 0; i < expected.length; i++) {
      _expectMatch(list[i], expected[i], '$path[$i]');
    }
  } else if (expected is num) {
    expect(actual, isA<num>(), reason: '$path should be a number');
    final a = (actual as num).toDouble();
    final e = expected.toDouble();
    expect(
      (a - e).abs() <= 1e-9 * math.max(1, e.abs()),
      isTrue,
      reason: '$path: $a != $e',
    );
  } else {
    expect(actual, expected, reason: path);
  }
}
