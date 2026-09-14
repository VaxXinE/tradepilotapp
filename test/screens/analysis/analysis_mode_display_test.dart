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

    // Technical detail now sits behind a collapsed section, so open it before
    // asserting on the indicators inside.
    await _reveal(
      tester,
      find.byKey(const ValueKey('analysis-technical-details')),
      find.byType(Scrollable).first,
    );
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
    await _reveal(
      tester,
      find.text('What does it mean?'),
      find.byType(Scrollable).first,
    );

    await _pumpDetail(tester, _analysis(AnalysisModeEnum.pro));

    expect(find.text('Pro Mode'), findsOneWidget);
    expect(find.text('Bearish'), findsOneWidget);
    expect(find.text('What does it mean?'), findsNothing);
  });

  testWidgets('market condition uses a localized semantic chip', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner, marketCondition: 'trending_up'),
    );

    expect(find.text('Uptrend'), findsOneWidget);
    expect(find.text('trending_up'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Medium Risk'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Medium Risk'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('analysis-result-header')),
        matching: find.byKey(const ValueKey('analysis-risk-chip')),
      ),
      findsOneWidget,
    );
    expect(find.text('medium'), findsNothing);
    expect(find.byTooltip('Reanalyze'), findsNothing);
  });

  testWidgets('analysis summary remains usable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.pro, marketCondition: 'trending_up'),
      onNewAnalysis: () {},
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('XAU/USD'), findsWidgets);
    await _reveal(tester, find.text('Uptrend'), find.byType(Scrollable).first);
    expect(find.text('Uptrend'), findsOneWidget);
  });

  testWidgets('the price chart is available without expanding anything', (
    tester,
  ) async {
    await _pumpDetail(tester, _analysis(AnalysisModeEnum.beginner));

    await tester.scrollUntilVisible(
      find.text('Price Chart'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // No disclosure tap is needed to reach the chart.
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

  testWidgets(
    'chart, levels, fundamental, and technical follow reading order',
    (tester) async {
      await _pumpDetail(
        tester,
        _analysis(
          AnalysisModeEnum.beginner,
          tradePlan: _tradePlan(),
          failureConditions: 'Invalidation details',
          mainScenario: 'Primary scenario details',
        ),
      );
      final scrollable = find.byType(Scrollable).first;

      await _reveal(tester, find.text('Price Chart'), scrollable);
      final chartOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(tester, find.text('Suggested Levels'), scrollable);
      final levelsOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(
        tester,
        find.byKey(const ValueKey('analysis-market-evidence')),
        scrollable,
      );
      final fundamentalOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(
        tester,
        find.byKey(const ValueKey('analysis-technical-details')),
        scrollable,
      );
      final technicalOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      await _reveal(tester, find.text('Notes & journal'), scrollable);
      final toolsOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;

      expect(levelsOffset, greaterThan(chartOffset));
      expect(fundamentalOffset, greaterThan(levelsOffset));
      expect(technicalOffset, greaterThan(fundamentalOffset));
      expect(toolsOffset, greaterThan(technicalOffset));
    },
  );

  testWidgets('invalidation, opportunity, and risk are collapsed by default', (
    tester,
  ) async {
    final analysis = _analysis(
      AnalysisModeEnum.beginner,
      failureConditions: 'Invalidation details',
      opportunity: 'Opportunity details',
      risk: 'Risk details',
    );
    await _pumpDetail(tester, analysis);

    for (final entry in const [
      (ValueKey('analysis-invalidation'), 'Invalidation details'),
      (ValueKey('analysis-opportunity'), 'Opportunity details'),
      (ValueKey('analysis-risk'), 'Risk details'),
    ]) {
      final card = find.byKey(entry.$1);
      await _reveal(tester, card, find.byType(Scrollable).first);
      expect(find.text(entry.$2), findsNothing);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
    }
  });

  testWidgets('execution insight matches the three web scenarios', (
    tester,
  ) async {
    await _pumpDetail(tester, _analysis(AnalysisModeEnum.beginner));

    final insight = find.byKey(const ValueKey('analysis-execution-insight'));
    await tester.scrollUntilVisible(
      insight,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('If Scenario A continues'), findsNothing);

    await tester.tap(insight);
    await tester.pumpAndSettle();

    expect(find.text('If Scenario A continues'), findsOneWidget);
    expect(find.textContaining('nearest resistance area'), findsOneWidget);
    expect(find.text('If Scenario B plays out'), findsOneWidget);
    expect(find.text('If waiting is the better choice'), findsOneWidget);
  });

  testWidgets('analysis scenarios share one collapsed card', (tester) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.beginner,
        mainScenario: 'Primary scenario details',
        alternativeScenario: 'Alternative scenario details',
      ),
    );

    final scenarios = find.byKey(const ValueKey('analysis-scenarios'));
    await _reveal(tester, scenarios, find.byType(Scrollable).first);
    expect(find.text('Primary scenario details'), findsNothing);

    await tester.tap(scenarios);
    await tester.pumpAndSettle();

    expect(find.text('Primary scenario details'), findsOneWidget);
    expect(find.text('Alternative scenario details'), findsOneWidget);
    expect(find.text('Scenario C — Wait / No Position'), findsOneWidget);
  });

  testWidgets('pro analysis factors share one collapsed card', (tester) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.pro,
        technicalDrivers: 'Technical factor details',
        fundamentalDrivers: 'Fundamental factor details',
        marketContext: 'Market context details',
      ),
    );

    expect(
      find.byKey(const ValueKey('analysis-evidence-summary')),
      findsNothing,
    );

    final details = find.byKey(const ValueKey('analysis-pro-details'));
    final scrollable = find.byType(Scrollable).first;
    await _reveal(
      tester,
      find.byKey(const ValueKey('analysis-scenarios')),
      scrollable,
    );
    final scenariosOffset = tester
        .state<ScrollableState>(scrollable)
        .position
        .pixels;
    await _reveal(tester, details, scrollable);
    final detailsOffset = tester
        .state<ScrollableState>(scrollable)
        .position
        .pixels;
    expect(detailsOffset, greaterThan(scenariosOffset));
    expect(find.text('Technical factor details'), findsNothing);

    await tester.tap(details);
    await tester.pumpAndSettle();

    expect(find.text('Technical factor details'), findsOneWidget);
    expect(find.text('Fundamental factor details'), findsOneWidget);
    expect(find.text('Market context details'), findsOneWidget);
  });

  testWidgets('confidence reason is collapsed by default', (tester) async {
    await _pumpDetail(
      tester,
      _analysis(
        AnalysisModeEnum.beginner,
        whyReason: 'Confidence reason details',
      ),
    );

    final reason = find.byKey(const ValueKey('analysis-confidence-reason'));
    final header = find.byKey(const ValueKey('analysis-result-header'));
    expect(find.descendant(of: header, matching: reason), findsOneWidget);
    expect(find.text('Confidence reason details'), findsNothing);
    expect(find.text('Cited sources'), findsNothing);

    await tester.tap(reason);
    await tester.pumpAndSettle();

    expect(find.text('Confidence reason details'), findsOneWidget);
  });

  testWidgets('active alert levels are collapsed until requested', (
    tester,
  ) async {
    final alerts = AlertStatus(
      (builder) => builder
        ..enabled = true
        ..armedCount = 1
        ..levels.add(
          AlertLevelRow(
            (row) => row
              ..level = AlertLevelRowLevelEnum.entry
              ..side = AlertLevelRowSideEnum.buy
              ..price = '4410'
              ..direction = AlertLevelRowDirectionEnum.above,
          ),
        ),
    );
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.pro, tradePlan: _tradePlan()),
      alertStatus: alerts,
    );

    final levels = find.byKey(const ValueKey('analysis-alert-levels'));
    await _reveal(tester, levels, find.byType(Scrollable).first);
    expect(find.text('@ 4410'), findsNothing);

    await tester.tap(levels);
    await tester.pumpAndSettle();

    expect(find.text('@ 4410'), findsOneWidget);
    expect(find.text('Monitored'), findsOneWidget);
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

  testWidgets('timeframe switch requires explicit analysis confirmation', (
    tester,
  ) async {
    Analysis? created;
    final provider = await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner),
      onAnalysisCreated: (value) => created = value,
    );

    await tester.tap(find.byKey(const Key('timeframe-option-4h')));
    await tester.tap(find.byKey(const Key('timeframe-option-1D')));
    await tester.pump();
    expect(provider.requestedTimeframes, isEmpty);
    expect(find.text('Analyze this timeframe'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('analyze-selected-timeframe-button')),
    );
    await tester.pumpAndSettle();

    expect(provider.requestedTimeframes, [CreateAnalysisBodyTimeframeEnum.n1d]);
    expect(created?.timeframe, '1D');
  });

  testWidgets('timeframe buttons keep a single width across selection', (
    tester,
  ) async {
    await _pumpDetail(tester, _analysis(AnalysisModeEnum.beginner));

    double widthOf(String timeframe) =>
        tester.getSize(find.byKey(Key('timeframe-option-$timeframe'))).width;

    const timeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1D', '1W'];
    final widths = {for (final tf in timeframes) widthOf(tf)};

    // Kisi berkolom tetap: label panjang atau pendek tidak mengubah lebar,
    // jadi kedua baris tetap rata.
    expect(widths, hasLength(1));

    // '1h' adalah timeframe analisis ini. Memilih yang lain tidak boleh
    // menggeser tata letak — itulah sebabnya centang dihilangkan.
    await tester.tap(find.byKey(const Key('timeframe-option-15m')));
    await tester.pump();

    for (final tf in timeframes) {
      expect(widthOf(tf), widths.single);
    }
  });

  testWidgets('new analysis button opens the analysis flow', (tester) async {
    var opened = false;
    await _pumpDetail(
      tester,
      _analysis(AnalysisModeEnum.beginner),
      onNewAnalysis: () => opened = true,
    );

    await tester.tap(find.byKey(const Key('detail-new-analysis-button')));

    expect(opened, isTrue);
  });
}

Future<void> _reveal(
  WidgetTester tester,
  Finder target,
  Finder scrollable,
) async {
  for (var attempt = 0; attempt < 20 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<_FakeAnalysisProvider> _pumpDetail(
  WidgetTester tester,
  Analysis analysis, {
  Map<String, Object?>? journal,
  ValueChanged<Analysis>? onAnalysisCreated,
  VoidCallback? onNewAnalysis,
  AlertStatus? alertStatus,
  TextScaler? textScaler,
}) async {
  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  auth.client.dio.httpClientAdapter = _JournalAdapter(journal);
  final analysisProvider = _FakeAnalysisProvider(
    auth,
    analysis,
    alertStatus: alertStatus,
  );
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
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: AnalysisDetailScreen(
              key: ValueKey(analysis.id),
              analysisId: analysis.id,
              preloaded: analysis,
              onAnalysisCreated: onAnalysisCreated,
              onNewAnalysis: onNewAnalysis,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return analysisProvider;
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

Analysis _analysis(
  AnalysisModeEnum mode, {
  int? id,
  String timeframe = '1h',
  String? failureConditions,
  String? opportunity,
  String? risk,
  String? mainScenario,
  String? alternativeScenario,
  String? technicalDrivers,
  String? fundamentalDrivers,
  String? marketContext,
  String? whyReason,
  String? marketCondition,
  TradePlan? tradePlan,
}) => $Analysis(
  (builder) => builder
    ..id = id ?? (mode == AnalysisModeEnum.pro ? 2 : 1)
    ..userId = 1
    ..instrument = 'XAU/USD'
    ..timeframe = timeframe
    ..mode = mode
    ..tradingBias = 'bearish'
    ..riskLevel = 'medium'
    ..failureConditions = failureConditions
    ..opportunity = opportunity
    ..risk = risk
    ..mainScenario = mainScenario
    ..alternativeScenario = alternativeScenario
    ..keyDriversTechnical = technicalDrivers
    ..keyDriversFundamental = fundamentalDrivers
    ..marketContext = marketContext
    ..whyReason = whyReason
    ..marketCondition = marketCondition
    ..tradePlan = tradePlan?.toBuilder()
    ..validUntil = DateTime.utc(2030)
    ..createdAt = DateTime.utc(2026),
);

TradePlan _tradePlan() => TradePlan(
  (plan) => plan
    ..preferredSide = TradePlanPreferredSideEnum.buy
    ..buy.replace(_tradeSide('4400'))
    ..sell.replace(_tradeSide('4420')),
);

TradeSide _tradeSide(String entry) => TradeSide(
  (side) => side
    ..entryZone = entry
    ..stopLoss = '4380'
    ..takeProfit1 = '4440'
    ..takeProfit2 = '4460'
    ..riskRewardRatio = '1:2'
    ..rationale = 'Test',
);

class _FakeAnalysisProvider extends AnalysisProvider {
  _FakeAnalysisProvider(super.auth, this.analysis, {this.alertStatus});

  final Analysis analysis;
  final AlertStatus? alertStatus;
  final List<CreateAnalysisBodyTimeframeEnum> requestedTimeframes = [];

  @override
  Future<Analysis?> getAnalysis(int id, {bool silent = false}) async =>
      analysis;

  @override
  Future<AlertStatus?> getAnalysisAlerts(int id) async => alertStatus;

  @override
  Future<Analysis?> createAnalysis({
    required String instrument,
    required CreateAnalysisBodyTimeframeEnum timeframe,
    required CreateAnalysisBodyModeEnum mode,
    String? userInputContext,
  }) async {
    requestedTimeframes.add(timeframe);
    final value = switch (timeframe) {
      CreateAnalysisBodyTimeframeEnum.n1m => '1m',
      CreateAnalysisBodyTimeframeEnum.n5m => '5m',
      CreateAnalysisBodyTimeframeEnum.n15m => '15m',
      CreateAnalysisBodyTimeframeEnum.n30m => '30m',
      CreateAnalysisBodyTimeframeEnum.n4h => '4h',
      CreateAnalysisBodyTimeframeEnum.n1d => '1D',
      CreateAnalysisBodyTimeframeEnum.n1w => '1W',
      _ => '1h',
    };
    return _analysis(
      mode == CreateAnalysisBodyModeEnum.pro
          ? AnalysisModeEnum.pro
          : AnalysisModeEnum.beginner,
      id: analysis.id + 1,
      timeframe: value,
    );
  }
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
