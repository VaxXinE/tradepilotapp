import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
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
      const Size(120, 80),
    );
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('login restores remembered credentials from secure storage', (
    tester,
  ) async {
    final localAuthentication = _FakeLocalAuthentication();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          if (call.method != 'read') return null;
          final key = (call.arguments as Map)['key'];
          return key == 'remembered_login_email'
              ? 'trader@example.com'
              : 'secure-password';
        });

    await _pumpAuthScreen(
      tester,
      LoginScreen(localAuthentication: localAuthentication),
    );
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
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller
          ?.text,
      'secure-password',
    );

    final biometricButton = find.byKey(const Key('biometric-login-button'));
    await tester.ensureVisible(biometricButton);
    await tester.tap(biometricButton);
    await tester.pump();
    expect(localAuthentication.authenticateCalls, 1);
  });

  testWidgets('register uses accessible mode selection and validates input', (
    tester,
  ) async {
    await _pumpAuthScreen(tester, const RegisterScreen());

    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    await tester.tap(find.text('Pro'));
    await tester.pump();
    expect(
      find.text('More concise and technical market information.'),
      findsOneWidget,
    );

    final submit = find.widgetWithText(ElevatedButton, 'Create Account');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
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

class _FakeLocalAuthentication extends LocalAuthentication {
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
    return false;
  }
}

Future<void> _pumpAuthScreen(WidgetTester tester, Widget screen) {
  return tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
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
