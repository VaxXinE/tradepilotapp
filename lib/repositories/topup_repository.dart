import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';
import '../l10n/app_messages.dart';

/// Akses tipis ke `TopupsApi` pada generated client.
///
/// Repository ini sengaja tidak menyimpan state apa pun: saldo credit dan
/// status top-up tetap milik backend. Tugasnya hanya memvalidasi input yang
/// jelas salah sebelum menembak jaringan, lalu mengembalikan model generated
/// apa adanya.
class TopupRepository {
  const TopupRepository(this._client);

  final TradePilotClient _client;

  /// Batas item riwayat per halaman, sesuai default `GET /topups/mine`.
  static const int historyPageSize = 20;

  /// `GET /topups/config`
  Future<TopupConfig?> getConfig() async {
    final response = await _client.topups.getTopupConfig();

    return response.data;
  }

  /// `GET /topups/balance`
  Future<CreditBalance?> getBalance() async {
    final response = await _client.topups.getCreditBalance();

    return response.data;
  }

  /// `POST /topups`
  ///
  /// [proofObjectPath] adalah object path hasil signed upload, bukan signed
  /// URL-nya. Signed URL tidak boleh ikut dikirim atau dicatat.
  Future<TopupRequest?> createRequest({
    required int amountRupiah,
    String? paymentReferenceNote,
    String? proofObjectPath,
  }) async {
    if (amountRupiah < 1) {
      throw ArgumentError.value(
        amountRupiah,
        'amountRupiah',
        AppMessages.l10n.errTopupAmountPositive,
      );
    }

    final note = paymentReferenceNote?.trim();
    final proof = proofObjectPath?.trim();

    final response = await _client.topups.createTopupRequest(
      createTopupRequestBody: CreateTopupRequestBody(
        (builder) => builder
          ..amountRupiah = amountRupiah
          ..paymentReferenceNote = (note == null || note.isEmpty) ? null : note
          ..proofObjectPath = (proof == null || proof.isEmpty) ? null : proof,
      ),
    );

    return response.data;
  }

  /// `GET /topups/mine`
  Future<TopupRequestList?> getMyRequests({
    required int page,
    int limit = historyPageSize,
  }) async {
    final response = await _client.topups.getMyTopupRequests(
      page: page,
      limit: limit,
    );

    return response.data;
  }
}
