import 'package:shared_preferences/shared_preferences.dart';

import '../core/setup/setup_prompt_policy.dart';

/// Stores what [SetupPromptPolicy] needs. The ask is recorded before the sheet
/// is shown, so a crash cannot lead to an extra ask.
class SetupPromptService {
  SetupPromptService(this._preferences, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _askCountKey = 'setup_prompt.ask_count';
  static const _lastAskKey = 'setup_prompt.last_ask_at';

  final SharedPreferences _preferences;
  final DateTime Function() _clock;

  SetupPromptState get state {
    final last = _preferences.getInt(_lastAskKey);
    return SetupPromptState(
      askCount: _preferences.getInt(_askCountKey) ?? 0,
      lastAskedAt: last == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(last),
    );
  }

  bool isDue(int analysisCount) =>
      SetupPromptPolicy.shouldAsk(state, analysisCount, _clock());

  Future<void> recordAsked() async {
    await _preferences.setInt(_askCountKey, state.askCount + 1);
    await _preferences.setInt(_lastAskKey, _clock().millisecondsSinceEpoch);
  }
}
