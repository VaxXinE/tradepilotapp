import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/theme/app_colors.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/widgets/market_mini_chart.dart';

import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('renders bullish and bearish candles with beginner labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MarketMiniChart(
          candles: [
            _candle(open: 100, close: 105),
            _candle(open: 105, close: 101),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('bullish-candle-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bearish-candle-1')), findsOneWidget);
    final bullishBodies = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byKey(const ValueKey('bullish-candle-0')),
        matching: find.byType(ColoredBox),
      ),
    );
    final bearishBodies = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byKey(const ValueKey('bearish-candle-1')),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(
      bullishBodies.map((widget) => widget.color),
      everyElement(AppColors.takeProfit),
    );
    expect(
      bearishBodies.map((widget) => widget.color),
      everyElement(AppColors.stopLoss),
    );
    expect(find.textContaining('Candlesticks: green'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Resistance'), findsOneWidget);
  });

  testWidgets('shows loading state', (tester) async {
    await tester.pumpWidget(
      _app(const MarketMiniChart(candles: [], isLoading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty and safe error states', (tester) async {
    await tester.pumpWidget(_app(const MarketMiniChart(candles: [])));
    expect(find.text('Chart data is unavailable.'), findsOneWidget);

    await tester.pumpWidget(
      _app(const MarketMiniChart(candles: [], error: 'Data gagal dimuat.')),
    );
    expect(find.text('Data gagal dimuat.'), findsOneWidget);
  });
}

Widget _app(Widget child) => localizedTestApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

MarketCandle _candle({required double open, required double close}) {
  return MarketCandle(
    date: DateTime.utc(2026, 8, 21),
    open: open,
    high: open > close ? open + 1 : close + 1,
    low: open < close ? open - 1 : close - 1,
    close: close,
  );
}
