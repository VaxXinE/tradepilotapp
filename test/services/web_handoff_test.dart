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

/// Accepts a handoff only for one `next` value and records every request.
class _SelectiveAdapter extends _Adapter {
  _SelectiveAdapter({required this.acceptedNext}) : super(201, const {});

  final String acceptedNext;
  final List<String> nextValues = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final next = (options.data as Map)['next'] as String;
    nextValues.add(next);
    final ok = next == acceptedNext;
    return ResponseBody.fromString(
      jsonEncode(
        ok
            ? {
                'url':
                    'https://tradepilot.id/api/auth/web-handoff/consume?code=abc',
                'expiresIn': 60,
              }
            : {'error': 'unsupported'},
      ),
      ok ? 201 : 400,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
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

  test('keeps the query of the requested page in the plain url', () {
    expect(
      WebHandoff.plainUri('/topup?source=app', baseUrl: base).toString(),
      'https://tradepilot.id/topup?source=app',
    );
  });

  test(
    'falls back to the next path when the backend rejects the first',
    () async {
      final adapter = _SelectiveAdapter(acceptedNext: '/topup');
      final uri = await WebHandoff.resolve(
        _client(adapter),
        '/topup?source=app',
        fallbackPaths: const ['/topup'],
        baseUrl: base,
      );

      expect(adapter.nextValues, ['/topup?source=app', '/topup']);
      expect(uri.toString(), contains('/auth/web-handoff/consume?code=abc'));
    },
  );

  test(
    'opens the plain page of the first path when every handoff fails',
    () async {
      final uri = await WebHandoff.resolve(
        _client(_Adapter(400, {'error': 'no'})),
        '/topup?source=app',
        fallbackPaths: const ['/topup'],
        baseUrl: base,
      );
      expect(uri.toString(), 'https://tradepilot.id/topup?source=app');
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
