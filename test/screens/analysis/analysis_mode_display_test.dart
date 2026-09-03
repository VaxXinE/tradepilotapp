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
    expect(find.text('Cenderung Turun'), findsOneWidget);
    expect(find.text('Apa artinya?'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
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
    expect(find.text('Apa artinya?'), findsNothing);
  });
}

Future<void> _pumpDetail(WidgetTester tester, Analysis analysis) async {
  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  final analysisProvider = _FakeAnalysisProvider(auth, analysis);
  final marketProvider = _FakeMarketProvider(auth);
  addTearDown(analysisProvider.dispose);
  addTearDown(marketProvider.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
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

Analysis _analysis(AnalysisModeEnum mode) => Analysis(
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
