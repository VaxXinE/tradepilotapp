import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/repositories/store_purchase_repository.dart';

void main() {
  test('sends store proof and parses an idempotent verification', () async {
    late RequestOptions captured;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'creditsGranted': 20,
                'balance': 42,
                'alreadyProcessed': false,
                'finalizedByServer': true,
              },
            ),
          );
        },
      ),
    );

    final result = await StorePurchaseRepository(dio).verify(
      source: 'google_play',
      productId: 'id.tradepilot.app.credits.20',
      verificationData: 'purchase-token',
      transactionId: 'order-id',
    );

    expect(captured.path, '/topups/store-purchases/verify');
    expect(captured.data, {
      'source': 'google_play',
      'productId': 'id.tradepilot.app.credits.20',
      'verificationData': 'purchase-token',
      'transactionId': 'order-id',
    });
    expect(result.creditsGranted, 20);
    expect(result.balance, 42);
    expect(result.finalizedByServer, isTrue);
  });

  test('rejects missing proof before making a request', () async {
    expect(
      StorePurchaseRepository(Dio()).verify(
        source: 'app_store',
        productId: 'id.tradepilot.app.credits.20',
        verificationData: ' ',
      ),
      throwsFormatException,
    );
  });

  test('rejects an invalid backend response', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(requestOptions: options, data: {'balance': 1}),
        ),
      ),
    );

    expect(
      StorePurchaseRepository(dio).verify(
        source: 'app_store',
        productId: 'id.tradepilot.app.credits.20',
        verificationData: 'signed-transaction',
      ),
      throwsFormatException,
    );
  });
}
