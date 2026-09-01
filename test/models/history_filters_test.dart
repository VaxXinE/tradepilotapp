import 'package:flutter_test/flutter_test.dart';

import 'package:tradepilotapp/models/history_filters.dart';
import 'package:tradepilotapp/models/history_sort.dart';

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

    test(
      'preference payload restores allowed fields but excludes private query',
      () {
        const filter = HistoryFilters(
          query: 'private journal context',
          mode: HistoryModeFilter.pro,
          outcome: HistoryOutcomeFilter.failed,
          instruments: [' xau/usd '],
          timeframes: ['1h'],
          minConfidence: 70,
          sort: HistorySort.confidenceHighest,
          from: null,
          to: null,
        );

        final payload = filter.toPreferencesJson();
        final restored = HistoryFilters.fromPreferencesJson(payload);

        expect(payload, isNot(contains('query')));
        expect(payload, isNot(contains('from')));
        expect(restored.query, isEmpty);
        expect(restored.mode, HistoryModeFilter.pro);
        expect(restored.outcome, HistoryOutcomeFilter.failed);
        expect(restored.instruments, ['XAU/USD']);
        expect(restored.timeframes, ['1h']);
        expect(restored.minConfidence, 70);
        expect(restored.sort, HistorySort.confidenceHighest);
      },
    );

    test(
      'corrupted preference values safely fall back and clamp confidence',
      () {
        final restored = HistoryFilters.fromPreferencesJson({
          'version': 1,
          'mode': 'removed_mode',
          'outcome': 123,
          'instruments': [' btc/usd ', 7],
          'minConfidence': 150,
          'sort': 'removed_sort',
        });

        expect(restored.mode, HistoryModeFilter.all);
        expect(restored.outcome, HistoryOutcomeFilter.all);
        expect(restored.instruments, ['BTC/USD']);
        expect(restored.minConfidence, 100);
        expect(restored.sort, HistorySort.newest);
      },
    );

    test('sort alone is not counted as an active filter', () {
      const filter = HistoryFilters(sort: HistorySort.oldest);

      expect(filter.isActive, isFalse);
      expect(filter.activeCategoryCount, 0);
      expect(filter.hasServerFilters, isFalse);
    });
  });
}
