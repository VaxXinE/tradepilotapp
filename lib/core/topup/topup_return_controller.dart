import 'package:flutter/foundation.dart';

import 'topup_return_link.dart';

/// Hands the web top-up result from where it arrives (the in-app browser tab
/// opened from Profile) to the app shell, which shows it once the user is
/// signed in and unlocked.
class TopupReturnController extends ChangeNotifier {
  TopupReturnLink? _pending;

  TopupReturnLink? get pending => _pending;

  /// Records the URL the browser tab ended on. Anything that is not a top-up
  /// return link is ignored.
  void report(Uri uri) {
    final link = TopupReturnLink.tryParse(uri);
    if (link == null) return;
    _pending = link;
    notifyListeners();
  }

  /// Returns the pending link once and clears it.
  TopupReturnLink? take() {
    final link = _pending;
    _pending = null;
    return link;
  }
}
