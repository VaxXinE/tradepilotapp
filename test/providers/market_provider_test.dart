import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/models/market_models.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/market_provider.dart';
import 'package:tradepilotapp/repositories/market_repository.dart';

typedef _QuoteSnapshot = ({List<LiveMarketQuote> quotes, DateTime? updatedAt});

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

  test('logout resets user-scoped and selected market state', () async {
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);
    auth
      ..status = AuthStatus.authenticated
      ..user = _user(1);
    final provider = MarketProvider(auth, _FakeMarketRepository());
    addTearDown(provider.dispose);

    provider
      ..selectedInstrument = 'BTC/USD'
      ..selectedTimeframe = '4h'
      ..quotes = {'BTC/USD': _quote}
      ..quotesUpdatedAt = DateTime.utc(2026, 8, 21)
      ..marketError = 'error lama'
      ..watchlist = {'BTC/USD'};

    auth
      ..status = AuthStatus.unauthenticated
      ..user = null
      ..notifyListeners();

    expect(provider.selectedInstrument, 'XAU/USD');
    expect(provider.selectedTimeframe, '1h');
    expect(provider.quotes, isEmpty);
    expect(provider.quotesUpdatedAt, isNull);
    expect(provider.marketError, isNull);
    expect(provider.watchlist, isEmpty);
  });

  test(
    'loadQuotes deduplicates requests and preserves data on failure',
    () async {
      final repository = _FakeMarketRepository();
      final auth = AuthProvider();
      await Future<void>.delayed(Duration.zero);
      final provider = MarketProvider(auth, repository);
      addTearDown(provider.dispose);

      final pending = Completer<_QuoteSnapshot>();
      repository.pending = pending;

      final first = provider.loadQuotes(force: true);
      final duplicate = provider.loadQuotes(force: true);

      expect(repository.calls, 1);

      pending.complete((
        quotes: [_quote],
        updatedAt: DateTime.utc(2026, 8, 21),
      ));
      await Future.wait([first, duplicate]);

      expect(provider.quoteFor('BTC/USD')?.price, 65000);

      repository
        ..pending = null
        ..error = DioException(requestOptions: RequestOptions());

      await provider.loadQuotes(force: true);

      expect(provider.quoteFor('BTC/USD')?.price, 65000);
      expect(provider.marketError, 'Gagal memuat harga live.');

      repository.error = null;
      await provider.loadQuotes(force: true);

      expect(provider.marketError, isNull);
      expect(repository.calls, 3);
    },
  );
}

const _quote = LiveMarketQuote(
  instrument: 'BTC/USD',
  symbol: 'BTCUSD',
  price: 65000,
  changePercent: 1.2,
  direction: 'up',
);

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

class _FakeMarketRepository extends MarketRepository {
  _FakeMarketRepository() : super(Dio());

  int calls = 0;
  Object? error;
  Completer<_QuoteSnapshot>? pending;

  @override
  Future<_QuoteSnapshot> getLiveQuotes() {
    calls++;

    final failure = error;
    if (failure != null) {
      return Future.error(failure);
    }

    return pending?.future ??
        Future.value((quotes: [_quote], updatedAt: DateTime.now()));
  }
}
