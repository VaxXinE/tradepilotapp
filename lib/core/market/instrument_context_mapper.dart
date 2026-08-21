import 'market_sessions.dart';

/// Beginner-friendly explanation of what typically drives an instrument.
///
/// Educational only — does not imply a direction or trading signal.
class InstrumentContextMapper {
  InstrumentContextMapper._();

  static const Map<String, String> _notes = {
    'XAU/USD':
        'Emas biasanya sensitif terhadap kebijakan suku bunga dan '
        'pergerakan dolar AS (USD).',
    'XAG/USD':
        'Perak cenderung mengikuti pola emas, namun pergerakannya '
        'sering lebih tajam.',
    'BRENT':
        'Minyak sensitif terhadap pasokan global, kebijakan OPEC, dan '
        'kondisi ekonomi dunia.',
    'DXY':
        'Indeks dolar AS mengukur kekuatan USD terhadap mata uang '
        'utama lainnya.',
    'EUR/USD':
        'Pasangan ini bergerak mengikuti kebijakan bank sentral Eropa '
        '(ECB) dan Amerika (The Fed).',
    'GBP/USD':
        'Pasangan ini sensitif terhadap data ekonomi Inggris (BoE) dan '
        'dolar AS.',
    'AUD/USD':
        'Pasangan ini terpengaruh harga komoditas dan kebijakan bank '
        'sentral Australia (RBA).',
    'USD/CHF':
        'Franc Swiss sering dianggap aset safe haven, jadi pasangan ini '
        'bereaksi terhadap sentimen risiko global.',
    'USD/JPY':
        'Pasangan ini dipengaruhi kebijakan suku bunga Jepang (BoJ) dan '
        'dolar AS.',
    'USD/IDR':
        'Rupiah dipengaruhi kebijakan Bank Indonesia serta arus modal '
        'asing ke pasar Indonesia.',
  };

  static const _cryptoNote =
      'Market kripto berjalan 24/7 dan cenderung sensitif terhadap '
      'sentimen pasar, likuiditas, dan berita regulasi.';

  static const _indexNote =
      'Indeks saham mengikuti performa gabungan saham-saham besar dan '
      'sensitif terhadap berita ekonomi makro.';

  static const _fallbackNote =
      'Pergerakan instrumen ini dipengaruhi oleh sentimen pasar dan '
      'data ekonomi terkait.';

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
