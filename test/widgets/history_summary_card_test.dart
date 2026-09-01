import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/history/history_statistics.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/widgets/history/history_summary_card.dart';

void main() {
  testWidgets('shows an empty loaded-history summary', (tester) async {
    await _pumpSummary(
      tester,
      HistoryStatistics.fromAnalyses(const []),
      isPartial: false,
    );

    expect(find.text('History summary'), findsOneWidget);
    expect(find.text('Positive'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('shows evaluated metrics and partial-page wording', (
    tester,
  ) async {
    const statistics = HistoryStatistics(
      total: 4,
      successCount: 2,
      failedCount: 1,
      pendingCount: 1,
      successRate: 66.7,
      averageConfidence: 74.5,
    );

    await _pumpSummary(tester, statistics, isPartial: true);

    expect(find.text('Partial summary'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(
      find.textContaining('positive outcomes from evaluated analyses'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpSummary(
  WidgetTester tester,
  HistoryStatistics statistics, {
  required bool isPartial,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HistorySummaryCard(statistics: statistics, isPartial: isPartial),
      ),
    ),
  );
}
