enum MarketSessionName { sydney, tokyo, london, newYork }

class MarketSessionDefinition {
  const MarketSessionDefinition({
    required this.name,
    required this.openUtcHour,
    required this.closeUtcHour,
  });

  final MarketSessionName name;

  final int openUtcHour;
  final int closeUtcHour;
}

const marketSessions = [
  MarketSessionDefinition(
    name: MarketSessionName.sydney,
    openUtcHour: 22,
    closeUtcHour: 7,
  ),
  MarketSessionDefinition(
    name: MarketSessionName.tokyo,
    openUtcHour: 0,
    closeUtcHour: 9,
  ),
  MarketSessionDefinition(
    name: MarketSessionName.london,
    openUtcHour: 8,
    closeUtcHour: 17,
  ),
  MarketSessionDefinition(
    name: MarketSessionName.newYork,
    openUtcHour: 13,
    closeUtcHour: 22,
  ),
];

class MarketSessionTransition {
  const MarketSessionTransition({
    required this.type,
    required this.session,
    required this.at,
    required this.until,
  });

  final String type;

  final MarketSessionName session;

  final DateTime at;

  final Duration until;
}

class MarketSessionStatus {
  const MarketSessionStatus({
    required this.openSessions,
    required this.isOverlap,
    required this.isWeekendClosed,
    required this.next,
  });

  final List<MarketSessionName> openSessions;

  final bool isOverlap;

  final bool isWeekendClosed;

  final MarketSessionTransition? next;
}

class _SessionInterval {
  const _SessionInterval({
    required this.name,
    required this.start,
    required this.end,
  });

  final MarketSessionName name;

  final DateTime start;
  final DateTime end;
}

const cryptoMarketInstruments = {
  'BTC/USD',
  'ETH/USD',
  'SOL/USD',
  'BNB/USD',
  'XRP/USD',
};

bool isCryptoMarketInstrument(String instrument) {
  return cryptoMarketInstruments.contains(instrument.trim().toUpperCase());
}

bool isInMarketWeekendClosure(DateTime value) {
  final utc = value.toUtc();

  final day = utc.weekday;

  final hour = utc.hour;

  // Dart:
  //
  // Monday = 1
  // ...
  // Friday = 5
  // Saturday = 6
  // Sunday = 7

  if (day == DateTime.saturday) {
    return true;
  }

  if (day == DateTime.friday && hour >= 22) {
    return true;
  }

  if (day == DateTime.sunday && hour < 22) {
    return true;
  }

  return false;
}

List<_SessionInterval> _generateMarketIntervals(DateTime now) {
  final utc = now.toUtc();

  final base = DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
  ).subtract(const Duration(days: 2));

  final intervals = <_SessionInterval>[];

  for (var dayOffset = 0; dayOffset < 6; dayOffset++) {
    final day = base.add(Duration(days: dayOffset));

    for (final session in marketSessions) {
      final start = DateTime.utc(
        day.year,
        day.month,
        day.day,
        session.openUtcHour,
      );

      if (isInMarketWeekendClosure(start)) {
        continue;
      }

      final wraps = session.closeUtcHour <= session.openUtcHour;

      final end = DateTime.utc(
        day.year,
        day.month,
        day.day + (wraps ? 1 : 0),
        session.closeUtcHour,
      );

      intervals.add(
        _SessionInterval(name: session.name, start: start, end: end),
      );
    }
  }

  return intervals;
}

MarketSessionStatus getMarketSessionStatus({DateTime? now}) {
  final current = (now ?? DateTime.now()).toUtc();

  final intervals = _generateMarketIntervals(current);

  final open = <MarketSessionName>[];

  for (final interval in intervals) {
    final isOpen =
        !current.isBefore(interval.start) && current.isBefore(interval.end);

    if (isOpen) {
      open.add(interval.name);
    }
  }

  final transitions = <MarketSessionTransition>[];

  for (final interval in intervals) {
    if (interval.start.isAfter(current)) {
      transitions.add(
        MarketSessionTransition(
          type: 'open',
          session: interval.name,
          at: interval.start,
          until: interval.start.difference(current),
        ),
      );
    }

    if (interval.end.isAfter(current)) {
      transitions.add(
        MarketSessionTransition(
          type: 'close',
          session: interval.name,
          at: interval.end,
          until: interval.end.difference(current),
        ),
      );
    }
  }

  transitions.sort((a, b) => a.until.compareTo(b.until));

  return MarketSessionStatus(
    openSessions: open,
    isOverlap: open.length >= 2,
    isWeekendClosed: open.isEmpty && isInMarketWeekendClosure(current),
    next: transitions.isEmpty ? null : transitions.first,
  );
}

String marketSessionLabel(MarketSessionName name) {
  switch (name) {
    case MarketSessionName.sydney:
      return 'Sydney';

    case MarketSessionName.tokyo:
      return 'Tokyo';

    case MarketSessionName.london:
      return 'London';

    case MarketSessionName.newYork:
      return 'New York';
  }
}

String formatMarketDuration(Duration duration) {
  if (duration <= Duration.zero) {
    return '0m';
  }

  final totalMinutes = duration.inMinutes;

  if (totalMinutes < 1) {
    return '<1m';
  }

  final hours = totalMinutes ~/ 60;

  final minutes = totalMinutes % 60;

  if (hours <= 0) {
    return '${minutes}m';
  }

  if (hours >= 24) {
    final days = hours ~/ 24;

    final remainingHours = hours % 24;

    if (remainingHours > 0) {
      return '${days}d '
          '${remainingHours}h';
    }

    return '${days}d';
  }

  if (minutes > 0) {
    return '${hours}h '
        '${minutes}m';
  }

  return '${hours}h';
}
