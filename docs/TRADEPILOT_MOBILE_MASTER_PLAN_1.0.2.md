# TradePilot Mobile Master Plan 1.0.2+

Dokumen ini menjadi sumber rencana utama untuk menyamakan aplikasi mobile dengan web terbaru pada branch backend/web `prodd-v2`. Fokus pekerjaan berikutnya adalah credit/top-up, penyelesaian native push, dan Google Sign-In native setelah kontrak backend tersedia.

## 1. Baseline

- Mobile branch: `feat/1.0.2/mobile-parity-and-push`
- Mobile baseline commit: `bb6ce35`
- Mobile version: `1.0.2+4`
- OpenAPI sumber kebenaran: `/Users/newsmaker23/flutterproject/major/Trade-Pilot/lib/api-spec/openapi.yaml`
- Status parity lama: sebagian besar fitur P0-P2 sebelumnya sudah tersedia.
- Fokus aktif: credit/top-up dan integrasinya dengan kuota analisis.

### Status

- `TODO`: belum dimulai.
- `BLOCKED`: menunggu perubahan atau konfigurasi pihak lain.
- `IN PROGRESS`: sedang dikerjakan.
- `DONE`: implementasi dan pengujian selesai.

## 2. Sasaran rilis

Rilis dianggap selesai jika pengguna dapat:

1. Melihat saldo credit.
2. Membuat permintaan top-up melalui QRIS beserta bukti pembayaran opsional.
3. Melihat riwayat dan status top-up.
4. Tetap membuat analisis dengan purchased credit saat kuota gratis habis.
5. Memahami kapan credit dipakai dan berapa saldo tersisa.
6. Menerima native push setelah konfigurasi backend selesai.
7. Login dengan Google secara native setelah endpoint backend tersedia.

## 3. Scope

### Termasuk

- Regenerasi dan re-vendor Dart API client.
- Credit balance, top-up QRIS, upload bukti, dan riwayat top-up.
- Integrasi credit dengan quota dan pembuatan analisis.
- Penanganan respons `429` yang jelas.
- Routing notifikasi top-up.
- Penyelesaian native push lintas mobile dan backend.
- Google Sign-In native setelah kontrak backend siap.
- Automated test dan regression test.

### Tidak termasuk

Fitur berikut tetap hanya untuk web/admin dan tidak boleh masuk ke aplikasi consumer:

- Admin dashboard.
- Review atau approval top-up.
- Pengaturan konfigurasi top-up.
- Statistik admin.
- Admin progression.
- User quota editor.
- Superadmin routes.

## 4. Urutan eksekusi

```text
M0 API contract
  -> M1 Credit data layer
    -> M2 Top-up experience
      -> M3 Quota & analysis integration
        -> M4 Notification & push closure
          -> M6 Release hardening

M5 Google Sign-In native berjalan terpisah setelah backend menyediakan endpoint.
```

Jangan mengerjakan UI credit sebelum generated client terbaru tervalidasi. Hal ini mencegah model manual berbeda dari kontrak backend.

## 5. Milestone M0 — Sinkronisasi API client

**Prioritas:** P0
**Status:** DONE
**Dependency:** OpenAPI backend terbaru

### Pekerjaan

- [x] Regenerate Dart client dari OpenAPI terbaru (openapi-generator 7.24.0, `dart-dio`).
- [x] Re-vendor generated client ke `packages/trade_pilot_api_client`.
- [x] Pastikan client menghasilkan:
  - [x] `TopupsApi`
  - [x] `TopupConfig`
  - [x] `CreditBalance`
  - [x] `CreateTopupRequestBody`
  - [x] `TopupRequest`
  - [x] `TopupRequestList`
  - [x] `AnalysisQuotaCredits`
  - [x] `CreateAnalysisResult`
  - [x] `creditConsumed`
  - [x] `creditBalance`
  - [x] `credits.balance` pada quota
- [x] Pastikan unregister native push tetap memakai:

```http
DELETE /native-push/unregister
```

- [x] Jalankan formatter, analyzer, dan seluruh client.
- [x] Pastikan tidak ada model API top-up yang ditulis manual dengan Dio mentah.

### Definition of Done

- Generated client cocok dengan OpenAPI terbaru.
- Semua existing caller berhasil dikompilasi.
- `flutter analyze` dan test generated client lulus.
- Tidak ada perubahan endpoint unregister menjadi `POST`.

### Catatan hasil re-vendor

`Analysis` sekarang non-instantiable (`@BuiltValue(instantiable: false)`) karena
`CreateAnalysisResult` mewarisinya lewat `allOf`; implementasi konkretnya adalah
`$Analysis`. Konsekuensinya:

- Deserialisasi lewat `Analysis.serializer` tetap bekerja seperti sebelumnya.
- Pembuatan objek manual (hanya di test) memakai `$Analysis(...)`.
- `AnalysisProvider.saveAnalysisNote` menormalkan `Analysis` apa pun ke
  `$Analysis` sebelum `rebuild`, supaya hasil `POST /analyses`
  (`CreateAnalysisResult`) tetap aman.

Deviasi yang disengaja terhadap output generator:

- Model dan operasi top-up khusus admin (`TopupRequestWithUser`,
  `TopupRequestWithUserList`, `TopupSummary`, `TopupUserSummary`,
  `ReviewTopupRequestBody`, `UpdateTopupConfigBody`, dan empat operasi
  `AdminApi` terkait) tidak ikut di-vendor, sesuai batasan scope pada bagian 3.
- Field `required` + `nullable: true` dipatch menjadi getter nullable, karena
  generator `dart-dio` 7.24.0 masih menghasilkan getter non-nullable dan gagal
  saat backend mengirim `null` (`TopupRequest`, `User.createdAt`,
  `JournalSentiment`, `Performance*`, `Fundamental*`, `AlertLevelRow`).
- `lib/trade_pilot_client.dart` adalah wrapper manual dan tetap dipertahankan.

Perbaikan yang ikut terbawa:

- `serializers.dart` sebelumnya kehilangan `..add(TopupRequest.serializer)`,
  sehingga `GET /topups/mine` gagal deserialisasi saat runtime.
- Model basi `ProgressionActivityInputProof` dihapus (sudah tidak ada di spec).
- Default builder `RegisterBody.selectedMode` diselaraskan ke `pro` sesuai spec.

## 6. Milestone M1 — Credit data layer

**Prioritas:** P0
**Status:** DONE
**Dependency:** M0

### Pekerjaan

- [x] Tambahkan state provider/repository tipis yang memakai `TopupsApi`.
- [x] Implementasikan:
  - [x] `GET /topups/config`
  - [x] `GET /topups/balance`
  - [x] `POST /topups`
  - [x] `GET /topups/mine`
- [x] Gunakan mekanisme auth dan penanganan `401` yang sudah ada.
- [x] Simpan hanya state UI yang diperlukan; saldo backend tetap menjadi sumber kebenaran.
- [x] Pisahkan loading/error saldo dari loading/error halaman Profile.
- [x] Dukung refresh dan pagination riwayat dengan batas 20 item per halaman.

### Definition of Done

- Seluruh operasi credit menggunakan typed client.
- Error jaringan, `401`, validasi `4xx`, dan `5xx` menghasilkan state yang dapat dipulihkan.
- Refresh tidak menggandakan item riwayat.

### Hasil implementasi

Berkas baru:

- `lib/repositories/topup_repository.dart` — pembungkus tipis `TopupsApi`, tanpa
  state. Hanya memvalidasi nominal dan merapikan string opsional sebelum
  request.
- `lib/providers/credit_provider.dart` — `ChangeNotifier` untuk saldo, config,
  riwayat, dan pembuatan top-up.
- `lib/main.dart` — `CreditProvider` didaftarkan sebagai
  `ChangeNotifierProxyProvider<AuthProvider, CreditProvider>`.

Catatan desain:

- Saldo, config, dan riwayat punya flag loading serta error terpisah. Karena
  `CreditProvider` berdiri sendiri di luar `AuthProvider`, kegagalan
  `GET /topups/balance` tidak bisa menyentuh state halaman Profile.
- `401` tetap ditangani interceptor bersama di `AuthProvider` yang menutup sesi;
  provider ini hanya menerjemahkan errornya untuk layar.
- Pesan validasi `4xx` dari backend diteruskan apa adanya (nominal minimum
  ditentukan backend), sedangkan detail `5xx` diganti pesan generik supaya
  internal server tidak bocor ke layar atau analytics.
- Riwayat digabung berdasarkan `id` dan diurutkan `createdAt` menurun, jadi
  refresh maupun `loadMore` tidak pernah menggandakan item.
- `submitTopup` menolak pemanggilan kedua selama request pertama berjalan, jadi
  double tap hanya menghasilkan satu `POST /topups`.
- Saldo di-prefetch sekali saat sesi login aktif, supaya badge Profile pada M2
  tidak perlu memicu load sendiri.

Test: `test/providers/credit_provider_test.dart` (13 test) menutup keempat
endpoint, pagination 20 item, refresh tanpa duplikasi, double submit, validasi
`4xx`, `5xx` tanpa bocor internal, kegagalan jaringan dan pemulihannya, isolasi
error saldo, serta pembersihan state saat logout.

## 7. Milestone M2 — Top-up experience

**Prioritas:** P0
**Status:** DONE
**Dependency:** M1

### 7.1 Halaman Top Up Credit

- [x] Tampilkan saldo credit terbaru.
- [x] Tampilkan gambar QRIS dari backend.
- [x] Tampilkan harga Rupiah per credit.
- [x] Sediakan input nominal Rupiah.
- [x] Tampilkan preview jumlah credit.
- [x] Sediakan catatan/reference pembayaran opsional.
- [x] Sediakan bukti pembayaran opsional dan preview gambar.
- [x] Sediakan tombol kirim dengan proteksi double-submit.
- [x] Tampilkan loading, empty, error, dan retry state.
- [x] Tampilkan riwayat top-up.
- [x] Tampilkan status `pending`, `approved`, dan `rejected`.
- [x] Tampilkan review note admin jika tersedia.
- [x] Sediakan pull-to-refresh dan pagination.

### 7.2 Upload bukti pembayaran

Gunakan alur signed upload yang sudah dipakai upload avatar:

```text
POST /storage/uploads/request-url
PUT  binary gambar ke signed URL
POST /topups dengan proofObjectPath
```

- [x] Reuse `image_picker` dan helper signed upload yang sudah ada.
- [x] Izinkan JPG, PNG, WebP, atau GIF saja.
- [x] Batasi ukuran file maksimal 5 MB sebelum upload.
- [x] Kirim object path, bukan signed URL, sebagai `proofObjectPath`.
- [x] Jangan mencatat signed URL atau query string ke log/error analytics.
- [x] Jangan menyimpan bukti pembayaran di storage publik.
- [x] Tampilkan kegagalan upload tanpa membuat top-up setengah terkirim.

### 7.3 Profile

- [x] Tambahkan menu `Top Up Credit` dan badge saldo.
- [x] Tap membuka halaman Top Up.
- [x] Error saldo tidak merusak menu Profile lain.
- [x] Saldo dapat di-refresh setelah approval atau pemakaian credit.

### Definition of Done

- Pengguna dapat menyelesaikan top-up dengan dan tanpa bukti pembayaran.
- Validasi nominal mengikuti konfigurasi backend.
- Double tap tidak membuat request ganda.
- Riwayat dan status sesuai respons backend.
- Tidak ada signed URL atau credential di log.

### Hasil implementasi

Berkas baru:

- `lib/core/storage/signed_upload.dart` — helper signed upload bersama.
- `lib/screens/topup/topup_screen.dart` — halaman Top Up Credit.
- 29 kunci l10n baru pada `app_en.arb` dan `app_id.arb`.

Berkas yang berubah:

- `lib/screens/home/tabs/profile_tab.dart` — menu `Top Up Credit` + badge saldo.
- `lib/screens/profile/edit_profile_screen.dart` — upload avatar sekarang
  memakai helper bersama.

Catatan desain:

- Sebelumnya tidak ada helper signed upload yang bisa dipakai ulang: alur avatar
  menuliskan aturan MIME, batas 5 MB, dan PUT-nya sendiri di dalam screen.
  Aturan itu dipindahkan ke `SignedUploadService`, lalu alur avatar diarahkan ke
  sana. Jadi hanya ada satu tempat yang menentukan format dan batas ukuran.
- `SignedUploadException` sengaja tidak menyimpan `DioException` aslinya.
  `DioException` membawa `requestOptions.uri`, yaitu signed URL lengkap dengan
  query string kredensialnya; menyimpannya membuat signed URL ikut muncul pada
  `toString()`, log, dan error analytics. Ada test yang memastikan pesan error
  tidak mengandung host, `X-Goog-Signature`, maupun `X-Goog-Credential`.
- PUT ke storage memakai `Dio` terpisah tanpa interceptor apa pun, supaya bearer
  token TradePilot tidak pernah ikut ke host storage. Yang diwarisi hanya
  `httpClientAdapter`-nya, supaya transport-nya tetap bisa diganti pada test.
- Upload bukti dijalankan sebelum `POST /topups`. Kalau upload gagal, top-up
  tidak dikirim sama sekali dan bukti yang sudah dipilih tetap dipertahankan
  supaya pengguna cukup mencoba ulang.
- Validasi nominal memakai `rupiahPerCredit` dari `GET /topups/config` sebagai
  minimum, sementara pesan validasi `4xx` dari backend tetap yang menang.
- Proteksi double-submit ada di dua lapis: tombol dinonaktifkan selama sibuk,
  dan `_submit` menolak pemanggilan ulang selama upload atau submit berjalan.

Test: `test/core/storage/signed_upload_test.dart` (6 test) dan
`test/screens/topup/topup_screen_test.dart` (12 test), ditambah asersi menu
`Top Up Credit` pada `test/screens/profile/profile_screens_test.dart`.

### Catatan lanjutan

Pesan error yang berasal dari provider ditulis dalam bahasa Indonesia, mengikuti
konvensi seluruh provider yang sudah ada, sedangkan teks layar memakai l10n.
Pada mode bahasa Inggris hal ini membuat pesan error tampil campur. Ini kondisi
lama yang berlaku untuk semua layar, bukan regresi dari M2, dan sebaiknya
dibereskan tersendiri kalau memang mau dilokalkan.

## 8. Milestone M3 — Kuota dan analisis

**Prioritas:** P0
**Status:** DONE
**Dependency:** M1 dan M2

### 8.1 Tampilan quota

- [x] Tampilkan sisa kuota per jam.
- [x] Tampilkan sisa kuota harian.
- [x] Tampilkan purchased credit balance.
- [x] Jangan menonaktifkan tombol analisis jika kuota gratis habis tetapi credit
  masih tersedia.
- [x] Refresh quota setelah analisis selesai.
- [x] Refresh credit balance setelah credit dipakai.

### 8.2 Respons `429`

Tangani scope:

- `hour`
- `day`
- `concurrent`

- [x] Judul dan pesan mengikuti scope.
- [x] Tampilkan progress `used / limit` jika tersedia.
- [x] Sediakan tombol tutup.
- [x] Sediakan tombol `Top Up Credit` untuk limit harian.
- [x] Hormati header `Retry-After`.
- [x] Jangan melakukan retry otomatis agresif.
- [x] Sediakan fallback aman jika payload quota tidak lengkap.

### 8.3 Credit consumption

Respons `POST /analyses` terbaru menggunakan `CreateAnalysisResult`:

```json
{
  "creditConsumed": true,
  "creditBalance": 9
}
```

- [x] Jika `creditConsumed=true`, tampilkan bahwa satu credit dipakai.
- [x] Tampilkan saldo tersisa.
- [x] Buka hasil analisis seperti biasa.
- [x] Jangan memperlakukan pemakaian credit sebagai error.
- [x] Refresh quota dan saldo setelah respons sukses.

### Definition of Done

- Analisis gratis dan analisis memakai credit sama-sama berhasil.
- Tidak terjadi debit credit ganda akibat retry dari client.
- UI tetap konsisten jika refresh saldo gagal setelah analisis sukses.
- Semua scope `429` teruji.

### Hasil implementasi

- Ringkasan pada layar analisis menampilkan kuota per jam, kuota harian, dan
  purchased credit; dashboard juga menampilkan saldo purchased credit.
- `AnalysisProvider` membaca hasil `CreateAnalysisResult`, menyimpan informasi
  pemakaian credit, dan me-refresh history, summary, serta quota di background.
- Respons `429` diterjemahkan menjadi dialog sesuai scope `hour`, `day`, atau
  `concurrent`, termasuk progress dan `Retry-After`. CTA `Top Up Credit` hanya
  muncul pada limit harian.
- Request `POST /analyses` tetap dilindungi oleh `isSubmitting` dan tidak
  di-retry otomatis. Timeout hanya memicu sinkronisasi `GET` di background,
  sehingga client tidak berisiko mendebit credit dua kali.
- Jika saldo tidak ikut dalam respons sukses, UI tidak menampilkan saldo nol
  yang menyesatkan; saldo ditandai sedang diperbarui sementara hasil analisis
  tetap dibuka.

Test provider memverifikasi ketiga scope `429`, `Retry-After`, hanya satu
request analisis, serta hasil sukses yang memakai credit. Widget test
memverifikasi judul dan aksi dialog ketiga scope. Seluruh 218 test project
lulus dan `flutter analyze` bersih.

## 9. Milestone M4 — Notifikasi dan native push

**Prioritas:** P1
**Status:** BLOCKED — menunggu deployment backend
**Dependency:** Backend/DevOps

### Backend/DevOps

- [ ] Set `FIREBASE_PROJECT_ID=trade-pilot-newsmaker23`.
- [ ] Sediakan Application Default Credentials melalui secret manager.
- [ ] Aktifkan FCM HTTP v1 API.
- [ ] Berikan permission minimum yang diperlukan untuk mengirim FCM.
- [ ] Konfigurasikan APNs key untuk iOS.
- [ ] Sediakan jalur test native push; endpoint test Web Push tidak cukup.
- [ ] Pastikan payload kategori mendukung filter preferensi mobile.

### Mobile

- [ ] Pastikan token register/unregister tetap bekerja.
- [ ] Tampilkan notifikasi hasil top-up pada notification feed.
- [ ] Tampilkan status dan review note.
- [ ] Tambahkan routing ke detail/top-up jika payload memiliki target yang valid.
- [ ] Abaikan target yang tidak dikenal dengan aman.
- [ ] Retest foreground, background, dan terminated.
- [ ] Retest quiet hours dan filter kategori.

### Definition of Done

- Push nyata diterima pada Android dan iOS physical device.
- Tap notifikasi membuka layar yang benar tanpa melewati autentikasi.
- Quiet hours dan kategori dihormati backend.
- Token invalid dibersihkan tanpa retry loop.

## 10. Milestone M5 — Google Sign-In native

**Prioritas:** P1
**Status:** BLOCKED — menunggu endpoint dan kontrak backend
**Dependency:** `POST /auth/google/native` dan field profile `hasPassword`

Handoff backend: [`BACKEND_HANDOFF_M5_NATIVE_GOOGLE_SIGN_IN.md`](BACKEND_HANDOFF_M5_NATIVE_GOOGLE_SIGN_IN.md)

### Backend

- [ ] Sediakan `POST /auth/google/native`.
- [ ] Verifikasi signature, issuer, audience, expiry, dan `email_verified` ID token.
- [ ] Kembalikan TradePilot Bearer token dan user profile.
- [ ] Definisikan aturan akun baru, akun existing, dan linking berdasarkan verified email.
- [ ] Tambahkan `hasPassword` pada profile/session response.
- [ ] Sediakan mekanisme reauthentication untuk operasi sensitif.

### Mobile setelah backend siap

- [ ] Tambahkan `google_sign_in` saja; jangan gunakan Firebase Auth jika backend hanya memerlukan Google ID token.
- [ ] Konfigurasikan Android OAuth Client ID dan SHA-1/SHA-256 debug/release.
- [ ] Konfigurasikan iOS OAuth Client ID dan reversed client ID URL scheme.
- [ ] Kirim Google ID token hanya ke endpoint native backend.
- [ ] Simpan hanya TradePilot Bearer token di secure storage.
- [ ] Tangani invalid token, expired token, audience mismatch, dan email belum diverifikasi.
- [ ] Sembunyikan ganti password/security question pada akun Google-only.
- [ ] Gunakan reauthentication sebelum hapus akun atau operasi sensitif.

### Larangan security

- Jangan membuka `GET /auth/google` melalui WebView.
- Jangan membundel `OAuth google.json` ke Flutter atau Git.
- Jangan menaruh web client secret di `firebase_options.dart`, assets, source code, atau log.

### Definition of Done

- Login akun baru dan existing berhasil di Android dan iOS.
- Akun Google-only tidak mendapat alur password yang tidak relevan.
- Operasi sensitif meminta verifikasi ulang.
- Secret tidak terdapat di APK/IPA maupun repository.

## 11. Milestone M6 — Quality gate dan release

**Prioritas:** P0 untuk fitur credit, P1 untuk fitur terblokir
**Status:** TODO
**Dependency:** Milestone yang masuk ke release

### Automated checks

- [ ] `dart format --output=none --set-exit-if-changed .`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Test parsing seluruh model baru.
- [ ] Test provider/repository success dan error.
- [ ] Widget test validasi top-up dan status history.
- [ ] Widget test dialog quota untuk `hour`, `day`, dan `concurrent`.
- [ ] Test `creditConsumed=true/false`.
- [ ] Test notification deep-link dengan target valid dan invalid.

### Manual regression

- [ ] Login/logout dan session expiry.
- [ ] Profile tetap dapat dibuka saat endpoint balance gagal.
- [ ] Top-up tanpa bukti.
- [ ] Top-up dengan bukti valid.
- [ ] Tolak format atau file lebih dari 5 MB.
- [ ] Double tap submit hanya membuat satu request.
- [ ] Riwayat lebih dari 20 item dapat dipaginasi tanpa duplikasi.
- [ ] Status pending/approved/rejected dan review note tampil benar.
- [ ] Analisis dengan quota gratis.
- [ ] Analisis dengan purchased credit.
- [ ] Semua scope `429`.
- [ ] Offline, timeout, dan recovery setelah koneksi kembali.
- [ ] Push foreground/background/terminated pada physical device.
- [ ] Android release build dan iOS archive.

### Release gate

- [ ] Tidak ada secret, token, signed URL, atau bukti pembayaran di log.
- [ ] Tidak ada endpoint admin di navigasi atau client consumer yang dipakai UI.
- [ ] Privacy manifest iOS dan backup policy Android tetap lulus.
- [ ] Version/build number dinaikkan.
- [ ] Changelog dan release notes tersedia.
- [ ] Branch rilis hanya dibuat setelah semua P0 berstatus `DONE`.

## 12. Test case minimum

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| CR-01 | Buka Profile | Saldo tampil tanpa memblokir menu lain |
| CR-02 | Endpoint saldo gagal | Menu lain tetap berfungsi dan tersedia retry |
| TU-01 | Top-up nominal valid tanpa bukti | Request dibuat sekali dengan status pending |
| TU-02 | Top-up dengan bukti valid | Object path tersimpan; signed URL tidak dikirim |
| TU-03 | Bukti lebih dari 5 MB/format salah | Ditolak sebelum upload |
| TU-04 | Double tap submit | Hanya satu request dibuat |
| TU-05 | Riwayat lebih dari 20 item | Pagination tanpa duplikasi |
| QU-01 | Kuota gratis tersedia | Analisis tidak memakai credit |
| QU-02 | Kuota gratis habis, credit tersedia | Analisis berhasil dan saldo berkurang satu |
| QU-03 | Limit harian tanpa credit | Dialog memberi CTA Top Up |
| QU-04 | Limit per jam | Dialog mengikuti `Retry-After` |
| QU-05 | Analisis concurrent | Tidak ada retry loop otomatis |
| NP-01 | Push foreground | Notifikasi tampil sesuai kebijakan aplikasi |
| NP-02 | Push background | Notifikasi diterima dan tap membuka target |
| NP-03 | Push terminated | App membuka target setelah autentikasi valid |
| GS-01 | Google akun baru | Akun dan session TradePilot dibuat |
| GS-02 | Google akun existing | Akun ditautkan sesuai aturan backend |
| GS-03 | Google token invalid | Login ditolak tanpa membocorkan detail sensitif |

## 13. Risiko dan mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Generated client tidak sinkron | Runtime parsing/error compile | OpenAPI menjadi sumber tunggal; codegen lebih dulu |
| Request top-up ganda | Beban review dan potensi salah credit | Disable submit saat loading dan backend idempotency bila tersedia |
| Signed URL bocor | Bukti pembayaran dapat diakses pihak lain | Redaksi log dan simpan object path saja |
| Credit terdebit tetapi UI gagal refresh | Pengguna melihat saldo lama | Analisis tetap sukses; refresh terpisah dan sediakan retry |
| FCM hanya diuji via Web Push | False positive integrasi | Test native FCM pada physical device |
| OAuth web secret masuk aplikasi | Credential compromise | Secret hanya di backend secret manager; audit APK/IPA |
| Deep-link melewati auth | Akses layar tanpa session valid | Semua routing melewati auth gate |

## 14. Strategi branch dan commit

Gunakan perubahan kecil yang dapat diuji secara terpisah:

```text
feat/1.0.2/credit-topup
```

Urutan commit yang disarankan:

1. `chore(api): regenerate client for credit and topup endpoints`
2. `feat(credit): add balance and topup data flow`
3. `feat(topup): add QRIS request and payment proof flow`
4. `feat(profile): show credit balance and topup entry`
5. `feat(analysis): support credit quota and consumption feedback`
6. `feat(notifications): route topup status updates`
7. `test(mobile): cover credit topup and quota flows`

Google Sign-In dibuat pada branch terpisah setelah backend selesai:

```text
feat/1.0.2/google-sign-in-native
```

## 15. Checklist koordinasi backend

- [ ] Konfirmasi OpenAPI terbaru dan response contoh untuk seluruh endpoint top-up.
- [ ] Konfirmasi aturan nominal minimum/maksimum dan pembulatan credit.
- [ ] Konfirmasi MIME type dan batas ukuran bukti pembayaran.
- [ ] Konfirmasi idempotency pembuatan top-up dan analisis berbayar.
- [ ] Konfirmasi payload `429` dan `Retry-After` untuk setiap scope.
- [ ] Konfirmasi payload notifikasi approved/rejected.
- [ ] Selesaikan konfigurasi native FCM production/staging.
- [ ] Sediakan endpoint Google native dan field `hasPassword` sebelum pekerjaan mobile dimulai.

## 16. Kriteria selesai keseluruhan

Master plan selesai ketika:

- Seluruh item P0 berstatus `DONE` dan lulus quality gate.
- Tidak ada model top-up manual di luar generated client.
- Alur top-up dan pemakaian credit berhasil end-to-end di staging.
- Native push berhasil pada Android dan iOS physical device.
- Item Google Sign-In tetap `BLOCKED` secara eksplisit atau selesai setelah kontrak backend tersedia.
- Tidak ada fitur admin atau secret backend yang masuk ke aplikasi consumer.
