import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/widgets/adaptive_position_plan_card.dart';

import '../helpers/localized_test_app.dart';

void main() {
  // AuthProvider reads secure storage as soon as it is built.
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('an expired analysis cannot be calculated', (tester) async {
    await _pump(
      tester,
      _analysis(validUntil: DateTime.now().subtract(const Duration(hours: 1))),
    );

    expect(
      find.byKey(const ValueKey('adaptive-analysis-expired')),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('create-adaptive-recommendation')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('an analysis without a candle snapshot sizes levels only', (
    tester,
  ) async {
    await _pump(tester, _analysis());

    expect(
      find.byKey(const ValueKey('adaptive-snapshot-warning')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('adaptive-candle-source-time')),
      findsNothing,
    );
  });

  testWidgets('a fresh saved snapshot is shown as the candle source', (
    tester,
  ) async {
    await _pump(tester, _analysis(snapshot: _snapshot()));

    expect(
      find.byKey(const ValueKey('adaptive-snapshot-warning')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('adaptive-candle-source-time')),
      findsOneWidget,
    );
  });

  testWidgets('a stale or unavailable snapshot is not used', (tester) async {
    await _pump(
      tester,
      _analysis(
        snapshot: _snapshot(
          status: MarketSnapshotSourceStatusEnum.staleSourceAge,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('adaptive-snapshot-warning')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('adaptive-candle-source-time')),
      findsNothing,
    );
  });

  testWidgets(
    'funds that cannot cover the minimum lot open the blocked dialog',
    (tester) async {
      await _pump(tester, _analysis());
      await _calculate(tester, funds: '1000', loss: '10');

      expect(
        find.byKey(const ValueKey('adaptive-blocked-dialog')),
        findsOneWidget,
      );
      expect(find.text("Why can't I enter?"), findsOneWidget);
      // Mini needs USD 1,200 at the stop for the minimum 0.10 lot.
      expect(
        find.byKey(const ValueKey('adaptive-blocked-edit-loss')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('adaptive-blocked-edit-funds')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('adaptive-blocked-dismiss')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('adaptive-blocked-dialog')),
        findsNothing,
      );
      // The decision stays on screen: skip, never an entry.
      expect(find.text('SKIP'), findsOneWidget);
    },
  );

  testWidgets('a plan that fits shows the scenario and its entries', (
    tester,
  ) async {
    await _pump(tester, _analysis());
    await tester.tap(find.text('Micro'));
    await tester.pumpAndSettle();
    await _calculate(tester, funds: '5000', loss: '500');

    expect(find.byKey(const ValueKey('adaptive-blocked-dialog')), findsNothing);
    expect(
      find.byKey(const ValueKey('adaptive-recommendation-result')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('adaptive-plan-buy')), findsOneWidget);
    expect(find.text('Plan ready to review'), findsWidgets);
    // Micro: 0.01 lot per entry, USD 230 at the final stop.
    expect(find.textContaining('0.01 lot'), findsWidgets);
    expect(find.text(r'$230'), findsWidgets);
  });

  testWidgets('editing an input clears the previous result', (tester) async {
    await _pump(tester, _analysis());
    await tester.tap(find.text('Micro'));
    await tester.pumpAndSettle();
    await _calculate(tester, funds: '5000', loss: '500');
    expect(
      find.byKey(const ValueKey('adaptive-recommendation-result')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('adaptive-loss-limit')),
      '400',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('adaptive-recommendation-result')),
      findsNothing,
    );
  });
}

Future<void> _calculate(
  WidgetTester tester, {
  required String funds,
  required String loss,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('adaptive-trading-capital')),
    funds,
  );
  await tester.enterText(
    find.byKey(const ValueKey('adaptive-loss-limit')),
    loss,
  );
  await tester.pumpAndSettle();
  final create = find.byKey(const ValueKey('create-adaptive-recommendation'));
  await tester.ensureVisible(create);
  await tester.pumpAndSettle();
  await tester.tap(create);
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, Analysis analysis) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  auth.client.dio.httpClientAdapter = _RulesAdapter();
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: localizedTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdaptivePositionPlanCard(
              analysis: analysis,
              candles: const [],
              onLearn: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RulesAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/trading-rules/standard') {
      return ResponseBody.fromString(
        jsonEncode(_rulesJson()),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('', 404);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _rulesJson() => {
  'name': 'TP Standard Trading Rules',
  'version': '1',
  'effectiveDate': '2026-01-01',
  'sourceDocument': 'fixture',
  'fixedRate': {'usd': 1, 'idr': 16000, 'label': 'fixture'},
  'account': {
    'minimumDepositUsd': 50,
    'minimumLot': 0.01,
    'maximumLot': 50,
    'maintenanceMarginPercent': 50,
    'marginCallBelowPercent': 50,
    'marginCallRestorePercent': 100,
    'autoLiquidationAtOrBelowPercent': 20,
    'equityReviewThresholdUsd': 100,
    'equityReviewThresholdIdr': 1600000,
  },
  'transactionFormula': 'fixture',
  'disclaimer': {'id': 'x', 'en': 'x'},
  'relationshipDisclosure': {'id': 'x', 'en': 'x'},
  'instruments': [
    {
      'code': 'XUL10',
      'product': 'Gold',
      'contractSize': 10,
      'contractUnit': 'troy ounce',
      'tradingDays': 'Monday–Friday',
      'tradingHours': {'summer': '06:00–04:00', 'winter': '07:00–05:00'},
      'initialMarginUsdPerLot': 100,
      'facilityFeeUsdPerLotPerSide': 5,
      'vatPercent': 11,
      'rolloverUsdPerLotPerNight': 3,
      'priceSource': 'Market feed',
      'priceGuidance': 'Indicative',
      'minimumSpread': '0.30',
      'maximumSpread': '1.00',
      'hecticSpread': 'May widen',
      'minimumPriceMovement': 'USD 0.01 / troy ounce',
      'limitStopRange': 'Market dependent',
      'deliveryBy': 'Cash',
    },
  ],
};

Analysis _analysis({DateTime? validUntil, MarketSnapshot? snapshot}) =>
    $Analysis(
      (b) => b
        ..id = 7
        ..userId = 1
        ..instrument = 'XAU/USD'
        ..timeframe = '1h'
        ..mode = AnalysisModeEnum.pro
        ..validUntil =
            validUntil ?? DateTime.now().add(const Duration(hours: 6))
        ..createdAt = DateTime.now().subtract(const Duration(minutes: 5))
        ..marketCondition = 'trending_up'
        ..riskLevel = 'low'
        ..tradingBias = 'bullish'
        ..confidenceMin = 70
        ..confidenceMax = 80
        ..techBuyCount = 8
        ..techSellCount = 2
        ..techNeutralCount = 1
        ..fundamentalContext.replace(FundamentalContext())
        ..marketSnapshot = snapshot?.toBuilder()
        ..tradePlan.replace(
          TradePlan(
            (plan) => plan
              ..preferredSide = TradePlanPreferredSideEnum.buy
              ..buy.replace(_side('2310–2330', '2200', '2400', '2500'))
              ..sell.replace(_side('2390–2410', '2500', '2300', '2200')),
          ),
        ),
    );

TradeSide _side(String entry, String stop, String tp1, String tp2) => TradeSide(
  (b) => b
    ..entryZone = entry
    ..stopLoss = stop
    ..takeProfit1 = tp1
    ..takeProfit2 = tp2
    ..riskRewardRatio = '1:2'
    ..rationale = 'Test',
);

MarketSnapshot _snapshot({
  MarketSnapshotSourceStatusEnum status = MarketSnapshotSourceStatusEnum.fresh,
}) {
  final base = DateTime.now().subtract(const Duration(minutes: 10));
  return MarketSnapshot(
    (b) => b
      ..instrument = 'XAU/USD'
      ..timeframe = '1h'
      ..capturedAt = DateTime.now().subtract(const Duration(minutes: 5))
      ..sourceFetchedAt = DateTime.now().subtract(const Duration(minutes: 5))
      ..priceAtAnalysis = 2320
      ..sourceStatus = status
      ..candles.addAll([
        for (var i = 0; i < 30; i++)
          MarketSnapshotCandle(
            (c) => c
              ..date = base.subtract(Duration(hours: 30 - i))
              ..open = 2320
              ..high = 2330
              ..low = 2310
              ..close = 2322,
          ),
      ]),
  );
}
