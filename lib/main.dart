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
import 'l10n/l10n.dart';
import 'providers/analysis_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/market_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/price_alert_provider.dart';
import 'providers/watchlist_provider.dart';
import 'repositories/market_repository.dart';
import 'repositories/price_alert_repository.dart';
import 'repositories/watchlist_repository.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

        // =====================================================================
        // AUTH
        // =====================================================================
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),

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
  late final Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(countryCode: 'ID');
    if (defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateAndroid());
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
    _upgrader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final locale = context.watch<LocaleController>();

    return MaterialApp(
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
