import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../repositories/watchlist_repository.dart';
import 'auth_provider.dart';

class WatchlistProvider extends ChangeNotifier {
  WatchlistProvider(this._authProvider, this._repository) {
    _activeUserId = _currentUserId;
    _authProvider.addListener(_handleAuthChanged);
  }

  final AuthProvider _authProvider;
  final WatchlistRepository _repository;

  List<WatchlistItem> _items = const [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;
  int? _activeUserId;
  int _sessionEpoch = 0;
  int _loadRequestId = 0;
  int _mutationRequestId = 0;

  List<WatchlistItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;
  bool get hasError => _error != null;

  int? get _currentUserId {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }
    return _authProvider.user?.id;
  }

  bool isWatchlisted(String instrument) {
    final normalized = _normalize(instrument);
    return _items.any((item) => _normalize(item.instrument) == normalized);
  }

  Future<void> loadWatchlist() async {
    final userId = _currentUserId;
    if (userId == null || _isLoading || _isUpdating) {
      return;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_loadRequestId;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.getWatchlist();
      if (!_isCurrent(epoch, userId) || requestId != _loadRequestId) {
        return;
      }
      _items = result;
      _error = null;
    } catch (error) {
      if (_isCurrent(epoch, userId) && requestId == _loadRequestId) {
        _error = _friendlyError(error, 'Gagal memuat watchlist.');
      }
    } finally {
      if (_isCurrent(epoch, userId) && requestId == _loadRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addInstrument(String instrument) async {
    final normalized = _normalize(instrument);
    if (isWatchlisted(normalized)) {
      return false;
    }

    return _mutate((isCurrent) async {
      final item = await _repository.addInstrument(normalized);
      if (!isCurrent()) {
        return;
      }
      if (item == null) {
        throw const FormatException('Invalid watchlist response.');
      }
      _items = [..._items, item];
    });
  }

  Future<bool> removeInstrument(String instrument) async {
    final normalized = _normalize(instrument);
    if (!isWatchlisted(normalized)) {
      return false;
    }

    return _mutate((isCurrent) async {
      await _repository.removeInstrument(normalized);
      if (!isCurrent()) {
        return;
      }
      _items = _items
          .where((item) => _normalize(item.instrument) != normalized)
          .toList();
    });
  }

  Future<bool> toggleInstrument(String instrument) {
    return isWatchlisted(instrument)
        ? removeInstrument(instrument)
        : addInstrument(instrument);
  }

  Future<bool> _mutate(
    Future<void> Function(bool Function() isCurrent) operation,
  ) async {
    final userId = _currentUserId;
    if (userId == null) {
      _error = 'Silakan login kembali.';
      notifyListeners();
      return false;
    }
    if (_isUpdating) {
      return false;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_mutationRequestId;
    _loadRequestId++;
    _isLoading = false;
    _isUpdating = true;
    _error = null;
    notifyListeners();

    bool isCurrent() =>
        _isCurrent(epoch, userId) && requestId == _mutationRequestId;

    try {
      await operation(isCurrent);
      return isCurrent();
    } catch (error) {
      if (_isCurrent(epoch, userId) && requestId == _mutationRequestId) {
        _error = _friendlyError(error, 'Gagal memperbarui watchlist.');
        notifyListeners();
      }
      return false;
    } finally {
      if (_isCurrent(epoch, userId) && requestId == _mutationRequestId) {
        _isUpdating = false;
        notifyListeners();
      }
    }
  }

  void reset() {
    _sessionEpoch++;
    _loadRequestId++;
    _mutationRequestId++;
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
    _mutationRequestId++;
    _resetState();

    if (nextUserId != null) {
      unawaited(loadWatchlist());
    }
    notifyListeners();
  }

  void _resetState() {
    _items = const [];
    _isLoading = false;
    _isUpdating = false;
    _error = null;
  }

  bool _isCurrent(int epoch, int userId) {
    return epoch == _sessionEpoch && _currentUserId == userId;
  }

  String _normalize(String instrument) => instrument.trim().toUpperCase();

  String _friendlyError(Object error, String fallback) {
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
