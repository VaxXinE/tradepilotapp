import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/widgets/history/history_analysis_card.dart';

void main() {
  testWidgets('shows pending status, confidence, journal, and legacy bias', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      _analysis(
        outcome: AnalysisOutcomeStatusEnum.pending,
        bias: 'strong_buy',
        hasNote: true,
      ),
    );

    expect(find.text('Evaluation pending'), findsOneWidget);
    expect(find.text('Confidence 70–80%'), findsOneWidget);
    expect(find.text('Strong bullish'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
  });

  testWidgets('maps positive and negative retrospective outcomes', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      _analysis(outcome: AnalysisOutcomeStatusEnum.tp1Hit),
    );
    expect(find.text('Reference target 1 reached'), findsOneWidget);

    await _pumpCard(
      tester,
      _analysis(outcome: AnalysisOutcomeStatusEnum.slHit),
    );
    expect(find.text('Risk limit reached'), findsOneWidget);
  });

  testWidgets('legacy null outcome uses a safe fallback', (tester) async {
    await _pumpCard(tester, _analysis());

    expect(find.text('Not yet evaluated'), findsOneWidget);
    expect(find.textContaining('WIN'), findsNothing);
    expect(find.textContaining('PROFIT'), findsNothing);
  });
}

Future<void> _pumpCard(WidgetTester tester, Analysis analysis) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HistoryAnalysisCard(analysis: analysis, onTap: () {}),
        ),
      ),
    ),
  );
}

Analysis _analysis({
  AnalysisOutcomeStatusEnum? outcome,
  String? bias = 'neutral',
  bool hasNote = false,
}) {
  return Analysis(
    (builder) => builder
      ..id = 1
      ..userId = 1
      ..instrument = 'XAU/USD'
      ..timeframe = '1h'
      ..mode = AnalysisModeEnum.beginner
      ..validUntil = DateTime.utc(2026, 8, 24)
      ..createdAt = DateTime.utc(2026, 8, 23, 10)
      ..confidenceMin = 70
      ..confidenceMax = 80
      ..tradingBias = bias
      ..outcomeStatus = outcome
      ..hasNote = hasNote
      ..riskLevel = 'medium'
      ..marketCondition = 'trending',
  );
}
