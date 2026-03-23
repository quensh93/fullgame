# مستند اجرایی تخته‌نرد برای پنل ادمین

- نسخه: `1.0`
- تاریخ: `2026-03-12`
- وضعیت: `Admin Panel Agent Ready`
- دامنه: `Catalog metadata برای BACKGAMMON`

---

## 1. هدف این سند

این سند باید برای ایجنت پنل ادمین کافی باشد تا surface مدیریتی موجود برای بازی `BACKGAMMON` را روی وب پیاده کند.

این سند feature جدید تعریف نمی‌کند. فقط APIهای موجود backend و محدودیت‌های runtime را formalize می‌کند.

---

## 2. Source Of Truth

- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminGameCatalogController.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameCatalogService.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameCatalogDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameCatalogUpdateRequest.java`
- `gameBackend/src/main/java/com/gameapp/game/models/UpdateGameEnabledRequest.java`
- `gameBackend/src/main/resources/db/v3/V2__create_game_catalog.sql`
- `gameBackend/src/main/java/com/gameapp/game/services/BackgammonEngineService.java`

### اصل مهم

- پنل ادمین برای Backgammon فقط metadata و availability را مدیریت می‌کند.
- هیچ admin gameplay control برای تخته‌نرد در backend فعلی وجود ندارد.

---

## 3. Scope واقعی پنل ادمین برای BACKGAMMON

### in-scope

- مشاهده card بازی `BACKGAMMON` در catalog
- مشاهده و ویرایش:
  - `name`
  - `description`
  - `iconKey`
  - `enabled`
  - `sortOrder`
- مشاهده stats:
  - `onlineCount`
  - `activeRoomCount`
  - `totalGamesPlayed`

### out-of-scope

- force roll
- force move
- force finish match
- تغییر scoreهای runtime داخل match
- cancel hand
- edit board position
- enable bots for Backgammon

---

## 4. Auth و Error Baseline

- همه endpointهای این سند زیر `/api/admin/games/**` هستند.
- فقط role=`ADMIN` مجاز است.

### error behavior

- `403 Forbidden`
  - وقتی کاربر admin نباشد
- `400 Bad Request`
  - وقتی body ناقص یا validation غلط باشد
- `404 Not Found`
  - وقتی `gameType` در catalog پیدا نشود

UI باید fallback این سه error shape را پشتیبانی کند:

- `body.error`
- `body.message`
- empty body + status text

---

## 5. Catalog Item for BACKGAMMON

### gameType ثابت

- مقدار backend همیشه `BACKGAMMON` است.
- label کاربر-facing پیشنهادی:
  - title: `تخته نرد`
  - subtitle: `BACKGAMMON`

### GameCatalogDto

```ts
export interface GameCatalogDto {
  gameType: string
  name: string
  iconKey: string
  description: string
  onlineCount: number
  activeRoomCount: number
  minPlayers: number
  maxPlayers: number
  enabled: boolean
  sortOrder: number
  createdAt: string
  totalGamesPlayed: number
}
```

### Backgammon-specific UI constraints

- `minPlayers` باید روی `2` lock شود.
- `maxPlayers` باید روی `2` lock شود.
- UI نباید اجازه دهد admin این بازی را به حالت چندنفره تغییر دهد.
- UI نباید option مربوط به bot gameplay برای این بازی نمایش دهد.

---

## 6. Endpoints

## 6.1 دریافت catalog

- `GET /api/admin/games/catalog`

### query params

- `sortBy`
  - default: `sortOrder`
  - allowed:
    - `sortOrder`
    - `name`
    - `onlineCount`
    - `activeRoomCount`
    - `createdAt`
    - `totalGamesPlayed`
- `sortDir`
  - default: `asc`
  - allowed:
    - `asc`
    - `desc`

### UI usage

- item با `gameType === "BACKGAMMON"` را از لیست پیدا کن.
- card باید `enabled`, `onlineCount`, `activeRoomCount`, `totalGamesPlayed` را نشان دهد.

## 6.2 toggle enable/disable

- `PATCH /api/admin/games/{gameType}/enabled`
- برای این بازی:
  - `{gameType} = BACKGAMMON`

### request

```ts
export interface UpdateGameEnabledRequest {
  enabled: boolean
}
```

### example

```json
{
  "enabled": true
}
```

### response

- همان `GameCatalogDto`

### UI behavior

- toggle با pending spinner
- rollback روی خطا
- success toast بعد از update

## 6.3 full update

- `PUT /api/admin/games/{gameType}`
- `PUT /api/admin/games/catalog/{gameType}`

هر دو route در backend به یک handler می‌رسند.

### request

```ts
export interface AdminGameCatalogUpdateRequest {
  name?: string
  description?: string
  minPlayers?: number
  maxPlayers?: number
  sortOrder?: number
  enabled?: boolean
}
```

### Backgammon-specific UI rules

- `name` editable
- `description` editable
- `enabled` editable
- `sortOrder` editable
- `minPlayers` readonly = `2`
- `maxPlayers` readonly = `2`

### response

- همان `GameCatalogDto`

---

## 7. Suggested UI Sections

برای Backgammon در پنل ادمین همین‌ها کافی‌اند:

1. `Catalog Card`
2. `Quick Enable Toggle`
3. `Edit Metadata Modal`
4. `Stats Badges`

### card fields

- title = `name`
- subtitle = `description`
- badge = `enabled | disabled`
- stat = `onlineCount`
- stat = `activeRoomCount`
- stat = `totalGamesPlayed`
- helper text = `2 players only`

### edit modal fields

- `name`
- `description`
- `sortOrder`
- `enabled`
- readonly text:
  - `minPlayers = 2`
  - `maxPlayers = 2`

---

## 8. Acceptance Checklist

- [ ] catalog tab item `BACKGAMMON` را از API پیدا می‌کند.
- [ ] quick toggle فقط `enabled` را update می‌کند.
- [ ] edit modal فیلدهای editable را update می‌کند.
- [ ] `minPlayers/maxPlayers` برای Backgammon قابل ویرایش نیستند.
- [ ] UI هیچ gameplay-control برای تخته‌نرد نشان نمی‌دهد.
- [ ] خطاهای `400/403/404` به toast یا inline error مناسب map می‌شوند.

---

## 9. Non-Goals

- admin live board viewer
- admin game intervention
- admin rescore
- admin timeout trigger
- bot administration مخصوص gameplay تخته‌نرد

