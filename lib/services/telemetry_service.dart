import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

/// Best-effort product telemetry. A telemetry failure must never block UI.
class TelemetryService {
  TelemetryService(this._client, {bool? enabled})
    : _enabled = enabled ?? Platform.environment['FLUTTER_TEST'] != 'true';

  final TradePilotClient _client;
  final bool _enabled;

  Future<void> track(
    AnalyticsEventBodyEventTypeEnum eventType, {
    String? path,
    Map<String, Object?> metadata = const {},
  }) async {
    if (!_enabled) return;
    try {
      await _client.events.trackAnalyticsEvent(
        analyticsEventBody: AnalyticsEventBody((builder) {
          builder
            ..eventType = eventType
            ..path = path;
          if (metadata.isNotEmpty) {
            builder.metadata.replace(
              BuiltMap<String, JsonObject?>(
                metadata.map((key, value) => MapEntry(key, JsonObject(value))),
              ),
            );
          }
        }),
      );
    } catch (_) {
      // Analytics bersifat best-effort dan tidak boleh mengganggu fitur utama.
    }
  }

  Future<void> pageView(String path) =>
      track(AnalyticsEventBodyEventTypeEnum.pageView, path: path);

  Future<void> recordOutboundClick({
    required OutboundClickBodyPlacementEnum placement,
    required OutboundClickBodyTargetEnum target,
    required String languageCode,
  }) async {
    if (!_enabled) return;
    try {
      await _client.events.recordOutboundClick(
        outboundClickBody: OutboundClickBody(
          (builder) => builder
            ..placement = placement
            ..target = target
            ..lang = languageCode == 'id'
                ? OutboundClickBodyLangEnum.id
                : OutboundClickBodyLangEnum.en,
        ),
      );
    } catch (_) {
      // Klik tetap membuka tujuan walaupun pencatatan gagal/offline.
    }
  }
}
