import 'history_sort.dart';

enum HistoryModeFilter { all, beginner, pro }

enum HistoryOutcomeFilter {
  all,
  pending,
  targetReached,
  riskLimitHit,
  expired,
  invalidated,
}

class HistoryFilters {
  const HistoryFilters({
    this.query = '',
    this.mode = HistoryModeFilter.all,
    this.outcome = HistoryOutcomeFilter.all,
    this.instruments = const [],
    this.timeframes = const [],
    this.sort = HistorySort.newest,
    this.from,
    this.to,
  });

  static const int maxSearchLength = 100;

  final String query;

  final HistoryModeFilter mode;

  final HistoryOutcomeFilter outcome;

  final List<String> instruments;

  final List<String> timeframes;

  final HistorySort sort;

  final DateTime? from;

  final DateTime? to;

  bool get isActive {
    return query.isNotEmpty ||
        mode != HistoryModeFilter.all ||
        outcome != HistoryOutcomeFilter.all ||
        instruments.isNotEmpty ||
        timeframes.isNotEmpty ||
        from != null ||
        to != null;
  }

  /// Only these fields are supported by the generated list API.
  bool get hasServerFilters {
    return query.isNotEmpty ||
        mode != HistoryModeFilter.all ||
        outcome != HistoryOutcomeFilter.all ||
        instruments.isNotEmpty ||
        timeframes.isNotEmpty ||
        from != null ||
        to != null;
  }

  bool hasSameServerFilters(HistoryFilters other) {
    return query == other.query &&
        mode == other.mode &&
        outcome == other.outcome &&
        _sameList(instruments, other.instruments) &&
        _sameList(timeframes, other.timeframes) &&
        from == other.from &&
        to == other.to;
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
      case HistoryOutcomeFilter.targetReached:
        return ['tp1_hit', 'tp2_hit'];

      case HistoryOutcomeFilter.riskLimitHit:
        return ['sl_hit'];

      case HistoryOutcomeFilter.expired:
        return ['expired'];

      case HistoryOutcomeFilter.invalidated:
        return ['invalidated'];

      case HistoryOutcomeFilter.pending:
        return ['pending'];

      case HistoryOutcomeFilter.all:
        return null;
    }
  }

  /// Jumlah kategori aktif yang diwakili lencana pada tombol filter.
  ///
  /// [query] sengaja tidak dihitung: pencarian tinggal di kolom search yang
  /// selalu terlihat beserta tombol hapusnya, dan tidak pernah muncul di
  /// filter sheet. Menghitungnya membuat lencana menunjuk sesuatu yang tidak
  /// bisa ditemukan pengguna ketika sheet dibuka.
  int get activeCategoryCount {
    var count = 0;

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

    return HistoryFilters(
      query: cleanQuery,
      mode: mode,
      outcome: outcome,
      instruments: _normalizeList(instruments, uppercase: true),
      timeframes: _normalizeList(timeframes, uppercase: false),
      sort: HistorySort.newest,
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
    HistorySort? sort,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return HistoryFilters(
      query: query ?? this.query,
      mode: mode ?? this.mode,
      outcome: outcome ?? this.outcome,
      instruments: instruments ?? this.instruments,
      timeframes: timeframes ?? this.timeframes,
      sort: sort ?? this.sort,
      from: clearFrom ? null : from ?? this.from,
      to: clearTo ? null : to ?? this.to,
    );
  }

  /// Preferences intentionally exclude query and absolute date ranges.
  Map<String, Object?> toPreferencesJson() {
    return {
      'version': 1,
      'mode': mode.name,
      'outcome': outcome.name,
      'instruments': instruments,
      'timeframes': timeframes,
    };
  }

  factory HistoryFilters.fromPreferencesJson(Map<String, Object?> json) {
    if (json['version'] != 1) {
      return const HistoryFilters();
    }

    T enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
      return values.where((value) => value.name == raw).firstOrNull ?? fallback;
    }

    List<String> strings(Object? raw) {
      return raw is List ? raw.whereType<String>().toList() : const [];
    }

    return HistoryFilters(
      mode: enumValue(
        HistoryModeFilter.values,
        json['mode'],
        HistoryModeFilter.all,
      ),
      outcome: switch (json['outcome']) {
        'success' => HistoryOutcomeFilter.targetReached,
        'failed' => HistoryOutcomeFilter.all,
        final value => enumValue(
          HistoryOutcomeFilter.values,
          value,
          HistoryOutcomeFilter.all,
        ),
      },
      instruments: strings(json['instruments']),
      timeframes: strings(json['timeframes']),
      sort: HistorySort.newest,
    ).normalized();
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

  static bool _sameList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}
