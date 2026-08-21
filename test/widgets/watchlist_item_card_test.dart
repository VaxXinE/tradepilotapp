import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/widgets/watchlist/watchlist_item_card.dart';

void main() {
  testWidgets('shows instrument, empty analysis state, and removes item', (
    tester,
  ) async {
    String? removed;
    final item = WatchlistItem(
      (builder) => builder
        ..instrument = 'XAU/USD'
        ..addedAt = DateTime.utc(2026, 8, 21),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WatchlistItemCard(
            item: item,
            onRemove: (instrument) async => removed = instrument,
          ),
        ),
      ),
    );

    expect(find.text('XAU/USD'), findsOneWidget);
    expect(find.text('Belum ada analisis'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pump();
    expect(removed, 'XAU/USD');
  });
}
