import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/analysis_provider.dart';
import 'providers/auth_provider.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AnalysisProvider>(
          create: (context) => AnalysisProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => previous ?? AnalysisProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (context) => NotificationsProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => previous ?? NotificationsProvider(auth),
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
