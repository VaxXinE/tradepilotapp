import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import 'package:tradepilotapp/core/history/history_statistics.dart';

void main() {
  test('calculates success rate correctly', () {
    final analyses = [
      $Analysis(
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

      $Analysis(
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
    expect(stats.targetHitCount, 1);
    expect(stats.riskLimitHitCount, 1);
    expect(stats.targetHitRate, 50);
    expect(stats.expiredCount, 0);
    expect(stats.invalidatedCount, 0);
  });

  test('empty list returns zero statistics', () {
    final stats = HistoryStatistics.fromAnalyses([]);

    expect(stats.total, 0);
    expect(stats.targetHitRate, 0);
  });

  test('expired and invalidated outcomes are not counted as failures', () {
    final analyses = [
      for (final entry in const [
        (1, AnalysisOutcomeStatusEnum.expired),
        (2, AnalysisOutcomeStatusEnum.invalidated),
      ])
        $Analysis(
          (b) => b
            ..id = entry.$1
            ..userId = 1
            ..instrument = 'XAU/USD'
            ..timeframe = '1h'
            ..mode = AnalysisModeEnum.beginner
            ..validUntil = DateTime.now()
            ..createdAt = DateTime.now()
            ..outcomeStatus = entry.$2,
        ),
    ];

    final stats = HistoryStatistics.fromAnalyses(analyses);

    expect(stats.riskLimitHitCount, 0);
    expect(stats.expiredCount, 1);
    expect(stats.invalidatedCount, 1);
  });

  test('maps the server aggregate for the complete history', () {
    final aggregate = $AnalysisHistoryOutcomeStats(
      (builder) => builder
        ..total = 340
        ..pending = 20
        ..activeValid = 12
        ..tp1Hit = 100
        ..tp2Hit = 40
        ..slHit = 80
        ..expired = 60
        ..invalidated = 40
        ..winRate = 140 / 220
        ..completionRate = 0.5,
    );

    final stats = HistoryStatistics.fromOutcomeStats(aggregate);

    expect(stats.total, 340);
    expect(stats.targetHitCount, 140);
    expect(stats.riskLimitHitCount, 80);
    expect(stats.pendingCount, 20);
    expect(stats.expiredCount, 60);
    expect(stats.invalidatedCount, 40);
  });
}
