import 'package:flutter/material.dart';

/// Brand palette: black + gold/amber — diselaraskan dengan
/// `artifacts/ai-trading/src/index.css` dan `artifacts/mobile/constants/colors.ts`
/// dari repo Trade-Pilot (branch prod).
class AppColors {
  AppColors._();

  // ---- Light theme ----
  static const lightText = Color(0xFF1A1509);
  static const lightBackground = Color(0xFFFAF9F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFFA86C05);
  static const lightPrimaryForeground = Color(0xFFFDFAF3);
  static const lightSecondary = Color(0xFFF3E9C0);
  static const lightSecondaryForeground = Color(0xFF1F1A0E);
  static const lightMuted = Color(0xFFF4F1E7);
  static const lightMutedForeground = Color(0xFF5D5247);
  static const lightAccent = Color(0xFFF08A0D);
  static const lightDestructive = Color(0xFFE83535);
  static const lightBorder = Color(0xFFE2DCC7);

  // ---- Dark theme ----
  static const darkText = Color(0xFFF6F3EA);
  static const darkBackground = Color(0xFF0D0C0A);
  static const darkCard = Color(0xFF141210);
  static const darkPrimary = Color(0xFFF5C518);
  static const darkPrimaryForeground = Color(0xFF17130E);
  static const darkSecondary = Color(0xFF201E1A);
  static const darkSecondaryForeground = Color(0xFFF6F3EA);
  static const darkMuted = Color(0xFF201E1A);
  static const darkMutedForeground = Color(0xFFB8B3AC);
  static const darkAccent = Color(0xFFF99800);
  static const darkDestructive = Color(0xFFCC2929);
  static const darkBorder = Color(0xFF282420);

  // ---- Trader-safety signal colors (same in both themes' intent) ----
  static const bullishLight = Color(0xFF16A34A);
  static const bearishLight = Color(0xFFDC2626);
  static const neutralLight = Color(0xFF78716C);

  static const bullishDark = Color(0xFF22C55E);
  static const bearishDark = Color(0xFFEF4444);
  static const neutralDark = Color(0xFFA8A29E);

  static const radius = 14.0;
}
