import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/models/market_context.dart';
import 'package:tradepilotapp/models/technical_summary.dart';
import 'package:tradepilotapp/widgets/technical/technical_summary_card.dart';

void main() {
  const bullish = TechnicalSummary(
    trend: MarketTrend.bullish,
    momentum: MarketLevel.medium,
    volatility: MarketLevel.low,
    explanation: '3 dari 4 indikator saat ini mendukung kenaikan.',
    riskLevel: MarketLevel.medium,
  );

  const bearish = TechnicalSummary(
    trend: MarketTrend.bearish,
    momentum: MarketLevel.high,
    volatility: MarketLevel.high,
    explanation: '2 dari 3 indikator saat ini mendukung penurunan.',
    riskLevel: MarketLevel.high,
  );

  testWidgets('renders a positive (bullish) summary', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TechnicalSummaryCard(summary: bullish)),
      ),
    );

    expect(find.text('Bullish'), findsOneWidget);
    expect(
      find.text('3 dari 4 indikator saat ini mendukung kenaikan.'),
      findsOneWidget,
    );
    expect(find.text('Sedang'), findsNWidgets(2));
  });

  testWidgets('renders a negative (bearish) summary', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TechnicalSummaryCard(summary: bearish)),
      ),
    );

    expect(find.text('Bearish'), findsOneWidget);
    expect(find.text('Tinggi'), findsNWidgets(2));
  });

  testWidgets('shows an empty state when there is no technical data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TechnicalSummaryCard(summary: null)),
      ),
    );

    expect(
      find.text('Ringkasan teknikal belum tersedia untuk market ini.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a loading indicator while data is not yet available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TechnicalSummaryCard(summary: null, isLoading: true),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a retry action on error', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnicalSummaryCard(
            summary: null,
            hasError: true,
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Ringkasan teknikal belum dapat dimuat.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));

    expect(retried, isTrue);
  });
}
