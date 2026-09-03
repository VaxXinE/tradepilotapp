import 'package:flutter/material.dart';

/// Brand palette: black + gold/amber — diselaraskan dengan
/// `artifacts/ai-trading/src/index.css` dan `artifacts/mobile/constants/colors.ts`
/// dari repo Trade-Pilot (branch prod).
class AppColors {
  AppColors._();

  // ---- Light theme ----
  static const lightText = Color(0xFF211A12);
  static const lightBackground = Color(0xFFFBFBF8);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFFAA6F09);
  static const lightPrimaryForeground = Color(0xFFFCFBF7);
  static const lightSecondary = Color(0xFFF7F4E8);
  static const lightSecondaryForeground = Color(0xFF281F15);
  static const lightMuted = Color(0xFFF6F4EE);
  static const lightMutedForeground = Color(0xFF67594C);
  static const lightAccent = Color(0xFFF29E0D);
  static const lightDestructive = Color(0xFFEF4444);
  static const lightBorder = Color(0xFFE8E4D9);
  static const destructiveForeground = Color(0xFFF8FAFC);

  // ---- Dark theme ----
  static const darkText = Color(0xFFF8F6F2);
  static const darkBackground = Color(0xFF0E0D0C);
  static const darkCard = Color(0xFF161413);
  static const darkPrimary = Color(0xFFF5C219);
  static const darkPrimaryForeground = Color(0xFF1B140E);
  static const darkSecondary = Color(0xFF221F1C);
  static const darkSecondaryForeground = Color(0xFFF8F6F2);
  static const darkMuted = Color(0xFF221F1C);
  static const darkMutedForeground = Color(0xFFC0BAAF);
  static const darkAccent = Color(0xFFFFAB1A);
  static const darkDestructive = Color(0xFFD02F2F);
  static const darkBorder = Color(0xFF312C21);

  // ---- Trader-safety signal colors (same in both themes' intent) ----
  static const bullishLight = Color(0xFF059669);
  static const bearishLight = Color(0xFFDC2626);
  static const neutralLight = Color(0xFFD97706);

  static const bullishDark = Color(0xFF34D399);
  static const bearishDark = Color(0xFFF87171);
  static const neutralDark = Color(0xFFFBBF24);

  // ---- Chart levels (Tailwind amber/red/emerald 500 on the web) ----
  static const entry = Color(0xFFF59E0B);
  static const stopLoss = Color(0xFFEF4444);
  static const takeProfit = Color(0xFF10B981);
  static const chartTextLight = Color(0xFF475569);
  static const chartTextDark = Color(0xFFCBD5E1);
  static const chartGridLight = Color(0xFF64748B);
  static const chartGridDark = Color(0xFF94A3B8);
  static const chartShadow = Color(0x33000000);

  static const radius = 20.0;
}
