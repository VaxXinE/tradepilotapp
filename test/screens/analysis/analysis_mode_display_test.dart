import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/theme/app_colors.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/market_provider.dart';
import 'package:tradepilotapp/repositories/market_repository.dart';
import 'package:tradepilotapp/screens/analysis/analysis_detail_screen.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  testWidgets('analysis detail clearly separates beginner and pro modes', (
    tester,
  ) async {
    await _pumpDetail(tester, _analysis(AnalysisModeEnum.beginner));

    expect(find.text('Beginner Mode'), findsOneWidget);
    expect(find.text('Leaning Bearish'), findsOneWidget);

    // The chart sits above the beginner explanation now, so scroll it in
    // before asserting on it.
    await tester.scrollUntilVisible(
      find.text('What does it mean?'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('What does it mean?'), findsOneWidget);
    // Technical detail now sits behind a collapsed section, so open it before
    // asserting on the indicators inside.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('analysis-technical-details')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analysis-technical-details')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('signal-scale-bar')), findsNWidgets(5));
    final segments = find.descendant(
      of: find.byKey(const ValueKey('signal-scale-bar')),
      matching: find.byType(ColoredBox),
    );
    expect(segments, findsNWidgets(25));
    for (final segment in segments.evaluate()) {
      expect(tester.getSize(find.byWidget(segment.widget)).height, 8);
    }
    expect(
      find.byKey(const ValueKey('indicator-signal-RSI (14)')),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Oscillator — 1h'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscillator — 1h'));
    await tester.pumpAndSettle();
    final buyDot = tester.widget<Container>(
      find.byKey(const ValueKey('indicator-signal-RSI (14)')),
    );
    final sellDot = tester.widget<Container>(
      find.byKey(const ValueKey('indicator-signal-MACD (12,26)')),
    );
    expect((buyDot.decoration! as BoxDecoration).color, AppColors.bullishLight);
    expect(
      (sellDot.decoration! as BoxDecoration).color,
      AppColors.bearishLight,
    );
    await tester.tap(find.text('Oscillator — 1h'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Moving Averages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moving Averages'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('indicator-signal-EMA (9)')),
      findsOneWidget,
    );

    await _pumpDetail(tester, _analysis(AnalysisModeEnum.pro));

    expect(find.text('Pro Mode'), findsOneWidget);
    expect(find.text('Bearish'), findsOneWidget);
    expect(find.text('What does it mean?'), findsNothing);
  });

  testWidgets('the price chart is visible without expanding anything', (
    tester,
  ) async {
    await _pumpDetail(tester, _analysis(AnalysisModeEnum.beginner));

    // No taps: opening a finished analysis must show the chart straight away.
    expect(find.text('Price Chart'), findsOneWidget);

    // It also must not be the collapsed evidence section that renders it.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('analysis-market-evidence')),
        matching: find.text('Price Chart'),
      ),
      findsNothing,
    );
  });

  testWidgets('analysis detail shows the journal linked by the server', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner),
      journal: {
        'id': 7,
        'analysisId': 1,
        'instrument': 'XAU/USD',
        'side': 'sell',
        'outcome': 'win',
        'mood': 'calm',
        'note': 'Entry sesuai rencana',
        'tradedAt': '2026-09-08T08:00:00.000Z',
        'createdAt': '2026-09-08T08:00:00.000Z',
        'updatedAt': '2026-09-08T08:00:00.000Z',
      },
    );

    await tester.scrollUntilVisible(
      find.text('My trade journal'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Entry sesuai rencana'), findsOneWidget);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester,
  Analysis analysis, {
  Map<String, Object?>? journal,
}) async {
  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  auth.client.dio.httpClientAdapter = _JournalAdapter(journal);
  final analysisProvider = _FakeAnalysisProvider(auth, analysis);
  final marketProvider = _FakeMarketProvider(auth);
  addTearDown(analysisProvider.dispose);
  addTearDown(marketProvider.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AnalysisProvider>.value(value: analysisProvider),
        ChangeNotifierProvider<MarketProvider>.value(value: marketProvider),
      ],
      child: localizedTestApp(
        home: AnalysisDetailScreen(
          key: ValueKey(analysis.id),
          analysisId: analysis.id,
          preloaded: analysis,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _JournalAdapter implements HttpClientAdapter {
  _JournalAdapter(this.journal);

  final Map<String, Object?>? journal;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.startsWith('/journal/for-analysis/')) {
      if (journal == null) return ResponseBody.fromString('', 404);
      return ResponseBody.fromString(
        jsonEncode(journal),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString('', 404);
  }

  @override
  void close({bool force = false}) {}
}

Analysis _analysis(AnalysisModeEnum mode) => $Analysis(
  (builder) => builder
    ..id = mode == AnalysisModeEnum.pro ? 2 : 1
    ..userId = 1
    ..instrument = 'XAU/USD'
    ..timeframe = '1h'
    ..mode = mode
    ..tradingBias = 'bearish'
    ..riskLevel = 'medium'
    ..validUntil = DateTime.utc(2030)
    ..createdAt = DateTime.utc(2026),
);

class _FakeAnalysisProvider extends AnalysisProvider {
  _FakeAnalysisProvider(super.auth, this.analysis);

  final Analysis analysis;

  @override
  Future<Analysis?> getAnalysis(int id, {bool silent = false}) async =>
      analysis;
}

class _FakeMarketProvider extends MarketProvider {
  _FakeMarketProvider(AuthProvider auth) : super(auth, MarketRepository(Dio()));

  @override
  Future<List<MarketCandle>> getCandlesFor(
    String instrument,
    String timeframe, {
    bool force = false,
  }) async => const [];

  @override
  Future<BeginnerTechnicalSnapshot?> getTechnicalFor(
    String instrument,
    String timeframe, {
    bool force = false,
  }) async => const BeginnerTechnicalSnapshot(
    lastClose: 100,
    change1dPercent: 0,
    rsi: 50,
    rsiSignal: 'Buy',
    macdAction: 'Sell',
    buyCount: 1,
    neutralCount: 1,
    sellCount: 1,
    overallSignal: 'Neutral',
    oscillatorBuyCount: 1,
    oscillatorNeutralCount: 1,
    oscillatorSellCount: 1,
    movingAverageBuyCount: 1,
    movingAverageNeutralCount: 1,
    movingAverageSellCount: 1,
    movingAverages: [
      TechnicalMovingAverage(period: 9, type: 'EMA', value: 100, signal: 'Buy'),
    ],
  );

  @override
  Future<void> loadQuotes({bool force = false, bool silent = false}) async {}
}
