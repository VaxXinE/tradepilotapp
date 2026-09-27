import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/theme/app_theme.dart';
import 'package:tradepilotapp/widgets/app_footer.dart';

import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('footer repeats the web legal links without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      localizedTestApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: SingleChildScrollView(child: AppFooter())),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('app-footer')), findsOneWidget);
    expect(
      find.text(
        'TradePilot is a decision-support tool, not financial advice or a '
        'trading service.',
      ),
      findsOneWidget,
    );
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    for (final label in [
      'Privacy Policy',
      'Terms of Service',
      'Support',
      'Delete Account',
    ]) {
      final target = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(target).width, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('footer stays readable at a larger text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: localizedTestApp(
          theme: AppTheme.light,
          home: const Scaffold(body: SingleChildScrollView(child: AppFooter())),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
