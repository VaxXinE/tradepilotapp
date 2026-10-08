/// What the app remembers to decide when it may ask for a store review.
class ReviewPromptState {
  const ReviewPromptState({
    this.analysisCount = 0,
    this.requestCount = 0,
    this.lastRequestedAt,
    this.analysisCountAtLastRequest = 0,
  });

  /// Analyses the user has created since the app started counting.
  final int analysisCount;

  /// Times the store review sheet was requested.
  final int requestCount;
  final DateTime? lastRequestedAt;

  /// [analysisCount] when the sheet was last requested.
  final int analysisCountAtLastRequest;
}

/// When the app may ask for a store review.
///
/// Neither store tells an app whether the user left a review, or even whether
/// the sheet was shown, so the app cannot tell reviewers from non-reviewers.
/// Both stores also limit the sheet themselves (iOS shows it at most three times
/// a year; Google Play applies its own quota and silently shows nothing once it
/// is used up). Custom review dialogs are not allowed on iOS.
///
/// So the policy asks after a few analyses, and only rarely again: a long gap
/// in days and in analyses, and a small lifetime cap. Set [maxRequests] to 1 to
/// ask exactly once.
class ReviewPromptPolicy {
  const ReviewPromptPolicy._();

  /// Analyses needed before the first request.
  static const minAnalyses = 3;

  /// Further analyses needed before asking again.
  static const minAnalysesBetweenRequests = 10;

  /// Days between two requests.
  static const minDaysBetweenRequests = 60;

  /// Requests over the lifetime of the install.
  static const maxRequests = 3;

  static bool shouldRequest(ReviewPromptState state, DateTime now) {
    if (state.requestCount >= maxRequests) return false;

    if (state.requestCount == 0) {
      return state.analysisCount >= minAnalyses;
    }

    final last = state.lastRequestedAt;
    if (last == null ||
        now.difference(last) < const Duration(days: minDaysBetweenRequests)) {
      return false;
    }
    return state.analysisCount - state.analysisCountAtLastRequest >=
        minAnalysesBetweenRequests;
  }
}
