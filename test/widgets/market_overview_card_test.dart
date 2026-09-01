import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/widgets/market/market_overview_card.dart';

import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows selected quote without advanced market fields', (
    tester,
  ) async {
    const quote = LiveMarketQuote(
      instrument: 'XAU/USD',
      symbol: 'XAUUSD',
      price: 2345.2,
      buy: 2345.1,
      sell: 2345.3,
      spread: 0.2,
      changePercent: 0.42,
      direction: 'up',
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: MarketOverviewCard(
            quote: quote,
            isLoading: false,
            error: null,
            updatedAt: DateTime.now(),
            onRetry: () {},
            onOpen: () {},
          ),
        ),
      ),
    );

    expect(find.text('Market Overview'), findsOneWidget);
    expect(find.text('XAU/USD'), findsOneWidget);
    expect(find.text('2,345.20'), findsOneWidget);
    expect(find.text('+0.42%'), findsOneWidget);
    expect(find.textContaining('Spread'), findsNothing);
  });
}
