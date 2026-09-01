import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:tradepilotapp/models/market_context.dart';
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
      ..marketError = 'error lama';

    auth
      ..status = AuthStatus.unauthenticated
      ..user = null
      ..notifyListeners();

    expect(provider.selectedInstrument, 'XAU/USD');
    expect(provider.selectedTimeframe, '1h');
    expect(provider.quotes, isEmpty);
    expect(provider.quotesUpdatedAt, isNull);
    expect(provider.marketError, isNull);
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

  test(
    'selectTimeframe requests candle data for the selected timeframe',
    () async {
      final repository = _FakeMarketRepository();
      final auth = AuthProvider();
      await Future<void>.delayed(Duration.zero);
      final provider = MarketProvider(auth, repository);
      addTearDown(provider.dispose);

      await provider.selectTimeframe('4h', force: true);

      expect(provider.selectedTimeframe, '4h');
      expect(repository.candleRequests, [('XAU/USD', '4h')]);
      expect(provider.selectedCandles.single.close, 104);
    },
  );

  test(
    'an old timeframe response cannot overwrite the latest selection',
    () async {
      final repository = _FakeMarketRepository();
      final oldResponse = Completer<List<MarketCandle>>();
      final latestResponse = Completer<List<MarketCandle>>();
      repository.candleResponses
        ..['4h'] = oldResponse
        ..['1D'] = latestResponse;
      final auth = AuthProvider();
      await Future<void>.delayed(Duration.zero);
      final provider = MarketProvider(auth, repository);
      addTearDown(provider.dispose);

      final oldRequest = provider.selectTimeframe('4h', force: true);
      final latestRequest = provider.selectTimeframe('1D', force: true);
      latestResponse.complete([_candle(200, 210)]);
      await latestRequest;
      oldResponse.complete([_candle(100, 90)]);
      await oldRequest;

      expect(provider.selectedTimeframe, '1D');
      expect(provider.selectedCandles.single.close, 210);
    },
  );

  test('loads and caches calendar with high-impact helpers', () async {
    final repository = _FakeMarketRepository();
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);
    final provider = MarketProvider(auth, repository);
    addTearDown(provider.dispose);

    await provider.selectInstrument('XAU/USD', force: true);
    await provider.getRelevantCalendarFor('xau/usd');

    expect(repository.calendarCalls, 1);
    expect(provider.hasEconomicCalendar, isTrue);
    expect(provider.highImpactEvents.single.currency, 'USD');
  });

  test(
    'an old calendar response cannot overwrite the latest instrument',
    () async {
      final repository = _FakeMarketRepository();
      final oldResponse = Completer<List<EconomicCalendarEvent>>();
      final latestResponse = Completer<List<EconomicCalendarEvent>>();
      repository.calendarResponses
        ..['EUR/USD'] = oldResponse
        ..['BTC/USD'] = latestResponse;
      final auth = AuthProvider();
      await Future<void>.delayed(Duration.zero);
      final provider = MarketProvider(auth, repository);
      addTearDown(provider.dispose);

      final oldRequest = provider.selectInstrument('EUR/USD', force: true);
      final latestRequest = provider.selectInstrument('BTC/USD', force: true);
      latestResponse.complete([_event('USD', 'Crypto Regulation Hearing')]);
      await latestRequest;
      oldResponse.complete([_event('EUR', 'ECB Speech')]);
      await oldRequest;

      expect(provider.selectedInstrument, 'BTC/USD');
      expect(
        provider.selectedCalendar.single.event,
        'Crypto Regulation Hearing',
      );
    },
  );

  test('selectedMarketContext is null before any market data loads', () async {
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);
    final provider = MarketProvider(auth, _FakeMarketRepository());
    addTearDown(provider.dispose);

    expect(provider.selectedMarketContext, isNull);
  });

  test(
    'selectedMarketContext derives from the currently selected candles',
    () async {
      final auth = AuthProvider();
      await Future<void>.delayed(Duration.zero);
      final provider = MarketProvider(auth, _FakeMarketRepository());
      addTearDown(provider.dispose);

      provider
        ..selectedInstrument = 'XAU/USD'
        ..selectedCandles = [_candle(100, 100), _candle(100, 104)];

      final context = provider.selectedMarketContext;

      expect(context, isNotNull);
      expect(context!.instrument, 'XAU/USD');
      expect(context.trend, MarketTrend.bullish);
    },
  );

  test(
    'selectedTechnicalSummary is null before any technical data loads',
    () async {
      final auth = AuthProvider();
      await Future<void>.delayed(Duration.zero);
      final provider = MarketProvider(auth, _FakeMarketRepository());
      addTearDown(provider.dispose);

      expect(provider.selectedTechnicalSummary, isNull);
    },
  );

  test(
    'selectedTechnicalSummary derives from the currently selected technical snapshot',
    () async {
      final auth = AuthProvider();
      await Future<void>.delayed(Duration.zero);
      final provider = MarketProvider(auth, _FakeMarketRepository());
      addTearDown(provider.dispose);

      provider.selectedTechnical = const BeginnerTechnicalSnapshot(
        lastClose: 100,
        change1dPercent: 0.1,
        rsi: 65,
        rsiSignal: 'Buy',
        macdAction: 'Buy',
        buyCount: 3,
        sellCount: 1,
        neutralCount: 0,
        overallSignal: 'Buy',
      );

      final summary = provider.selectedTechnicalSummary;

      expect(summary, isNotNull);
      expect(summary!.trend, MarketTrend.bullish);
    },
  );

  test('an old technical response cannot overwrite the latest selection '
      '(stale response protection)', () async {
    final repository = _FakeMarketRepository();
    final oldResponse = Completer<BeginnerTechnicalSnapshot?>();
    final latestResponse = Completer<BeginnerTechnicalSnapshot?>();
    repository.technicalResponses
      ..['4h'] = oldResponse
      ..['1D'] = latestResponse;
    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);
    final provider = MarketProvider(auth, repository);
    addTearDown(provider.dispose);

    final oldRequest = provider.selectTimeframe('4h', force: true);
    final latestRequest = provider.selectTimeframe('1D', force: true);
    latestResponse.complete(
      const BeginnerTechnicalSnapshot(
        lastClose: 100,
        change1dPercent: 1,
        rsi: 60,
        rsiSignal: 'Buy',
        macdAction: 'Buy',
        buyCount: 3,
        sellCount: 0,
        neutralCount: 0,
        overallSignal: 'Buy',
      ),
    );
    await latestRequest;
    oldResponse.complete(
      const BeginnerTechnicalSnapshot(
        lastClose: 90,
        change1dPercent: -1,
        rsi: 25,
        rsiSignal: 'Sell',
        macdAction: 'Sell',
        buyCount: 0,
        sellCount: 3,
        neutralCount: 0,
        overallSignal: 'Sell',
      ),
    );
    await oldRequest;

    expect(provider.selectedTimeframe, '1D');
    expect(provider.selectedTechnicalSummary?.trend, MarketTrend.bullish);
  });
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
  final List<(String, String)> candleRequests = [];
  final Map<String, Completer<List<MarketCandle>>> candleResponses = {};
  final Map<String, Completer<BeginnerTechnicalSnapshot?>> technicalResponses =
      {};
  int calendarCalls = 0;
  final Map<String, Completer<List<EconomicCalendarEvent>>> calendarResponses =
      {};

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

  @override
  Future<List<MarketCandle>> getCandles({
    required String instrument,
    required String timeframe,
  }) {
    candleRequests.add((instrument, timeframe));
    return candleResponses[timeframe]?.future ??
        Future.value([_candle(100, 104)]);
  }

  @override
  Future<BeginnerTechnicalSnapshot?> getTechnical({
    required String instrument,
    required String timeframe,
  }) {
    return technicalResponses[timeframe]?.future ?? Future.value(null);
  }

  @override
  Future<List<EconomicCalendarEvent>> getRelevantCalendar(String instrument) {
    calendarCalls++;
    return calendarResponses[instrument]?.future ??
        Future.value([_event('USD', 'FOMC Decision')]);
  }
}

MarketCandle _candle(double open, double close) => MarketCandle(
  date: DateTime.utc(2026, 8, 21),
  open: open,
  high: math.max(open, close) + 2,
  low: math.min(open, close) - 2,
  close: close,
);

EconomicCalendarEvent _event(String currency, String name) =>
    EconomicCalendarEvent(
      time: '19:00',
      currency: currency,
      impact: 'high',
      event: name,
      previous: '5.00%',
      forecast: '5.25%',
      actual: '',
      date: '2026-08-21T12:00:00Z',
      epochMs: 1787313600000,
      whyTraderCare: '',
    );
