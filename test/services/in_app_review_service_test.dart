import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradepilotapp/core/review/review_prompt_policy.dart';
import 'package:tradepilotapp/services/in_app_review_service.dart';

class _FakePlatform implements ReviewPlatform {
  _FakePlatform({this.available = true, this.fails = false});

  bool available;
  bool fails;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requests++;
    if (fails) throw StateError('store failed');
  }
}

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 1, 9);
  });

  Future<InAppReviewService> service(_FakePlatform platform) async =>
      InAppReviewService(
        await SharedPreferences.getInstance(),
        platform: platform,
        clock: () => now,
      );

  Future<void> create(InAppReviewService reviews, int analyses) async {
    for (var i = 0; i < analyses; i++) {
      await reviews.recordAnalysisCreated();
    }
  }

  test('asks on the third analysis, not before', () async {
    final platform = _FakePlatform();
    final reviews = await service(platform);

    expect(await reviews.recordAnalysisCreated(), isFalse);
    expect(await reviews.recordAnalysisCreated(), isFalse);
    expect(platform.requests, 0);
    expect(await reviews.recordAnalysisCreated(), isTrue);
    expect(platform.requests, 1);
  });

  test('stays quiet right after a request, even over many analyses', () async {
    final platform = _FakePlatform();
    final reviews = await service(platform);
    await create(reviews, 3);

    await create(reviews, 30);
    expect(platform.requests, 1, reason: 'the day gap has not passed');
  });

  test('asks again after the gap, and survives a restart in between', () async {
    final platform = _FakePlatform();
    var reviews = await service(platform);
    await create(reviews, 3);
    expect(platform.requests, 1);

    now = now.add(const Duration(days: 61));
    // A new service over the same stored data, like an app restart.
    reviews = await service(platform);
    await create(reviews, 9);
    expect(
      platform.requests,
      1,
      reason: 'needs 10 analyses since the last ask',
    );
    expect(await reviews.recordAnalysisCreated(), isTrue);
    expect(platform.requests, 2);
  });

  test('never exceeds the lifetime cap', () async {
    final platform = _FakePlatform();
    final reviews = await service(platform);
    for (var round = 0; round < 8; round++) {
      now = now.add(const Duration(days: 90));
      await create(reviews, 12);
    }
    expect(platform.requests, ReviewPromptPolicy.maxRequests);
  });

  test('keeps the chance while the store sheet is unavailable', () async {
    final platform = _FakePlatform(available: false);
    final reviews = await service(platform);
    await create(reviews, 5);
    expect(reviews.state.requestCount, 0);

    platform.available = true;
    expect(await reviews.recordAnalysisCreated(), isTrue);
  });

  test('a store error is not retried straight away', () async {
    final platform = _FakePlatform(fails: true);
    final reviews = await service(platform);
    await create(reviews, 3);
    expect(platform.requests, 1);

    platform.fails = false;
    await create(reviews, 5);
    expect(platform.requests, 1, reason: 'recorded before the store was asked');
  });

  test('recordAnalysisCreatedSoon counts after the delay', () async {
    final reviews = await service(_FakePlatform());
    reviews.recordAnalysisCreatedSoon(delay: const Duration(milliseconds: 20));
    expect(reviews.state.analysisCount, 0);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(reviews.state.analysisCount, 1);
  });
}
