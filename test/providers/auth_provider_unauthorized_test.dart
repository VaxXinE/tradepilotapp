import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';

/// Guards the central 401 handling.
///
/// The distinction under test is the whole point of the interceptor: a 401 on a
/// session-backed endpoint means the token died and the user must be returned
/// to login, while a 401 on an endpoint that re-challenges for the current
/// password means the user simply mistyped it and must stay logged in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late List<String> deletedKeys;

  setUp(() {
    deletedKeys = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          if (call.method == 'delete') {
            deletedKeys.add((call.arguments as Map)['key'] as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  test('every launch deletes the password older builds left behind', () async {
    await _authenticatedUser();

    expect(
      deletedKeys,
      contains('remembered_login_password'),
      reason: 'a password cannot be revoked server-side, so it must go',
    );
  });

  test(
    '401 on a session endpoint closes the session and clears storage',
    () async {
      final auth = await _authenticatedUser();
      auth.client.dio.httpClientAdapter = _UnauthorizedAdapter();

      await auth.refreshMe();
      await pumpEventQueue();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.user, isNull);
      expect(deletedKeys, contains('trade_pilot_token'));
    },
  );

  test('401 while changing password keeps the user signed in', () async {
    final auth = await _authenticatedUser();
    auth.client.dio.httpClientAdapter = _UnauthorizedAdapter();

    final changed = await auth.changePassword(
      currentPassword: 'wrong-password',
      newPassword: 'a-new-password',
    );
    await pumpEventQueue();

    expect(changed, isFalse);
    expect(
      auth.status,
      AuthStatus.authenticated,
      reason: 'mistyping the current password must not eject the user',
    );
    expect(auth.user, isNotNull);
    expect(
      deletedKeys,
      isNot(contains('trade_pilot_token')),
      reason: 'the session token must survive a wrong-password rejection',
    );
  });

  test('401 while deleting the account keeps the user signed in', () async {
    final auth = await _authenticatedUser();
    auth.client.dio.httpClientAdapter = _UnauthorizedAdapter();

    final deleted = await auth.deleteAccount('wrong-password');
    await pumpEventQueue();

    expect(deleted, isFalse);
    expect(auth.status, AuthStatus.authenticated);
    expect(deletedKeys, isNot(contains('trade_pilot_token')));
  });

  test('wrong security answer has a specific validation message', () async {
    final auth = await _authenticatedUser();
    auth.client.dio.httpClientAdapter = _UnauthorizedAdapter();

    final result = await auth.verifySecurityAnswer(
      email: 'user@example.com',
      answer: 'wrong-answer',
    );

    expect(result, isNull);
    expect(auth.errorMessage, 'That security answer is incorrect.');
    expect(auth.status, AuthStatus.authenticated);
  });

  test('the rejected request still surfaces its error to the caller', () async {
    final auth = await _authenticatedUser();
    auth.client.dio.httpClientAdapter = _UnauthorizedAdapter();

    await auth.changePassword(
      currentPassword: 'wrong-password',
      newPassword: 'a-new-password',
    );
    await pumpEventQueue();

    expect(
      auth.profileError,
      isNotNull,
      reason: 'the interceptor closes sessions, it must not swallow errors',
    );
  });

  test('concurrent 401s only tear the session down once', () async {
    final auth = await _authenticatedUser();
    auth.client.dio.httpClientAdapter = _UnauthorizedAdapter();

    var notifications = 0;
    auth.addListener(() => notifications++);

    await Future.wait([auth.refreshMe(), auth.refreshMe(), auth.refreshMe()]);
    await pumpEventQueue();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(notifications, 1, reason: 'three parallel rejections, one logout');
  });
}

Future<AuthProvider> _authenticatedUser() async {
  final auth = AuthProvider();
  await pumpEventQueue();
  return auth
    ..status = AuthStatus.authenticated
    ..user = _user();
}

User _user() => User(
  (builder) => builder
    ..id = 1
    ..email = 'user@example.com'
    ..displayName = 'Trader'
    ..role = UserRoleEnum.user
    ..selectedMode = UserSelectedModeEnum.beginner
    ..themePreference = UserThemePreferenceEnum.dark
    ..securityQuestion = 'Nama hewan pertama?'
    ..createdAt = DateTime.utc(2026)
    ..onboardingCompleted = true,
);

/// Answers 401 to everything, so each test is defined purely by which endpoint
/// it calls.
class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'error': 'Unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
