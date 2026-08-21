import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';
import 'package:tradepilotapp/repositories/price_alert_repository.dart';

void main() {
  test('lists, creates, and deletes price alerts', () async {
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
                  'alerts': [
                    {
                      'id': 1,
                      'instrument': 'XAU/USD',
                      'targetPrice': '2500.5',
                      'triggerDirection': 'above',
                      'note': 'cek ulang',
                      'status': 'active',
                      'createdAt': '2026-08-21T10:00:00Z',
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
                  'id': 2,
                  'instrument': 'EUR/USD',
                  'targetPrice': '1.1',
                  'triggerDirection': 'below',
                  'status': 'active',
                  'createdAt': '2026-08-21T11:00:00Z',
                },
              ),
            );
            return;
          }

          handler.resolve(
            Response(requestOptions: options, data: {'message': 'deleted'}),
          );
        },
      ),
    );

    final repository = PriceAlertRepository(
      TradePilotClient(baseUrl: 'https://example.test/api', dio: dio),
    );

    final alerts = await repository.getAlerts();
    final created = await repository.createAlert(
      instrument: ' eur/usd ',
      targetPrice: 1.1,
      triggerAbove: false,
      note: '  cek lagi  ',
    );
    await repository.deleteAlert(2);

    expect(alerts.single.instrument, 'XAU/USD');
    expect(alerts.single.targetPrice, '2500.5');
    expect(created?.instrument, 'EUR/USD');
    expect(requests[1].data, {
      'instrument': 'EUR/USD',
      'targetPrice': 1.1,
      'triggerDirection': 'below',
      'note': 'cek lagi',
      'lang': 'id',
    });
    expect(requests.last.path, '/user-price-alerts/2');
  });

  test('rejects an empty instrument before sending a request', () async {
    final repository = PriceAlertRepository(
      TradePilotClient(baseUrl: 'https://example.test/api'),
    );

    await expectLater(
      repository.createAlert(
        instrument: '  ',
        targetPrice: 100,
        triggerAbove: true,
      ),
      throwsArgumentError,
    );
  });

  test(
    'rejects a non-positive target price before sending a request',
    () async {
      final repository = PriceAlertRepository(
        TradePilotClient(baseUrl: 'https://example.test/api'),
      );

      await expectLater(
        repository.createAlert(
          instrument: 'XAU/USD',
          targetPrice: 0,
          triggerAbove: true,
        ),
        throwsArgumentError,
      );

      await expectLater(
        repository.createAlert(
          instrument: 'XAU/USD',
          targetPrice: -5,
          triggerAbove: true,
        ),
        throwsArgumentError,
      );
    },
  );

  test('rejects a note longer than 200 characters', () async {
    final repository = PriceAlertRepository(
      TradePilotClient(baseUrl: 'https://example.test/api'),
    );

    await expectLater(
      repository.createAlert(
        instrument: 'XAU/USD',
        targetPrice: 100,
        triggerAbove: true,
        note: 'a' * 201,
      ),
      throwsArgumentError,
    );
  });
}
