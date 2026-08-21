import '../../models/market_context.dart';
import '../../models/market_models.dart';
import '../../models/technical_summary.dart';

/// Rule-based (not AI) engine that turns a [BeginnerTechnicalSnapshot]
/// into a beginner-friendly [TechnicalSummary]. Never produces
/// buy/sell/entry/target wording.
class TechnicalSummaryEngine {
  TechnicalSummaryEngine._();

  static const _oversold = 30;
  static const _overbought = 70;

  static const _lowVolatilityChangePercent = 0.3;
  static const _highVolatilityChangePercent = 1.2;

  static TechnicalSummary? build(BeginnerTechnicalSnapshot? technical) {
    if (technical == null) {
      return null;
    }

    final trend = _resolveTrend(technical);

    final momentum = _resolveMomentum(technical);

    final volatility = _resolveVolatility(technical);

    var riskLevel = volatility;

    final rsi = technical.rsi;

    if (rsi != null && (rsi <= 20 || rsi >= 80)) {
      riskLevel = _bumpLevel(riskLevel);
    }

    return TechnicalSummary(
      trend: trend,
      momentum: momentum,
      volatility: volatility,
      explanation: _explanation(technical),
      riskLevel: riskLevel,
    );
  }

  static MarketTrend _resolveTrend(BeginnerTechnicalSnapshot t) {
    if (t.bullish) {
      return MarketTrend.bullish;
    }

    if (t.bearish) {
      return MarketTrend.bearish;
    }

    return MarketTrend.neutral;
  }

  static MarketLevel _resolveMomentum(BeginnerTechnicalSnapshot t) {
    final rsi = t.rsi;

    if (rsi == null) {
      return MarketLevel.medium;
    }

    if (rsi < _oversold || rsi > _overbought) {
      return MarketLevel.high;
    }

    if (rsi >= 45 && rsi <= 55) {
      return MarketLevel.low;
    }

    return MarketLevel.medium;
  }

  static MarketLevel _resolveVolatility(BeginnerTechnicalSnapshot t) {
    final change = t.change1dPercent.abs();

    if (change >= _highVolatilityChangePercent) {
      return MarketLevel.high;
    }

    if (change >= _lowVolatilityChangePercent) {
      return MarketLevel.medium;
    }

    return MarketLevel.low;
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

  static String _explanation(BeginnerTechnicalSnapshot t) {
    final buffer = StringBuffer(_trendSentence(t));

    final rsiSentence = _rsiSentence(t);

    if (rsiSentence != null) {
      buffer.write(' $rsiSentence');
    }

    buffer.write(' ${_macdSentence(t)}');

    final rsi = t.rsi;

    if (rsi != null && (rsi <= 20 || rsi >= 80)) {
      buffer.write(
        ' Momentum tinggi dapat meningkatkan risiko pembalikan arah, '
        'jadi tetap berhati-hati.',
      );
    }

    return buffer.toString();
  }

  static String _trendSentence(BeginnerTechnicalSnapshot t) {
    final total = t.totalSignals;

    if (total <= 0) {
      return 'Indikator belum menunjukkan arah yang dominan.';
    }

    if (t.bullish) {
      return '${t.buyCount} dari $total indikator saat ini mendukung '
          'kenaikan.';
    }

    if (t.bearish) {
      return '${t.sellCount} dari $total indikator saat ini mendukung '
          'penurunan.';
    }

    return 'Indikator belum menunjukkan arah yang dominan '
        '(${t.neutralCount} dari $total netral).';
  }

  static String? _rsiSentence(BeginnerTechnicalSnapshot t) {
    final rsi = t.rsi;

    if (rsi == null) {
      return null;
    }

    if (rsi < _oversold) {
      return 'RSI ${rsi.toStringAsFixed(1)} menunjukkan momentum sedang '
          'melemah dan harga berada dekat area rendah.';
    }

    if (rsi > _overbought) {
      return 'RSI ${rsi.toStringAsFixed(1)} menunjukkan momentum sedang '
          'tinggi; kondisi ini dapat berarti pergerakan kuat, namun tetap '
          'perhatikan risiko perubahan arah.';
    }

    return 'RSI ${rsi.toStringAsFixed(1)} menunjukkan momentum yang '
        'relatif normal.';
  }

  static String _macdSentence(BeginnerTechnicalSnapshot t) {
    switch (t.macdAction.trim().toLowerCase()) {
      case 'buy':
        return 'MACD menunjukkan momentum jangka pendek cenderung positif.';

      case 'sell':
        return 'MACD menunjukkan momentum jangka pendek sedang melemah.';

      default:
        return 'MACD belum menunjukkan perubahan momentum yang signifikan.';
    }
  }
}
