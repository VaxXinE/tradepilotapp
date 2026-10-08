import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/history/history_statistics.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/widgets/history/history_summary_card.dart';

void main() {
  testWidgets('shows the seven web summary metrics', (tester) async {
    await _pumpSummary(tester, HistoryStatistics.fromAnalyses(const []));

    expect(find.text('Total analyses'), findsOneWidget);
    expect(find.text('Still valid'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('SL'), findsOneWidget);
    expect(find.text('TP1'), findsOneWidget);
    expect(find.text('TP2'), findsOneWidget);
    expect(find.text('Invalid'), findsOneWidget);
  });

  testWidgets('keeps TP1 and TP2 as separate metrics', (tester) async {
    const statistics = HistoryStatistics(
      total: 4,
      targetHitCount: 2,
      riskLimitHitCount: 1,
      pendingCount: 1,
      expiredCount: 0,
      invalidatedCount: 0,
      targetHitRate: 66.7,
      activeValidCount: 1,
      tp1HitCount: 1,
      tp2HitCount: 1,
    );

    await _pumpSummary(tester, statistics);

    expect(find.text('Total analyses'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(4));
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
      tester.getTopLeft(find.text('Total analyses')).dy,
      lessThan(tester.getTopLeft(find.text('Still valid')).dy),
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
