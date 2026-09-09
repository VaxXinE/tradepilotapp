# TradePilot Mobile UI Parity Baseline

## Acuan

- Web: `Trade-Pilot/artifacts/ai-trading`
- Branch web: `prodd-v2`
- Commit acuan: `860e898`
- Target utama: responsive mobile web, bukan `artifacts/mobile` lama
- Viewport pembanding: 360×800, 390×844, dan 430×932

Perubahan ini mengejar visual parity. Navigasi native, secure storage, API,
provider, polling, dan business logic Flutter tetap menjadi source of truth.
Fitur admin web tidak dibawa ke aplikasi mobile.

## Token desain

| Elemen | Web | Flutter M1 |
| --- | --- | --- |
| Font | Inter 100–900 | Inter variable, dibundel lokal dengan lisensi SIL OFL 1.1 |
| Light background | `hsl(0 0% 100%)` | `#FFFFFF` |
| Light card | `hsl(0 0% 98%)` | `#FAFAFA` |
| Dark background | `hsl(0 0% 2%)` | `#050505` |
| Dark card | `hsl(0 0% 4%)` | `#0A0A0A` |
| Gold accent | `hsl(43 96% 48–50%)` | `#F0AD05` / `#FAB505` |
| Card border | 90% light / 12% dark | `#E6E6E6` / `#1F1F1F` |
| Card radius | `rounded-xl` (12 px) | 12 px |
| Primary control height | 48 px | 48 px |

Light-theme link text tetap menggunakan emas gelap `#8A5900` agar teks kecil
memenuhi kontras WCAG AA. Emas terang dipakai sebagai fill dengan teks hitam.

## Matriks halaman web dan Flutter

| Area | Referensi web | Implementasi Flutter | Prioritas | Status baseline |
| --- | --- | --- | --- | --- |
| App shell | `components/layout.tsx` | `screens/home/home_shell.dart` | P0 | M2 diterapkan |
| Login | `pages/login.tsx` | `screens/auth/login_screen.dart` | P0 | M3 diterapkan |
| Register | `pages/register.tsx` | `screens/auth/register_screen.dart` | P0 | M3 diterapkan |
| Forgot password | `pages/forgot-password.tsx` | `screens/auth/forgot_password_screen.dart` | P0 | M3 diterapkan |
| Analyze | `pages/analyze.tsx` | `screens/home/tabs/analyze_tab.dart` | P0 | M3 diterapkan |
| Dashboard | Web mengarah ke Analyze | `screens/home/tabs/dashboard_tab.dart` | P0 | Dipertahankan sebagai fitur native |
| History | `pages/history.tsx` | `screens/home/tabs/history_tab.dart` | P0 | M3 diterapkan |
| Analysis detail | `pages/analysis-detail.tsx` | `screens/analysis/analysis_detail_screen.dart` | P0 | M3 diterapkan |
| Profile | `pages/profile.tsx` | `screens/home/tabs/profile_tab.dart` | P1 | M5 diterapkan |
| Top up | `pages/topup.tsx` | `screens/topup/topup_screen.dart` | P1 | M4 wizard diterapkan |
| Notifications | `pages/notifications.tsx` | `screens/notifications/notifications_screen.dart` | P1 | M5 diterapkan |
| Progression | `pages/progression.tsx` | `screens/progression/progression_screen.dart` | P1 | M5 diterapkan |
| Guide | `pages/guide.tsx` | `screens/mindset/mindset_screen.dart` | P1 | M5 diterapkan |
| Journal | `pages/journal.tsx` | `screens/journal/trade_journal_screen.dart` | P1 | M5 diterapkan |
| Price alert | `pages/my-alerts.tsx` | `screens/price_alert/price_alert_list_screen.dart` | P1 | M5 diterapkan |
| Analytics | `pages/analytics.tsx` | `screens/analytics/analytics_screen.dart` | P2 | M6 diterapkan |
| Performance | `pages/performance.tsx` | `screens/performance/performance_screen.dart` | P2 | M6 diterapkan |
| Daily summary | `pages/daily-summary.tsx` | `screens/daily_summary/daily_summary_screen.dart` | P2 | M6 diterapkan |
| Trader mirror | `pages/mirror.tsx` | `screens/trader_mirror/trader_mirror_screen.dart` | P2 | M6 diterapkan |
| Mindset | `pages/mindset.tsx` | `screens/mindset/mindset_screen.dart` | P2 | M6 diterapkan |
| Legal/support | `pages/legal.tsx` | External browser dari Profil | P2 | Perilaku native dipertahankan |

## App shell M2

- Header konsisten berisi brand, bahasa, theme, price alert, notification badge,
  dan avatar profil.
- Live quote ticker menggunakan data `MarketProvider` yang sudah ada.
- Bottom navigation memakai floating card dengan safe-area Android/iOS.
- Tab Flutter mengikuti web pada M8b: Analisis, Riwayat, Panduan. Dashboard
  dan Profil menjadi layar tanpa tab seperti pada web.
- App bar duplikat pada tab utama dihapus.

Ticker sengaja dapat digeser pengguna dan tidak bergerak otomatis. Ini tetap
menampilkan data live seperti web, tetapi menghindari animasi kontinu yang dapat
mengganggu aksesibilitas dan tidak membutuhkan dependency marquee tambahan.

## Core journey M3

- Login, register, dan forgot password memakai panel formulir yang konsisten
  dengan mobile web tanpa mengubah validasi, autofill, atau secure storage.
- Dashboard, Analyze, dan History menggunakan app shell M2 dan komponen kartu
  dari design foundation.
- Analysis Detail mempertahankan alur native yang sudah lengkap; detail teknis
  tetap dapat diciutkan agar ringkasan dan rekomendasi mudah dipindai.

## Financial flow M4

- Kuota per jam, kuota harian, dan purchased credit tampil bersama di Analyze.
- Top Up memakai wizard dua langkah: pilih nominal lalu isi detail pembayaran.
- Riwayat dan status transaksi tetap berasal dari endpoint serta model generated.
- Validasi nominal, bukti pembayaran, dan pencegahan submit ganda dipertahankan.

## Supporting features M5

- Profile, Notifications, Progression, Guide, Journal, dan Price Alert memakai
  token tema serta pola kartu yang sama.
- Navigasi dan business logic yang sudah stabil digunakan ulang; tidak ada
  endpoint baru atau duplikasi state hanya untuk kebutuhan visual.

## Secondary screens M6

- Performance, Analytics, Daily Summary, Trader Mirror, Mindset, dan layar
  keamanan profil memakai lebar konten responsif maksimal 720 px; formulir
  keamanan dibatasi 480 px.
- Literal UI pada Analytics, Daily Summary, Trader Mirror, dan pencarian Guide
  dipindahkan ke ARB Indonesia/English.
- Status tetap memiliki label teks, bukan hanya warna atau ikon.
- Tombol visibility pada security question memiliki tooltip aksesibilitas.

## QA parity M7

- Screenshot smoke test iOS Simulator tersimpan di
  `output/ui-parity/m7-ios-smoke.png`.
- Widget test secondary screens mencakup viewport 360×800 dan text scale 1.3.
- Localization test memastikan string ARB tersedia pada Indonesia dan English.
- Full analyzer dan regression test menjadi gate sebelum merge.

## Checklist QA M0–M2

- [ ] Tidak ada overflow pada lebar 360 px.
- [ ] Header tetap dapat digunakan pada text scale 1.3.
- [ ] Bottom navigation tidak tertutup gesture area.
- [ ] Avatar tanpa gambar menampilkan inisial.
- [ ] Ticker tidak tampil ketika quote belum tersedia.
- [ ] Badge notification menangani nilai 0 dan 9+.
- [ ] Light/dark theme memiliki hierarchy dan kontras yang benar.
- [ ] Seluruh font tersedia offline.
- [ ] `flutter analyze` lulus.
- [ ] `flutter test` lulus.

## Parity pass M8

Pass kedua ini menutup perbedaan yang masih terlihat ketika mobile web dan
Flutter dibandingkan halaman demi halaman.

| Area | Perbedaan sebelumnya | Perubahan M8 |
| --- | --- | --- |
| Footer global | Web menampilkan disclaimer dan tautan legal di setiap halaman, Flutter tidak punya footer | `widgets/app_footer.dart` dipakai di Dashboard, Analisis, Riwayat, Panduan, dan Profil |
| Navigasi bawah | Web punya tab Panduan, Flutter tidak | Tab Panduan ditambahkan (lihat M8b untuk susunan akhir tiga tab) |
| Panduan | Hanya dapat dibuka dari Profil dan detail analisis | Menjadi tab dengan judul, subjudul, filter kategori, dan empty state seperti `pages/guide.tsx` |
| Header Analisis | Judul saja | Judul web (`Analisis Baru`) plus chip progression dan chip kuota per jam/hari |
| Pemilih instrumen | Bottom sheet | Grid dua kolom dengan tiga kategori yang bisa dibuka-tutup, sama seperti `pages/analyze.tsx` |
| Header Riwayat | Judul saja | Judul web plus baris jumlah analisis |
| Profil | Switch tema dan tanpa peran | Segmented control Terang/Gelap dan badge peran seperti `pages/profile.tsx` |
| Dashboard | Nama pengguna dan badge mode | Label sambutan uppercase, nama, badge mode, dan tombol analisis baru |
| Top Up | Preset 50rb–500rb | Preset mengikuti web: 5.000, 10.000, 15.000, 20.000 |
| Price alert | Hanya judul AppBar | Judul dan subjudul halaman seperti `pages/my-alerts.tsx` |
| Ticker atas | Hanya harga, statis, warna surface | Marquee gelap berjalan dengan badge `LIVE QUOTE`, harga berpanah, badge `BREAKING NEWS`, dan headline `\/ticker-news` seperti `components/continuous-ticker.tsx` |
| Header | Bahasa, tema, alert, lonceng, avatar | Urutan web: bahasa, tema, avatar, lonceng; pintasan alert pindah ke Profil |
| Profil | Tidak ada entri price alert | Baris `Price Alert Saya` seperti `button-go-my-alerts` pada web |
| Login | Placeholder email | Label `Username / Email` dan placeholder web, string ARB disamakan |

### Penyesuaian lanjutan M8b

Tiga perbedaan yang sebelumnya ditunda ikut ditutup.

| Area | Web | Mobile sekarang |
| --- | --- | --- |
| Navigasi bawah | Tiga tab: Analisis, Riwayat, Panduan; profil pada avatar header | Sama persis. `AppBottomNav` menggantikan `NavigationBar` agar bisa tanpa tab aktif |
| Dashboard | Halaman `/dashboard`, tujuan setelah login, tanpa item navigasi | Tetap layar pertama setelah login, tanpa tab; dibuka lagi dari Profil |
| Profil | Dibuka dari avatar header, header memunculkan tombol kembali | Sama; avatar mendapat cincin aktif dan header memunculkan tombol kembali |
| Daftar instrumen | `VISIBLE_INSTRUMENTS`: XAU/USD, BRENT, NIKKEI, HSI | `MarketProvider.analyzeVisibleInstruments` dengan isi yang sama; hanya satu kategori terlihat sehingga tab kategori tidak dirender, sama seperti web |
| Instrumen bebas | Input teks `Instrumen lain…` yang dikirim apa adanya | Input yang sama; `selectInstrument(..., allowUnsupported: true)` menyimpan simbol tanpa memanggil endpoint market |

Daftar penuh 19 instrumen tetap dipakai untuk quote, watchlist, riwayat, dan
alert, sehingga data lama pengguna tidak hilang. Yang dipersempit hanya pemilih
pada layar Analisis, persis seperti allowlist web. Pintasan "market terakhir"
dan "market favorit" ikut disaring agar tidak menawarkan simbol tersembunyi.

Untuk simbol bebas, permintaan candle, teknikal, dan kalender dilewati karena
backend hanya menyediakan data untuk simbol yang didukung. Layar menampilkan
status kosong, bukan error, dan analisis tetap dikirim dengan simbol tersebut
seperti pada web.

### Perbedaan yang sengaja dipertahankan

- Dashboard tetap dapat dibuka dari Profil. Web hanya menyediakannya lewat URL,
  yang tidak punya padanan di aplikasi native.
- Footer dipasang pada lima tab utama, bukan pada setiap layar yang dibuka
  sebagai route native, agar layar detail tetap ringkas.
- Ticker berhenti bergerak dan dapat digeser manual ketika sistem meminta
  pengurangan animasi, sehingga marquee tidak memaksa gerakan terus-menerus.
- Fitur admin web tetap tidak dibawa ke mobile.
