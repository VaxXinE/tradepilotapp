import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';
import 'package:tradepilotapp/services/web_handoff.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final Object body;
  RequestOptions? seen;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

TradePilotClient _client(_Adapter adapter) {
  final client = TradePilotClient(
    baseUrl: 'https://tradepilot.id/api',
    getToken: () async => 'token',
  );
  client.dio.httpClientAdapter = adapter;
  return client;
}

void main() {
  const base = 'https://tradepilot.id/api';

  test('uses the one-time handoff url returned by the backend', () async {
    final adapter = _Adapter(201, {
      'url': 'https://tradepilot.id/api/auth/web-handoff/consume?code=abc',
      'expiresIn': 60,
    });
    final uri = await WebHandoff.resolve(
      _client(adapter),
      '/topup',
      baseUrl: base,
    );

    expect(uri.toString(), contains('/auth/web-handoff/consume?code=abc'));
    expect(adapter.seen?.path, '/auth/web-handoff');
    expect(adapter.seen?.method, 'POST');
    expect(adapter.seen?.data, {'next': '/topup'});
  });

  test('falls back to the plain page when the backend refuses', () async {
    final uri = await WebHandoff.resolve(
      _client(_Adapter(404, {'error': 'nope'})),
      '/topup',
      baseUrl: base,
    );
    expect(uri.toString(), 'https://tradepilot.id/topup');
  });

  test(
    'never follows a handoff url on another host or without https',
    () async {
      for (final url in [
        'https://evil.example/api/auth/web-handoff/consume?code=abc',
        'http://tradepilot.id/api/auth/web-handoff/consume?code=abc',
      ]) {
        final uri = await WebHandoff.resolve(
          _client(_Adapter(201, {'url': url, 'expiresIn': 60})),
          '/topup',
          baseUrl: base,
        );
        expect(uri.toString(), 'https://tradepilot.id/topup', reason: url);
      }
    },
  );

  test('plain url keeps a non-default port of a dev backend', () {
    expect(
      WebHandoff.plainUri(
        '/topup',
        baseUrl: 'https://dev.local:8443/api',
      ).toString(),
      'https://dev.local:8443/topup',
    );
  });
}
