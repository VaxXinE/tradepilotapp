import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._preferences)
    : _isDarkMode = _preferences.getBool(_preferenceKey) ?? true;

  static const _preferenceKey = 'dark_mode_enabled';

  final SharedPreferences _preferences;
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get mode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDarkMode(bool enabled) async {
    if (_isDarkMode == enabled) return;

    _isDarkMode = enabled;
    notifyListeners();
    await _preferences.setBool(_preferenceKey, enabled);
  }
}
