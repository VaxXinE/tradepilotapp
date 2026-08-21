import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/market/technical_summary_engine.dart';
import 'package:tradepilotapp/models/market_context.dart';
import 'package:tradepilotapp/models/market_models.dart';

BeginnerTechnicalSnapshot _snapshot({
  double? rsi,
  String rsiSignal = 'Neutral',
  String macdAction = 'Neutral',
  int buyCount = 0,
  int sellCount = 0,
  int neutralCount = 0,
  String overallSignal = 'Neutral',
  double change1dPercent = 0,
}) {
  return BeginnerTechnicalSnapshot(
    lastClose: 100,
    change1dPercent: change1dPercent,
    rsi: rsi,
    rsiSignal: rsiSignal,
    macdAction: macdAction,
    buyCount: buyCount,
    sellCount: sellCount,
    neutralCount: neutralCount,
    overallSignal: overallSignal,
  );
}

void main() {
  test('returns null for empty technical data', () {
    expect(TechnicalSummaryEngine.build(null), isNull);
  });

  group('trend', () {
    test('bullish when overall signal is buy', () {
      final summary = TechnicalSummaryEngine.build(
        _snapshot(overallSignal: 'Buy', buyCount: 3, neutralCount: 1),
      );

      expect(summary!.trend, MarketTrend.bullish);
      expect(summary.explanation, contains('3 dari 4'));
    });

    test('bearish when overall signal is sell', () {
      final summary = TechnicalSummaryEngine.build(
        _snapshot(overallSignal: 'Sell', sellCount: 2, neutralCount: 1),
      );

      expect(summary!.trend, MarketTrend.bearish);
      expect(summary.explanation, contains('2 dari 3'));
    });

    test('neutral when overall signal is neutral', () {
      final summary = TechnicalSummaryEngine.build(
        _snapshot(overallSignal: 'Neutral', neutralCount: 2),
      );

      expect(summary!.trend, MarketTrend.neutral);
    });
  });

  group('RSI momentum', () {
    test('rates momentum high and mentions the low area when oversold', () {
      final summary = TechnicalSummaryEngine.build(_snapshot(rsi: 22));

      expect(summary!.momentum, MarketLevel.high);
      expect(summary.explanation, contains('area rendah'));
    });

    test(
      'rates momentum high and warns about reversal risk when overbought',
      () {
        final summary = TechnicalSummaryEngine.build(_snapshot(rsi: 82));

        expect(summary!.momentum, MarketLevel.high);
        expect(summary.riskLevel, isNot(MarketLevel.low));
        expect(summary.explanation, contains('risiko perubahan arah'));
        expect(summary.explanation, contains('risiko pembalikan arah'));
      },
    );

    test('rates momentum low for a flat mid-range RSI', () {
      final summary = TechnicalSummaryEngine.build(_snapshot(rsi: 50));

      expect(summary!.momentum, MarketLevel.low);
      expect(summary.explanation, contains('relatif normal'));
    });

    test('defaults momentum to medium when RSI is unavailable', () {
      final summary = TechnicalSummaryEngine.build(_snapshot(rsi: null));

      expect(summary!.momentum, MarketLevel.medium);
    });
  });

  group('MACD', () {
    test('describes a positive short-term momentum', () {
      final summary = TechnicalSummaryEngine.build(
        _snapshot(macdAction: 'Buy'),
      );

      expect(summary!.explanation, contains('cenderung positif'));
    });

    test('describes a weakening short-term momentum', () {
      final summary = TechnicalSummaryEngine.build(
        _snapshot(macdAction: 'Sell'),
      );

      expect(summary!.explanation, contains('sedang melemah'));
    });

    test('describes no significant change for a neutral MACD', () {
      final summary = TechnicalSummaryEngine.build(
        _snapshot(macdAction: 'Neutral'),
      );

      expect(summary!.explanation, contains('belum menunjukkan perubahan'));
    });
  });

  group('volatility', () {
    test('rates volatility low for a small daily change', () {
      final summary = TechnicalSummaryEngine.build(
        _snapshot(change1dPercent: 0.1),
      );

      expect(summary!.volatility, MarketLevel.low);
    });

    test('rates volatility high for a large daily change', () {
      final summary = TechnicalSummaryEngine.build(
        _snapshot(change1dPercent: -2.5),
      );

      expect(summary!.volatility, MarketLevel.high);
    });
  });

  test('does not produce any trading signal wording', () {
    final summary = TechnicalSummaryEngine.build(
      _snapshot(rsi: 85, macdAction: 'Buy', overallSignal: 'Buy', buyCount: 4),
    );

    final text = summary!.explanation.toLowerCase();

    expect(text, isNot(contains('buy')));
    expect(text, isNot(contains('sell')));
    expect(text, isNot(contains('target')));
    expect(text, isNot(contains('entry')));
  });
}
