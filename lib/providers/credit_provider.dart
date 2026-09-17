import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../repositories/topup_repository.dart';
import 'auth_provider.dart';
import '../l10n/app_messages.dart';

/// State credit dan top-up.
///
/// Saldo backend tetap menjadi sumber kebenaran; provider ini hanya menyimpan
/// hasil terakhir supaya UI tidak perlu memanggil ulang pada tiap rebuild.
///
/// Saldo, konfigurasi, dan riwayat punya flag loading serta error masing-masing
/// supaya kegagalan salah satunya tidak menjatuhkan yang lain — halaman Profile
/// harus tetap terbuka meski `GET /topups/balance` gagal.
class CreditProvider extends ChangeNotifier {
  CreditProvider(this._authProvider, this._repository) {
    _activeUserId = _currentUserId;
    _authProvider.addListener(_handleAuthChanged);

    if (_activeUserId != null) {
      unawaited(loadBalance());
    }
  }

  final AuthProvider _authProvider;
  final TopupRepository _repository;

  // ===========================================================================
  // STATE
  // ===========================================================================

  /// `null` selama saldo belum pernah berhasil dimuat.
  int? _balance;
  TopupConfig? _config;
  List<TopupRequest> _history = const [];
  int _historyTotal = 0;
  int _historyPage = 1;

  bool _isLoadingBalance = false;
  bool _isLoadingConfig = false;
  bool _isLoadingHistory = false;
  bool _isLoadingMoreHistory = false;
  bool _isSubmitting = false;

  String? _balanceError;
  String? _configError;
  String? _historyError;
  String? _submitError;

  int? _activeUserId;
  int _sessionEpoch = 0;
  int _balanceRequestId = 0;
  int _configRequestId = 0;
  int _historyRequestId = 0;
  int _submitRequestId = 0;
  bool _historyRequestInFlight = false;

  int? get balance => _balance;
  bool get hasBalance => _balance != null;
  TopupConfig? get config => _config;
  List<TopupRequest> get history => List.unmodifiable(_history);
  int get historyTotal => _historyTotal;
  int get historyPage => _historyPage;

  bool get isLoadingBalance => _isLoadingBalance;
  bool get isLoadingConfig => _isLoadingConfig;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingMoreHistory => _isLoadingMoreHistory;
  bool get isSubmitting => _isSubmitting;

  String? get balanceError => _balanceError;
  String? get configError => _configError;
  String? get historyError => _historyError;
  String? get submitError => _submitError;

  bool get hasMoreHistory => _history.length < _historyTotal;

  /// Jumlah credit untuk sebuah nominal Rupiah, mengikuti rate backend.
  ///
  /// `null` selama konfigurasi belum dimuat, supaya UI tidak menebak rate.
  int? creditsFor(int amountRupiah) {
    final rate = _config?.rupiahPerCredit;

    if (rate == null || rate <= 0 || amountRupiah <= 0) {
      return null;
    }

    return amountRupiah ~/ rate;
  }

  int? get _currentUserId {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }

    return _authProvider.user?.id;
  }

  // ===========================================================================
  // BALANCE
  // ===========================================================================

  /// `GET /topups/balance`
  ///
  /// [silent] dipakai untuk refresh latar belakang — saldo lama tetap tampil
  /// dan kegagalannya tidak memunculkan error baru di layar.
  Future<void> loadBalance({bool silent = false}) async {
    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_balanceRequestId;

    bool isCurrent() =>
        _isCurrent(epoch, userId) && requestId == _balanceRequestId;

    if (!silent) {
      _isLoadingBalance = true;
      _balanceError = null;
      notifyListeners();
    }

    try {
      final result = await _repository.getBalance();

      if (!isCurrent()) {
        return;
      }

      if (result != null) {
        _balance = result.balance;
        _balanceError = null;
      }
    } catch (error) {
      if (isCurrent() && !silent) {
        _balanceError = _friendlyError(
          error,
          AppMessages.l10n.errBalanceLoadFailed,
        );
      }
    } finally {
      if (isCurrent()) {
        _isLoadingBalance = false;
        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // CONFIG
  // ===========================================================================

  /// `GET /topups/config`
  Future<void> loadConfig() async {
    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_configRequestId;

    bool isCurrent() =>
        _isCurrent(epoch, userId) && requestId == _configRequestId;

    _isLoadingConfig = true;
    _configError = null;
    notifyListeners();

    try {
      final result = await _repository.getConfig();

      if (!isCurrent()) {
        return;
      }

      if (result != null) {
        _config = result;
        _configError = null;
      }
    } catch (error) {
      if (isCurrent()) {
        _configError = _friendlyError(
          error,
          AppMessages.l10n.errTopupConfigLoadFailed,
        );
      }
    } finally {
      if (isCurrent()) {
        _isLoadingConfig = false;
        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // HISTORY
  // ===========================================================================

  /// `GET /topups/mine`
  ///
  /// [refresh] memuat ulang dari halaman pertama. Item digabung berdasarkan id
  /// sehingga refresh tidak pernah menggandakan riwayat.
  Future<void> loadHistory({bool refresh = false}) async {
    await _loadHistoryPage(refresh ? 1 : _historyPage);
  }

  Future<void> loadMoreHistory() async {
    if (_historyRequestInFlight || !hasMoreHistory) {
      return;
    }

    await _loadHistoryPage(_historyPage + 1);
  }

  Future<void> _loadHistoryPage(int page) async {
    final userId = _currentUserId;

    if (userId == null) {
      return;
    }

    // Cegah tabrakan antara pull-to-refresh dan scroll pagination.
    if (_historyRequestInFlight) {
      return;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_historyRequestId;
    final isLoadMore = page > 1;

    _historyRequestInFlight = true;

    if (isLoadMore) {
      _isLoadingMoreHistory = true;
    } else {
      _isLoadingHistory = true;
    }

    _historyError = null;
    notifyListeners();

    bool isCurrent() =>
        _isCurrent(epoch, userId) && requestId == _historyRequestId;

    try {
      final result = await _repository.getMyRequests(page: page);

      if (!isCurrent()) {
        return;
      }

      if (result != null) {
        final incoming = result.requests.toList();

        _history = page == 1 ? incoming : _mergeUnique(_history, incoming);
        _historyPage = page;
        _historyTotal = result.total;
        _historyError = null;
      }
    } catch (error) {
      if (isCurrent()) {
        _historyError = _friendlyError(
          error,
          AppMessages.l10n.errTopupHistoryLoadFailed,
        );
      }
    } finally {
      // Flag in-flight selalu dilepas oleh request yang mengambilnya, walaupun
      // sesi sudah berganti — kalau tidak, pagination bisa macet permanen.
      _historyRequestInFlight = false;

      if (_isCurrent(epoch, userId)) {
        if (isLoadMore) {
          _isLoadingMoreHistory = false;
        } else {
          _isLoadingHistory = false;
        }

        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // CREATE TOP-UP
  // ===========================================================================

  /// `POST /topups`
  ///
  /// Mengembalikan `null` kalau gagal; pesan errornya ada di [submitError].
  /// Pemanggilan kedua saat request pertama masih jalan diabaikan, supaya double
  /// tap tidak membuat dua permintaan top-up.
  Future<TopupRequest?> submitTopup({
    required int amountRupiah,
    String? paymentReferenceNote,
    required String proofObjectPath,
  }) async {
    final userId = _currentUserId;

    if (userId == null) {
      _submitError = AppMessages.l10n.errSessionExpiredRelogin;
      notifyListeners();
      return null;
    }

    if (_isSubmitting) {
      return null;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_submitRequestId;

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    bool isCurrent() =>
        _isCurrent(epoch, userId) && requestId == _submitRequestId;

    try {
      final created = await _repository.createRequest(
        amountRupiah: amountRupiah,
        paymentReferenceNote: paymentReferenceNote,
        proofObjectPath: proofObjectPath,
      );

      if (!isCurrent()) {
        return null;
      }

      if (created == null) {
        throw const FormatException('Invalid top-up response.');
      }

      // Merge by id: kalau riwayat di-refresh setelah ini, item yang sama tidak
      // akan muncul dua kali.
      _history = _mergeUnique(_history, [created]);
      _historyTotal += 1;

      // Backend terbaru meng-approve dan mengkredit top-up langsung. Ambil
      // saldo authoritative agar UI tidak tetap menampilkan nilai lama.
      if (created.status == TopupRequestStatus.approved) {
        await loadBalance();
      }

      return created;
    } catch (error) {
      if (isCurrent()) {
        _submitError = _friendlyError(
          error,
          AppMessages.l10n.errTopupSubmitFailed,
        );
      }

      return null;
    } finally {
      if (isCurrent()) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  /// Muat ulang data halaman Top Up dalam satu tarikan.
  Future<void> refreshAll() async {
    await Future.wait([
      loadBalance(),
      loadConfig(),
      loadHistory(refresh: true),
    ]);
  }

  void clearSubmitError() {
    if (_submitError == null) {
      return;
    }

    _submitError = null;
    notifyListeners();
  }

  void reset() {
    _bumpSession();
    _resetState();
    notifyListeners();
  }

  void _handleAuthChanged() {
    final nextUserId = _currentUserId;

    if (nextUserId == _activeUserId) {
      return;
    }

    _activeUserId = nextUserId;
    _bumpSession();
    _resetState();

    if (nextUserId != null) {
      unawaited(loadBalance());
    }

    notifyListeners();
  }

  void _bumpSession() {
    _sessionEpoch++;
    _balanceRequestId++;
    _configRequestId++;
    _historyRequestId++;
    _submitRequestId++;
    _historyRequestInFlight = false;
  }

  void _resetState() {
    _balance = null;
    _config = null;
    _history = const [];
    _historyTotal = 0;
    _historyPage = 1;
    _isLoadingBalance = false;
    _isLoadingConfig = false;
    _isLoadingHistory = false;
    _isLoadingMoreHistory = false;
    _isSubmitting = false;
    _balanceError = null;
    _configError = null;
    _historyError = null;
    _submitError = null;
  }

  bool _isCurrent(int epoch, int userId) {
    return epoch == _sessionEpoch && _currentUserId == userId;
  }

  List<TopupRequest> _mergeUnique(
    List<TopupRequest> existing,
    List<TopupRequest> incoming,
  ) {
    final byId = <int, TopupRequest>{};

    for (final item in existing) {
      byId[item.id] = item;
    }

    // Data server terbaru menang atas cache lama.
    for (final item in incoming) {
      byId[item.id] = item;
    }

    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  String _friendlyError(Object error, String fallback) {
    if (error is ArgumentError) {
      final message = error.message;

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    if (error is DioException) {
      final status = error.response?.statusCode;

      if (status == 401) {
        return AppMessages.l10n.errSessionExpiredRelogin;
      }

      // Validasi backend (mis. nominal di luar batas) memang untuk dibaca
      // pengguna. Detail 5xx tidak: itu internal server dan tidak boleh bocor
      // ke layar maupun log analytics.
      if (status != null && status >= 400 && status < 500) {
        final body = error.response?.data;

        if (body is Map) {
          final message = body['error'] ?? body['message'];

          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }

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

    return fallback;
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
