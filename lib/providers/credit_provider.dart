import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../l10n/app_messages.dart';
import '../repositories/topup_repository.dart';
import 'auth_provider.dart';

/// Read-only state for the authenticated user's analysis-credit balance.
class CreditProvider extends ChangeNotifier {
  CreditProvider(this._authProvider, this._repository) {
    _activeUserId = _currentUserId;
    _authProvider.addListener(_handleAuthChanged);
    if (_activeUserId != null) unawaited(loadBalance());
  }

  final AuthProvider _authProvider;
  final TopupRepository _repository;

  int? _balance;
  bool _isLoadingBalance = false;
  String? _balanceError;
  int? _activeUserId;
  int _sessionEpoch = 0;
  int _balanceRequestId = 0;

  int? get balance => _balance;
  bool get hasBalance => _balance != null;
  bool get isLoadingBalance => _isLoadingBalance;
  String? get balanceError => _balanceError;

  int? get _currentUserId {
    if (_authProvider.status != AuthStatus.authenticated) return null;
    return _authProvider.user?.id;
  }

  Future<void> loadBalance({bool silent = false}) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final epoch = _sessionEpoch;
    final requestId = ++_balanceRequestId;
    bool isCurrent() =>
        epoch == _sessionEpoch &&
        userId == _currentUserId &&
        requestId == _balanceRequestId;

    if (!silent) {
      _isLoadingBalance = true;
      _balanceError = null;
      notifyListeners();
    }

    try {
      final result = await _repository.getBalance();
      if (!isCurrent()) return;
      if (result != null) {
        _balance = result.balance;
        _balanceError = null;
      }
    } catch (error) {
      if (isCurrent() && !silent) _balanceError = _friendlyError(error);
    } finally {
      if (isCurrent()) {
        _isLoadingBalance = false;
        notifyListeners();
      }
    }
  }

  void reset() {
    _invalidateRequests();
    _clearState();
    notifyListeners();
  }

  void _handleAuthChanged() {
    final nextUserId = _currentUserId;
    if (nextUserId == _activeUserId) return;

    _activeUserId = nextUserId;
    _invalidateRequests();
    _clearState();
    if (nextUserId != null) unawaited(loadBalance());
    notifyListeners();
  }

  void _invalidateRequests() {
    _sessionEpoch++;
    _balanceRequestId++;
  }

  void _clearState() {
    _balance = null;
    _isLoadingBalance = false;
    _balanceError = null;
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) return AppMessages.l10n.errSessionExpiredRelogin;
      if (status != null && status >= 500) {
        return AppMessages.l10n.errServerProblem;
      }
      if (error.type == DioExceptionType.connectionError) {
        return AppMessages.l10n.errNoConnection;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return AppMessages.l10n.errConnectionTimeout;
      }
    }
    return AppMessages.l10n.errBalanceLoadFailed;
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
