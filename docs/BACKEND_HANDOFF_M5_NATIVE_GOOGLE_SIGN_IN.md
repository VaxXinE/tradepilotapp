# Backend Handoff — M5 Native Google Sign-In

**Project:** TradePilot Mobile 1.0.2
**Priority:** P1
**Owner utama:** Backend
**Status mobile:** BLOCKED
**Terakhir diverifikasi:** 8 September 2026

## 1. Tujuan

Dokumen ini mendefinisikan pekerjaan backend yang dibutuhkan agar aplikasi
Flutter dapat melakukan Google Sign-In native secara aman di Android dan iOS.

Mobile hanya akan memakai Google SDK untuk memperoleh **Google ID token**.
Backend tetap menjadi satu-satunya pihak yang:

- memverifikasi ID token;
- membuat atau menautkan akun TradePilot;
- menerbitkan session Bearer token TradePilot; dan
- mengotorisasi reauthentication untuk operasi sensitif.

Firebase Auth tidak dibutuhkan untuk rancangan ini.

## 2. Mengapa M5 belum dapat diimplementasikan di mobile

Hasil pemeriksaan kontrak dan source backend terbaru:

1. OpenAPI hanya menyediakan login email/password. Belum terdapat
   `POST /auth/google/native`.
2. Backend hanya mempunyai `GET /auth/google` dan
   `GET /auth/google/callback`. Keduanya merupakan browser redirect flow yang
   bergantung pada cookie dan tidak cocok untuk aplikasi native.
3. Respons `GET /auth/me` belum mempunyai field `hasPassword`. Mobile tidak
   dapat membedakan akun password, Google-only, dan akun yang pernah ditautkan.
4. Belum ada kontrak reauthentication Google untuk hapus akun atau operasi
   sensitif lainnya.
5. Dokumentasi backend saat ini juga secara eksplisit menyatakan bahwa Google
   Sign-In mobile belum didukung.

Tanpa endpoint native, mobile tidak memiliki tempat yang aman untuk menukar
Google ID token menjadi TradePilot Bearer token. Membuka flow web lewat WebView
bukan solusi: callback menghasilkan cookie browser, memperumit state/CSRF, dan
tidak memberi kontrak session native yang dapat diandalkan.

Karena alasan tersebut, mobile belum menambahkan tombol Google Sign-In maupun
dependency `google_sign_in`. Menampilkan tombol sebelum backend tersedia hanya
akan menghasilkan alur login yang selalu gagal.

## 3. Endpoint wajib

Path di bawah mengikuti path OpenAPI tanpa prefix deployment `/api`.

### 3.1 `POST /auth/google/native`

Menukar Google ID token valid menjadi session TradePilot.

Request:

```http
POST /api/auth/google/native
Content-Type: application/json
```

```json
{
  "idToken": "GOOGLE_ID_TOKEN"
}
```

Aturan request:

- body harus strict; field yang tidak dikenal ditolak;
- `idToken` wajib berupa string non-kosong;
- token tidak boleh ditulis ke application log, error tracker, atau analytics;
- jangan menerima `email`, `googleId`, `audience`, atau `emailVerified` dari
  client sebagai sumber kebenaran.

Respons sukses `200` menggunakan bentuk `AuthResponse` yang sama dengan login
normal:

```json
{
  "token": "TRADEPILOT_BEARER_TOKEN",
  "user": {
    "id": 123,
    "email": "user@example.com",
    "displayName": "Example User",
    "avatarUrl": null,
    "role": "user",
    "selectedMode": "beginner",
    "themePreference": "dark",
    "onboardingCompleted": false,
    "hasPassword": false,
    "createdAt": "2026-09-08T08:00:00.000Z"
  }
}
```

Persyaratan session:

- `token` harus berupa session token TradePilot, bukan Google access token atau
  Google ID token;
- session disimpan dan memiliki expiry seperti session login lainnya;
- login ulang tidak boleh membuat session tanpa batas; kebijakan jumlah
  session/cleanup harus sama dengan login password;
- endpoint native tidak boleh bergantung pada cookie agar berhasil;
- respons tidak boleh mengembalikan Google token, password hash, Google `sub`,
  atau credential internal lainnya.

### 3.2 `GET /auth/me`

Tambahkan field wajib berikut pada schema `User`:

```yaml
hasPassword:
  type: boolean
  description: True jika akun memiliki password lokal yang dapat dipakai untuk reauthentication.
```

Field ini harus ikut pada seluruh respons yang menggunakan schema `User`,
termasuk login, register, Google native login, dan session restore.

Jangan mengirim `passwordHash` atau `googleId` untuk memenuhi kebutuhan ini.

### 3.3 `POST /auth/reauth/google`

Operasi sensitif tidak boleh hanya mengandalkan session lama. Google-only user
harus dapat membuktikan identitas menggunakan Google ID token yang baru.

Request:

```http
POST /api/auth/reauth/google
Authorization: Bearer TRADEPILOT_BEARER_TOKEN
Content-Type: application/json
```

```json
{
  "idToken": "FRESH_GOOGLE_ID_TOKEN"
}
```

Respons sukses:

```json
{
  "reauthToken": "SHORT_LIVED_SINGLE_USE_TOKEN",
  "expiresAt": "2026-09-08T08:05:00.000Z"
}
```

Persyaratan `reauthToken`:

- acak secara kriptografis;
- disimpan dalam bentuk hash;
- berlaku maksimal 5 menit;
- hanya sekali pakai;
- terikat pada user dan tujuan operasi, misalnya `delete_account`;
- langsung dihapus/ditandai terpakai setelah operasi berhasil;
- tidak pernah dicatat ke log atau analytics.

Minimal untuk M5, `DELETE /auth/account` harus menerima bukti reauthentication:

- akun dengan `hasPassword=true`: password lama yang benar; atau
- akun Google-only: `reauthToken` yang masih valid.

Session aktif saja bukan bukti ulang yang cukup untuk menghapus akun
Google-only.

## 4. Verifikasi Google ID token

Backend wajib menggunakan library resmi/terawat untuk memverifikasi token,
bukan sekadar melakukan Base64 decode pada JWT.

Validasi minimum:

- signature cocok dengan Google public keys dan algoritma yang diizinkan;
- `iss` adalah issuer Google yang sah;
- `aud` termasuk OAuth client ID yang telah di-allowlist backend;
- `azp` ikut diperiksa ketika claim tersebut relevan;
- `exp` belum lewat dan `iat` masuk akal dengan toleransi clock skew kecil;
- `email_verified` bernilai `true`;
- `sub` tersedia dan dipakai sebagai identitas Google stabil;
- email dinormalisasi sesuai aturan akun TradePilot;
- token untuk project/client lain ditolak.

Daftar audience harus berasal dari konfigurasi server, bukan dari body request.
Contoh:

```text
GOOGLE_NATIVE_ALLOWED_CLIENT_IDS=<comma-separated Android/iOS/server client IDs>
```

OAuth **client ID bukan secret**, tetapi allowlist tetap harus dikelola melalui
konfigurasi deployment. OAuth web client secret hanya boleh berada di secret
manager backend dan tidak pernah dikirim ke mobile.

## 5. Aturan akun dan account linking

Gunakan aturan yang konsisten dengan web:

1. Cari berdasarkan Google `sub`/`googleId` terlebih dahulu.
2. Jika belum ada, cari akun berdasarkan **verified email**.
3. Jika verified email cocok dan akun belum tertaut ke identitas Google lain,
   tautkan Google `sub` tersebut.
4. Jika tidak ada akun, buat akun baru dengan default produk yang disepakati.
5. Jika email sudah tertaut ke Google `sub` berbeda, jangan overwrite;
   kembalikan conflict yang aman.

Implementasi harus memakai transaction dan database uniqueness constraint agar
dua request bersamaan tidak membuat akun ganda atau mengganti tautan akun.

Data seperti nama dan foto hanya boleh diambil dari claim Google yang sudah
terverifikasi. Jangan menaikkan role, mengubah mode, atau menimpa profil existing
berdasarkan data yang dikirim langsung oleh client.

## 6. Status dan format error

Gunakan format error API yang konsisten:

```json
{
  "error": "Login Google tidak dapat diverifikasi. Silakan coba lagi."
}
```

| Status | Kondisi |
| --- | --- |
| `400` | Body kosong, tipe salah, atau field tidak dikenal |
| `401` | Signature/issuer/audience salah, token expired, atau email belum verified |
| `401` | Reauthentication gagal atau `reauthToken` invalid/expired/used |
| `409` | Email sudah tertaut ke identitas Google lain |
| `429` | Rate limit; sertakan header `Retry-After` dalam detik |
| `500` | Kegagalan internal dengan pesan generik; jangan bocorkan detail token/library |

Jangan membuat pesan berbeda yang memungkinkan enumeration akun berdasarkan
email. Detail alasan validasi boleh masuk structured security log, tetapi token
mentah dan PII yang tidak diperlukan harus di-redact.

## 7. Rate limit dan audit keamanan

- Terapkan rate limit pada Google native login dan reauthentication.
- Catat hasil sukses/gagal, user ID jika sudah diketahui, waktu, serta kategori
  alasan yang aman; jangan catat token mentah.
- Kirim login/security notification memakai mekanisme yang sudah ada.
- Rotasi atau cabut session sesuai kebijakan ketika akun dihapus atau terjadi
  perubahan keamanan penting.
- Semua endpoint wajib HTTPS pada staging dan production.

## 8. Perubahan OpenAPI yang dibutuhkan

Tambahkan dan publikasikan:

- `POST /auth/google/native`, misalnya operation ID `loginWithGoogleNative`;
- `POST /auth/reauth/google`, misalnya operation ID
  `reauthenticateWithGoogle`;
- schema `GoogleNativeLoginBody`;
- schema `GoogleReauthBody`;
- schema `GoogleReauthResponse`;
- field wajib `User.hasPassword`;
- seluruh response sukses dan error, termasuk `429` dan header
  `Retry-After`.

Setelah OpenAPI diperbarui, kirim ke tim mobile:

1. file OpenAPI terbaru;
2. base URL staging;
3. OAuth client ID/audience publik yang harus dipakai Android dan iOS;
4. contoh respons akun baru, akun existing, dan akun Google-only;
5. contoh error invalid audience, expired token, unverified email, conflict,
   dan rate limit;
6. kontrak operasi sensitif yang memakai `reauthToken`.

Tim mobile akan regenerate Dart API client. Endpoint baru tidak akan ditulis
manual menggunakan raw Dio.

## 9. Konfigurasi platform yang perlu dikoordinasikan

Tim backend/Firebase/Google Cloud perlu memastikan tersedia:

- Android OAuth client untuk package `id.tradepilot.app`;
- SHA-1 dan SHA-256 untuk debug, release/upload, serta Play App Signing;
- iOS OAuth client untuk bundle ID `id.tradepilot.app`;
- reversed client ID untuk URL scheme iOS;
- server/web client ID jika dipakai sebagai `serverClientId`;
- seluruh client ID yang sah masuk allowlist audience backend.

Yang boleh diberikan ke tim mobile hanyalah file konfigurasi publik dan client
ID. Jangan pernah mengirim OAuth web client secret untuk dimasukkan ke Flutter,
APK, IPA, repository, atau CI artifact mobile.

## 10. Acceptance test backend

Semua test berikut harus lulus sebelum blocker mobile dibuka:

- [ ] ID token valid membuat akun baru dan mengembalikan `{user, token}`.
- [ ] Login berikutnya dengan Google `sub` yang sama memakai akun yang sama.
- [ ] Verified email menautkan akun password existing sesuai aturan.
- [ ] Request paralel tidak membuat user atau link ganda.
- [ ] Google `sub` berbeda tidak dapat mengambil alih link existing.
- [ ] Signature invalid ditolak.
- [ ] Issuer invalid ditolak.
- [ ] Audience/authorized party yang tidak di-allowlist ditolak.
- [ ] Token expired ditolak.
- [ ] `email_verified=false` ditolak.
- [ ] Field/token tambahan yang tidak sesuai schema ditolak.
- [ ] Rate limit mengembalikan `429` dan `Retry-After`.
- [ ] Seluruh response `User` mengandung nilai `hasPassword` yang benar.
- [ ] Google-only user tidak dapat memakai endpoint password/security question.
- [ ] Fresh Google ID token menghasilkan `reauthToken` berumur pendek.
- [ ] `reauthToken` milik user lain, expired, atau sudah dipakai ditolak.
- [ ] Hapus akun Google-only gagal tanpa reauthentication baru.
- [ ] Hapus akun berhasil dengan bukti reauthentication valid.
- [ ] Log dan error tracker tidak mengandung Google ID token, session token,
  OAuth client secret, atau `reauthToken`.

## 11. Definition of Ready untuk tim mobile

M5 siap dilanjutkan di Flutter setelah semua kondisi ini terpenuhi:

- [ ] Endpoint native dan reauthentication tersedia di staging.
- [ ] OpenAPI terbaru sudah memuat seluruh kontrak di atas.
- [ ] `User.hasPassword` tersedia dan konsisten pada semua auth response.
- [ ] Backend acceptance test lulus.
- [ ] Android/iOS OAuth client dan audience allowlist sudah dikonfigurasi.
- [ ] Tim mobile menerima test account dan langkah pengujian tanpa menerima
  secret backend apa pun.

Sesudah itu mobile dapat menambahkan `google_sign_in`, mengirim ID token hanya
ke backend, menyimpan hanya TradePilot Bearer token di secure storage,
menyembunyikan menu password untuk Google-only user, dan meminta
reauthentication sebelum operasi sensitif.
