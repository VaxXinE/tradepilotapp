import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/theme/app_theme.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/screens/lock_screen.dart';
import 'package:tradepilotapp/screens/splash_screen.dart';

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

  testWidgets('a successful prompt unlocks the session', (tester) async {
    final auth = await _lockedSession(tester);
    final localAuth = _FakeLocalAuthentication(result: true);

    await _pumpLockScreen(tester, auth, localAuth);
    await tester.pumpAndSettle();

    expect(localAuth.authenticateCalls, 1, reason: 'prompts without a tap');
    expect(auth.isLocked, isFalse);
  });

  testWidgets('a refused prompt keeps the session locked', (tester) async {
    final auth = await _lockedSession(tester);
    final localAuth = _FakeLocalAuthentication(result: false);

    await _pumpLockScreen(tester, auth, localAuth);
    await tester.pumpAndSettle();

    expect(auth.isLocked, isTrue);
    expect(
      find.text('Could not verify your identity. Try again or sign out.'),
      findsOneWidget,
    );
  });

  testWidgets('a cancelled prompt keeps the session locked', (tester) async {
    final auth = await _lockedSession(tester);
    final localAuth = _FakeLocalAuthentication(
      exceptionCode: LocalAuthExceptionCode.userCanceled,
    );

    await _pumpLockScreen(tester, auth, localAuth);
    await tester.pumpAndSettle();

    expect(auth.isLocked, isTrue);
    expect(
      find.text('Could not verify your identity. Try again or sign out.'),
      findsOneWidget,
    );
  });

  testWidgets('a device without working biometrics is not left stranded', (
    tester,
  ) async {
    final auth = await _lockedSession(tester);
    final localAuth = _FakeLocalAuthentication(
      exceptionCode: LocalAuthExceptionCode.noBiometricHardware,
    );

    await _pumpLockScreen(tester, auth, localAuth);
    await tester.pumpAndSettle();

    expect(
      auth.isLocked,
      isFalse,
      reason: 'a broken sensor must not permanently bar a valid session',
    );
  });

  testWidgets('signing out from the lock screen ends the session', (
    tester,
  ) async {
    final auth = await _lockedSession(tester);
    final localAuth = _FakeLocalAuthentication(result: false);

    await _pumpLockScreen(tester, auth, localAuth);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lock-sign-out-button')));
    await tester.pumpAndSettle();

    expect(auth.status, AuthStatus.unauthenticated);
  });

  testWidgets('splash routes an authenticated but locked session to the lock '
      'screen', (tester) async {
    final auth = await _lockedSession(tester);

    await tester.pumpWidget(_app(auth, const SplashScreen()));
    await tester.pumpAndSettle();

    // The unlocked branch renders HomeShell, which needs every other provider;
    // that transition is covered by unlockSession() in the tests above.
    expect(find.byType(LockScreen), findsOneWidget);
  });
}

/// Builds a provider that behaves like a restored-but-locked session.
///
/// The constructor kicks off `_restoreSession()`, which resolves to
/// *unauthenticated* here because storage hands back no token. That has to land
/// before the state below is applied, or it clobbers it. Note this pumps rather
/// than awaiting `pumpEventQueue()`: under `testWidgets` the binding drives a
/// fake clock, so `pumpEventQueue()` waits on a timer that never fires.
Future<AuthProvider> _lockedSession(WidgetTester tester) async {
  final auth = AuthProvider();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  return auth
    ..status = AuthStatus.authenticated
    ..user = _user()
    ..isLocked = true;
}

User _user() => User(
  (builder) => builder
    ..id = 1
    ..email = 'user@example.com'
    ..displayName = 'Trader'
    ..role = UserRoleEnum.user
    ..selectedMode = UserSelectedModeEnum.beginner
    ..themePreference = UserThemePreferenceEnum.dark
    ..createdAt = DateTime.utc(2026)
    ..onboardingCompleted = true
    ..hasPassword = true,
);

Future<void> _pumpLockScreen(
  WidgetTester tester,
  AuthProvider auth,
  LocalAuthentication localAuth,
) {
  return tester.pumpWidget(
    _app(auth, LockScreen(localAuthentication: localAuth)),
  );
}

Widget _app(AuthProvider auth, Widget home) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

class _FakeLocalAuthentication extends LocalAuthentication {
  _FakeLocalAuthentication({this.result = true, this.exceptionCode});

  final bool result;
  final LocalAuthExceptionCode? exceptionCode;
  int authenticateCalls = 0;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [
    BiometricType.face,
  ];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    authenticateCalls++;
    if (exceptionCode case final code?) {
      throw LocalAuthException(code: code);
    }
    return result;
  }
}
