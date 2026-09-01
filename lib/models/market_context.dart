enum MarketTrend { bullish, bearish, neutral }

enum MarketLevel { low, medium, high }

extension MarketTrendLabel on MarketTrend {
  String get label {
    switch (this) {
      case MarketTrend.bullish:
        return 'Bullish';
      case MarketTrend.bearish:
        return 'Bearish';
      case MarketTrend.neutral:
        return 'Neutral';
    }
  }
}

extension MarketLevelLabel on MarketLevel {
  String get label {
    switch (this) {
      case MarketLevel.low:
        return 'Low';
      case MarketLevel.medium:
        return 'Medium';
      case MarketLevel.high:
        return 'High';
    }
  }
}

/// Beginner-friendly, rule-based summary of current market conditions.
///
/// This is educational context, not a trading signal — it never
/// recommends buying, selling, entries, or targets.
class MarketContext {
  const MarketContext({
    required this.instrument,
    required this.trend,
    required this.volatility,
    required this.condition,
    required this.explanation,
    required this.riskLevel,
  });

  final String instrument;

  final MarketTrend trend;
  final MarketLevel volatility;

  final String condition;
  final String explanation;

  final MarketLevel riskLevel;
}
