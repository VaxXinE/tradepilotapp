import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
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
    'display-name update trims input and refreshes authenticated user',
    () async {
      final auth = await _authenticatedUser();
      final adapter = _ProfileAdapter();
      auth.client.dio.httpClientAdapter = adapter;

      expect(await auth.updateDisplayName('  Nama Baru  '), isTrue);
      expect(auth.user?.displayName, 'Nama Baru');
      expect(adapter.profileCalls, 1);
      expect(auth.isUpdatingProfile, isFalse);
    },
  );

  test(
    'registration keeps localized UI text out of the API contract',
    () async {
      final auth = AuthProvider();
      final adapter = _RegisterAdapter();
      auth.client.dio.httpClientAdapter = adapter;
      await pumpEventQueue();

      expect(
        await auth.register(
          email: 'release-test@example.com',
          password: 'secure-password',
          displayName: 'Release Test',
          securityQuestion: 'Nama hewan peliharaan pertama kamu?',
          securityAnswer: 'answer',
          mode: RegisterBodySelectedModeEnum.beginner,
        ),
        isTrue,
      );
      expect(
        adapter.requestData['securityQuestion'],
        'Nama hewan peliharaan pertama kamu?',
      );
    },
  );

  test(
    'profile mutation rejects invalid input and hides raw server errors',
    () async {
      final auth = await _authenticatedUser();
      final adapter = _ProfileAdapter()..failProfile = true;
      auth.client.dio.httpClientAdapter = adapter;

      expect(await auth.updateDisplayName(' '), isFalse);
      expect(adapter.profileCalls, 0);

      expect(await auth.updateDisplayName('Nama Valid'), isFalse);
      expect(
        auth.profileError,
        'Could not update your profile. Please try again.',
      );
      expect(auth.profileError, isNot(contains('SQL')));
    },
  );

  test('rapid mode changes allow only one request in flight', () async {
    final auth = await _authenticatedUser();
    final adapter = _ProfileAdapter()..deferProfile = true;
    auth.client.dio.httpClientAdapter = adapter;

    final first = auth.updateSelectedMode(UserSelectedModeEnum.pro);
    await pumpEventQueue();
    expect(auth.isUpdatingProfile, isTrue);
    expect(
      await auth.updateSelectedMode(UserSelectedModeEnum.beginner),
      isFalse,
    );
    expect(adapter.profileCalls, 1);

    adapter.completeProfile(mode: 'pro');
    expect(await first, isTrue);
    expect(auth.user?.selectedMode, UserSelectedModeEnum.pro);
  });

  test('language changes are synced to the authenticated profile', () async {
    final auth = await _authenticatedUser();
    final adapter = _ProfileAdapter();
    auth.client.dio.httpClientAdapter = adapter;

    expect(await auth.updateLanguage('en'), isTrue);
    expect(adapter.lastProfileData['lang'], 'en');
  });

  test('stale profile response cannot restore state after logout', () async {
    final auth = await _authenticatedUser();
    final adapter = _ProfileAdapter()..deferProfile = true;
    auth.client.dio.httpClientAdapter = adapter;

    final update = auth.updateDisplayName('Nama Baru');
    await pumpEventQueue();
    await auth.logout();
    adapter.completeProfile();

    expect(await update, isFalse);
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.user, isNull);
  });

  test('change-password state and errors remain safe', () async {
    final auth = await _authenticatedUser();
    final adapter = _ProfileAdapter()..failPassword = true;
    auth.client.dio.httpClientAdapter = adapter;

    expect(
      await auth.changePassword(
        currentPassword: 'wrong-password',
        newPassword: 'new-password',
      ),
      isFalse,
    );
    expect(auth.isChangingPassword, isFalse);
    expect(
      auth.profileError,
      'Could not change your password. Please try again.',
    );
  });

  test('Google ID token is exchanged for a TradePilot session', () async {
    var forcedAccountPicker = true;
    final auth = AuthProvider(
      googleIdTokenProvider: ({required forceAccountPicker}) async {
        forcedAccountPicker = forceAccountPicker;
        return 'google-id-token';
      },
    );
    final adapter = _GoogleAuthAdapter();
    auth.client.dio.httpClientAdapter = adapter;
    await pumpEventQueue();

    expect(await auth.loginWithGoogle(), isTrue);
    expect(forcedAccountPicker, isFalse);
    expect(adapter.loginIdToken, 'google-id-token');
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.user?.hasPassword, isFalse);
  });

  test('Google client configuration failure is explained', () async {
    final auth = AuthProvider(
      googleIdTokenProvider: ({required forceAccountPicker}) async {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'OAuth client does not match the signing certificate',
        );
      },
    );
    await pumpEventQueue();

    expect(await auth.loginWithGoogle(), isFalse);
    expect(
      auth.errorMessage,
      'Google Sign-In is not configured for this app build. Please contact support.',
    );
  });

  test(
    'Apple credential is exchanged with nonce for a TradePilot session',
    () async {
      final auth = AuthProvider(
        appleCredentialProvider: () async => (
          identityToken: 'apple-identity-token',
          authorizationCode: 'apple-authorization-code',
          nonce: 'raw-single-use-nonce',
          givenName: '  Apple ',
          familyName: ' Trader  ',
        ),
      );
      final adapter = _GoogleAuthAdapter();
      auth.client.dio.httpClientAdapter = adapter;
      await pumpEventQueue();

      expect(await auth.loginWithApple(), isTrue);
      expect(adapter.appleLoginData, {
        'identityToken': 'apple-identity-token',
        'authorizationCode': 'apple-authorization-code',
        'nonce': 'raw-single-use-nonce',
        'givenName': 'Apple',
        'familyName': 'Trader',
      });
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user?.hasPassword, isFalse);
    },
  );

  test('an over-long Apple name is capped instead of failing login', () async {
    // Skema backend memakai .strict() dengan max 100 karakter, jadi nama
    // panjang menolak seluruh permintaan login — bukan hanya namanya.
    final auth = AuthProvider(
      appleCredentialProvider: () async => (
        identityToken: 'apple-identity-token',
        authorizationCode: 'apple-authorization-code',
        nonce: 'raw-single-use-nonce',
        givenName: 'A' * 140,
        familyName: '   ',
      ),
    );
    final adapter = _GoogleAuthAdapter();
    auth.client.dio.httpClientAdapter = adapter;
    await pumpEventQueue();

    expect(await auth.loginWithApple(), isTrue);
    expect((adapter.appleLoginData!['givenName'] as String).length, 100);
    // Nama yang hanya berisi spasi tidak dikirim sama sekali.
    expect(adapter.appleLoginData!.containsKey('familyName'), isFalse);
  });

  test('Google-only deletion uses a fresh token and one-time proof', () async {
    var forcedAccountPicker = false;
    final auth = AuthProvider(
      googleIdTokenProvider: ({required forceAccountPicker}) async {
        forcedAccountPicker = forceAccountPicker;
        return 'fresh-google-id-token';
      },
    );
    final adapter = _GoogleAuthAdapter();
    auth.client.dio.httpClientAdapter = adapter;
    await pumpEventQueue();
    auth
      ..status = AuthStatus.authenticated
      ..user = _user(name: 'Google User', hasPassword: false);

    expect(await auth.deleteGoogleAccount(), isTrue);
    expect(forcedAccountPicker, isTrue);
    expect(adapter.reauthIdToken, 'fresh-google-id-token');
    expect(adapter.deleteReauthToken, 'single-use-reauth-token');
    expect(auth.status, AuthStatus.unauthenticated);
  });

  test(
    'Apple-only deletion uses a fresh credential and one-time proof',
    () async {
      final auth = AuthProvider(
        appleCredentialProvider: () async => (
          identityToken: 'fresh-apple-identity-token',
          authorizationCode: 'fresh-apple-authorization-code',
          nonce: 'fresh-raw-nonce',
          givenName: null,
          familyName: null,
        ),
      );
      final adapter = _GoogleAuthAdapter();
      auth.client.dio.httpClientAdapter = adapter;
      await pumpEventQueue();
      auth
        ..status = AuthStatus.authenticated
        ..user = _user(name: 'Apple User', hasPassword: false);

      expect(await auth.deleteAppleAccount(), isTrue);
      expect(adapter.appleReauthData, {
        'identityToken': 'fresh-apple-identity-token',
        'authorizationCode': 'fresh-apple-authorization-code',
        'nonce': 'fresh-raw-nonce',
      });
      expect(adapter.deleteReauthToken, 'single-use-reauth-token');
      expect(auth.status, AuthStatus.unauthenticated);
    },
  );
}

Future<AuthProvider> _authenticatedUser() async {
  final auth = AuthProvider();
  await pumpEventQueue();
  return auth
    ..status = AuthStatus.authenticated
    ..user = _user(name: 'User Lama');
}

User _user({
  required String name,
  String mode = 'beginner',
  bool hasPassword = true,
}) => User(
  (builder) => builder
    ..id = 1
    ..email = 'user@example.com'
    ..displayName = name
    ..role = UserRoleEnum.user
    ..selectedMode = mode == 'pro'
        ? UserSelectedModeEnum.pro
        : UserSelectedModeEnum.beginner
    ..themePreference = UserThemePreferenceEnum.dark
    ..createdAt = DateTime.utc(2026)
    ..onboardingCompleted = true
    ..hasPassword = hasPassword,
);

class _GoogleAuthAdapter implements HttpClientAdapter {
  String? loginIdToken;
  String? reauthIdToken;
  String? deleteReauthToken;
  Map<String, dynamic>? appleLoginData;
  Map<String, dynamic>? appleReauthData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = Map<String, dynamic>.from(options.data as Map);
    if (options.path == '/auth/google/native') {
      loginIdToken = data['idToken'] as String?;
      return _jsonResponse({
        'token': 'tradepilot-session-token',
        'user': _googleUserJson,
      });
    }
    if (options.path == '/auth/apple/native') {
      appleLoginData = data;
      return _jsonResponse({
        'token': 'tradepilot-session-token',
        'user': _googleUserJson,
      });
    }
    if (options.path == '/auth/reauth/google') {
      reauthIdToken = data['idToken'] as String?;
      return _jsonResponse({
        'reauthToken': 'single-use-reauth-token',
        'expiresAt': '2026-01-01T00:05:00.000Z',
      });
    }
    if (options.path == '/auth/reauth/apple') {
      appleReauthData = data;
      return _jsonResponse({
        'reauthToken': 'single-use-reauth-token',
        'expiresAt': '2026-01-01T00:05:00.000Z',
      });
    }
    if (options.path == '/auth/account') {
      deleteReauthToken = data['reauthToken'] as String?;
      return _jsonResponse({'message': 'deleted'});
    }
    throw StateError('Unexpected request: ${options.path}');
  }

  static const _googleUserJson = {
    'id': 2,
    'email': 'google@example.com',
    'displayName': 'Google User',
    'role': 'user',
    'selectedMode': 'beginner',
    'themePreference': 'dark',
    'onboardingCompleted': true,
    'hasPassword': false,
    'createdAt': '2026-01-01T00:00:00.000Z',
  };

  ResponseBody _jsonResponse(Object data) => ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _ProfileAdapter implements HttpClientAdapter {
  int profileCalls = 0;
  Map<String, dynamic> lastProfileData = {};
  bool failProfile = false;
  bool failPassword = false;
  bool deferProfile = false;
  Completer<ResponseBody>? _pendingProfile;

  void completeProfile({String mode = 'beginner'}) {
    _pendingProfile!.complete(_userResponse(name: 'Nama Baru', mode: mode));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/profile') {
      profileCalls++;
      lastProfileData = Map<String, dynamic>.from(options.data as Map);
      if (failProfile) return _errorResponse();
      if (deferProfile) {
        _pendingProfile = Completer<ResponseBody>();
        return _pendingProfile!.future;
      }
      return _userResponse(name: 'Nama Baru');
    }
    if (options.path == '/auth/password') {
      if (failPassword) return _errorResponse();
      return _jsonResponse({'message': 'ok'});
    }
    throw StateError('Unexpected request: ${options.path}');
  }

  ResponseBody _userResponse({required String name, String mode = 'beginner'}) {
    return _jsonResponse({
      'id': 1,
      'email': 'user@example.com',
      'displayName': name,
      'role': 'user',
      'selectedMode': mode,
      'themePreference': 'dark',
      'securityQuestion': 'Nama hewan pertama?',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'onboardingCompleted': true,
      'hasPassword': true,
    });
  }

  ResponseBody _errorResponse() => ResponseBody.fromString(
    jsonEncode({'message': 'SQL connection leaked internal detail'}),
    500,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  ResponseBody _jsonResponse(Object data) => ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _RegisterAdapter implements HttpClientAdapter {
  Map<String, dynamic> requestData = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/auth/register') {
      throw StateError('Unexpected request: ${options.path}');
    }
    requestData = Map<String, dynamic>.from(options.data as Map);
    return ResponseBody.fromString(
      jsonEncode({
        'token': 'registration-token',
        'user': {
          'id': 2,
          'email': 'release-test@example.com',
          'displayName': 'Release Test',
          'role': 'user',
          'selectedMode': 'beginner',
          'themePreference': 'dark',
          'securityQuestion': 'Nama hewan peliharaan pertama kamu?',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'onboardingCompleted': false,
          'hasPassword': true,
        },
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
