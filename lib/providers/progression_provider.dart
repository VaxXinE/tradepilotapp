import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

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

  int? _activeUserId;
  int _sessionEpoch = 0;

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
    } catch (_) {
      if (epoch == _sessionEpoch && userId == _currentUserId) error = 'load';
    } finally {
      if (epoch == _sessionEpoch && userId == _currentUserId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void _handleAuthChanged() {
    final userId = _currentUserId;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    _sessionEpoch++;
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
