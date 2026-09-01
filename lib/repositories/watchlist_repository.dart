import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

class WatchlistRepository {
  const WatchlistRepository(this._client);

  final TradePilotClient _client;

  Future<List<WatchlistItem>> getWatchlist() async {
    final response = await _client.watchlist.getWatchlist();
    return response.data?.items.toList() ?? const [];
  }

  Future<WatchlistItem?> addInstrument(String instrument) async {
    final normalized = _normalize(instrument);
    final response = await _client.watchlist.addWatchlistItem(
      addWatchlistBody: AddWatchlistBody(
        (builder) => builder.instrument = normalized,
      ),
    );
    return response.data;
  }

  Future<void> removeInstrument(String instrument) async {
    final normalized = _normalize(instrument);
    final baseUri = Uri.parse(_client.dio.options.baseUrl);

    // Generated client tidak meng-encode slash pada path parameter.
    final uri = baseUri.replace(
      pathSegments: [
        ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        'watchlist',
        normalized,
      ],
    );

    await _client.dio.deleteUri(uri);
  }

  String _normalize(String instrument) {
    final normalized = instrument.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        instrument,
        'instrument',
        'Instrument tidak boleh kosong.',
      );
    }
    return normalized;
  }
}
