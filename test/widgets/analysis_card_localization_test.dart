import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/l10n/l10n.dart';
import 'package:tradepilotapp/widgets/analysis_card.dart';

void main() {
  testWidgets('uses the selected locale for analysis status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AnalysisCard(analysis: _analysis(), onTap: () {}),
        ),
      ),
    );

    expect(find.text('Neutral'), findsOneWidget);
    expect(find.textContaining('Analysis window expired at'), findsOneWidget);
    expect(find.text('Netral'), findsNothing);
    expect(find.textContaining('Jendela analisis berakhir'), findsNothing);
  });

  testWidgets('explains confidence and active analysis window', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: AnalysisCard(
              analysis: _analysis(
                validUntil: DateTime.utc(2100),
                confidenceMin: 50,
                confidenceMax: 65,
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('AI Confidence: 50–65%'), findsOneWidget);
    expect(find.textContaining('Analysis window active until'), findsOneWidget);
    expect(find.text('Valid'), findsNothing);
  });
}

Analysis _analysis({
  DateTime? validUntil,
  int? confidenceMin,
  int? confidenceMax,
}) => $Analysis(
  (builder) => builder
    ..id = 1
    ..userId = 1
    ..instrument = 'BTC/USD'
    ..timeframe = '1h'
    ..mode = AnalysisModeEnum.beginner
    ..validUntil = validUntil ?? DateTime.utc(2020)
    ..createdAt = DateTime.utc(2020)
    ..tradingBias = 'neutral'
    ..confidenceMin = confidenceMin
    ..confidenceMax = confidenceMax,
);
