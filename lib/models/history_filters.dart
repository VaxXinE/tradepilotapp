enum HistoryModeFilter { all, beginner, pro }

class HistoryFilters {
  const HistoryFilters({
    this.query = '',
    this.mode = HistoryModeFilter.all,
    this.instruments = const [],
    this.timeframes = const [],
    this.from,
    this.to,
  });

  static const int maxSearchLength = 100;

  final String query;

  final HistoryModeFilter mode;

  final List<String> instruments;

  final List<String> timeframes;

  final DateTime? from;
  final DateTime? to;

  bool get isActive {
    return query.isNotEmpty ||
        mode != HistoryModeFilter.all ||
        instruments.isNotEmpty ||
        timeframes.isNotEmpty ||
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

  int get activeCategoryCount {
    var count = 0;

    if (query.isNotEmpty) {
      count++;
    }

    if (mode != HistoryModeFilter.all) {
      count++;
    }

    if (instruments.isNotEmpty) {
      count++;
    }

    if (timeframes.isNotEmpty) {
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

    final cleanInstruments = _normalizeList(instruments, uppercase: true);

    final cleanTimeframes = _normalizeList(timeframes, uppercase: false);

    return HistoryFilters(
      query: cleanQuery,
      mode: mode,
      instruments: cleanInstruments,
      timeframes: cleanTimeframes,
      from: _dateOnly(from),
      to: _dateOnly(to),
    );
  }

  HistoryFilters copyWith({
    String? query,
    HistoryModeFilter? mode,
    List<String>? instruments,
    List<String>? timeframes,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return HistoryFilters(
      query: query ?? this.query,
      mode: mode ?? this.mode,
      instruments: instruments ?? this.instruments,
      timeframes: timeframes ?? this.timeframes,
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
