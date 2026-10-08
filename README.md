# Trade Pilot — Aplikasi Mobile

Aplikasi Flutter (Android & iOS) untuk **Trade Pilot / TradePilot.id**, asisten
analisis pasar berbasis AI. Aplikasi ini adalah pendamping mobile dari web app
dan memakai backend yang sama. Web app adalah sumber kebenaran: perilaku, angka,
dan alur di sini harus mengikuti web.

- Bundle ID: `id.tradepilot.app`
- Versi saat ini: `1.0.10+12` (lihat `pubspec.yaml`)
- Bahasa UI: Indonesia dan Inggris
- Bukan broker. Aplikasi tidak membuka, menutup, atau mengelola posisi;
  semua hasil adalah bahan pertimbangan, bukan instruksi trading.

## Sumber dan sinkronisasi dengan web

| | |
|---|---|
| Repo web | `Trade-Pilot` (frontend `artifacts/ai-trading`, backend `artifacts/api-server`) |
| Sinkron terakhir | branch `merge-devv-psr` @ `0168712` |
| API base URL | `https://tradepilot.id/api` (default) |

Yang dipakai bersama web:

- **API client Dart** di `packages/trade_pilot_api_client`, di-vendor dari
  `lib/api-client-dart` repo web (sudah ter-generate, tidak perlu
  `build_runner`). Kalau spec OpenAPI web berubah, salin ulang folder itu dan
  format dengan `dart format --language-version=2.18`.
- **Aturan Adaptive Plan** di `lib/core/analysis/`, port dari
  `adaptive-position-plan.ts`. Angkanya diverifikasi terhadap engine web asli
  (lihat bagian Pengujian).
- **Teks UI** di `lib/l10n/app_en.arb` dan `app_id.arb`, disamakan dengan
  `locales/en.ts` dan `id.ts` di web.

Saat menyinkronkan, mulai dari commit terakhir di atas:
`git log 0168712..origin/merge-devv-psr` di repo web, lalu ikuti perubahan
kontrak API (server), teks, dan logika yang tampil di mobile.

## Fitur

**Akun**
- Login/daftar email, Google Sign-In, Sign in with Apple, lupa password,
  onboarding pertama kali.
- Sesi disimpan di secure storage; kunci biometrik saat kembali dari background
  (bisa dimatikan di Profil).
- Edit profil, ganti password, ganti pertanyaan keamanan, privasi & keamanan,
  hapus akun.

**Analisis**
- Analisis baru hanya untuk **8 instrumen terverifikasi**: XAU/USD, BRENT, HSI,
  NIKKEI, EUR/USD, GBP/USD, AUD/USD, USD/JPY, dengan 8 timeframe (1m sampai 1W).
  Kode lain bisa **diminta** lewat dialog "Instrumen lain"; permintaan hanya
  dicatat dan tidak memakai kuota.
- Detail analisis: bias, confidence, skenario, kondisi invalidasi, Standard
  Plan (Buy/Sell), chart level dengan share (salin/simpan/bagikan), konteks
  fundamental (berita & kalender), indikator teknikal, peta risiko timeframe,
  alert harga per level, catatan pribadi, jurnal, dan feedback.
- **Adaptive Plan**: simulasi entry, lot, dan risiko dari analisis tersimpan
  untuk tier akun Micro/Mini/Regular dan tiga gaya risiko. Memakai snapshot
  candle yang tersimpan di analisis, menolak analisis kedaluwarsa, menjelaskan
  kenapa entry terblokir (dana atau batas rugi), dan bisa dibagikan sebagai
  gambar atau dicetak sebagai PDF. Semua ekspor diberi watermark TradePilot.id.
- Kuota gratis dan dialog kuota. Top-up tidak ada di mobile; menu Kredit
  Analisis membuka halaman `/topup` di browser dan memakai handoff sesi satu
  kali pakai (`POST /auth/web-handoff`) agar pengguna tidak perlu login ulang.
  Kalau backend menolak, dibuka halaman biasa.

**Pendukung**
- Dashboard (ringkasan, watchlist, harga live, berita, kalender), riwayat dengan
  filter dan preset, performa, analitik, jurnal trading, Trader Mirror,
  ringkasan harian.
- Price alert, notifikasi (inbox dan preferensi), push native lewat Firebase
  Cloud Messaging.
- Progression: XP, level, achievement, dialog naik level, dan checklist
  pra-analisis.
- Pusat Panduan dan Mindset (konten di `assets/guide_*.json`); membaca panduan
  memberi XP setelah jeda baca minimum dari server.

## Menjalankan

Prasyarat: Flutter stabil dengan Dart `^3.10.4`.

```bash
flutter pub get
flutter run
```

Override environment dengan `--dart-define`:

| Variabel | Fungsi |
|---|---|
| `API_BASE_URL` | Backend lain (dev/staging/lokal), mis. `https://<domain>/api` |
| `SHOW_SPONSOR` | Menampilkan kartu sponsor |
| `SHOW_NEWSMAKER` | Menampilkan elemen Newsmaker |

Backend lokal lewat HTTP butuh pengecualian ATS di
`ios/Runner/Info.plist` dan `android:usesCleartextTraffic="true"`. Hanya untuk
development, jangan masuk build produksi.

Firebase dikonfigurasi lewat `firebase.json`,
`android/app/google-services.json`, dan `ios/Runner/GoogleService-Info.plist`.
Update kode lewat Shorebird (`shorebird.yaml`).

Teks UI dihasilkan dari ARB. Setelah mengubah `app_en.arb` atau `app_id.arb`:

```bash
flutter gen-l10n
```

## Struktur

```
lib/
  core/
    analysis/      # engine Adaptive Plan + perbandingan tier akun
    market/        # instrumen terverifikasi, sesi pasar, konteks & ringkasan teknikal
    api/ storage/ theme/ localization/ preferences/ analytics/ history/ mindset/
  l10n/            # ARB (en, id) dan kode hasil generate
  models/          # model tampilan (market, filter riwayat, notifikasi)
  providers/       # state (Provider/ChangeNotifier): auth, analysis, market,
                   # credit, notifications, price alert, progression, watchlist
  repositories/    # akses API per domain
  services/        # push native, telemetri, PDF Adaptive, gambar ringkasan
                   # plan, watermark ekspor
  screens/         # auth, home (dashboard/analisis/riwayat/profil), analysis,
                   # journal, performance, analytics, mindset, progression, dll.
  widgets/         # komponen reusable, termasuk kartu Adaptive Plan
packages/
  trade_pilot_api_client/   # API client Dart (vendored dari repo web)
assets/                     # panduan (JSON), font Inter, ikon
test/                       # mencerminkan struktur lib/
```

## Pengujian

```bash
flutter analyze
flutter test
```

Beberapa pengujian penting:

- `test/core/adaptive_reference_test.dart` memutar ulang 220 kasus acak yang
  hasilnya dihasilkan oleh engine TypeScript web asli (waktu dibekukan),
  disimpan di `test/fixtures/adaptive_reference.json.gz`. Port Dart harus
  menghasilkan angka dan keputusan yang sama. Kalau logika Adaptive di web
  berubah, buat ulang fixture dengan menjalankan engine web memakai
  `node --experimental-strip-types`.
- `test/api_client_sync_test.dart` menjaga kontrak API client, termasuk field
  yang boleh null dari server.

## Catatan

- `flutter_secure_storage` sengaja dipin ke `^10.3.1`. Jangan loncat ke 11:
  versi itu menghapus backend lama sehingga token sesi yang sudah tersimpan
  tidak bisa dibaca.
- File `.g.dart` di `packages/trade_pilot_api_client` sesekali perlu ditambal
  manual (mis. `MarketSnapshot` yang bisa null). Generate ulang dari OpenAPI akan
  menimpanya, jadi cek `test/api_client_sync_test.dart` setelah update.
- Dokumen internal (`docs/`, `anti-slop/`) tidak dilacak di git.
