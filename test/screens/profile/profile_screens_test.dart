import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/theme/theme_controller.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/screens/home/tabs/profile_tab.dart';
import 'package:tradepilotapp/screens/profile/change_password_screen.dart';
import 'package:tradepilotapp/screens/profile/delete_account_screen.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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

  testWidgets('profile renders account sections without notification entry', (
    tester,
  ) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    final theme = ThemeController(await SharedPreferences.getInstance());
    final locale = LocaleController(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: locale),
        ],
        child: const _LocalizedApp(home: ProfileTab()),
      ),
    );

    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Profile Information'), findsOneWidget);
    expect(find.text('Analysis mode'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Dark theme'),
          )
          .value,
      isTrue,
    );
    expect(find.textContaining('Current: Beginner'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Notification Settings'), findsNothing);

    final originalLauncher = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _FailingUrlLauncher();
    addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);
    await tester.scrollUntilVisible(
      find.text('Privacy Policy'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy Policy'));
    await tester.pump();
    expect(find.text('The link could not be opened.'), findsOneWidget);

    await tester.ensureVisible(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();

    expect(locale.locale.languageCode, 'id');
    expect(find.text('Preferensi'), findsOneWidget);
  });

  testWidgets('account deletion requires confirmation and clears session', (
    tester,
  ) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    final adapter = _DeleteAccountAdapter();
    auth.client.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const _LocalizedApp(home: DeleteAccountScreen()),
      ),
    );

    final deleteButton = find.widgetWithText(
      FilledButton,
      'Permanently Delete Account',
    );
    expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'current-password');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(adapter.password, 'current-password');
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.user, isNull);
  });

  testWidgets('change password rejects confirmation mismatch locally', (
    tester,
  ) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    final adapter = _CountingAdapter();
    auth.client.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const _LocalizedApp(home: ChangePasswordScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'current-pass');
    await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
    await tester.enterText(find.byType(TextFormField).at(2), 'different-pass');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Password confirmation does not match'), findsOneWidget);
    expect(adapter.calls, 0);
  });

  testWidgets('logout clears the session', (tester) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    auth.client.dio.httpClientAdapter = _LogoutAdapter();
    final theme = ThemeController(await SharedPreferences.getInstance());
    final locale = LocaleController(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: locale),
        ],
        child: const _LocalizedApp(home: ProfileTab()),
      ),
    );
    final logoutButton = find.widgetWithText(OutlinedButton, 'Sign Out');
    await tester.ensureVisible(logoutButton);
    await tester.pump();
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
    await tester.pumpAndSettle();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.user, isNull);
  });
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController?>()?.locale;
    return MaterialApp(
      locale: locale ?? const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }
}

void _authenticate(AuthProvider auth) {
  auth
    ..status = AuthStatus.authenticated
    ..user = User(
      (builder) => builder
        ..id = 1
        ..email = 'user@example.com'
        ..displayName = 'User Profile'
        ..role = UserRoleEnum.user
        ..selectedMode = UserSelectedModeEnum.beginner
        ..themePreference = UserThemePreferenceEnum.dark
        ..securityQuestion = 'Nama hewan pertama?'
        ..onboardingCompleted = true,
    );
}

class _CountingAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls++;
    throw StateError('Request tidak seharusnya dikirim');
  }

  @override
  void close({bool force = false}) {}
}

class _LogoutAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"ok"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _DeleteAccountAdapter implements HttpClientAdapter {
  String? password;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.method, 'DELETE');
    expect(options.path, '/auth/account');
    password =
        (options.data as Map<String, dynamic>)['currentPassword'] as String;
    return ResponseBody.fromString(
      '{"message":"ok"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FailingUrlLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) {
    throw PlatformException(code: 'channel-error');
  }
}
