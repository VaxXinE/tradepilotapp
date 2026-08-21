import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/market/market_sessions.dart';

void main() {
  test('calculates sessions from UTC boundaries and closes on weekends', () {
    final overlap = getMarketSessionStatus(
      now: DateTime.parse('2026-08-17T21:00:00+07:00'),
    );

    expect(
      overlap.openSessions,
      containsAll([MarketSessionName.london, MarketSessionName.newYork]),
    );
    expect(overlap.isOverlap, isTrue);

    final londonClose = getMarketSessionStatus(
      now: DateTime.utc(2026, 8, 17, 17),
    );

    expect(londonClose.openSessions, [MarketSessionName.newYork]);
    expect(londonClose.isOverlap, isFalse);

    final weekend = getMarketSessionStatus(now: DateTime.utc(2026, 8, 22, 12));

    expect(weekend.openSessions, isEmpty);
    expect(weekend.isWeekendClosed, isTrue);
    expect(weekend.next?.type, 'open');
    expect(weekend.next?.session, MarketSessionName.sydney);
    expect(weekend.next?.at, DateTime.utc(2026, 8, 23, 22));
  });
}
