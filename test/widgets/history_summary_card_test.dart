import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/history/history_statistics.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/widgets/history/history_summary_card.dart';

void main() {
  testWidgets('shows an empty all-history summary', (tester) async {
    await _pumpSummary(tester, HistoryStatistics.fromAnalyses(const []));

    expect(find.text('All analysis summary'), findsOneWidget);
    expect(find.text('Target reached'), findsOneWidget);
    expect(find.text('Cannot be evaluated'), findsOneWidget);
  });

  testWidgets('shows evaluated metrics for all history', (tester) async {
    const statistics = HistoryStatistics(
      total: 4,
      targetHitCount: 2,
      riskLimitHitCount: 1,
      pendingCount: 1,
      expiredCount: 0,
      invalidatedCount: 0,
      targetHitRate: 66.7,
    );

    await _pumpSummary(tester, statistics);

    expect(find.text('All analysis summary'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.textContaining('Targets were reached'), findsOneWidget);
  });

  testWidgets('stacks summary metrics at 200% text without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const statistics = HistoryStatistics(
      total: 12,
      targetHitCount: 5,
      riskLimitHitCount: 3,
      pendingCount: 4,
      expiredCount: 0,
      invalidatedCount: 0,
      targetHitRate: 62.5,
    );
    await _pumpSummary(
      tester,
      statistics,
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Evaluated')).dy,
      lessThan(tester.getTopLeft(find.text('Pending')).dy),
    );
  });
}

Future<void> _pumpSummary(
  WidgetTester tester,
  HistoryStatistics statistics, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            child: HistorySummaryCard(statistics: statistics),
          ),
        ),
      ),
    ),
  );
}
