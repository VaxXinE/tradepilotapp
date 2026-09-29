import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/widgets/history/history_analysis_card.dart';

void main() {
  testWidgets('shows the compact web history row', (tester) async {
    await _pumpCard(
      tester,
      _analysis(
        outcome: AnalysisOutcomeStatusEnum.pending,
        bias: 'strong_buy',
        hasNote: true,
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget);
    expect(find.text('Confidence 70–80%'), findsNothing);
    expect(find.text('Strong bullish'), findsNothing);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
  });

  testWidgets('maps positive and negative retrospective outcomes', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      _analysis(outcome: AnalysisOutcomeStatusEnum.tp1Hit),
    );
    expect(find.text('TP1 Hit'), findsOneWidget);

    await _pumpCard(
      tester,
      _analysis(outcome: AnalysisOutcomeStatusEnum.slHit),
    );
    expect(find.text('SL Hit'), findsOneWidget);
  });

  testWidgets('legacy null outcome uses a safe fallback', (tester) async {
    await _pumpCard(tester, _analysis());

    expect(find.text('Not yet evaluated'), findsOneWidget);
    expect(find.textContaining('WIN'), findsNothing);
    expect(find.textContaining('PROFIT'), findsNothing);
  });

  testWidgets('uses the web re-analyze action', (tester) async {
    var tapped = false;
    await _pumpCard(tester, _analysis(), onReanalyze: () => tapped = true);

    await tester.tap(find.text('Re-analyze'));

    expect(tapped, isTrue);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
  });

  testWidgets('keeps the compact row readable at 200% text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpCard(
      tester,
      _analysis(outcome: AnalysisOutcomeStatusEnum.expired),
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Trending'), findsOneWidget);
  });
}

Future<void> _pumpCard(
  WidgetTester tester,
  Analysis analysis, {
  TextScaler textScaler = TextScaler.noScaling,
  VoidCallback? onReanalyze,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            child: HistoryAnalysisCard(
              analysis: analysis,
              onTap: () {},
              onReanalyze: onReanalyze,
            ),
          ),
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
  return $Analysis(
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
