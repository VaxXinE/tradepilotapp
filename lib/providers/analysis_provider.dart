import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

import 'auth_provider.dart';

/// Single source of truth untuk seluruh state analisis.
///
/// Tanggung jawab:
/// - create analysis
/// - history
/// - pagination
/// - summary dashboard
/// - quota
/// - detail cache update
/// - silent background revalidation
/// - timeout recovery
/// - isolasi cache antar-user
class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider(this._authProvider) {
    _activeUserId = _currentAuthenticatedUserId;
    _authProvider.addListener(_handleAuthStateChanged);
  }

  final AuthProvider _authProvider;

  TradePilotClient get _client => _authProvider.client;

  // ---------------------------------------------------------------------------
  // PUBLIC STATE
  // ---------------------------------------------------------------------------

  bool isSubmitting = false;

  bool isLoadingHistory = false;
  bool isLoadingMoreHistory = false;

  bool isLoadingSummary = false;

  String? errorMessage;

  List<Analysis> history = [];

  int historyTotal = 0;
  int historyPage = 1;

  static const int _pageSize = 20;

  AnalysesSummary? summary;
  AnalysisQuota? quota;

  // ---------------------------------------------------------------------------
  // INTERNAL STATE
  // ---------------------------------------------------------------------------

  int? _activeUserId;
  int _sessionEpoch = 0;

  bool _historyRequestInFlight = false;
  bool _summaryRequestInFlight = false;
  bool _quotaRequestInFlight = false;

  int _historyRequestId = 0;
  int _summaryRequestId = 0;
  int _quotaRequestId = 0;
  int _createRequestId = 0;

  // ---------------------------------------------------------------------------
  // AUTH / CACHE ISOLATION
  // ---------------------------------------------------------------------------

  int? get _currentAuthenticatedUserId {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }

    return _authProvider.user?.id;
  }

  bool _isSessionCurrent(int epoch) {
    return epoch == _sessionEpoch &&
        _authProvider.status == AuthStatus.authenticated &&
        _currentAuthenticatedUserId == _activeUserId;
  }

  void _handleAuthStateChanged() {
    final nextUserId = _currentAuthenticatedUserId;

    if (nextUserId == _activeUserId) {
      return;
    }

    _activeUserId = nextUserId;
    _sessionEpoch++;

    // Invalidasi seluruh request lama agar response milik user sebelumnya
    // tidak boleh masuk ke cache user baru.
    _historyRequestId++;
    _summaryRequestId++;
    _quotaRequestId++;
    _createRequestId++;

    _historyRequestInFlight = false;
    _summaryRequestInFlight = false;
    _quotaRequestInFlight = false;

    _resetCachedData();

    notifyListeners();
  }

  void _resetCachedData() {
    isSubmitting = false;

    isLoadingHistory = false;
    isLoadingMoreHistory = false;
    isLoadingSummary = false;

    errorMessage = null;

    history = [];
    historyTotal = 0;
    historyPage = 1;

    summary = null;
    quota = null;
  }

  // ---------------------------------------------------------------------------
  // QUOTA
  // ---------------------------------------------------------------------------

  Future<void> loadQuota() async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    if (_quotaRequestInFlight) {
      return;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_quotaRequestId;

    _quotaRequestInFlight = true;

    try {
      final response = await _client.analyses.getAnalysisQuota();

      if (!_isSessionCurrent(epoch) ||
          requestId != _quotaRequestId) {
        return;
      }

      quota = response.data;
    } catch (_) {
      // Quota bukan critical state.
      // Kalau background refresh gagal, pertahankan cache terakhir.
    } finally {
      if (requestId == _quotaRequestId) {
        _quotaRequestInFlight = false;

        if (_isSessionCurrent(epoch)) {
          notifyListeners();
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SUMMARY
  // ---------------------------------------------------------------------------

  Future<void> loadSummary({
    bool silent = false,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    if (_summaryRequestInFlight) {
      return;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_summaryRequestId;

    _summaryRequestInFlight = true;

    if (!silent) {
      isLoadingSummary = true;
      notifyListeners();
    }

    try {
      final response = await _client.analyses.getAnalysesSummary();

      if (!_isSessionCurrent(epoch) ||
          requestId != _summaryRequestId) {
        return;
      }

      summary = response.data;
    } catch (e) {
      if (_isSessionCurrent(epoch) && !silent) {
        errorMessage = _friendlyError(e);
      }
    } finally {
      if (requestId == _summaryRequestId) {
        _summaryRequestInFlight = false;

        if (_isSessionCurrent(epoch)) {
          if (!silent) {
            isLoadingSummary = false;
          }

          notifyListeners();
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CORE REFRESH
  // ---------------------------------------------------------------------------

  /// Refresh data yang dipakai Dashboard.
  ///
  /// silent = true:
  /// - data lama tetap tampil
  /// - tidak muncul loading full-screen
  /// - cocok untuk polling/background sync
  ///
  /// silent = false:
  /// - cocok untuk first load / pull-to-refresh
  Future<void> refreshCoreData({
    bool silent = true,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    await Future.wait([
      loadHistory(
        refresh: true,
        silent: silent,
      ),
      loadSummary(
        silent: silent,
      ),
      loadQuota(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // CREATE ANALYSIS
  // ---------------------------------------------------------------------------

  Future<Analysis?> createAnalysis({
    required String instrument,
    required CreateAnalysisBodyTimeframeEnum timeframe,
    required CreateAnalysisBodyModeEnum mode,
    String? userInputContext,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      errorMessage = 'Sesi login sudah berakhir. Silakan login kembali.';
      notifyListeners();

      return null;
    }

    // Defense-in-depth untuk mencegah double submit.
    if (isSubmitting) {
      return null;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_createRequestId;

    isSubmitting = true;
    errorMessage = null;

    notifyListeners();

    try {
      final response = await _client.analyses.createAnalysis(
        createAnalysisBody: CreateAnalysisBody(
          (builder) => builder
            ..instrument = instrument
            ..timeframe = timeframe
            ..mode = mode
            ..userInputContext = userInputContext,
        ),
      );

      if (!_isSessionCurrent(epoch) ||
          requestId != _createRequestId) {
        return null;
      }

      final created = response.data;

      isSubmitting = false;

      if (created != null) {
        final inserted = _upsertHistory(
          created,
          countAsNew: true,
        );

        if (inserted) {
          _optimisticallyIncrementSummary(created);
        }
      }

      notifyListeners();

      // UI tidak perlu menunggu GET lain.
      //
      // POST sudah memberikan Analysis lengkap, jadi langsung tampilkan.
      // Setelah itu server direvalidasi di background.
      unawaited(
        loadHistory(
          refresh: true,
          silent: true,
        ),
      );

      unawaited(
        loadSummary(
          silent: true,
        ),
      );

      unawaited(
        loadQuota(),
      );

      return created;
    } catch (e) {
      if (!_isSessionCurrent(epoch) ||
          requestId != _createRequestId) {
        return null;
      }

      isSubmitting = false;

      final isTimeout = e is DioException &&
          (e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionTimeout);

      if (isTimeout) {
        errorMessage =
            'Koneksi ke AI lama meresponsnya. Analisis mungkin tetap '
            'berhasil dibuat — data akan disinkronkan otomatis.';

        _scheduleTimeoutRevalidation(
          epoch: epoch,
          userId: _activeUserId,
        );
      } else {
        errorMessage = _friendlyError(e);
      }

      notifyListeners();

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // HISTORY
  // ---------------------------------------------------------------------------

  Future<void> loadHistory({
    bool refresh = false,
    bool silent = false,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    final requestedPage = refresh ? 1 : historyPage;

    await _loadHistoryPage(
      requestedPage,
      silent: silent,

      // Background refresh page 1 jangan menghapus page 2, 3, dst
      // yang sudah user load.
      preserveExistingPages: refresh && silent,
    );
  }

  Future<void> _loadHistoryPage(
    int page, {
    required bool silent,
    bool preserveExistingPages = false,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    // Prevent race-condition karena scroll listener / polling.
    if (_historyRequestInFlight) {
      return;
    }

    final epoch = _sessionEpoch;
    final requestId = ++_historyRequestId;

    final isLoadMore = page > 1;

    _historyRequestInFlight = true;

    if (!silent) {
      if (isLoadMore) {
        isLoadingMoreHistory = true;
      } else {
        isLoadingHistory = true;
      }

      notifyListeners();
    }

    try {
      final response = await _client.analyses.listAnalyses(
        page: page,
        limit: _pageSize,
      );

      if (!_isSessionCurrent(epoch) ||
          requestId != _historyRequestId) {
        return;
      }

      final data = response.data;

      if (data == null) {
        return;
      }

      final incoming = data.analyses.toList();

      if (page == 1) {
        if (preserveExistingPages && history.isNotEmpty) {
          // Silent polling:
          //
          // update data page 1 tetapi jangan buang pagination yang sudah
          // pernah user load.
          history = _mergeUnique(
            history,
            incoming,
          );
        } else {
          // Initial load / manual refresh.
          history = incoming;
          historyPage = 1;
        }
      } else {
        history = _mergeUnique(
          history,
          incoming,
        );

        historyPage = page;
      }

      historyTotal = data.total;
    } catch (e) {
      if (_isSessionCurrent(epoch) && !silent) {
        errorMessage = _friendlyError(e);
      }
    } finally {
      if (requestId == _historyRequestId) {
        _historyRequestInFlight = false;

        if (_isSessionCurrent(epoch)) {
          if (!silent) {
            if (isLoadMore) {
              isLoadingMoreHistory = false;
            } else {
              isLoadingHistory = false;
            }
          }

          notifyListeners();
        }
      }
    }
  }

  Future<void> loadMoreHistory() async {
    if (_historyRequestInFlight) {
      return;
    }

    if (isLoadingMoreHistory) {
      return;
    }

    if (historyTotal == 0) {
      return;
    }

    if (history.length >= historyTotal) {
      return;
    }

    await _loadHistoryPage(
      historyPage + 1,
      silent: false,
    );
  }

  // ---------------------------------------------------------------------------
  // DETAIL
  // ---------------------------------------------------------------------------

  Future<Analysis?> getAnalysis(
    int id, {
    bool silent = false,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }

    final epoch = _sessionEpoch;

    try {
      final response = await _client.analyses.getAnalysis(
        id: id,
      );

      if (!_isSessionCurrent(epoch)) {
        return null;
      }

      final analysis = response.data;

      if (analysis != null) {
        // Update object yang sama di History/Dashboard.
        _upsertHistory(analysis);

        notifyListeners();
      }

      return analysis;
    } catch (e) {
      if (_isSessionCurrent(epoch) && !silent) {
        errorMessage = _friendlyError(e);
        notifyListeners();
      }

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // FEEDBACK
  // ---------------------------------------------------------------------------

  Future<bool> submitFeedback({
    required int analysisId,
    required FeedbackBodyFeedbackTypeEnum type,
    FeedbackBodyOutcomeEnum? outcome,
    String? note,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return false;
    }

    final epoch = _sessionEpoch;

    try {
      await _client.analyses.submitFeedback(
        id: analysisId,
        feedbackBody: FeedbackBody(
          (builder) => builder
            ..feedbackType = type
            ..outcome = outcome
            ..note = note,
        ),
      );

      return _isSessionCurrent(epoch);
    } catch (e) {
      if (_isSessionCurrent(epoch)) {
        errorMessage = _friendlyError(e);
        notifyListeners();
      }

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // COMPATIBILITY
  // ---------------------------------------------------------------------------

  /// Dipertahankan supaya caller lama tidak langsung break.
  ///
  /// Dashboard versi baru membaca [summary] secara reactive.
  Future<AnalysesSummary?> getSummary() async {
    await loadSummary();

    return summary;
  }

  // ---------------------------------------------------------------------------
  // LOCAL CACHE
  // ---------------------------------------------------------------------------

  bool _upsertHistory(
    Analysis analysis, {
    bool countAsNew = false,
  }) {
    final index = history.indexWhere(
      (item) => item.id == analysis.id,
    );

    if (index >= 0) {
      history[index] = analysis;

      history.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return false;
    }

    history = [
      analysis,
      ...history,
    ];

    history.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    if (countAsNew) {
      historyTotal += 1;
    } else if (historyTotal < history.length) {
      historyTotal = history.length;
    }

    return true;
  }

  List<Analysis> _mergeUnique(
    List<Analysis> existing,
    List<Analysis> incoming,
  ) {
    final byId = <int, Analysis>{};

    for (final item in existing) {
      byId[item.id] = item;
    }

    // Incoming menang supaya data dari server terbaru menggantikan cache.
    for (final item in incoming) {
      byId[item.id] = item;
    }

    final merged = byId.values.toList();

    merged.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return merged;
  }

  void _optimisticallyIncrementSummary(
    Analysis created,
  ) {
    final current = summary;

    if (current == null) {
      return;
    }

    final isBeginner =
        created.mode == AnalysisModeEnum.beginner;

    summary = current.rebuild(
      (builder) => builder
        ..totalAnalyses = current.totalAnalyses + 1
        ..beginnerCount =
            current.beginnerCount + (isBeginner ? 1 : 0)
        ..proCount =
            current.proCount + (isBeginner ? 0 : 1),
    );
  }

  // ---------------------------------------------------------------------------
  // TIMEOUT RECOVERY
  // ---------------------------------------------------------------------------

  void _scheduleTimeoutRevalidation({
    required int epoch,
    required int? userId,
  }) {
    const delays = [
      Duration(seconds: 3),
      Duration(seconds: 8),
      Duration(seconds: 15),
      Duration(seconds: 30),
    ];

    for (final delay in delays) {
      unawaited(
        Future<void>.delayed(
          delay,
          () async {
            if (!_isSessionCurrent(epoch)) {
              return;
            }

            if (_activeUserId != userId) {
              return;
            }

            await refreshCoreData(
              silent: true,
            );
          },
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------

  String _friendlyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;

      if (data is Map) {
        final message =
            data['error'] ?? data['message'];

        if (message is String &&
            message.isNotEmpty) {
          return message;
        }
      }

      if (e.response?.statusCode == 401) {
        return 'Sesi login sudah berakhir. Silakan login kembali.';
      }

      if (e.response?.statusCode == 429) {
        return 'Batas kuota analisis tercapai. Coba lagi nanti.';
      }

      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'AI butuh waktu lebih lama dari biasanya untuk '
            'menganalisis. Silakan coba lagi.';
      }

      if (e.type == DioExceptionType.connectionError) {
        return 'Tidak bisa terhubung ke server. '
            'Periksa koneksi internet kamu.';
      }
    }

    return 'Analisis gagal. Silakan coba lagi.';
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _authProvider.removeListener(
      _handleAuthStateChanged,
    );

    super.dispose();
  }
}