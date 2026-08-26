import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/history/history_statistics.dart';
import 'package:tradepilotapp/widgets/history/history_summary_card.dart';

void main() {
  testWidgets('shows an empty loaded-history summary', (tester) async {
    await _pumpSummary(
      tester,
      HistoryStatistics.fromAnalyses(const []),
      isPartial: false,
    );

    expect(find.text('Ringkasan riwayat'), findsOneWidget);
    expect(find.text('Positif'), findsOneWidget);
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

    expect(find.text('Ringkasan sementara'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(
      find.textContaining(
        'outcome positif dari analisis yang sudah dievaluasi',
      ),
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
      home: Scaffold(
        body: HistorySummaryCard(statistics: statistics, isPartial: isPartial),
      ),
    ),
  );
}
