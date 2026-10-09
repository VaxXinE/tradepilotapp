import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../services/web_handoff.dart';
import 'topup_return_controller.dart';
import 'topup_return_link.dart';

/// Opens a URL in an in-app browser tab and resolves with the callback URL.
typedef InAppBrowserAuthenticate =
    Future<String> Function({
      required String url,
      required String callbackUrlScheme,
      FlutterWebAuth2Options options,
    });

/// Opens the web top-up page, signed in, and brings the user back to the app
/// once the payment is done. Shared by the profile and the "out of analyses"
/// dialog. [authenticate] is replaceable so tests do not open a real tab.
Future<void> openTopUp(
  BuildContext context, {
  InAppBrowserAuthenticate authenticate = FlutterWebAuth2.authenticate,
}) async {
  final auth = context.read<AuthProvider>();
  final credits = context.read<CreditProvider>();
  final returned = context.read<TopupReturnController>();
  var opened = false;
  try {
    // Signs the browser in with a one-time code so the user does not have
    // to log in again; falls back to the plain page if that is unavailable.
    // `source=app` asks the web page to send the user back to the app once
    // the payment is done. A backend that does not know it yet rejects it,
    // and the plain handoff for /topup is used instead.
    final target = await WebHandoff.resolve(
      auth.client,
      '/topup?source=app',
      fallbackPaths: const ['/topup'],
    );
    credits.markTopupStarted();
    opened = await _openInAppBrowser(target, credits, returned, authenticate);
    if (!opened) {
      opened = await launchUrl(target, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    // Native browser channel can fail when no compatible app is available.
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.linkOpenFailed)));
  }
}

/// Opens the top-up page in an in-app browser tab that closes itself, and
/// returns the user to the app, when the web page navigates to
/// `id.tradepilot.app://topup/result?...`. A system browser would ask the
/// user to confirm leaving the page, because a link opened without a tap is
/// treated as untrusted. Returns false when the tab could not be opened.
Future<bool> _openInAppBrowser(
  Uri target,
  CreditProvider credits,
  TopupReturnController returned,
  InAppBrowserAuthenticate authenticate,
) async {
  try {
    final result = await authenticate(
      url: target.toString(),
      callbackUrlScheme: TopupReturnLink.scheme,
      // One-time handoff code signs in inside the tab, so nothing needs to
      // be shared with the system browser; also skips iOS's sign-in notice.
      options: FlutterWebAuth2Options(
        preferEphemeral: defaultTargetPlatform == TargetPlatform.iOS,
      ),
    );
    returned.report(Uri.parse(result));
    return true;
  } on PlatformException catch (error) {
    if (error.code.toLowerCase().contains('cancel')) {
      // The user closed the tab, possibly after paying: check the balance.
      unawaited(credits.refreshAfterTopupReturn());
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}
