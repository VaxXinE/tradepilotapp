import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/market/instrument_context_mapper.dart';

void main() {
  test('returns a specific note for a known instrument', () {
    expect(InstrumentContextMapper.explain('XAU/USD'), contains('Emas'));
    expect(InstrumentContextMapper.explain('eur/usd'), contains('ECB'));
  });

  test('returns the shared crypto note for any crypto instrument', () {
    final btc = InstrumentContextMapper.explain('BTC/USD');
    final sol = InstrumentContextMapper.explain('SOL/USD');

    expect(btc, contains('24/7'));
    expect(btc, sol);
  });

  test('falls back to a generic note for unknown instruments', () {
    expect(InstrumentContextMapper.explain('ZZZ/USD'), isNotEmpty);
  });
}
