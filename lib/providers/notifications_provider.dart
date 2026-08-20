import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

import 'auth_provider.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._authProvider);

  final AuthProvider _authProvider;
  TradePilotClient get _client => _authProvider.client;

  List<Notification> items = [];
  int unreadCount = 0;
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _client.notifications.getNotifications();
      final data = response.data;
      if (data != null) {
        items = data.notifications.toList();
        unreadCount = items.where((n) => n.readAt == null).length;
      }
    } catch (_) {
      // biarkan list kosong kalau gagal, tampilkan state kosong di UI
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    try {
      await _client.notifications.markNotificationRead(id: id);
      final idx = items.indexWhere((n) => n.id == id);
      if (idx != -1 && items[idx].readAt == null) {
        items[idx] = items[idx].rebuild((b) => b..readAt = DateTime.now());
        unreadCount = (unreadCount - 1).clamp(0, 1 << 30);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _client.notifications.markAllNotificationsRead();
      items = items
          .map((n) => n.readAt == null ? n.rebuild((b) => b..readAt = DateTime.now()) : n)
          .toList();
      unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
