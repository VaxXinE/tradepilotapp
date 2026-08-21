import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
