import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
