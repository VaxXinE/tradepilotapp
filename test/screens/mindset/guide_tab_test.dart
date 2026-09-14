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

  testWidgets('guide tab drops the app bar and offers category filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Guide Center'), findsOneWidget);
    expect(find.text('Knowledge, features, and mindset.'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);

    // Filtering by a category keeps only that category's cards on screen.
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Glossary'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Glossary'));
    await tester.pumpAndSettle();

    expect(find.text('Common Trading Terms'), findsOneWidget);
    expect(find.text('FOMO — Trading Late on a Move'), findsNothing);
  });
}
