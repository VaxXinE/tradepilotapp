import 'package:flutter/material.dart';

/// Brand palette: black + gold/amber — diselaraskan dengan
/// `artifacts/ai-trading/src/index.css` dan `artifacts/mobile/constants/colors.ts`
/// dari repo Trade-Pilot (branch prod).
class AppColors {
  AppColors._();

  // ---- Light theme ----
  static const lightText = Color(0xFF0D0D0D);
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFAFAFA);
  // Emas gelap dipakai untuk teks/link kecil agar tetap memenuhi kontras AA.
  static const lightPrimary = Color(0xFF8A5900);
  static const lightPrimaryForeground = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFFF5F5F5);
  static const lightSecondaryForeground = Color(0xFF171717);
  static const lightMuted = Color(0xFFF5F5F5);
  static const lightMutedForeground = Color(0xFF737373);
  static const lightAccent = Color(0xFFF0AD05);
  static const lightDestructive = Color(0xFFEF4444);
  static const lightBorder = Color(0xFFE6E6E6);
  static const destructiveForeground = Color(0xFFF8FAFC);

  // ---- Dark theme ----
  static const darkText = Color(0xFFF8F6F2);
  static const darkBackground = Color(0xFF050505);
  static const darkCard = Color(0xFF0A0A0A);
  static const darkPrimary = Color(0xFFFAB505);
  static const darkPrimaryForeground = Color(0xFF0D0D0D);
  static const darkSecondary = Color(0xFF1A1A1A);
  static const darkSecondaryForeground = Color(0xFFFAFAFA);
  static const darkMuted = Color(0xFF1A1A1A);
  static const darkMutedForeground = Color(0xFFA6A6A6);
  static const darkAccent = Color(0xFFFAB505);
  static const darkDestructive = Color(0xFFD02F2F);
  static const darkBorder = Color(0xFF1F1F1F);

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

  static const radius = 12.0;
}
