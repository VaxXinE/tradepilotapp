import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/services/native_push_service.dart';

void main() {
  test(
    'notification action parser allowlists targets and validates analysis ID',
    () {
      final analysis = NotificationAction.fromData({
        'actionType': 'analysis',
        'actionId': '42',
        'notificationId': '7',
      });

      expect(analysis?.type, NotificationActionType.analysis);
      expect(analysis?.actionId, 42);
      expect(analysis?.notificationId, 7);
      expect(
        NotificationAction.fromData({
          'actionType': 'analysis',
          'actionId': 'https://evil.example',
        }),
        isNull,
      );
      expect(
        NotificationAction.fromData({'actionType': 'https://evil.example'}),
        isNull,
      );
      expect(
        NotificationAction.fromData({
          'actionType': 'analysis',
          'actionId': '-1',
        }),
        isNull,
      );
      expect(
        NotificationAction.fromData({
          'actionType': 'analysis',
          'actionId': '1.5',
        }),
        isNull,
      );
      expect(
        NotificationAction.fromData({'actionType': 'history'})?.type,
        NotificationActionType.history,
      );
    },
  );
}
