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

  test(
    'gets, arms, and cancels AI analysis levels without manual prices',
    () async {
      final auth = AuthProvider();
      await pumpEventQueue();
      auth
        ..status = AuthStatus.authenticated
        ..user = _user();
      final adapter = _AnalysisAlertAdapter();
      auth.client.dio.httpClientAdapter = adapter;
      final provider = AnalysisProvider(auth);
      addTearDown(provider.dispose);

      expect((await provider.getAnalysisAlerts(42))?.enabled, isFalse);
      final armed = await provider.setAnalysisAlerts(42, enabled: true);
      expect(armed?.enabled, isTrue);
      expect(armed?.levels.single.price, '4350.00');
      expect(armed?.levels.single.triggeredAt, isNull);
      expect(
        (await provider.setAnalysisAlerts(42, enabled: false))?.enabled,
        isFalse,
      );
      expect(
        adapter.requests.map((request) => '${request.method} ${request.path}'),
        [
          'GET /analyses/42/alerts',
          'POST /analyses/42/alerts',
          'DELETE /analyses/42/alerts',
        ],
      );
    },
  );
}

User _user() => User(
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

class _AnalysisAlertAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final enabled = options.method == 'POST';
    return ResponseBody.fromString(
      jsonEncode({
        'enabled': enabled,
        'armedCount': enabled ? 1 : 0,
        'levels': enabled
            ? [
                {
                  'level': 'tp1',
                  'side': 'buy',
                  'price': '4350.00',
                  'direction': 'above',
                  'triggeredAt': null,
                  'triggeredPrice': null,
                  'cancelledAt': null,
                },
              ]
            : [],
      }),
      enabled ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
