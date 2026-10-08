import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:trade_pilot_api_client/trade_pilot_client.dart';

/// Read-only access to the user's analysis-credit balance.
class TopupRepository {
  const TopupRepository(this._client);

  final TradePilotClient _client;

  Future<CreditBalance?> getBalance() async {
    final response = await _client.topups.getCreditBalance();
    return response.data;
  }

  // Payment checkout is intentionally unavailable in the mobile app.
  // Keep payment APIs in the generated client only for backend schema parity.
}
