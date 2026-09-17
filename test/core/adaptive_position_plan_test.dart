import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/analysis/adaptive_position_plan.dart';

void main() {
  test('adaptive plan respects the hard loss ceiling', () {
    final plan = buildAdaptiveRecommendation(
      analysis: _analysis(),
      standardRule: _goldRule(),
      availableMargin: 5000,
      maximumLoss: 500,
      existingExposure: 0,
      accountTier: AdaptiveAccountTier.mini,
      riskStyle: AdaptiveRiskStyle.conservative,
      checkpointPrices: const {
        'buy': [2300, 2280],
        'sell': [2420, 2440],
      },
    );

    expect(plan.valid, isTrue);
    expect(plan.preferredSide, 'buy');
    expect(plan.buy!.layers.length, inInclusiveRange(1, 3));
    expect(plan.buy!.estimatedLoss, lessThanOrEqualTo(plan.usableRisk));
    expect(plan.buy!.fundsAtStop, lessThanOrEqualTo(5000));

    final invalid = buildAdaptiveRecommendation(
      analysis: _analysis(),
      standardRule: _goldRule(),
      availableMargin: 100,
      maximumLoss: 101,
      existingExposure: 0,
      accountTier: AdaptiveAccountTier.mini,
      riskStyle: AdaptiveRiskStyle.conservative,
    );
    expect(invalid.valid, isFalse);
    expect(invalid.errors.single, contains('cannot exceed'));
  });
}

Analysis _analysis() => $Analysis(
  (builder) => builder
    ..id = 1
    ..userId = 1
    ..instrument = 'XAU/USD'
    ..timeframe = '1h'
    ..mode = AnalysisModeEnum.pro
    ..validUntil = DateTime.utc(2026, 9, 8)
    ..marketCondition = 'trending_up'
    ..riskLevel = 'low'
    ..confidenceMin = 70
    ..confidenceMax = 80
    ..tradingBias = 'bullish'
    ..techBuyCount = 8
    ..techSellCount = 2
    ..techNeutralCount = 1
    ..tradePlan.replace(
      TradePlan(
        (plan) => plan
          ..preferredSide = TradePlanPreferredSideEnum.buy
          ..buy.replace(_side('2310–2330', '2200', '2400', '2500'))
          ..sell.replace(_side('2390–2410', '2500', '2300', '2200')),
      ),
    )
    ..fundamentalContext.replace(FundamentalContext())
    ..createdAt = DateTime.utc(2026, 9, 8),
);

TradeSide _side(String entry, String stop, String tp1, String tp2) => TradeSide(
  (builder) => builder
    ..entryZone = entry
    ..stopLoss = stop
    ..takeProfit1 = tp1
    ..takeProfit2 = tp2
    ..riskRewardRatio = '1:2'
    ..rationale = 'Test',
);

StandardTradingRuleInstrument _goldRule() => StandardTradingRuleInstrument(
  (builder) => builder
    ..code = StandardTradingRuleInstrumentCodeEnum.XUL10
    ..product = 'Gold'
    ..contractSize = 10
    ..contractUnit = StandardTradingRuleInstrumentContractUnitEnum.troyOunce
    ..tradingDays = 'Monday–Friday'
    ..tradingHours.update(
      (hours) => hours
        ..summer = '06:00–04:00'
        ..winter = '07:00–05:00',
    )
    ..initialMarginUsdPerLot = 100
    ..facilityFeeUsdPerLotPerSide = 5
    ..vatPercent = 11
    ..rolloverUsdPerLotPerNight = 3
    ..priceSource = 'Market feed'
    ..priceGuidance = 'Indicative'
    ..minimumSpread = '0.30'
    ..maximumSpread = '1.00'
    ..hecticSpread = 'May widen'
    ..minimumPriceMovement = '0.01'
    ..limitStopRange = 'Market dependent'
    ..deliveryBy = 'Cash',
);
