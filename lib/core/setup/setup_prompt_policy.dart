/// What the app remembers to decide when to suggest turning on notifications
/// and the biometric lock.
class SetupPromptState {
  const SetupPromptState({this.askCount = 0, this.lastAskedAt});

  /// Times the setup sheet was shown.
  final int askCount;
  final DateTime? lastAskedAt;
}

/// When the app may suggest notifications and the biometric lock.
///
/// Not on first launch: the user is asked once they have used the app for a
/// while (a couple of analyses), when the settings are easy to see the point
/// of. A user who closes the sheet is asked again only rarely and never more
/// than [maxAsks] times, so it cannot turn into nagging.
class SetupPromptPolicy {
  const SetupPromptPolicy._();

  /// Analyses created before the first ask.
  static const minAnalyses = 2;

  /// Days between two asks.
  static const minDaysBetweenAsks = 7;

  /// Asks over the lifetime of the install.
  static const maxAsks = 2;

  static bool shouldAsk(
    SetupPromptState state,
    int analysisCount,
    DateTime now,
  ) {
    if (analysisCount < minAnalyses) return false;
    if (state.askCount >= maxAsks) return false;
    final last = state.lastAskedAt;
    if (last == null) return true;
    return now.difference(last) >= const Duration(days: minDaysBetweenAsks);
  }
}
