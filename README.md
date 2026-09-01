# Trade Pilot — Flutter App

Aplikasi mobile Flutter untuk **Trade Pilot** (AI Trading Assistant), dibangun
mengikuti desain & fitur web app di repo
[`Trade-Pilot`](https://github.com/aisgbizdev/Trade-Pilot) branch `prod`
(`artifacts/ai-trading`), dan mengonsumsi backend `artifacts/api-server` lewat
API client Dart yang di-vendor dari `lib/api-client-dart`.

## Setup

```bash
flutter pub get
```

### Konfigurasi Base URL API

Default base URL sudah diarahkan ke domain production Trade-Pilot:
**`https://tradepilot.id/api`** (dikonfirmasi dari dashboard Replit →
Deployments → "AI Trading Assistant"). Sesuai "Production Routing" di
`replit.md`: `ai-trading` di-serve statis di `/`, `api-server` di-serve di
`/api/*` — satu domain yang sama.

Kalau butuh arahkan ke environment lain (dev/staging/lokal), override lewat
`--dart-define` saat run/build:

```bash
flutter run --dart-define=API_BASE_URL=https://<domain-lain>/api
```

Kalau testing ke backend lokal via HTTP (bukan HTTPS), tambahkan exception
App Transport Security di `ios/Runner/Info.plist` dan
`android:usesCleartextTraffic="true"` di `AndroidManifest.xml` (khusus dev,
jangan dipakai di build production).

### Menjalankan

```bash
flutter run
```

## Struktur

```
lib/
  core/
    api/            # konfigurasi base URL
    storage/         # secure storage token & user
    theme/            # warna + ThemeData (brand hitam+emas, selaras web app)
  providers/          # state management (Provider/ChangeNotifier)
    auth_provider.dart
    analysis_provider.dart
    notifications_provider.dart
  screens/
    auth/             # login, register, lupa password (3-step)
    home/
      home_shell.dart # bottom nav 4 tab
      tabs/            # dashboard, analyze, history, profile
    analysis/          # detail analisis + trade plan + feedback
    notifications/
    profile/           # ganti password
  widgets/             # komponen reusable (analysis card, error banner)
packages/
  trade_pilot_api_client/  # API client Dart (di-vendor dari Trade-Pilot repo,
                            # lib/api-client-dart — sudah generated, tidak perlu
                            # build_runner)
```

## Fitur yang sudah diimplementasikan

- Autentikasi: login, register (dengan pertanyaan keamanan + mode
  Pemula/Pro), lupa password 3-langkah, session token tersimpan aman
  (`flutter_secure_storage`), auto-restore sesi saat app dibuka.
- Dashboard: statistik ringkas, kuota analisis (per jam/hari), daftar
  analisis terbaru.
- Analisis AI: form pilih instrumen (Forex/Crypto/Futures) + timeframe +
  catatan tambahan, submit ke AI, redirect ke halaman detail.
- Detail analisis: bias (bullish/bearish/netral), confidence bar, skenario
  utama & alternatif, kondisi invalidasi, **rencana trading lengkap**
  (entry/stop-loss/TP1/TP2/risk-reward untuk sisi Buy & Sell), feedback
  (membantu / kurang membantu).
- Riwayat analisis dengan infinite scroll.
- Notifikasi: daftar, tandai dibaca (satu/semua).
- Profil: toggle mode Pemula/Pro, ganti password, lihat pertanyaan
  keamanan, logout.

## Belum diimplementasikan (fitur lanjutan web app)

Web app (`artifacts/ai-trading`) juga punya halaman-halaman berikut yang
**belum** dibuatkan versi Flutter-nya — silakan lanjutkan sesuai prioritas:

- Analytics/Personal Analytics (grafik `recharts` → bisa pakai `fl_chart`,
  sudah ditambahkan sebagai dependency tapi belum dipakai)
- Trade Journal (`journal.tsx`)
- Trader Mirror (`mirror.tsx`)
- Daily Summary (`daily-summary.tsx`)
- Performance (`performance.tsx`)
- My Alerts / Price Alerts (`my-alerts.tsx`)
- Mindset (`mindset.tsx`)
- Admin panel (`admin.tsx`, `admin-users.tsx`, `admin-feedback.tsx`) — ini
  khusus role admin/super_admin, biasanya tidak perlu di app mobile end-user
- Web Push Notifications (VAPID) — mobile biasanya pakai FCM/APNs, ini butuh
  desain ulang terpisah dari implementasi web push
- Watchlist widget di dashboard, live prices, news/calendar widget

Semua endpoint untuk fitur-fitur di atas **sudah tersedia** di
`packages/trade_pilot_api_client` (cek `AdminApi`, `TradeJournalApi`,
`TraderMirrorApi`, `DailySummaryApi`, `PerformanceApi`,
`UserPriceAlertsApi`, `WatchlistApi`, dst) — tinggal dibuatkan provider +
screen-nya mengikuti pola yang sudah ada di `lib/providers/` dan
`lib/screens/`.

## Catatan penting

- Kode ini ditulis manual tanpa akses Flutter SDK di lingkungan pembuatannya
  (sandbox tidak punya Flutter toolchain), jadi **belum pernah di-compile
  atau di-`flutter analyze`**. Jalankan `flutter pub get` lalu
  `flutter analyze` / `flutter run` setelah pull untuk menangkap kemungkinan
  typo atau ketidakcocokan API kecil sebelum lanjut development.
- `packages/trade_pilot_api_client` di-vendor (bukan git submodule) supaya
  self-contained. Kalau `Trade-Pilot` (branch `prod`) meng-update OpenAPI
  spec / API client-nya, salin ulang folder
  `lib/api-client-dart` dari repo itu ke `packages/trade_pilot_api_client`
  di sini.
