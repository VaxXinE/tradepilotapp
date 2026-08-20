import 'dart:async';
import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

import 'auth_provider.dart';

enum NotificationPreferenceKey {
  expiry,
  broadcast,
  dailySummary,
  marketNews,
  calendarEvents,
  priceAnomaly,
  weeklyRecap,
  signalFlip,
  dormancyNudge,
  onboarding,
}

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._authProvider) {
    _activeUserId = _currentUserId;

    _authProvider.addListener(_handleAuthChanged);
  }

  final AuthProvider _authProvider;

  TradePilotClient get _client => _authProvider.client;

  // ===========================================================================
  // PUBLIC STATE
  // ===========================================================================

  List<Notification> items = [];

  int unreadCount = 0;

  bool isLoading = false;

  PushPrefs? preferences;

  bool isLoadingPreferences = false;

  bool isSavingPreferences = false;

  String? preferencesError;

  bool isRealtimeConnected = false;

  // ===========================================================================
  // AUTH / SESSION
  // ===========================================================================

  int? _activeUserId;

  int _sessionEpoch = 0;

  int? get _currentUserId {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }

    return _authProvider.user?.id;
  }

  bool _isCurrentSession({required int epoch, required int userId}) {
    return epoch == _sessionEpoch &&
        userId == _currentUserId &&
        _authProvider.status == AuthStatus.authenticated;
  }

  void _handleAuthChanged() {
    final nextUserId = _currentUserId;

    if (nextUserId == _activeUserId) {
      return;
    }

    _activeUserId = nextUserId;

    _sessionEpoch++;

    _loadRequestId++;

    _prefsRequestId++;

    _prefsMutationId++;

    _stopRealtimeStream(preserveEnabled: true);

    _loadRequestInFlight = false;

    _prefsRequestInFlight = false;

    _reloadRequestedDuringLoad = false;

    items = [];

    unreadCount = 0;

    isLoading = false;

    preferences = null;

    isLoadingPreferences = false;

    isSavingPreferences = false;

    preferencesError = null;

    if (nextUserId != null) {
      unawaited(load(silent: true));

      unawaited(loadPreferences(silent: true));

      if (_realtimeEnabled) {
        _startRealtimeStream();
      }
    }

    notifyListeners();
  }

  // ===========================================================================
  // NOTIFICATION LOAD
  // ===========================================================================

  int _loadRequestId = 0;

  bool _loadRequestInFlight = false;

  bool _reloadRequestedDuringLoad = false;

  Future<void> load({bool silent = false}) async {
    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    if (_loadRequestInFlight) {
      _reloadRequestedDuringLoad = true;

      return;
    }

    final epoch = _sessionEpoch;

    final requestId = ++_loadRequestId;

    _loadRequestInFlight = true;

    if (!silent) {
      isLoading = true;

      notifyListeners();
    }

    try {
      final response = await _client.notifications.getNotifications();

      if (!_isCurrentSession(epoch: epoch, userId: userId) ||
          requestId != _loadRequestId) {
        return;
      }

      final data = response.data;

      if (data != null) {
        items = data.notifications.toList();

        unreadCount = items
            .where((notification) => notification.readAt == null)
            .length;
      }
    } catch (_) {
      // Notification bukan critical path.
      // Pertahankan cache terakhir.
    } finally {
      if (requestId == _loadRequestId) {
        _loadRequestInFlight = false;

        isLoading = false;

        if (_isCurrentSession(epoch: epoch, userId: userId)) {
          notifyListeners();

          if (_reloadRequestedDuringLoad) {
            _reloadRequestedDuringLoad = false;

            unawaited(load(silent: true));
          }
        }
      }
    }
  }

  // ===========================================================================
  // MARK READ
  // ===========================================================================

  Future<void> markRead(int id) async {
    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    final epoch = _sessionEpoch;

    try {
      await _client.notifications.markNotificationRead(id: id);

      if (!_isCurrentSession(epoch: epoch, userId: userId)) {
        return;
      }

      final index = items.indexWhere((notification) => notification.id == id);

      if (index != -1 && items[index].readAt == null) {
        items[index] = items[index].rebuild((builder) {
          builder.readAt = DateTime.now();
        });

        unreadCount = (unreadCount - 1).clamp(0, 1 << 30);

        notifyListeners();
      }
    } catch (_) {
      // Non-critical.
    }
  }

  Future<void> markAllRead() async {
    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    final epoch = _sessionEpoch;

    try {
      await _client.notifications.markAllNotificationsRead();

      if (!_isCurrentSession(epoch: epoch, userId: userId)) {
        return;
      }

      final now = DateTime.now();

      items = items.map((notification) {
        if (notification.readAt != null) {
          return notification;
        }

        return notification.rebuild((builder) {
          builder.readAt = now;
        });
      }).toList();

      unreadCount = 0;

      notifyListeners();
    } catch (_) {
      // Non-critical.
    }
  }

  // ===========================================================================
  // PUSH PREFERENCES
  // ===========================================================================

  int _prefsRequestId = 0;

  int _prefsMutationId = 0;

  bool _prefsRequestInFlight = false;

  Future<void> loadPreferences({bool silent = false}) async {
    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    if (_prefsRequestInFlight) {
      return;
    }

    final epoch = _sessionEpoch;

    final requestId = ++_prefsRequestId;

    _prefsRequestInFlight = true;

    if (!silent) {
      isLoadingPreferences = true;

      notifyListeners();
    }

    try {
      final response = await _client.push.getPushPrefs();

      if (!_isCurrentSession(epoch: epoch, userId: userId) ||
          requestId != _prefsRequestId) {
        return;
      }

      preferences = response.data;

      preferencesError = null;
    } catch (_) {
      if (_isCurrentSession(epoch: epoch, userId: userId)) {
        preferencesError = 'Gagal memuat preferensi notifikasi.';
      }
    } finally {
      if (requestId == _prefsRequestId) {
        _prefsRequestInFlight = false;

        if (_isCurrentSession(epoch: epoch, userId: userId)) {
          isLoadingPreferences = false;

          notifyListeners();
        }
      }
    }
  }

  Future<bool> updatePreference({
    required NotificationPreferenceKey key,
    required bool enabled,
  }) async {
    final userId = _currentUserId;

    if (userId == null || isSavingPreferences) {
      return false;
    }

    final epoch = _sessionEpoch;

    final mutationId = ++_prefsMutationId;

    isSavingPreferences = true;

    preferencesError = null;

    notifyListeners();

    try {
      final update = PushPrefsUpdate((builder) {
        switch (key) {
          case NotificationPreferenceKey.expiry:
            builder.pushExpiry = enabled;
            break;

          case NotificationPreferenceKey.broadcast:
            builder.pushBroadcast = enabled;
            break;

          case NotificationPreferenceKey.dailySummary:
            builder.pushDailySummary = enabled;
            break;

          case NotificationPreferenceKey.marketNews:
            builder.pushMarketNews = enabled;
            break;

          case NotificationPreferenceKey.calendarEvents:
            builder.pushCalendarEvents = enabled;
            break;

          case NotificationPreferenceKey.priceAnomaly:
            builder.pushPriceAnomaly = enabled;
            break;

          case NotificationPreferenceKey.weeklyRecap:
            builder.pushWeeklyRecap = enabled;
            break;

          case NotificationPreferenceKey.signalFlip:
            builder.pushSignalFlip = enabled;
            break;

          case NotificationPreferenceKey.dormancyNudge:
            builder.pushDormancyNudge = enabled;
            break;

          case NotificationPreferenceKey.onboarding:
            builder.pushOnboarding = enabled;
            break;
        }
      });

      final response = await _client.push.updatePushPrefs(
        pushPrefsUpdate: update,
      );

      if (!_isCurrentSession(epoch: epoch, userId: userId) ||
          mutationId != _prefsMutationId) {
        return false;
      }

      preferences = response.data;

      return true;
    } catch (_) {
      if (_isCurrentSession(epoch: epoch, userId: userId)) {
        preferencesError = 'Gagal menyimpan preferensi notifikasi.';
      }

      return false;
    } finally {
      if (mutationId == _prefsMutationId &&
          _isCurrentSession(epoch: epoch, userId: userId)) {
        isSavingPreferences = false;

        notifyListeners();
      }
    }
  }

  Future<bool> updateMarketSession({
    required String session,
    required bool enabled,
  }) async {
    final userId = _currentUserId;

    final prefs = preferences;

    if (userId == null || prefs == null || isSavingPreferences) {
      return false;
    }

    const allowed = {'tokyo', 'london', 'newyork'};

    if (!allowed.contains(session)) {
      return false;
    }

    final selected = prefs.marketOpenSessions.map((item) => item.name).toSet();

    if (enabled) {
      selected.add(session);
    } else {
      selected.remove(session);
    }

    final values = selected
        .map(PushPrefsUpdateMarketOpenSessionsEnum.valueOf)
        .toBuiltList();

    final epoch = _sessionEpoch;

    final mutationId = ++_prefsMutationId;

    isSavingPreferences = true;

    preferencesError = null;

    notifyListeners();

    try {
      final response = await _client.push.updatePushPrefs(
        pushPrefsUpdate: PushPrefsUpdate((builder) {
          builder.marketOpenSessions.replace(values);
        }),
      );

      if (!_isCurrentSession(epoch: epoch, userId: userId) ||
          mutationId != _prefsMutationId) {
        return false;
      }

      preferences = response.data;

      return true;
    } catch (_) {
      if (_isCurrentSession(epoch: epoch, userId: userId)) {
        preferencesError = 'Gagal menyimpan pengingat sesi market.';
      }

      return false;
    } finally {
      if (mutationId == _prefsMutationId &&
          _isCurrentSession(epoch: epoch, userId: userId)) {
        isSavingPreferences = false;

        notifyListeners();
      }
    }
  }

  Future<bool> dismissDisengageNotice() async {
    final userId = _currentUserId;

    if (userId == null || isSavingPreferences) {
      return false;
    }

    final epoch = _sessionEpoch;

    final mutationId = ++_prefsMutationId;

    isSavingPreferences = true;

    notifyListeners();

    try {
      final response = await _client.push.updatePushPrefs(
        pushPrefsUpdate: PushPrefsUpdate((builder) {
          builder.dismissDisengageNotice = true;
        }),
      );

      if (!_isCurrentSession(epoch: epoch, userId: userId) ||
          mutationId != _prefsMutationId) {
        return false;
      }

      preferences = response.data;

      return true;
    } catch (_) {
      return false;
    } finally {
      if (mutationId == _prefsMutationId &&
          _isCurrentSession(epoch: epoch, userId: userId)) {
        isSavingPreferences = false;

        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // FOREGROUND REALTIME — SSE
  // ===========================================================================

  bool _realtimeEnabled = false;

  bool _streamRunning = false;

  int _streamGeneration = 0;

  int _reconnectAttempt = 0;

  CancelToken? _streamCancelToken;

  Timer? _reconnectTimer;

  void setRealtimeEnabled(bool enabled) {
    if (_realtimeEnabled == enabled) {
      return;
    }

    _realtimeEnabled = enabled;

    if (!enabled) {
      _stopRealtimeStream();

      return;
    }

    _startRealtimeStream();
  }

  void _startRealtimeStream() {
    if (!_realtimeEnabled || _streamRunning || _currentUserId == null) {
      return;
    }

    unawaited(_runRealtimeStream());
  }

  Future<void> _runRealtimeStream() async {
    final userId = _currentUserId;

    if (userId == null || !_realtimeEnabled) {
      return;
    }

    final epoch = _sessionEpoch;

    final generation = ++_streamGeneration;

    final cancelToken = CancelToken();

    _streamCancelToken = cancelToken;

    _streamRunning = true;

    try {
      final response = await _client.dio.get<ResponseBody>(
        '/notifications/stream',
        options: Options(
          responseType: ResponseType.stream,
          headers: {Headers.acceptHeader: 'text/event-stream'},
        ),
        cancelToken: cancelToken,
      );

      if (!_isCurrentSession(epoch: epoch, userId: userId) ||
          generation != _streamGeneration ||
          !_realtimeEnabled) {
        return;
      }

      final body = response.data;

      if (body == null) {
        return;
      }

      isRealtimeConnected = true;

      _reconnectAttempt = 0;

      notifyListeners();

      String? eventName;

      final lines = const LineSplitter().bind(utf8.decoder.bind(body.stream));

      await for (final line in lines) {
        if (!_isCurrentSession(epoch: epoch, userId: userId) ||
            generation != _streamGeneration ||
            !_realtimeEnabled) {
          break;
        }

        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();

          continue;
        }

        if (line.startsWith('data:')) {
          if (eventName == 'notification') {
            if (_loadRequestInFlight) {
              _reloadRequestedDuringLoad = true;
            } else {
              unawaited(load(silent: true));
            }
          }

          continue;
        }

        if (line.isEmpty) {
          eventName = null;
        }
      }
    } on DioException catch (error) {
      if (error.type != DioExceptionType.cancel) {
        // Reconnect di finally.
      }
    } catch (_) {
      // Reconnect di finally.
    } finally {
      if (generation == _streamGeneration) {
        _streamRunning = false;

        _streamCancelToken = null;

        isRealtimeConnected = false;

        if (_isCurrentSession(epoch: epoch, userId: userId)) {
          notifyListeners();

          if (_realtimeEnabled) {
            _scheduleReconnect();
          }
        }
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    const delays = [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 30),
      Duration(seconds: 60),
    ];

    final index = _reconnectAttempt.clamp(0, delays.length - 1);

    final delay = delays[index];

    _reconnectAttempt = (_reconnectAttempt + 1).clamp(0, delays.length - 1);

    _reconnectTimer = Timer(delay, () {
      _startRealtimeStream();
    });
  }

  void _stopRealtimeStream({bool preserveEnabled = false}) {
    if (!preserveEnabled) {
      _realtimeEnabled = false;
    }

    _streamGeneration++;

    _reconnectTimer?.cancel();

    _reconnectTimer = null;

    _streamCancelToken?.cancel('Realtime notifications stopped.');

    _streamCancelToken = null;

    _streamRunning = false;

    isRealtimeConnected = false;
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _stopRealtimeStream();

    _authProvider.removeListener(_handleAuthChanged);

    super.dispose();
  }
}
