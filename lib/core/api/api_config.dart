/// Konfigurasi endpoint backend Trade Pilot (artifacts/api-server pada
/// repo Trade-Pilot, branch prod).
///
/// Override saat build/run kalau perlu, contoh:
///   flutter run --dart-define=API_BASE_URL=https://api.tradepilot.app/api
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // TODO: ganti default ini dengan URL production api-server kamu
    // (lihat "Production Routing" di replit.md Trade-Pilot: api-server
    // di-deploy sebagai Cloud Run service yang serve /api/*).
    defaultValue: 'https://tradepilot.example.com/api',
  );
}
