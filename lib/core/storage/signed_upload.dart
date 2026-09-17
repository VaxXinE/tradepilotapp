import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

/// Kenapa sebuah upload ditolak atau gagal.
enum SignedUploadFailure {
  /// Bukan JPG, PNG, WebP, atau GIF.
  unsupportedType,

  /// Melebihi [maxSignedUploadBytes].
  tooLarge,

  /// Backend menolak memberi signed URL, atau PUT ke storage gagal.
  failed,
}

/// Error upload yang aman untuk ditampilkan maupun dicatat.
///
/// Sengaja tidak menyimpan `DioException` aslinya: object itu membawa
/// `requestOptions.uri`, yaitu signed URL beserta query string kredensialnya.
/// Menyimpannya berarti signed URL ikut terbawa ke `toString()`, log, dan
/// error analytics.
class SignedUploadException implements Exception {
  const SignedUploadException(this.failure);

  final SignedUploadFailure failure;

  @override
  String toString() => 'SignedUploadException(${failure.name})';
}

/// Batas ukuran bukti/avatar sebelum upload.
const int maxSignedUploadBytes = 5 * 1024 * 1024;

/// Hanya format gambar yang diterima backend.
const Set<String> allowedImageContentTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
};

/// Content type gambar dari MIME yang dilaporkan picker, dengan fallback ke
/// ekstensi berkas. `null` kalau formatnya tidak didukung.
String? resolveImageContentType({String? mimeType, required String fileName}) {
  final mime = mimeType?.toLowerCase();

  if (mime != null && allowedImageContentTypes.contains(mime)) {
    return mime;
  }

  final name = fileName.toLowerCase();

  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.gif')) return 'image/gif';

  return null;
}

/// Alur signed upload bersama untuk avatar dan bukti pembayaran.
///
/// ```text
/// POST /storage/uploads/request-url
/// PUT  binary ke signed URL
/// ```
///
/// Yang dikembalikan adalah object path — itu yang boleh disimpan dan dikirim
/// ke backend. Signed URL tidak pernah keluar dari kelas ini.
class SignedUploadService {
  SignedUploadService(this._client, {Dio? transport})
    : _transport =
          transport ??
          // Dio terpisah dari client utama: PUT ke storage tidak boleh membawa
          // bearer token TradePilot, jadi interceptor-nya sengaja tidak ikut.
          // Adapter-nya tetap diwarisi supaya transport-nya bisa diganti pada
          // test lewat satu titik yang sama dengan request lainnya.
          (Dio()..httpClientAdapter = _client.dio.httpClientAdapter);

  final TradePilotClient _client;

  final Dio _transport;

  /// Mengunggah [bytes] lalu mengembalikan object path-nya.
  ///
  /// Melempar [SignedUploadException] untuk semua kegagalan.
  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final contentType = resolveImageContentType(
      mimeType: mimeType,
      fileName: fileName,
    );

    if (contentType == null) {
      throw const SignedUploadException(SignedUploadFailure.unsupportedType);
    }

    if (bytes.length > maxSignedUploadBytes) {
      throw const SignedUploadException(SignedUploadFailure.tooLarge);
    }

    final UploadUrlResponse target;

    try {
      final response = await _client.storage.requestUploadUrl(
        uploadUrlRequest: UploadUrlRequest(
          (builder) => builder
            ..name = fileName
            ..size = bytes.length
            ..contentType = contentType,
        ),
      );

      final data = response.data;

      if (data == null) {
        throw const SignedUploadException(SignedUploadFailure.failed);
      }

      target = data;
    } on SignedUploadException {
      rethrow;
    } catch (_) {
      throw const SignedUploadException(SignedUploadFailure.failed);
    }

    try {
      await _transport.putUri<void>(
        Uri.parse(target.uploadURL),
        data: Stream.value(bytes),
        options: Options(
          contentType: contentType,
          headers: {Headers.contentLengthHeader: bytes.length},
        ),
      );
    } catch (_) {
      // Error aslinya dibuang di sini, sebelum sempat naik ke pemanggil: ia
      // membawa signed URL lengkap dengan query string.
      throw const SignedUploadException(SignedUploadFailure.failed);
    }

    return target.objectPath;
  }
}
