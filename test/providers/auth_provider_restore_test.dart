import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';

/// Restoring the saved session on launch. The token is only worth deleting
/// when the server rejected it: a network hiccup (typical right after coming
/// back from the browser, or a cold start with a weak signal) used to send the
/// user to the login form and wipe a perfectly good token.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late List<String> deletedKeys;
  late bool hasStoredToken;

  setUp(() {
    deletedKeys = [];
    hasStoredToken = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final key = (call.arguments as Map)['key'] as String?;
          if (call.method == 'delete' && key != null) deletedKeys.add(key);
          if (call.method == 'read' && key == 'trade_pilot_token') {
            return hasStoredToken ? 'saved-token' : null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Future<AuthProvider> launch(_MeAdapter adapter) async {
    // The constructor restores once with no token; the real restore is the
    // explicit call below, after the fake network is in place.
    final auth = AuthProvider();
    await pumpEventQueue();
    deletedKeys.clear();
    hasStoredToken = true;
    auth
      ..restoreRetryDelay = Duration.zero
      ..client.dio.httpClientAdapter = adapter;
    await auth.restoreSession();
    return auth;
  }

  test('a valid saved session signs the user in', () async {
    final adapter = _MeAdapter([_ok]);
    final auth = await launch(adapter);

    expect(auth.status, AuthStatus.authenticated);
    expect(auth.user?.email, 'user@example.com');
    expect(deletedKeys, isNot(contains('trade_pilot_token')));
  });

  test('a brief network failure is retried instead of signing out', () async {
    final adapter = _MeAdapter([_offline, _offline, _ok]);
    final auth = await launch(adapter);

    expect(adapter.calls, 3);
    expect(auth.status, AuthStatus.authenticated);
    expect(deletedKeys, isNot(contains('trade_pilot_token')));
  });

  test('a server outage keeps the saved token for the next launch', () async {
    final adapter = _MeAdapter([_offline, _offline, _offline]);
    final auth = await launch(adapter);

    expect(adapter.calls, 3);
    expect(auth.status, AuthStatus.unauthenticated);
    expect(
      deletedKeys,
      isNot(contains('trade_pilot_token')),
      reason: 'the token was never rejected, so the next launch can reuse it',
    );
  });

  test('a 503 is treated like a network failure', () async {
    final adapter = _MeAdapter([_unavailable, _ok]);
    final auth = await launch(adapter);

    expect(auth.status, AuthStatus.authenticated);
    expect(deletedKeys, isNot(contains('trade_pilot_token')));
  });

  test('every request tells the backend it comes from the app', () async {
    final adapter = _MeAdapter([_ok]);
    await launch(adapter);

    expect(adapter.lastHeaders['X-Client-Platform'], 'native');
  });

  test('a rejected token is deleted straight away', () async {
    final adapter = _MeAdapter([_unauthorized]);
    final auth = await launch(adapter);

    expect(adapter.calls, 1, reason: 'a dead token is not worth retrying');
    expect(auth.status, AuthStatus.unauthenticated);
    expect(deletedKeys, contains('trade_pilot_token'));
  });
}

typedef _Reply = ResponseBody Function();

ResponseBody _ok() => ResponseBody.fromString(
  jsonEncode({
    'id': 1,
    'email': 'user@example.com',
    'displayName': 'Trader',
    'role': 'user',
    'selectedMode': 'beginner',
    'themePreference': 'dark',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'onboardingCompleted': true,
    'hasPassword': true,
  }),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _unauthorized() => ResponseBody.fromString(
  jsonEncode({'error': 'Unauthorized'}),
  401,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _unavailable() => ResponseBody.fromString(
  jsonEncode({'error': 'Unavailable'}),
  503,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _offline() => throw DioException.connectionError(
  requestOptions: RequestOptions(path: '/auth/me'),
  reason: 'offline',
);

/// Answers `/auth/me` with the scripted replies, in order.
class _MeAdapter implements HttpClientAdapter {
  _MeAdapter(this._replies);

  final List<_Reply> _replies;
  int calls = 0;
  Map<String, dynamic> lastHeaders = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final reply =
        _replies[calls < _replies.length ? calls : _replies.length - 1];
    calls++;
    lastHeaders = Map.of(options.headers);
    return reply();
  }

  @override
  void close({bool force = false}) {}
}
