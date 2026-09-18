import 'package:dio/dio.dart';

class VerifiedStorePurchase {
  const VerifiedStorePurchase({
    required this.creditsGranted,
    required this.balance,
    required this.alreadyProcessed,
    required this.finalizedByServer,
  });

  final int creditsGranted;
  final int balance;
  final bool alreadyProcessed;
  final bool finalizedByServer;
}

abstract class StorePurchaseVerifier {
  Future<VerifiedStorePurchase> verify({
    required String source,
    required String productId,
    required String verificationData,
    String? transactionId,
  });
}

class StorePurchaseRepository implements StorePurchaseVerifier {
  const StorePurchaseRepository(this._dio);

  final Dio _dio;

  @override
  Future<VerifiedStorePurchase> verify({
    required String source,
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async {
    if (verificationData.trim().isEmpty) {
      throw const FormatException('Missing store verification data.');
    }

    final payload = <String, dynamic>{
      'source': source,
      'productId': productId,
      'verificationData': verificationData,
    };
    if (transactionId != null) {
      payload['transactionId'] = transactionId;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/topups/store-purchases/verify',
      data: payload,
    );
    final data = response.data;
    final creditsGranted = data?['creditsGranted'];
    final balance = data?['balance'];
    final alreadyProcessed = data?['alreadyProcessed'];
    final finalizedByServer = data?['finalizedByServer'];

    if (creditsGranted is! int ||
        balance is! int ||
        alreadyProcessed is! bool ||
        finalizedByServer is! bool) {
      throw const FormatException('Invalid store verification response.');
    }

    return VerifiedStorePurchase(
      creditsGranted: creditsGranted,
      balance: balance,
      alreadyProcessed: alreadyProcessed,
      finalizedByServer: finalizedByServer,
    );
  }
}
