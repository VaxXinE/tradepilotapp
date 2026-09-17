import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

void main() {
  test('auth response accepts the user shape returned by production', () {
    final response = standardSerializers.deserializeWith(
      AuthResponse.serializer,
      {
        'token': 'session-token',
        'user': {
          'id': 1,
          'email': 'user@example.com',
          'displayName': 'User',
          'role': 'user',
          'selectedMode': 'beginner',
          'themePreference': 'dark',
          'onboardingCompleted': true,
          'hasPassword': true,
          'createdAt': '2026-01-01T00:00:00.000Z',
          'avatarUrl': null,
        },
      },
    );

    expect(response?.token, 'session-token');
    expect(response?.user.hasPassword, isTrue);
    expect(response?.user.createdAt, DateTime.utc(2026));
  });

  test('analysis accepts nullable fundamental feed values', () {
    final analysis = standardSerializers.deserializeWith(Analysis.serializer, {
      'id': 1,
      'userId': 1,
      'instrument': 'XAU/USD',
      'timeframe': '1h',
      'mode': 'pro',
      'validUntil': '2026-09-08T12:00:00.000Z',
      'createdAt': '2026-09-08T10:00:00.000Z',
      'fundamentalContext': {
        'newsItems': [
          {
            'id': 'news-1',
            'title': 'Market update',
            'summary': 'Summary',
            'source': 'Newsmaker.id',
            'url': null,
            'publishedAt': '2026-09-08T09:00:00.000Z',
          },
        ],
        'calendarEvents': [
          {
            'date': '2026-09-08',
            'time': null,
            'currency': 'USD',
            'event': 'Economic event',
            'impact': null,
            'actual': null,
            'forecast': null,
            'previous': null,
          },
        ],
      },
    });

    expect(analysis?.fundamentalContext?.newsItems.single.url, isNull);
    final event = analysis?.fundamentalContext?.calendarEvents.single;
    expect(event?.time, isNull);
    expect(event?.actual, isNull);
    expect(event?.forecast, isNull);
  });

  test('vendored client exposes new APIs and notification fields', () {
    final client = TradePilotClient(baseUrl: 'https://example.com/api');

    expect(client.nativePush, isA<NativePushApi>());
    expect(client.progression, isA<ProgressionApi>());
    expect(client.topups, isA<TopupsApi>());
    expect(client.tradingRules, isA<TradingRulesApi>());
    expect([
      client.admin.backfillProgression,
      client.admin.getProgressionAudit,
      client.analyses.getAnalysisHistorySummary,
      client.analyses.getGuardrails,
      client.analyses.getTimeframeRiskMap,
      client.analyses.recordGuardrailTelemetry,
      client.analyses.waitGuardrail,
      client.auth.deleteAccount,
      client.auth.loginWithAppleNative,
      client.auth.reauthenticateWithApple,
      client.nativePush.registerNativePushDevice,
      client.nativePush.sendNativePushTest,
      client.nativePush.unregisterNativePushDevice,
      client.progression.getProgressionCatalog,
      client.progression.getProgressionHistory,
      client.progression.getProgressionSummary,
      client.progression.recordProgressionActivity,
      client.progression.startProgressionEvidence,
      client.tradingRules.getStandardTradingRules,
    ], hasLength(19));

    final appleBody = AppleNativeLoginBody(
      (builder) => builder
        ..identityToken = 'identity-token'
        ..authorizationCode = 'authorization-code'
        ..nonce = 'raw-nonce',
    );
    final appleJson =
        standardSerializers.serializeWith(
              AppleNativeLoginBody.serializer,
              appleBody,
            )!
            as Map<String, Object?>;
    expect(appleJson['nonce'], 'raw-nonce');

    final prefs = PushPrefsUpdate(
      (builder) => builder
        ..quietHoursEnabled = true
        ..quietHoursStart = '22:00'
        ..quietHoursEnd = '07:00'
        ..notificationTimezone = 'Asia/Jakarta'
        ..nativePushEnabled = true
        ..progressionNotificationsEnabled = true,
    );
    final prefsJson =
        standardSerializers.serializeWith(PushPrefsUpdate.serializer, prefs)!
            as Map<String, Object?>;

    expect(prefsJson['notificationTimezone'], 'Asia/Jakarta');
    expect(prefsJson['nativePushEnabled'], isTrue);

    final notification = Notification(
      (builder) => builder
        ..id = 1
        ..title = 'Login baru'
        ..message = 'Perangkat baru terdeteksi'
        ..type = NotificationTypeEnum.warning
        ..category = 'security_alert'
        ..createdAt = DateTime.utc(2026, 9, 7),
    );
    final notificationJson =
        standardSerializers.serializeWith(
              Notification.serializer,
              notification,
            )!
            as Map<String, Object?>;

    expect(notificationJson['category'], 'security_alert');

    final gatedSentiment = standardSerializers
        .deserializeWith(JournalSentiment.serializer, {
          'instrument': 'XAU/USD',
          'windowDays': 7,
          'minSampleSize': 10,
          'minDistinctTraders': 4,
          'sampleSize': null,
          'distinctTraders': null,
          'gated': true,
          'buyPct': null,
          'sellPct': null,
        })!;
    expect(gatedSentiment.gated, isTrue);
    expect(gatedSentiment.sampleSize, isNull);
    expect(gatedSentiment.buyPct, isNull);

    final thinBanner = standardSerializers
        .deserializeWith(PerformanceBanner.serializer, {
          'severity': 'ok',
          'recentDays': 7,
          'recentSample': 2,
          'baselineSample': 4,
          'recentHitRate': null,
          'baselineHitRate': null,
          'delta': null,
        })!;
    expect(thinBanner.recentHitRate, isNull);
  });

  test('credit and top-up contracts match the latest API schema', () {
    final quota = standardSerializers.deserializeWith(
      AnalysisQuota.serializer,
      {
        'unlimited': false,
        'hourly': {'limit': 5, 'used': 5, 'remaining': 0},
        'daily': {'limit': 20, 'used': 20, 'remaining': 0},
        'credits': {'balance': 10},
      },
    );
    expect(quota?.credits.balance, 10);

    final created = standardSerializers
        .deserializeWith(CreateAnalysisResult.serializer, {
          'id': 1,
          'userId': 1,
          'instrument': 'XAU/USD',
          'timeframe': '1h',
          'mode': 'pro',
          'validUntil': '2026-09-08T12:00:00.000Z',
          'createdAt': '2026-09-08T10:00:00.000Z',
          'creditConsumed': true,
          'creditBalance': 9,
        });
    expect(created?.creditConsumed, isTrue);
    expect(created?.creditBalance, 9);

    final topup = standardSerializers.deserializeWith(TopupRequest.serializer, {
      'id': 7,
      'userId': 1,
      'amountRupiah': 50000,
      'creditsRequested': 10,
      'conversionRateSnapshot': 5000,
      'paymentReferenceNote': null,
      'proofObjectPath': null,
      'status': 'pending',
      'reviewedByUserId': null,
      'reviewedAt': null,
      'reviewNote': null,
      'creditsGranted': null,
      'createdAt': '2026-09-08T10:00:00.000Z',
    });
    expect(topup?.status, TopupRequestStatus.pending);
    expect(topup?.reviewNote, isNull);

    expect(
      () => CreateTopupRequestBody((builder) => builder.amountRupiah = 5000),
      throwsA(isA<BuiltValueNullFieldError>()),
    );
  });

  test('top-up endpoints round-trip through the generated TopupsApi', () async {
    final client = TradePilotClient(baseUrl: 'https://example.com/api');
    final adapter = _TopupsAdapter();
    client.dio.httpClientAdapter = adapter;

    final config = await client.topups.getTopupConfig();
    expect(config.data?.rupiahPerCredit, 5000);
    expect(config.data?.qrisImageUrl, 'https://cdn.example.com/qris.png');

    final balance = await client.topups.getCreditBalance();
    expect(balance.data?.balance, 10);

    final created = await client.topups.createTopupRequest(
      createTopupRequestBody: CreateTopupRequestBody(
        (builder) => builder
          ..amountRupiah = 50000
          ..paymentReferenceNote = 'BCA 1234'
          ..proofObjectPath = 'topups/proof-1.jpg',
      ),
    );
    expect(created.data?.status, TopupRequestStatus.pending);
    expect(created.data?.creditsRequested, 10);

    // History goes through the serializer registry, so a missing
    // ListBuilder<TopupRequest> factory would only fail here.
    final history = await client.topups.getMyTopupRequests(page: 1, limit: 20);
    expect(history.data?.total, 2);
    expect(history.data?.requests, hasLength(2));
    expect(history.data?.requests.first.reviewNote, isNull);
    expect(history.data?.requests.last.status, TopupRequestStatus.approved);
    expect(history.data?.requests.last.creditsGranted, 10);

    expect(
      adapter.requests.map((options) => '${options.method} ${options.path}'),
      [
        'GET /topups/config',
        'GET /topups/balance',
        'POST /topups',
        'GET /topups/mine',
      ],
    );

    final createBody = Map<String, dynamic>.from(
      adapter.requests[2].data as Map,
    );
    expect(createBody['amountRupiah'], 50000);
    expect(createBody['proofObjectPath'], 'topups/proof-1.jpg');

    final historyQuery = adapter.requests.last.queryParameters;
    expect(historyQuery['page'], 1);
    expect(historyQuery['limit'], 20);
  });

  test(
    'native push unregister stays on DELETE /native-push/unregister',
    () async {
      final client = TradePilotClient(baseUrl: 'https://example.com/api');
      final adapter = _TopupsAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.nativePush.unregisterNativePushDevice(
        nativePushUnregisterBody: NativePushUnregisterBody(
          (builder) => builder.token = 'device-token',
        ),
      );

      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/native-push/unregister');
    },
  );

  test('native push test uses POST /native-push/test', () async {
    final client = TradePilotClient(baseUrl: 'https://example.com/api');
    final adapter = _TopupsAdapter();
    client.dio.httpClientAdapter = adapter;

    final response = await client.nativePush.sendNativePushTest();

    expect(response.data?.targeted, 2);
    expect(response.data?.accepted, 1);
    expect(
      response.data?.failures.single,
      NativePushTestResultFailuresEnum.unregistered,
    );
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, '/native-push/test');
  });
}

const _pendingTopup = {
  'id': 7,
  'userId': 1,
  'amountRupiah': 50000,
  'creditsRequested': 10,
  'conversionRateSnapshot': 5000,
  'paymentReferenceNote': 'BCA 1234',
  'proofObjectPath': 'topups/proof-1.jpg',
  'status': 'pending',
  'reviewedByUserId': null,
  'reviewedAt': null,
  'reviewNote': null,
  'creditsGranted': null,
  'createdAt': '2026-09-08T10:00:00.000Z',
};

const _approvedTopup = {
  'id': 6,
  'userId': 1,
  'amountRupiah': 50000,
  'creditsRequested': 10,
  'conversionRateSnapshot': 5000,
  'paymentReferenceNote': null,
  'proofObjectPath': null,
  'status': 'approved',
  'reviewedByUserId': 2,
  'reviewedAt': '2026-09-07T10:00:00.000Z',
  'reviewNote': 'Verified',
  'creditsGranted': 10,
  'createdAt': '2026-09-07T09:00:00.000Z',
};

class _TopupsAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final body = switch (options.path) {
      '/topups/config' => {
        'rupiahPerCredit': 5000,
        'qrisImageUrl': 'https://cdn.example.com/qris.png',
      },
      '/topups/balance' => {'balance': 10},
      '/topups' => _pendingTopup,
      '/topups/mine' => {
        'requests': [_pendingTopup, _approvedTopup],
        'total': 2,
        'page': 1,
        'limit': 20,
      },
      '/native-push/test' => {
        'targeted': 2,
        'accepted': 1,
        'failures': ['unregistered'],
      },
      _ => {'message': 'ok'},
    };

    return ResponseBody.fromString(
      jsonEncode(body),
      options.path == '/topups' ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
