import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/preferences/mental_checklist_controller.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/credit_provider.dart';
import 'package:tradepilotapp/providers/market_provider.dart';
import 'package:tradepilotapp/providers/progression_provider.dart';
import 'package:tradepilotapp/providers/watchlist_provider.dart';
import 'package:tradepilotapp/repositories/market_repository.dart';
import 'package:tradepilotapp/repositories/topup_repository.dart';
import 'package:tradepilotapp/repositories/watchlist_repository.dart';
import 'package:tradepilotapp/screens/analysis/analysis_detail_screen.dart';
import 'package:tradepilotapp/screens/home/tabs/analyze_tab.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  testWidgets('analysis header stays on one row on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpAnalyzeTab(tester);

    final title = find.text('New Analysis');
    final progression = find.byKey(const Key('analyze-progression-chip'));
    final quota = find.byKey(const Key('analyze-quota-chip'));
    final session = find.byKey(const Key('analyze-market-session'));

    expect(tester.getCenter(title).dy, tester.getCenter(progression).dy);
    expect(tester.getCenter(progression).dy, tester.getCenter(quota).dy);
    expect(
      tester.getBottomLeft(progression).dy,
      lessThan(tester.getTopLeft(session).dy),
    );
    expect(session, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('market session pill opens the contextual popover', (
    tester,
  ) async {
    await _pumpAnalyzeTab(tester);

    await tester.tap(find.byKey(const Key('analyze-market-session')));
    await tester.pumpAndSettle();

    expect(find.text('About market sessions'), findsOneWidget);
    expect(find.text('Typical session hours'), findsOneWidget);
    expect(find.text('05:00–14:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('other instrument opens the picker and applies a shortcut', (
    tester,
  ) async {
    await _pumpAnalyzeTab(tester);

    await tester.tap(find.byKey(const Key('custom-instrument-field')));
    await tester.pumpAndSettle();

    expect(find.text('Other instrument…'), findsWidgets);
    expect(
      find.byKey(const Key('other-instrument-search-field')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('other-instrument-EUR/USD')));
    await tester.pumpAndSettle();

    expect(find.text('EUR/USD'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown instrument becomes a request that is not available', (
    tester,
  ) async {
    await _pumpAnalyzeTab(tester);

    await tester.tap(find.byKey(const Key('custom-instrument-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('other-instrument-search-field')),
      'btc/usdh',
    );
    await tester.pumpAndSettle();

    expect(find.text('Request BTC/USDH'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('other-instrument-EUR/USD')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('other-instrument-request-button')));
    await tester.pumpAndSettle();

    expect(find.text('BTC/USDH is not available'), findsOneWidget);

    await tester.tap(find.byKey(const Key('instrument-unavailable-close')));
    await tester.pumpAndSettle();

    expect(find.text('BTC/USDH is not available'), findsNothing);
    expect(
      find.byKey(const Key('other-instrument-search-field')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the analysis form remains visible above the result', (
    tester,
  ) async {
    final provider = await _pumpAnalyzeTab(tester);

    expect(
      find.byKey(const ValueKey('analyze-instrument-XAU/USD')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('timeframe-1h')), findsNothing);
    expect(find.byKey(const Key('set-price-alert-button')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Timeframe:'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1h'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('TradePilot is a decision-support tool'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('TradePilot is a decision-support tool'),
      findsOneWidget,
    );
    await _scrollToTop(tester);

    await _runAnalysis(tester);

    expect(provider.requestedModes, [CreateAnalysisBodyModeEnum.pro]);
    expect(find.byType(AnalysisDetailScreen), findsOneWidget);
    expect(find.byKey(const Key('submit-analysis-button')), findsNothing);

    await _scrollToTop(tester);
    expect(find.text('Select Instrument'), findsOneWidget);
    expect(
      find.byKey(const Key('change-analysis-selection-button')),
      findsNothing,
    );
    expect(find.byKey(const Key('new-analysis-button')), findsOneWidget);
  });

  testWidgets('picking another instrument waits for explicit submit', (
    tester,
  ) async {
    final provider = await _pumpAnalyzeTab(tester);

    await _runAnalysis(tester);
    expect(provider.requested, ['XAU/USD']);

    await _scrollToTop(tester);
    final newAnalysis = find.byKey(const Key('new-analysis-button'));
    await tester.ensureVisible(newAnalysis);
    await tester.tap(newAnalysis);
    await tester.pumpAndSettle();
    await tester.tap(find.text('BRENT'));
    await tester.pumpAndSettle();
    expect(provider.requested, ['XAU/USD']);

    await _runAnalysis(tester);
    expect(provider.requested, ['XAU/USD', 'BRENT']);
  });

  testWidgets('new analysis button clears the result and keeps the form', (
    tester,
  ) async {
    var shellNotified = 0;
    await _pumpAnalyzeTab(tester, onNewAnalysis: () => shellNotified++);

    await _runAnalysis(tester);
    expect(find.byType(AnalysisDetailScreen), findsOneWidget);

    await _scrollToTop(tester);
    await tester.tap(find.byKey(const Key('new-analysis-button')));
    await tester.pumpAndSettle();

    expect(find.byType(AnalysisDetailScreen), findsNothing);
    expect(find.text('Select Instrument'), findsOneWidget);
    expect(shellNotified, 1);

    // Tombol submit kembali muncul karena tidak ada hasil di halaman.
    await tester.scrollUntilVisible(
      find.byKey(const Key('submit-analysis-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('submit-analysis-button')), findsOneWidget);
  });

  testWidgets(
    'concurrent analysis uses the dialog without a stale error banner',
    (tester) async {
      await _pumpAnalyzeTab(tester, concurrentFailure: true);

      await _runAnalysis(tester);
      expect(find.text('Analysis still in progress'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Previous analysis raw backend error'), findsNothing);
    },
  );
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, 5000));
  await tester.pumpAndSettle();
}

Future<void> _runAnalysis(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Analyze'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Analyze'));
  await tester.pumpAndSettle();
}

Future<_FakeAnalysisProvider> _pumpAnalyzeTab(
  WidgetTester tester, {
  VoidCallback? onNewAnalysis,
  bool concurrentFailure = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  auth.client.dio.httpClientAdapter = _OfflineAdapter();

  final analysisProvider = _FakeAnalysisProvider(
    auth,
    concurrentFailure: concurrentFailure,
  );
  final marketProvider = _FakeMarketProvider(auth);
  final watchlistProvider = WatchlistProvider(
    auth,
    WatchlistRepository(auth.client),
  );
  final progressionProvider = ProgressionProvider(auth);
  progressionProvider.summary = ProgressionSummary(
    (builder) => builder
      ..totalXp = 0
      ..level = 1
      ..masteryLevel = 0
      ..rank = 'seedling'
      ..currentLevelXp = 0
      ..nextLevelXp = 100
      ..currentStreak = 0
      ..longestStreak = 0,
  );
  analysisProvider.quota = AnalysisQuota(
    (builder) => builder
      ..unlimited = false
      ..daily.limit = 20
      ..daily.used = 7
      ..daily.remaining = 13
      ..credits.balance = 0,
  );
  final creditProvider = CreditProvider(auth, TopupRepository(auth.client));
  final checklist = MentalChecklistController(preferences);

  addTearDown(analysisProvider.dispose);
  addTearDown(marketProvider.dispose);
  addTearDown(watchlistProvider.dispose);
  addTearDown(progressionProvider.dispose);
  addTearDown(creditProvider.dispose);
  addTearDown(checklist.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AnalysisProvider>.value(value: analysisProvider),
        ChangeNotifierProvider<MarketProvider>.value(value: marketProvider),
        ChangeNotifierProvider<WatchlistProvider>.value(
          value: watchlistProvider,
        ),
        ChangeNotifierProvider<ProgressionProvider>.value(
          value: progressionProvider,
        ),
        ChangeNotifierProvider<CreditProvider>.value(value: creditProvider),
        ChangeNotifierProvider<MentalChecklistController>.value(
          value: checklist,
        ),
      ],
      child: localizedTestApp(home: AnalyzeTab(onNewAnalysis: onNewAnalysis)),
    ),
  );
  await tester.pumpAndSettle();
  return analysisProvider;
}

/// Semua panggilan jaringan gagal supaya tab jatuh ke state offline yang stabil.
class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('', 404);

  @override
  void close({bool force = false}) {}
}

class _FakeAnalysisProvider extends AnalysisProvider {
  _FakeAnalysisProvider(super.auth, {this.concurrentFailure = false});

  final bool concurrentFailure;

  final List<String> requested = [];
  final List<CreateAnalysisBodyModeEnum> requestedModes = [];

  @override
  Future<Analysis?> createAnalysis({
    required String instrument,
    required CreateAnalysisBodyTimeframeEnum timeframe,
    required CreateAnalysisBodyModeEnum mode,
    String? userInputContext,
  }) async {
    requested.add(instrument);
    requestedModes.add(mode);
    if (concurrentFailure) {
      quotaLimit = const AnalysisQuotaLimit(
        scope: 'concurrent',
        retryAfter: Duration(seconds: 5),
      );
      errorMessage = 'Previous analysis raw backend error';
      notifyListeners();
      return null;
    }
    return _analysis(instrument);
  }

  @override
  Future<Analysis?> getAnalysis(int id, {bool silent = false}) async =>
      _analysis('XAU/USD');

  @override
  Future<void> loadQuota({bool ensureFresh = false}) async {}
}

Analysis _analysis(String instrument) => $Analysis(
  (builder) => builder
    ..id = 1
    ..userId = 1
    ..instrument = instrument
    ..timeframe = '1h'
    ..mode = AnalysisModeEnum.beginner
    ..tradingBias = 'bearish'
    ..riskLevel = 'medium'
    ..validUntil = DateTime.utc(2030)
    ..createdAt = DateTime.utc(2026),
);

class _FakeMarketProvider extends MarketProvider {
  _FakeMarketProvider(AuthProvider auth) : super(auth, MarketRepository(Dio()));

  @override
  Future<void> loadQuotes({bool force = false, bool silent = false}) async {}

  @override
  Future<void> loadSelectedMarketData({bool force = false}) async {}

  @override
  Future<List<MarketCandle>> getCandlesFor(
    String instrument,
    String timeframe, {
    bool force = false,
  }) async => const [];
}
