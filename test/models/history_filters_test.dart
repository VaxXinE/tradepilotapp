import 'package:flutter_test/flutter_test.dart';

import 'package:tradepilotapp/models/history_filters.dart';

void main() {
  group('HistoryFilters', () {
    test('outcome filter maps success correctly', () {
      const filter = HistoryFilters(outcome: HistoryOutcomeFilter.success);

      expect(filter.apiOutcome, ['tp1_hit', 'tp2_hit']);
    });

    test('confidence normalized between 0-100', () {
      const filter = HistoryFilters(minConfidence: 150);

      final result = filter.normalized();

      expect(result.minConfidence, 100);
    });

    test('active category count includes new filters', () {
      const filter = HistoryFilters(
        outcome: HistoryOutcomeFilter.pending,
        minConfidence: 70,
      );

      expect(filter.activeCategoryCount, 2);
    });
  });
}
