import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/market/analysis_instruments.dart';

void main() {
  test('exactly eight instruments are verified for a new analysis', () {
    expect(verifiedAnalysisInstruments, {
      'XAU/USD',
      'BRENT',
      'HSI',
      'NIKKEI',
      'EUR/USD',
      'GBP/USD',
      'AUD/USD',
      'USD/JPY',
    });
    expect(isVerifiedAnalysisInstrument('BTC/USD'), isFalse);
    expect(isVerifiedAnalysisInstrument('XAG/USD'), isFalse);
  });

  test('an empty search lists only the non-core options', () {
    expect(matchAnalysisInstruments('').map((o) => o.code), [
      'EUR/USD',
      'GBP/USD',
      'AUD/USD',
      'USD/JPY',
    ]);
  });

  test('search matches codes, names and aliases case-insensitively', () {
    expect(matchAnalysisInstruments('gold').map((o) => o.code), ['XAU/USD']);
    expect(matchAnalysisInstruments('hang').map((o) => o.code), ['HSI']);
    expect(matchAnalysisInstruments('yen').map((o) => o.code), ['USD/JPY']);
    expect(
      matchAnalysisInstruments('usd').map((o) => o.code),
      containsAll(['XAU/USD', 'EUR/USD', 'USD/JPY']),
    );
    expect(matchAnalysisInstruments('zzz'), isEmpty);
  });

  test('an exact alias resolves to its instrument', () {
    expect(exactAnalysisInstrument('cable')?.code, 'GBP/USD');
    expect(exactAnalysisInstrument(' ukoil ')?.code, 'BRENT');
    expect(exactAnalysisInstrument('gbp'), isNull);
  });

  test('only well-formed, unsupported codes can be requested', () {
    expect(instrumentRequestCode('btc/usdh'), 'BTC/USDH');
    expect(instrumentRequestCode('nas100'), 'NAS100');
    expect(
      instrumentRequestCode('xau/usd'),
      isNull,
      reason: 'already verified',
    );
    expect(instrumentRequestCode('ukoil'), isNull, reason: 'covered by Brent');
    expect(instrumentRequestCode('bco'), isNull, reason: 'covered by Brent');
    expect(instrumentRequestCode('cable'), isNull, reason: 'exact alias');
    expect(instrumentRequestCode('x'), isNull, reason: 'too short');
    expect(instrumentRequestCode('bad code!'), isNull);
    expect(instrumentRequestCode(''), isNull);
    expect(instrumentRequestCode('A' * 26), isNull);
  });
}
