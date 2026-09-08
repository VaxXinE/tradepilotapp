import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../models/notification_action.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_messages.dart';

class NativePushService extends ChangeNotifier {
  NativePushService(this._auth) {
    _activeUserId = _currentUserId;
    _auth.addListener(_handleAuthChanged);
  }

  static const _channel = AndroidNotificationChannel(
    'trade_pilot_alerts',
    'Trade Pilot Alerts',
    description: 'Trading alerts and important Trade Pilot notifications.',
    importance: Importance.high,
  );

  final AuthProvider _auth;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _actions = StreamController<NotificationAction>();

  late final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Future<void>? _initialization;
  Future<bool>? _registrationRequest;
  String? _registeredToken;
  int? _activeUserId;
  int _sessionEpoch = 0;

  Stream<NotificationAction> get actions => _actions.stream;
  AuthorizationStatus authorizationStatus = AuthorizationStatus.notDetermined;
  bool isRegistered = false;
  bool isEnabled = false;
  bool isBusy = false;
  String? errorMessage;
  DateTime? lastMessageReceivedAt;

  bool get isPermissionDenied =>
      authorizationStatus == AuthorizationStatus.denied;

  int? get _currentUserId =>
      _auth.status == AuthStatus.authenticated ? _auth.user?.id : null;

  bool get _permissionGranted =>
      authorizationStatus == AuthorizationStatus.authorized ||
      authorizationStatus == AuthorizationStatus.provisional;

  bool _isCurrentSession(int epoch, int userId) =>
      epoch == _sessionEpoch && userId == _currentUserId;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    // Widget tests construct the provider without bootstrapping Firebase.
    if (Firebase.apps.isEmpty) return;

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
      _showForegroundNotification,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _markMessageReceived();
      _emitAction(message.data);
    });
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      final userId = _currentUserId;
      if (userId != null && isEnabled) {
        unawaited(_registerToken(token, _sessionEpoch, userId));
      }
    });

    authorizationStatus =
        (await _messaging.getNotificationSettings()).authorizationStatus;
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _markMessageReceived();
      _emitAction(initialMessage.data);
    }
    await _loadEnabledPreference();
    if (isEnabled && _permissionGranted) {
      Future<void>.delayed(Duration.zero, _syncSilently);
    }
    notifyListeners();
  }

  Future<bool> enable() async {
    await initialize();
    if (Firebase.apps.isEmpty || isBusy) return false;

    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      authorizationStatus = (await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      )).authorizationStatus;
      if (!_permissionGranted) {
        errorMessage = AppMessages.l10n.errPushPermissionSystem;
        return false;
      }
      if (!await _setEnabledPreference(true)) return false;
      return syncToken();
    } catch (_) {
      errorMessage = AppMessages.l10n.errPushEnableFailed;
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> disable() async {
    if (isBusy) return;
    isBusy = true;
    notifyListeners();
    try {
      if (!await _setEnabledPreference(false)) return;
      await unregister();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _loadEnabledPreference() async {
    if (_currentUserId == null) return;
    try {
      isEnabled =
          (await _auth.client.push.getPushPrefs()).data?.nativePushEnabled ??
          false;
    } catch (_) {
      // Fail closed: jangan mendaftarkan token bila preferensi tidak terbaca.
      isEnabled = false;
    }
  }

  Future<bool> _setEnabledPreference(bool enabled) async {
    if (_currentUserId == null) return false;
    try {
      final response = await _auth.client.push.updatePushPrefs(
        pushPrefsUpdate: PushPrefsUpdate(
          (builder) => builder.nativePushEnabled = enabled,
        ),
      );
      isEnabled = response.data?.nativePushEnabled ?? enabled;
      errorMessage = null;
      notifyListeners();
      return isEnabled == enabled;
    } catch (_) {
      errorMessage = AppMessages.l10n.errPushPrefsSaveFailed;
      notifyListeners();
      return false;
    }
  }

  Future<bool> syncToken() async {
    await initialize();
    if (Firebase.apps.isEmpty) return false;
    final userId = _currentUserId;
    if (userId == null) return false;
    final epoch = _sessionEpoch;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      for (var attempt = 0; attempt < 10; attempt++) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!_isCurrentSession(epoch, userId)) return false;
      }
    }

    final token = await _messaging.getToken();
    if (!_isCurrentSession(epoch, userId)) return false;
    if (token == null || token.isEmpty) {
      errorMessage = AppMessages.l10n.errPushTokenUnavailable;
      notifyListeners();
      return false;
    }
    return _registerToken(token, epoch, userId);
  }

  Future<bool> _registerToken(String token, int epoch, int userId) async {
    if (!_isCurrentSession(epoch, userId)) return false;
    if (token == _registeredToken && isRegistered) return true;

    final pending = _registrationRequest;
    if (pending != null) await pending;
    if (!_isCurrentSession(epoch, userId)) return false;
    if (token == _registeredToken && isRegistered) return true;

    final request = _sendRegistration(token, epoch, userId);
    _registrationRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_registrationRequest, request)) {
        _registrationRequest = null;
      }
    }
  }

  Future<bool> _sendRegistration(String token, int epoch, int userId) async {
    try {
      await _auth.client.nativePush.registerNativePushDevice(
        nativePushRegisterBody: NativePushRegisterBody(
          (builder) => builder
            ..token = token
            ..platform = defaultTargetPlatform == TargetPlatform.iOS
                ? NativePushRegisterBodyPlatformEnum.ios
                : NativePushRegisterBodyPlatformEnum.android,
        ),
      );
      if (!_isCurrentSession(epoch, userId)) return false;
      _registeredToken = token;
      isRegistered = true;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      if (!_isCurrentSession(epoch, userId)) return false;
      isRegistered = false;
      errorMessage = AppMessages.l10n.errPushRegisterFailed;
      notifyListeners();
      return false;
    }
  }

  Future<void> unregister() async {
    await initialize();
    if (Firebase.apps.isEmpty) return;
    final userId = _currentUserId;
    if (userId == null) return;
    final epoch = _sessionEpoch;
    await _registrationRequest;
    if (!_isCurrentSession(epoch, userId)) return;

    final token = _registeredToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    try {
      await _auth.client.nativePush.unregisterNativePushDevice(
        nativePushUnregisterBody: NativePushUnregisterBody(
          (builder) => builder.token = token,
        ),
      );
    } catch (_) {
      // Logout lokal tidak boleh gagal hanya karena perangkat sedang offline.
    } finally {
      if (_isCurrentSession(epoch, userId)) {
        _registeredToken = null;
        isRegistered = false;
        notifyListeners();
      }
    }
  }

  void _handleAuthChanged() {
    final nextUserId = _currentUserId;
    if (nextUserId == _activeUserId) return;
    _activeUserId = nextUserId;
    _sessionEpoch++;
    _registeredToken = null;
    isRegistered = false;
    isEnabled = false;
    errorMessage = null;
    if (nextUserId != null) {
      unawaited(_refreshPreferenceAndSync());
    } else if (Firebase.apps.isNotEmpty) {
      // Token server yang gagal di-unregister setelah forced logout tidak boleh
      // tetap menerima data akun pada device yang kini berada di layar login.
      unawaited(FirebaseMessaging.instance.deleteToken());
    }
    notifyListeners();
  }

  Future<void> _refreshPreferenceAndSync() async {
    await initialize();
    await _loadEnabledPreference();
    if (isEnabled && _permissionGranted) await _syncSilently();
  }

  Future<void> _syncSilently() async {
    try {
      await syncToken();
    } catch (_) {
      errorMessage = AppMessages.l10n.errPushTokenSyncFailed;
      notifyListeners();
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    _markMessageReceived();
    final notification = message.notification;
    if (notification == null) return;
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

  void _markMessageReceived() {
    lastMessageReceivedAt = DateTime.now();
    notifyListeners();
  }

  void _emitPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) _emitAction(decoded);
    } on FormatException {
      // Payload OS adalah input tidak tepercaya: payload invalid diabaikan.
    }
  }

  void _emitAction(Map<String, dynamic> data) {
    final action = NotificationAction.fromData(data);
    if (action != null && !_actions.isClosed) _actions.add(action);
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChanged);
    unawaited(_tokenSubscription?.cancel());
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
    unawaited(_actions.close());
    super.dispose();
  }
}
