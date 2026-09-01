import 'market_sessions.dart';

/// Beginner-friendly explanation of what typically drives an instrument.
///
/// Educational only — does not imply a direction or trading signal.
class InstrumentContextMapper {
  InstrumentContextMapper._();

  static const Map<String, String> _notes = {
    'XAU/USD':
        'Gold is usually sensitive to interest-rate policy and US dollar '
        '(USD) movements.',
    'XAG/USD': 'Silver often follows gold, but its moves can be sharper.',
    'BRENT':
        'Oil is sensitive to global supply, OPEC policy, and global economic '
        'conditions.',
    'DXY':
        'The US Dollar Index measures USD strength against other major '
        'currencies.',
    'EUR/USD':
        'This pair responds to European Central Bank (ECB) and US Federal '
        'Reserve policy.',
    'GBP/USD':
        'This pair is sensitive to UK economic data, Bank of England policy, '
        'and the US dollar.',
    'AUD/USD':
        'This pair is influenced by commodity prices and Reserve Bank of '
        'Australia policy.',
    'USD/CHF':
        'The Swiss franc is often considered a safe-haven asset, so this pair '
        'responds to global risk sentiment.',
    'USD/JPY':
        'This pair is influenced by Bank of Japan policy and the US dollar.',
    'USD/IDR':
        'The rupiah is influenced by Bank Indonesia policy and foreign capital '
        'flows into Indonesian markets.',
  };

  static const _cryptoNote =
      'Crypto markets trade 24/7 and are sensitive to market sentiment, '
      'liquidity, and regulatory news.';

  static const _indexNote =
      'Stock indices track groups of major companies and are sensitive to '
      'macroeconomic news.';

  static const _fallbackNote =
      'This instrument is influenced by market sentiment and related economic '
      'data.';

  static const _indices = {'HSI', 'NIKKEI', 'DJIA', 'NASDAQ'};

  static String explain(String instrument) {
    final normalized = instrument.trim().toUpperCase();

    final note = _notes[normalized];
    if (note != null) {
      return note;
    }

    if (isCryptoMarketInstrument(normalized)) {
      return _cryptoNote;
    }

    if (_indices.contains(normalized)) {
      return _indexNote;
    }

    return _fallbackNote;
  }
}
