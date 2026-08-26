import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/widgets/market/market_overview_card.dart';
import 'package:tradepilotapp/widgets/market/market_session_card.dart';

void main() {
  testWidgets('shows active overlap and high liquidity for beginners', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarketSessionCard(
            instrument: 'XAU/USD',
            now: DateTime.utc(2026, 8, 17, 14),
          ),
        ),
      ),
    );

    expect(find.text('London + New York'), findsOneWidget);
    expect(find.text('AKTIF'), findsOneWidget);
    expect(find.text('TINGGI'), findsOneWidget);
    expect(find.textContaining('London tutup dalam 3h'), findsOneWidget);
    expect(find.textContaining('UTC'), findsNothing);
  });

  testWidgets('market cards fit a small screen in dark mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                MarketOverviewCard(
                  quote: const LiveMarketQuote(
                    instrument: 'XAU/USD',
                    symbol: 'XAUUSD',
                    price: 2345.2,
                    changePercent: 0.42,
                    direction: 'up',
                  ),
                  isLoading: false,
                  error: null,
                  updatedAt: DateTime.now(),
                  onRetry: () {},
                  onOpen: () {},
                ),
                MarketSessionCard(
                  instrument: 'XAU/USD',
                  now: DateTime.utc(2026, 8, 17, 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ringkasan Pasar'), findsOneWidget);
    expect(find.text('Sesi Market'), findsOneWidget);
  });

  testWidgets('crypto remains active during the forex weekend', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarketSessionCard(
            instrument: 'BTC/USD',
            now: DateTime.utc(2026, 8, 22, 12),
          ),
        ),
      ),
    );

    expect(find.text('Market Crypto 24/7'), findsOneWidget);
    expect(find.text('AKTIF'), findsOneWidget);
    expect(find.text('BERVARIASI'), findsOneWidget);
  });
}
