import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';
import 'package:tradepilotapp/repositories/watchlist_repository.dart';

void main() {
  test('keeps rich items and safely encodes slash when removing', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);

          if (options.method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'items': [
                    {
                      'instrument': 'XAU/USD',
                      'addedAt': '2026-08-21T10:00:00Z',
                      'mostRecentAnalysisId': 42,
                      'mostRecentAnalysisAt': '2026-08-21T09:00:00Z',
                    },
                  ],
                },
              ),
            );
            return;
          }

          if (options.method == 'POST') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'instrument': 'EUR/USD',
                  'addedAt': '2026-08-21T11:00:00Z',
                  'mostRecentAnalysisId': null,
                  'mostRecentAnalysisAt': null,
                },
              ),
            );
            return;
          }

          handler.resolve(
            Response(requestOptions: options, data: {'message': 'removed'}),
          );
        },
      ),
    );
    final repository = WatchlistRepository(
      TradePilotClient(baseUrl: 'https://example.test/api', dio: dio),
    );

    final items = await repository.getWatchlist();
    final added = await repository.addInstrument(' eur/usd ');
    await repository.removeInstrument(' xau/usd ');

    expect(items.single.instrument, 'XAU/USD');
    expect(items.single.mostRecentAnalysisId, 42);
    expect(added?.instrument, 'EUR/USD');
    expect(requests[1].data, {'instrument': 'EUR/USD'});
    expect(
      requests.last.uri.toString(),
      'https://example.test/api/watchlist/XAU%2FUSD',
    );
  });

  test('rejects an empty instrument before sending a request', () async {
    final repository = WatchlistRepository(
      TradePilotClient(baseUrl: 'https://example.test/api'),
    );

    await expectLater(repository.addInstrument('  '), throwsArgumentError);
    await expectLater(repository.removeInstrument('  '), throwsArgumentError);
  });
}
