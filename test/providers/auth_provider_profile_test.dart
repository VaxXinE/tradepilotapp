import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(auth.profileError, 'Gagal memperbarui profil. Silakan coba lagi.');
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
    expect(auth.profileError, 'Gagal mengubah password. Silakan coba lagi.');
  });
}

Future<AuthProvider> _authenticatedUser() async {
  final auth = AuthProvider();
  await pumpEventQueue();
  return auth
    ..status = AuthStatus.authenticated
    ..user = _user(name: 'User Lama');
}

User _user({required String name, String mode = 'beginner'}) => User(
  (builder) => builder
    ..id = 1
    ..email = 'user@example.com'
    ..displayName = name
    ..role = UserRoleEnum.user
    ..selectedMode = mode == 'pro'
        ? UserSelectedModeEnum.pro
        : UserSelectedModeEnum.beginner
    ..themePreference = UserThemePreferenceEnum.dark
    ..securityQuestion = 'Nama hewan pertama?'
    ..onboardingCompleted = true,
);

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
      'onboardingCompleted': true,
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
          'onboardingCompleted': false,
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
