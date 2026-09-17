import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/models/market_models.dart';

void main() {
  test('candle ISO timestamps use the device local timezone', () {
    final candle = MarketCandle.fromJson({
      'date': '2026-09-14T14:30:00.000Z',
      'open': 100,
      'high': 102,
      'low': 99,
      'close': 101,
    });

    expect(candle.date.isUtc, isFalse);
    expect(candle.date.toUtc(), DateTime.utc(2026, 9, 14, 14, 30));
  });

  test('technical snapshot keeps the full indicator payload', () {
    final snapshot = BeginnerTechnicalSnapshot.fromJson({
      'lastClose': 4321.79,
      'change1dPct': -0.01,
      'change20dPct': -1.47,
      'dataPoints': 13729,
      'rsi14': {'value': 35.05, 'signal': 'Neutral'},
      'macd': {
        'macd': -26.6686,
        'signal': -20.0,
        'histogram': -6.6686,
        'action': 'Sell',
      },
      'stochastic': {'k': 40.61, 'd': 42.0, 'signal': 'Neutral'},
      'bollinger': {
        'upper': 4388.01,
        'middle': 4338.0,
        'lower': 4289.04,
        'signal': 'Neutral',
      },
      'overallSummary': {'buy': 3, 'neutral': 2, 'sell': 6, 'signal': 'Sell'},
      'oscillatorSummary': {'buy': 2, 'neutral': 2, 'sell': 0},
      'maSummary': {'buy': 1, 'neutral': 0, 'sell': 6},
      'movingAverages': [
        {'type': 'EMA', 'period': 9, 'value': 4322.52, 'signal': 'Sell'},
      ],
    });

    expect(snapshot.dataPoints, 13729);
    expect(snapshot.stochasticK, 40.61);
    expect(snapshot.bollingerLower, 4289.04);
    expect(snapshot.movingAverages.single.period, 9);
    expect(snapshot.movingAverageSellCount, 6);
  });
}
