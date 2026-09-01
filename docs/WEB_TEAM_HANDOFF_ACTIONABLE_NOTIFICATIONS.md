# Handoff Tim Web — Actionable Notifications (P2-B2)

Dokumen ini menjelaskan perubahan backend dan web yang diperlukan agar perilaku notifikasi web konsisten dengan aplikasi Flutter saat ini.

## Outcome

Notifikasi penyelesaian analisis harus membawa target terstruktur:

```json
{
  "id": 381,
  "title": "Analisis Selesai",
  "message": "Analisis XAU/USD (1h, Pemula) telah selesai diproses.",
  "type": "info",
  "readAt": null,
  "actionType": "analysis",
  "actionId": 381,
  "createdAt": "2026-08-21T00:00:00.000Z"
}
```

Ketika notifikasi ditekan:

```text
mark notification as read
          ↓
allowlist actionType
          ↓
actionType=analysis + actionId valid
          ↓
navigate ke /analyses/:id
          ↓
GET /analyses/:id memverifikasi id + userId
```

`actionType` bukan URL. Client dilarang meneruskannya langsung ke router atau `window.location`.

## Kontrak API yang harus tersedia

### `Notification`

Tambahkan field nullable berikut dan jangan masukkan ke daftar `required`:

```yaml
actionType:
  type: string
  nullable: true
  enum: [analysis, history, notifications, daily_summary, alerts]
  description: >
    Structured in-app navigation target. Clients must allowlist supported
    action types and must not interpret this value as an arbitrary URL.

actionId:
  type: integer
  nullable: true
  description: >
    Optional resource ID associated with actionType. For actionType=analysis
    this is the analysis ID.
```

### `NotificationsList`

Response `GET /notifications` wajib berbentuk:

```json
{
  "notifications": [],
  "unreadCount": 0
}
```

`unreadCount` adalah jumlah total unread di database, bukan hasil `notifications.filter(...)`. Endpoint membatasi daftar ke 50 row sehingga perhitungan dari array dapat salah.

## Perubahan backend pada branch `prod`

### 1. Database schema

File: `lib/db/src/schema/index.ts`

Tambahkan pada tabel `notifications`:

```ts
actionType: text("action_type"),
actionId: integer("action_id"),
```

Keduanya nullable agar backward-compatible dengan notifikasi lama. `actionId` sengaja tidak menjadi foreign key karena targetnya generik.

Setelah target database dipastikan benar:

```bash
pnpm --filter @workspace/db push
```

Jangan menjalankan push ke production sebelum `DATABASE_URL` diverifikasi.

### 2. Notification creation

File: `artifacts/api-server/src/lib/create-notification.ts`

Tambahkan union dan field berikut:

```ts
export type NotificationActionType =
  | "analysis"
  | "history"
  | "notifications"
  | "daily_summary"
  | "alerts";

export interface NotificationContent {
  // field existing tetap dipertahankan
  actionType?: NotificationActionType | null;
  actionId?: number | null;
}
```

Persist kedua field pada seluruh jalur insert:

- insert dengan `dedupeKey`;
- insert tanpa `dedupeKey`;
- bulk insert `createNotificationsForUsers()`.

Gunakan conditional spread agar `undefined` tidak ditulis secara tidak sengaja:

```ts
...(content.actionType !== undefined
  ? { actionType: content.actionType }
  : {}),
...(content.actionId !== undefined
  ? { actionId: content.actionId }
  : {}),
```

SSE tidak perlu membawa dua field ini. Event SSE tetap menjadi sinyal untuk invalidate/refetch `GET /notifications`, sehingga hanya ada satu serialization contract.

### 3. Server unread count

File: `artifacts/api-server/src/routes/notifications.ts`

Hitung total unread dengan query `count(notifications.id)` yang tetap dibatasi oleh `userId` dan `readAt IS NULL`, lalu kembalikan bersama daftar:

```ts
res.json({
  notifications: rows,
  unreadCount: Number(unreadRow?.count ?? 0),
});
```

Ownership filter pada query daftar maupun count tidak boleh dihapus.

### 4. Analysis-complete notification

File: `artifacts/api-server/src/routes/analyses.ts`

Saat analisis selesai:

```ts
await createNotification(
  req.userId!,
  {
    title: completeTitle,
    message: completeMessage,
    type: "info",
    actionType: "analysis",
    actionId: analysis.id,
  },
  {
    title: "Analisis Selesai ✅",
    body: `${instrument} (${timeframe}) — buka Trade Pilot untuk lihat hasilnya.`,
    url: `/analyses/${analysis.id}`,
    tag: `analysis-${analysis.id}`,
  },
);
```

Authorization tetap ditegakkan oleh `GET /analyses/:id` menggunakan kombinasi `analysis.id` dan authenticated `userId`. Jangan mengandalkan kerahasiaan `actionId`.

### 5. OpenAPI dan generated clients

File sumber: `lib/api-spec/openapi.yaml`

Regenerate, jangan edit generated React/Zod/Dart model secara manual:

```bash
pnpm --filter @workspace/api-spec codegen
```

Expected generated React contract:

```ts
export interface Notification {
  // field existing
  actionType?: NotificationActionType | null;
  actionId?: number | null;
}

export interface NotificationsList {
  notifications: Notification[];
  unreadCount: number;
}
```

## Perubahan React web

### 1. Shared allowlist resolver

Buat satu pure helper kecil, misalnya `artifacts/ai-trading/src/lib/notification-action.ts`, agar notification page dan header bell memakai aturan yang sama:

```ts
import type { Notification } from "@workspace/api-client-react";

type ActionNotification = Pick<Notification, "actionType" | "actionId">;

export function notificationHref(notification: ActionNotification): string | null {
  switch (notification.actionType) {
    case "analysis":
      return Number.isInteger(notification.actionId) && notification.actionId! > 0
        ? `/analyses/${notification.actionId}`
        : null;
    case "history":
      return "/history";
    case "notifications":
      return "/notifications";
    case "daily_summary":
      return "/daily-summary";
    case "alerts":
      return "/my-alerts";
    default:
      return null;
  }
}
```

Rules:

- unknown/null action harus menghasilkan `null`;
- `analysis` wajib memiliki integer positif;
- jangan gunakan `navigate(notification.actionType)`;
- jangan membuka arbitrary URL dari payload.

### 2. Notifications page

File: `artifacts/ai-trading/src/pages/notifications.tsx`

Perubahan:

1. Gunakan `data.unreadCount`, bukan filter atas maksimum 50 row:

   ```ts
   const notificationData = data as NotificationsList | undefined;
   const notifications = notificationData?.notifications ?? [];
   const unreadCount = notificationData?.unreadCount ?? 0;
   ```

2. Saat card ditekan:
   - tandai read jika masih unread;
   - resolve target melalui `notificationHref()`;
   - navigate hanya jika helper mengembalikan internal path;
   - notifikasi read tetap boleh membuka target;
   - kegagalan mark-read tidak boleh membuat arbitrary fallback navigation.

3. Gunakan router `wouter` yang sudah terpasang; tidak perlu dependency baru.

### 3. Header notification bell

File: `artifacts/ai-trading/src/components/layout.tsx`

Perubahan:

- gunakan `notifData.unreadCount`, bukan `notifications.length`;
- buat lima preview row dapat membuka action melalui helper yang sama;
- close popover setelah navigasi;
- mark row sebagai read sebelum/refetch setelah navigasi sesuai mutation pattern existing;
- row tanpa action tetap aman dan tidak melakukan navigasi.

### 4. Web Push / service worker

File: `artifacts/ai-trading/src/sw.ts`

Backend akan mengirim `url: "/analyses/:id"`. Pertahankan click handling yang memfokuskan window existing atau membuka window baru, tetapi pastikan:

- destination selalu same-origin;
- hanya internal route yang diizinkan;
- base path deployment/PWA scope tidak hilang ketika payload dimulai dengan `/`;
- URL invalid atau external fallback ke halaman notifications, bukan dibuka.

Perhatian: `new URL("/analyses/123", serviceWorkerScope)` membuang pathname base dari scope. Ini harus dites jika web deploy di subpath seperti `/artifacts/ai-trading/`.

## Test minimum

Backend:

- single, dedupe, dan bulk insert menyimpan action fields;
- `GET /notifications` mengembalikan total `unreadCount` milik user;
- ownership user lain tidak bocor pada daftar/count;
- analysis-complete row mempunyai `actionType="analysis"` dan ID yang benar;
- push URL menjadi `/analyses/:id`;
- `GET /analyses/:id` tetap menolak non-owner.

Web:

- resolver memetakan seluruh allowlist dengan benar;
- analysis ID null, nol, negatif, desimal, atau unknown action menghasilkan `null`;
- string seperti `https://evil.example` tidak pernah dinavigasikan;
- clicking unread actionable notification melakukan PATCH dan navigasi;
- clicking read actionable notification tetap navigasi;
- non-actionable notification tidak navigasi;
- page dan header memakai `unreadCount` dari server, termasuk nilai di atas 50;
- service-worker click tetap same-origin dan benar pada deployment subpath.

Jalankan minimal:

```bash
pnpm run typecheck
pnpm --filter @workspace/api-server test
pnpm --filter @workspace/ai-trading test
pnpm --filter @workspace/ai-trading build
```

## Urutan rollout

1. Push schema nullable ke database target yang sudah diverifikasi.
2. Deploy API server dan contract OpenAPI/generated clients.
3. Deploy React web.
4. Tes create-analysis → notification row → notification page/header → analysis detail.
5. Tes user A tidak dapat membuka analysis milik user B walaupun `actionId` dimanipulasi.

## Acceptance criteria

- Mobile dan web membaca contract Notification yang sama.
- Counter unread berasal dari server dan akurat saat unread melebihi 50.
- Notification analysis membuka `/analyses/:id` dari page, header bell, dan OS push.
- Unknown/malformed action fail closed.
- Tidak ada arbitrary URL navigation.
- Legacy notification tanpa action tetap tampil dan dapat ditandai read.
- SSE tetap hanya menjadi trigger refetch.
- Typecheck, tests, dan web build lulus.

---

# Prompt Codex untuk Tim Web

Salin prompt berikut dan jalankan Codex dari root repo `aisgbizdev/Trade-Pilot` pada branch kerja yang berbasis `prod`:

```text
Kamu bekerja pada repo aisgbizdev/Trade-Pilot, branch kerja berbasis prod.

Implementasikan actionable notifications end-to-end agar web konsisten dengan mobile. Jangan mengubah repo/aplikasi Flutter. Inspect kode dan semua caller terlebih dahulu; pertahankan perubahan lokal yang tidak terkait dan gunakan pattern/dependency yang sudah ada.

Kontrak final:
- Notification memiliki field nullable actionType dan actionId.
- actionType allowlist: analysis, history, notifications, daily_summary, alerts.
- NotificationsList wajib mengembalikan notifications dan total unreadCount dari database.
- Legacy notification tanpa action harus tetap berfungsi.

Backend:
1. Tambahkan notifications.action_type TEXT NULL dan action_id INTEGER NULL di lib/db/src/schema/index.ts. Jangan jadikan action_id foreign key generik.
2. Update NotificationContent dan semua insert path pada artifacts/api-server/src/lib/create-notification.ts, termasuk dedupe, non-dedupe, dan bulk.
3. Update GET /notifications agar unreadCount dihitung dengan SQL count berdasarkan authenticated userId + readAt IS NULL, bukan dari array limit 50.
4. Update OpenAPI Notification dan regenerate semua clients memakai script repo; jangan edit generated file manual.
5. Notification selesai analisis harus menyimpan actionType=analysis, actionId=analysis.id, dan Web Push URL /analyses/:id.
6. Pertahankan ownership GET /analyses/:id berdasarkan analysis.id + authenticated userId.
7. SSE tetap hanya menjadi trigger refetch; jangan duplikasi deserialization contract di SSE.

React web:
1. Buat satu pure allowlist resolver shared untuk memetakan action ke route internal:
   analysis + positive integer ID -> /analyses/:id
   history -> /history
   notifications -> /notifications
   daily_summary -> /daily-summary
   alerts -> /my-alerts
   unknown/malformed/null -> null
2. Notifications page memakai server unreadCount dan saat row ditekan melakukan mark-read lalu safe navigation. Row yang sudah read tetap dapat membuka target.
3. Header notification bell memakai server unreadCount, preview row memakai resolver yang sama, dan popover ditutup setelah navigasi.
4. Service worker hanya boleh membuka same-origin allowlisted internal route. Pastikan path benar saat aplikasi di-deploy pada subpath/PWA scope; external atau invalid URL fallback ke notifications.
5. Jangan pernah memakai actionType sebagai route/URL secara langsung. Jangan menambah dependency baru.

Security:
- Fail closed untuk unknown action.
- Validasi actionId dengan Number.isInteger dan > 0.
- Tidak boleh ada arbitrary external URL navigation/openWindow.
- Backend authorization tetap menjadi enforcement utama; UI check bukan authorization.
- Jangan menjalankan drizzle push sampai target DATABASE_URL diverifikasi. Jika environment DB tidak tersedia, implementasikan kode lalu laporkan command yang belum dijalankan.

Tests minimum:
- Persist action fields pada single/dedupe/bulk insert.
- unreadCount benar dan terisolasi per user, termasuk >50 unread.
- analysis notification action dan push URL benar.
- resolver menolak malformed ID, unknown action, dan URL injection.
- click unread melakukan PATCH + navigate; click read tetap navigate; no-action tidak navigate.
- page/header memakai server unreadCount.
- service-worker route aman untuk root dan subpath deployment.

Verifikasi:
- pnpm run typecheck
- pnpm --filter @workspace/api-server test
- pnpm --filter @workspace/ai-trading test
- pnpm --filter @workspace/ai-trading build

Hasil akhir yang gue mau:
- Implementasi selesai dengan diff minimal dan production-ready.
- Jangan commit/push/deploy tanpa instruksi eksplisit.
- Laporkan file yang berubah, checks yang lulus, serta DB/deploy step yang belum dijalankan.
```
