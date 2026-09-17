import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';

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

  for (final testCase in [
    ('hour', 5, 5, 3600),
    ('day', 20, 20, 86400),
    ('concurrent', null, null, 5),
  ]) {
    test('captures ${testCase.$1} quota without retrying', () async {
      final adapter = _AnalysisAdapter(
        scope: testCase.$1,
        limit: testCase.$2,
        used: testCase.$3,
        retryAfter: testCase.$4,
      );
      final provider = await _provider(adapter);
      addTearDown(provider.dispose);

      final result = await provider.createAnalysis(
        instrument: 'XAU/USD',
        timeframe: CreateAnalysisBodyTimeframeEnum.n1h,
        mode: CreateAnalysisBodyModeEnum.beginner,
      );

      expect(result, isNull);
      expect(provider.quotaLimit?.scope, testCase.$1);
      expect(provider.quotaLimit?.limit, testCase.$2);
      expect(provider.quotaLimit?.used, testCase.$3);
      expect(provider.quotaLimit?.retryAfter?.inSeconds, testCase.$4);
      expect(adapter.analysisRequests, 1);
    });
  }

  test(
    'keeps a successful credit-backed analysis as a normal result',
    () async {
      final adapter = _AnalysisAdapter.success();
      final provider = await _provider(adapter);
      addTearDown(provider.dispose);

      final result = await provider.createAnalysis(
        instrument: 'XAU/USD',
        timeframe: CreateAnalysisBodyTimeframeEnum.n1h,
        mode: CreateAnalysisBodyModeEnum.beginner,
      );

      expect(result?.id, 42);
      expect(provider.lastAnalysisConsumedCredit, isTrue);
      expect(provider.lastAnalysisCreditBalance, 9);
      expect(provider.quotaLimit, isNull);
      expect(adapter.analysisRequests, 1);
      await pumpEventQueue(times: 20);
    },
  );

  test(
    'queues a fresh quota read when analysis finishes during a load',
    () async {
      final adapter = _QuotaRefreshAdapter();
      final provider = await _provider(adapter);
      addTearDown(provider.dispose);

      final initialLoad = provider.loadQuota();
      await pumpEventQueue();
      expect(adapter.quotaRequests, 1);

      final result = await provider.createAnalysis(
        instrument: 'XAU/USD',
        timeframe: CreateAnalysisBodyTimeframeEnum.n1h,
        mode: CreateAnalysisBodyModeEnum.beginner,
      );
      expect(result?.id, 42);

      adapter.completeInitialQuota();
      await initialLoad;
      await pumpEventQueue(times: 20);

      expect(adapter.quotaRequests, 2);
      expect(provider.quota?.hourly.remaining, 4);
      expect(provider.quota?.daily.remaining, 9);
    },
  );

  test('reports missing quota and clears the error after retry', () async {
    final adapter = _QuotaFailureAdapter();
    final provider = await _provider(adapter);
    addTearDown(provider.dispose);

    await provider.loadQuota();
    expect(provider.quota, isNull);
    expect(provider.quotaLoadFailed, isTrue);

    await provider.loadQuota(ensureFresh: true);
    expect(provider.quota, isNull);
    expect(provider.quotaLoadFailed, isTrue);

    await provider.loadQuota(ensureFresh: true);
    expect(provider.quota?.credits.balance, 3);
    expect(provider.quotaLoadFailed, isFalse);
  });
}

Future<AnalysisProvider> _provider(HttpClientAdapter adapter) async {
  final auth = AuthProvider();
  await pumpEventQueue();
  auth
    ..status = AuthStatus.authenticated
    ..user = User(
      (builder) => builder
        ..id = 1
        ..email = 'user@example.com'
        ..displayName = 'User'
        ..role = UserRoleEnum.user
        ..selectedMode = UserSelectedModeEnum.beginner
        ..themePreference = UserThemePreferenceEnum.dark
        ..createdAt = DateTime.utc(2026)
        ..onboardingCompleted = true
        ..hasPassword = true,
    );
  auth.client.dio.httpClientAdapter = adapter;
  return AnalysisProvider(auth);
}

class _AnalysisAdapter implements HttpClientAdapter {
  _AnalysisAdapter({
    required this.scope,
    required this.limit,
    required this.used,
    required this.retryAfter,
  }) : succeeds = false;

  _AnalysisAdapter.success()
    : scope = '',
      limit = null,
      used = null,
      retryAfter = 0,
      succeeds = true;

  final String scope;
  final int? limit;
  final int? used;
  final int retryAfter;
  final bool succeeds;
  int analysisRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/analyses') {
      return _json({'message': 'ok'}, 200);
    }

    analysisRequests++;

    if (succeeds) {
      return _json({
        'id': 42,
        'userId': 1,
        'instrument': 'XAU/USD',
        'timeframe': '1h',
        'mode': 'beginner',
        'validUntil': '2026-09-08T12:00:00.000Z',
        'createdAt': '2026-09-08T10:00:00.000Z',
        'creditConsumed': true,
        'creditBalance': 9,
      }, 201);
    }

    return _json(
      {
        'error': 'Quota reached',
        'quota': {
          'scope': scope,
          if (limit != null) 'limit': limit,
          if (used != null) 'used': used,
        },
      },
      429,
      headers: {
        'retry-after': ['$retryAfter'],
      },
    );
  }

  ResponseBody _json(
    Object body,
    int status, {
    Map<String, List<String>>? headers,
  }) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...?headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _QuotaRefreshAdapter implements HttpClientAdapter {
  final Completer<ResponseBody> _initialQuota = Completer<ResponseBody>();
  int quotaRequests = 0;

  void completeInitialQuota() {
    _initialQuota.complete(_quotaResponse(hourly: 5, daily: 10));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/analyses/quota') {
      quotaRequests++;
      return quotaRequests == 1
          ? _initialQuota.future
          : _quotaResponse(hourly: 4, daily: 9);
    }

    if (options.path == '/analyses' && options.method == 'POST') {
      return _json({
        'id': 42,
        'userId': 1,
        'instrument': 'XAU/USD',
        'timeframe': '1h',
        'mode': 'beginner',
        'validUntil': '2026-09-08T12:00:00.000Z',
        'createdAt': '2026-09-08T10:00:00.000Z',
        'creditConsumed': false,
      }, 201);
    }

    return _json({'message': 'ok'}, 200);
  }

  ResponseBody _quotaResponse({required int hourly, required int daily}) =>
      _json({
        'unlimited': false,
        'hourly': {'limit': 5, 'used': 5 - hourly, 'remaining': hourly},
        'daily': {'limit': 10, 'used': 10 - daily, 'remaining': daily},
        'credits': {'balance': 3},
      }, 200);

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _QuotaFailureAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (requests == 1) return _json(null, 200);
    if (requests == 2) return _json({'error': 'Unavailable'}, 500);
    return _json({
      'unlimited': false,
      'hourly': {'limit': 5, 'used': 1, 'remaining': 4},
      'daily': {'limit': 10, 'used': 2, 'remaining': 8},
      'credits': {'balance': 3},
    }, 200);
  }

  ResponseBody _json(Object? body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
