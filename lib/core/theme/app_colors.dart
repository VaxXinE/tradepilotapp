import 'package:flutter/material.dart';

/// Token desain Trade-Pilot.
///
/// Sumber kebenaran adalah `artifacts/ai-trading/src/index.css` pada repo
/// Trade-Pilot — setiap nilai di bawah adalah konversi langsung dari custom
/// property HSL di sana, sehingga mobile dan web memakai palet yang sama.
class AppColors {
  AppColors._();

  // ---- Light theme (`:root` pada index.css) ----
  /// `--foreground: 0 0% 5%`
  static const lightText = Color(0xFF0D0D0D);

  /// `--background: 0 0% 100%`
  static const lightBackground = Color(0xFFFFFFFF);

  /// `--card: 0 0% 98%`
  static const lightCard = Color(0xFFFAFAFA);

  /// `--primary: 43 96% 48%`
  static const lightPrimary = Color(0xFFF0AD05);

  /// `--primary-foreground: 0 0% 5%` — emas web selalu berpasangan dengan
  /// teks nyaris hitam, bukan putih.
  static const lightPrimaryForeground = Color(0xFF0D0D0D);

  /// Emas gelap untuk teks/ikon kecil di atas `background`.
  ///
  /// Web memakai `--primary` apa adanya di sini, tetapi emas terang pada latar
  /// putih hanya mencapai rasio kontras ~1.9:1 — di bawah ambang WCAG AA untuk
  /// teks. Nada ini menjaga kesan emas yang sama sambil tetap terbaca.
  static const lightPrimaryText = Color(0xFF8A5900);

  /// `--secondary: 0 0% 96%`
  static const lightSecondary = Color(0xFFF5F5F5);

  /// `--secondary-foreground: 0 0% 9%`
  static const lightSecondaryForeground = Color(0xFF171717);

  /// `--muted: 0 0% 96%`
  static const lightMuted = Color(0xFFF5F5F5);

  /// `--muted-foreground: 0 0% 45%`
  static const lightMutedForeground = Color(0xFF737373);

  /// `--accent: 43 96% 48%`
  static const lightAccent = Color(0xFFF0AD05);

  /// `--destructive: 0 84.2% 60.2%`
  static const lightDestructive = Color(0xFFEF4444);

  /// `--border: 0 0% 90%`
  static const lightBorder = Color(0xFFE5E5E5);

  /// `--destructive-foreground: 210 40% 98%`
  static const destructiveForeground = Color(0xFFF8FAFC);

  // ---- Dark theme (`.dark` pada index.css) ----
  /// `--foreground: 0 0% 98%`
  static const darkText = Color(0xFFFAFAFA);

  /// `--background: 0 0% 2%`
  static const darkBackground = Color(0xFF050505);

  /// Surface kartu sedikit terangkat dari background agar hierarki tetap
  /// terbaca tanpa mengubah identitas hitam-emas TradePilot.
  static const darkCard = Color(0xFF101216);

  /// `--primary: 43 96% 50%`
  static const darkPrimary = Color(0xFFFAB505);

  /// `--primary-foreground: 0 0% 5%`
  static const darkPrimaryForeground = Color(0xFF0D0D0D);

  /// Emas terang sudah kontras di atas latar gelap, jadi tidak perlu nada
  /// terpisah seperti [lightPrimaryText].
  static const darkPrimaryText = darkPrimary;

  /// `--secondary: 0 0% 10%`
  static const darkSecondary = Color(0xFF1A1A1A);

  /// `--secondary-foreground: 0 0% 98%`
  static const darkSecondaryForeground = Color(0xFFFAFAFA);

  /// `--muted: 0 0% 10%`
  static const darkMuted = Color(0xFF1A1A1A);

  /// `--muted-foreground: 0 0% 65%`
  static const darkMutedForeground = Color(0xFFA6A6A6);

  /// `--accent: 43 96% 50%`
  static const darkAccent = Color(0xFFFAB505);

  /// `--destructive: 0 62.8% 50%`
  static const darkDestructive = Color(0xFFD02F2F);

  /// Border mobile dibuat sedikit lebih terang daripada token web agar batas
  /// kartu tetap terbaca pada layar OLED dan brightness rendah.
  static const darkBorder = Color(0xFF34373E);

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

  /// Glow halus untuk status bullish/bearish di dark mode.
  ///
  /// Warna tidak boleh menjadi satu-satunya penanda status; widget pemakai
  /// tetap wajib menampilkan ikon atau label.
  static List<BoxShadow> signalGlow(Color color, {required bool enabled}) =>
      enabled
      ? [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: -3,
          ),
        ]
      : const [];

  // ---- Radius scale ----
  //
  // `--radius: 0.5rem` pada web, dengan turunan `calc()` di blok
  // `@theme inline`. Tailwind memetakannya ke kelas `rounded-*`.

  /// `--radius-sm: calc(var(--radius) - 4px)`
  static const radiusSm = 4.0;

  /// `--radius-md: calc(var(--radius) - 2px)` — radius baku `<Button>`,
  /// `<Input>`, dan `<Badge>` shadcn.
  static const radiusMd = 6.0;

  /// `--radius-lg: var(--radius)` — tombol instrumen/timeframe dan `<Dialog>`.
  static const radiusLg = 8.0;

  /// `--radius-xl: calc(var(--radius) + 4px)` — `<Card>` (`rounded-xl`).
  static const radiusXl = 12.0;

  /// Radius kartu, dipertahankan sebagai nama lama yang dipakai luas.
  static const radius = radiusXl;
}
