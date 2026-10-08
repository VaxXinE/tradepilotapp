import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/credit_provider.dart';
import 'package:tradepilotapp/repositories/topup_repository.dart';

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

  test('credit flow is read-only and only loads the balance', () async {
    final (provider, adapter) = await _provider();

    await provider.loadBalance();

    expect(provider.balance, 10);
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      ['GET /topups/balance'],
    );
    expect(
      adapter.requests.where((request) => request.method == 'POST'),
      isEmpty,
    );
  });

  test('resume refresh only runs while a top-up is in progress', () async {
    final (provider, adapter) = await _provider();
    await provider.loadBalance();
    adapter.requests.clear();

    await provider.refreshIfAwaitingTopup();
    expect(adapter.requests, isEmpty);
    expect(provider.isAwaitingTopup, isFalse);

    provider.markTopupStarted();
    expect(provider.isAwaitingTopup, isTrue);

    // Paid but the balance has not moved yet: keep watching.
    await provider.refreshIfAwaitingTopup();
    expect(adapter.requests, hasLength(1));
    expect(provider.isAwaitingTopup, isTrue);

    // Credits arrived: the balance updates and watching stops.
    adapter.balance = 25;
    await provider.refreshIfAwaitingTopup();
    expect(provider.balance, 25);
    expect(provider.isAwaitingTopup, isFalse);

    adapter.requests.clear();
    await provider.refreshIfAwaitingTopup();
    expect(adapter.requests, isEmpty);
  });

  test('does not leak backend internals when balance fails', () async {
    final (provider, adapter) = await _provider();
    adapter.failBalance = true;

    await provider.loadBalance();

    expect(provider.balanceError, isNot(contains('SQL')));
    expect(provider.isLoadingBalance, isFalse);
  });
}

Future<(CreditProvider, _CreditAdapter)> _provider() async {
  final auth = AuthProvider();
  await pumpEventQueue();
  auth
    ..status = AuthStatus.authenticated
    ..user = User(
      (builder) => builder
        ..id = 1
        ..email = 'user@example.com'
        ..displayName = 'User'
        ..role = UserRoleEnum.user
        ..selectedMode = UserSelectedModeEnum.beginner
        ..themePreference = UserThemePreferenceEnum.dark
        ..createdAt = DateTime.utc(2026)
        ..onboardingCompleted = true
        ..hasPassword = true,
    );

  final adapter = _CreditAdapter();
  auth.client.dio.httpClientAdapter = adapter;
  final provider = CreditProvider(auth, TopupRepository(auth.client));
  addTearDown(provider.dispose);
  await pumpEventQueue();
  adapter.requests.clear();
  return (provider, adapter);
}

class _CreditAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  bool failBalance = false;
  int balance = 10;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (failBalance) {
      return _json({'error': 'SQL connection details'}, 500);
    }
    return _json({'balance': balance}, 200);
  }

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
