import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import 'package:tradepilotapp/core/history/history_statistics.dart';

void main() {
  test('calculates success rate correctly', () {
    final analyses = [
      Analysis(
        (b) => b
          ..id = 1
          ..userId = 1
          ..instrument = 'XAU/USD'
          ..timeframe = '1h'
          ..mode = AnalysisModeEnum.beginner
          ..validUntil = DateTime.now()
          ..createdAt = DateTime.now()
          ..outcomeStatus = AnalysisOutcomeStatusEnum.tp1Hit
          ..confidenceMin = 70
          ..confidenceMax = 80,
      ),

      Analysis(
        (b) => b
          ..id = 2
          ..userId = 1
          ..instrument = 'BTC/USD'
          ..timeframe = '1h'
          ..mode = AnalysisModeEnum.beginner
          ..validUntil = DateTime.now()
          ..createdAt = DateTime.now()
          ..outcomeStatus = AnalysisOutcomeStatusEnum.slHit
          ..confidenceMin = 60
          ..confidenceMax = 70,
      ),
    ];

    final stats = HistoryStatistics.fromAnalyses(analyses);

    expect(stats.total, 2);
    expect(stats.successCount, 1);
    expect(stats.failedCount, 1);
    expect(stats.successRate, 50);
    expect(stats.averageConfidence, 70);
  });

  test('empty list returns zero statistics', () {
    final stats = HistoryStatistics.fromAnalyses([]);

    expect(stats.total, 0);
    expect(stats.successRate, 0);
    expect(stats.averageConfidence, 0);
  });
}
