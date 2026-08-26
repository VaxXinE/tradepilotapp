import 'package:flutter/material.dart';

/// Brand palette: black + gold/amber — diselaraskan dengan
/// `artifacts/ai-trading/src/index.css` dan `artifacts/mobile/constants/colors.ts`
/// dari repo Trade-Pilot (branch prod).
class AppColors {
  AppColors._();

  // ---- Light theme ----
  static const lightText = Color(0xFF171006);
  static const lightBackground = Color(0xFFFFF9F0);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFFFFA216);
  static const lightPrimaryForeground = Color(0xFF171006);
  static const lightSecondary = Color(0xFFFFEBCB);
  static const lightSecondaryForeground = Color(0xFF4A2A00);
  static const lightMuted = Color(0xFFF5EFE6);
  static const lightMutedForeground = Color(0xFF665D52);
  static const lightAccent = Color(0xFFFFA216);
  static const lightDestructive = Color(0xFFC83A3A);
  static const lightBorder = Color(0xFFE8DDCC);

  // ---- Dark theme ----
  static const darkText = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF050505);
  static const darkCard = Color(0xFF101010);
  static const darkPrimary = Color(0xFFFFA216);
  static const darkPrimaryForeground = Color(0xFF171006);
  static const darkSecondary = Color(0xFF2B1B05);
  static const darkSecondaryForeground = Color(0xFFFFD18A);
  static const darkMuted = Color(0xFF1A1A1A);
  static const darkMutedForeground = Color(0xFFB8B8B8);
  static const darkAccent = Color(0xFFFFA216);
  static const darkDestructive = Color(0xFFE15454);
  static const darkBorder = Color(0xFF2B2B2B);

  // ---- Trader-safety signal colors (same in both themes' intent) ----
  static const bullishLight = Color(0xFF169B55);
  static const bearishLight = Color(0xFFD94444);
  static const neutralLight = Color(0xFF78716C);

  static const bullishDark = Color(0xFF2DCB7F);
  static const bearishDark = Color(0xFFFF5D5D);
  static const neutralDark = Color(0xFFA8A29E);

  static const radius = 20.0;
}
