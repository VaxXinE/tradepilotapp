/// Konfigurasi endpoint backend Trade Pilot (artifacts/api-server pada
/// repo Trade-Pilot, branch prod).
///
/// Override saat build/run kalau perlu, contoh:
///   flutter run --dart-define=API_BASE_URL=https://api.tradepilot.app/api
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Domain production Trade-Pilot (dashboard Replit → Deployments →
    // "AI Trading Assistant" → tradepilot.id). Sesuai "Production Routing"
    // di replit.md: ai-trading di-serve statis di "/", api-server di-serve
    // di "/api/*" — jadi satu domain yang sama untuk web app dan API.
    defaultValue: 'https://tradepilot.id/api',
  );
}
