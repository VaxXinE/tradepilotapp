import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/core/async/best_effort.dart';

void main() {
  test('runs the action', () async {
    var ran = false;
    await runBestEffort(() async => ran = true);
    expect(ran, isTrue);
  });

  test('swallows an error from the action', () async {
    await runBestEffort(() async => throw StateError('boom'));
  });

  test('stops waiting for an action that never finishes', () async {
    final stopwatch = Stopwatch()..start();
    await runBestEffort(
      () => Completer<void>().future,
      timeout: const Duration(milliseconds: 50),
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
