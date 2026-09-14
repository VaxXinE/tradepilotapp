import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/providers/analysis_provider.dart';
import 'package:tradepilotapp/widgets/analysis_quota_dialog.dart';

void main() {
  testWidgets('renders hour, day, and concurrent quota actions', (
    tester,
  ) async {
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
      ('hour', 'Hourly limit reached', false),
      ('day', 'Daily limit reached', true),
      ('concurrent', 'Analysis still in progress', false),
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
      expect(find.text('Used 5 of 5'), findsOneWidget);
      expect(find.text('Try again in 30 seconds'), findsOneWidget);
      expect(
        find.text('Top Up Credit'),
        testCase.$3 ? findsOneWidget : findsNothing,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(await future, isFalse);
    }
  });
}
