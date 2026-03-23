# مستند اجرایی رامی برای پنل ادمین

- نسخه: `1.0`
- تاریخ: `2026-03-12`
- وضعیت: `Admin Panel Agent Ready`
- دامنه: `Catalog + Rooms + Results + Reports برای بازی RIM / رامی`

---

## 1. هدف این سند

این سند باید برای ایجنت پنل ادمین کافی باشد تا surfaceهای مدیریتی مربوط به رامی را روی وب پیاده کند؛ شامل:

- catalog item بازی `RIM`
- room list/detail/cancel
- results list/detail/stats/export
- reports بازی با فیلتر `gameType=RIM`
- validationها، sortها، filterها و error handling
- gapهای runtime و محدودیت‌های مهم backend

این سند feature جدید تعریف نمی‌کند. فقط surfaceهای موجود backend را برای UI ادمین formalize می‌کند.

---

## 2. Source Of Truth

مرجع قطعی این سند backend runtime فعلی است.

### فایل‌های مرجع

- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminGameCatalogController.java`
- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminGameRoomController.java`
- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminGameResultController.java`
- `gameBackend/src/main/java/com/gameapp/game/controllers/AdminFinancialReportController.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameCatalogService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/AdminGameRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/AdminGameResultService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/AdminReportsService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameCatalogDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameRoomDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameResultDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminRoomStatsDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameResultStatsDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGamesReportResponseDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/AdminGameDistributionItemDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/Enums.java`

### اصل مهم

- اگر بین نیاز UI و surface موجود backend اختلاف بود، UI باید با surface موجود تطبیق داده شود.
- این سند برای رامی فقط `admin مشاهده/مدیریت metadata` را پوشش می‌دهد، نه live-control gameplay.

---

## 3. مدل مفهومی پنل ادمین برای رامی

برای بازی `RIM` در پنل ادمین چهار بخش کافی است:

1. `Catalog`
2. `Rooms`
3. `Results`
4. `Reports`

### چیزهایی که ادمین برای رامی ندارد

- force-play
- force-finish-hand
- edit hand cards
- edit table melds
- manual settlement مخصوص رامی
- config اختصاصی gameplay خارج از game catalog

---

## 4. Auth و Error Baseline

- همه endpointهای این سند زیر `/api/admin/**` هستند.
- فقط role=`ADMIN` مجاز است.

### رفتار کلی خطا

- `403 Forbidden`
  - در بعضی controllerها body خالی است
  - در بعضی controllerها body با `{ "error": "..." }` می‌آید
- `400 Bad Request`
  - معمولاً `{ "error": "..." }`
- `404 Not Found`
  - معمولاً `{ "error": "..." }` یا body خالی
- `409 Conflict`
  - معمولاً `{ "error": "..." }`

### نکته مهم

error shape در کل admin uniform کامل نیست. UI باید حداقل این fallbackها را پشتیبانی کند:

- `body.error`
- `body.message`
- empty body + status text

---

## 5. Catalog

## 5.1 هدف UI

تب Catalog برای رامی باید بتواند:

- item بازی `RIM` را در لیست کاتالوگ نشان دهد
- enabled/disabled بودنش را toggle کند
- metadata عمومی‌اش را update کند

در این تب label کاربر-facing را `رامی / Rummy` نشان بده، ولی `gameType` ارسالی به backend همیشه `RIM` باشد.

## 5.2 لیست بازی‌ها

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
  - allowed: `asc`, `desc`

### response model

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

### RIM-specific UI mapping

- `gameType === "RIM"` را در لیست پیدا کن.
- label نمایشی:
  - title: `رامی`
  - subtitle: `RIM`

### validation/error

- sortBy نامعتبر:
  - `400`
  - message: `Invalid sortBy. Allowed values: sortOrder, name, onlineCount, activeRoomCount, createdAt, totalGamesPlayed`
- sortDir نامعتبر:
  - `400`
  - message: `Invalid sortDir. Allowed values: asc, desc`

## 5.3 enable/disable

- `PATCH /api/admin/games/{gameType}/enabled`
- برای رامی:
  - `gameType = RIM`

### request

```ts
export interface UpdateGameEnabledRequest {
  enabled: boolean;
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

- toggle باید optimistic ملایم باشد:
  - pending spinner
  - rollback روی خطا
- اگر 404 گرفتی:
  - item catalog sync نیست
  - error toast نمایش بده

## 5.4 full update

- `PUT /api/admin/games/{gameType}`
- `PUT /api/admin/games/catalog/{gameType}`

هر دو route در backend به یک handler می‌رسند.

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

### response

- همان `GameCatalogDto`

### validation/runtime notes

- service فقط این را enforce می‌کند:
  - `minPlayers >= 1`
  - `maxPlayers >= minPlayers`
- ولی برای رامی، runtime واقعی create room و engine این limit را enforce می‌کنند:
  - `2 <= maxPlayers <= 6`

### rule اجباری برای UI

- form رامی باید `minPlayers` و `maxPlayers` را خارج از `2..6` اصلاً submit نکند.
- اگر می‌خواهی safe بمانی:
  - default پیشنهادشده:
    - `minPlayers = 2`
    - `maxPlayers = 6`

### GAP مهم

catalog validation ضعیف‌تر از runtime رامی است. بنابراین UI باید validation رامی-specific داشته باشد.

---

## 6. Rooms

## 6.1 هدف UI

تب Rooms برای رامی باید بتواند:

- roomهای `gameType=RIM` را list کند
- فیلتر و sort کند
- detail هر room را باز کند
- roomهای pending/ready را cancel کند
- stats کلی roomها را نشان دهد

## 6.2 لیست روم‌ها

- `GET /api/admin/rooms`

### query params

- `status?: "PENDING" | "READY" | "IN_PROGRESS" | "FINISHED" | "CANCELLED"`
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
- `sortDir?: "asc" | "desc"`
- `page?: number`
- `size?: number`

### sortBy های معتبر

- `id`
- `createdAt`
- `gameType`
- `roomStatus`
- `maxPlayers`
- `roomCode`
- `entryFee`
- `createdByEmail`

### search behavior

`search` روی این فیلدها عمل می‌کند:

- `roomCode`
- `createdBy.email`
- `room.id` به‌صورت string

### response shape

- Spring `Page<AdminGameRoomDto>`

```ts
export interface AdminGameRoomDto {
  id: number;
  roomCode: string;
  gameType: string;
  roomStatus: string;
  entryFee: number;
  maxPlayers: number | null;
  createdById: number | null;
  createdByEmail: string | null;
  createdAt: string;
  players?: Array<{
    userId: number;
    email: string;
    username: string;
    seatNumber: number | null;
  }>;
  result?: AdminGameResultDto | null;
}
```

### نمونه filter برای رامی

`GET /api/admin/rooms?gameType=RIM&status=IN_PROGRESS&page=0&size=20`

### validation/error

- `gameType` نامعتبر:
  - `400`
  - `error = "Invalid gameType"`
- `minEntryFee > maxEntryFee`:
  - `400`
  - `error = "minEntryFee cannot be greater than maxEntryFee"`
- `minPlayers > maxPlayers`:
  - `400`
  - `error = "minPlayers cannot be greater than maxPlayers"`
- `fromDate > toDate`:
  - `400`
  - `error = "fromDate cannot be after toDate"`
- `fromDate/toDate` فرمت نامعتبر:
  - `400`
  - `error = "<fieldName> must be a valid ISO date string"`
- `sortDir` نامعتبر:
  - `400`
  - `error = "Invalid sortDir. Allowed values: asc, desc"`

### date input formats مجاز

backend این formatها را می‌پذیرد:

- `YYYY-MM-DD`
- ISO `LocalDateTime`
- ISO `OffsetDateTime`

## 6.3 جزئیات روم

- `GET /api/admin/rooms/{id}`

### response

- همان `AdminGameRoomDto`
- با `players` و `result` populated

### نکته مهم برای رامی

- اگر room تمام شده باشد و result ثبت شده باشد:
  - `result` داخل همین payload می‌آید.
- اگر room در جریان باشد:
  - `result = null`

## 6.4 لغو روم

- `PATCH /api/admin/rooms/{id}`

### request

```ts
export interface AdminPatchRoomRequest {
  entryFee?: number;
  maxPlayers?: number;
  roomStatus: string;
}
```

### only supported operation

برای این endpoint فقط این حالت معتبر است:

```json
{
  "roomStatus": "CANCELLED"
}
```

### header

- `Idempotency-Key` اختیاری است ولی strongly recommended

### rules

- اگر room قبلاً `CANCELLED` باشد:
  - همان room برمی‌گردد
- اگر room در `FINISHED` یا `IN_PROGRESS` باشد:
  - `409`
  - `ROOM_NOT_EDITABLE`
- اگر request شامل `entryFee` یا `maxPlayers` باشد:
  - `400`
  - فقط cancel مجاز است

### UI rule

- دکمه cancel را فقط برای `PENDING` و `READY` نشان بده.

## 6.5 room stats

- `GET /api/admin/rooms/stats`

### response

```ts
export interface AdminRoomStatsDto {
  totalRooms: number;
  pendingRooms: number;
  readyRooms: number;
  inProgressRooms: number;
  finishedRooms: number;
  cancelledRooms: number;
  totalActivePlayers: number;
}
```

### note

- این stats global است، نه فقط برای RIM.
- اگر tab رامی جداست، می‌توانی این endpoint را فقط برای summary کلی استفاده کنی و stats رامی-specific را از list filtered بسازی.

## 6.6 RIM-specific room fields

`gameScore` در room detail/list raw DTO عمومی معمولاً به‌صورت enum string است:

- `RIM_HUNDRED`
- `RIM_ONE_FIFTY`
- `RIM_TWO_HUNDRED`
- `RIM_TWO_FIFTY`
- `RIM_THREE_HUNDRED`

نمایش UI پیشنهادی:

- `RIM_HUNDRED -> 100`
- `RIM_ONE_FIFTY -> 150`
- `RIM_TWO_HUNDRED -> 200`
- `RIM_TWO_FIFTY -> 250`
- `RIM_THREE_HUNDRED -> 300`

---

## 7. Results

## 7.1 هدف UI

تب Results برای رامی باید بتواند:

- resultهای `gameType=RIM` را list کند
- detail هر result را باز کند
- stats aggregate را نشان دهد
- export csv بگیرد

## 7.2 لیست نتایج

- `GET /api/admin/results`

### query params

- `page?: number`
- `size?: number`
- `search?: string`
- `gameType?: string`
- `userId?: number`
- `dateFrom?: ISO LocalDateTime`
- `dateTo?: ISO LocalDateTime`
- `sortBy?: string`
- `sortDir?: "asc" | "desc"`

### sortBy های معتبر

- `createdAt`
- `durationMinutes`
- `totalRounds`
- `gameType`

### search behavior

`search` روی این فیلدها عمل می‌کند:

- `roomCode`
- `winner.email`
- `winner.username`

### userId behavior

اگر `userId` بدهی، rowهایی match می‌شوند که:

- user winner باشد
- یا participant room باشد
- یا key او در `participants_scores_json` وجود داشته باشد

### response model

```ts
export interface AdminGameResultDto {
  id: number;
  gameRoomId: number | null;
  roomCode: string | null;
  gameType: string | null;
  winnerUserId: number | null;
  winnerEmail: string | null;
  winnerUsername: string | null;
  winnerTeamId: number | null;
  teamAFinalScore: number | null;
  teamBFinalScore: number | null;
  totalRounds: number | null;
  durationMinutes: number | null;
  participantsScores: Record<number, number>;
  startedAt: string | null;
  finishedAt: string | null;
  createdAt: string | null;
}
```

### فیلدهای مهم برای رامی

- `winnerTeamId`
  - برای رامی عملاً `null`
- `teamAFinalScore/teamBFinalScore`
  - برای رامی `null`
- `participantsScores`
  - final match score هر participant
- `totalRounds`
  - در رامی معادل تعداد handهای انجام‌شده match است

## 7.3 جزئیات result

- `GET /api/admin/results/{id}`

### behavior

- اگر موجود باشد:
  - `200 + AdminGameResultDto`
- اگر موجود نباشد:
  - `404`

## 7.4 stats

- `GET /api/admin/results/stats`

### response

```ts
export interface AdminGameResultStatsDto {
  totalGames: number;
  totalDurationMinutes: number;
  averageDurationMinutes: number;
  mostPlayedGame: string | null;
  mostPlayedGameCount: number;
  gamesLast24h: number;
  gamesLast7d: number;
}
```

### note

- این stats global است.
- برای tab رامی اگر stat card رامی-specific می‌خواهی، باید از list filtered یا report endpoint استفاده کنی.

## 7.5 export

- `GET /api/admin/results/export`

### query params

- `format`
- `gameType`
- `dateFrom`
- `dateTo`

### فقط format معتبر

- `csv`

### response

- file download
- content-type:
  - `text/csv; charset=UTF-8`

### exported columns

- `id`
- `gameRoomId`
- `roomCode`
- `gameType`
- `winnerUserId`
- `winnerEmail`
- `winnerUsername`
- `totalRounds`
- `durationMinutes`
- `startedAt`
- `finishedAt`
- `createdAt`

### limit مهم

- اگر تعداد rowها بیشتر از `50,000` باشد:
  - `400`
  - `EXPORT_LIMIT_EXCEEDED`
  - message: `Too many records. Apply filters.`

## 7.6 نحوه نمایش forfeit و blocked tie در admin results

### forfeit

- websocket runtime در `RIM_GAME_FINISHED` ممکن است `reason="FORFEIT"` و `leavingPlayer` بفرستد.
- اما `GameResult` persistence این reason را ذخیره نمی‌کند.
- بنابراین در admin `results` tab به‌صورت deterministic نمی‌توانی row را به‌عنوان forfeit badge علامت بزنی.

### blocked tie

- `BLOCKED_TIE` فقط hand-level event است.
- اگر match بعداً ادامه پیدا کند و در نهایت winner عادی داشته باشد، فقط result نهایی match ذخیره می‌شود.
- بنابراین admin results هیچ row یا field جدا برای blocked tie ندارد.

### نتیجه UI

- در results tab فقط final match outcome را نشان بده.
- روی وجود field جدا برای `reason` حساب نکن.

---

## 8. Reports

## 8.1 هدف UI

تب Reports برای رامی باید بتواند:

- report سری زمانی بازی‌ها را با `gameType=RIM` بگیرد
- distribution عمومی بازی‌ها را نمایش دهد

## 8.2 games report

- `GET /api/admin/reports/games`

### query params

- `period`
- `from`
- `to`
- `gameType`

### برای رامی

- `gameType=RIM` یا `gameType=rim` هر دو توسط normalize backend کار می‌کنند.

### response

```ts
export interface AdminGamesReportResponseDto {
  summary: {
    totalGamesPlayed: number;
    totalRoomsCreated: number;
    uniquePlayers: number;
    totalBetVolume: number;
    totalRakeCollected: number;
    averageGameDuration: number;
  };
  series: Array<{
    date: string;
    gamesPlayed: number;
    roomsCreated: number;
    uniquePlayers: number;
    betVolume: number;
    rakeCollected: number;
    avgDurationMinutes: number;
  }>;
}
```

### UI mapping پیشنهادی

- summary cards:
  - total games
  - total rooms
  - unique players
  - bet volume
  - rake
  - avg duration
- chart:
  - x-axis = `date`
  - seriesها بسته به نیاز:
    - `gamesPlayed`
    - `roomsCreated`
    - `uniquePlayers`
    - `avgDurationMinutes`

## 8.3 distribution report

- `GET /api/admin/reports/games/distribution`

### query params

- `from`
- `to`

### response

```ts
export interface AdminGameDistributionItemDto {
  gameType: string;
  displayName: string;
  emoji: string;
  count: number;
  percentage: number;
  totalBetVolume: number;
  totalRake: number;
}
```

### UI rule

- اگر row مربوط به `RIM` در distribution برگشت:
  - از `displayName` و `emoji` server استفاده کن.
- اگر خواستی فقط رامی را جدا highlight کنی:
  - روی `gameType === "RIM"` فیلتر کن.

### note

- distribution endpoint خودش filter `gameType` ندارد.
- اگر report صفحه‌ی اختصاصی رامی می‌سازی، این endpoint بیشتر برای comparative market view مناسب است.

---

## 9. Recommended UI Structure

## 9.1 Catalog Tab

- table columns:
  - name
  - gameType
  - enabled
  - minPlayers
  - maxPlayers
  - onlineCount
  - activeRoomCount
  - totalGamesPlayed
  - sortOrder
- actions:
  - toggle enabled
  - edit metadata

## 9.2 Rooms Tab

- filters:
  - status
  - search
  - entry fee range
  - player range
  - createdByEmail
  - date range
- table columns:
  - id
  - roomCode
  - roomStatus
  - entryFee
  - maxPlayers
  - createdByEmail
  - createdAt
- detail drawer:
  - players
  - result summary if exists
  - cancel button when editable

## 9.3 Results Tab

- filters:
  - search
  - userId
  - date range
  - sortBy/sortDir
- table columns:
  - id
  - roomCode
  - winnerUsername
  - totalRounds
  - durationMinutes
  - createdAt
- detail drawer:
  - participantsScores
  - winner identity
  - startedAt/finishedAt

## 9.4 Reports Tab

- summary cards از `/reports/games?gameType=RIM`
- line/bar chart از `series`
- optional market comparison از `/reports/games/distribution`

---

## 10. GAP Log

### GAP-001: catalog player-count validation با runtime رامی هم‌سطح نیست

- catalog service فقط `min>=1` و `max>=min` را validate می‌کند.
- runtime create room و engine رامی limit واقعی `2..6` دارند.
- UI باید validation رامی-specific داشته باشد.

### GAP-002: result persistence reason را ذخیره نمی‌کند

- forfeit reason و leavingPlayer فقط در websocket final event هستند.
- `GameResult` این metadata را نگه نمی‌دارد.
- admin result list/detail نمی‌تواند با قطعیت reason نهایی match را نشان دهد.

### GAP-003: blocked tie فقط hand-level است

- event `RIM_HAND_FINISHED` با `reason=BLOCKED_TIE` وجود دارد.
- ولی هیچ admin table برای hand history یا tie history وجود ندارد.
- panel فقط final match result را می‌بیند.

### GAP-004: stats endpointهای room/result global هستند

- `rooms/stats`
- `results/stats`

این‌ها رامی-specific نیستند. اگر KPI رامی-specific لازم است، از list filtered یا reports endpoint استفاده کن.

### GAP-005: error response shape در admin uniform نیست

- بعضی endpointها body خالی برمی‌گردانند.
- بعضی `{error}` برمی‌گردانند.
- بعضی exception code را اصلاً serialize نمی‌کنند.

---

## 11. Acceptance Checklist

پیاده‌سازی admin فقط وقتی complete محسوب می‌شود که این سناریوها pass شوند:

1. item بازی `RIM` در catalog پیدا، edit و enable/disable می‌شود.
2. rooms tab با `gameType=RIM` list و detail و cancel را درست handle می‌کند.
3. UI اجازه submit `min/max players` نامعتبر برای رامی را نمی‌دهد.
4. results tab list/detail/export رامی را بدون فرض team fields پیاده می‌کند.
5. reports tab با `gameType=RIM` summary و series صحیح می‌سازد.
6. UI روی نبود `reason` در persisted results دچار assumption غلط نمی‌شود.

