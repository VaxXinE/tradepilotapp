import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/widgets/analysis_quota_dialog.dart';

void main() {
  testWidgets('renders daily and concurrent quota actions', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    for (final testCase in [
      ('day', "You're Out of Credits"),
      ('concurrent', 'Analysis still in progress'),
    ]) {
      final future = showAnalysisQuotaDialog(
        navigatorKey.currentContext!,
        AnalysisQuotaLimit(
          scope: testCase.$1,
          used: 5,
          limit: 5,
          retryAfter: const Duration(seconds: 30),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testCase.$2), findsOneWidget);
      // The daily limit counts every analysis ever made, so no "used X of Y".
      expect(
        find.text('Used 5 of 5'),
        testCase.$1 == 'day' ? findsNothing : findsOneWidget,
      );
      expect(find.text('Try again in 30 seconds'), findsOneWidget);
      expect(find.byKey(const Key('quota-dialog-top-up')), findsNothing);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await future;
    }
  });

  Future<GlobalKey<NavigatorState>> pumpHost(WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    return navigatorKey;
  }

  testWidgets('offers top-up when the daily limit is reached', (tester) async {
    final navigatorKey = await pumpHost(tester);
    var topUps = 0;

    final future = showAnalysisQuotaDialog(
      navigatorKey.currentContext!,
      const AnalysisQuotaLimit(scope: 'day', used: 5, limit: 5),
      onTopUp: () async => topUps++,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quota-dialog-top-up')), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    await tester.tap(find.byKey(const Key('quota-dialog-top-up')));
    await tester.pumpAndSettle();
    await future;

    expect(find.byType(AlertDialog), findsNothing);
    expect(topUps, 1);
  });

  testWidgets('does not offer top-up when it would not help', (tester) async {
    final navigatorKey = await pumpHost(tester);

    final future = showAnalysisQuotaDialog(
      navigatorKey.currentContext!,
      const AnalysisQuotaLimit(scope: 'concurrent', used: 1, limit: 1),
      onTopUp: () async {},
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quota-dialog-top-up')), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await future;
  });
}
