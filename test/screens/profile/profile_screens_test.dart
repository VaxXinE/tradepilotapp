import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/theme/theme_controller.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';
import 'package:tradepilotapp/core/preferences/mental_checklist_controller.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/credit_provider.dart';
import 'package:tradepilotapp/providers/progression_provider.dart';
import 'package:tradepilotapp/repositories/topup_repository.dart';
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

  testWidgets('profile follows the compact responsive web structure', (
    tester,
  ) async {
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    final theme = ThemeController(await SharedPreferences.getInstance());
    final locale = LocaleController(await SharedPreferences.getInstance());
    final checklist = MentalChecklistController(
      await SharedPreferences.getInstance(),
    );
    final progression = ProgressionProvider(auth);
    addTearDown(progression.dispose);
    final credit = CreditProvider(auth, TopupRepository(auth.client));
    addTearDown(credit.dispose);
    final originalLauncher = UrlLauncherPlatform.instance;
    final launcher = _RecordingUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: locale),
          ChangeNotifierProvider.value(value: checklist),
          ChangeNotifierProvider.value(value: progression),
          ChangeNotifierProvider.value(value: credit),
        ],
        child: const _LocalizedApp(home: ProfileTab()),
      ),
    );

    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.byKey(const Key('profile-theme-segmented')), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Security Question'), findsOneWidget);
    expect(find.text('Privacy & Security'), findsOneWidget);
    expect(find.text('My Alerts'), findsOneWidget);
    expect(find.text('Notification Settings'), findsOneWidget);
    expect(find.text('Analysis Credits'), findsOneWidget);
    expect(find.byKey(const Key('profile-sign-out')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Analysis Credits'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analysis Credits'));
    await tester.pumpAndSettle();
    expect(launcher.launchedUrls, ['https://tradepilot.id/topup?source=app']);
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

  testWidgets('passwordless deletion offers Apple and Google on iOS', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final auth = AuthProvider();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      _authenticate(auth, hasPassword: false);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: const _LocalizedApp(home: DeleteAccountScreen()),
        ),
      );

      expect(find.byKey(const Key('delete-with-apple')), findsOneWidget);
      expect(find.byKey(const Key('delete-with-google')), findsOneWidget);
      expect(
        find.text(
          'To protect your account, verify with the sign-in method linked to this account before deletion.',
        ),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
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
    final checklist = MentalChecklistController(
      await SharedPreferences.getInstance(),
    );
    final progression = ProgressionProvider(auth);
    addTearDown(progression.dispose);
    final credit = CreditProvider(auth, TopupRepository(auth.client));
    addTearDown(credit.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: locale),
          ChangeNotifierProvider.value(value: checklist),
          ChangeNotifierProvider.value(value: progression),
          ChangeNotifierProvider.value(value: credit),
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

  testWidgets('profile remains readable at 200% text scaling', (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    _authenticate(auth);
    final preferences = await SharedPreferences.getInstance();
    final progression = ProgressionProvider(auth);
    addTearDown(progression.dispose);
    final credit = CreditProvider(auth, TopupRepository(auth.client));
    addTearDown(credit.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => ThemeController(preferences)),
          ChangeNotifierProvider(create: (_) => LocaleController(preferences)),
          ChangeNotifierProvider.value(value: progression),
          ChangeNotifierProvider.value(value: credit),
        ],
        child: const _LocalizedApp(
          home: ProfileTab(),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -900), 1200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({
    required this.home,
    this.textScaler = TextScaler.noScaling,
  });

  final Widget home;
  final TextScaler textScaler;

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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: home,
    );
  }
}

void _authenticate(AuthProvider auth, {bool hasPassword = true}) {
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
        ..createdAt = DateTime.utc(2026)
        ..onboardingCompleted = true
        ..hasPassword = hasPassword,
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
