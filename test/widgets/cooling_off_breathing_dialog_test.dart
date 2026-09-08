import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/widgets/cooling_off_breathing_dialog.dart';

import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('cooling-off dialog animates phases and requires a choice', (
    tester,
  ) async {
    var waited = false;
    var continued = false;

    await tester.pumpWidget(
      localizedTestApp(
        home: CoolingOffBreathingDialog(
          lossPercent: '2.5',
          onWait: () => waited = true,
          onContinue: () => continued = true,
        ),
      ),
    );

    expect(find.textContaining('Breathe in'), findsOneWidget);
    expect(find.textContaining('2.5%'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.textContaining('Hold'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cooling-off-wait')));
    expect(waited, isTrue);
    expect(continued, isFalse);
  });
}
