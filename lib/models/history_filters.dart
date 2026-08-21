enum HistoryModeFilter { all, beginner, pro }

enum HistoryOutcomeFilter { all, success, failed, pending }

class HistoryFilters {
  const HistoryFilters({
    this.query = '',
    this.mode = HistoryModeFilter.all,
    this.outcome = HistoryOutcomeFilter.all,
    this.instruments = const [],
    this.timeframes = const [],
    this.minConfidence,
    this.from,
    this.to,
  });

  static const int maxSearchLength = 100;

  final String query;

  final HistoryModeFilter mode;

  final HistoryOutcomeFilter outcome;

  final List<String> instruments;

  final List<String> timeframes;

  final int? minConfidence;

  final DateTime? from;

  final DateTime? to;

  bool get isActive {
    return query.isNotEmpty ||
        mode != HistoryModeFilter.all ||
        outcome != HistoryOutcomeFilter.all ||
        instruments.isNotEmpty ||
        timeframes.isNotEmpty ||
        minConfidence != null ||
        from != null ||
        to != null;
  }

  String? get apiMode {
    switch (mode) {
      case HistoryModeFilter.beginner:
        return 'beginner';

      case HistoryModeFilter.pro:
        return 'pro';

      case HistoryModeFilter.all:
        return null;
    }
  }

  List<String>? get apiOutcome {
    switch (outcome) {
      case HistoryOutcomeFilter.success:
        return ['tp1_hit', 'tp2_hit'];

      case HistoryOutcomeFilter.failed:
        return ['sl_hit', 'expired', 'invalidated'];

      case HistoryOutcomeFilter.pending:
        return ['pending'];

      case HistoryOutcomeFilter.all:
        return null;
    }
  }

  int get activeCategoryCount {
    var count = 0;

    if (query.isNotEmpty) {
      count++;
    }

    if (mode != HistoryModeFilter.all) {
      count++;
    }

    if (outcome != HistoryOutcomeFilter.all) {
      count++;
    }

    if (instruments.isNotEmpty) {
      count++;
    }

    if (timeframes.isNotEmpty) {
      count++;
    }

    if (minConfidence != null) {
      count++;
    }

    if (from != null || to != null) {
      count++;
    }

    return count;
  }

  HistoryFilters normalized() {
    var cleanQuery = query.trim();

    if (cleanQuery.length > maxSearchLength) {
      cleanQuery = cleanQuery.substring(0, maxSearchLength);
    }

    var cleanConfidence = minConfidence;

    if (cleanConfidence != null) {
      cleanConfidence = cleanConfidence.clamp(0, 100);
    }

    return HistoryFilters(
      query: cleanQuery,
      mode: mode,
      outcome: outcome,
      instruments: _normalizeList(instruments, uppercase: true),
      timeframes: _normalizeList(timeframes, uppercase: false),
      minConfidence: cleanConfidence,
      from: _dateOnly(from),
      to: _dateOnly(to),
    );
  }

  HistoryFilters copyWith({
    String? query,
    HistoryModeFilter? mode,
    HistoryOutcomeFilter? outcome,
    List<String>? instruments,
    List<String>? timeframes,
    int? minConfidence,
    DateTime? from,
    DateTime? to,
    bool clearConfidence = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return HistoryFilters(
      query: query ?? this.query,
      mode: mode ?? this.mode,
      outcome: outcome ?? this.outcome,
      instruments: instruments ?? this.instruments,
      timeframes: timeframes ?? this.timeframes,
      minConfidence: clearConfidence
          ? null
          : minConfidence ?? this.minConfidence,
      from: clearFrom ? null : from ?? this.from,
      to: clearTo ? null : to ?? this.to,
    );
  }

  static List<String> _normalizeList(
    List<String> values, {
    required bool uppercase,
  }) {
    final result = <String>[];

    final seen = <String>{};

    for (final raw in values) {
      var value = raw.trim();

      if (uppercase) {
        value = value.toUpperCase();
      }

      if (value.isEmpty || seen.contains(value)) {
        continue;
      }

      seen.add(value);
      result.add(value);
    }

    return result;
  }

  static DateTime? _dateOnly(DateTime? value) {
    if (value == null) {
      return null;
    }

    return DateTime(value.year, value.month, value.day);
  }
}
