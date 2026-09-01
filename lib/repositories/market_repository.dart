import 'package:dio/dio.dart';

import '../models/market_models.dart';

class MarketRepository {
  const MarketRepository(this._dio);

  final Dio _dio;

  Future<({List<LiveMarketQuote> quotes, DateTime? updatedAt})>
  getLiveQuotes() async {
    final response = await _dio.get('/quotes/live');
    final body = marketMap(response.data);
    final rawQuotes = body['data'];

    if (rawQuotes is! List) {
      throw const FormatException('Invalid live quote payload.');
    }

    return (
      quotes: [
        for (final raw in rawQuotes) LiveMarketQuote.fromJson(marketMap(raw)),
      ],
      updatedAt: DateTime.tryParse(body['updatedAt']?.toString() ?? ''),
    );
  }

  Future<List<MarketCandle>> getCandles({
    required String instrument,
    required String timeframe,
  }) async {
    final response = await _dio.get(
      '/historical/candles',
      queryParameters: {'instrument': instrument, 'timeframe': timeframe},
    );
    final rawCandles = marketMap(response.data)['candles'];

    if (rawCandles is! List) {
      throw const FormatException('Invalid candle payload.');
    }

    final candles = <MarketCandle>[];
    for (final raw in rawCandles) {
      try {
        candles.add(MarketCandle.fromJson(marketMap(raw)));
      } catch (_) {
        // Abaikan bar upstream yang rusak tanpa menggagalkan seluruh chart.
      }
    }
    candles.sort((a, b) => a.date.compareTo(b.date));
    return candles;
  }

  Future<BeginnerTechnicalSnapshot?> getTechnical({
    required String instrument,
    required String timeframe,
  }) async {
    final response = await _dio.get(
      '/historical/indicators',
      queryParameters: {'instrument': instrument, 'timeframe': timeframe},
    );
    final indicators = marketMap(marketMap(response.data)['indicators']);

    return indicators.isEmpty
        ? null
        : BeginnerTechnicalSnapshot.fromJson(indicators);
  }

  Future<List<EconomicCalendarEvent>> getRelevantCalendar(
    String instrument,
  ) async {
    final normalized = instrument.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{2,10}(?:/[A-Z0-9]{2,10})?$').hasMatch(normalized)) {
      throw ArgumentError.value(
        instrument,
        'instrument',
        'Invalid instrument.',
      );
    }

    final response = await _dio.get(
      '/calendar/relevant',
      queryParameters: {'instrument': normalized, 'maxItems': 8},
    );
    final rawEvents = marketMap(response.data)['events'];

    if (rawEvents is! List) {
      return const [];
    }

    final events = <EconomicCalendarEvent>[];
    for (final raw in rawEvents) {
      try {
        events.add(EconomicCalendarEvent.fromJson(marketMap(raw)));
      } catch (_) {
        // Satu event upstream yang rusak tidak boleh mengosongkan calendar.
      }
    }
    events.sort((a, b) {
      final left = a.eventDateTime;
      final right = b.eventDateTime;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });
    return events;
  }
}
