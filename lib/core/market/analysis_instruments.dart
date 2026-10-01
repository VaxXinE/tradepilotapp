/// Instruments a NEW analysis may be started for.
///
/// Mirrors `ANALYSIS_INSTRUMENT_OPTIONS` on the web analyze page and the
/// server's `VERIFIED_ANALYSIS_INSTRUMENTS`: the four core instruments plus
/// four FX pairs whose price and history sources are verified. Anything else
/// can only be *requested*; the server rejects it with HTTP 400.
///
/// Never use this to filter historical rows: older analyses keep whatever
/// instrument they were created with.
class AnalysisInstrumentOption {
  const AnalysisInstrumentOption(this.code, this.name, this.aliases);

  final String code;
  final String name;
  final List<String> aliases;
}

const analysisCoreInstruments = ['XAU/USD', 'BRENT', 'HSI', 'NIKKEI'];

const analysisInstrumentOptions = [
  AnalysisInstrumentOption('XAU/USD', 'Gold', ['GOLD', 'XAUUSD']),
  AnalysisInstrumentOption('BRENT', 'Brent crude oil', [
    'CRUDE',
    'BRENT OIL',
    'BCO',
    'UK OIL',
    'UKOIL',
    'UK-OIL',
  ]),
  AnalysisInstrumentOption('HSI', 'Hang Seng Index', ['HANG SENG', 'HANGSENG']),
  AnalysisInstrumentOption('NIKKEI', 'Nikkei 225', ['JAPAN 225', 'NIKKEI 225']),
  AnalysisInstrumentOption('EUR/USD', 'Euro / US dollar', [
    'EURUSD',
    'EURO DOLLAR',
  ]),
  AnalysisInstrumentOption('GBP/USD', 'British pound / US dollar', [
    'GBPUSD',
    'CABLE',
    'POUND DOLLAR',
  ]),
  AnalysisInstrumentOption('AUD/USD', 'Australian dollar / US dollar', [
    'AUDUSD',
    'AUSSIE',
  ]),
  AnalysisInstrumentOption('USD/JPY', 'US dollar / Japanese yen', [
    'USDJPY',
    'DOLLAR YEN',
  ]),
];

final Set<String> verifiedAnalysisInstruments = {
  for (final option in analysisInstrumentOptions) option.code,
};

bool isVerifiedAnalysisInstrument(String instrument) =>
    verifiedAnalysisInstruments.contains(instrument);

/// Codes that map onto an already verified instrument and so can never be
/// requested (the Brent aliases the server also refuses).
const _alreadyCoveredAliases = {'BCO', 'UKOIL', 'UK-OIL'};

final _requestCodePattern = RegExp(
  r'^[A-Z0-9]{2,12}(?:[/.:-][A-Z0-9]{1,12})?$',
);

String _normalize(String query) => query.trim().toUpperCase();

/// Options matching [query]. An empty query lists only the non-core options,
/// because the core four are already on the main grid.
List<AnalysisInstrumentOption> matchAnalysisInstruments(String query) {
  final search = _normalize(query);
  return [
    for (final option in analysisInstrumentOptions)
      if ((search.isNotEmpty ||
              !analysisCoreInstruments.contains(option.code)) &&
          [
            option.code,
            option.name,
            ...option.aliases,
          ].any((term) => term.toUpperCase().contains(search)))
        option,
  ];
}

/// The verified option whose code or alias equals [query] exactly.
AnalysisInstrumentOption? exactAnalysisInstrument(String query) {
  final search = _normalize(query);
  for (final option in analysisInstrumentOptions) {
    if (option.code == search || option.aliases.contains(search)) return option;
  }
  return null;
}

/// [query] normalised, when it is a well-formed code we may collect interest
/// for; null otherwise.
String? instrumentRequestCode(String query) {
  final search = _normalize(query);
  if (search.isEmpty ||
      search.length > 25 ||
      verifiedAnalysisInstruments.contains(search) ||
      _alreadyCoveredAliases.contains(search) ||
      // An exact alias (e.g. CABLE) selects its instrument; nothing to request.
      exactAnalysisInstrument(search) != null ||
      !_requestCodePattern.hasMatch(search)) {
    return null;
  }
  return search;
}
