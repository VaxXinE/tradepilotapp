import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/theme/app_colors.dart';
import 'package:tradepilotapp/core/theme/app_theme.dart';

/// Mengunci token mobile pada custom property di
/// `Trade-Pilot/artifacts/ai-trading/src/index.css`.
///
/// Nilai HSL di sana dikonversi ke sRGB, jadi setiap penyimpangan pada web
/// atau mobile memunculkan kegagalan di sini alih-alih terlihat sebagai dua
/// aplikasi yang perlahan berbeda warna.
void main() {
  group('light tokens follow :root in index.css', () {
    test('surfaces and text', () {
      // --background: 0 0% 100%  /  --foreground: 0 0% 5%
      expect(AppColors.lightBackground, const Color(0xFFFFFFFF));
      expect(AppColors.lightText, const Color(0xFF0D0D0D));
      // --card: 0 0% 98%  /  --border: 0 0% 90%
      expect(AppColors.lightCard, const Color(0xFFFAFAFA));
      expect(AppColors.lightBorder, const Color(0xFFE5E5E5));
      // --secondary + --muted: 0 0% 96%
      expect(AppColors.lightSecondary, const Color(0xFFF5F5F5));
      expect(AppColors.lightMuted, const Color(0xFFF5F5F5));
      // --secondary-foreground: 0 0% 9%  /  --muted-foreground: 0 0% 45%
      expect(AppColors.lightSecondaryForeground, const Color(0xFF171717));
      expect(AppColors.lightMutedForeground, const Color(0xFF737373));
    });

    test('brand gold pairs with near-black, never white', () {
      // --primary + --accent: 43 96% 48%
      expect(AppColors.lightPrimary, const Color(0xFFF0AD05));
      expect(AppColors.lightAccent, const Color(0xFFF0AD05));
      // --primary-foreground: 0 0% 5%
      expect(AppColors.lightPrimaryForeground, const Color(0xFF0D0D0D));
    });

    test('destructive', () {
      // --destructive: 0 84.2% 60.2%
      expect(AppColors.lightDestructive, const Color(0xFFEF4444));
      // --destructive-foreground: 210 40% 98%
      expect(AppColors.destructiveForeground, const Color(0xFFF8FAFC));
    });
  });

  group('dark tokens follow .dark in index.css', () {
    test('surfaces and text', () {
      // --background: 0 0% 2%  /  --foreground: 0 0% 98%
      expect(AppColors.darkBackground, const Color(0xFF050505));
      expect(AppColors.darkText, const Color(0xFFFAFAFA));
      // Surface dan border mobile sengaja dibuat lebih terpisah agar hierarki
      // tetap terbaca pada OLED dan brightness rendah.
      expect(AppColors.darkCard, const Color(0xFF101216));
      expect(AppColors.darkBorder, const Color(0xFF34373E));
      // --secondary + --muted: 0 0% 10%
      expect(AppColors.darkSecondary, const Color(0xFF1A1A1A));
      expect(AppColors.darkMuted, const Color(0xFF1A1A1A));
      // --muted-foreground: 0 0% 65%
      expect(AppColors.darkMutedForeground, const Color(0xFFA6A6A6));
    });

    test('brand gold and destructive', () {
      // --primary + --accent: 43 96% 50%
      expect(AppColors.darkPrimary, const Color(0xFFFAB505));
      expect(AppColors.darkAccent, const Color(0xFFFAB505));
      expect(AppColors.darkPrimaryForeground, const Color(0xFF0D0D0D));
      // --destructive: 0 62.8% 50%
      expect(AppColors.darkDestructive, const Color(0xFFD02F2F));
    });
  });

  group('radius scale follows @theme inline', () {
    test('derives from --radius: 0.5rem', () {
      expect(AppColors.radiusSm, 4);
      expect(AppColors.radiusMd, 6);
      expect(AppColors.radiusLg, 8);
      expect(AppColors.radiusXl, 12);
    });

    test('cards use rounded-xl and buttons rounded-md', () {
      final card = AppTheme.dark.cardTheme.shape! as RoundedRectangleBorder;
      expect(card.borderRadius, BorderRadius.circular(AppColors.radiusXl));

      final button =
          AppTheme.dark.elevatedButtonTheme.style!.shape!.resolve({})!
              as RoundedRectangleBorder;
      expect(button.borderRadius, BorderRadius.circular(AppColors.radiusMd));
    });
  });

  test('filled buttons put near-black on gold in both themes', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final style = theme.elevatedButtonTheme.style!;
      expect(style.backgroundColor!.resolve({}), theme.colorScheme.primary);
      expect(
        style.foregroundColor!.resolve({}),
        const Color(0xFF0D0D0D),
        reason: 'index.css pairs --primary with --primary-foreground: 0 0% 5%',
      );
    }
  });

  test('small gold text stays readable on a light background', () {
    // Satu-satunya penyimpangan yang disengaja dari web: emas terang di atas
    // putih hanya ~1.9:1, sehingga teks/ikon kecil memakai nada yang lebih
    // gelap. Isian tombol tetap memakai emas web.
    expect(AppColors.lightPrimaryText, const Color(0xFF8A5900));
    expect(AppColors.darkPrimaryText, AppColors.darkPrimary);

    final textButton = AppTheme.light.textButtonTheme.style!;
    expect(textButton.foregroundColor!.resolve({}), AppColors.lightPrimaryText);
  });
}
