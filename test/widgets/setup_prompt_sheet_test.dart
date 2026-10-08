import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/setup/setup_prompt_policy.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/services/in_app_review_service.dart';
import 'package:tradepilotapp/services/native_push_service.dart';
import 'package:tradepilotapp/services/setup_prompt_service.dart';
import 'package:tradepilotapp/widgets/setup_prompt_sheet.dart';

class _FakePush extends NativePushService {
  _FakePush(super.auth, {this.active = false, this.denied = false});

  bool active;
  final bool denied;
  int enableCalls = 0;

  @override
  bool get isActive => active;

  @override
  bool get isPermissionDenied => denied;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> enable() async {
    enableCalls++;
    active = true;
    notifyListeners();
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_secure_storage holds the biometric-lock flag.
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secure = <String, String>{};

  setUp(() {
    secure.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
          switch (call.method) {
            case 'read':
              return secure[args['key']];
            case 'write':
              secure[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              secure.remove(args['key']);
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Future<
    ({
      AuthProvider auth,
      _FakePush push,
      SetupPromptService setup,
      Future<bool> Function() show,
    })
  >
  pump(
    WidgetTester tester, {
    int analyses = SetupPromptPolicy.minAnalyses,
    bool biometrics = true,
    bool pushActive = false,
    bool pushDenied = false,
    bool locked = false,
  }) async {
    SharedPreferences.setMockInitialValues({'review.analysis_count': analyses});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    auth
      ..status = AuthStatus.authenticated
      ..isLocked = locked
      ..user = User(
        (b) => b
          ..id = 1
          ..email = 'user@example.com'
          ..displayName = 'User'
          ..role = UserRoleEnum.user
          ..selectedMode = UserSelectedModeEnum.beginner
          ..themePreference = UserThemePreferenceEnum.dark
          ..createdAt = DateTime.utc(2026)
          ..onboardingCompleted = true
          ..hasPassword = true,
      );
    final push = _FakePush(auth, active: pushActive, denied: pushDenied);
    addTearDown(push.dispose);
    final setup = SetupPromptService(prefs);

    late BuildContext captured;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<NativePushService>.value(value: push),
          Provider<InAppReviewService>.value(value: InAppReviewService(prefs)),
          Provider<SetupPromptService>.value(value: setup),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              captured = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );
    return (
      auth: auth,
      push: push,
      setup: setup,
      show: () => showSetupPromptIfDue(
        captured,
        biometricsAvailable: () async => biometrics,
      ),
    );
  }

  testWidgets('offers both settings to a user who has used the app', (
    tester,
  ) async {
    final h = await pump(tester);
    final shown = h.show();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setup-prompt-notifications')), findsOneWidget);
    expect(find.byKey(const Key('setup-prompt-biometric')), findsOneWidget);
    expect(h.setup.state.askCount, 1);

    await tester.tap(find.byKey(const Key('setup-prompt-dismiss')));
    await tester.pumpAndSettle();
    expect(await shown, true);
  });

  testWidgets('does not ask a new user', (tester) async {
    final h = await pump(tester, analyses: 1);
    expect(await h.show(), false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setup-prompt-notifications')), findsNothing);
    expect(h.setup.state.askCount, 0);
  });

  testWidgets('does not ask while the app is locked', (tester) async {
    final h = await pump(tester, locked: true);
    expect(await h.show(), false);
    expect(h.setup.state.askCount, 0);
  });

  testWidgets('skips what is already on or cannot be turned on', (
    tester,
  ) async {
    final h = await pump(tester, pushActive: true, biometrics: false);
    expect(await h.show(), false);
    expect(h.setup.state.askCount, 0);
  });

  testWidgets(
    'only offers biometrics when notifications are blocked in settings',
    (tester) async {
      final h = await pump(tester, pushDenied: true);
      final shown = h.show();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('setup-prompt-notifications')), findsNothing);
      expect(find.byKey(const Key('setup-prompt-biometric')), findsOneWidget);

      await tester.tap(find.byKey(const Key('setup-prompt-dismiss')));
      await tester.pumpAndSettle();
      await shown;
      expect(h.push.enableCalls, 0);
    },
  );

  testWidgets('turning each setting on works from the sheet', (tester) async {
    final h = await pump(tester);
    final shown = h.show();
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('setup-prompt-notifications')),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(h.push.enableCalls, 1);

    await tester.runAsync(() async {
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('setup-prompt-biometric')),
          matching: find.byType(FilledButton),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(secure['trade_pilot_biometric_lock'], 'true');
    expect(find.byType(FilledButton), findsNothing);

    await tester.tap(find.byKey(const Key('setup-prompt-dismiss')));
    await tester.pumpAndSettle();
    await shown;
  });

  testWidgets('stays readable on a narrow screen at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await pump(tester);
    final shown = h.show();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The sheet scrolls (the test font is far wider than a real one).
    await tester.ensureVisible(find.byKey(const Key('setup-prompt-dismiss')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setup-prompt-dismiss')));
    await tester.pumpAndSettle();
    await shown;
  });
}
