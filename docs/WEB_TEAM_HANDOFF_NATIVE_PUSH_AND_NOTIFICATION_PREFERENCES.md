# Handoff Tim Web — Native Push (P2-B3) + Preference Contract (P2-B4.1)

> **DIARSIPKAN:** aplikasi mobile saat ini tidak memakai Firebase/FCM atau
> native push. Jangan implementasikan bagian native push dari dokumen ini
> sampai fitur tersebut diputuskan aktif kembali. Notification inbox backend
> tetap digunakan.

Dokumen ini dibuat dari audit read-only repo `aisgbizdev/Trade-Pilot` branch
`prod` pada commit `16d9eb6` dan implementasi Flutter saat ini.

## Status nyata

Flutter sudah memakai Firebase project berikut:

```text
Project ID: trade-pilot-newsmaker23
Android:    com.tradepilot.app
iOS:        com.tradepilot.app
```

Mobile sudah memiliki:

- Firebase initialization dan background handler;
- permission UI `Mobile Push`;
- register/refresh/unregister FCM token;
- foreground local notification;
- open handling untuk foreground, background, dan terminated;
- allowlist action serta ownership check melalui API analysis;
- unregister sebelum logout;
- konfigurasi Android/iOS dan build yang lulus.

Mobile memanggil endpoint authenticated berikut:

```text
POST   /api/native-push/register
DELETE /api/native-push/unregister
```

Endpoint tersebut belum tersedia pada branch `prod`. Sampai backend bagian B3
di bawah dideploy, toggle Mobile Push akan gagal secara aman dan menampilkan
bahwa server belum dapat mendaftarkan perangkat.

## Temuan branch `prod`

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

# Prompt Codex untuk Tim Web

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
