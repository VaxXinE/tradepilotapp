import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';
import 'package:tradepilotapp/core/theme/app_theme.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/screens/auth/login_screen.dart';
import 'package:tradepilotapp/screens/auth/register_screen.dart';
import 'package:tradepilotapp/screens/auth/welcome_screen.dart';

void main() {
  testWidgets('onboarding remembers completion and opens registration', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(_TestApp(preferences: preferences));

    await tester.ensureVisible(
      find.byKey(const Key('onboarding-register-button')),
    );
    await tester.tap(find.byKey(const Key('onboarding-register-button')));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(preferences.getBool(WelcomeScreen.preferenceKey), isTrue);
  });

  testWidgets('onboarding remains usable on a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      _TestApp(preferences: preferences, theme: AppTheme.dark),
    );
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-login-button')),
    );
    await tester.tap(find.byKey(const Key('onboarding-login-button')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.preferences, this.theme});

  final SharedPreferences preferences;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleController(preferences)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: WelcomeScreen(preferences: preferences),
      ),
    );
  }
}
