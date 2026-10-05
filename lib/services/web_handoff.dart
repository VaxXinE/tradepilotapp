import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

import '../core/api/api_config.dart';

/// Resolves the URL to open in the system browser for a web-only page (the
/// top-up page) so the user is already signed in there.
///
/// Asks the backend for a one-time handoff URL (`POST /auth/web-handoff`).
/// Any failure — old backend, rate limit, offline, unexpected URL — falls back
/// to the plain page URL, which only costs the user a login in the browser.
class WebHandoff {
  const WebHandoff._();

  /// [path] may carry a query string, e.g. `/topup?source=app`.
  static Uri plainUri(String path, {String? baseUrl}) {
    final origin = Uri.parse(baseUrl ?? ApiConfig.baseUrl);
    final target = Uri.parse(path);
    return Uri(
      scheme: origin.scheme,
      host: origin.host,
      port: _port(origin),
      path: target.path,
      query: target.hasQuery ? target.query : null,
    );
  }

  /// Tries [path] first, then each of [fallbackPaths], asking the backend for
  /// a signed-in handoff URL for each. A backend that does not know [path] yet
  /// answers 400, so the next candidate is tried before giving up and opening
  /// the plain page for [path].
  static Future<Uri> resolve(
    TradePilotClient client,
    String path, {
    String? baseUrl,
    List<String> fallbackPaths = const [],
  }) async {
    final plain = plainUri(path, baseUrl: baseUrl);
    for (final candidate in [path, ...fallbackPaths]) {
      try {
        final response = await client.auth.createWebHandoff(
          webHandoffBody: WebHandoffBody((b) => b..next = candidate),
        );
        final url = Uri.tryParse(response.data?.url ?? '');
        // The code is bearer-equivalent: only ever hand it to the host the app
        // already talks to, over https.
        if (url != null && url.isScheme('https') && url.host == plain.host) {
          return url;
        }
      } catch (_) {}
    }
    return plain;
  }

  static int? _port(Uri origin) => origin.hasPort ? origin.port : null;
}
