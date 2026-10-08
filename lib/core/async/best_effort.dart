import 'dart:async';

/// Runs [action] but never lets it block or break the caller: errors are
/// swallowed and the wait is capped at [timeout]. For cleanup that should be
/// attempted before an operation that must happen regardless, such as signing
/// out. If [action] outlives [timeout] it keeps running in the background.
Future<void> runBestEffort(
  Future<void> Function() action, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    await action().timeout(timeout);
  } catch (_) {
    // Intentionally ignored; see the doc comment.
  }
}
