import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/widgets/risk/risk_tools_section.dart';

import '../helpers/localized_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('risk map support follows the backend instrument allowlist', () {
    expect(supportsRiskMap('xau/usd'), isTrue);
    expect(supportsRiskMap('BTC/USD'), isFalse);
  });

  testWidgets('risk map never presents insufficient data as low risk', (
    tester,
  ) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    auth.client.dio.httpClientAdapter = _RiskMapAdapter();
    String? selected;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: localizedTestApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => RiskToolsSection(
                  instrument: 'XAU/USD',
                  selectedTimeframe: selected ?? '1h',
                  onSelectTimeframe: (value) =>
                      setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Timeframe Risk Map'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Unavailable'), findsWidgets);
    expect(find.text('Low risk'), findsOneWidget);
    await tester.tap(find.text('Use 4h'));
    await tester.pump();
    expect(selected, '4h');
    expect(find.text('Selected'), findsOneWidget);

    await tester.ensureVisible(find.text('TP Standard Trading Rules'));
    await tester.tap(find.text('TP Standard Trading Rules'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Contract size'), findsOneWidget);
    expect(find.text('Source disclosure'), findsOneWidget);
  });
}

class _RiskMapAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/trading-rules/standard') {
      return _response({
        'name': 'TP Standard Trading Rules',
        'version': '1.0',
        'effectiveDate': '2026-01-01',
        'sourceDocument': 'Standard Rules.pdf',
        'fixedRate': {'usd': 1, 'idr': 16000, 'label': 'USD 1 = IDR 16,000'},
        'account': {
          'minimumDepositUsd': 100,
          'minimumLot': 0.1,
          'maximumLot': 10,
          'maintenanceMarginPercent': 70,
          'marginCallBelowPercent': 70,
          'marginCallRestorePercent': 100,
          'autoLiquidationAtOrBelowPercent': 20,
          'equityReviewThresholdUsd': 1000,
          'equityReviewThresholdIdr': 16000000,
        },
        'transactionFormula': '(sell - buy) × contract size × lot',
        'instruments': [
          {
            'code': 'XUL10',
            'product': 'Gold',
            'contractSize': 10,
            'contractUnit': 'troy ounce',
            'tradingDays': 'Monday–Friday',
            'tradingHours': {'summer': '06:00–04:00', 'winter': '07:00–05:00'},
            'initialMarginUsdPerLot': 1000,
            'facilityFeeUsdPerLotPerSide': 5,
            'vatPercent': 11,
            'rolloverUsdPerLotPerNight': 3,
            'priceSource': 'Market feed',
            'priceGuidance': 'Indicative only',
            'minimumSpread': '0.30',
            'maximumSpread': '1.00',
            'hecticSpread': 'May widen',
            'minimumPriceMovement': '0.01',
            'limitStopRange': 'Market dependent',
            'deliveryBy': 'Cash settlement',
          },
        ],
        'disclaimer': {
          'id': 'Bukan rekomendasi.',
          'en': 'Not a recommendation.',
        },
        'relationshipDisclosure': {
          'id': 'Pengungkapan sumber',
          'en': 'Source disclosure',
        },
      });
    }
    if (options.path != '/risk-map/timeframes') {
      throw StateError('Unexpected request: ${options.path}');
    }
    return _response({
      'instrument': 'XAU/USD',
      'generatedAt': '2026-09-08T01:00:00.000Z',
      'timeframes': [
        {
          'timeframe': '1h',
          'status': 'insufficient',
          'riskScore': null,
          'riskCategory': 'unavailable',
          'reasonCodes': ['INSUFFICIENT_HISTORY'],
          'metrics': null,
          'dataQuality': 'limited',
          'confidence': 'low',
          'recommendation': 'wait',
        },
        {
          'timeframe': '4h',
          'status': 'available',
          'riskScore': 22,
          'riskCategory': 'low',
          'reasonCodes': ['SIGNALS_RELATIVELY_ALIGNED'],
          'metrics': {
            'buySignals': 6,
            'sellSignals': 1,
            'neutralSignals': 2,
            'rsi14': 52.0,
            'change20Pct': 0.5,
            'bollingerWidthPct': 1.2,
          },
          'dataQuality': 'good',
          'confidence': 'high',
          'recommendation': 'eligible',
        },
      ],
      'overall': {'state': 'wait', 'reasonCode': 'INSUFFICIENT_TIMEFRAME_DATA'},
    });
  }

  ResponseBody _response(Object body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
