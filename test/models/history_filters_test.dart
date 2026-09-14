import 'package:flutter_test/flutter_test.dart';

import 'package:tradepilotapp/models/history_filters.dart';
import 'package:tradepilotapp/models/history_sort.dart';

void main() {
  test('preserves the backend other-instruments bucket key', () {
    final filters = const HistoryFilters(
      instruments: ['__OTHER__', 'xau/usd'],
    ).normalized();

    expect(filters.instruments, ['__other__', 'XAU/USD']);
  });

  group('HistoryFilters', () {
    test('outcome filters map to distinct server statuses', () {
      const filter = HistoryFilters(
        outcome: HistoryOutcomeFilter.targetReached,
      );

      expect(filter.apiOutcome, ['tp1_hit', 'tp2_hit']);
      expect(
        const HistoryFilters(
          outcome: HistoryOutcomeFilter.riskLimitHit,
        ).apiOutcome,
        ['sl_hit'],
      );
      expect(
        const HistoryFilters(outcome: HistoryOutcomeFilter.expired).apiOutcome,
        ['expired'],
      );
      expect(
        const HistoryFilters(
          outcome: HistoryOutcomeFilter.invalidated,
        ).apiOutcome,
        ['invalidated'],
      );
    });

    test('active category count includes new filters', () {
      const filter = HistoryFilters(outcome: HistoryOutcomeFilter.pending);

      expect(filter.activeCategoryCount, 1);
    });

    test('the filter badge ignores the search query', () {
      const searchOnly = HistoryFilters(query: 'xau');

      // Pencarian punya kolom sendiri dan tidak ada di filter sheet, jadi
      // lencana tidak boleh menghitungnya.
      expect(searchOnly.activeCategoryCount, 0);
      expect(searchOnly.isActive, isTrue);

      const searchAndOutcome = HistoryFilters(
        query: 'xau',
        outcome: HistoryOutcomeFilter.pending,
      );

      expect(searchAndOutcome.activeCategoryCount, 1);
    });

    test(
      'preference payload restores allowed fields but excludes private query',
      () {
        const filter = HistoryFilters(
          query: 'private journal context',
          mode: HistoryModeFilter.pro,
          outcome: HistoryOutcomeFilter.targetReached,
          instruments: [' xau/usd '],
          timeframes: ['1h'],
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
        expect(restored.outcome, HistoryOutcomeFilter.targetReached);
        expect(restored.instruments, ['XAU/USD']);
        expect(restored.timeframes, ['1h']);
        expect(payload, isNot(contains('minConfidence')));
        expect(payload, isNot(contains('sort')));
        expect(restored.sort, HistorySort.newest);
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
