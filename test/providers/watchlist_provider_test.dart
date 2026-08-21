import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';
import 'package:tradepilotapp/providers/auth_provider.dart';
import 'package:tradepilotapp/providers/watchlist_provider.dart';
import 'package:tradepilotapp/repositories/watchlist_repository.dart';

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

  test('loads rich items and adds/removes normalized instruments', () async {
    final repository = _FakeWatchlistRepository()..loaded = [_item('BTC/USD')];
    final auth = await _authenticatedUser();
    final provider = WatchlistProvider(auth, repository);
    addTearDown(provider.dispose);

    await provider.loadWatchlist();
    expect(provider.items.single.instrument, 'BTC/USD');
    expect(provider.items.single.mostRecentAnalysisId, 42);

    expect(await provider.addInstrument(' btc/usd '), isFalse);
    expect(repository.addCalls, 0);

    expect(await provider.addInstrument(' eur/usd '), isTrue);
    expect(provider.isWatchlisted('EUR/USD'), isTrue);
    expect(repository.addCalls, 1);

    expect(await provider.removeInstrument(' eur/usd '), isTrue);
    expect(provider.isWatchlisted('EUR/USD'), isFalse);
    expect(repository.removed, ['EUR/USD']);
  });

  test('logout resets state and ignores stale responses', () async {
    final pending = Completer<List<WatchlistItem>>();
    final repository = _FakeWatchlistRepository()..pendingLoad = pending;
    final auth = await _authenticatedUser();
    final provider = WatchlistProvider(auth, repository);
    addTearDown(provider.dispose);

    final load = provider.loadWatchlist();
    auth
      ..status = AuthStatus.unauthenticated
      ..user = null
      ..notifyListeners();
    pending.complete([_item('BTC/USD')]);
    await load;

    expect(provider.items, isEmpty);
    expect(provider.isLoading, isFalse);

    provider.reset();
    expect(provider.items, isEmpty);
    expect(provider.error, isNull);
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

WatchlistItem _item(String instrument) => WatchlistItem(
  (builder) => builder
    ..instrument = instrument
    ..addedAt = DateTime.utc(2026, 8, 21)
    ..mostRecentAnalysisId = 42
    ..mostRecentAnalysisAt = DateTime.utc(2026, 8, 20),
);

class _FakeWatchlistRepository extends WatchlistRepository {
  _FakeWatchlistRepository()
    : super(TradePilotClient(baseUrl: 'https://example.test/api'));

  List<WatchlistItem> loaded = const [];
  Completer<List<WatchlistItem>>? pendingLoad;
  int addCalls = 0;
  final List<String> removed = [];

  @override
  Future<List<WatchlistItem>> getWatchlist() {
    return pendingLoad?.future ?? Future.value(loaded);
  }

  @override
  Future<WatchlistItem?> addInstrument(String instrument) async {
    addCalls++;
    return _item(instrument);
  }

  @override
  Future<void> removeInstrument(String instrument) async {
    removed.add(instrument);
  }
}
