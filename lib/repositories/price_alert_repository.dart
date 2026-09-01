import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

class PriceAlertRepository {
  const PriceAlertRepository(this._client);

  final TradePilotClient _client;

  Future<List<UserPriceAlert>> getAlerts() async {
    final response = await _client.userPriceAlerts.listUserPriceAlerts();
    return response.data?.alerts.toList() ?? const [];
  }

  Future<UserPriceAlert?> createAlert({
    required String instrument,
    required double targetPrice,
    required bool triggerAbove,
    String? note,
  }) async {
    final normalized = _normalizeInstrument(instrument);

    if (!targetPrice.isFinite || targetPrice <= 0) {
      throw ArgumentError.value(
        targetPrice,
        'targetPrice',
        'Target harga harus lebih besar dari 0.',
      );
    }

    final trimmedNote = note?.trim();

    if (trimmedNote != null && trimmedNote.length > 200) {
      throw ArgumentError.value(
        trimmedNote,
        'note',
        'Catatan maksimal 200 karakter.',
      );
    }

    final response = await _client.userPriceAlerts.createUserPriceAlert(
      createUserPriceAlertBody: CreateUserPriceAlertBody(
        (builder) => builder
          ..instrument = normalized
          ..targetPrice = targetPrice
          ..triggerDirection = triggerAbove
              ? CreateUserPriceAlertBodyTriggerDirectionEnum.above
              : CreateUserPriceAlertBodyTriggerDirectionEnum.below
          ..note = (trimmedNote == null || trimmedNote.isEmpty)
              ? null
              : trimmedNote
          ..lang = CreateUserPriceAlertBodyLangEnum.id,
      ),
    );

    return response.data;
  }

  Future<void> deleteAlert(int id) async {
    await _client.userPriceAlerts.deleteUserPriceAlert(id: id);
  }

  String _normalizeInstrument(String instrument) {
    final normalized = instrument.trim().toUpperCase();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        instrument,
        'instrument',
        'Instrumen tidak boleh kosong.',
      );
    }

    return normalized;
  }
}
