# Handoff Native Push (FCM) + Preference Contract

> **KEPUTUSAN 7 September 2026: AKTIFKAN KEMBALI FCM.** Backend native push
> sudah live dan integrasi Flutter sudah dipasang. Validasi terakhir tetap
> membutuhkan perangkat fisik serta kredensial APNs milik pemilik akun.

Dokumen awal dibuat dari audit repo web dan implementasi Flutter. Status di
bagian awal ini sudah diperbarui sesuai kondisi backend dan mobile terkini.

## Status terkini

Target konfigurasi yang benar:

```text
Project ID: trade-pilot-newsmaker23
Android:    id.tradepilot.app
iOS:        id.tradepilot.app
```

Konfigurasi Firebase lama memakai `com.tradepilot.app`. Jangan mengambil ulang
`google-services.json`, `GoogleService-Info.plist`, atau
`firebase_options.dart` lama dari riwayat Git karena ketiganya terikat ke ID
aplikasi yang salah.

Backend sudah memiliki:

- authenticated `POST /api/native-push/register`;
- authenticated `DELETE /api/native-push/unregister`;
- registry device dan sender FCM;
- preference `nativePushEnabled` serta field notification generasi baru.

Mobile sekarang memakai method typed untuk kedua endpoint tersebut dan sudah
memiliki Firebase initialization, permission OS, token lifecycle, foreground
notification, handler tap yang di-allowlist, ownership check untuk analisis,
serta unregister sebelum logout.

## Tutorial pemilik akun: siapkan Firebase dan APNs

### 1. Verifikasi identifier produksi

Jalankan dari root project Flutter:

```bash
rg 'applicationId|PRODUCT_BUNDLE_IDENTIFIER' \
  android/app/build.gradle.kts ios/Runner.xcodeproj/project.pbxproj
```

Android dan target Runner iOS harus menunjukkan `id.tradepilot.app`.

### 2. Daftarkan aplikasi Android dan iOS di Firebase

1. Buka Firebase Console → project `trade-pilot-newsmaker23` → Project
   settings → General.
2. Tambahkan Android app dengan package name **`id.tradepilot.app`**.
3. Unduh `google-services.json`, lalu simpan tepat di
   `android/app/google-services.json`.
4. Tambahkan Apple app dengan bundle ID **`id.tradepilot.app`**.
5. Unduh `GoogleService-Info.plist`, lalu simpan tepat di
   `ios/Runner/GoogleService-Info.plist`.

Jangan mengubah package/bundle ID aplikasi agar cocok dengan konfigurasi lama.
Konfigurasi Firebase harus mengikuti identifier aplikasi yang sudah dirilis.

### 3. Jalankan FlutterFire CLI

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Saat diminta:

- pilih project `trade-pilot-newsmaker23`;
- pilih platform Android dan iOS saja;
- cocokkan keduanya dengan app `id.tradepilot.app` yang baru dibuat;
- izinkan CLI membuat `lib/firebase_options.dart`.

Setelah selesai, pastikan tiga file berikut ada:

```text
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart
```

### 4. Aktifkan APNs untuk iOS

1. Buka Apple Developer → Certificates, Identifiers & Profiles → Identifiers.
2. Pilih App ID `id.tradepilot.app`, lalu aktifkan capability Push
   Notifications.
3. Buka Keys → tombol `+`, buat key dengan capability Apple Push
   Notifications service (APNs), lalu unduh file `.p8`.
4. Catat **Key ID** dan **Team ID**. File `.p8` hanya dapat diunduh sekali.
5. Buka Firebase Console → Project settings → Cloud Messaging → Apple app
   configuration → APNs Authentication Key.
6. Upload `.p8`, lalu isi Key ID dan Team ID.
7. Di Xcode target Runner → Signing & Capabilities, tambahkan **Push
   Notifications** dan **Background Modes → Remote notifications**.

Jangan pernah memasukkan `.p8`, service-account JSON, private key, atau token
FCM lengkap ke Git, Flutter assets, screenshot, log, maupun chat. Simpan `.p8`
di password manager/secret manager organisasi.

### 5. Validasi implementasi Flutter

Setelah langkah 1-4 selesai, uji pada perangkat fisik Android dan iPhone:

- login lalu aktifkan `Mobile Push` pada halaman Notifikasi;
- pastikan backend menerima satu registrasi token untuk user tersebut;
- kirim notifikasi saat app foreground, background, dan terminated;
- tap notifikasi analisis dan pastikan hanya analisis milik user yang terbuka;
- logout dan pastikan token perangkat dihapus dari registry backend.

## Catatan historis implementasi backend

Bagian B3/B4.1 di bawah dipertahankan sebagai referensi desain. Endpoint dan
contract-nya sekarang sudah live; jangan mengimplementasikannya ulang.

### Temuan baseline lama

Jangan membuat ulang fitur yang sudah ada:

- preferensi sudah disimpan sebagai kolom pada `users`;
- `GET/PATCH /push/prefs` dan schema `PushPrefs` sudah digunakan web + Flutter;
- `notifications.category` dan `notifications.dedupe_key` sudah ada;
- `notification-guards.ts` sudah menyediakan quiet-hour, frequency cap,
  dedupe, dan grouping helper;
- kategori existing meliputi `market_news`, `calendar_event`,
  `price_anomaly`, `signal_flip`, `weekly_recap`, `market_open`,
  `dormancy_nudge`, `onboarding`, dan `trader_mirror_report`.

Masalah kontrak yang masih ada pada baseline tersebut:

- B2 `actionType`/`actionId` belum ada di schema backend/OpenAPI;
- `GET /notifications` belum menghitung/mengembalikan `unreadCount`, walaupun
  OpenAPI sudah mendeklarasikannya;
- `category` belum diekspos pada schema OpenAPI `Notification`;
- native device registry dan FCM sender belum ada.

Karena itu rollout wajib: **B2 backend → B3 backend → B4.1**.

---

# P2-B3 — Backend Native Push

## 1. Database

File: `lib/db/src/schema/index.ts`

Tambahkan tabel terpisah dari Web Push:

```ts
export const nativePushDevices = pgTable(
  "native_push_devices",
  {
    id: serial("id").primaryKey(),
    userId: integer("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    token: text("token").notNull(),
    platform: text("platform").notNull(),
    enabled: boolean("enabled").notNull().default(true),
    lastSeenAt: timestamp("last_seen_at").defaultNow().notNull(),
    createdAt: timestamp("created_at").defaultNow().notNull(),
    updatedAt: timestamp("updated_at").defaultNow().notNull(),
  },
  (table) => ({
    tokenUnique: uniqueIndex("native_push_devices_token_unique").on(
      table.token,
    ),
  }),
);
```

`token` unik global karena satu token FCM aktif hanya boleh dimiliki satu user.
Upsert harus memindahkan ownership token ketika device login ke account lain.

Jangan menjalankan DB push sebelum `DATABASE_URL` target diverifikasi:

```bash
pnpm --filter @workspace/db push
```

## 2. API contract

Tambahkan ke `lib/api-spec/openapi.yaml`:

```yaml
/native-push/register:
  post:
    operationId: registerNativePushDevice
    tags: [Native Push]
    requestBody:
      required: true
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/NativePushRegisterBody"
    responses:
      "201":
        description: Device registered
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/MessageResponse"

/native-push/unregister:
  delete:
    operationId: unregisterNativePushDevice
    tags: [Native Push]
    requestBody:
      required: true
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/NativePushUnregisterBody"
    responses:
      "200":
        description: Device unregistered
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/MessageResponse"

NativePushRegisterBody:
  type: object
  properties:
    token:
      type: string
      minLength: 20
      maxLength: 4096
    platform:
      type: string
      enum: [android, ios]
  required: [token, platform]

NativePushUnregisterBody:
  type: object
  properties:
    token:
      type: string
      minLength: 20
      maxLength: 4096
  required: [token]
```

Route wajib memakai `requireAuth`. Unregister wajib memfilter kombinasi
`userId AND token`, bukan token saja.

## 3. FCM HTTP v1 sender

Gunakan `google-auth-library` yang sudah ada; jangan menambahkan Firebase Admin
SDK hanya untuk satu endpoint.

Environment production:

```text
FIREBASE_PROJECT_ID=trade-pilot-newsmaker23
```

Gunakan Application Default Credentials. Untuk local-only boleh memakai
`GOOGLE_APPLICATION_CREDENTIALS` yang menunjuk file di luar repo.

Sender wajib:

- meminta OAuth scope `https://www.googleapis.com/auth/firebase.messaging`;
- mengirim ke FCM HTTP v1 `/v1/projects/{projectId}/messages:send`;
- mengirim `actionType`, `actionId`, dan `notificationId` sebagai string pada
  payload `data`;
- memakai channel Android `trade_pilot_alerts`;
- memakai APNs sound default dan `content-available: 1`;
- menghapus token `UNREGISTERED`/404;
- tidak pernah log token lengkap—maksimum suffix 8 karakter;
- tidak membuat kegagalan push menggagalkan insert notification/API utama.

`createNotification()` harus menangkap ID row dari `.returning()` tanpa
mengubah return contract boolean existing, lalu mengirim Web Push dan Native
Push berdampingan. Bulk insert juga harus memasangkan notification ID dengan
user yang benar.

## 4. Manual Firebase/Apple step

Masih harus dilakukan oleh pemilik Apple Developer account:

```text
Firebase Console
→ Project Settings
→ Cloud Messaging
→ Apple app configuration
→ upload APNs Authentication Key (.p8 + Key ID + Team ID)
```

`.p8` dan service-account JSON tidak boleh masuk Git, Flutter assets, image
Docker, log, atau chat.

---

# P2-B4.1 — Notification Preference Schema + API Contract

## Keputusan kompatibilitas

**Jangan buat tabel `notification_preferences` baru sekarang.** Branch `prod`
sudah menyimpan seluruh preference pada `users` dan semua client memakai
`GET/PATCH /push/prefs`. Tabel baru akan memerlukan migrasi data, dual-read,
dan perubahan banyak job tanpa memberi manfaat untuk relasi one-to-one ini.

Tambahkan hanya kolom yang belum terwakili:

```ts
pushAnalysisCompleted: boolean("push_analysis_completed")
  .notNull()
  .default(true),
pushTpSlHit: boolean("push_tp_sl_hit").notNull().default(true),
pushLoginAlert: boolean("push_login_alert").notNull().default(true),
nativePushEnabled: boolean("native_push_enabled").notNull().default(true),
webPushEnabled: boolean("web_push_enabled").notNull().default(true),
quietHoursEnabled: boolean("quiet_hours_enabled").notNull().default(true),
quietHoursStart: text("quiet_hours_start").notNull().default("22:00"),
quietHoursEnd: text("quiet_hours_end").notNull().default("07:00"),
notificationTimezone: text("notification_timezone")
  .notNull()
  .default("Asia/Jakarta"),
```

Mapping fitur existing:

```text
Signal BUY/SELL       → pushSignalFlip
Market news          → pushMarketNews
Economic warning     → pushCalendarEvents
Price warning        → pushPriceAnomaly
Web Push channel     → webPushEnabled
Mobile Push channel  → nativePushEnabled
```

Email belum memiliki sender, jadi `emailEnabled` sengaja tidak ditambahkan.
Tambahkan saat email delivery benar-benar diimplementasikan.

Security alert kritis tidak boleh bisa dimatikan. `pushLoginAlert` boleh
dikontrol user, tetapi password/email/security recovery alert harus selalu
dibuat sebagai in-app notification dan melewati quiet hours. Channel global
tetap dihormati jika user menonaktifkan izin OS.

## PushPrefs contract

Tambahkan field required pada response `PushPrefs`:

```yaml
pushAnalysisCompleted: { type: boolean }
pushTpSlHit: { type: boolean }
pushLoginAlert: { type: boolean }
nativePushEnabled: { type: boolean }
webPushEnabled: { type: boolean }
quietHoursEnabled: { type: boolean }
quietHoursStart:
  type: string
  pattern: "^([01]\\d|2[0-3]):[0-5]\\d$"
quietHoursEnd:
  type: string
  pattern: "^([01]\\d|2[0-3]):[0-5]\\d$"
notificationTimezone:
  type: string
  example: Asia/Jakarta
```

Tambahkan field yang sama sebagai optional pada `PushPrefsUpdate`.

Backend validation wajib:

- reject unknown keys melalui Zod `.strict()`;
- waktu harus valid `HH:MM`;
- timezone harus valid IANA melalui `Intl.DateTimeFormat`;
- PATCH kosong tetap 400;
- query/update selalu berdasarkan authenticated `userId`;
- response tetap satu shape `PushPrefs` agar web dan Flutter konsisten.

## Notification category contract

Kolom `notifications.category` sudah ada. Tambahkan field nullable ke OpenAPI
`Notification`; jangan membuat kolom kedua.

Tambahkan kategori baru hanya ketika producer-nya tersedia:

```text
analysis_completed
tp_sl_hit
login_alert
security_alert
```

Setiap producer harus memberikan `category`, `dedupeKey`, dan structured
`actionType`/`actionId` dari B2. Jangan memakai title/message untuk menentukan
preference atau routing.

## Scope B4.1

B4.1 hanya schema + API contract + generated clients. Jangan sekaligus membuat
queue quiet-hours, analytics event table, atau grouping worker. Helper grouping
sudah ada dan queue membutuhkan desain retry/idempotency tersendiri pada fase
berikutnya.

## Test minimum

Backend:

- token register melakukan upsert dan ownership transfer;
- unregister user A tidak dapat menghapus token user B;
- token malformed/platform unknown ditolak;
- FCM invalid token dihapus tanpa log token penuh;
- Web Push tetap berjalan ketika Native Push gagal dan sebaliknya;
- seluruh field PushPrefs round-trip GET/PATCH;
- invalid time/timezone dan unknown field ditolak;
- channel toggle hanya menekan channel terkait, bukan notification DB/SSE;
- security alert kritis melewati quiet hours;
- ownership notification/analysis tetap terisolasi per user.

Verifikasi minimal:

```bash
pnpm --filter @workspace/api-spec codegen
pnpm run typecheck
pnpm --filter @workspace/api-server test
pnpm --filter @workspace/ai-trading test
pnpm --filter @workspace/ai-trading build
```

Jangan menjalankan DB push, commit, push Git, atau deploy tanpa instruksi
eksplisit dan verifikasi environment target.

---

# Prompt historis untuk Tim Web — jangan jalankan ulang

```text
Kamu bekerja pada repo aisgbizdev/Trade-Pilot, branch kerja berbasis prod.

Baca docs handoff mobile P2-B2 dan dokumen P2-B3/B4.1 ini. Audit seluruh caller
createNotification(), push prefs, notification guards, OpenAPI, generated
clients, dan tests sebelum mengubah kode. Pertahankan perubahan lokal yang
tidak terkait. Jangan mengubah repo Flutter.

Urutan wajib:
1. Selesaikan contract B2 actionType/actionId + server unreadCount terlebih
   dahulu jika belum ada.
2. Implementasikan native_push_devices, authenticated register/unregister,
   FCM HTTP v1 sender, dan fan-out Web Push + Native Push.
3. Extend users + GET/PATCH /push/prefs dengan delta B4.1. Jangan membuat tabel
   notification_preferences baru dan jangan menduplikasi category/quiet-hour/
   grouping helper yang sudah ada.
4. Tambahkan category nullable ke OpenAPI Notification lalu regenerate semua
   clients dari source spec; jangan edit generated files manual.

Firebase:
- project ID trade-pilot-newsmaker23;
- Android/iOS identifier com.tradepilot.app;
- gunakan ADC + FIREBASE_PROJECT_ID;
- jangan commit/log credential, APNs key, service-account JSON, atau full FCM
  token.

Security:
- validate token length/platform dan PushPrefs dengan Zod strict;
- unregister harus userId AND token;
- actionType harus allowlist dan bukan arbitrary URL;
- authorization GET /analyses/:id tetap id + authenticated userId;
- security alert kritis tidak dapat dimatikan dan melewati quiet hours;
- channel opt-out hanya menekan channel OS, bukan notification DB/SSE.

Scope B4.1 berhenti pada schema, API contract, generated clients, dan tests.
Jangan membuat email sender, analytics pipeline, atau durable quiet-hours queue
di fase ini.

Jalankan codegen, typecheck, API tests, web tests, dan web build. Jangan DB
push/commit/push/deploy tanpa instruksi eksplisit. Laporkan file berubah,
checks lulus, environment/secret/manual APNs step yang belum dilakukan.
```
