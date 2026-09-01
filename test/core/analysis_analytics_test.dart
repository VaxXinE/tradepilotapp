import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/analytics/analysis_analytics.dart';

void main() {
  test('empty and partial datasets remain explicit', () {
    final analytics = AnalysisAnalytics.from(const [], serverTotal: 4);
    expect(analytics.total, 0);
    expect(analytics.averageConfidence, isNull);
    expect(analytics.isPartial, isTrue);
  });

  test('aggregates outcomes, confidence, instrument, timeframe and notes', () {
    final analytics = AnalysisAnalytics.from([
      _analysis(1, 'XAU/USD', '1h', 'pending', 60, 80, true),
      _analysis(2, 'XAU/USD', '4h', 'tp1Hit', 70, 90, false),
      _analysis(3, 'EUR/USD', '1h', 'slHit', 50, 70, false),
    ], serverTotal: 3);

    expect(analytics.evaluated, 2);
    expect(analytics.pending, 1);
    expect(analytics.positiveOutcomes, 1);
    expect(analytics.negativeOutcomes, 1);
    expect(analytics.averageConfidence, 70);
    expect(analytics.topInstrument, 'XAU/USD');
    expect(analytics.topTimeframe, '1h');
    expect(analytics.journaled, 1);
    expect(analytics.isPartial, isFalse);
  });
}

Analysis _analysis(
  int id,
  String instrument,
  String timeframe,
  String outcome,
  int min,
  int max,
  bool hasNote,
) => Analysis(
  (builder) => builder
    ..id = id
    ..userId = 1
    ..instrument = instrument
    ..timeframe = timeframe
    ..mode = AnalysisModeEnum.beginner
    ..validUntil = DateTime.utc(2026, 8, 25)
    ..createdAt = DateTime.utc(2026, 8, 23, id)
    ..outcomeStatus = AnalysisOutcomeStatusEnum.valueOf(outcome)
    ..confidenceMin = min
    ..confidenceMax = max
    ..hasNote = hasNote,
);
