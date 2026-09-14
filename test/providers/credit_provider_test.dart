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

  test('loads config, balance and history through the typed client', () async {
    final (provider, adapter, _) = await _provider();

    await provider.refreshAll();

    expect(provider.balance, 10);
    expect(provider.config?.rupiahPerCredit, 5000);
    expect(provider.config?.qrisImageUrl, 'https://cdn.example.com/qris.png');
    expect(provider.history, hasLength(20));
    expect(provider.history.first.id, 25);
    expect(provider.history.last.id, 6);
    expect(provider.historyTotal, 25);
    expect(provider.balanceError, isNull);
    expect(provider.configError, isNull);
    expect(provider.historyError, isNull);

    expect(
      adapter.requests.map((options) => '${options.method} ${options.path}'),
      containsAll([
        'GET /topups/balance',
        'GET /topups/config',
        'GET /topups/mine',
      ]),
    );
  });

  test('history pages 20 at a time and refresh never duplicates', () async {
    final (provider, adapter, _) = await _provider();

    await provider.loadHistory(refresh: true);
    expect(provider.history, hasLength(20));
    expect(provider.hasMoreHistory, isTrue);

    await provider.loadMoreHistory();
    expect(provider.history, hasLength(25));
    expect(provider.hasMoreHistory, isFalse);
    expect(
      provider.history.map((request) => request.id).toSet(),
      hasLength(25),
    );

    // Page 2 overlaps page 1 on the server (a new row shifted the window);
    // a refresh must still not duplicate anything.
    await provider.loadHistory(refresh: true);
    expect(
      provider.history.map((request) => request.id).toSet(),
      hasLength(provider.history.length),
    );

    // Sorted newest first regardless of merge order.
    final createdAt = provider.history.map((request) => request.createdAt);
    expect(
      createdAt.toList(),
      orderedEquals(createdAt.toList()..sort((a, b) => b.compareTo(a))),
    );

    final historyRequests = adapter.requests
        .where((options) => options.path == '/topups/mine')
        .toList();
    expect(historyRequests, isNotEmpty);
    for (final options in historyRequests) {
      expect(options.queryParameters['limit'], TopupRepository.historyPageSize);
      expect(options.queryParameters['limit'], 20);
    }
    expect(historyRequests.map((o) => o.queryParameters['page']), [1, 2, 1]);
  });

  test('submitting a top-up posts once and lands in history', () async {
    final (provider, adapter, _) = await _provider();

    await provider.loadHistory(refresh: true);
    final before = provider.history.length;

    final created = await provider.submitTopup(
      amountRupiah: 50000,
      paymentReferenceNote: '  BCA 1234  ',
      proofObjectPath: 'topups/proof-1.jpg',
    );

    expect(created?.id, 99);
    expect(provider.submitError, isNull);
    expect(provider.isSubmitting, isFalse);
    expect(provider.history.first.id, 99);
    expect(provider.history, hasLength(before + 1));

    final posts = adapter.requests
        .where((options) => options.method == 'POST')
        .toList();
    expect(posts, hasLength(1));

    final body = Map<String, dynamic>.from(posts.single.data as Map);
    expect(body['amountRupiah'], 50000);
    expect(body['paymentReferenceNote'], 'BCA 1234');
    expect(body['proofObjectPath'], 'topups/proof-1.jpg');
  });

  test('double submit only fires one request', () async {
    final (provider, adapter, _) = await _provider();

    final results = await Future.wait([
      provider.submitTopup(amountRupiah: 50000),
      provider.submitTopup(amountRupiah: 50000),
    ]);

    expect(results.where((request) => request != null), hasLength(1));
    expect(
      adapter.requests.where((options) => options.method == 'POST'),
      hasLength(1),
    );
  });

  test('rejects a non-positive amount before hitting the network', () async {
    final (provider, adapter, _) = await _provider();

    final created = await provider.submitTopup(amountRupiah: 0);

    expect(created, isNull);
    expect(provider.submitError, 'The top-up amount must be greater than 0.');
    expect(
      adapter.requests.where((options) => options.method == 'POST'),
      isEmpty,
    );

    provider.clearSubmitError();
    expect(provider.submitError, isNull);
  });

  test('surfaces backend validation messages on 4xx', () async {
    final (provider, _, _) = await _provider();
    await provider.loadConfig();

    final created = await provider.submitTopup(amountRupiah: 1);

    expect(created, isNull);
    expect(provider.submitError, 'Nominal minimal Rp10.000.');
    expect(provider.isSubmitting, isFalse);
  });

  test('hides server internals on 5xx but stays recoverable', () async {
    final (provider, adapter, _) = await _provider();
    adapter.balanceStatus = 500;

    await provider.loadBalance();

    expect(
      provider.balanceError,
      'The server is having trouble. Try again shortly.',
    );
    expect(provider.balanceError, isNot(contains('SQL')));
    expect(provider.isLoadingBalance, isFalse);

    adapter.balanceStatus = 200;
    await provider.loadBalance();

    expect(provider.balance, 10);
    expect(provider.balanceError, isNull);
  });

  test('reports a network failure and recovers on retry', () async {
    final (provider, adapter, _) = await _provider();
    adapter.offline = true;

    await provider.loadHistory(refresh: true);

    expect(
      provider.historyError,
      'Could not reach the server. Check your internet connection.',
    );
    expect(provider.isLoadingHistory, isFalse);

    adapter.offline = false;
    await provider.loadHistory(refresh: true);

    expect(provider.historyError, isNull);
    expect(provider.history, hasLength(20));
  });

  test('a 401 reports an expired session and ends the session', () async {
    final (provider, adapter, _) = await _provider();
    adapter.balanceStatus = 401;

    await provider.loadBalance();
    await pumpEventQueue();

    // The shared interceptor closes the session; the provider only explains it.
    expect(provider.isLoadingBalance, isFalse);
    expect(provider.balance, isNull);
  });

  test('a failing balance does not disturb config or history', () async {
    final (provider, adapter, _) = await _provider();
    adapter.balanceStatus = 500;

    await provider.refreshAll();

    expect(provider.balanceError, isNotNull);
    expect(provider.config?.rupiahPerCredit, 5000);
    expect(provider.configError, isNull);
    expect(provider.history, hasLength(20));
    expect(provider.historyError, isNull);
  });

  test('a silent refresh keeps the last known balance on failure', () async {
    final (provider, adapter, _) = await _provider();

    await provider.loadBalance();
    expect(provider.balance, 10);

    adapter.balanceStatus = 500;
    await provider.loadBalance(silent: true);

    expect(provider.balance, 10);
    expect(provider.balanceError, isNull);
  });

  test('logout clears every credit state', () async {
    final (provider, _, auth) = await _provider();

    await provider.refreshAll();
    expect(provider.history, isNotEmpty);

    auth
      ..status = AuthStatus.unauthenticated
      ..user = null
      ..notifyListeners();

    expect(provider.balance, isNull);
    expect(provider.config, isNull);
    expect(provider.history, isEmpty);
    expect(provider.historyTotal, 0);
    expect(provider.historyPage, 1);
    expect(provider.balanceError, isNull);
    expect(provider.historyError, isNull);
  });

  test('credits preview follows the backend rate', () async {
    final (provider, _, _) = await _provider();

    expect(provider.creditsFor(50000), isNull);

    await provider.loadConfig();

    expect(provider.creditsFor(50000), 10);
    expect(provider.creditsFor(0), isNull);
  });
}

Future<(CreditProvider, _TopupsAdapter, AuthProvider)> _provider() async {
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

  final adapter = _TopupsAdapter();
  auth.client.dio.httpClientAdapter = adapter;

  final provider = CreditProvider(auth, TopupRepository(auth.client));
  addTearDown(provider.dispose);

  // The constructor prefetches the balance; drain it so per-test request
  // counts only cover what the test itself triggers.
  await pumpEventQueue();
  adapter.requests.clear();

  return (provider, adapter, auth);
}

/// 25 rows, newest first, so page 1 holds 20 and page 2 holds the last 5.
List<Map<String, dynamic>> _rows() {
  return List.generate(25, (index) {
    final id = 25 - index;
    return {
      'id': id,
      'userId': 1,
      'amountRupiah': 50000,
      'creditsRequested': 10,
      'conversionRateSnapshot': 5000,
      'paymentReferenceNote': null,
      'proofObjectPath': null,
      'status': id.isEven ? 'approved' : 'pending',
      'reviewedByUserId': id.isEven ? 2 : null,
      'reviewedAt': id.isEven ? '2026-09-07T10:00:00.000Z' : null,
      'reviewNote': id.isEven ? 'Verified' : null,
      'creditsGranted': id.isEven ? 10 : null,
      'createdAt': DateTime.utc(
        2026,
        9,
        1,
      ).add(Duration(hours: id)).toIso8601String(),
    };
  });
}

class _TopupsAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int balanceStatus = 200;
  bool offline = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'network is unreachable',
      );
    }

    if (options.path == '/topups/balance' && balanceStatus != 200) {
      return _json(
        balanceStatus == 401
            ? {'error': 'Unauthorized'}
            : {'error': 'SQL error: relation "credits" does not exist'},
        balanceStatus,
      );
    }

    switch (options.path) {
      case '/topups/config':
        return _json({
          'rupiahPerCredit': 5000,
          'qrisImageUrl': 'https://cdn.example.com/qris.png',
        }, 200);

      case '/topups/balance':
        return _json({'balance': 10}, 200);

      case '/topups':
        final body = Map<String, dynamic>.from(options.data as Map);
        final amount = body['amountRupiah'] as int;

        if (amount < 10000) {
          return _json({'error': 'Nominal minimal Rp10.000.'}, 400);
        }

        return _json({
          ..._rows().first,
          'id': 99,
          'amountRupiah': amount,
          'status': 'pending',
          'reviewedByUserId': null,
          'reviewedAt': null,
          'reviewNote': null,
          'creditsGranted': null,
          'paymentReferenceNote': body['paymentReferenceNote'],
          'proofObjectPath': body['proofObjectPath'],
          'createdAt': DateTime.utc(2026, 9, 9).toIso8601String(),
        }, 201);

      case '/topups/mine':
        final page = int.tryParse('${options.queryParameters['page']}') ?? 1;
        final limit = int.tryParse('${options.queryParameters['limit']}') ?? 20;
        final rows = _rows();
        final start = (page - 1) * limit;
        final end = (start + limit).clamp(0, rows.length);

        return _json({
          'requests': start >= rows.length
              ? const <Map<String, dynamic>>[]
              : rows.sublist(start, end),
          'total': rows.length,
          'page': page,
          'limit': limit,
        }, 200);

      default:
        return _json({'message': 'ok'}, 200);
    }
  }

  ResponseBody _json(Object body, int status) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
