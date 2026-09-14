import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MentalChecklistController extends ChangeNotifier {
  MentalChecklistController(this._preferences)
    : _enabled = _preferences.getBool(_preferenceKey) ?? false;

  static const _preferenceKey = 'tradepilot.mentalChecklist.enabled';

  final SharedPreferences _preferences;
  bool _enabled;

  bool get enabled => _enabled;

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
    await _preferences.setBool(_preferenceKey, enabled);
  }
}
