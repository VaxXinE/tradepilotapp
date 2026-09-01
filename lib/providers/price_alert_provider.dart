import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../repositories/price_alert_repository.dart';
import 'auth_provider.dart';

class PriceAlertProvider extends ChangeNotifier {
  PriceAlertProvider(this._authProvider, this._repository) {
    _activeUserId = _currentUserId;
    _authProvider.addListener(_handleAuthChanged);
  }

  final AuthProvider _authProvider;
  final PriceAlertRepository _repository;

  List<UserPriceAlert> _alerts = const [];
  bool _isLoading = false;
  bool _isCreating = false;
  final Set<int> _deletingIds = {};

  String? _error;

  int? _activeUserId;
  int _sessionEpoch = 0;
  int _loadRequestId = 0;
  int _createRequestId = 0;

  List<UserPriceAlert> get alerts => List.unmodifiable(_alerts);
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;
  bool get hasError => _error != null;

  bool isDeleting(int id) => _deletingIds.contains(id);

  int? get _currentUserId {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }
    return _authProvider.user?.id;
  }

  Future<void> loadAlerts() async {
    final userId = _currentUserId;
    if (userId == null || _isLoading) {
      return;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_loadRequestId;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.getAlerts();
      if (!_isCurrent(epoch, userId) || requestId != _loadRequestId) {
        return;
      }
      _alerts = result;
      _error = null;
    } catch (error) {
      if (_isCurrent(epoch, userId) && requestId == _loadRequestId) {
        _error = _friendlyError(error, 'Gagal memuat price alert.');
      }
    } finally {
      if (_isCurrent(epoch, userId) && requestId == _loadRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createAlert({
    required String instrument,
    required double targetPrice,
    required bool triggerAbove,
    String? note,
  }) async {
    _error = null;

    final normalized = instrument.trim().toUpperCase();

    if (normalized.isEmpty) {
      _error = 'Instrumen tidak boleh kosong.';
      notifyListeners();
      return false;
    }

    if (!targetPrice.isFinite || targetPrice <= 0) {
      _error = 'Target harga harus lebih besar dari 0.';
      notifyListeners();
      return false;
    }

    final trimmedNote = note?.trim();

    if (trimmedNote != null && trimmedNote.length > 200) {
      _error = 'Catatan maksimal 200 karakter.';
      notifyListeners();
      return false;
    }

    final userId = _currentUserId;

    if (userId == null) {
      _error = 'Sesi login sudah berakhir.';
      notifyListeners();
      return false;
    }

    if (_isCreating) {
      return false;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_createRequestId;
    _isCreating = true;
    notifyListeners();

    bool isCurrent() =>
        _isCurrent(epoch, userId) && requestId == _createRequestId;

    try {
      final created = await _repository.createAlert(
        instrument: normalized,
        targetPrice: targetPrice,
        triggerAbove: triggerAbove,
        note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
      );

      if (!isCurrent()) {
        return false;
      }

      if (created == null) {
        throw const FormatException('Invalid price alert response.');
      }

      _alerts = [created, ..._alerts];
      return true;
    } catch (error) {
      if (isCurrent()) {
        _error = _friendlyError(error, 'Gagal membuat price alert.');
        notifyListeners();
      }
      return false;
    } finally {
      if (isCurrent()) {
        _isCreating = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteAlert(int id) async {
    final userId = _currentUserId;

    if (userId == null) {
      _error = 'Sesi login sudah berakhir.';
      notifyListeners();
      return false;
    }

    if (_deletingIds.contains(id)) {
      return false;
    }

    final epoch = _sessionEpoch;
    _deletingIds.add(id);
    _error = null;
    notifyListeners();

    bool isCurrent() => _isCurrent(epoch, userId) && _deletingIds.contains(id);

    try {
      await _repository.deleteAlert(id);

      if (!isCurrent()) {
        return false;
      }

      _alerts = _alerts.where((alert) => alert.id != id).toList();
      return true;
    } catch (error) {
      if (isCurrent()) {
        _error = _friendlyError(error, 'Gagal menghapus price alert.');
        notifyListeners();
      }
      return false;
    } finally {
      if (_isCurrent(epoch, userId)) {
        _deletingIds.remove(id);
        notifyListeners();
      }
    }
  }

  void reset() {
    _sessionEpoch++;
    _loadRequestId++;
    _createRequestId++;
    _resetState();
    notifyListeners();
  }

  void _handleAuthChanged() {
    final nextUserId = _currentUserId;
    if (nextUserId == _activeUserId) {
      return;
    }

    _activeUserId = nextUserId;
    _sessionEpoch++;
    _loadRequestId++;
    _createRequestId++;
    _resetState();

    if (nextUserId != null) {
      unawaited(loadAlerts());
    }
    notifyListeners();
  }

  void _resetState() {
    _alerts = const [];
    _isLoading = false;
    _isCreating = false;
    _deletingIds.clear();
    _error = null;
  }

  bool _isCurrent(int epoch, int userId) {
    return epoch == _sessionEpoch && _currentUserId == userId;
  }

  String _friendlyError(Object error, String fallback) {
    if (error is ArgumentError) {
      final message = error.message;
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map) {
        final message = body['error'] ?? body['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      if (error.response?.statusCode == 401) {
        return 'Sesi login sudah berakhir.';
      }
    }

    return fallback;
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
