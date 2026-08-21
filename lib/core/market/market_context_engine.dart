import '../../models/market_context.dart';
import '../../models/market_models.dart';
import 'instrument_context_mapper.dart';
import 'market_sessions.dart';

/// Rule-based (not AI) engine that turns existing market data — candles,
/// live quote, technical snapshot, calendar — into a beginner-friendly
/// [MarketContext] summary. Never produces buy/sell signals.
class MarketContextEngine {
  MarketContextEngine._();

  static const _neutralTrendThresholdPercent = 0.12;
  static const _highImpactWindow = Duration(hours: 3);
  static const _highSpreadPercent = 0.08;
  static const _maxSample = 20;

  static MarketContext? build({
    required String instrument,
    required List<MarketCandle> candles,
    LiveMarketQuote? quote,
    BeginnerTechnicalSnapshot? technical,
    List<EconomicCalendarEvent> calendar = const [],
    DateTime? now,
  }) {
    final trend = _resolveTrend(candles, technical);

    if (trend == null) {
      return null;
    }

    final currentTime = now ?? DateTime.now();

    final upcomingHighImpact = _nextHighImpactEvent(calendar, currentTime);

    var volatility = _resolveVolatility(candles, quote);

    if (upcomingHighImpact != null) {
      volatility = _bumpLevel(volatility);
    }

    return MarketContext(
      instrument: instrument,
      trend: trend,
      volatility: volatility,
      condition: _condition(trend, volatility),
      explanation: _explanation(
        instrument: instrument,
        trend: trend,
        volatility: volatility,
        now: currentTime,
        upcomingHighImpact: upcomingHighImpact,
      ),
      riskLevel: volatility,
    );
  }

  static MarketTrend? _resolveTrend(
    List<MarketCandle> candles,
    BeginnerTechnicalSnapshot? technical,
  ) {
    if (candles.length >= 2) {
      final sample = _lastN(candles, _maxSample);

      final last = sample.last.close;

      final baseline = sample.sublist(0, sample.length - 1);

      final avg =
          baseline.map((c) => c.close).reduce((a, b) => a + b) /
          baseline.length;

      if (avg == 0) {
        return MarketTrend.neutral;
      }

      final diffPercent = (last - avg) / avg * 100;

      if (diffPercent > _neutralTrendThresholdPercent) {
        return MarketTrend.bullish;
      }

      if (diffPercent < -_neutralTrendThresholdPercent) {
        return MarketTrend.bearish;
      }

      return MarketTrend.neutral;
    }

    final overall = technical?.overallSignal.trim().toLowerCase();

    if (overall == null || overall.isEmpty) {
      return null;
    }

    if (overall == 'buy') {
      return MarketTrend.bullish;
    }

    if (overall == 'sell') {
      return MarketTrend.bearish;
    }

    return MarketTrend.neutral;
  }

  static MarketLevel _resolveVolatility(
    List<MarketCandle> candles,
    LiveMarketQuote? quote,
  ) {
    var level = MarketLevel.medium;

    if (candles.length >= 2) {
      final sample = _lastN(candles, _maxSample);

      final ranges = sample
          .where((c) => c.close != 0)
          .map((c) => (c.high - c.low) / c.close * 100)
          .toList();

      if (ranges.isNotEmpty) {
        final last = ranges.last;

        final prior = ranges.length > 1
            ? ranges.sublist(0, ranges.length - 1)
            : ranges;

        final avg = prior.reduce((a, b) => a + b) / prior.length;

        if (avg > 0) {
          final ratio = last / avg;

          if (ratio >= 1.6) {
            level = MarketLevel.high;
          } else if (ratio >= 0.9) {
            level = MarketLevel.medium;
          } else {
            level = MarketLevel.low;
          }
        } else {
          level = last > 0 ? MarketLevel.medium : MarketLevel.low;
        }
      }
    }

    final spread = quote?.spread;
    final price = quote?.price;

    if (spread != null && price != null && price > 0) {
      final spreadPercent = spread / price * 100;

      if (spreadPercent >= _highSpreadPercent) {
        level = _bumpLevel(level);
      }
    }

    return level;
  }

  static EconomicCalendarEvent? _nextHighImpactEvent(
    List<EconomicCalendarEvent> calendar,
    DateTime now,
  ) {
    EconomicCalendarEvent? closest;
    Duration? closestDelta;

    for (final event in calendar) {
      if (!event.isHighImpact) {
        continue;
      }

      final eventTime = event.eventDateTime;

      if (eventTime == null) {
        continue;
      }

      final delta = eventTime.difference(now);

      if (delta.isNegative || delta > _highImpactWindow) {
        continue;
      }

      if (closestDelta == null || delta < closestDelta) {
        closest = event;
        closestDelta = delta;
      }
    }

    return closest;
  }

  static MarketLevel _bumpLevel(MarketLevel level) {
    switch (level) {
      case MarketLevel.low:
        return MarketLevel.medium;
      case MarketLevel.medium:
        return MarketLevel.high;
      case MarketLevel.high:
        return MarketLevel.high;
    }
  }

  static String _condition(MarketTrend trend, MarketLevel volatility) {
    switch (trend) {
      case MarketTrend.bullish:
        switch (volatility) {
          case MarketLevel.low:
            return 'Bullish stabil';
          case MarketLevel.medium:
            return 'Bullish dengan volatilitas sedang';
          case MarketLevel.high:
            return 'Bullish tapi volatile';
        }
      case MarketTrend.bearish:
        switch (volatility) {
          case MarketLevel.low:
            return 'Tekanan bearish stabil';
          case MarketLevel.medium:
            return 'Bearish dengan volatilitas sedang';
          case MarketLevel.high:
            return 'Bearish dan volatile';
        }
      case MarketTrend.neutral:
        switch (volatility) {
          case MarketLevel.low:
            return 'Sideways / konsolidasi';
          case MarketLevel.medium:
            return 'Sideways dengan pergerakan naik-turun';
          case MarketLevel.high:
            return 'Sideways tapi volatile';
        }
    }
  }

  static String _explanation({
    required String instrument,
    required MarketTrend trend,
    required MarketLevel volatility,
    required DateTime now,
    required EconomicCalendarEvent? upcomingHighImpact,
  }) {
    final isCrypto = isCryptoMarketInstrument(instrument);

    final sessionPhrase = isCrypto
        ? 'market kripto yang aktif 24/7'
        : _sessionPhrase(now);

    final trendPhrase = switch (trend) {
      MarketTrend.bullish => 'bergerak naik (bullish)',
      MarketTrend.bearish => 'bergerak turun (bearish)',
      MarketTrend.neutral => 'bergerak sideways',
    };

    final buffer = StringBuffer(
      'Harga $instrument $trendPhrase di $sessionPhrase.',
    );

    final note = InstrumentContextMapper.explain(instrument);

    if (note.isNotEmpty) {
      buffer.write(' $note');
    }

    if (upcomingHighImpact != null) {
      final delta = upcomingHighImpact.eventDateTime!.difference(now);

      buffer.write(
        ' Ada event ${upcomingHighImpact.currency} berdampak tinggi '
        '${_untilPhrase(delta)}, jadi pergerakan harga bisa lebih cepat '
        'dari biasanya.',
      );
    } else if (volatility == MarketLevel.high) {
      buffer.write(
        ' Volatilitas sedang tinggi, jadi pergerakan harga bisa lebih '
        'cepat dari biasanya.',
      );
    }

    return buffer.toString();
  }

  static String _sessionPhrase(DateTime now) {
    final status = getMarketSessionStatus(now: now);

    if (status.openSessions.isEmpty) {
      return 'saat market sedang tutup';
    }

    final sessions = status.openSessions.map(marketSessionLabel).join(' + ');

    return 'saat sesi $sessions aktif';
  }

  static String _untilPhrase(Duration delta) {
    if (delta.inMinutes < 60) {
      return 'dalam ${delta.inMinutes} menit';
    }

    final hours = delta.inMinutes / 60;

    final rounded = (hours * 10).round() / 10;

    final label = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();

    return 'dalam $label jam';
  }

  static List<MarketCandle> _lastN(List<MarketCandle> candles, int n) {
    if (candles.length <= n) {
      return candles;
    }

    return candles.sublist(candles.length - n);
  }
}
