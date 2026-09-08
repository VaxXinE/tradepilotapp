import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/notifications_provider.dart';

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

  test('loads server unread count and clears state on logout', () async {
    final auth = await _authenticatedUser();
    auth.client.dio.httpClientAdapter = _NotificationsAdapter();
    final provider = NotificationsProvider(auth);
    addTearDown(provider.dispose);

    await provider.load();
    expect(provider.items.single.id, 9);
    expect(provider.unreadCount, 73);
    expect(provider.loadError, isNull);

    auth
      ..status = AuthStatus.unauthenticated
      ..user = null
      ..notifyListeners();
    expect(provider.items, isEmpty);
    expect(provider.unreadCount, 0);
  });

  test(
    'load failure keeps cache and exposes a friendly retry message',
    () async {
      final auth = await _authenticatedUser();
      final adapter = _NotificationsAdapter();
      auth.client.dio.httpClientAdapter = adapter;
      final provider = NotificationsProvider(auth);
      addTearDown(provider.dispose);

      await provider.load();
      adapter.fail = true;
      await provider.load();

      expect(provider.items.single.id, 9);
      expect(provider.loadError, contains('Tarik untuk mencoba lagi'));
      expect(provider.loadError, isNot(contains('SQL')));
    },
  );

  test('updates quiet hours and notification timezone together', () async {
    final auth = await _authenticatedUser();
    final adapter = _NotificationsAdapter();
    auth.client.dio.httpClientAdapter = adapter;
    final provider = NotificationsProvider(auth);
    addTearDown(provider.dispose);

    await provider.loadPreferences();
    expect(
      await provider.updateQuietHours(
        enabled: true,
        start: '23:00',
        end: '06:00',
        timezone: 'Asia/Makassar',
      ),
      isTrue,
    );
    expect(provider.preferences?.quietHoursStart, '23:00');
    expect(provider.preferences?.notificationTimezone, 'Asia/Makassar');
    expect(
      adapter.requests.last.data,
      containsPair('notificationTimezone', 'Asia/Makassar'),
    );

    final requestsBeforeInvalidInput = adapter.requests.length;
    expect(await provider.updateQuietHours(start: '25:00'), isFalse);
    expect(adapter.requests, hasLength(requestsBeforeInvalidInput));
  });
}

Future<AuthProvider> _authenticatedUser() async {
  final auth = AuthProvider();
  await pumpEventQueue();
  return auth
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
        ..onboardingCompleted = true,
    );
}

class _NotificationsAdapter implements HttpClientAdapter {
  bool fail = false;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (fail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'SQL internal failure'}),
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/push/prefs') {
      final update = options.data is Map
          ? Map<String, dynamic>.from(options.data as Map)
          : <String, dynamic>{};
      return ResponseBody.fromString(
        jsonEncode({..._pushPrefs(), ...update}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'notifications': [
          {
            'id': 9,
            'userId': 1,
            'title': 'Analisis Selesai',
            'message': 'Hasil tersedia.',
            'type': 'info',
            'actionType': 'open_analysis',
            'actionId': '42',
            'createdAt': '2026-08-23T00:00:00.000Z',
          },
        ],
        'unreadCount': 73,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _pushPrefs() => {
  'pushExpiry': true,
  'pushBroadcast': true,
  'pushDailySummary': true,
  'pushMarketNews': true,
  'pushCalendarEvents': true,
  'pushPriceAnomaly': true,
  'pushWeeklyRecap': true,
  'pushSignalFlip': true,
  'marketOpenSessions': <String>[],
  'pushDormancyNudge': false,
  'pushOnboarding': true,
  'disengageNoticeCategory': null,
  'guardrailRevenge': true,
  'guardrailOvertrading': true,
  'guardrailHighRisk': true,
  'coolingOffEnabled': false,
  'pushAnalysisCompleted': true,
  'pushTpSlHit': true,
  'pushLoginAlert': true,
  'nativePushEnabled': true,
  'webPushEnabled': false,
  'quietHoursEnabled': true,
  'quietHoursStart': '22:00',
  'quietHoursEnd': '07:00',
  'notificationTimezone': 'Asia/Jakarta',
  'progressionNotificationsEnabled': true,
};
