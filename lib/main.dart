import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/analysis_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/market_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const TradePilotApp());
}

class TradePilotApp extends StatelessWidget {
  const TradePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
            return MarketProvider(context.read<AuthProvider>());
          },
          update: (context, auth, previous) {
            return previous ?? MarketProvider(auth);
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
      child: MaterialApp(
        title: 'Trade Pilot',
        debugShowCheckedModeBanner: false,

        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,

        home: const SplashScreen(),
      ),
    );
  }
}
