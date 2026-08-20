import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

import 'auth_provider.dart';

/// State management untuk analisis AI: submit analisis baru, riwayat,
/// detail, kuota, dan feedback. Setara halaman analyze.tsx / history.tsx /
/// analysis-detail.tsx pada web app (artifacts/ai-trading).
class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider(this._authProvider);

  final AuthProvider _authProvider;
  TradePilotClient get _client => _authProvider.client;

  bool isSubmitting = false;
  bool isLoadingHistory = false;
  String? errorMessage;

  List<Analysis> history = [];
  int historyTotal = 0;
  int historyPage = 1;
  static const _pageSize = 20;

  AnalysisQuota? quota;

  Future<void> loadQuota() async {
    try {
      final response = await _client.analyses.getAnalysisQuota();
      quota = response.data;
      notifyListeners();
    } catch (_) {
      // quota bersifat non-kritis untuk ditampilkan; abaikan error diam-diam
    }
  }

  Future<Analysis?> createAnalysis({
    required String instrument,
    required CreateAnalysisBodyTimeframeEnum timeframe,
    required CreateAnalysisBodyModeEnum mode,
    String? userInputContext,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _client.analyses.createAnalysis(
        createAnalysisBody: CreateAnalysisBody((b) => b
          ..instrument = instrument
          ..timeframe = timeframe
          ..mode = mode
          ..userInputContext = userInputContext),
      );
      isSubmitting = false;
      notifyListeners();
      await loadQuota();
      return response.data;
    } catch (e) {
      isSubmitting = false;
      errorMessage = _friendlyError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh) {
      historyPage = 1;
      history = [];
    }
    isLoadingHistory = true;
    notifyListeners();
    try {
      final response = await _client.analyses.listAnalyses(
        page: historyPage,
        limit: _pageSize,
      );
      final data = response.data;
      if (data != null) {
        history = historyPage == 1 ? data.analyses.toList() : [...history, ...data.analyses];
        historyTotal = data.total;
      }
    } catch (e) {
      errorMessage = _friendlyError(e);
    }
    isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> loadMoreHistory() async {
    if (history.length >= historyTotal) return;
    historyPage += 1;
    await loadHistory();
  }

  Future<Analysis?> getAnalysis(int id) async {
    try {
      final response = await _client.analyses.getAnalysis(id: id);
      return response.data;
    } catch (e) {
      errorMessage = _friendlyError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> submitFeedback({
    required int analysisId,
    required FeedbackBodyFeedbackTypeEnum type,
    FeedbackBodyOutcomeEnum? outcome,
    String? note,
  }) async {
    try {
      await _client.analyses.submitFeedback(
        id: analysisId,
        feedbackBody: FeedbackBody((b) => b
          ..feedbackType = type
          ..outcome = outcome
          ..note = note),
      );
      return true;
    } catch (e) {
      errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<AnalysesSummary?> getSummary() async {
    try {
      final response = await _client.analyses.getAnalysesSummary();
      return response.data;
    } catch (_) {
      return null;
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.response?.statusCode == 429) {
        return 'Batas kuota analisis tercapai. Coba lagi nanti.';
      }
    }
    return 'Analisis gagal. Silakan coba lagi.';
  }
}
