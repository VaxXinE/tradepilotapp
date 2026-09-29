import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradepilotapp/core/localization/locale_controller.dart';
import 'package:tradepilotapp/core/theme/app_theme.dart';
import 'package:tradepilotapp/screens/mindset/mindset_screen.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guide tab matches web flow and supports large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: LocaleController(preferences),
        child: localizedTestApp(
          theme: AppTheme.dark,
          home: const MindsetScreen(embedded: true),
        ),
      ),
    );
    await _pumpGuide(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Guide Center'), findsOneWidget);
    expect(find.text('Knowledge, features, and mindset.'), findsOneWidget);
    expect(
      find.text('Begin with the most important workflows.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);

    // Filtering by a category keeps only that category's cards on screen.
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Glossary'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Glossary'));
    await tester.pumpAndSettle();

    expect(find.text('Common Trading Terms'), findsOneWidget);
    expect(find.text('FOMO — Trading Late on a Move'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'How We Handle Your Data');
    await tester.pump();
    await tester.tap(find.text('How We Handle Your Data').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Back to Guide'), findsOneWidget);
    expect(find.text('DATA & PRIVACY'), findsOneWidget);
  });
}

Future<void> _pumpGuide(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(TextField).evaluate().isNotEmpty) return;
  }
}
