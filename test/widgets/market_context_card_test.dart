import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/models/market_context.dart';
import 'package:tradepilotapp/widgets/context/market_context_card.dart';

import '../helpers/localized_test_app.dart';

void main() {
  const bullish = MarketContext(
    instrument: 'XAU/USD',
    trend: MarketTrend.bullish,
    volatility: MarketLevel.medium,
    condition: 'Bullish dengan volatilitas sedang',
    explanation: 'Harga XAU/USD bergerak naik saat sesi London aktif.',
    riskLevel: MarketLevel.medium,
  );

  const bearish = MarketContext(
    instrument: 'EUR/USD',
    trend: MarketTrend.bearish,
    volatility: MarketLevel.high,
    condition: 'Bearish dan volatile',
    explanation: 'Harga EUR/USD bergerak turun saat sesi London aktif.',
    riskLevel: MarketLevel.high,
  );

  testWidgets('renders a bullish context', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: MarketContextCard(
            instrument: 'XAU/USD',
            marketContext: bullish,
          ),
        ),
      ),
    );

    expect(find.text('Bullish'), findsOneWidget);
    expect(find.text('Bullish dengan volatilitas sedang'), findsOneWidget);
    expect(
      find.text('Harga XAU/USD bergerak naik saat sesi London aktif.'),
      findsOneWidget,
    );
    expect(find.text('Medium'), findsOneWidget);
  });

  testWidgets('renders a bearish context', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: MarketContextCard(
            instrument: 'EUR/USD',
            marketContext: bearish,
          ),
        ),
      ),
    );

    expect(find.text('Bearish'), findsOneWidget);
    expect(find.text('Bearish dan volatile'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('shows an empty state when there is not enough data', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: MarketContextCard(instrument: 'XAU/USD', marketContext: null),
        ),
      ),
    );

    expect(
      find.text('There is not enough data to assess market conditions.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a loading indicator while data is not yet available', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: MarketContextCard(
            instrument: 'XAU/USD',
            marketContext: null,
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a retry action on error', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: MarketContextCard(
            instrument: 'XAU/USD',
            marketContext: null,
            hasError: true,
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(
      find.text('The market context could not be loaded.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));

    expect(retried, isTrue);
  });
}
