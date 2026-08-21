import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/repositories/market_repository.dart';

void main() {
  test('getCandles skips malformed bars and sorts valid bars', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(
            requestOptions: options,
            data: {
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
                  'date': '2026-01-01T00:00:00Z',
                  'open': 1,
                  'high': 2,
                  'low': 0.5,
                  'close': 1.5,
                },
              ],
            },
          ),
        ),
      ),
    );

    final candles = await MarketRepository(
      dio,
    ).getCandles(instrument: 'XAU/USD', timeframe: '1h');

    expect(candles, hasLength(2));
    expect(candles.first.date, DateTime.parse('2026-01-01T00:00:00Z'));
    expect(candles.last.date, DateTime.parse('2026-01-02T00:00:00Z'));
  });
}
