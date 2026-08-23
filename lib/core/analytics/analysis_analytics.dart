import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

class AnalysisAnalytics {
  const AnalysisAnalytics({
    required this.total,
    required this.evaluated,
    required this.pending,
    required this.positiveOutcomes,
    required this.negativeOutcomes,
    required this.journaled,
    required this.averageConfidence,
    required this.topInstrument,
    required this.topTimeframe,
    required this.isPartial,
  });

  factory AnalysisAnalytics.from(
    Iterable<Analysis> source, {
    required int serverTotal,
  }) {
    final analyses = source.toList(growable: false);
    var evaluated = 0;
    var pending = 0;
    var positive = 0;
    var negative = 0;
    var journaled = 0;
    var confidenceTotal = 0.0;
    var confidenceCount = 0;
    final instruments = <String, int>{};
    final timeframes = <String, int>{};

    for (final analysis in analyses) {
      final outcome = analysis.outcomeStatus?.name;
      if (outcome == null || outcome == 'pending') {
        pending++;
      } else {
        evaluated++;
        if (outcome == 'tp1Hit' || outcome == 'tp2Hit') {
          positive++;
        } else {
          negative++;
        }
      }
      if (analysis.hasNote == true) journaled++;
      final min = analysis.confidenceMin;
      final max = analysis.confidenceMax;
      if (min != null || max != null) {
        confidenceTotal += ((min ?? max)! + (max ?? min)!) / 2;
        confidenceCount++;
      }
      instruments.update(
        analysis.instrument,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      timeframes.update(
        analysis.timeframe,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    String? top(Map<String, int> counts) {
      if (counts.isEmpty) return null;
      final entries = counts.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          return byCount != 0 ? byCount : a.key.compareTo(b.key);
        });
      return entries.first.key;
    }

    return AnalysisAnalytics(
      total: analyses.length,
      evaluated: evaluated,
      pending: pending,
      positiveOutcomes: positive,
      negativeOutcomes: negative,
      journaled: journaled,
      averageConfidence: confidenceCount == 0
          ? null
          : confidenceTotal / confidenceCount,
      topInstrument: top(instruments),
      topTimeframe: top(timeframes),
      isPartial: serverTotal > analyses.length,
    );
  }

  final int total;
  final int evaluated;
  final int pending;
  final int positiveOutcomes;
  final int negativeOutcomes;
  final int journaled;
  final double? averageConfidence;
  final String? topInstrument;
  final String? topTimeframe;
  final bool isPartial;
}
