import 'package:flutter/services.dart';

/// Bridge to the native SolidChat SDKs (Android: Compose, iOS: SwiftUI).
///
/// The chat UI is rendered fully natively; Dart only opens it, forwards the
/// backend-issued identity token and resets the local visitor on logout.
class LiveChatService {
  const LiveChatService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'id.tradepilot.app/live_chat';

  final MethodChannel _channel;

  /// Opens the native chat screen. [language] is `id` or `en`.
  /// Returns false when the native side is unavailable.
  Future<bool> open({String language = 'id'}) async {
    try {
      await _channel.invokeMethod<void>('open', {'language': language});
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Links the chat visitor to the signed-in customer. [identityToken] must be
  /// a short-lived JWT signed by a trusted backend, never created in the app.
  Future<void> identify(String identityToken) async {
    try {
      await _channel.invokeMethod<void>('identify', {'token': identityToken});
    } on PlatformException {
      // Chat still works anonymously.
    } on MissingPluginException {
      // Native side not registered (tests, unsupported platform).
    }
  }

  /// Clears the local visitor and conversation. Call on logout.
  Future<void> reset() async {
    try {
      await _channel.invokeMethod<void>('reset');
    } on PlatformException {
      // Best effort; the next user simply resumes a fresh visitor later.
    } on MissingPluginException {
      // Native side not registered (tests, unsupported platform).
    }
  }
}
