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
        ..onboardingCompleted = true,
    );
}

class _NotificationsAdapter implements HttpClientAdapter {
  bool fail = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (fail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'SQL internal failure'}),
        500,
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
            'actionType': 'analysis',
            'actionId': 42,
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
