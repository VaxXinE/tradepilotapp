import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/widgets/analysis_levels_chart.dart';
import 'package:tradepilotapp/widgets/market_mini_chart.dart';

import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('renders candlesticks and both trade-plan sides', (tester) async {
    final buy = _side('101', '99', '103', '105');
    final sell = _side('98', '102', '96', '94');
    final plan = TradePlan(
      (builder) => builder
        ..preferredSide = TradePlanPreferredSideEnum.buy
        ..buy.replace(buy)
        ..sell.replace(sell),
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: AnalysisLevelsChart(
            candles: [
              _candle(open: 100, close: 102),
              _candle(open: 102, close: 97),
            ],
            tradePlan: plan,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('bullish-candle-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bearish-candle-1')), findsOneWidget);
    expect(find.textContaining('BUY Entry'), findsWidgets);
    expect(find.textContaining('BUY TP2'), findsWidgets);
    expect(find.textContaining('SELL Entry'), findsWidgets);
    expect(find.textContaining('SELL TP2'), findsWidgets);

    final chart = tester.getRect(find.byType(CandlestickPlot));
    final gesture = await tester.startGesture(
      Offset(chart.left + 20, chart.center.dy),
    );
    await tester.pump(kLongPressTimeout);
    expect(find.byKey(const ValueKey('chart-price-tooltip')), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('chart-price-tooltip')), findsNothing);
  });

  testWidgets('shows levels that match the market bias', (tester) async {
    final plan = TradePlan(
      (builder) => builder
        ..preferredSide = TradePlanPreferredSideEnum.wait
        ..buy.replace(_side('101', '99', '103', '105'))
        ..sell.replace(_side('98', '102', '96', '94')),
    );

    Future<void> pump(String bias) => tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: AnalysisLevelsChart(
            candles: [
              _candle(open: 100, close: 102),
              _candle(open: 102, close: 97),
            ],
            tradePlan: plan,
            tradingBias: bias,
          ),
        ),
      ),
    );

    await pump('bullish');
    expect(find.textContaining('BUY Entry'), findsOneWidget);
    expect(find.textContaining('SELL Entry'), findsNothing);

    await pump('bearish');
    expect(find.textContaining('BUY Entry'), findsNothing);
    expect(find.textContaining('SELL Entry'), findsOneWidget);

    await pump('neutral');
    expect(find.textContaining('BUY Entry'), findsOneWidget);
    expect(find.textContaining('SELL Entry'), findsOneWidget);
  });
}

TradeSide _side(String entry, String stop, String tp1, String tp2) => TradeSide(
  (builder) => builder
    ..entryZone = entry
    ..stopLoss = stop
    ..takeProfit1 = tp1
    ..takeProfit2 = tp2
    ..riskRewardRatio = '1:2'
    ..rationale = 'Test',
);

MarketCandle _candle({required double open, required double close}) {
  return MarketCandle(
    date: DateTime.utc(2026, 9, 2),
    open: open,
    high: (open > close ? open : close) + 1,
    low: (open < close ? open : close) - 1,
    close: close,
  );
}
