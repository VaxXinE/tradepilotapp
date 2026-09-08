import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/localization/locale_controller.dart';
import 'core/preferences/mental_checklist_controller.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'models/notification_action.dart';
import 'providers/analysis_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/market_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/price_alert_provider.dart';
import 'providers/progression_provider.dart';
import 'providers/watchlist_provider.dart';
import 'repositories/market_repository.dart';
import 'repositories/price_alert_repository.dart';
import 'repositories/watchlist_repository.dart';
import 'screens/analysis/analysis_detail_screen.dart';
import 'screens/daily_summary/daily_summary_screen.dart';
import 'screens/home/tabs/history_tab.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/price_alert/price_alert_list_screen.dart';
import 'screens/splash_screen.dart';
import 'services/native_push_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final preferences = await SharedPreferences.getInstance();
  runApp(TradePilotApp(preferences: preferences));
}

class TradePilotApp extends StatelessWidget {
  const TradePilotApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(preferences),
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(preferences),
        ),
        ChangeNotifierProvider<MentalChecklistController>(
          create: (_) => MentalChecklistController(preferences),
        ),

        // =====================================================================
        // AUTH
        // =====================================================================
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),

        ChangeNotifierProxyProvider<AuthProvider, NativePushService>(
          create: (context) => NativePushService(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? NativePushService(auth),
        ),

        // =====================================================================
        // ANALYSIS
        // =====================================================================
        ChangeNotifierProxyProvider<AuthProvider, AnalysisProvider>(
          create: (context) {
            return AnalysisProvider(context.read<AuthProvider>());
          },
          update: (context, auth, previous) {
            return previous ?? AnalysisProvider(auth);
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, ProgressionProvider>(
          create: (context) =>
              ProgressionProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? ProgressionProvider(auth),
        ),

        // =====================================================================
        // MARKET
        // =====================================================================
        ChangeNotifierProxyProvider<AuthProvider, MarketProvider>(
          create: (context) {
            final auth = context.read<AuthProvider>();
            return MarketProvider(auth, MarketRepository(auth.client.dio));
          },
          update: (context, auth, previous) {
            return previous ??
                MarketProvider(auth, MarketRepository(auth.client.dio));
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, WatchlistProvider>(
          create: (context) {
            final auth = context.read<AuthProvider>();
            return WatchlistProvider(auth, WatchlistRepository(auth.client));
          },
          update: (context, auth, previous) {
            return previous ??
                WatchlistProvider(auth, WatchlistRepository(auth.client));
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, PriceAlertProvider>(
          create: (context) {
            final auth = context.read<AuthProvider>();
            return PriceAlertProvider(auth, PriceAlertRepository(auth.client));
          },
          update: (context, auth, previous) {
            return previous ??
                PriceAlertProvider(auth, PriceAlertRepository(auth.client));
          },
        ),

        // =====================================================================
        // NOTIFICATIONS
        // =====================================================================
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (context) {
            return NotificationsProvider(context.read<AuthProvider>());
          },
          update: (context, auth, previous) {
            return previous ?? NotificationsProvider(auth);
          },
        ),
      ],
      child: const _TradePilotMaterialApp(),
    );
  }
}

class _TradePilotMaterialApp extends StatefulWidget {
  const _TradePilotMaterialApp();

  @override
  State<_TradePilotMaterialApp> createState() => _TradePilotMaterialAppState();
}

class _TradePilotMaterialAppState extends State<_TradePilotMaterialApp> {
  late final Upgrader _upgrader;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final AuthProvider _auth;
  late final NativePushService _nativePush;
  StreamSubscription<NotificationAction>? _pushActionSubscription;
  NotificationAction? _pendingPushAction;
  bool _openingPushAction = false;

  AuthStatus? _previousAuthStatus;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(countryCode: 'ID');

    _auth = context.read<AuthProvider>();
    _nativePush = context.read<NativePushService>();
    _previousAuthStatus = _auth.status;
    _auth.addListener(_handleAuthStatusChanged);
    _pushActionSubscription = _nativePush.actions.listen(_handlePushAction);
    unawaited(_nativePush.initialize());

    if (defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateAndroid());
    }
  }

  /// Clears the navigation stack when a session ends.
  ///
  /// [SplashScreen] is this app's `home`, so it swaps itself to
  /// [LoginScreen] on its own as soon as the status changes. Routes pushed on
  /// top of it — analysis detail, journal, alerts — sit *above* `home` in the
  /// navigator and would happily stay there, covering the login form with a
  /// screen whose data is backed by a token that no longer works.
  ///
  /// Handles both a forced logout (expired token) and a manual one.
  void _handleAuthStatusChanged() {
    final previous = _previousAuthStatus;
    final current = _auth.status;
    _previousAuthStatus = current;

    if (previous == AuthStatus.authenticated &&
        current == AuthStatus.unauthenticated) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    if (current == AuthStatus.authenticated && !_auth.isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_openPendingPushAction());
      });
    }
  }

  void _handlePushAction(NotificationAction action) {
    _pendingPushAction = action;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openPendingPushAction());
    });
  }

  Future<void> _openPendingPushAction() async {
    if (!mounted || _openingPushAction) return;
    final action = _pendingPushAction;
    final navigator = _navigatorKey.currentState;
    final navigationContext = _navigatorKey.currentContext;
    if (action == null ||
        navigator == null ||
        navigationContext == null ||
        _auth.status != AuthStatus.authenticated ||
        _auth.isLocked) {
      return;
    }

    _pendingPushAction = null;
    _openingPushAction = true;
    try {
      if (action.notificationId case final notificationId?) {
        unawaited(
          navigationContext.read<NotificationsProvider>().markRead(
            notificationId,
          ),
        );
      }

      switch (action.type) {
        case NotificationActionType.analysis:
          final analysisId = action.actionId!;
          final analysis = await navigationContext
              .read<AnalysisProvider>()
              .getAnalysis(analysisId, silent: true);
          if (!mounted || analysis == null) return;
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => AnalysisDetailScreen(
                analysisId: analysisId,
                preloaded: analysis,
              ),
            ),
          );
        case NotificationActionType.history:
          await navigator.push(
            MaterialPageRoute(builder: (_) => const HistoryTab()),
          );
        case NotificationActionType.notifications:
          await navigator.push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        case NotificationActionType.dailySummary:
          await navigator.push(
            MaterialPageRoute(builder: (_) => const DailySummaryScreen()),
          );
        case NotificationActionType.alerts:
          await navigator.push(
            MaterialPageRoute(builder: (_) => const PriceAlertListScreen()),
          );
      }
    } finally {
      _openingPushAction = false;
    }
  }

  Future<void> _updateAndroid() async {
    try {
      final update = await InAppUpdate.checkForUpdate();
      if (update.updateAvailability == UpdateAvailability.updateAvailable &&
          update.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (error) {
      debugPrint('Google Play update check failed: $error');
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthStatusChanged);
    unawaited(_pushActionSubscription?.cancel());
    _upgrader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final locale = context.watch<LocaleController>();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.mode,
      home: defaultTargetPlatform == TargetPlatform.iOS
          ? UpgradeAlert(
              upgrader: _upgrader,
              barrierDismissible: false,
              showIgnore: false,
              showLater: false,
              shouldPopScope: () => false,
              child: const SplashScreen(),
            )
          : const SplashScreen(),
    );
  }
}
