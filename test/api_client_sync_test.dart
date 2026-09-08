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
          'avatarUrl': null,
        },
      },
    );

    expect(response?.token, 'session-token');
    expect(response?.user.createdAt, isNull);
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
      client.nativePush.registerNativePushDevice,
      client.nativePush.unregisterNativePushDevice,
      client.progression.getProgressionCatalog,
      client.progression.getProgressionHistory,
      client.progression.getProgressionSummary,
      client.progression.recordProgressionActivity,
      client.progression.startProgressionEvidence,
      client.tradingRules.getStandardTradingRules,
    ], hasLength(16));

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
}
