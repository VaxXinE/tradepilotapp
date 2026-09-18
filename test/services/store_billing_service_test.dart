import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/credit_provider.dart';
import 'package:tradepilotapp/repositories/store_purchase_repository.dart';
import 'package:tradepilotapp/repositories/topup_repository.dart';
import 'package:tradepilotapp/services/store_billing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  test(
    'finishes a purchase only after backend verification succeeds',
    () async {
      final auth = await _authenticatedUser();
      final credit = _FakeCreditProvider(auth);
      await pumpEventQueue();
      credit.balanceRefreshes = 0;
      final gateway = _FakeStoreGateway();
      final verifier = _FakeVerifier();
      final service = StoreBillingService(
        auth,
        credit,
        verifier,
        gateway: gateway,
        autoInitialize: false,
      );
      addTearDown(service.dispose);
      addTearDown(credit.dispose);

      gateway.emit(_purchase());
      await pumpEventQueue();

      expect(verifier.calls, 1);
      expect(gateway.completed, 1);
      expect(credit.balanceRefreshes, 1);
      expect(service.error, isNull);
    },
  );

  test('keeps an unverified purchase unfinished for a safe retry', () async {
    final auth = await _authenticatedUser();
    final credit = _FakeCreditProvider(auth);
    await pumpEventQueue();
    credit.balanceRefreshes = 0;
    final gateway = _FakeStoreGateway();
    final verifier = _FakeVerifier()..fail = true;
    final service = StoreBillingService(
      auth,
      credit,
      verifier,
      gateway: gateway,
      autoInitialize: false,
    );
    addTearDown(service.dispose);
    addTearDown(credit.dispose);

    gateway.emit(_purchase());
    await pumpEventQueue();

    expect(verifier.calls, 1);
    expect(gateway.completed, 0);
    expect(credit.balanceRefreshes, 0);
    expect(service.error, isNotNull);
  });

  test('does not finish a purchase already finalized by the backend', () async {
    final auth = await _authenticatedUser();
    final credit = _FakeCreditProvider(auth);
    await pumpEventQueue();
    credit.balanceRefreshes = 0;
    final gateway = _FakeStoreGateway();
    final verifier = _FakeVerifier()..finalizedByServer = true;
    final service = StoreBillingService(
      auth,
      credit,
      verifier,
      gateway: gateway,
      autoInitialize: false,
    );
    addTearDown(service.dispose);
    addTearDown(credit.dispose);

    gateway.emit(_purchase());
    await pumpEventQueue();

    expect(verifier.calls, 1);
    expect(gateway.completed, 0);
    expect(credit.balanceRefreshes, 1);
  });
}

Future<AuthProvider> _authenticatedUser() async {
  final auth = AuthProvider();
  await pumpEventQueue();
  auth
    ..status = AuthStatus.authenticated
    ..user = User(
      (builder) => builder
        ..id = 7
        ..email = 'buyer@example.com'
        ..displayName = 'Buyer'
        ..role = UserRoleEnum.user
        ..selectedMode = UserSelectedModeEnum.beginner
        ..themePreference = UserThemePreferenceEnum.dark
        ..createdAt = DateTime.utc(2026)
        ..onboardingCompleted = true
        ..hasPassword = true,
    );
  return auth;
}

PurchaseDetails _purchase() {
  final purchase = PurchaseDetails(
    purchaseID: 'transaction-1',
    productID: 'id.tradepilot.app.credits.20',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local-proof',
      serverVerificationData: 'server-proof',
      source: 'app_store',
    ),
    transactionDate: '1',
    status: PurchaseStatus.purchased,
  );
  purchase.pendingCompletePurchase = true;
  return purchase;
}

class _FakeStoreGateway implements StoreGateway {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();
  int completed = 0;

  void emit(PurchaseDetails purchase) => _updates.add([purchase]);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    throw UnimplementedError();
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    required bool autoConsume,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed++;
  }
}

class _FakeVerifier implements StorePurchaseVerifier {
  int calls = 0;
  bool fail = false;
  bool finalizedByServer = false;

  @override
  Future<VerifiedStorePurchase> verify({
    required String source,
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async {
    calls++;
    if (fail) throw StateError('invalid receipt');
    return VerifiedStorePurchase(
      creditsGranted: 20,
      balance: 20,
      alreadyProcessed: false,
      finalizedByServer: finalizedByServer,
    );
  }
}

class _FakeCreditProvider extends CreditProvider {
  _FakeCreditProvider(AuthProvider auth)
    : super(auth, TopupRepository(auth.client));

  int balanceRefreshes = 0;

  @override
  Future<void> loadBalance({bool silent = false}) async {
    balanceRefreshes++;
  }
}
