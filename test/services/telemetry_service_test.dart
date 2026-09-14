import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';
import 'package:tradepilotapp/services/telemetry_service.dart';

void main() {
  test('sends typed analytics and outbound-click payloads', () async {
    final adapter = _RecordingAdapter();
    final client = TradePilotClient(
      baseUrl: 'https://example.com/api',
      dio: Dio(),
    );
    client.dio.httpClientAdapter = adapter;
    final telemetry = TelemetryService(client, enabled: true);

    await telemetry.track(
      AnalyticsEventBodyEventTypeEnum.analysisCreated,
      path: '/analyze',
      metadata: {'instrument': 'XAU/USD', 'timeframe': '1h'},
    );
    await telemetry.recordOutboundClick(
      placement: OutboundClickBodyPlacementEnum.profileCta,
      target: OutboundClickBodyTargetEnum.sgBerjangka,
      languageCode: 'id',
    );

    expect(adapter.requests.map((request) => request.path), [
      '/events/track',
      '/events/outbound-click',
    ]);
    expect(
      adapter.requests.first.data,
      containsPair('eventType', 'analysis_created'),
    );
    expect(adapter.requests.first.data, containsPair('path', '/analyze'));
    expect(adapter.requests.last.data, containsPair('target', 'sg-berjangka'));
    expect(adapter.requests.last.data, containsPair('lang', 'id'));
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}
