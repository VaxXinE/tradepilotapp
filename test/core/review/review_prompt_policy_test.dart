import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/review/review_prompt_policy.dart';

void main() {
  final now = DateTime.utc(2026, 10, 10, 12);

  test('asks the first time after three analyses', () {
    expect(
      ReviewPromptPolicy.shouldRequest(
        const ReviewPromptState(analysisCount: 2),
        now,
      ),
      isFalse,
    );
    expect(
      ReviewPromptPolicy.shouldRequest(
        const ReviewPromptState(analysisCount: 3),
        now,
      ),
      isTrue,
    );
  });

  ReviewPromptState afterOneRequest({
    required int analyses,
    required int daysAgo,
    int requests = 1,
  }) => ReviewPromptState(
    analysisCount: analyses,
    requestCount: requests,
    lastRequestedAt: now.subtract(Duration(days: daysAgo)),
    analysisCountAtLastRequest: 3,
  );

  test('asks again only after both a long gap and enough new analyses', () {
    // Enough analyses, too soon.
    expect(
      ReviewPromptPolicy.shouldRequest(
        afterOneRequest(analyses: 40, daysAgo: 59),
        now,
      ),
      isFalse,
    );
    // Long enough ago, too few new analyses.
    expect(
      ReviewPromptPolicy.shouldRequest(
        afterOneRequest(analyses: 12, daysAgo: 200),
        now,
      ),
      isFalse,
    );
    expect(
      ReviewPromptPolicy.shouldRequest(
        afterOneRequest(analyses: 13, daysAgo: 60),
        now,
      ),
      isTrue,
    );
  });

  test('stops at the lifetime cap', () {
    expect(
      ReviewPromptPolicy.shouldRequest(
        afterOneRequest(
          analyses: 500,
          daysAgo: 900,
          requests: ReviewPromptPolicy.maxRequests,
        ),
        now,
      ),
      isFalse,
    );
  });
}
