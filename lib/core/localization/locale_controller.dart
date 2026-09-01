import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._preferences)
    : _locale = Locale(_preferences.getString(_preferenceKey) ?? 'en');

  static const _preferenceKey = 'app_language_code';
  static const supportedLanguageCodes = {'en', 'id'};

  final SharedPreferences _preferences;
  Locale _locale;

  Locale get locale => _locale;

  Future<void> setLanguage(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode) ||
        _locale.languageCode == languageCode) {
      return;
    }

    _locale = Locale(languageCode);
    notifyListeners();
    await _preferences.setString(_preferenceKey, languageCode);
  }
}
