import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

import 'auth_provider.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._authProvider) {
    _activeUserId = _currentUserId;

    _authProvider.addListener(_handleAuthChanged);
  }

  final AuthProvider _authProvider;

  TradePilotClient get _client => _authProvider.client;

  List<Notification> items = [];

  int unreadCount = 0;

  bool isLoading = false;

  // ===========================================================================
  // REQUEST / SESSION GUARDS
  // ===========================================================================

  int? _activeUserId;

  int _sessionEpoch = 0;

  int _loadRequestId = 0;

  bool _loadRequestInFlight = false;

  int? get _currentUserId {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }

    return _authProvider.user?.id;
  }

  bool _isCurrentSession({required int epoch, required int userId}) {
    return epoch == _sessionEpoch && userId == _currentUserId;
  }

  void _handleAuthChanged() {
    final nextUserId = _currentUserId;

    if (nextUserId == _activeUserId) {
      return;
    }

    _activeUserId = nextUserId;

    // Invalidasi semua response dari session lama.
    _sessionEpoch++;
    _loadRequestId++;

    _loadRequestInFlight = false;

    // Security:
    //
    // Jangan biarkan notification milik account sebelumnya
    // masih hidup di memory setelah logout / switch account.
    items = [];
    unreadCount = 0;
    isLoading = false;

    notifyListeners();
  }

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> load({bool silent = false}) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    if (_loadRequestInFlight) {
      return;
    }

    final userId = _currentUserId;

    if (userId == null) {
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
      // Notification bukan critical path aplikasi.
      //
      // Kalau gagal, pertahankan state lama daripada membuat
      // Dashboard ikut gagal.
    } finally {
      if (requestId == _loadRequestId) {
        _loadRequestInFlight = false;

        isLoading = false;

        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // MARK ONE READ
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
      // UI tetap usable kalau endpoint gagal.
    }
  }

  // ===========================================================================
  // MARK ALL READ
  // ===========================================================================

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
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);

    super.dispose();
  }
}
