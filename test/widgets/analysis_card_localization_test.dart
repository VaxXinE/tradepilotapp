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
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Netral'), findsNothing);
    expect(find.text('Kedaluwarsa'), findsNothing);
  });
}

Analysis _analysis() => Analysis(
  (builder) => builder
    ..id = 1
    ..userId = 1
    ..instrument = 'BTC/USD'
    ..timeframe = '1h'
    ..mode = AnalysisModeEnum.beginner
    ..validUntil = DateTime.utc(2020)
    ..createdAt = DateTime.utc(2020)
    ..tradingBias = 'neutral',
);
