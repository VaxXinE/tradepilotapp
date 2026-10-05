import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../core/topup/topup_return_link.dart';

/// Listens for the link the web top-up page opens once the payment is over
/// (`id.tradepilot.app://topup/result?...`) and reports it to [onReturn].
///
/// Links that are not top-up returns are ignored, so this can coexist with the
/// OAuth callback that uses the same scheme.
class TopupReturnService {
  TopupReturnService({
    required this.onReturn,
    Stream<Uri>? linkStream,
    Future<Uri?> Function()? initialLink,
  }) : _linkStream = linkStream,
       _initialLink = initialLink;

  final void Function(TopupReturnLink link) onReturn;
  final Stream<Uri>? _linkStream;
  final Future<Uri?> Function()? _initialLink;
  StreamSubscription<Uri>? _subscription;

  Future<void> start() async {
    if (_subscription != null) return;
    try {
      final appLinks = _linkStream == null || _initialLink == null
          ? AppLinks()
          : null;
      _subscription = (_linkStream ?? appLinks!.uriLinkStream).listen(
        _handle,
        onError: (Object error) =>
            debugPrint('Top-up return link error: $error'),
      );
      final initial = await (_initialLink ?? appLinks!.getInitialLink)();
      if (initial != null) _handle(initial);
    } catch (error) {
      // Deep links are a convenience; the app works without them.
      debugPrint('Top-up return link unavailable: $error');
    }
  }

  void _handle(Uri uri) {
    final link = TopupReturnLink.tryParse(uri);
    if (link != null) onReturn(link);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
