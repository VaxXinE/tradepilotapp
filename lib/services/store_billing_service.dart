import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/store_credit_product.dart';
import '../providers/auth_provider.dart';
import '../providers/credit_provider.dart';
import '../repositories/store_purchase_repository.dart';

abstract class StoreGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    required bool autoConsume,
  });

  Future<void> completePurchase(PurchaseDetails purchase);
}

class InAppPurchaseGateway implements StoreGateway {
  const InAppPurchaseGateway();

  InAppPurchase get _store => InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _store.purchaseStream;

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _store.queryProductDetails(identifiers);

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    required bool autoConsume,
  }) => _store.buyConsumable(
    purchaseParam: purchaseParam,
    autoConsume: autoConsume,
  );

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _store.completePurchase(purchase);
}

class StoreBillingService extends ChangeNotifier {
  StoreBillingService(
    this._auth,
    this._credit,
    this._repository, {
    StoreGateway gateway = const InAppPurchaseGateway(),
    bool autoInitialize = true,
  }) : _gateway = gateway {
    _purchaseSubscription = _gateway.purchaseStream.listen(
      _handlePurchases,
      onError: (Object _) {
        _error = 'Store purchase update failed.';
        _isPurchasing = false;
        notifyListeners();
      },
    );
    if (autoInitialize) unawaited(initialize());
  }

  final AuthProvider _auth;
  final CreditProvider _credit;
  final StorePurchaseVerifier _repository;
  final StoreGateway _gateway;

  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  List<ProductDetails> _products = const [];
  bool _isLoading = false;
  bool _isAvailable = false;
  bool _isPurchasing = false;
  String? _error;

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;

  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _isAvailable = await _gateway.isAvailable();
      if (!_isAvailable) return;

      final response = await _gateway.queryProductDetails(
        storeCreditProductIds,
      );
      if (response.error != null) {
        throw StateError(response.error!.message);
      }
      if (response.notFoundIDs.isNotEmpty) {
        throw StateError(
          'Store products are not configured: ${response.notFoundIDs.join(', ')}',
        );
      }

      _products = response.productDetails.toList()
        ..sort(
          (left, right) => (creditsForStoreProduct(left.id) ?? 0).compareTo(
            creditsForStoreProduct(right.id) ?? 0,
          ),
        );
    } catch (_) {
      _isAvailable = false;
      _error = 'Store products are temporarily unavailable.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchase(ProductDetails product) async {
    final userId = _auth.user?.id;
    if (_auth.status != AuthStatus.authenticated || userId == null) {
      _error = 'Your session has expired. Please sign in again.';
      notifyListeners();
      return;
    }
    if (_isPurchasing || !storeCreditProductIds.contains(product.id)) return;

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final started = await _gateway.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: _accountToken(userId),
        ),
        // Google Play consumption happens on the backend after verification.
        autoConsume: false,
      );
      if (!started) {
        _isPurchasing = false;
        _error = 'The store could not start this purchase.';
        notifyListeners();
      }
    } catch (_) {
      _isPurchasing = false;
      _error = 'The store could not start this purchase.';
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isPurchasing = true;
          break;
        case PurchaseStatus.canceled:
          _isPurchasing = false;
          break;
        case PurchaseStatus.error:
          _isPurchasing = false;
          _error = purchase.error?.message ?? 'The purchase failed.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndFinish(purchase);
          break;
      }
    }
    notifyListeners();
  }

  Future<void> _verifyAndFinish(PurchaseDetails purchase) async {
    if (!storeCreditProductIds.contains(purchase.productID)) {
      _error = 'Unknown store product.';
      _isPurchasing = false;
      return;
    }

    try {
      final verified = await _repository.verify(
        source: purchase.verificationData.source,
        productId: purchase.productID,
        verificationData: purchase.verificationData.serverVerificationData,
        transactionId: purchase.purchaseID,
      );

      // Google consumables are finalized by the backend. StoreKit
      // transactions must still be finished on this device.
      if (!verified.finalizedByServer && purchase.pendingCompletePurchase) {
        await _gateway.completePurchase(purchase);
      }

      await _credit.loadBalance(silent: true);
      _error = null;
    } catch (_) {
      // Do not finish an unverified transaction. The store will redeliver it,
      // and the idempotent backend endpoint can safely retry later.
      _error = 'Purchase verification failed. Your payment will be retried.';
    } finally {
      _isPurchasing = false;
    }
  }

  String _accountToken(int userId) {
    final bytes = sha256.convert(utf8.encode('tradepilot-user:$userId')).bytes;
    final hex = bytes
        .take(16)
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription.cancel());
    super.dispose();
  }
}
