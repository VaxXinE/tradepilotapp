import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/price_alert_provider.dart';
import 'package:tradepilotapp/repositories/price_alert_repository.dart';

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

  group('createAlert validation', () {
    test(
      'rejects an empty instrument without calling the repository',
      () async {
        final repository = _FakePriceAlertRepository();
        final auth = await _authenticatedUser();
        final provider = PriceAlertProvider(auth, repository);
        addTearDown(provider.dispose);

        final ok = await provider.createAlert(
          instrument: '   ',
          targetPrice: 100,
          triggerAbove: true,
        );

        expect(ok, isFalse);
        expect(provider.error, 'Instrumen tidak boleh kosong.');
        expect(repository.createCalls, 0);
      },
    );

    test(
      'rejects a non-positive target price without calling the repository',
      () async {
        final repository = _FakePriceAlertRepository();
        final auth = await _authenticatedUser();
        final provider = PriceAlertProvider(auth, repository);
        addTearDown(provider.dispose);

        expect(
          await provider.createAlert(
            instrument: 'XAU/USD',
            targetPrice: 0,
            triggerAbove: true,
          ),
          isFalse,
        );
        expect(provider.error, 'Target harga harus lebih besar dari 0.');

        expect(
          await provider.createAlert(
            instrument: 'XAU/USD',
            targetPrice: -5,
            triggerAbove: true,
          ),
          isFalse,
        );
        expect(repository.createCalls, 0);
      },
    );

    test(
      'rejects a note longer than 200 characters without calling the repository',
      () async {
        final repository = _FakePriceAlertRepository();
        final auth = await _authenticatedUser();
        final provider = PriceAlertProvider(auth, repository);
        addTearDown(provider.dispose);

        final ok = await provider.createAlert(
          instrument: 'XAU/USD',
          targetPrice: 100,
          triggerAbove: true,
          note: 'a' * 201,
        );

        expect(ok, isFalse);
        expect(provider.error, 'Catatan maksimal 200 karakter.');
        expect(repository.createCalls, 0);
      },
    );
  });

  test('createAlert prepends the new alert on success', () async {
    final repository = _FakePriceAlertRepository();
    final auth = await _authenticatedUser();
    final provider = PriceAlertProvider(auth, repository);
    addTearDown(provider.dispose);

    final ok = await provider.createAlert(
      instrument: ' xau/usd ',
      targetPrice: 2500,
      triggerAbove: true,
    );

    expect(ok, isTrue);
    expect(provider.alerts.single.instrument, 'XAU/USD');
    expect(provider.isCreating, isFalse);
  });

  test('createAlert prevents a duplicate concurrent submission', () async {
    final repository = _FakePriceAlertRepository()
      ..pendingCreate = Completer<UserPriceAlert?>();
    final auth = await _authenticatedUser();
    final provider = PriceAlertProvider(auth, repository);
    addTearDown(provider.dispose);

    final first = provider.createAlert(
      instrument: 'XAU/USD',
      targetPrice: 2500,
      triggerAbove: true,
    );

    expect(provider.isCreating, isTrue);

    final duplicate = await provider.createAlert(
      instrument: 'XAU/USD',
      targetPrice: 2500,
      triggerAbove: true,
    );

    expect(duplicate, isFalse);
    expect(repository.createCalls, 1);

    repository.pendingCreate!.complete(_alert(id: 1));
    expect(await first, isTrue);
  });

  test('a stale create response cannot overwrite state after logout '
      '(stale request race)', () async {
    final repository = _FakePriceAlertRepository()
      ..pendingCreate = Completer<UserPriceAlert?>();
    final auth = await _authenticatedUser();
    final provider = PriceAlertProvider(auth, repository);
    addTearDown(provider.dispose);

    final createFuture = provider.createAlert(
      instrument: 'XAU/USD',
      targetPrice: 2500,
      triggerAbove: true,
    );

    auth
      ..status = AuthStatus.unauthenticated
      ..user = null
      ..notifyListeners();

    repository.pendingCreate!.complete(_alert(id: 1));

    expect(await createFuture, isFalse);
    expect(provider.alerts, isEmpty);
  });

  test('keeps a friendly error message when create fails', () async {
    final repository = _FakePriceAlertRepository()
      ..createError = StateError('network down');
    final auth = await _authenticatedUser();
    final provider = PriceAlertProvider(auth, repository);
    addTearDown(provider.dispose);

    final ok = await provider.createAlert(
      instrument: 'XAU/USD',
      targetPrice: 2500,
      triggerAbove: true,
    );

    expect(ok, isFalse);
    expect(provider.error, 'Gagal membuat price alert.');
    expect(provider.alerts, isEmpty);
  });

  test('deleteAlert removes the alert and blocks a duplicate delete while '
      'in flight', () async {
    final repository = _FakePriceAlertRepository()..loaded = [_alert(id: 5)];
    final auth = await _authenticatedUser();
    final provider = PriceAlertProvider(auth, repository);
    addTearDown(provider.dispose);

    await provider.loadAlerts();
    expect(provider.alerts, hasLength(1));

    repository.pendingDelete = Completer<void>();
    final first = provider.deleteAlert(5);

    expect(provider.isDeleting(5), isTrue);
    expect(await provider.deleteAlert(5), isFalse);

    repository.pendingDelete!.complete();

    expect(await first, isTrue);
    expect(provider.alerts, isEmpty);
    expect(provider.isDeleting(5), isFalse);
  });

  test('logout clears alerts, error, and pending state', () async {
    final repository = _FakePriceAlertRepository()..loaded = [_alert(id: 1)];
    final auth = await _authenticatedUser();
    final provider = PriceAlertProvider(auth, repository);
    addTearDown(provider.dispose);

    await provider.loadAlerts();
    expect(provider.alerts, hasLength(1));

    auth
      ..status = AuthStatus.unauthenticated
      ..user = null
      ..notifyListeners();

    expect(provider.alerts, isEmpty);
    expect(provider.error, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.isCreating, isFalse);
  });
}

Future<AuthProvider> _authenticatedUser() async {
  final auth = AuthProvider();
  await Future<void>.delayed(Duration.zero);
  return auth
    ..status = AuthStatus.authenticated
    ..user = _user(1);
}

User _user(int id) => User(
  (builder) => builder
    ..id = id
    ..email = 'user$id@example.com'
    ..displayName = 'User $id'
    ..role = UserRoleEnum.user
    ..selectedMode = UserSelectedModeEnum.beginner
    ..themePreference = UserThemePreferenceEnum.dark
    ..onboardingCompleted = true,
);

UserPriceAlert _alert({
  required int id,
  String instrument = 'XAU/USD',
  String targetPrice = '2500',
  bool triggerAbove = true,
  String? note,
  UserPriceAlertStatusEnum status = UserPriceAlertStatusEnum.active,
}) => UserPriceAlert(
  (b) => b
    ..id = id
    ..instrument = instrument
    ..targetPrice = targetPrice
    ..triggerDirection = triggerAbove
        ? UserPriceAlertTriggerDirectionEnum.above
        : UserPriceAlertTriggerDirectionEnum.below
    ..note = note
    ..status = status
    ..createdAt = DateTime.utc(2026, 8, 21),
);

class _FakePriceAlertRepository extends PriceAlertRepository {
  _FakePriceAlertRepository()
    : super(TradePilotClient(baseUrl: 'https://example.test/api'));

  List<UserPriceAlert> loaded = const [];
  Completer<UserPriceAlert?>? pendingCreate;
  int createCalls = 0;
  Object? createError;
  Completer<void>? pendingDelete;
  Object? deleteError;

  @override
  Future<List<UserPriceAlert>> getAlerts() async => loaded;

  @override
  Future<UserPriceAlert?> createAlert({
    required String instrument,
    required double targetPrice,
    required bool triggerAbove,
    String? note,
  }) async {
    createCalls++;

    if (createError case final error?) {
      throw error;
    }

    if (pendingCreate case final pending?) {
      return pending.future;
    }

    return _alert(
      id: createCalls,
      instrument: instrument,
      targetPrice: targetPrice.toString(),
      triggerAbove: triggerAbove,
      note: note,
    );
  }

  @override
  Future<void> deleteAlert(int id) async {
    if (deleteError case final error?) {
      throw error;
    }

    if (pendingDelete case final pending?) {
      await pending.future;
    }
  }
}
