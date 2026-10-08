import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/widgets/product_state_view.dart';

void main() {
  testWidgets('state view explains failure and exposes recovery', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductStateView(
            kind: ProductStateKind.error,
            title: 'Could not load journal',
            message: 'Your existing entries are unchanged.',
            actionLabel: 'Try again',
            onAction: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Could not load journal'), findsOneWidget);
    expect(find.text('Your existing entries are unchanged.'), findsOneWidget);

    await tester.tap(find.text('Try again'));

    expect(retried, isTrue);
  });
}
