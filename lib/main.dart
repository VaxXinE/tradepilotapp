import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';
import 'providers/analysis_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/market_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/price_alert_provider.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<NotificationAction>? _actionSubscription;

  @override
  void initState() {
    super.initState();
    final nativePush = context.read<NativePushService>();
    _actionSubscription = nativePush.actions.listen(_handlePushAction);
    unawaited(nativePush.initialize());
  }

  void _handlePushAction(NotificationAction action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openPushAction(action));
    });
  }

  Future<void> _openPushAction(NotificationAction action) async {
    final navigationContext = _navigatorKey.currentContext;
    final navigator = _navigatorKey.currentState;
    if (navigationContext == null ||
        navigator == null ||
        navigationContext.read<AuthProvider>().status !=
            AuthStatus.authenticated) {
      return;
    }

    final notificationId = action.notificationId;
    if (notificationId != null) {
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
        if (!mounted || analysis == null) {
          return;
        }
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => AnalysisDetailScreen(
              analysisId: analysisId,
              preloaded: analysis,
            ),
          ),
        );
        return;
      case NotificationActionType.history:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const HistoryTab()),
        );
        return;
      case NotificationActionType.notifications:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        return;
      case NotificationActionType.dailySummary:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const DailySummaryScreen()),
        );
        return;
      case NotificationActionType.alerts:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const PriceAlertListScreen()),
        );
        return;
    }
  }

  @override
  void dispose() {
    unawaited(_actionSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Trade Pilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.mode,
      home: const SplashScreen(),
    );
  }
}
