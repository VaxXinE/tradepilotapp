import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/screens/home/tabs/dashboard_tab.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  final summary = AnalysesSummary(
    (builder) => builder
      ..totalAnalyses = 244
      ..beginnerCount = 203
      ..proCount = 41
      ..avgConfidenceMin = 49
      ..avgConfidenceMax = 65,
  );

  testWidgets('dashboard stats stack and remain readable at 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      localizedTestApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DashboardStats(summary: summary),
            ),
          ),
        ),
      ),
    );

    final totalCard = find.byKey(const ValueKey('dashboard-stat-total'));
    final confidenceCard = find.byKey(
      const ValueKey('dashboard-stat-confidence'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('244'), findsOneWidget);
    expect(find.text('203'), findsNothing);
    expect(find.text('49–65%'), findsOneWidget);
    expect(tester.getSize(totalCard).width, greaterThan(340));
    expect(
      tester.getTopLeft(confidenceCard).dy,
      greaterThan(tester.getBottomLeft(totalCard).dy),
    );
  });

  testWidgets('dashboard stats stay compact at normal text size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DashboardStats(summary: summary),
          ),
        ),
      ),
    );

    final totalCard = find.byKey(const ValueKey('dashboard-stat-total'));
    final confidenceCard = find.byKey(
      const ValueKey('dashboard-stat-confidence'),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(totalCard).width, lessThan(190));
    expect(
      tester.getTopLeft(confidenceCard).dy,
      tester.getTopLeft(totalCard).dy,
    );
  });

  AnalysisOutcomesSummary outcomes({int pending = 0, int invalidated = 0}) =>
      AnalysisOutcomesSummary(
        (b) => b
          ..rangeDays = 30
          ..total = 12
          ..tp1Hit = 3
          ..tp2Hit = 1
          ..slHit = 2
          ..expired = 1
          ..invalidated = invalidated
          ..pending = pending
          ..scored = 6
          ..tpHitRate = 4 / 6
          ..slHitRate = 2 / 6,
      );

  testWidgets('outcome card says how many analyses are still pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: OutcomeSummaryCard(
            outcomes: outcomes(pending: 5, invalidated: 2),
          ),
        ),
      ),
    );

    expect(find.text('5 still pending · Analysis Invalidated: 2'), findsOneWidget);
  });

  testWidgets('outcome card hides the open-items line when there are none', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(body: OutcomeSummaryCard(outcomes: outcomes())),
      ),
    );

    expect(find.byKey(const ValueKey('dashboard-outcome-open')), findsNothing);
  });
}
