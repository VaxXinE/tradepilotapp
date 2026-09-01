import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/repositories/market_repository.dart';

void main() {
  test('getLiveQuotes parses a valid response and server timestamp', () async {
    final repository = MarketRepository(
      _dioWithResponse({
        'data': [
          {
            'instrument': 'EUR/USD',
            'symbol': 'EURUSD',
            'price': 1.085,
            'changePercent': 0.25,
          },
        ],
        'updatedAt': '2026-08-21T10:00:00Z',
      }),
    );

    final snapshot = await repository.getLiveQuotes();

    expect(snapshot.quotes.single.instrument, 'EUR/USD');
    expect(snapshot.quotes.single.price, 1.085);
    expect(snapshot.updatedAt, DateTime.parse('2026-08-21T10:00:00Z'));
  });

  test('getLiveQuotes rejects an invalid response shape', () async {
    final repository = MarketRepository(_dioWithResponse({'data': {}}));

    expect(repository.getLiveQuotes(), throwsFormatException);
  });

  test('getLiveQuotes accepts an empty market response', () async {
    final snapshot = await MarketRepository(
      _dioWithResponse({'data': []}),
    ).getLiveQuotes();

    expect(snapshot.quotes, isEmpty);
  });

  test('getLiveQuotes propagates API failures', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 503),
          ),
        ),
      ),
    );

    expect(MarketRepository(dio).getLiveQuotes(), throwsA(isA<DioException>()));
  });

  test('getCandles skips malformed bars and sorts valid bars', () async {
    final dio = _dioWithResponse({
      'candles': [
        {
          'date': '2026-01-02T00:00:00Z',
          'open': 2,
          'high': 3,
          'low': 1,
          'close': 2.5,
        },
        {'date': 'rusak'},
        {
          'date': '2026-01-03T00:00:00Z',
          'open': 10,
          'high': 5,
          'low': 1,
          'close': 8,
        },
        {
          'date': '2026-01-01T00:00:00Z',
          'open': 1,
          'high': 2,
          'low': 0.5,
          'close': 1.5,
        },
      ],
    });

    final candles = await MarketRepository(
      dio,
    ).getCandles(instrument: 'XAU/USD', timeframe: '1h');

    expect(candles, hasLength(2));
    expect(candles.first.date, DateTime.parse('2026-01-01T00:00:00Z'));
    expect(candles.last.date, DateTime.parse('2026-01-02T00:00:00Z'));
  });

  test('getCandles parses and sorts daily or weekly API dates', () async {
    final repository = MarketRepository(
      _dioWithResponse({
        'candles': [
          {
            'date': '25 Aug 2026',
            'open': 4600,
            'high': 4700,
            'low': 4550,
            'close': 4650,
          },
          {
            'date': '29 Aug 2025',
            'open': 3300,
            'high': 3400,
            'low': 3250,
            'close': 3350,
          },
        ],
      }),
    );

    final candles = await repository.getCandles(
      instrument: 'XAU/USD',
      timeframe: '1D',
    );

    expect(candles, hasLength(2));
    expect(candles.first.date, DateTime.utc(2025, 8, 29));
    expect(candles.last.date, DateTime.utc(2026, 8, 25));
  });

  test(
    'getRelevantCalendar normalizes input and skips invalid events',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.queryParameters['instrument'], 'XAU/USD');
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'events': [
                    {
                      'event': 'FOMC Decision',
                      'currency': 'usd',
                      'impact': 'high',
                      'epochMs': 1787342400000,
                      'forecast': '5.25%',
                    },
                    {'currency': 'USD'},
                  ],
                },
              ),
            );
          },
        ),
      );

      final events = await MarketRepository(
        dio,
      ).getRelevantCalendar(' xau/usd ');

      expect(events, hasLength(1));
      expect(events.single.currency, 'USD');
      expect(events.single.isHighImpact, isTrue);
    },
  );

  test('getRelevantCalendar accepts an empty response', () async {
    final events = await MarketRepository(
      _dioWithResponse({'events': []}),
    ).getRelevantCalendar('EUR/USD');

    expect(events, isEmpty);
  });

  test('getRelevantCalendar rejects malformed instruments', () async {
    expect(
      MarketRepository(Dio()).getRelevantCalendar('../admin'),
      throwsArgumentError,
    );
  });
}

Dio _dioWithResponse(Object? data) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) =>
          handler.resolve(Response(requestOptions: options, data: data)),
    ),
  );
  return dio;
}
