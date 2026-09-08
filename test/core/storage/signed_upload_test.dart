import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';
import 'package:tradepilotapp/core/storage/signed_upload.dart';

/// A signed URL always carries its credentials in the query string. If any of
/// this ever reaches a log line or an analytics payload, the payment proof it
/// protects becomes readable by whoever can see that log.
const _signedUrl =
    'https://storage.googleapis.com/tradepilot/topups/proof-1.jpg'
    '?X-Goog-Algorithm=GOOG4-RSA-SHA256'
    '&X-Goog-Credential=service-account%40project.iam.gserviceaccount.com'
    '&X-Goog-Signature=deadbeefcafe';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rejects a file that is not an allowed image type', () async {
    final (service, adapter) = _service();

    await expectLater(
      service.uploadImage(
        fileName: 'statement.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'application/pdf',
      ),
      throwsA(
        isA<SignedUploadException>().having(
          (error) => error.failure,
          'failure',
          SignedUploadFailure.unsupportedType,
        ),
      ),
    );

    // Nothing may reach the network before the type is accepted.
    expect(adapter.requests, isEmpty);
  });

  test('rejects a file larger than 5 MB before uploading', () async {
    final (service, adapter) = _service();

    await expectLater(
      service.uploadImage(
        fileName: 'proof.jpg',
        bytes: Uint8List(maxSignedUploadBytes + 1),
        mimeType: 'image/jpeg',
      ),
      throwsA(
        isA<SignedUploadException>().having(
          (error) => error.failure,
          'failure',
          SignedUploadFailure.tooLarge,
        ),
      ),
    );

    expect(adapter.requests, isEmpty);
  });

  test('accepts every allowed type, including by extension alone', () async {
    for (final (name, mime) in [
      ('proof.jpg', 'image/jpeg'),
      ('proof.png', 'image/png'),
      ('proof.webp', 'image/webp'),
      ('proof.gif', 'image/gif'),
    ]) {
      expect(
        resolveImageContentType(mimeType: mime, fileName: name),
        mime,
        reason: name,
      );

      // Some pickers report no MIME type at all.
      expect(
        resolveImageContentType(mimeType: null, fileName: name),
        mime,
        reason: name,
      );
    }

    expect(
      resolveImageContentType(mimeType: 'application/pdf', fileName: 'a.pdf'),
      isNull,
    );
  });

  test(
    'returns the object path and PUTs the bytes to the signed URL',
    () async {
      final (service, adapter) = _service();

      final objectPath = await service.uploadImage(
        fileName: 'proof.jpg',
        bytes: Uint8List.fromList(List.filled(64, 7)),
        mimeType: 'image/jpeg',
      );

      expect(objectPath, 'topups/proof-1.jpg');

      final request = adapter.requests.first;
      expect(request.method, 'POST');
      expect(request.path, '/storage/uploads/request-url');

      final metadata = Map<String, dynamic>.from(request.data as Map);
      expect(metadata['name'], 'proof.jpg');
      expect(metadata['size'], 64);
      expect(metadata['contentType'], 'image/jpeg');

      final put = adapter.requests.last;
      expect(put.method, 'PUT');
      expect(put.uri.toString(), _signedUrl);
    },
  );

  test('a failed PUT never carries the signed URL into the error', () async {
    final (service, adapter) = _service();
    adapter.failUpload = true;

    Object? thrown;
    try {
      await service.uploadImage(
        fileName: 'proof.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
      );
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<SignedUploadException>());
    expect(
      (thrown as SignedUploadException).failure,
      SignedUploadFailure.failed,
    );

    // This is the whole point of wrapping the DioException: whatever a caller
    // logs about this failure must not contain the URL or its signature.
    final rendered = thrown.toString();
    expect(rendered, isNot(contains('X-Goog-Signature')));
    expect(rendered, isNot(contains('X-Goog-Credential')));
    expect(rendered, isNot(contains('storage.googleapis.com')));
    expect(rendered, isNot(contains('?')));
  });

  test('a rejected signed-URL request fails without leaking either', () async {
    final (service, adapter) = _service();
    adapter.failRequestUrl = true;

    Object? thrown;
    try {
      await service.uploadImage(
        fileName: 'proof.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
      );
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<SignedUploadException>());
    expect(thrown.toString(), isNot(contains('storage.googleapis.com')));

    // The proof must never be sent anywhere when no signed URL was issued.
    expect(
      adapter.requests.where((options) => options.method == 'PUT'),
      isEmpty,
    );
  });
}

(SignedUploadService, _UploadAdapter) _service() {
  final client = TradePilotClient(baseUrl: 'https://example.com/api');
  final adapter = _UploadAdapter();
  client.dio.httpClientAdapter = adapter;

  final transport = Dio()..httpClientAdapter = adapter;

  return (SignedUploadService(client, transport: transport), adapter);
}

class _UploadAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  bool failRequestUrl = false;
  bool failUpload = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.method == 'PUT') {
      if (failUpload) {
        throw DioException.badResponse(
          statusCode: 403,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 403,
            data: 'SignatureDoesNotMatch',
          ),
        );
      }

      return ResponseBody.fromString('', 200);
    }

    if (failRequestUrl) {
      return ResponseBody.fromString(
        jsonEncode({'error': 'Upload not allowed'}),
        403,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'uploadURL': _signedUrl, 'objectPath': 'topups/proof-1.jpg'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
