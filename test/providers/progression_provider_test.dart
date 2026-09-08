import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/progression_provider.dart';

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

  test('loads private progression and clears it on logout', () async {
    final auth = AuthProvider();
    await pumpEventQueue();
    auth
      ..status = AuthStatus.authenticated
      ..user = User(
        (builder) => builder
          ..id = 7
          ..email = 'user@example.com'
          ..displayName = 'User'
          ..role = UserRoleEnum.user
          ..selectedMode = UserSelectedModeEnum.beginner
          ..themePreference = UserThemePreferenceEnum.dark
          ..createdAt = DateTime.utc(2026)
          ..onboardingCompleted = true,
      );
    auth.client.dio.httpClientAdapter = _ProgressionAdapter();
    final progression = ProgressionProvider(auth);
    addTearDown(progression.dispose);

    await progression.refresh();

    expect(progression.summary?.totalXp, 120);
    expect(progression.catalog?.achievements.single.unlocked, isTrue);
    expect(progression.history?.entries.single.source_, 'guide_completion');

    await auth.forceLogout();

    expect(progression.summary, isNull);
    expect(progression.catalog, isNull);
    expect(progression.history, isNull);
  });
}

class _ProgressionAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = switch (options.path) {
      '/progression/summary' => {
        'totalXp': 120,
        'level': 3,
        'masteryLevel': 0,
        'rank': 'observer',
        'currentLevelXp': 100,
        'nextLevelXp': 180,
        'currentStreak': 2,
        'longestStreak': 4,
      },
      '/progression/catalog' => {
        'achievements': [
          {
            'key': 'guide_1',
            'unlocked': true,
            'unlockedAt': '2026-09-07T01:00:00.000Z',
          },
        ],
      },
      '/progression/history' => {
        'entries': [
          {
            'id': 1,
            'source': 'guide_completion',
            'xp': 10,
            'dayBucket': '2026-09-07',
            'ruleVersion': 'v1',
            'createdAt': '2026-09-07T01:00:00.000Z',
          },
        ],
      },
      _ => throw StateError('Unexpected request: ${options.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
