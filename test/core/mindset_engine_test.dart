import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/core/mindset/mindset_engine.dart';

void main() {
  const engine = MindsetEngine();

  test('insufficient samples produce no insight', () {
    expect(engine.evaluate([_analysis(1), _analysis(2)]), isEmpty);
  });

  test('insights use deterministic ordering and evidence thresholds', () {
    final insights = engine.evaluate([
      _analysis(1, minute: 0),
      _analysis(2, minute: 20),
      _analysis(3, minute: 40),
      _analysis(4, instrument: 'EUR/USD', minute: 80),
    ]);

    expect(insights.map((item) => item.type), [
      MindsetInsightType.frequency,
      MindsetInsightType.concentration,
      MindsetInsightType.pending,
      MindsetInsightType.journal,
    ]);
    final copy = insights.map((item) => item.message).join(' ').toLowerCase();
    expect(copy, isNot(contains('kecanduan')));
    expect(copy, isNot(contains('jaminan')));
  });
}

Analysis _analysis(int id, {String instrument = 'XAU/USD', int minute = 0}) =>
    Analysis(
      (builder) => builder
        ..id = id
        ..userId = 1
        ..instrument = instrument
        ..timeframe = '1h'
        ..mode = AnalysisModeEnum.beginner
        ..validUntil = DateTime.utc(2026, 8, 25)
        ..createdAt = DateTime.utc(
          2026,
          8,
          23,
          8,
        ).add(Duration(minutes: minute))
        ..outcomeStatus = AnalysisOutcomeStatusEnum.pending
        ..hasNote = false,
    );
