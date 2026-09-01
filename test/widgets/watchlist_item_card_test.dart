import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/widgets/watchlist/watchlist_item_card.dart';

import '../helpers/localized_test_app.dart';

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
      localizedTestApp(
        home: Scaffold(
          body: WatchlistItemCard(
            item: item,
            onRemove: (instrument) async => removed = instrument,
          ),
        ),
      ),
    );

    expect(find.text('XAU/USD'), findsOneWidget);
    expect(find.text('No previous analysis'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(removed, 'XAU/USD');
  });
}
