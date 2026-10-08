import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/review/review_prompt_policy.dart';

/// The store's native review sheet (Google Play In-App Review on Android,
/// StoreKit on iOS).
abstract class ReviewPlatform {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class _StoreReviewPlatform implements ReviewPlatform {
  const _StoreReviewPlatform();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

/// Asks for a store review after a few analyses, and only rarely again.
///
/// The decision lives in [ReviewPromptPolicy]; this class stores what the
/// policy needs and calls the store. Each request is recorded before the sheet
/// is asked for, so a crash or a store error cannot lead to an extra ask.
class InAppReviewService {
  InAppReviewService(
    this._preferences, {
    ReviewPlatform? platform,
    DateTime Function()? clock,
  }) : _platform = platform ?? const _StoreReviewPlatform(),
       _clock = clock ?? DateTime.now;

  static const _analysisCountKey = 'review.analysis_count';
  static const _requestCountKey = 'review.request_count';
  static const _lastRequestKey = 'review.last_request_at';
  static const _countAtLastRequestKey = 'review.analysis_count_at_last_request';

  final SharedPreferences _preferences;
  final ReviewPlatform _platform;
  final DateTime Function() _clock;

  ReviewPromptState get state {
    final last = _preferences.getInt(_lastRequestKey);
    return ReviewPromptState(
      analysisCount: _preferences.getInt(_analysisCountKey) ?? 0,
      requestCount: _preferences.getInt(_requestCountKey) ?? 0,
      lastRequestedAt: last == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(last),
      analysisCountAtLastRequest:
          _preferences.getInt(_countAtLastRequestKey) ?? 0,
    );
  }

  /// Like [recordAnalysisCreated], a moment later, so the new result is on
  /// screen before the store sheet can cover it.
  void recordAnalysisCreatedSoon({
    Duration delay = const Duration(seconds: 3),
  }) {
    unawaited(Future<void>.delayed(delay, recordAnalysisCreated));
  }

  /// Counts a newly created analysis and asks for a review if it is time.
  /// Returns whether a request was made. Never throws.
  Future<bool> recordAnalysisCreated() async {
    try {
      final count = state.analysisCount + 1;
      await _preferences.setInt(_analysisCountKey, count);
      final now = _clock();
      if (!ReviewPromptPolicy.shouldRequest(state, now)) return false;
      // Without the store sheet (no Play services, an unsupported OS, an app
      // that was not installed from the store) nothing can show, so keep the
      // chance for later.
      if (!await _platform.isAvailable()) return false;

      await _preferences.setInt(_requestCountKey, state.requestCount + 1);
      await _preferences.setInt(_lastRequestKey, now.millisecondsSinceEpoch);
      await _preferences.setInt(_countAtLastRequestKey, count);
      await _platform.requestReview();
      return true;
    } catch (error) {
      debugPrint('In-app review skipped: $error');
      return false;
    }
  }
}
