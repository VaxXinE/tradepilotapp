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
  testWidgets('the instrument picker stays reachable after an analysis', (
    tester,
  ) async {
    await _pumpAnalyzeTab(tester);

    await _runAnalysis(tester);

    // Web menampilkan hasil DI BAWAH form, bukan menggantinya, sehingga
    // pemilihan simbol tidak pernah hilang.
    expect(find.byType(AnalysisDetailScreen), findsOneWidget);

    // Tombol submit disembunyikan; simbol lain langsung dianalisis ulang.
    expect(find.byKey(const Key('submit-analysis-button')), findsNothing);

    await _scrollToTop(tester);
    expect(find.text('Select Instrument'), findsOneWidget);
    expect(find.text('BRENT'), findsOneWidget);
    expect(find.byKey(const Key('new-analysis-button')), findsOneWidget);
  });

  testWidgets('picking another instrument re-analyzes immediately', (
    tester,
  ) async {
    final provider = await _pumpAnalyzeTab(tester);

    await _runAnalysis(tester);
    expect(provider.requested, ['XAU/USD']);

    await _scrollToTop(tester);
    await tester.tap(find.text('BRENT'));
    await tester.pumpAndSettle();

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
}

/// Hasil dirender di bawah form dan halaman ikut menggulir ke sana, jadi
/// bagian form perlu ditarik kembali ke layar sebelum di-assert.
Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('new-analysis-button')),
    -400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _runAnalysis(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Get AI Analysis'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get AI Analysis'));
  await tester.pumpAndSettle();
}

Future<_FakeAnalysisProvider> _pumpAnalyzeTab(
  WidgetTester tester, {
  VoidCallback? onNewAnalysis,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  final auth = AuthProvider();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  auth.client.dio.httpClientAdapter = _OfflineAdapter();

  final analysisProvider = _FakeAnalysisProvider(auth);
  final marketProvider = _FakeMarketProvider(auth);
  final watchlistProvider = WatchlistProvider(
    auth,
    WatchlistRepository(auth.client),
  );
  final progressionProvider = ProgressionProvider(auth);
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
  _FakeAnalysisProvider(super.auth);

  final List<String> requested = [];

  @override
  Future<Analysis?> createAnalysis({
    required String instrument,
    required CreateAnalysisBodyTimeframeEnum timeframe,
    required CreateAnalysisBodyModeEnum mode,
    String? userInputContext,
  }) async {
    requested.add(instrument);
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
