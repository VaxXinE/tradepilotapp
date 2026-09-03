import 'package:intl/intl.dart';

final _marketDayFormat = DateFormat('d MMM yyyy', 'en_US');

DateTime? _parseMarketDate(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return null;

  final isoDate = DateTime.tryParse(raw);
  if (isoDate != null) return isoDate;

  try {
    return _marketDayFormat.parseStrict(raw, true);
  } on FormatException {
    return null;
  }
}

double? marketDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    final cleaned = value.trim().replaceAll('%', '').replaceAll(',', '');

    return double.tryParse(cleaned);
  }

  return null;
}

int? marketInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

Map<String, dynamic> marketMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

// =============================================================================
// LIVE QUOTE
// =============================================================================

class LiveMarketQuote {
  const LiveMarketQuote({
    required this.instrument,
    required this.symbol,
    required this.price,
    this.buy,
    this.sell,
    this.spread,
    this.high,
    this.low,
    this.open,
    required this.changePercent,
    required this.direction,
    this.serverTime,
    this.updatedAt,
  });

  final String instrument;
  final String symbol;

  final double price;
  final double? buy;
  final double? sell;
  final double? spread;

  final double? high;
  final double? low;
  final double? open;

  final double changePercent;

  final String direction;

  final String? serverTime;
  final DateTime? updatedAt;

  bool get isUp {
    return direction == 'up' || changePercent > 0;
  }

  bool get isDown {
    return direction == 'down' || changePercent < 0;
  }

  factory LiveMarketQuote.fromJson(Map<String, dynamic> json) {
    final change = marketDouble(json['changePercent'] ?? json['change%']) ?? 0;

    final direction =
        (json['direction'] as String?)?.trim().toLowerCase() ??
        (change < 0 ? 'down' : 'up');

    return LiveMarketQuote(
      instrument: (json['instrument'] ?? '').toString().trim().toUpperCase(),
      symbol: (json['symbol'] ?? '').toString().trim(),
      price: marketDouble(json['price']) ?? 0,
      buy: marketDouble(json['buy']),
      sell: marketDouble(json['sell']),
      spread: marketDouble(json['spread']),
      high: marketDouble(json['high']),
      low: marketDouble(json['low']),
      open: marketDouble(json['open']),
      changePercent: change,
      direction: direction,
      serverTime: json['serverTime']?.toString(),
      updatedAt: DateTime.tryParse(
        json['updatedAt']?.toString() ??
            json['serverDateTime']?.toString() ??
            '',
      ),
    );
  }
}

// =============================================================================
// CANDLE
// =============================================================================

class MarketCandle {
  const MarketCandle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final DateTime date;

  final double open;
  final double high;
  final double low;
  final double close;

  bool get bullish => close >= open;

  factory MarketCandle.fromJson(Map<String, dynamic> json) {
    final date = _parseMarketDate(json['date']);

    if (date == null) {
      throw const FormatException('Invalid candle date.');
    }

    final open = marketDouble(json['open']);
    final high = marketDouble(json['high']);
    final low = marketDouble(json['low']);
    final close = marketDouble(json['close']);

    if (open == null || high == null || low == null || close == null) {
      throw const FormatException('Invalid candle price.');
    }

    if (![open, high, low, close].every((value) => value.isFinite) ||
        high < low ||
        high < open ||
        high < close ||
        low > open ||
        low > close) {
      throw const FormatException('Invalid candle range.');
    }

    return MarketCandle(
      date: date,
      open: open,
      high: high,
      low: low,
      close: close,
    );
  }
}

// =============================================================================
// TECHNICAL INDICATORS — BEGINNER VIEW
// =============================================================================

class BeginnerTechnicalSnapshot {
  const BeginnerTechnicalSnapshot({
    required this.lastClose,
    required this.change1dPercent,
    required this.rsi,
    required this.rsiSignal,
    required this.macdAction,
    required this.buyCount,
    required this.sellCount,
    required this.neutralCount,
    required this.overallSignal,
    this.dataPoints = 0,
    this.change20dPercent = 0,
    this.macdValue,
    this.macdSignal,
    this.macdHistogram,
    this.stochasticK,
    this.stochasticD,
    this.stochasticSignal = 'Neutral',
    this.bollingerUpper,
    this.bollingerMiddle,
    this.bollingerLower,
    this.bollingerSignal = 'Neutral',
    this.oscillatorBuyCount = 0,
    this.oscillatorSellCount = 0,
    this.oscillatorNeutralCount = 0,
    this.movingAverageBuyCount = 0,
    this.movingAverageSellCount = 0,
    this.movingAverageNeutralCount = 0,
    this.movingAverages = const [],
  });

  final double? lastClose;

  final double change1dPercent;

  final double? rsi;
  final String rsiSignal;

  final String macdAction;

  final int buyCount;
  final int sellCount;
  final int neutralCount;

  final String overallSignal;
  final int dataPoints;
  final double change20dPercent;
  final double? macdValue;
  final double? macdSignal;
  final double? macdHistogram;
  final double? stochasticK;
  final double? stochasticD;
  final String stochasticSignal;
  final double? bollingerUpper;
  final double? bollingerMiddle;
  final double? bollingerLower;
  final String bollingerSignal;
  final int oscillatorBuyCount;
  final int oscillatorSellCount;
  final int oscillatorNeutralCount;
  final int movingAverageBuyCount;
  final int movingAverageSellCount;
  final int movingAverageNeutralCount;
  final List<TechnicalMovingAverage> movingAverages;

  int get totalSignals {
    return buyCount + sellCount + neutralCount;
  }

  bool get bullish {
    return overallSignal.toLowerCase() == 'buy';
  }

  bool get bearish {
    return overallSignal.toLowerCase() == 'sell';
  }

  bool get neutral {
    return !bullish && !bearish;
  }

  factory BeginnerTechnicalSnapshot.fromJson(Map<String, dynamic> json) {
    final overall = marketMap(json['overallSummary']);

    final rsi = marketMap(json['rsi14']);

    final macd = marketMap(json['macd']);
    final stochastic = marketMap(json['stochastic']);
    final bollinger = marketMap(json['bollinger']);
    final oscillator = marketMap(json['oscillatorSummary']);
    final movingAverage = marketMap(json['maSummary']);
    final movingAverages = json['movingAverages'];

    return BeginnerTechnicalSnapshot(
      lastClose: marketDouble(json['lastClose']),
      change1dPercent: marketDouble(json['change1dPct']) ?? 0,
      rsi: marketDouble(rsi['value']),
      rsiSignal: rsi['signal']?.toString() ?? 'Neutral',
      macdAction: macd['action']?.toString() ?? 'Neutral',
      buyCount: marketInt(overall['buy']) ?? 0,
      sellCount: marketInt(overall['sell']) ?? 0,
      neutralCount: marketInt(overall['neutral']) ?? 0,
      overallSignal: overall['signal']?.toString() ?? 'Neutral',
      dataPoints: marketInt(json['dataPoints']) ?? 0,
      change20dPercent: marketDouble(json['change20dPct']) ?? 0,
      macdValue: marketDouble(macd['macd']),
      macdSignal: marketDouble(macd['signal']),
      macdHistogram: marketDouble(macd['histogram']),
      stochasticK: marketDouble(stochastic['k']),
      stochasticD: marketDouble(stochastic['d']),
      stochasticSignal: stochastic['signal']?.toString() ?? 'Neutral',
      bollingerUpper: marketDouble(bollinger['upper']),
      bollingerMiddle: marketDouble(bollinger['middle']),
      bollingerLower: marketDouble(bollinger['lower']),
      bollingerSignal: bollinger['signal']?.toString() ?? 'Neutral',
      oscillatorBuyCount: marketInt(oscillator['buy']) ?? 0,
      oscillatorSellCount: marketInt(oscillator['sell']) ?? 0,
      oscillatorNeutralCount: marketInt(oscillator['neutral']) ?? 0,
      movingAverageBuyCount: marketInt(movingAverage['buy']) ?? 0,
      movingAverageSellCount: marketInt(movingAverage['sell']) ?? 0,
      movingAverageNeutralCount: marketInt(movingAverage['neutral']) ?? 0,
      movingAverages: movingAverages is List
          ? movingAverages
                .map((item) => TechnicalMovingAverage.fromJson(marketMap(item)))
                .where((item) => item.value != null)
                .toList(growable: false)
          : const [],
    );
  }
}

class TechnicalMovingAverage {
  const TechnicalMovingAverage({
    required this.period,
    required this.type,
    required this.value,
    required this.signal,
  });

  final int period;
  final String type;
  final double? value;
  final String signal;

  factory TechnicalMovingAverage.fromJson(Map<String, dynamic> json) {
    return TechnicalMovingAverage(
      period: marketInt(json['period']) ?? 0,
      type: json['type']?.toString() ?? 'MA',
      value: marketDouble(json['value']),
      signal: json['signal']?.toString() ?? 'Neutral',
    );
  }
}

// =============================================================================
// ECONOMIC CALENDAR
// =============================================================================

enum EconomicImpactLevel { high, medium, low }

class EconomicCalendarEvent {
  const EconomicCalendarEvent({
    required this.time,
    required this.currency,
    required this.impact,
    required this.event,
    required this.previous,
    required this.forecast,
    required this.actual,
    required this.date,
    required this.epochMs,
    required this.whyTraderCare,
  });

  final String time;
  final String currency;
  final String impact;
  final String event;

  final String previous;
  final String forecast;
  final String actual;

  final String date;

  final int? epochMs;

  final String whyTraderCare;

  DateTime? get eventDateTime {
    final epoch = epochMs;

    if (epoch != null) {
      return DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true).toLocal();
    }

    return DateTime.tryParse(date);
  }

  bool get isHighImpact {
    return impactLevel == EconomicImpactLevel.high;
  }

  EconomicImpactLevel get impactLevel {
    final normalized = impact.trim().toLowerCase();
    if (normalized == 'high' || normalized == '★★★' || normalized == '3') {
      return EconomicImpactLevel.high;
    }
    if (normalized == 'medium' || normalized == '★★' || normalized == '2') {
      return EconomicImpactLevel.medium;
    }
    return EconomicImpactLevel.low;
  }

  factory EconomicCalendarEvent.fromJson(Map<String, dynamic> json) {
    final event = json['event']?.toString().trim() ?? '';
    final currency = json['currency']?.toString().trim().toUpperCase() ?? '';
    final epochMs = marketInt(json['epochMs']);

    if (event.isEmpty ||
        currency.isEmpty ||
        (epochMs != null && epochMs <= 0)) {
      throw const FormatException('Invalid economic calendar event.');
    }

    return EconomicCalendarEvent(
      time: json['time']?.toString().trim() ?? '',
      currency: currency,
      impact: json['impact']?.toString().trim() ?? '',
      event: event,
      previous: json['previous']?.toString().trim() ?? '',
      forecast: json['forecast']?.toString().trim() ?? '',
      actual: json['actual']?.toString().trim() ?? '',
      date: json['date']?.toString().trim() ?? '',
      epochMs: epochMs,
      whyTraderCare: json['whyTraderCare']?.toString().trim() ?? '',
    );
  }
}
