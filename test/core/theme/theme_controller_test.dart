import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradepilotapp/core/theme/app_colors.dart';
import 'package:tradepilotapp/core/theme/app_theme.dart';
import 'package:tradepilotapp/core/theme/theme_controller.dart';

void main() {
  test('defaults to dark and persists a light-mode selection', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(preferences);

    expect(controller.mode, ThemeMode.dark);

    await controller.setDarkMode(false);

    expect(controller.mode, ThemeMode.light);
    expect(ThemeController(preferences).mode, ThemeMode.light);
  });

  test('uses the website brand and chart color tokens', () {
    expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(AppTheme.dark.colorScheme.surface, AppColors.darkCard);
    expect(AppTheme.dark.colorScheme.primary, AppColors.darkPrimary);
    expect(AppTheme.dark.colorScheme.outline, AppColors.darkBorder);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.lightBackground);
    expect(AppTheme.light.colorScheme.primary, AppColors.lightPrimary);
    expect(AppColors.entry, const Color(0xFFF59E0B));
    expect(AppColors.stopLoss, const Color(0xFFEF4444));
    expect(AppColors.takeProfit, const Color(0xFF10B981));
    expect(AppColors.chartTextDark, const Color(0xFFCBD5E1));
    expect(AppColors.chartTextLight, const Color(0xFF475569));
  });
}
