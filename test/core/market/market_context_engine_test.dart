import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/market/market_context_engine.dart';
import 'package:tradepilotapp/models/market_context.dart';
import 'package:tradepilotapp/models/market_models.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 14); // London + New York overlap.

  MarketCandle flatCandle(DateTime date, double close, {double range = 0}) {
    return MarketCandle(
      date: date,
      open: close,
      high: close + range / 2,
      low: close - range / 2,
      close: close,
    );
  }

  group('trend', () {
    test('detects bullish when price sits above the recent baseline', () {
      final candles = [
        flatCandle(now.subtract(const Duration(hours: 2)), 100),
        flatCandle(now.subtract(const Duration(hours: 1)), 100),
        flatCandle(now, 102),
      ];

      final context = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: candles,
        now: now,
      );

      expect(context, isNotNull);
      expect(context!.trend, MarketTrend.bullish);
    });

    test('detects bearish when price sits below the recent baseline', () {
      final candles = [
        flatCandle(now.subtract(const Duration(hours: 2)), 100),
        flatCandle(now.subtract(const Duration(hours: 1)), 100),
        flatCandle(now, 98),
      ];

      final context = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: candles,
        now: now,
      );

      expect(context!.trend, MarketTrend.bearish);
    });

    test('detects neutral for a near-flat price', () {
      final candles = [
        flatCandle(now.subtract(const Duration(hours: 2)), 100),
        flatCandle(now.subtract(const Duration(hours: 1)), 100),
        flatCandle(now, 100.05),
      ];

      final context = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: candles,
        now: now,
      );

      expect(context!.trend, MarketTrend.neutral);
    });

    test('falls back to the technical snapshot with fewer than 2 candles', () {
      final context = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: const [],
        technical: const BeginnerTechnicalSnapshot(
          lastClose: 100,
          change1dPercent: 1,
          rsi: 60,
          rsiSignal: 'Buy',
          macdAction: 'Buy',
          buyCount: 3,
          sellCount: 1,
          neutralCount: 0,
          overallSignal: 'Buy',
        ),
        now: now,
      );

      expect(context!.trend, MarketTrend.bullish);
    });

    test('returns null when there is not enough data to assess', () {
      final context = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: const [],
        now: now,
      );

      expect(context, isNull);
    });
  });

  group('volatility', () {
    test('rates volatility high when the latest range spikes', () {
      final candles = [
        flatCandle(now.subtract(const Duration(hours: 2)), 100, range: 1),
        flatCandle(now.subtract(const Duration(hours: 1)), 100, range: 1),
        flatCandle(now, 100, range: 3),
      ];

      final context = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: candles,
        now: now,
      );

      expect(context!.volatility, MarketLevel.high);
      expect(context.riskLevel, MarketLevel.high);
    });

    test('rates volatility low when the latest range shrinks', () {
      final candles = [
        flatCandle(now.subtract(const Duration(hours: 2)), 100, range: 1),
        flatCandle(now.subtract(const Duration(hours: 1)), 100, range: 1),
        flatCandle(now, 100, range: 0.3),
      ];

      final context = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: candles,
        now: now,
      );

      expect(context!.volatility, MarketLevel.low);
    });

    test('bumps volatility one level when a high-impact event is imminent', () {
      final candles = [
        flatCandle(now.subtract(const Duration(hours: 2)), 100, range: 1),
        flatCandle(now.subtract(const Duration(hours: 1)), 100, range: 1),
        flatCandle(now, 100, range: 0.3),
      ];

      final calendar = [
        EconomicCalendarEvent(
          time: '16:00',
          currency: 'USD',
          impact: 'high',
          event: 'CPI',
          previous: '3.1%',
          forecast: '3.0%',
          actual: '',
          date: now.add(const Duration(hours: 1)).toIso8601String(),
          epochMs: null,
          whyTraderCare: '',
        ),
      ];

      final withoutEvent = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: candles,
        now: now,
      );

      final withEvent = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: candles,
        calendar: calendar,
        now: now,
      );

      expect(withoutEvent!.volatility, MarketLevel.low);
      expect(withEvent!.volatility, MarketLevel.medium);
      expect(withEvent.explanation, contains('USD'));
    });

    test('ignores a high-impact event that is too far away', () {
      final candles = [
        flatCandle(now.subtract(const Duration(hours: 2)), 100, range: 1),
        flatCandle(now.subtract(const Duration(hours: 1)), 100, range: 1),
        flatCandle(now, 100, range: 0.3),
      ];

      final calendar = [
        EconomicCalendarEvent(
          time: '22:00',
          currency: 'USD',
          impact: 'high',
          event: 'CPI',
          previous: '3.1%',
          forecast: '3.0%',
          actual: '',
          date: now.add(const Duration(hours: 6)).toIso8601String(),
          epochMs: null,
          whyTraderCare: '',
        ),
      ];

      final context = MarketContextEngine.build(
        instrument: 'XAU/USD',
        candles: candles,
        calendar: calendar,
        now: now,
      );

      expect(context!.volatility, MarketLevel.low);
    });
  });

  test('does not produce any trading signal wording', () {
    final candles = [
      flatCandle(now.subtract(const Duration(hours: 2)), 100),
      flatCandle(now.subtract(const Duration(hours: 1)), 100),
      flatCandle(now, 102),
    ];

    final context = MarketContextEngine.build(
      instrument: 'XAU/USD',
      candles: candles,
      now: now,
    );

    final text = '${context!.condition} ${context.explanation}'.toLowerCase();

    expect(text, isNot(contains('buy')));
    expect(text, isNot(contains('sell')));
    expect(text, isNot(contains('target')));
    expect(text, isNot(contains('entry')));
  });
}
