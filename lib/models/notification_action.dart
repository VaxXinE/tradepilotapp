enum NotificationActionType {
  analysis,
  history,
  notifications,
  dailySummary,
  alerts,
}

class NotificationAction {
  const NotificationAction({
    required this.type,
    this.actionId,
    this.notificationId,
  });

  final NotificationActionType type;
  final int? actionId;
  final int? notificationId;

  static NotificationAction? fromData(Map<String, dynamic> data) {
    final type = switch (data['actionType']?.toString()) {
      'analysis' => NotificationActionType.analysis,
      'history' => NotificationActionType.history,
      'notifications' => NotificationActionType.notifications,
      'daily_summary' => NotificationActionType.dailySummary,
      'alerts' => NotificationActionType.alerts,
      _ => null,
    };

    if (type == null) return null;

    final actionId = _positiveInt(data['actionId']);
    if (type == NotificationActionType.analysis && actionId == null) {
      return null;
    }

    return NotificationAction(
      type: type,
      actionId: actionId,
      notificationId: _positiveInt(data['notificationId']),
    );
  }

  static int? _positiveInt(Object? value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
