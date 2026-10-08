import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/analysis/adaptive_position_plan.dart';
import 'package:tradepilotapp/core/analysis/adaptive_tier_comparison.dart';

/// Behavioural scenarios. Every expected number was produced by the web engine
/// (`adaptive-position-plan.ts` @ Trade-Pilot 4ef3a07) for the same inputs; the
/// exhaustive replay lives in `adaptive_reference_test.dart`.
void main() {
  final now = DateTime.utc(2026, 9, 30, 12);

  AdaptiveRecommendation run({
    String instrument = 'XAU/USD',
    TradePlan? plan,
    StandardTradingRuleInstrument? rule,
    AdaptiveAnalysisContext? context,
    double funds = 5000,
    double loss = 500,
    AdaptiveAccountTier tier = AdaptiveAccountTier.mini,
    AdaptiveRiskStyle style = AdaptiveRiskStyle.conservative,
    Map<String, List<double>>? checkpoints,
  }) => buildAdaptiveRecommendation(
    instrument: instrument,
    tradePlan: plan ?? _goldPlan(),
    availableMargin: funds,
    maximumLoss: loss,
    existingExposure: 0,
    standardRule: rule ?? _goldRule(),
    context: context ?? _context(now),
    checkpointPrices:
        checkpoints ??
        const {
          'buy': [2300, 2280],
          'sell': [2420, 2440],
        },
    accountTier: tier,
    riskStyle: style,
    now: now,
  );

  group('contract value scales with the account tier', () {
    test('micro fits a wide gold stop that mini and regular cannot', () {
      final micro = run(tier: AdaptiveAccountTier.micro);
      expect(micro.valid, isTrue);
      expect(micro.preferredSide, 'buy');
      expect(micro.posture, AdaptivePosture.scalingAllowed);
      expect(micro.budget!.usableRiskBudget, 250);
      expect(micro.budget!.unusedRiskBuffer, 250);
      expect(micro.buy!.layers.map((l) => (l.price, l.lot)), [
        (2320.0, 0.01),
        (2310.0, 0.01),
      ]);
      expect(micro.buy!.estimatedLoss, closeTo(230, 1e-9));
      expect(micro.buy!.marginRequired, closeTo(20, 1e-9));
      expect(micro.buy!.fundsAtStop, closeTo(250, 1e-9));

      // A 120-point stop is USD 1,200 at the Mini minimum lot (10 oz), far
      // above a USD 250 usable budget. The previous port understated this 10x.
      for (final tier in [
        AdaptiveAccountTier.mini,
        AdaptiveAccountTier.regular,
      ]) {
        final blocked = run(tier: tier);
        expect(blocked.valid, isFalse, reason: tier.name);
        expect(blocked.posture, AdaptivePosture.notRecommended);
        expect(blocked.buyEvaluation.status, AdaptiveSideStatus.blocked);
        expect(
          blocked.errors.single,
          'Buy minimum lot exceeds the effective margin and/or Stop Loss risk budget.',
        );
      }
    });

    test('index contracts keep USD 5/point at Mini and Regular', () {
      final mini = run(
        instrument: 'HSI',
        plan: _hsiPlan(),
        rule: _hsiRule(),
        funds: 50000,
        loss: 5000,
        checkpoints: const {},
      );
      final regular = run(
        instrument: 'HSI',
        plan: _hsiPlan(),
        rule: _hsiRule(),
        funds: 500000,
        loss: 5000,
        tier: AdaptiveAccountTier.regular,
        checkpoints: const {},
      );
      expect(mini.valid, isTrue);
      expect(regular.valid, isTrue);
      expect(mini.buy!.layers.map((l) => l.lot), [0.1, 0.1]);
      expect(mini.buy!.estimatedLoss, closeTo(1625, 1e-9));
      expect(regular.buy!.layers.map((l) => l.lot), [1, 1]);
      // Same loss for ten times the lots: Regular does not multiply again.
      expect(regular.buy!.estimatedLoss, closeTo(1625, 1e-9));
      expect(regular.buy!.marginRequired, closeTo(2000, 1e-9));
    });

    test('the Micro contract is flagged as an assumption', () {
      final micro = adaptiveMarketRule(
        'XAU/USD',
        _goldRule(),
        AdaptiveAccountTier.micro,
      )!;
      final mini = adaptiveMarketRule(
        'XAU/USD',
        _goldRule(),
        AdaptiveAccountTier.mini,
      )!;
      expect(micro.contractIsAssumption, isTrue);
      expect(mini.contractIsAssumption, isFalse);
      expect(micro.contractSize, 1);
      expect(mini.contractSize, 10);
    });
  });

  group('guardrails', () {
    test('a neutral high-risk snapshot only offers conditional scenarios', () {
      final plan = run(
        context: _context(
          now,
          marketCondition: 'ranging',
          riskLevel: 'high',
          confidenceMin: 40,
          confidenceMax: 60,
          tradingBias: 'neutral',
          techBuy: 4,
          techSell: 6,
        ),
        funds: 1000,
        loss: 1000,
        style: AdaptiveRiskStyle.aggressive,
      );
      expect(plan.valid, isFalse);
      expect(plan.posture, AdaptivePosture.entryOnly);
      expect(plan.preferredSide, 'none');
      expect(
        plan.errors.single,
        'No directionally supported side has a safe minimum-lot plan.',
      );
      expect(plan.buyEvaluation.status, AdaptiveSideStatus.notAligned);
      expect(plan.sellEvaluation.status, AdaptiveSideStatus.notAligned);
      expect(plan.reasonCodes, containsAll(['high_risk', 'neutral_bias']));
    });

    test('a technical snapshot against the market direction is rejected', () {
      final plan = run(
        context: _context(now, marketCondition: 'trending_down'),
        style: AdaptiveRiskStyle.balanced,
      );
      expect(plan.valid, isFalse);
      expect(plan.posture, AdaptivePosture.notRecommended);
      expect(plan.reasonCodes, contains('directional_conflict'));
      expect(
        plan.errors.single,
        'The technical snapshot conflicts with the market direction.',
      );
    });

    test('an expired analysis needs a new analysis', () {
      final plan = run(
        context: _context(
          now,
          validUntil: now.subtract(const Duration(seconds: 1)),
        ),
        style: AdaptiveRiskStyle.balanced,
      );
      expect(plan.valid, isFalse);
      expect(plan.posture, AdaptivePosture.notRecommended);
      expect(plan.errors.single, contains('expired'));
      expect(plan.buyEvaluation.status, AdaptiveSideStatus.unavailable);
    });

    test('the hard loss limit cannot exceed the trading capital', () {
      final plan = run(funds: 100, loss: 101);
      expect(plan.valid, isFalse);
      expect(plan.errors.single, contains('cannot exceed'));
    });
  });

  group('tier comparison', () {
    test('every tier explains why it cannot enter', () {
      final tiers = compareAdaptiveAccountTiers(
        instrument: 'XAU/USD',
        tradePlan: _goldPlan(),
        availableMargin: 1000,
        maximumLoss: 10,
        existingExposure: 0,
        standardRule: _goldRule(),
        context: _context(now),
        checkpointPrices: const {},
        now: now,
      );
      final micro = tiers[AdaptiveAccountTier.micro]!;
      expect(micro.action, 'skip');
      expect(micro.actionReason, AdaptiveTierActionReason.hardRisk);
      expect(micro.buy.fit, AdaptiveTierFit.blockedRisk);
      expect(micro.buy.riskAtStop, closeTo(120, 1e-9));
      expect(micro.buy.fundsAtStop, closeTo(130, 1e-9));

      final mini = tiers[AdaptiveAccountTier.mini]!;
      expect(mini.actionReason, AdaptiveTierActionReason.both);
      expect(mini.buy.fit, AdaptiveTierFit.blockedBoth);
      expect(mini.buy.riskAtStop, closeTo(1200, 1e-9));
      expect(mini.buy.fundsAtStop, closeTo(1300, 1e-9));
      expect(
        tiers[AdaptiveAccountTier.regular]!.buy.riskAtStop,
        closeTo(12000, 1e-9),
      );
    });
  });

  group('inputs', () {
    test('timeframe digits inside level text are not prices', () {
      final plan = TradePlan(
        (b) => b
          ..preferredSide = TradePlanPreferredSideEnum.buy
          ..buy.replace(
            _side(
              'di atas 2320 setelah breakout H1',
              '2200 (close M15)',
              '2400',
              '2500',
            ),
          )
          ..sell.replace(_side('2390–2410', '2500', '2300', '2200')),
      );
      final result = run(plan: plan, tier: AdaptiveAccountTier.micro);
      expect(result.buy!.entry, 2320);
      expect(result.buy!.stopLoss, 2200);
    });

    test('chart swings inside the entry-to-stop path become candidates', () {
      final candles = <AdaptiveCandle>[
        for (var i = 0; i < 12; i++)
          AdaptiveCandle(
            date: DateTime.utc(2026, 9, 30, i),
            open: 2320,
            high: 2330 + (i.isEven ? 8 : 0),
            low: i == 6 ? 2290 : 2310 - (i % 3),
            close: 2322,
          ),
      ];
      final found = adaptiveChartCandidates(candles, _goldPlan(), 0.01);
      expect(found['buy'], contains(2290));
      expect(found['sell'], isNotNull);
    });
  });
}

// ---------------------------------------------------------------------------

AdaptiveAnalysisContext _context(
  DateTime now, {
  String marketCondition = 'trending_up',
  String riskLevel = 'low',
  String tradingBias = 'bullish',
  int confidenceMin = 70,
  int confidenceMax = 80,
  int techBuy = 8,
  int techSell = 2,
  DateTime? validUntil,
}) => AdaptiveAnalysisContext(
  timeframe: '1h',
  validUntil: validUntil ?? now.add(const Duration(hours: 6)),
  marketCondition: marketCondition,
  riskLevel: riskLevel,
  tradingBias: tradingBias,
  confidenceMin: confidenceMin,
  confidenceMax: confidenceMax,
  techBuyCount: techBuy,
  techSellCount: techSell,
  techNeutralCount: 1,
  fundamentalContext: FundamentalContext(),
);

TradePlan _goldPlan() => TradePlan(
  (b) => b
    ..preferredSide = TradePlanPreferredSideEnum.buy
    ..buy.replace(_side('2310–2330', '2200', '2400', '2500'))
    ..sell.replace(_side('2390–2410', '2500', '2300', '2200')),
);

TradePlan _hsiPlan() => TradePlan(
  (b) => b
    ..preferredSide = TradePlanPreferredSideEnum.buy
    ..buy.replace(_side('18450–18500', '18300', '18800', '19000'))
    ..sell.replace(_side('18600–18650', '18800', '18300', '18100')),
);

TradeSide _side(String entry, String stop, String tp1, String tp2) => TradeSide(
  (b) => b
    ..entryZone = entry
    ..stopLoss = stop
    ..takeProfit1 = tp1
    ..takeProfit2 = tp2
    ..riskRewardRatio = '1:2'
    ..rationale = 'Test',
);

StandardTradingRuleInstrument _goldRule() => StandardTradingRuleInstrument(
  (b) => b
    ..code = StandardTradingRuleInstrumentCodeEnum.XUL10
    ..product = 'Gold'
    ..contractSize = 10
    ..contractUnit = StandardTradingRuleInstrumentContractUnitEnum.troyOunce
    ..initialMarginUsdPerLot = 100
    ..minimumPriceMovement = '0.01'
    ..tradingDays = 'Monday–Friday'
    ..tradingHours.update(
      (h) => h
        ..summer = '06:00–04:00'
        ..winter = '07:00–05:00',
    )
    ..vatPercent = 11
    ..rolloverUsdPerLotPerNight = 3
    ..priceSource = 'Market feed'
    ..priceGuidance = 'Indicative'
    ..minimumSpread = '0.30'
    ..maximumSpread = '1.00'
    ..hecticSpread = 'May widen'
    ..limitStopRange = 'Market dependent'
    ..deliveryBy = 'Cash',
);

StandardTradingRuleInstrument _hsiRule() => StandardTradingRuleInstrument(
  (b) => b
    ..code = StandardTradingRuleInstrumentCodeEnum.HKK50_BBJ
    ..product = 'Hang Seng'
    ..contractSize = 5
    ..contractUnit = StandardTradingRuleInstrumentContractUnitEnum.uSDSlashPoint
    ..initialMarginUsdPerLot = 100
    ..minimumPriceMovement = '1 point'
    ..tradingDays = 'Monday–Friday'
    ..tradingHours.update(
      (h) => h
        ..summer = '08:15–02:00'
        ..winter = '09:15–03:00',
    )
    ..vatPercent = 11
    ..rolloverUsdPerLotPerNight = 3
    ..priceSource = 'Market feed'
    ..priceGuidance = 'Indicative'
    ..minimumSpread = '3'
    ..maximumSpread = '10'
    ..hecticSpread = 'May widen'
    ..limitStopRange = 'Market dependent'
    ..deliveryBy = 'Cash',
);
