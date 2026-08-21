import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

class HistoryStatistics {
  const HistoryStatistics({
    required this.total,
    required this.successCount,
    required this.failedCount,
    required this.pendingCount,
    required this.successRate,
    required this.averageConfidence,
  });

  final int total;

  final int successCount;

  final int failedCount;

  final int pendingCount;

  final double successRate;

  final double averageConfidence;

  factory HistoryStatistics.fromAnalyses(List<Analysis> analyses) {
    if (analyses.isEmpty) {
      return const HistoryStatistics(
        total: 0,
        successCount: 0,
        failedCount: 0,
        pendingCount: 0,
        successRate: 0,
        averageConfidence: 0,
      );
    }

    var success = 0;
    var failed = 0;
    var pending = 0;

    var confidenceTotal = 0;
    var confidenceCount = 0;

    for (final analysis in analyses) {
      switch (analysis.outcomeStatus) {
        case AnalysisOutcomeStatusEnum.tp1Hit:
        case AnalysisOutcomeStatusEnum.tp2Hit:
          success++;
          break;

        case AnalysisOutcomeStatusEnum.slHit:
        case AnalysisOutcomeStatusEnum.expired:
        case AnalysisOutcomeStatusEnum.invalidated:
          failed++;
          break;

        case AnalysisOutcomeStatusEnum.pending:
        case null:
          pending++;
          break;
      }

      if (analysis.confidenceMin != null && analysis.confidenceMax != null) {
        final avg = (analysis.confidenceMin! + analysis.confidenceMax!) / 2;

        confidenceTotal += avg.round();
        confidenceCount++;
      }
    }

    final resolved = success + failed;

    return HistoryStatistics(
      total: analyses.length,
      successCount: success,
      failedCount: failed,
      pendingCount: pending,
      successRate: resolved == 0 ? 0 : (success / resolved) * 100,
      averageConfidence: confidenceCount == 0
          ? 0
          : confidenceTotal / confidenceCount,
    );
  }
}
