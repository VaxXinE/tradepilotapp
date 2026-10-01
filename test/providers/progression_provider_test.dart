import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/progression_provider.dart';

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
          ..onboardingCompleted = true
          ..hasPassword = true,
      );
    auth.client.dio.httpClientAdapter = _ProgressionAdapter();
    final progression = ProgressionProvider(auth);
    addTearDown(progression.dispose);

    await progression.refresh();

    expect(progression.summary?.totalXp, 120);
    expect(progression.catalog?.achievements.single.unlocked, isTrue);
    expect(progression.completedGuideIds, {'how-ai-works'});
    expect(progression.history?.entries.single.source_, 'guide_completion');

    await auth.forceLogout();

    expect(progression.summary, isNull);
    expect(progression.catalog, isNull);
    expect(progression.history, isNull);
  });

  group('level-up celebration', () {
    test('the first summary of a session is only a baseline', () async {
      final auth = await _authenticated();
      final adapter = _ProgressionAdapter(level: 3, totalXp: 120);
      auth.client.dio.httpClientAdapter = adapter;
      final progression = ProgressionProvider(auth);
      addTearDown(progression.dispose);

      // The constructor already starts a background refresh for a signed-in
      // user; wait for it so the baseline is established deterministically.
      await pumpEventQueue(times: 60);

      expect(progression.celebrationLevel, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('tp_mobile_progression_level_ack.7'), 3);
    });

    test(
      'more XP and a higher level in the same session celebrates once',
      () async {
        final auth = await _authenticated();
        final adapter = _ProgressionAdapter(level: 3, totalXp: 120);
        auth.client.dio.httpClientAdapter = adapter;
        final progression = ProgressionProvider(auth);
        addTearDown(progression.dispose);
        await pumpEventQueue(times: 60);

        adapter
          ..level = 4
          ..totalXp = 190;
        await progression.refresh();
        expect(progression.celebrationLevel, 4);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('tp_mobile_progression_level_ack.7'), 4);

        progression.acknowledgeCelebration();
        expect(progression.celebrationLevel, isNull);

        // Refreshing again at the same level never replays it.
        await progression.refresh();
        expect(progression.celebrationLevel, isNull);
      },
    );

    test('a level recalculation without new XP is not a level-up', () async {
      final auth = await _authenticated();
      final adapter = _ProgressionAdapter(level: 3, totalXp: 120);
      auth.client.dio.httpClientAdapter = adapter;
      final progression = ProgressionProvider(auth);
      addTearDown(progression.dispose);
      await pumpEventQueue(times: 60);

      adapter.level = 5; // rules changed, XP did not
      await progression.refresh();

      expect(progression.celebrationLevel, isNull);
    });

    test(
      'a level already acknowledged on this device is not replayed',
      () async {
        SharedPreferences.setMockInitialValues({
          'tp_mobile_progression_level_ack.7': 6,
        });
        final auth = await _authenticated();
        final adapter = _ProgressionAdapter(level: 3, totalXp: 120);
        auth.client.dio.httpClientAdapter = adapter;
        final progression = ProgressionProvider(auth);
        addTearDown(progression.dispose);
        await pumpEventQueue(times: 60);

        adapter
          ..level = 5
          ..totalXp = 300;
        await progression.refresh();

        expect(progression.celebrationLevel, isNull);
      },
    );
  });
}

Future<AuthProvider> _authenticated() async {
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
        ..onboardingCompleted = true
        ..hasPassword = true,
    );
  return auth;
}

class _ProgressionAdapter implements HttpClientAdapter {
  _ProgressionAdapter({this.level = 3, this.totalXp = 120});

  int level;
  int totalXp;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = switch (options.path) {
      '/progression/summary' => {
        'totalXp': totalXp,
        'level': level,
        'masteryLevel': 0,
        'rank': 'observer',
        'currentLevelXp': 100,
        'nextLevelXp': 180,
        'currentStreak': 2,
        'longestStreak': 4,
      },
      '/progression/catalog' => {
        'completedGuideIds': ['how-ai-works'],
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
