import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';
import 'package:tradepilotapp/core/theme/app_theme.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/screens/auth/forgot_password_screen.dart';
import 'package:tradepilotapp/screens/auth/login_screen.dart';
import 'package:tradepilotapp/screens/auth/register_screen.dart';

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

  testWidgets('login keeps branding compact and validates empty form', (
    tester,
  ) async {
    await _pumpAuthScreen(tester, const LoginScreen());

    expect(
      tester.getSize(find.byKey(const Key('login-brand-mark'))),
      const Size(56, 56),
    );
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byKey(const Key('google-sign-in-button')), findsOneWidget);
    expect(find.byKey(const Key('apple-sign-in-button')), findsNothing);

    await tester.ensureVisible(find.text('Sign In to Dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('login exposes Sign in with Apple only on iOS', (tester) async {
    // Kerangka test memverifikasi debug variable sebelum tearDown berjalan,
    // jadi override dikembalikan di sini — bukan lewat addTearDown.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _pumpAuthScreen(tester, const LoginScreen());

      expect(find.byKey(const Key('google-sign-in-button')), findsOneWidget);
      expect(find.byKey(const Key('apple-sign-in-button')), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('login hides Sign in with Apple on Android', (tester) async {
    // Apple mewajibkan tombolnya hanya muncul di platform Apple; di Android
    // tombol Google tetap satu-satunya opsi sosial.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _pumpAuthScreen(tester, const LoginScreen());

      expect(find.byKey(const Key('google-sign-in-button')), findsOneWidget);
      expect(find.byKey(const Key('apple-sign-in-button')), findsNothing);
      expect(find.text('Continue with Apple'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('login restores the remembered email but never a password', (
    tester,
  ) async {
    // Stands in for a device upgraded from 1.0.1, which stored the plaintext
    // password and typed it back into the form. Storage still hands one over;
    // the screen must refuse it.
    final readKeys = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          if (call.method != 'read') return null;
          final key = (call.arguments as Map)['key'] as String;
          readKeys.add(key);
          return key == 'remembered_login_email'
              ? 'trader@example.com'
              : 'secure-password';
        });

    await _pumpAuthScreen(tester, const LoginScreen());
    await tester.pumpAndSettle();

    expect(find.text('trader@example.com'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const Key('remember-me-checkbox')),
          )
          .value,
      isTrue,
    );

    expect(
      readKeys,
      isNot(contains('remembered_login_password')),
      reason: 'the password key must not be read back at all',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller
          ?.text,
      isEmpty,
      reason: 'a prefilled password is readable by anyone holding the phone',
    );
  });

  testWidgets('login offers no biometric shortcut into a stored password', (
    tester,
  ) async {
    await _pumpAuthScreen(tester, const LoginScreen());
    await tester.pumpAndSettle();

    // Biometrics unlock an existing session on LockScreen. Reaching the login
    // screen means there is no session, so there is nothing to unlock.
    expect(find.byKey(const Key('biometric-login-button')), findsNothing);
  });

  testWidgets('register follows provider-only account creation', (
    tester,
  ) async {
    await _pumpAuthScreen(tester, const RegisterScreen());

    expect(find.byKey(const Key('register-google-button')), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Beginner'), findsNothing);
    expect(find.text('Security Question'), findsNothing);
  });

  testWidgets('forgot password explains progress and reports invalid email', (
    tester,
  ) async {
    await _pumpAuthScreen(tester, const ForgotPasswordScreen());

    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Find your account'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });
}

Future<void> _pumpAuthScreen(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleController(preferences)),
      ],
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
        home: screen,
      ),
    ),
  );
}
