import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/models/history_filters.dart';
import 'package:tradepilotapp/models/history_sort.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  test(
    'sorting and client filters never mutate dashboard base history',
    () async {
      final auth = await _authenticatedUser(1);
      final provider = AnalysisProvider(auth);
      addTearDown(provider.dispose);
      final newest = _analysis(2, confidence: 60, day: 23);
      final oldest = _analysis(1, confidence: 90, day: 22);
      provider.history = [newest, oldest];
      provider.historyTotal = 2;

      await provider.applyHistoryFilters(
        const HistoryFilters(
          minConfidence: 70,
          sort: HistorySort.confidenceHighest,
        ),
      );

      expect(provider.visibleHistory.map((item) => item.id), [1]);
      expect(provider.history.map((item) => item.id), [2, 1]);

      await provider.applyHistoryFilters(
        const HistoryFilters(sort: HistorySort.oldest),
      );
      expect(provider.visibleHistory.map((item) => item.id), [1, 2]);
      expect(provider.history.map((item) => item.id), [2, 1]);
    },
  );

  test(
    'preferences exclude query and remain isolated per authenticated user',
    () async {
      final auth = await _authenticatedUser(1);
      final provider = AnalysisProvider(auth);
      addTearDown(provider.dispose);

      await provider.applyHistoryFilters(
        const HistoryFilters(
          query: 'private context',
          outcome: HistoryOutcomeFilter.success,
          sort: HistorySort.oldest,
        ),
      );

      final preferences = await SharedPreferences.getInstance();
      final userOne =
          jsonDecode(preferences.getString('history_preferences_v1_1')!)
              as Map<String, dynamic>;
      expect(userOne.containsKey('query'), isFalse);
      expect(userOne['outcome'], 'success');

      auth
        ..status = AuthStatus.authenticated
        ..user = _user(2)
        ..notifyListeners();

      expect(provider.historyFilters, isA<HistoryFilters>());
      expect(provider.historyFilters.isActive, isFalse);
      expect(provider.historyFilters.sort, HistorySort.newest);
      expect(preferences.getString('history_preferences_v1_2'), isNull);

      await provider.applyHistoryFilters(
        const HistoryFilters(mode: HistoryModeFilter.pro),
      );
      expect(preferences.getString('history_preferences_v1_2'), isNotNull);
      expect(userOne['mode'], 'all');
    },
  );

  test('rapid server-filter changes reject the stale response', () async {
    final auth = await _authenticatedUser(1);
    final adapter = _DeferredHistoryAdapter();
    auth.client.dio.httpClientAdapter = adapter;
    final provider = AnalysisProvider(auth);
    addTearDown(provider.dispose);
    await pumpEventQueue();

    final oldRequest = provider.applyHistoryFilters(
      const HistoryFilters(query: 'old'),
    );
    await pumpEventQueue();
    expect(
      adapter.hasRequest('old'),
      isTrue,
      reason:
          'auth=${auth.status}, loading=${provider.isLoadingFilteredHistory}, '
          'query=${provider.historyFilters.query}, '
          'error=${provider.filteredHistoryError}',
    );

    final newRequest = provider.applyHistoryFilters(
      const HistoryFilters(query: 'new'),
    );
    await pumpEventQueue();
    expect(adapter.hasRequest('new'), isTrue);
    adapter.complete('new', [_analysis(2, confidence: 80, day: 23)]);
    await newRequest;

    adapter.complete('old', [_analysis(1, confidence: 70, day: 22)]);
    await oldRequest;

    expect(provider.filteredHistory.map((item) => item.id), [2]);
    expect(provider.historyFilters.query, 'new');
  });

  test(
    'restores allowed preferences and ignores corrupted stored data',
    () async {
      SharedPreferences.setMockInitialValues({
        'history_preferences_v1_1': jsonEncode(
          const HistoryFilters(
            outcome: HistoryOutcomeFilter.pending,
            sort: HistorySort.oldest,
          ).toPreferencesJson(),
        ),
        'history_preferences_v1_2': '{broken-json',
      });
      final auth = await _authenticatedUser(1);
      final provider = AnalysisProvider(auth);
      addTearDown(provider.dispose);
      await pumpEventQueue();

      expect(provider.historyFilters.outcome, HistoryOutcomeFilter.pending);
      expect(provider.historyFilters.sort, HistorySort.oldest);

      auth
        ..user = _user(2)
        ..notifyListeners();
      await pumpEventQueue();

      expect(provider.historyFilters.isActive, isFalse);
      expect(provider.historyFilters.sort, HistorySort.newest);
    },
  );
}

Future<AuthProvider> _authenticatedUser(int id) async {
  final auth = AuthProvider();
  await pumpEventQueue();
  return auth
    ..status = AuthStatus.authenticated
    ..user = _user(id);
}

User _user(int id) => User(
  (builder) => builder
    ..id = id
    ..email = 'user$id@example.com'
    ..displayName = 'User $id'
    ..role = UserRoleEnum.user
    ..selectedMode = UserSelectedModeEnum.beginner
    ..themePreference = UserThemePreferenceEnum.dark
    ..onboardingCompleted = true,
);

Analysis _analysis(int id, {required int confidence, required int day}) {
  return Analysis(
    (builder) => builder
      ..id = id
      ..userId = 1
      ..instrument = 'XAU/USD'
      ..timeframe = '1h'
      ..mode = AnalysisModeEnum.beginner
      ..validUntil = DateTime.utc(2026, 8, 24)
      ..createdAt = DateTime.utc(2026, 8, day)
      ..confidenceMin = confidence
      ..confidenceMax = confidence,
  );
}

class _DeferredHistoryAdapter implements HttpClientAdapter {
  final Map<String, Completer<ResponseBody>> _requests = {};

  bool hasRequest(String query) => _requests.containsKey(query);

  void complete(String query, List<Analysis> analyses) {
    _requests[query]!.complete(
      ResponseBody.fromString(
        jsonEncode({
          'analyses': analyses
              .map(
                (analysis) => {
                  'id': analysis.id,
                  'userId': analysis.userId,
                  'instrument': analysis.instrument,
                  'timeframe': analysis.timeframe,
                  'mode': analysis.mode.name,
                  'validUntil': analysis.validUntil.toIso8601String(),
                  'confidenceMin': analysis.confidenceMin,
                  'confidenceMax': analysis.confidenceMax,
                  'createdAt': analysis.createdAt.toIso8601String(),
                },
              )
              .toList(),
          'total': analyses.length,
          'page': 1,
          'limit': 20,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final query = options.queryParameters['q'].toString();
    final response = Completer<ResponseBody>();
    _requests[query] = response;

    if (cancelFuture == null) {
      return response.future;
    }

    return Future.any([
      response.future,
      cancelFuture.then<ResponseBody>(
        (_) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        ),
      ),
    ]);
  }

  @override
  void close({bool force = false}) {}
}
