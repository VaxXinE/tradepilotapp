# TradePilot Mobile UI Parity QA — M7

## Baseline

- Web: `Trade-Pilot`, branch `prodd-v2`, commit `403edd4`
- Flutter: branch `feat/1.0.2/web-mobile-ui-parity`
- Platform smoke test: iOS Simulator, iPhone 17 Pro Max
- Target layout test: 360×800 dengan text scale 1.3

## Hasil perbandingan

| Area | Referensi web | Hasil Flutter | Status |
| --- | --- | --- | --- |
| Design foundation | Inter, gold accent, dark/light surface, card 12 px | Token global dan font lokal digunakan | PASS |
| App shell | Header, ticker, floating navigation, safe area | Struktur dan hierarchy setara | PASS |
| Core journey | Auth card, Analyze, History, detail analysis | Pola kartu dan hierarchy diterapkan tanpa mengubah business logic | PASS |
| Financial flow | Quota, credit, top-up bertahap, status | Wizard dua langkah dan status transaksi tersedia | PASS |
| Supporting features | Profile, notifications, progression, guide, journal, alerts | Menggunakan foundation dan navigation native | PASS |
| Secondary screens | Performance, analytics, daily summary, mirror, mindset, security | Lebar responsif dan copy terlokalisasi | PASS |

## Bukti render

- `output/ui-parity/m7-ios-smoke.png`: hasil build dan render iOS Simulator.
- Tidak terlihat overflow, konten terpotong, atau benturan dengan safe area.
- Navigasi bawah tetap terbaca dan CTA utama memiliki hierarchy tertinggi.

## Accessibility dan responsive

- [x] Dashboard beradaptasi hingga text scale 2.0.
- [x] Secondary screens diuji pada 360×800 dan text scale 1.3.
- [x] Informasi status tidak bergantung pada warna saja.
- [x] Input rahasia memiliki kontrol visibility dan tooltip.
- [x] Scroll view menghormati safe area dan tetap dapat pull-to-refresh.
- [x] Konten dibatasi 720 px pada layar lebar; form sensitif 480 px.

## Localization

- [x] English dan Bahasa Indonesia berasal dari ARB.
- [x] Analytics tidak menampilkan literal Indonesia dalam mode English.
- [x] Daily Summary dan Trader Mirror memakai judul serta label lokal.
- [x] Guide search mengikuti locale aktif.
- [x] Kontrak nilai security question backend tetap dipertahankan; hanya label
  tampilan yang diterjemahkan.

## Gate sebelum merge

```bash
flutter gen-l10n
flutter analyze
flutter test
```

Build store tetap perlu smoke test terakhir pada perangkat Android kecil dan
iPhone fisik sebelum dipromosikan ke production.

## QA parity M8

Verifikasi dilakukan pada iOS Simulator iPhone 17 Pro Max dengan akun nyata,
membandingkan tiap tab terhadap mobile web `prodd-v2`.

| Bukti | Isi |
| --- | --- |
| `output/ui-parity/m8-dashboard.png` | Header sambutan, badge mode, tombol analisis baru, dan navigasi lima tab |
| `output/ui-parity/m8-analyze.png` | Judul `New Analysis`, chip progression, chip kuota, dan grid instrumen dengan kategori |
| `output/ui-parity/m8-guide.png` | Tab Panduan: judul, subjudul, pencarian, chip kategori, dan daftar artikel |
| `output/ui-parity/m8-profile.png` | Badge peran, segmented control tema, dan urutan header seperti web |

Gate yang dijalankan ulang setelah seluruh perubahan M8:

```bash
flutter gen-l10n
flutter analyze   # No issues found
flutter test      # All tests passed
```

Test baru: `test/widgets/app_footer_test.dart` dan
`test/screens/mindset/guide_tab_test.dart`. Test ticker pada
`test/widgets/app_shell_chrome_test.dart` diperbarui untuk marquee ganda.

Sisa perbedaan yang belum ditutup tercatat pada bagian "Perbedaan yang sengaja
dipertahankan" di `UI_PARITY_BASELINE_M0.md`.

## QA parity M8b

| Bukti | Isi |
| --- | --- |
| `output/ui-parity/m8b-analyze.png` | Navigasi tiga tab, grid instrumen empat simbol tanpa tab kategori, dan input `Other instrument…` |
| `output/ui-parity/m8b-dashboard.png` | Dashboard sebagai layar tanpa tab: tombol kembali pada header dan tidak ada item navigasi yang aktif |

Test tambahan:

- `test/providers/market_provider_test.dart` — allowlist instrumen Analisis dan
  perilaku simbol bebas (tidak memanggil endpoint market, flag ikut bersih saat
  kembali ke simbol yang didukung).
- `test/widgets/app_shell_chrome_test.dart` — navigasi tiga tab tanpa item aktif
  dan tombol kembali pada header.
