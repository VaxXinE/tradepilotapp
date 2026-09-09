import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

void main() {
  test('POST analyses accepts the current backend response', () async {
    final client = TradePilotClient(baseUrl: 'https://example.test/api');
    client.dio.httpClientAdapter = _AnalysisResponseAdapter();

    final response = await client.analyses.createAnalysis(
      createAnalysisBody: CreateAnalysisBody(
        (builder) => builder
          ..instrument = 'XAU/USD'
          ..timeframe = CreateAnalysisBodyTimeframeEnum.n1h
          ..mode = CreateAnalysisBodyModeEnum.beginner,
      ),
    );

    expect(response.data?.id, 42);
    expect(response.data?.creditConsumed, isFalse);
  });
}

class _AnalysisResponseAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'id': 42,
        'userId': 7,
        'instrument': 'XAU/USD',
        'timeframe': '1h',
        'mode': 'beginner',
        'validUntil': '2026-09-09T12:00:00.000Z',
        'createdAt': '2026-09-09T10:00:00.000Z',
        'creditConsumed': false,
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
