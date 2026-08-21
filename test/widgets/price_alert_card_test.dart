import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/widgets/price_alert/price_alert_card.dart';

UserPriceAlert _alert({
  required int id,
  String instrument = 'XAU/USD',
  String targetPrice = '2500',
  bool triggerAbove = true,
  String? note,
  UserPriceAlertStatusEnum status = UserPriceAlertStatusEnum.active,
}) => UserPriceAlert(
  (b) => b
    ..id = id
    ..instrument = instrument
    ..targetPrice = targetPrice
    ..triggerDirection = triggerAbove
        ? UserPriceAlertTriggerDirectionEnum.above
        : UserPriceAlertTriggerDirectionEnum.below
    ..note = note
    ..status = status
    ..createdAt = DateTime.utc(2026, 8, 21),
);

void main() {
  testWidgets('renders the alert list with condition and status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceAlertCard(
            alerts: [
              _alert(id: 1, note: 'cek ulang kondisi market'),
              _alert(
                id: 2,
                instrument: 'EUR/USD',
                targetPrice: '1.05',
                triggerAbove: false,
                status: UserPriceAlertStatusEnum.triggered,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('XAU/USD'), findsOneWidget);
    expect(find.text('Naik melewati 2500'), findsOneWidget);
    expect(find.text('cek ulang kondisi market'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);

    expect(find.text('EUR/USD'), findsOneWidget);
    expect(find.text('Turun melewati 1.05'), findsOneWidget);
    expect(find.text('Terpicu'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no alerts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PriceAlertCard(alerts: [])),
      ),
    );

    expect(find.textContaining('Belum ada price alert'), findsOneWidget);
  });

  testWidgets('shows a loading indicator while there is no data yet', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PriceAlertCard(alerts: [], isLoading: true)),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a retry action on error', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceAlertCard(
            alerts: const [],
            hasError: true,
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Price alert belum dapat dimuat.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));

    expect(retried, isTrue);
  });

  testWidgets('taps delete and shows a spinner for the deleting item', (
    tester,
  ) async {
    int? deletedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceAlertCard(
            alerts: [
              _alert(id: 1),
              _alert(id: 2, instrument: 'EUR/USD'),
            ],
            isDeleting: (id) => id == 2,
            onDelete: (id) => deletedId = id,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));

    expect(deletedId, 1);
  });
}
