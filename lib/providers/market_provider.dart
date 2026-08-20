import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

import '../models/market_models.dart';
import 'auth_provider.dart';

class MarketProvider extends ChangeNotifier {
  MarketProvider(this._authProvider) {
    _activeUserId = _currentUserId;

    _authProvider.addListener(_handleAuthChanged);
  }

  final AuthProvider _authProvider;

  TradePilotClient get _client => _authProvider.client;

  // ===========================================================================
  // SOURCE OF TRUTH — INSTRUMENTS
  // ===========================================================================

  /// Disamakan dengan Trade-Pilot web `prod`
  /// dan SUPPORTED_INSTRUMENTS backend.
  static const instrumentGroups = {
    'Futures': [
      'XAU/USD',
      'BRENT',
      'XAG/USD',
      'HSI',
      'NIKKEI',
      'DJIA',
      'NASDAQ',
      'DXY',
    ],
    'Forex': ['AUD/USD', 'EUR/USD', 'GBP/USD', 'USD/CHF', 'USD/JPY', 'USD/IDR'],
    'Crypto': ['BTC/USD', 'ETH/USD', 'SOL/USD', 'BNB/USD', 'XRP/USD'],
  };

  static final Set<String> supportedInstruments = {
    for (final group in instrumentGroups.values) ...group,
  };

  static const supportedTimeframes = {
    '1m',
    '5m',
    '15m',
    '30m',
    '1h',
    '4h',
    '1D',
    '1W',
  };

  // ===========================================================================
  // SELECTED MARKET
  // ===========================================================================

  String selectedInstrument = 'XAU/USD';

  String selectedTimeframe = '1h';

  List<MarketCandle> selectedCandles = const [];

  BeginnerTechnicalSnapshot? selectedTechnical;

  List<EconomicCalendarEvent> selectedCalendar = const [];

  bool isLoadingSelectedMarket = false;

  // ===========================================================================
  // LIVE QUOTES
  // ===========================================================================

  Map<String, LiveMarketQuote> quotes = {};

  bool isLoadingQuotes = false;

  DateTime? quotesUpdatedAt;

  Timer? _quoteTimer;

  bool _quotePollingEnabled = false;

  bool _quotesRequestInFlight = false;

  DateTime? _quotesFetchedAt;

  static const Duration _quoteRefreshInterval = Duration(seconds: 15);

  static const Duration _quoteClientCacheTtl = Duration(seconds: 10);

  LiveMarketQuote? quoteFor(String instrument) {
    return quotes[_normalizeInstrument(instrument)];
  }

  LiveMarketQuote? get selectedQuote {
    return quoteFor(selectedInstrument);
  }

  // ===========================================================================
  // WATCHLIST
  // ===========================================================================

  Set<String> watchlist = {};

  bool isLoadingWatchlist = false;

  bool _watchlistRequestInFlight = false;

  // ===========================================================================
  // ERRORS
  // ===========================================================================

  String? marketError;
  String? watchlistError;
  String? alertError;

  // ===========================================================================
  // CACHES
  // ===========================================================================

  final Map<String, List<MarketCandle>> _candleCache = {};

  final Map<String, DateTime> _candleFetchedAt = {};

  final Map<String, BeginnerTechnicalSnapshot> _technicalCache = {};

  final Map<String, DateTime> _technicalFetchedAt = {};

  final Map<String, List<EconomicCalendarEvent>> _calendarCache = {};

  final Map<String, DateTime> _calendarFetchedAt = {};

  final Map<String, Future<List<MarketCandle>>> _candleInFlight = {};

  final Map<String, Future<BeginnerTechnicalSnapshot?>> _technicalInFlight = {};

  final Map<String, Future<List<EconomicCalendarEvent>>> _calendarInFlight = {};

  static const Duration _candleCacheTtl = Duration(seconds: 30);

  static const Duration _technicalCacheTtl = Duration(seconds: 30);

  static const Duration _calendarCacheTtl = Duration(minutes: 30);

  int _selectionGeneration = 0;

  int? _activeUserId;

  int _sessionEpoch = 0;

  int _watchlistRequestId = 0;

  int _watchlistMutationRequestId = 0;

  bool isUpdatingWatchlist = false;

  // ===========================================================================
  // AUTH / USER-SCOPED STATE
  // ===========================================================================

  int? get _currentUserId {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }

    return _authProvider.user?.id;
  }

  bool _isCurrentUserSession({required int epoch, required int userId}) {
    return epoch == _sessionEpoch &&
        _authProvider.status == AuthStatus.authenticated &&
        _currentUserId == userId;
  }

  void _handleAuthChanged() {
    final nextUserId = _currentUserId;

    if (nextUserId == _activeUserId) {
      return;
    }

    _activeUserId = nextUserId;

    // Invalidasi semua response user-scoped
    // dari session sebelumnya.
    _sessionEpoch++;

    _watchlistRequestId++;
    _watchlistMutationRequestId++;

    _watchlistRequestInFlight = false;

    isUpdatingWatchlist = false;

    watchlist = {};

    isLoadingWatchlist = false;

    watchlistError = null;
    alertError = null;

    if (nextUserId == null) {
      setQuotePollingEnabled(false);
    } else {
      unawaited(loadWatchlist());
    }

    notifyListeners();
  }

  // ===========================================================================
  // LIVE QUOTE POLLING
  // ===========================================================================

  void setQuotePollingEnabled(bool enabled) {
    if (_quotePollingEnabled == enabled) {
      return;
    }

    _quotePollingEnabled = enabled;

    _quoteTimer?.cancel();
    _quoteTimer = null;

    if (!enabled) {
      return;
    }

    // Immediate fetch.
    unawaited(loadQuotes(force: true, silent: true));

    _quoteTimer = Timer.periodic(_quoteRefreshInterval, (_) {
      unawaited(loadQuotes(force: true, silent: true));
    });
  }

  Future<void> loadQuotes({bool force = false, bool silent = false}) async {
    if (_quotesRequestInFlight) {
      return;
    }

    final last = _quotesFetchedAt;

    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _quoteClientCacheTtl) {
      return;
    }

    _quotesRequestInFlight = true;

    if (!silent) {
      isLoadingQuotes = true;
      notifyListeners();
    }

    try {
      final response = await _client.dio.get('/quotes/live');

      final body = marketMap(response.data);

      final rawData = body['data'];

      if (rawData is! List) {
        throw const FormatException('Invalid live quote payload.');
      }

      final nextQuotes = <String, LiveMarketQuote>{};

      for (final raw in rawData) {
        final json = marketMap(raw);

        final quote = LiveMarketQuote.fromJson(json);

        if (quote.instrument.isEmpty || quote.price <= 0) {
          continue;
        }

        nextQuotes[_normalizeInstrument(quote.instrument)] = quote;
      }

      quotes = nextQuotes;

      _quotesFetchedAt = DateTime.now();

      quotesUpdatedAt =
          DateTime.tryParse(body['updatedAt']?.toString() ?? '') ??
          _quotesFetchedAt;

      marketError = null;
    } catch (e) {
      if (!silent) {
        marketError = _friendlyError(e, fallback: 'Gagal memuat harga live.');
      }
    } finally {
      _quotesRequestInFlight = false;

      if (!silent) {
        isLoadingQuotes = false;
      }

      notifyListeners();
    }
  }

  // ===========================================================================
  // SELECT INSTRUMENT
  // ===========================================================================

  Future<void> selectInstrument(
    String instrument, {
    String? timeframe,
    bool force = false,
  }) async {
    final normalized = _normalizeInstrument(instrument);

    if (!supportedInstruments.contains(normalized)) {
      marketError = 'Instrumen tidak didukung.';

      notifyListeners();
      return;
    }

    final nextTimeframe = timeframe ?? selectedTimeframe;

    if (!supportedTimeframes.contains(nextTimeframe)) {
      marketError = 'Timeframe tidak didukung.';

      notifyListeners();
      return;
    }

    selectedInstrument = normalized;

    selectedTimeframe = nextTimeframe;

    selectedCandles = const [];

    selectedTechnical = null;

    selectedCalendar = const [];

    await loadSelectedMarketData(force: force);
  }

  Future<void> selectTimeframe(String timeframe, {bool force = false}) async {
    if (!supportedTimeframes.contains(timeframe)) {
      marketError = 'Timeframe tidak didukung.';

      notifyListeners();
      return;
    }

    selectedTimeframe = timeframe;

    selectedCandles = const [];
    selectedTechnical = null;

    await loadSelectedTechnicalData(force: force);
  }

  Future<void> loadSelectedMarketData({bool force = false}) async {
    final generation = ++_selectionGeneration;

    final instrument = selectedInstrument;

    final timeframe = selectedTimeframe;

    isLoadingSelectedMarket = true;
    marketError = null;

    notifyListeners();

    var candles = const <MarketCandle>[];

    BeginnerTechnicalSnapshot? technical;

    var calendar = const <EconomicCalendarEvent>[];

    var candlesLoaded = false;
    var technicalLoaded = false;
    var calendarLoaded = false;

    Object? firstError;

    try {
      await Future.wait<void>([
        () async {
          try {
            candles = await getCandlesFor(instrument, timeframe, force: force);

            candlesLoaded = true;
          } catch (error) {
            firstError ??= error;
          }
        }(),

        () async {
          try {
            technical = await getTechnicalFor(
              instrument,
              timeframe,
              force: force,
            );

            technicalLoaded = true;
          } catch (error) {
            firstError ??= error;
          }
        }(),

        () async {
          try {
            calendar = await getRelevantCalendarFor(instrument, force: force);

            calendarLoaded = true;
          } catch (error) {
            firstError ??= error;
          }
        }(),
      ]);

      // User keburu ganti instrument/timeframe.
      // Jangan timpa selection terbaru dengan response lama.
      if (generation != _selectionGeneration ||
          instrument != selectedInstrument ||
          timeframe != selectedTimeframe) {
        return;
      }

      if (candlesLoaded) {
        selectedCandles = candles;
      }

      if (technicalLoaded) {
        selectedTechnical = technical;
      }

      if (calendarLoaded) {
        selectedCalendar = calendar;
      }

      if (firstError != null) {
        marketError = _friendlyError(
          firstError!,
          fallback: 'Sebagian data pasar belum tersedia.',
        );
      } else {
        marketError = null;
      }
    } finally {
      if (generation == _selectionGeneration) {
        isLoadingSelectedMarket = false;

        notifyListeners();
      }
    }
  }

  Future<void> loadSelectedTechnicalData({bool force = false}) async {
    final generation = ++_selectionGeneration;

    final instrument = selectedInstrument;

    final timeframe = selectedTimeframe;

    isLoadingSelectedMarket = true;

    marketError = null;

    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        getCandlesFor(instrument, timeframe, force: force),
        getTechnicalFor(instrument, timeframe, force: force),
      ]);

      if (generation != _selectionGeneration ||
          instrument != selectedInstrument ||
          timeframe != selectedTimeframe) {
        return;
      }

      selectedCandles = results[0] as List<MarketCandle>;

      selectedTechnical = results[1] as BeginnerTechnicalSnapshot?;
    } catch (e) {
      if (generation == _selectionGeneration) {
        marketError = _friendlyError(
          e,
          fallback: 'Gagal memuat data teknikal.',
        );
      }
    } finally {
      if (generation == _selectionGeneration) {
        isLoadingSelectedMarket = false;

        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // CANDLES
  // ===========================================================================

  Future<List<MarketCandle>> getCandlesFor(
    String instrument,
    String timeframe, {
    bool force = false,
  }) async {
    final normalized = _normalizeInstrument(instrument);

    _validateInstrument(normalized);

    _validateTimeframe(timeframe);

    final key = '$normalized|$timeframe';

    if (!force && _isFresh(_candleFetchedAt[key], _candleCacheTtl)) {
      return _candleCache[key] ?? const [];
    }

    final existing = _candleInFlight[key];

    if (existing != null) {
      return existing;
    }

    final future = _fetchCandles(normalized, timeframe);

    _candleInFlight[key] = future;

    try {
      final result = await future;

      _candleCache[key] = result;

      _candleFetchedAt[key] = DateTime.now();

      return result;
    } finally {
      _candleInFlight.remove(key);
    }
  }

  Future<List<MarketCandle>> _fetchCandles(
    String instrument,
    String timeframe,
  ) async {
    final response = await _client.dio.get(
      '/historical/candles',
      queryParameters: {'instrument': instrument, 'timeframe': timeframe},
    );

    final body = marketMap(response.data);

    final rawCandles = body['candles'];

    if (rawCandles is! List) {
      throw const FormatException('Invalid candle payload.');
    }

    final candles = <MarketCandle>[];

    for (final raw in rawCandles) {
      try {
        candles.add(MarketCandle.fromJson(marketMap(raw)));
      } catch (_) {
        // Skip malformed upstream bar.
      }
    }

    candles.sort((a, b) => a.date.compareTo(b.date));

    return candles;
  }

  // ===========================================================================
  // TECHNICAL INDICATORS
  // ===========================================================================

  Future<BeginnerTechnicalSnapshot?> getTechnicalFor(
    String instrument,
    String timeframe, {
    bool force = false,
  }) async {
    final normalized = _normalizeInstrument(instrument);

    _validateInstrument(normalized);

    _validateTimeframe(timeframe);

    final key = '$normalized|$timeframe';

    if (!force && _isFresh(_technicalFetchedAt[key], _technicalCacheTtl)) {
      return _technicalCache[key];
    }

    final existing = _technicalInFlight[key];

    if (existing != null) {
      return existing;
    }

    final future = _fetchTechnical(normalized, timeframe);

    _technicalInFlight[key] = future;

    try {
      final result = await future;

      if (result != null) {
        _technicalCache[key] = result;

        _technicalFetchedAt[key] = DateTime.now();
      }

      return result;
    } finally {
      _technicalInFlight.remove(key);
    }
  }

  Future<BeginnerTechnicalSnapshot?> _fetchTechnical(
    String instrument,
    String timeframe,
  ) async {
    final response = await _client.dio.get(
      '/historical/indicators',
      queryParameters: {'instrument': instrument, 'timeframe': timeframe},
    );

    final body = marketMap(response.data);

    final indicators = marketMap(body['indicators']);

    if (indicators.isEmpty) {
      return null;
    }

    return BeginnerTechnicalSnapshot.fromJson(indicators);
  }

  // ===========================================================================
  // ECONOMIC CALENDAR
  // ===========================================================================

  Future<List<EconomicCalendarEvent>> getRelevantCalendarFor(
    String instrument, {
    bool force = false,
  }) async {
    final normalized = _normalizeInstrument(instrument);

    _validateInstrument(normalized);

    final key = normalized;

    if (!force && _isFresh(_calendarFetchedAt[key], _calendarCacheTtl)) {
      return _calendarCache[key] ?? const [];
    }

    final existing = _calendarInFlight[key];

    if (existing != null) {
      return existing;
    }

    final future = _fetchRelevantCalendar(normalized);

    _calendarInFlight[key] = future;

    try {
      final result = await future;

      _calendarCache[key] = result;

      _calendarFetchedAt[key] = DateTime.now();

      return result;
    } finally {
      _calendarInFlight.remove(key);
    }
  }

  Future<List<EconomicCalendarEvent>> _fetchRelevantCalendar(
    String instrument,
  ) async {
    final response = await _client.dio.get(
      '/calendar/relevant',
      queryParameters: {'instrument': instrument, 'maxItems': 8},
    );

    final body = marketMap(response.data);

    final rawEvents = body['events'];

    if (rawEvents is! List) {
      return const [];
    }

    final events = <EconomicCalendarEvent>[];

    for (final raw in rawEvents) {
      events.add(EconomicCalendarEvent.fromJson(marketMap(raw)));
    }

    return events;
  }

  // ===========================================================================
  // WATCHLIST
  // ===========================================================================

  bool isWatchlisted(String instrument) {
    return watchlist.contains(_normalizeInstrument(instrument));
  }

  Future<void> loadWatchlist() async {
    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    if (_watchlistRequestInFlight) {
      return;
    }

    final epoch = _sessionEpoch;

    final requestId = ++_watchlistRequestId;

    _watchlistRequestInFlight = true;

    isLoadingWatchlist = true;

    notifyListeners();

    try {
      final response = await _client.watchlist.getWatchlist();

      if (!_isCurrentUserSession(epoch: epoch, userId: userId) ||
          requestId != _watchlistRequestId) {
        return;
      }

      final items = response.data?.items;

      watchlist = {
        if (items != null)
          for (final item in items) _normalizeInstrument(item.instrument),
      };

      watchlistError = null;
    } catch (error) {
      if (!_isCurrentUserSession(epoch: epoch, userId: userId) ||
          requestId != _watchlistRequestId) {
        return;
      }

      watchlistError = _friendlyError(
        error,
        fallback: 'Gagal memuat watchlist.',
      );
    } finally {
      if (requestId == _watchlistRequestId) {
        _watchlistRequestInFlight = false;

        if (_isCurrentUserSession(epoch: epoch, userId: userId)) {
          isLoadingWatchlist = false;

          notifyListeners();
        }
      }
    }
  }

  Future<bool> toggleWatchlist(String instrument) async {
    final userId = _currentUserId;

    if (userId == null) {
      watchlistError = 'Silakan login kembali.';

      notifyListeners();

      return false;
    }

    final normalized = _normalizeInstrument(instrument);

    if (!supportedInstruments.contains(normalized)) {
      watchlistError = 'Instrumen tidak didukung.';

      notifyListeners();

      return false;
    }

    // Hindari double-tap / request race.
    if (isUpdatingWatchlist) {
      return false;
    }

    final epoch = _sessionEpoch;

    final requestId = ++_watchlistMutationRequestId;

    final wasWatchlisted = watchlist.contains(normalized);

    isUpdatingWatchlist = true;

    // Optimistic UI.
    if (wasWatchlisted) {
      watchlist.remove(normalized);
    } else {
      watchlist.add(normalized);
    }

    watchlistError = null;

    notifyListeners();

    try {
      if (wasWatchlisted) {
        await _client.watchlist.removeWatchlistItem(instrument: normalized);
      } else {
        await _client.watchlist.addWatchlistItem(
          addWatchlistBody: AddWatchlistBody((builder) {
            builder.instrument = normalized;
          }),
        );
      }

      if (!_isCurrentUserSession(epoch: epoch, userId: userId) ||
          requestId != _watchlistMutationRequestId) {
        return false;
      }

      return true;
    } catch (error) {
      if (!_isCurrentUserSession(epoch: epoch, userId: userId) ||
          requestId != _watchlistMutationRequestId) {
        return false;
      }

      // Rollback optimistic update.
      if (wasWatchlisted) {
        watchlist.add(normalized);
      } else {
        watchlist.remove(normalized);
      }

      watchlistError = _friendlyError(
        error,
        fallback: 'Gagal memperbarui watchlist.',
      );

      notifyListeners();

      return false;
    } finally {
      if (requestId == _watchlistMutationRequestId &&
          _isCurrentUserSession(epoch: epoch, userId: userId)) {
        isUpdatingWatchlist = false;

        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // PRICE ALERT
  // ===========================================================================

  Future<bool> createPriceAlert({
    required String instrument,
    required double targetPrice,
    required bool triggerAbove,
    String? note,
  }) async {
    alertError = null;

    if (_authProvider.status != AuthStatus.authenticated) {
      alertError = 'Sesi login sudah berakhir.';

      notifyListeners();
      return false;
    }

    final userId = _currentUserId;

    if (userId == null) {
      alertError = 'Sesi login sudah berakhir.';

      notifyListeners();

      return false;
    }

    final epoch = _sessionEpoch;

    final normalized = _normalizeInstrument(instrument);

    if (!supportedInstruments.contains(normalized)) {
      alertError = 'Instrumen tidak didukung.';

      notifyListeners();
      return false;
    }

    if (!targetPrice.isFinite || targetPrice <= 0) {
      alertError = 'Target harga harus lebih besar dari 0.';

      notifyListeners();
      return false;
    }

    final cleanNote = note?.trim();

    if (cleanNote != null && cleanNote.length > 200) {
      alertError = 'Catatan maksimal 200 karakter.';

      notifyListeners();
      return false;
    }

    try {
      await _client.userPriceAlerts.createUserPriceAlert(
        createUserPriceAlertBody: CreateUserPriceAlertBody(
          (builder) => builder
            ..instrument = normalized
            ..targetPrice = targetPrice
            ..triggerDirection = triggerAbove
                ? CreateUserPriceAlertBodyTriggerDirectionEnum.above
                : CreateUserPriceAlertBodyTriggerDirectionEnum.below
            ..note = cleanNote
            ..lang = CreateUserPriceAlertBodyLangEnum.id,
        ),
      );
      if (!_isCurrentUserSession(epoch: epoch, userId: userId)) {
        return false;
      }

      alertError = null;

      notifyListeners();

      return true;
    } catch (e) {
      if (!_isCurrentUserSession(epoch: epoch, userId: userId)) {
        return false;
      }

      alertError = _friendlyError(e, fallback: 'Gagal membuat alert harga.');

      notifyListeners();

      return false;
    }
  }

  // ===========================================================================
  // UTILITY
  // ===========================================================================

  String _normalizeInstrument(String instrument) {
    return instrument.trim().toUpperCase();
  }

  void _validateInstrument(String instrument) {
    if (!supportedInstruments.contains(instrument)) {
      throw ArgumentError.value(
        instrument,
        'instrument',
        'Instrument tidak didukung.',
      );
    }
  }

  void _validateTimeframe(String timeframe) {
    if (!supportedTimeframes.contains(timeframe)) {
      throw ArgumentError.value(
        timeframe,
        'timeframe',
        'Timeframe tidak didukung.',
      );
    }
  }

  bool _isFresh(DateTime? timestamp, Duration ttl) {
    if (timestamp == null) {
      return false;
    }

    return DateTime.now().difference(timestamp) < ttl;
  }

  String _friendlyError(Object error, {required String fallback}) {
    if (error is DioException) {
      final body = error.response?.data;

      if (body is Map) {
        final message = body['error'] ?? body['message'];

        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }

      if (error.response?.statusCode == 401) {
        return 'Sesi login sudah berakhir.';
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Tidak dapat terhubung ke server.';
      }
    }

    return fallback;
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _quoteTimer?.cancel();

    _authProvider.removeListener(_handleAuthChanged);

    super.dispose();
  }
}
