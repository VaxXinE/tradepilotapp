import 'market_context.dart';

/// Beginner-friendly, rule-based interpretation of a
/// [BeginnerTechnicalSnapshot] — plain-language trend, momentum, and
/// risk awareness. Educational only, never a trading signal.
class TechnicalSummary {
  const TechnicalSummary({
    required this.trend,
    required this.momentum,
    required this.volatility,
    required this.explanation,
    required this.riskLevel,
  });

  final MarketTrend trend;

  final MarketLevel momentum;
  final MarketLevel volatility;

  final String explanation;

  final MarketLevel riskLevel;
}
