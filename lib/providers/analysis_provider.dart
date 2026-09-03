import 'dart:async';
import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

import '../models/history_filters.dart';
import '../models/history_sort.dart';
import 'auth_provider.dart';

/// Single source of truth untuk seluruh state analisis.
///
/// Tanggung jawab:
/// - create analysis
/// - unfiltered history
/// - filtered history
/// - server-side search
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

    if (_activeUserId case final userId?) {
      unawaited(_restoreHistoryPreferences(userId, _sessionEpoch));
    }
  }

  final AuthProvider _authProvider;

  TradePilotClient get _client => _authProvider.client;

  // ===========================================================================
  // PUBLIC STATE — CORE
  // ===========================================================================

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

  // ===========================================================================
  // PUBLIC STATE — FILTERED HISTORY
  // ===========================================================================

  /// Filter aktif yang sedang digunakan oleh halaman History.
  ///
  /// State ini sengaja dipisah dari [history] karena [history]
  /// merupakan source of truth Dashboard/realtime state.
  HistoryFilters historyFilters = const HistoryFilters();

  /// Hasil query server-side ketika filter/search aktif.
  List<Analysis> filteredHistory = [];

  int filteredHistoryTotal = 0;

  int filteredHistoryPage = 1;

  bool isLoadingFilteredHistory = false;

  bool isLoadingMoreFilteredHistory = false;

  String? filteredHistoryError;

  // ===========================================================================
  // VISIBLE HISTORY HELPERS
  // ===========================================================================

  bool get hasActiveHistoryFilters {
    return historyFilters.isActive;
  }

  List<Analysis> get visibleHistory {
    // The generated API has no outcome/confidence/sort parameters yet.
    // Refine a copy of the loaded page so Dashboard's base history stays intact.
    final result = List<Analysis>.of(
      historyFilters.hasServerFilters ? filteredHistory : history,
    );

    result.removeWhere((analysis) => !_matchesClientFilters(analysis));
    result.sort(_compareVisibleHistory);

    return result;
  }

  int get visibleHistoryTotal {
    if (historyFilters.outcome != HistoryOutcomeFilter.all ||
        historyFilters.minConfidence != null) {
      return visibleHistory.length;
    }

    return visibleHistorySourceTotal;
  }

  int get visibleHistorySourceTotal {
    return historyFilters.hasServerFilters
        ? filteredHistoryTotal
        : historyTotal;
  }

  bool get hasClientHistoryRefinement {
    return historyFilters.outcome != HistoryOutcomeFilter.all ||
        historyFilters.minConfidence != null;
  }

  bool get isLoadingVisibleHistory {
    return historyFilters.hasServerFilters
        ? isLoadingFilteredHistory
        : isLoadingHistory;
  }

  bool get isLoadingMoreVisibleHistory {
    return historyFilters.hasServerFilters
        ? isLoadingMoreFilteredHistory
        : isLoadingMoreHistory;
  }

  String? get visibleHistoryError {
    return historyFilters.hasServerFilters
        ? filteredHistoryError
        : errorMessage;
  }

  // ===========================================================================
  // INTERNAL STATE — AUTH / SESSION
  // ===========================================================================

  int? _activeUserId;

  int _sessionEpoch = 0;

  // ===========================================================================
  // INTERNAL STATE — CORE REQUESTS
  // ===========================================================================

  bool _historyRequestInFlight = false;

  bool _summaryRequestInFlight = false;

  bool _quotaRequestInFlight = false;

  int _historyRequestId = 0;

  int _summaryRequestId = 0;

  int _quotaRequestId = 0;

  int _createRequestId = 0;

  final Set<int> _savingNoteIds = <int>{};

  bool isSavingNote(int analysisId) => _savingNoteIds.contains(analysisId);

  // ===========================================================================
  // INTERNAL STATE — FILTERED HISTORY
  // ===========================================================================

  bool _filteredHistoryRequestInFlight = false;

  int _filteredHistoryRequestId = 0;

  /// Berubah setiap kali kombinasi filter berubah.
  ///
  /// Response dari filter lama tidak boleh masuk ke filter baru.
  int _historyFilterGeneration = 0;

  CancelToken? _filteredHistoryCancelToken;

  // ===========================================================================
  // AUTH / CACHE ISOLATION
  // ===========================================================================

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

    // -----------------------------------------------------------------------
    // Invalidasi semua request dari account/session lama.
    // -----------------------------------------------------------------------

    _historyRequestId++;

    _summaryRequestId++;

    _quotaRequestId++;

    _createRequestId++;

    _savingNoteIds.clear();

    _filteredHistoryRequestId++;

    _historyFilterGeneration++;

    // Cancel network request filter yang masih berjalan.
    _filteredHistoryCancelToken?.cancel('Authentication session changed.');

    _filteredHistoryCancelToken = null;

    _historyRequestInFlight = false;

    _summaryRequestInFlight = false;

    _quotaRequestInFlight = false;

    _filteredHistoryRequestInFlight = false;

    _resetCachedData();

    notifyListeners();

    if (nextUserId != null) {
      unawaited(_restoreHistoryPreferences(nextUserId, _sessionEpoch));
    }
  }

  void _resetCachedData() {
    isSubmitting = false;

    // -----------------------------------------------------------------------
    // Core history
    // -----------------------------------------------------------------------

    isLoadingHistory = false;

    isLoadingMoreHistory = false;

    history = [];

    historyTotal = 0;

    historyPage = 1;

    // -----------------------------------------------------------------------
    // Filtered history
    // -----------------------------------------------------------------------

    historyFilters = const HistoryFilters();

    filteredHistory = [];

    filteredHistoryTotal = 0;

    filteredHistoryPage = 1;

    isLoadingFilteredHistory = false;

    isLoadingMoreFilteredHistory = false;

    filteredHistoryError = null;

    // -----------------------------------------------------------------------
    // Dashboard state
    // -----------------------------------------------------------------------

    isLoadingSummary = false;

    summary = null;

    quota = null;

    errorMessage = null;
  }

  // ===========================================================================
  // QUOTA
  // ===========================================================================

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

      if (!_isSessionCurrent(epoch) || requestId != _quotaRequestId) {
        return;
      }

      quota = response.data;
    } catch (_) {
      // Quota bukan critical state.
      //
      // Kalau background refresh gagal,
      // pertahankan cache terakhir.
    } finally {
      if (requestId == _quotaRequestId) {
        _quotaRequestInFlight = false;

        if (_isSessionCurrent(epoch)) {
          notifyListeners();
        }
      }
    }
  }

  // ===========================================================================
  // SUMMARY
  // ===========================================================================

  Future<void> loadSummary({bool silent = false}) async {
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

      if (!_isSessionCurrent(epoch) || requestId != _summaryRequestId) {
        return;
      }

      summary = response.data;
    } catch (error) {
      if (_isSessionCurrent(epoch) && !silent) {
        errorMessage = _friendlyError(error);
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

  // ===========================================================================
  // CORE REFRESH
  // ===========================================================================

  /// Refresh data yang digunakan Dashboard.
  ///
  /// silent = true:
  /// - data lama tetap tampil
  /// - tidak muncul loading screen
  /// - cocok untuk background sync
  ///
  /// silent = false:
  /// - cocok untuk initial load / pull-to-refresh
  Future<void> refreshCoreData({bool silent = true}) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    await Future.wait([
      loadHistory(refresh: true, silent: silent),
      loadSummary(silent: silent),
      loadQuota(),
    ]);
  }

  // ===========================================================================
  // CREATE ANALYSIS
  // ===========================================================================

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

    // Defense-in-depth:
    // mencegah double submit dari UI.
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

      if (!_isSessionCurrent(epoch) || requestId != _createRequestId) {
        return null;
      }

      final created = response.data;

      isSubmitting = false;

      if (created != null) {
        final inserted = _upsertHistory(created, countAsNew: true);

        if (inserted) {
          _optimisticallyIncrementSummary(created);
        }
      }

      notifyListeners();

      // ---------------------------------------------------------------------
      // POST sudah memberikan Analysis lengkap.
      //
      // UI tidak perlu menunggu GET tambahan.
      // Revalidate server state di background.
      // ---------------------------------------------------------------------

      unawaited(loadHistory(refresh: true, silent: true));

      unawaited(loadSummary(silent: true));

      unawaited(loadQuota());

      return created;
    } catch (error) {
      if (!_isSessionCurrent(epoch) || requestId != _createRequestId) {
        return null;
      }

      isSubmitting = false;

      final isTimeout =
          error is DioException &&
          (error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.connectionTimeout);

      if (isTimeout) {
        errorMessage =
            'Koneksi ke AI lama meresponsnya. Analisis mungkin tetap '
            'berhasil dibuat — data akan disinkronkan otomatis.';

        _scheduleTimeoutRevalidation(epoch: epoch, userId: _activeUserId);
      } else {
        errorMessage = _friendlyError(error);
      }

      notifyListeners();

      return null;
    }
  }

  // ===========================================================================
  // BASE / UNFILTERED HISTORY
  // ===========================================================================

  Future<void> loadHistory({bool refresh = false, bool silent = false}) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    final requestedPage = refresh ? 1 : historyPage;

    await _loadHistoryPage(
      requestedPage,
      silent: silent,

      // Background refresh page pertama
      // tidak boleh membuang page 2, 3, dst
      // yang sebelumnya sudah di-load.
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

    // Prevent race-condition dari:
    //
    // - scroll pagination
    // - polling
    // - pull-to-refresh
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

      if (!_isSessionCurrent(epoch) || requestId != _historyRequestId) {
        return;
      }

      final data = response.data;

      if (data == null) {
        return;
      }

      final incoming = data.analyses.toList();

      if (page == 1) {
        if (preserveExistingPages && history.isNotEmpty) {
          history = _mergeUnique(history, incoming);
        } else {
          history = incoming;

          historyPage = 1;
        }
      } else {
        history = _mergeUnique(history, incoming);

        historyPage = page;
      }

      historyTotal = data.total;
    } catch (error) {
      if (_isSessionCurrent(epoch) && !silent) {
        errorMessage = _friendlyError(error);
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

    await _loadHistoryPage(historyPage + 1, silent: false);
  }

  // ===========================================================================
  // FILTERED HISTORY
  // ===========================================================================

  /// Terapkan kombinasi search/filter baru.
  ///
  /// Request filter lama dibatalkan agar hasil dari query lama
  /// tidak bisa menimpa query yang lebih baru.
  Future<void> applyHistoryFilters(HistoryFilters filters) async {
    final epoch = _sessionEpoch;
    final userId = _activeUserId;
    final normalized = filters.normalized();
    final serverFiltersChanged = !historyFilters.hasSameServerFilters(
      normalized,
    );

    final from = normalized.from;

    final to = normalized.to;

    if (from != null && to != null && from.isAfter(to)) {
      filteredHistoryError = 'Tanggal awal tidak boleh melewati tanggal akhir.';

      notifyListeners();

      return;
    }

    historyFilters = normalized;

    await _persistHistoryPreferences(normalized);

    if (epoch != _sessionEpoch || userId != _activeUserId) {
      return;
    }

    if (!serverFiltersChanged) {
      filteredHistoryError = null;
      notifyListeners();
      return;
    }

    // -----------------------------------------------------------------------
    // Bump generation sebelum cancel request lama.
    // -----------------------------------------------------------------------

    _historyFilterGeneration++;

    _filteredHistoryRequestId++;

    _filteredHistoryCancelToken?.cancel('History filters changed.');

    _filteredHistoryCancelToken = null;

    _filteredHistoryRequestInFlight = false;

    isLoadingFilteredHistory = false;

    isLoadingMoreFilteredHistory = false;

    filteredHistoryError = null;

    // -----------------------------------------------------------------------
    // Tidak ada filter:
    //
    // kembali ke base/unfiltered history.
    // -----------------------------------------------------------------------

    if (!normalized.hasServerFilters) {
      filteredHistory = [];

      filteredHistoryTotal = 0;

      filteredHistoryPage = 1;

      notifyListeners();

      await loadHistory(refresh: true, silent: true);

      return;
    }

    notifyListeners();

    await _loadFilteredHistoryPage(
      1,
      silent: false,
      preserveExistingPages: false,
      supersede: true,
    );
  }

  /// Refresh list yang sedang terlihat user.
  ///
  /// Kalau filter aktif → refresh filtered query.
  /// Kalau filter tidak aktif → refresh base history.
  Future<void> refreshVisibleHistory({bool silent = true}) async {
    if (!historyFilters.hasServerFilters) {
      await loadHistory(refresh: true, silent: silent);

      return;
    }

    await _loadFilteredHistoryPage(
      1,
      silent: silent,

      // Background refresh jangan membuang
      // hasil page 2, 3, dst.
      preserveExistingPages: silent,

      supersede: true,
    );
  }

  /// Pagination untuk history yang sedang terlihat.
  Future<void> loadMoreVisibleHistory() async {
    if (!historyFilters.hasServerFilters) {
      await loadMoreHistory();

      return;
    }

    if (_filteredHistoryRequestInFlight || isLoadingMoreFilteredHistory) {
      return;
    }

    if (filteredHistoryTotal == 0) {
      return;
    }

    if (filteredHistory.length >= filteredHistoryTotal) {
      return;
    }

    await _loadFilteredHistoryPage(
      filteredHistoryPage + 1,
      silent: false,
      preserveExistingPages: true,
    );
  }

  Future<void> _loadFilteredHistoryPage(
    int page, {
    required bool silent,
    required bool preserveExistingPages,
    bool supersede = false,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return;
    }

    // -----------------------------------------------------------------------
    // Kalau request lama masih berjalan dan request baru lebih penting
    // (search/filter berubah atau refresh), cancel request lama.
    // -----------------------------------------------------------------------

    if (_filteredHistoryRequestInFlight) {
      if (!supersede) {
        return;
      }

      _filteredHistoryCancelToken?.cancel(
        'Superseded by newer history request.',
      );

      _filteredHistoryRequestInFlight = false;
    }

    final epoch = _sessionEpoch;

    final generation = _historyFilterGeneration;

    final requestId = ++_filteredHistoryRequestId;

    // Snapshot filter saat request dibuat.
    final filters = historyFilters;

    final isLoadMore = page > 1;

    final cancelToken = CancelToken();

    _filteredHistoryCancelToken = cancelToken;

    _filteredHistoryRequestInFlight = true;

    if (!silent) {
      if (isLoadMore) {
        isLoadingMoreFilteredHistory = true;
      } else {
        isLoadingFilteredHistory = true;
      }

      notifyListeners();
    }

    try {
      final response = await _client.analyses.listAnalyses(
        mode: filters.apiMode,

        instruments: filters.instruments.isEmpty
            ? null
            : BuiltList<String>(filters.instruments),

        timeframes: filters.timeframes.isEmpty
            ? null
            : BuiltList<String>(filters.timeframes),

        q: filters.query.isEmpty ? null : filters.query,

        from: _toApiDate(filters.from),

        to: _toApiDate(filters.to),

        page: page,

        limit: _pageSize,

        cancelToken: cancelToken,
      );

      // ---------------------------------------------------------------------
      // Jangan menerima:
      //
      // - response account lama
      // - response filter lama
      // - response request lama
      // ---------------------------------------------------------------------

      if (!_isSessionCurrent(epoch) ||
          generation != _historyFilterGeneration ||
          requestId != _filteredHistoryRequestId) {
        return;
      }

      final data = response.data;

      if (data == null) {
        return;
      }

      final incoming = data.analyses.toList();

      if (page == 1) {
        if (preserveExistingPages && filteredHistory.isNotEmpty) {
          filteredHistory = _mergeUnique(filteredHistory, incoming);
        } else {
          filteredHistory = incoming;

          filteredHistoryPage = 1;
        }
      } else {
        filteredHistory = _mergeUnique(filteredHistory, incoming);

        filteredHistoryPage = page;
      }

      filteredHistoryTotal = data.total;

      filteredHistoryError = null;
    } catch (error) {
      // Request sengaja dibatalkan karena:
      //
      // - user mengetik search baru
      // - filter berubah
      // - account/session berubah
      if (error is DioException && error.type == DioExceptionType.cancel) {
        return;
      }

      if (_isSessionCurrent(epoch) &&
          generation == _historyFilterGeneration &&
          requestId == _filteredHistoryRequestId &&
          !silent) {
        filteredHistoryError = _friendlyError(error);
      }
    } finally {
      if (requestId == _filteredHistoryRequestId) {
        _filteredHistoryRequestInFlight = false;

        _filteredHistoryCancelToken = null;

        if (_isSessionCurrent(epoch) &&
            generation == _historyFilterGeneration) {
          if (!silent) {
            if (isLoadMore) {
              isLoadingMoreFilteredHistory = false;
            } else {
              isLoadingFilteredHistory = false;
            }
          }

          notifyListeners();
        }
      }
    }
  }

  Date? _toApiDate(DateTime? date) {
    if (date == null) {
      return null;
    }

    return Date(date.year, date.month, date.day);
  }

  bool _matchesClientFilters(Analysis analysis) {
    switch (historyFilters.outcome) {
      case HistoryOutcomeFilter.success:
        if (analysis.outcomeStatus != AnalysisOutcomeStatusEnum.tp1Hit &&
            analysis.outcomeStatus != AnalysisOutcomeStatusEnum.tp2Hit) {
          return false;
        }
        break;
      case HistoryOutcomeFilter.failed:
        if (analysis.outcomeStatus != AnalysisOutcomeStatusEnum.slHit &&
            analysis.outcomeStatus != AnalysisOutcomeStatusEnum.expired &&
            analysis.outcomeStatus != AnalysisOutcomeStatusEnum.invalidated) {
          return false;
        }
        break;
      case HistoryOutcomeFilter.pending:
        if (analysis.outcomeStatus != null &&
            analysis.outcomeStatus != AnalysisOutcomeStatusEnum.pending) {
          return false;
        }
        break;
      case HistoryOutcomeFilter.all:
        break;
    }

    final minimum = historyFilters.minConfidence;
    if (minimum != null && _averageConfidence(analysis) < minimum) {
      return false;
    }

    return true;
  }

  int _compareVisibleHistory(Analysis left, Analysis right) {
    int result;

    switch (historyFilters.sort) {
      case HistorySort.newest:
        result = right.createdAt.compareTo(left.createdAt);
        break;
      case HistorySort.oldest:
        result = left.createdAt.compareTo(right.createdAt);
        break;
      case HistorySort.confidenceHighest:
        result = _averageConfidence(right).compareTo(_averageConfidence(left));
        break;
    }

    if (result != 0) {
      return result;
    }

    return right.id.compareTo(left.id);
  }

  double _averageConfidence(Analysis analysis) {
    final minimum = analysis.confidenceMin;
    final maximum = analysis.confidenceMax;

    if (minimum != null && maximum != null) {
      return (minimum + maximum) / 2;
    }

    return (minimum ?? maximum ?? -1).toDouble();
  }

  String _historyPreferencesKey(int userId) {
    return 'history_preferences_v1_$userId';
  }

  Future<void> _persistHistoryPreferences(HistoryFilters filters) async {
    final userId = _currentAuthenticatedUserId;
    if (userId == null) {
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _historyPreferencesKey(userId),
        jsonEncode(filters.toPreferencesJson()),
      );
    } catch (_) {
      // Preference storage is non-critical; filtering must keep working.
    }
  }

  Future<void> _restoreHistoryPreferences(int userId, int epoch) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_historyPreferencesKey(userId));

      if (encoded == null || !_isSessionCurrent(epoch)) {
        return;
      }

      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return;
      }

      final restored = HistoryFilters.fromPreferencesJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );

      if (!_isSessionCurrent(epoch) || _activeUserId != userId) {
        return;
      }

      await applyHistoryFilters(restored);
    } catch (_) {
      // Corrupted/legacy preferences fall back to the already-reset defaults.
    }
  }

  // ===========================================================================
  // DETAIL
  // ===========================================================================

  Future<Analysis?> getAnalysis(int id, {bool silent = false}) async {
    if (_authProvider.status != AuthStatus.authenticated) {
      return null;
    }

    final epoch = _sessionEpoch;

    try {
      final response = await _client.analyses.getAnalysis(id: id);

      if (!_isSessionCurrent(epoch)) {
        return null;
      }

      final analysis = response.data;

      if (analysis != null) {
        // Update object yang sama pada:
        //
        // - Dashboard
        // - unfiltered History
        // - filtered History
        //
        // melalui satu cache operation.
        _upsertHistory(analysis);

        notifyListeners();
      }

      return analysis;
    } catch (error) {
      if (_isSessionCurrent(epoch) && !silent) {
        errorMessage = _friendlyError(error);

        notifyListeners();
      }

      return null;
    }
  }

  Future<Analysis?> saveAnalysisNote({
    required Analysis analysis,
    required String note,
  }) async {
    if (_authProvider.status != AuthStatus.authenticated ||
        _savingNoteIds.contains(analysis.id) ||
        note.length > 5000) {
      if (note.length > 5000) {
        errorMessage = 'Catatan maksimal 5.000 karakter.';
        notifyListeners();
      }
      return null;
    }

    final epoch = _sessionEpoch;
    final userId = _activeUserId;
    _savingNoteIds.add(analysis.id);
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.analyses.setAnalysisNote(
        id: analysis.id,
        setAnalysisNoteRequest: SetAnalysisNoteRequest(
          (builder) => builder.note = note,
        ),
      );
      final saved = response.data;
      if (!_isSessionCurrent(epoch) ||
          userId != _activeUserId ||
          saved == null) {
        return null;
      }

      final normalized = saved.note.trim();
      final updated = analysis.rebuild(
        (builder) => builder
          ..userNote = normalized.isEmpty ? null : saved.note
          ..userNoteUpdatedAt = normalized.isEmpty ? null : saved.updatedAt
          ..hasNote = normalized.isNotEmpty,
      );
      _upsertHistory(updated);
      return updated;
    } catch (error) {
      if (_isSessionCurrent(epoch) && userId == _activeUserId) {
        errorMessage = _friendlyNoteError(error);
      }
      return null;
    } finally {
      if (_isSessionCurrent(epoch) && userId == _activeUserId) {
        _savingNoteIds.remove(analysis.id);
        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // FUNDAMENTAL SNAPSHOT
  // ===========================================================================

  Future<RefreshFundamentalsResponse?> refreshFundamentals(
    int analysisId,
  ) async {
    if (_authProvider.status != AuthStatus.authenticated) return null;

    final epoch = _sessionEpoch;
    try {
      final response = await _client.analyses.refreshFundamentals(
        id: analysisId,
      );
      return _isSessionCurrent(epoch) ? response.data : null;
    } catch (error) {
      if (_isSessionCurrent(epoch)) {
        errorMessage = _friendlyError(error);
        notifyListeners();
      }
      return null;
    }
  }

  // ===========================================================================
  // FEEDBACK
  // ===========================================================================

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
    } catch (error) {
      if (_isSessionCurrent(epoch)) {
        errorMessage = _friendlyError(error);

        notifyListeners();
      }

      return false;
    }
  }

  // ===========================================================================
  // COMPATIBILITY
  // ===========================================================================

  /// Dipertahankan supaya caller lama tidak langsung break.
  ///
  /// Dashboard versi baru membaca [summary] secara reactive.
  Future<AnalysesSummary?> getSummary() async {
    await loadSummary();

    return summary;
  }

  // ===========================================================================
  // LOCAL CACHE
  // ===========================================================================

  /// Insert/update analysis pada cache utama.
  ///
  /// Filtered cache tidak boleh mendapat analysis baru secara otomatis,
  /// karena kita belum tahu apakah analysis baru tersebut memenuhi query
  /// filter server-side.
  ///
  /// Tetapi jika analysis tersebut SUDAH berada di filtered list,
  /// object-nya harus diperbarui supaya outcome/detail tetap realtime.
  bool _upsertHistory(Analysis analysis, {bool countAsNew = false}) {
    // -----------------------------------------------------------------------
    // P2-A.6:
    //
    // Sinkronkan object yang sudah berada di filtered result.
    // -----------------------------------------------------------------------

    _replaceFilteredHistoryItem(analysis);

    final index = history.indexWhere((item) => item.id == analysis.id);

    if (index >= 0) {
      history[index] = analysis;

      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return false;
    }

    history = [analysis, ...history];

    history.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (countAsNew) {
      historyTotal += 1;
    } else if (historyTotal < history.length) {
      historyTotal = history.length;
    }

    return true;
  }

  /// Update analysis dalam filtered result TANPA memasukkan analysis baru.
  ///
  /// Kenapa?
  ///
  /// Misalnya filter aktif:
  ///
  /// q = "FOMC"
  ///
  /// lalu user membuat analysis XAU/USD baru.
  ///
  /// Kita tidak boleh asal memasukkan analysis baru ke filteredHistory,
  /// karena hanya backend yang tahu apakah narrative analysis tersebut
  /// benar-benar match query "FOMC".
  ///
  /// Sebaliknya, jika analysis sudah ada di filtered list lalu outcome
  /// berubah menjadi TP1/SL, object tersebut aman untuk kita replace.
  void _replaceFilteredHistoryItem(Analysis analysis) {
    final index = filteredHistory.indexWhere((item) => item.id == analysis.id);

    if (index < 0) {
      return;
    }

    filteredHistory[index] = analysis;

    filteredHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Analysis> _mergeUnique(
    List<Analysis> existing,
    List<Analysis> incoming,
  ) {
    final byId = <int, Analysis>{};

    for (final item in existing) {
      byId[item.id] = item;
    }

    // Incoming menang supaya data server terbaru
    // menggantikan cache lama.
    for (final item in incoming) {
      byId[item.id] = item;
    }

    final merged = byId.values.toList();

    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  void _optimisticallyIncrementSummary(Analysis created) {
    final current = summary;

    if (current == null) {
      return;
    }

    final isBeginner = created.mode == AnalysisModeEnum.beginner;

    summary = current.rebuild(
      (builder) => builder
        ..totalAnalyses = current.totalAnalyses + 1
        ..beginnerCount = current.beginnerCount + (isBeginner ? 1 : 0)
        ..proCount = current.proCount + (isBeginner ? 0 : 1),
    );
  }

  // ===========================================================================
  // TIMEOUT RECOVERY
  // ===========================================================================

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
        Future<void>.delayed(delay, () async {
          if (!_isSessionCurrent(epoch)) {
            return;
          }

          if (_activeUserId != userId) {
            return;
          }

          await refreshCoreData(silent: true);
        }),
      );
    }
  }

  // ===========================================================================
  // ERROR HANDLING
  // ===========================================================================

  String _friendlyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map) {
        final message = data['error'] ?? data['message'];

        if (message is String && message.isNotEmpty) {
          return message;
        }
      }

      if (error.response?.statusCode == 401) {
        return 'Sesi login sudah berakhir. Silakan login kembali.';
      }

      if (error.response?.statusCode == 429) {
        return 'Batas kuota analisis tercapai. Coba lagi nanti.';
      }

      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'AI butuh waktu lebih lama dari biasanya untuk '
            'menganalisis. Silakan coba lagi.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Tidak bisa terhubung ke server. '
            'Periksa koneksi internet kamu.';
      }

      if (error.type == DioExceptionType.cancel) {
        return 'Permintaan dibatalkan.';
      }
    }

    return 'Analisis gagal. Silakan coba lagi.';
  }

  String _friendlyNoteError(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Sesi login sudah berakhir. Silakan login kembali.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Catatan belum tersimpan. Periksa koneksi lalu coba lagi.';
      }
    }
    return 'Catatan belum dapat disimpan. Silakan coba lagi.';
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    // Cancel filtered request supaya tidak ada callback network
    // yang masih mencoba menyentuh provider setelah dispose.
    _filteredHistoryCancelToken?.cancel('AnalysisProvider disposed.');

    _filteredHistoryCancelToken = null;

    _authProvider.removeListener(_handleAuthStateChanged);

    super.dispose();
  }
}
