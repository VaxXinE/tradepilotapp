import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../core/preferences/progression_level_observation.dart';
import 'auth_provider.dart';

class ProgressionProvider extends ChangeNotifier {
  ProgressionProvider(this._auth) {
    _activeUserId = _currentUserId;
    _auth.addListener(_handleAuthChanged);
    if (_activeUserId != null) Future.microtask(() => refresh(silent: true));
  }

  final AuthProvider _auth;

  ProgressionSummary? summary;
  ProgressionCatalog? catalog;
  ProgressionHistory? history;
  bool isLoading = false;
  String? error;

  Set<String> get completedGuideIds =>
      catalog?.completedGuideIds.toSet() ?? const {};

  /// A level reached during this session that has not been celebrated yet.
  int? celebrationLevel;

  int? _activeUserId;
  int _sessionEpoch = 0;

  // Level-up observation (web `ProgressionLevelUpWatcher`). The mobile key is
  // separate from the web one so the two apps never suppress each other.
  static const _ackPrefix = 'tp_mobile_progression_level_ack';
  int? _observedUserId;
  int? _previousLevel;
  int? _previousTotalXp;
  int _highestAcknowledgedLevel = 0;

  int? get _currentUserId =>
      _auth.status == AuthStatus.authenticated ? _auth.user?.id : null;

  Future<void> refresh({bool silent = false}) async {
    final userId = _currentUserId;
    if (userId == null) return;
    final epoch = _sessionEpoch;
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }
    try {
      final responses = await Future.wait([
        _auth.client.progression.getProgressionSummary(),
        _auth.client.progression.getProgressionCatalog(),
        _auth.client.progression.getProgressionHistory(limit: 100),
      ]);
      if (epoch != _sessionEpoch || userId != _currentUserId) {
        return;
      }
      summary = responses[0].data as ProgressionSummary?;
      catalog = responses[1].data as ProgressionCatalog?;
      history = responses[2].data as ProgressionHistory?;
      error = summary == null ? 'empty' : null;
      if (summary != null) await _observeLevel(userId, summary!, epoch);
    } catch (_) {
      if (epoch == _sessionEpoch && userId == _currentUserId) error = 'load';
    } finally {
      if (epoch == _sessionEpoch && userId == _currentUserId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Celebrates a level reached in this session. The first summary of a
  /// session (or of a new account) only sets the baseline.
  Future<void> _observeLevel(
    int userId,
    ProgressionSummary current,
    int epoch,
  ) async {
    final key = '$_ackPrefix.$userId';
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Without storage the in-memory baseline still prevents duplicates.
    }
    if (epoch != _sessionEpoch || userId != _currentUserId) return;

    if (_observedUserId != userId) {
      final stored = prefs?.getInt(key) ?? 0;
      _highestAcknowledgedLevel = stored > current.level
          ? stored
          : current.level;
      unawaited(_writeAck(prefs, key, _highestAcknowledgedLevel));
      _observedUserId = userId;
      _previousLevel = current.level;
      _previousTotalXp = current.totalXp;
      celebrationLevel = null;
      return;
    }

    final result = observeProgressionLevel(
      currentLevel: current.level,
      previousLevel: _previousLevel,
      currentTotalXp: current.totalXp,
      previousTotalXp: _previousTotalXp,
      highestAcknowledgedLevel: _highestAcknowledgedLevel,
    );
    _previousLevel = current.level;
    _previousTotalXp = current.totalXp;
    if (result.highestAcknowledgedLevel > _highestAcknowledgedLevel) {
      // Persist before presenting so a restart cannot replay this level-up.
      _highestAcknowledgedLevel = result.highestAcknowledgedLevel;
      await _writeAck(prefs, key, _highestAcknowledgedLevel);
    }
    if (result.celebrateLevel != null) celebrationLevel = result.celebrateLevel;
  }

  Future<void> _writeAck(
    SharedPreferences? prefs,
    String key,
    int level,
  ) async {
    try {
      await prefs?.setInt(key, level);
    } catch (_) {
      // The in-memory value still covers this session.
    }
  }

  /// Called once the level-up dialog has been shown and dismissed.
  void acknowledgeCelebration() {
    if (celebrationLevel == null) return;
    celebrationLevel = null;
    notifyListeners();
  }

  void _handleAuthChanged() {
    final userId = _currentUserId;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    _sessionEpoch++;
    _observedUserId = null;
    _previousLevel = null;
    _previousTotalXp = null;
    _highestAcknowledgedLevel = 0;
    celebrationLevel = null;
    summary = null;
    catalog = null;
    history = null;
    isLoading = false;
    error = null;
    notifyListeners();
    if (userId != null) unawaited(refresh(silent: true));
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
