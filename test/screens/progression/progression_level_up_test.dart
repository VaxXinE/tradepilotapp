import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/progression_provider.dart';
import 'package:tradepilotapp/screens/progression/progression_screen.dart';
import 'package:tradepilotapp/widgets/progression/level_up_watcher.dart';

import '../../helpers/localized_test_app.dart';

void main() {
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

  Future<ProgressionProvider> pump(WidgetTester tester, Widget home) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final locale = LocaleController(preferences);
    addTearDown(locale.dispose);
    final auth = AuthProvider();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final progression = ProgressionProvider(auth)
      ..summary = ProgressionSummary(
        (b) => b
          ..totalXp = 60
          ..level = 2
          ..masteryLevel = 0
          ..rank = 'seedling'
          ..currentLevelXp = 50
          ..nextLevelXp = 110
          ..currentStreak = 1
          ..longestStreak = 3,
      );
    addTearDown(progression.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
          ChangeNotifierProvider<ProgressionProvider>.value(value: progression),
        ],
        child: localizedTestApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
    return progression;
  }

  testWidgets('the progression hero says how to reach the next level', (
    tester,
  ) async {
    await pump(tester, const ProgressionScreen());

    expect(
      find.text(
        'Small, consistent actions earn XP. You need 50 XP for the next level.',
      ),
      findsOneWidget,
    );
    expect(find.text('Write a short journal reflection'), findsNothing);

    await tester.tap(find.text('How to level up'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Write a short journal reflection'),
      findsOneWidget,
    );
    expect(find.textContaining('20 XP · up to 2/day'), findsOneWidget);
    expect(
      find.textContaining('Evaluate an analysis without adding a note'),
      findsOneWidget,
    );
    expect(find.textContaining('Keep your daily streak'), findsOneWidget);
  });

  testWidgets('a level reached in this session is celebrated once', (
    tester,
  ) async {
    final progression = await pump(
      tester,
      const ProgressionLevelUpWatcher(child: Scaffold(body: Text('app'))),
    );
    expect(
      find.byKey(const ValueKey('progression-level-up-dialog')),
      findsNothing,
    );

    progression
      ..celebrationLevel = 4
      ..notifyListeners();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('progression-level-up-dialog')),
      findsOneWidget,
    );
    expect(find.text('Congratulations! You reached Level 4!'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('progression-level-up-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('progression-level-up-dialog')),
      findsNothing,
    );
    expect(progression.celebrationLevel, isNull);
  });
}
