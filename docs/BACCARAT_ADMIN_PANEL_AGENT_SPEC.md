# مستند اجرایی باکارات برای پنل ادمین

- نسخه: `1.0`
- تاریخ: `2026-03-12`
- وضعیت: `Admin Panel Agent Ready`
- دامنه: `Catalog + Game Configs + Rooms + Results + Reports برای BACCARAT`

---

## 1. هدف این سند

این سند باید برای ایجنت پنل ادمین کافی باشد تا surfaceهای مدیریتی مربوط به باکارات را روی وب پیاده کند؛ شامل:

- runtime catalog item بازی `BACCARAT`
- config عمومی بازی `baccarat`
- room list/detail/cancel
- results list/detail/stats/export
- reports بازی با فیلتر `gameType=BACCARAT`
- validationها، filterها، sortها و error handling
- semantics مهم scoreهای باکارات

این سند feature جدید تعریف نمی‌کند. فقط surfaceهای موجود backend را برای UI ادمین formalize می‌کند.

---

## 2. Source Of Truth

### فایل‌های مرجع

- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminGameCatalogController.java`
- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminGameConfigController.java`
- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminGameRoomController.java`
- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminGameResultController.java`
- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminFinancialReportController.java`
- `gameBackend/src/main/java/com/gameapp/game/controllers/PublicGameConfigController.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameCatalogService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameConfigService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/AdminGameRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/AdminGameResultService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/AdminReportsService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/AdminReportValidationService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameCatalogDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameConfigDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameRoomDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameResultDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameResultStatsDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminRoomStatsDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGamesReportResponseDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameDistributionItemDto.java`

### اصل مهم

- اگر بین نیاز UI و backend اختلاف بود، UI باید با backend فعلی تطبیق داده شود.
- این سند برای باکارات فقط surfaceهای مدیریت/مشاهده را پوشش می‌دهد، نه live-control gameplay.

---

## 3. مدل مفهومی پنل ادمین برای باکارات

برای باکارات در پنل ادمین این بخش‌ها کافی است:

1. `Catalog`
2. `Game Configs`
3. `Rooms`
4. `Results`
5. `Reports`

### چیزهایی که ادمین برای باکارات ندارد

- force-pick side
- force-resolve hand
- force-finish match با payload اختصاصی باکارات
- edit live shoe
- edit player score
- config اختصاصی gameplay rules
- side-bet management

---

## 4. دو سطح جدا که UI باید تفکیک کند

## 4.1 Runtime Catalog

این سطح در جدول `game_catalog` نگه‌داری می‌شود و برای این‌ها اثر دارد:

- فعال/غیرفعال بودن runtime بازی
- نمایش بازی در lobby/catalog
- اجازه create/join room

### شناسه

- `gameType = "BACCARAT"`

## 4.2 Public Game Config

این سطح در جدول `game_configs` نگه‌داری می‌شود و برای این‌ها اثر دارد:

- min bet
- max bet
- rake percent
- visibility در endpoint عمومی `/api/game-configs/active`

### شناسه

- `gameKey = "baccarat"`

## 4.3 نکته بسیار مهم

- disable شدن `game_catalog` برای `BACCARAT` create/join runtime را block می‌کند.
- disable شدن `game_configs` برای `baccarat` فقط آن را از endpoint عمومی config حذف می‌کند و runtime را مستقیماً خاموش نمی‌کند.
- UI ادمین باید این دو toggle را با هم قاطی نکند.

---

## 5. Auth و Error Baseline

- همه endpointهای admin این سند زیر `/api/admin/**` هستند.
- فقط role=`ADMIN` مجاز است.

### رفتار کلی خطا

- `403 Forbidden`
  - بعضی endpointها body خالی برمی‌گردانند
- `400 Bad Request`
  - معمولاً `{ "error": "..." }`
- `404 Not Found`
  - معمولاً `{ "error": "..." }`
- `409 Conflict`
  - معمولاً `{ "error": "..." }`

### fallback policy برای UI

در toast/modal این ترتیب را پشتیبانی کن:

1. `body.error`
2. `body.message`
3. status text

---

## 6. Catalog APIs

## 6.1 دریافت catalog

- endpoint:
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

### response

```ts
export interface GameCatalogDto {
  gameType: string;
  name: string;
  iconKey: string;
  description: string;
  onlineCount: number;
  activeRoomCount: number;
  minPlayers: number;
  maxPlayers: number;
  enabled: boolean;
  sortOrder: number;
  createdAt: string;
  totalGamesPlayed: number;
}
```

### Baccarat mapping

- `gameType === "BACCARAT"`
- `name === "باکارات"` در seed فعلی
- `iconKey === "BACCARAT_ICON"`
- `minPlayers === 2`
- `maxPlayers === 2`

## 6.2 enable / disable runtime

- endpoint:
  - `PATCH /api/admin/games/BACCARAT/enabled`

### request

```ts
export interface UpdateGameEnabledRequest {
  enabled: boolean;
}
```

### response

- همان `GameCatalogDto`

### UI behavior

- toggle pending state داشته باشد
- روی خطا rollback شود
- اگر 404 آمد، item از backend sync نیست

## 6.3 full update catalog

- endpoint:
  - `PUT /api/admin/games/BACCARAT`
  - `PUT /api/admin/games/catalog/BACCARAT`

### request

```ts
export interface AdminGameCatalogUpdateRequest {
  name?: string;
  description?: string;
  minPlayers?: number;
  maxPlayers?: number;
  sortOrder?: number;
  enabled?: boolean;
}
```

### backend validation

- `minPlayers >= 1`
- `maxPlayers >= minPlayers`

### UI rule for Baccarat

- اگرچه endpoint اجازه update `minPlayers/maxPlayers` می‌دهد، UI برای باکارات باید این دو را read-only روی `2 / 2` نگه دارد.
- runtime anyway باکارات را 2 نفره enforce می‌کند.

---

## 7. Game Config APIs

## 7.1 دریافت همه configها

- endpoint:
  - `GET /api/admin/game-configs`

### response

```ts
export interface AdminGameConfigDto {
  id: number;
  gameKey: string;
  displayName: string;
  emoji?: string | null;
  enabled: boolean;
  minBet: number;
  maxBet: number;
  rakePercent: number;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}
```

### Baccarat mapping

- `gameKey === "baccarat"`
- `displayName === "Baccarat"`
- `emoji === "💎"`
- seed فعلی:
  - `enabled = true`
  - `minBet = 50`
  - `maxBet = 5000`
  - `rakePercent = 2.00`

## 7.2 update single config

- endpoint:
  - `PUT /api/admin/game-configs/baccarat`

### headers

- `Idempotency-Key` اختیاری ولی strongly recommended

### request

```ts
export interface AdminGameConfigUpdateRequest {
  enabled?: boolean;
  minBet?: number;
  maxBet?: number;
  rakePercent?: number;
}
```

### validation

- `minBet > 0`
- `maxBet >= minBet`
- `rakePercent` بین `0..100`
- `gameKey` باید موجود باشد و با case-insensitive lookup resolve می‌شود

### response

- `AdminGameConfigDto`

## 7.3 update batch config

- endpoint:
  - `PUT /api/admin/game-configs/batch`

### headers

- `Idempotency-Key` اختیاری ولی recommended

### request

```ts
export interface AdminGameConfigBatchItemRequest {
  gameKey: string;
  enabled?: boolean;
  minBet?: number;
  maxBet?: number;
  rakePercent?: number;
}
```

### response

- آرایه‌ای از `AdminGameConfigDto`

### validation

- batch item نباید null باشد
- `gameKey` نباید خالی باشد
- بقیه validationها همان update single

---

## 8. Rooms APIs

## 8.1 لیست roomها

- endpoint:
  - `GET /api/admin/rooms`

### query params

- `status?: RoomStatus`
- `search?: string`
- `gameType?: string`
- `minEntryFee?: number`
- `maxEntryFee?: number`
- `minPlayers?: number`
- `maxPlayers?: number`
- `createdByEmail?: string`
- `fromDate?: string`
- `toDate?: string`
- `sortBy?: string`
- `sortDir?: string`
- `page?: number`
- `size?: number`

### sortBy supported

- `id`
- `createdAt`
- `gameType`
- `roomStatus`
- `maxPlayers`
- `roomCode`
- `entryFee`
- `createdByEmail`

### sortDir supported

- `asc`
- `desc`

### behavior

- اگر `sortBy` ناشناخته باشد، backend silently به `createdAt` fallback می‌کند.
- اگر `sortDir` نامعتبر باشد، `400 INVALID_SORT_DIR`

### validations

- `gameType` نامعتبر -> `400 VALIDATION_ERROR`
- `minEntryFee > maxEntryFee` -> `400 VALIDATION_ERROR`
- `minPlayers > maxPlayers` -> `400 VALIDATION_ERROR`
- `fromDate > toDate` -> `400 VALIDATION_ERROR`
- تاریخ‌ها یکی از این formatها:
  - `YYYY-MM-DD`
  - `ISO LocalDateTime`
  - `ISO OffsetDateTime`

### response

```ts
export interface AdminGameRoomPlayerDto {
  userId: number;
  email: string;
  username?: string | null;
  seatNumber?: number | null;
}

export interface AdminGameRoomDto {
  id: number;
  roomCode?: string | null;
  gameType: string;
  roomStatus: string;
  entryFee: number;
  maxPlayers?: number | null;
  createdById?: number | null;
  createdByEmail?: string | null;
  createdAt?: string | null;
  players?: AdminGameRoomPlayerDto[] | null;
  result?: AdminGameResultDto | null;
}
```

### Baccarat-specific UI behavior

- primary filter برای این بازی:
  - `gameType=BACCARAT`
- `maxPlayers` را عملیاتی `2` فرض کن، حتی اگر historical data جایی null باشد.

## 8.2 جزئیات room

- endpoint:
  - `GET /api/admin/rooms/{id}`

### response

- `AdminGameRoomDto`
- `result` اگر game result برای room موجود باشد attach می‌شود.

### errors

- room ناموجود -> `404 ROOM_NOT_FOUND`

## 8.3 cancel room

- endpoint:
  - `PATCH /api/admin/rooms/{id}`

### headers

- `Idempotency-Key` اختیاری

### request

```json
{
  "roomStatus": "CANCELLED"
}
```

### validation

- فقط `roomStatus=CANCELLED` مجاز است
- `entryFee` و `maxPlayers` در این endpoint editable نیستند
- room در statusهای زیر cancel نمی‌شود:
  - `IN_PROGRESS`
  - `FINISHED`

### errors

- request body نامعتبر -> `400 VALIDATION_ERROR`
- room ناموجود -> `404 ROOM_NOT_FOUND`
- status غیرقابل‌ویرایش -> `409 ROOM_NOT_EDITABLE`

---

## 9. Results APIs

## 9.1 لیست results

- endpoint:
  - `GET /api/admin/results`

### query params

- `page` default=`0`
- `size` default=`20`
- `search?: string`
- `gameType?: string`
- `userId?: number`
- `dateFrom?: ISO date-time`
- `dateTo?: ISO date-time`
- `sortBy?: string`
- `sortDir?: string`

### sortBy supported

- `createdAt`
- `durationMinutes`
- `totalRounds`
- `gameType`

### sortDir supported

- `asc`
- `desc`

### validation

- `sortBy` نامعتبر -> `400 INVALID_SORT_BY`
- `sortDir` نامعتبر -> `400 INVALID_SORT_DIR`
- `gameType` با `trim().toUpperCase()` فیلتر می‌شود

### response

```ts
export interface AdminGameResultDto {
  id: number;
  gameRoomId?: number | null;
  roomCode?: string | null;
  gameType?: string | null;
  winnerUserId?: number | null;
  winnerEmail?: string | null;
  winnerUsername?: string | null;
  winnerTeamId?: number | null;
  teamAFinalScore?: number | null;
  teamBFinalScore?: number | null;
  totalRounds?: number | null;
  durationMinutes?: number | null;
  participantsScores?: Record<string, number> | null;
  startedAt?: string | null;
  finishedAt?: string | null;
  createdAt?: string | null;
}
```

## 9.2 جزئیات result

- endpoint:
  - `GET /api/admin/results/{id}`

- response:
  - `AdminGameResultDto`

## 9.3 stats

- endpoint:
  - `GET /api/admin/results/stats`

### response

- `totalGames`
- `totalDurationMinutes`
- `averageDurationMinutes`
- `mostPlayedGame`
- `mostPlayedGameCount`
- `gamesLast24h`
- `gamesLast7d`

## 9.4 export

- endpoint:
  - `GET /api/admin/results/export`

### query params

- `format=csv`
- `gameType?: string`
- `dateFrom?: ISO date-time`
- `dateTo?: ISO date-time`

### validation

- فقط `csv` پشتیبانی می‌شود
- اگر تعداد رکوردها بیشتر از `50,000` باشد:
  - `400 EXPORT_LIMIT_EXCEEDED`

### نکته

- برای export باکارات از `gameType=BACCARAT` استفاده کن.

---

## 10. Reports APIs

## 10.1 Games Report

- endpoint:
  - `GET /api/admin/reports/games`

### query params

- `period`
- `from`
- `to`
- `gameType?`

### allowed period

- `daily`
- `weekly`
- `monthly`

### date rules

- `from` و `to` اجباری‌اند
- format:
  - `YYYY-MM-DD`
  - یا ISO date-time
- اگر `from > to`:
  - `400`
- اگر بازه بیشتر از `730` روز شود:
  - `400`
- اگر `period=daily` و بازه بیشتر از `365` روز شود:
  - `400`

### gameType normalization

- `baccarat -> BACCARAT`
- `BACCARAT -> BACCARAT`

### response summary fields

- `totalGamesPlayed`
- `totalRoomsCreated`
- `uniquePlayers`
- `totalBetVolume`
- `totalRakeCollected`
- `averageGameDuration`

### response series item

- `date`
- `gamesPlayed`
- `roomsCreated`
- `uniquePlayers`
- `betVolume`
- `rakeCollected`
- `avgDurationMinutes`

## 10.2 Game Distribution

- endpoint:
  - `GET /api/admin/reports/games/distribution`

### query params

- `from`
- `to`

### response item

- `gameType`
- `displayName`
- `emoji`
- `count`
- `percentage`
- `totalBetVolume`
- `totalRake`

### Baccarat usage

- باکارات داخل pie/breakdown با `gameType=BACCARAT` دیده می‌شود.

---

## 11. Score Semantics for Baccarat

این مهم‌ترین تفاوت باکارات برای ادمین است.

### raw scores

- `participantsScores`
- scoreهای history
- scoreهای recent history
- scoreهای in-room player state

همه raw scaled integer هستند، نه decimal-ready.

### display rule

```ts
export function formatBaccaratScore(raw: number | null | undefined): string {
  return ((raw ?? 0) / 100).toFixed(2);
}
```

### نمونه

- `95 -> 0.95`
- `-100 -> -1.00`
- `800 -> 8.00`

### UI rule

- در results table
- result detail
- room detail اگر score نمایش می‌دهی
- report drilldown

همه‌جا برای `gameType=BACCARAT` همین formatter را بزن.

---

## 12. Runtime Truths که Admin UI نباید نقض کند

- باکارات همیشه `2` نفره است.
- room creation runtime روی `game_catalog.enabled` gate می‌شود، نه `game_configs.enabled`.
- `game_configs.baccarat` فقط config عمومی/مالی است.
- runtime باکارات side bet یا gameplay tuning API ندارد.
- اگر ادمین catalog را آپدیت کند و `minPlayers/maxPlayers` را چیز دیگری بگذارد، engine و room service همچنان باکارات را 2 نفره enforce می‌کنند.

---

## 13. Acceptance Checklist

- catalog tab بتواند item `BACCARAT` را از `GET /api/admin/games/catalog` پیدا کند.
- runtime toggle روی `PATCH /api/admin/games/BACCARAT/enabled` کار کند.
- config tab بتواند row با `gameKey=baccarat` را از `GET /api/admin/game-configs` پیدا کند.
- config update با `PUT /api/admin/game-configs/baccarat` و `Idempotency-Key` کار کند.
- rooms tab با `gameType=BACCARAT` filter شود.
- results tab با `gameType=BACCARAT` filter شود.
- export نتایج با `gameType=BACCARAT` انجام شود.
- reports tab با `gameType=baccarat` یا `BACCARAT` قابل فیلتر باشد.
- `participantsScores` برای باکارات decimal نمایش داده شود، نه integer خام.
- `minPlayers/maxPlayers` در UI باکارات editable نباشد.

---

## 14. Out Of Scope

- live moderation gameplay
- player-side actions
- تغییر rules باکارات
- side bet config
- score repair tools
- settlement repair مخصوص باکارات

