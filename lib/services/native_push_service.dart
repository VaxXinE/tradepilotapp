import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../providers/auth_provider.dart';

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

    if (type == null) {
      return null;
    }

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

class NativePushService extends ChangeNotifier {
  NativePushService(this._authProvider) {
    _authProvider.addListener(_handleAuthChanged);
  }

  static const _channel = AndroidNotificationChannel(
    'trade_pilot_alerts',
    'Trade Pilot Alerts',
    description: 'Trading alerts and important Trade Pilot notifications.',
    importance: Importance.high,
  );

  final AuthProvider _authProvider;
  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationAction> _actions =
      StreamController<NotificationAction>();

  Stream<NotificationAction> get actions => _actions.stream;

  AuthorizationStatus authorizationStatus = AuthorizationStatus.notDetermined;
  bool isRegistered = false;
  bool isBusy = false;
  String? errorMessage;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _registeredToken;
  Future<void>? _initialization;

  bool get isPermissionDenied =>
      authorizationStatus == AuthorizationStatus.denied;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    _messaging = FirebaseMessaging.instance;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _emitPayload(response.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _emitPayload(launchDetails?.notificationResponse?.payload);
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _emitAction(message.data),
    );
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      if (_authProvider.status == AuthStatus.authenticated) {
        unawaited(_registerToken(token));
      }
    });

    authorizationStatus =
        (await _messaging.getNotificationSettings()).authorizationStatus;

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _emitAction(initialMessage.data);
    }

    if (_authProvider.status == AuthStatus.authenticated &&
        _permissionGranted) {
      unawaited(syncToken());
    }
    notifyListeners();
  }

  Future<bool> enable() async {
    await initialize();
    if (Firebase.apps.isEmpty) {
      return false;
    }

    if (isBusy) {
      return false;
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      authorizationStatus = settings.authorizationStatus;

      if (!_permissionGranted) {
        errorMessage = 'Izin notifikasi belum diberikan di pengaturan sistem.';
        return false;
      }

      return await syncToken();
    } catch (_) {
      errorMessage = 'Push notification belum dapat diaktifkan.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> syncToken() async {
    await initialize();
    if (Firebase.apps.isEmpty) {
      return false;
    }

    if (_authProvider.status != AuthStatus.authenticated) {
      return false;
    }

    if (Platform.isIOS) {
      for (var attempt = 0; attempt < 10; attempt++) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      errorMessage = 'Token push belum tersedia pada perangkat ini.';
      notifyListeners();
      return false;
    }

    return _registerToken(token);
  }

  Future<bool> _registerToken(String token) async {
    if (token == _registeredToken && isRegistered) {
      return true;
    }

    try {
      await _authProvider.client.dio.post<void>(
        '/native-push/register',
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
      _registeredToken = token;
      isRegistered = true;
      errorMessage = null;
      notifyListeners();
      return true;
    } on DioException {
      isRegistered = false;
      errorMessage = 'Server belum dapat mendaftarkan perangkat push.';
      notifyListeners();
      return false;
    }
  }

  Future<void> unregister() async {
    await initialize();
    if (Firebase.apps.isEmpty) {
      return;
    }

    final token = _registeredToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _authProvider.client.dio.delete<void>(
        '/native-push/unregister',
        data: {'token': token},
      );
    } on DioException {
      // Logout tetap harus berlanjut ketika perangkat sedang offline.
    } finally {
      _registeredToken = null;
      isRegistered = false;
      notifyListeners();
    }
  }

  bool get _permissionGranted =>
      authorizationStatus == AuthorizationStatus.authorized ||
      authorizationStatus == AuthorizationStatus.provisional;

  void _handleAuthChanged() {
    if (_authProvider.status == AuthStatus.authenticated &&
        _permissionGranted) {
      unawaited(syncToken());
      return;
    }

    if (_authProvider.status == AuthStatus.unauthenticated) {
      _registeredToken = null;
      isRegistered = false;
      notifyListeners();
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: notification.title ?? 'Trade Pilot',
      body: notification.body ?? '',
      payload: jsonEncode(message.data),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'trade_pilot_alerts',
          'Trade Pilot Alerts',
          channelDescription:
              'Trading alerts and important Trade Pilot notifications.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _emitPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _emitAction(decoded);
      }
    } on FormatException {
      // Payload dari OS dianggap input tidak tepercaya dan fail closed.
    }
  }

  void _emitAction(Map<String, dynamic> data) {
    final action = NotificationAction.fromData(data);
    if (action != null && !_actions.isClosed) {
      _actions.add(action);
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    unawaited(_tokenSubscription?.cancel());
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
    unawaited(_actions.close());
    super.dispose();
  }
}
