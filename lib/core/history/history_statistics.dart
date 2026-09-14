import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

class HistoryStatistics {
  const HistoryStatistics({
    required this.total,
    required this.targetHitCount,
    required this.riskLimitHitCount,
    required this.pendingCount,
    required this.expiredCount,
    required this.invalidatedCount,
    required this.targetHitRate,
  });

  final int total;

  final int targetHitCount;

  final int riskLimitHitCount;

  final int pendingCount;

  final int expiredCount;

  final int invalidatedCount;

  final double targetHitRate;

  factory HistoryStatistics.fromAnalyses(List<Analysis> analyses) {
    if (analyses.isEmpty) {
      return const HistoryStatistics(
        total: 0,
        targetHitCount: 0,
        riskLimitHitCount: 0,
        pendingCount: 0,
        expiredCount: 0,
        invalidatedCount: 0,
        targetHitRate: 0,
      );
    }

    var targetHit = 0;
    var riskLimitHit = 0;
    var pending = 0;
    var expired = 0;
    var invalidated = 0;

    for (final analysis in analyses) {
      switch (analysis.outcomeStatus) {
        case AnalysisOutcomeStatusEnum.tp1Hit:
        case AnalysisOutcomeStatusEnum.tp2Hit:
          targetHit++;
          break;

        case AnalysisOutcomeStatusEnum.slHit:
          riskLimitHit++;
          break;

        case AnalysisOutcomeStatusEnum.expired:
          expired++;
          break;

        case AnalysisOutcomeStatusEnum.invalidated:
          invalidated++;
          break;

        case AnalysisOutcomeStatusEnum.pending:
        case null:
          pending++;
          break;
      }
    }

    final evaluated = targetHit + riskLimitHit;

    return HistoryStatistics(
      total: analyses.length,
      targetHitCount: targetHit,
      riskLimitHitCount: riskLimitHit,
      pendingCount: pending,
      expiredCount: expired,
      invalidatedCount: invalidated,
      targetHitRate: evaluated == 0 ? 0 : (targetHit / evaluated) * 100,
    );
  }

  factory HistoryStatistics.fromOutcomeStats(
    AnalysisHistoryOutcomeStats stats,
  ) {
    final targetHit = stats.tp1Hit + stats.tp2Hit;
    final evaluated = targetHit + stats.slHit;

    return HistoryStatistics(
      total: stats.total,
      targetHitCount: targetHit,
      riskLimitHitCount: stats.slHit,
      pendingCount: stats.pending,
      expiredCount: stats.expired,
      invalidatedCount: stats.invalidated,
      targetHitRate: evaluated == 0 ? 0 : (targetHit / evaluated) * 100,
    );
  }
}
