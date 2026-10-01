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

  static Uri plainUri(String path, {String? baseUrl}) {
    final origin = Uri.parse(baseUrl ?? ApiConfig.baseUrl);
    return Uri(
      scheme: origin.scheme,
      host: origin.host,
      port: _port(origin),
      path: path,
    );
  }

  static Future<Uri> resolve(
    TradePilotClient client,
    String path, {
    String? baseUrl,
  }) async {
    final fallback = plainUri(path, baseUrl: baseUrl);
    try {
      final response = await client.auth.createWebHandoff(
        webHandoffBody: WebHandoffBody((b) => b..next = path),
      );
      final url = Uri.tryParse(response.data?.url ?? '');
      // The code is bearer-equivalent: only ever hand it to the host the app
      // already talks to, over https.
      if (url != null && url.isScheme('https') && url.host == fallback.host) {
        return url;
      }
    } catch (_) {}
    return fallback;
  }

  static int? _port(Uri origin) => origin.hasPort ? origin.port : null;
}
