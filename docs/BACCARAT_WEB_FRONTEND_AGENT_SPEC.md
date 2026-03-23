# مستند اجرایی باکارات برای ایجنت فرانت وب

- نسخه: `1.0`
- تاریخ: `2026-03-12`
- وضعیت: `Frontend Agent Ready`
- دامنه: `Lobby + Room + Gameplay + History contracts برای BACCARAT`

---

## 1. هدف این سند

این سند باید برای ایجنت فرانت کافی باشد تا surface کاربر بازی باکارات را روی وب پیاده کند؛ شامل:

- قوانین runtime که روی UI اثر دارند
- flow ساخت room، ورود، خروج و شروع خودکار
- actionهای قابل ارسال به سرور
- eventهای دریافتی از سرور
- validationهای لازم قبل از ارسال
- state model پیشنهادی برای UI
- formatting score و نکات مهم history
- تفاوت raw wire message با aliasهای احتمالی فرانت

این سند feature جدید تعریف نمی‌کند. مرجع قطعی آن implementation فعلی backend است.

---

## 2. Source Of Truth

### فایل‌های مرجع

- `gameBackend/src/main/java/com/gameapp/game/services/BaccaratEngineService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/BaccaratBotStrategy.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WebSocketRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WsEnvelopeService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WebSocketMessageHandler.java`
- `gameBackend/src/main/java/com/gameapp/game/models/CreateGameRoomRequest.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameRoomListDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameCatalogDto.java`
- `gameBackend/src/main/java/com/gameapp/game/models/PublicGameConfigDto.java`
- `gameapp/lib/features/game/ui/game_ui/baccarat_game_ui.dart`
- `gameapp/lib/core/constants/game_types.dart`
- `gameapp/lib/core/utils/baccarat_utils.dart`
- `gameapp/lib/core/services/websocket_manager.dart`
- `gameapp/lib/core/websocket/ws_normalization_adapter.dart`

### اصل مهم

- اگر بین Flutter فعلی و backend اختلاف بود، backend معتبر است.
- اگر بین specهای قبلی و runtime فعلی اختلاف بود، runtime معتبر است.
- اگر بین raw wire type و normalized alias اختلاف بود، raw wire type مرجع اصلی است.

---

## 3. خلاصه قوانین runtime که روی فرانت اثر دارند

این بخش As-Is است؛ دقیقاً مطابق engine فعلی.

- بازی فقط `2` نفره است.
- variant بازی `Punto Banco` استاندارد است.
- match چند-handی است.
- `gameScore` روم یکی از این سه مقدار است:
  - `BACCARAT_TEN -> 10`
  - `BACCARAT_FIFTEEN -> 15`
  - `BACCARAT_TWENTY -> 20`
- اگر `gameScore` هنگام create room ارسال نشود، backend آن را `BACCARAT_TEN` می‌گذارد.

### مقدار کارت‌ها

- `A = 1`
- `2..9 = همان عدد`
- `10/J/Q/K = 0`
- مجموع دست = `sum(cards) % 10`

### نچرال

- اگر Player یا Banker در دو کارت اول `8` یا `9` شود، hand همان‌جا تمام می‌شود.

### قواعد کارت سوم

- Player روی `0..5` کارت می‌کشد.
- Player روی `6..7` می‌ایستد.
- اگر Player کارت سوم نکشد، Banker روی `0..5` می‌کشد.
- اگر Player کارت سوم `X` بکشد، Banker:
  - روی `0..2` همیشه می‌کشد
  - روی `3` مگر وقتی `X=8`
  - روی `4` وقتی `X in 2..7`
  - روی `5` وقتی `X in 4..7`
  - روی `6` وقتی `X in 6..7`
  - روی `7` نمی‌کشد

### انتخاب side

- sideهای معتبر:
  - `PLAYER`
  - `BANKER`
  - `TIE`
- انتخاب‌ها public و exclusive هستند.
- نفر اول از بین هر سه side انتخاب می‌کند.
- نفر دوم فقط از sideهای باقی‌مانده انتخاب می‌کند.
- انتخاب تکراری ممکن نیست.

### picker order

- دست اول: شروع‌کننده تصادفی است.
- دست‌های بعدی: first picker بین دو بازیکن rotate می‌شود.

### timeout

- timeout هر انتخاب `15` ثانیه است.
- در timeout، backend به‌ترتیب `BANKER > PLAYER > TIE` auto-pick می‌کند.

### scoring

- انتخاب درست `PLAYER = +100`
- انتخاب درست `BANKER = +95`
- انتخاب درست `TIE = +800`
- انتخاب اشتباه `= -100`
- اگر outcome=`TIE` و بازیکن `PLAYER` یا `BANKER` را زده باشد `= 0`

### پایان match

- match بعد از scheduled hands تمام می‌شود.
- اگر بعد از scheduled hands امتیازها مساوی باشند، `sudden death` فعال می‌شود.
- در `sudden death` تا وقتی امتیازها برابر باشند hand بعدی شروع می‌شود.

### forfeit

- اگر بازیکن در وضعیت `IN_PROGRESS` room را ترک کند، برای باکارات معادل باخت فوری است.
- backend تضمین می‌کند بازیکن باقی‌مانده final score بالاتری داشته باشد.
- finish event در این حالت `reason="FORFEIT"` دارد.

---

## 4. Dependency Summary

این موارد برای mount و navigation لازم‌اند ولی خودشان موضوع gameplay نیستند:

- کاربر authenticate شده باشد.
- WebSocket روی `/ws-v3` وصل و `AUTH` شده باشد.
- `roomId` از router یا lobby در دسترس باشد.
- current user id برای تشخیص turn و score row در دسترس باشد.
- room page باید generic room flow را از gameplay باکارات جدا نگه دارد.

---

## 5. WS Endpoint, Envelope, Error Rules

## 5.1 Endpoint

- `endpoint`: `/ws-v3`

## 5.2 Envelope baseline

نمونه generic action:

```json
{
  "type": "GAME_ACTION",
  "action": "BACCARAT_PICK_SIDE",
  "roomId": 123,
  "clientActionId": "1c4ab9b0-2b8d-4af4-b79c-4c5f449aa001",
  "data": {
    "gameStateId": 456,
    "betSide": "BANKER",
    "stateVersion": 12
  }
}
```

نمونه generic success:

```json
{
  "type": "GAME_ACTION",
  "action": "BACCARAT_ROUND_STARTED",
  "roomId": 123,
  "success": true,
  "data": {},
  "eventId": "...",
  "traceId": "...",
  "serverTime": "...",
  "protocolVersion": 3,
  "stateVersion": 12
}
```

نمونه generic error:

```json
{
  "type": "ERROR",
  "action": "GAME_ACTION",
  "roomId": 123,
  "success": false,
  "errorCode": "VALIDATION_ERROR",
  "error": "message"
}
```

### فیلدهایی که فرانت باید parse کند

- `type`
- `action`
- `roomId`
- `success`
- `data`
- `errorCode`
- `error`
- `eventId`
- `traceId`
- `serverTime`
- `protocolVersion`
- `stateVersion`
- `clientActionId`

### قواعد عملی برای وب

- برای همه `GAME_ACTION`ها این فیلدها را بفرست:
  - top-level `roomId`
  - top-level `clientActionId`
  - nested `data.stateVersion`
- روی `ACTION_ACK` به‌عنوان state source تکیه نکن.
- state نهایی فقط از eventهای `BACCARAT_*` یا resnapshot می‌آید.
- `playerId` را نفرست، یا اگر فرستادی آن را authoritative فرض نکن؛ session user مرجع نهایی است.

---

## 6. Generic Lobby / Room Contracts

## 6.1 Game Catalog

- request:

```json
{
  "type": "GET_GAME_CATALOG"
}
```

- response:

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

- برای باکارات:
  - `gameType = "BACCARAT"`
  - `minPlayers = 2`
  - `maxPlayers = 2`

## 6.2 Public Game Configs

- endpoint:
  - `GET /api/game-configs/active`

- response:

```ts
export interface PublicGameConfigDto {
  gameKey: string;
  displayName: string;
  emoji: string;
  minBet: number;
  maxBet: number;
}
```

- برای باکارات:
  - `gameKey = "baccarat"`
  - `displayName = "Baccarat"`
  - `emoji = "💎"`

## 6.3 Room List

- request:

```json
{
  "type": "GET_ROOM_LIST",
  "gameType": "BACCARAT"
}
```

- raw push/update types در wire:
  - `room_list`
  - `room_update`
  - `room_created`
- اگر client adapter normalize کند:
  - `room_list -> ROOM_LIST`
  - `room_created -> ROOM_CREATED_STREAM`
  - `room_update -> ROOM_UPDATE`
- current mobile implementation هنوز روی raw lowercase گوش می‌دهد.

- `room_list` payload shape:

```json
{
  "type": "room_list",
  "success": true,
  "gameType": "BACCARAT",
  "data": {
    "rooms": []
  }
}
```

- فقط roomهای `PENDING` و joinable در list می‌آیند.
- room full دیگر در room list باقی نمی‌ماند.

## 6.4 GameRoomListDto

```ts
export interface GameRoomUserDto {
  id: number;
  username: string;
  email: string;
  avatarUrl?: string | null;
  level?: number | null;
}

export interface GameRoomPlayerDto {
  id: number;
  user: GameRoomUserDto;
  status: string;
  seatNumber?: number | null;
  teamId?: number | null;
  score?: number | null;
  isReady?: boolean | null;
  handCards?: Array<Record<string, unknown>>;
  isBot?: boolean | null;
  botDifficulty?: string | null;
}

export interface GameRoomListDto {
  id: number;
  gameType: string;
  roomType: string;
  entryFee: string;
  gameScore: string;
  diceWinnerType?: string | null;
  maxPlayers: number;
  roomCode?: string | null;
  roomStatus: string;
  botAssisted?: boolean;
  botMode?: string | null;
  botCount?: number | null;
  createdBy?: GameRoomUserDto | null;
  players: GameRoomPlayerDto[];
  onlinePlayersCount?: number | null;
  createdAt?: string | null;
}
```

### Baccarat-specific UI rules

- `maxPlayers` را همیشه `2` فرض کن.
- `players[].score` در room DTO برای باکارات raw scaled integer است.
- room page نباید اجازه انتخاب maxPlayers یا score غیرمجاز بدهد.
- rollout بات برای باکارات در این پاس فقط `internal/tester rooms` است و `public beta` خارج از scope می‌ماند.

## 6.5 Subscribe / Join / Get Room / Leave

- subscribe lobby:

```json
{
  "type": "SUBSCRIBE_ROOMS",
  "gameType": "BACCARAT"
}
```

- success:
  - `SUBSCRIBE_ROOMS_SUCCESS`
  - بعد از آن معمولاً `room_list`

- join:

```json
{
  "type": "JOIN_ROOM",
  "roomId": 123
}
```

- success:

```json
{
  "type": "JOIN_ROOM_SUCCESS",
  "success": true,
  "data": {
    "roomId": 123
  }
}
```

- get room:

```json
{
  "type": "GET_ROOM",
  "roomId": 123
}
```

- response:
  - `ROOM_DETAILS` با `data: GameRoomListDto`

- leave:

```json
{
  "type": "LEAVE_ROOM",
  "roomId": 123
}
```

- success:
  - `LEAVE_ROOM_SUCCESS`
- نکته:
  - اگر room در `IN_PROGRESS` باشد، برای باکارات این action gameplay را با forfeit تمام می‌کند.

---

## 7. Create Room Contract

request:

```json
{
  "type": "CREATE_ROOM",
  "gameType": "BACCARAT",
  "roomType": "PUBLIC",
  "entryFee": "<shared EntryFee enum>",
  "maxPlayers": 2,
  "gameScore": "BACCARAT_TEN"
}
```

### validation

- `gameType`, `roomType`, `entryFee` اجباری هستند.
- اگر `gameScore` خالی باشد، backend آن را `BACCARAT_TEN` می‌کند.
- `gameScore` فقط یکی از این سه مقدار:
  - `BACCARAT_TEN`
  - `BACCARAT_FIFTEEN`
  - `BACCARAT_TWENTY`
- `maxPlayers` برای باکارات همیشه `2` normalize می‌شود.
- create روی بازی disabled در `game_catalog` باید fail شود.
- کاربر باید برای entry fee سکه کافی داشته باشد.
- rate limit ساخت room: حداکثر `5` بار در دقیقه به‌ازای هر کاربر.

### success

- `ROOM_CREATED` با `data: GameRoomListDto`

### async side-effects

- بعد از create، creator داخل room عضو می‌شود.
- اگر room public باشد، push lobby هم ممکن است از `room_created` یا `room_update` برسد.

---

## 8. Invitation Contracts

این بخش dependency gameplay نیست، ولی برای private-room flow باکارات مهم است.

## 8.1 Send Invitation

- request:

```json
{
  "type": "SEND_GAME_INVITATION",
  "receiverId": 77,
  "gameType": "BACCARAT",
  "entryFee": 500,
  "maxPlayers": 2
}
```

- یا می‌توان از room فعلی derive کرد:

```json
{
  "type": "SEND_GAME_INVITATION",
  "receiverId": 77,
  "roomId": 123
}
```

### validation

- `receiverId` اجباری
- اگر `roomId` داده نشده باشد:
  - `gameType`
  - `entryFee`
  - `maxPlayers`
  باید موجود باشند
- برای باکارات `maxPlayers` همیشه `2` normalize می‌شود

### response

- `GAME_INVITATION_SENT`
- payload:

```ts
export interface GameInvitationDto {
  id: number;
  invitationId: number;
  sender: {
    id: number;
    username: string;
    avatarUrl?: string | null;
  };
  receiver: {
    id: number;
    username: string;
    avatarUrl?: string | null;
  };
  gameType: string;
  entryFee: number;
  maxPlayers: number;
  status: string;
  createdAt: string;
  respondedAt?: string | null;
  expiresAt: string;
  rejectionReason?: string | null;
}
```

## 8.2 Accept / Reject / Cancel / List

- accept:

```json
{
  "type": "ACCEPT_GAME_INVITATION",
  "invitationId": 9001
}
```

- reject:

```json
{
  "type": "REJECT_GAME_INVITATION",
  "invitationId": 9001,
  "reason": "busy"
}
```

- cancel:

```json
{
  "type": "CANCEL_GAME_INVITATION",
  "invitationId": 9001
}
```

- get received:

```json
{
  "type": "GET_RECEIVED_INVITATIONS"
}
```

- get sent:

```json
{
  "type": "GET_SENT_INVITATIONS"
}
```

### success types

- `GAME_INVITATION_ACCEPTED`
- `GAME_INVITATION_REJECTED`
- `GAME_INVITATION_CANCELLED`
- `RECEIVED_INVITATIONS`
- `SENT_INVITATIONS`

### Baccarat-specific rule

- invitation row یا modal برای باکارات باید `2 نفره` بودن را explicit نشان دهد.

---

## 9. Auto Start Flow

- وقتی room full شود:
  - room به `IN_PROGRESS` می‌رود
  - `room_update` به room page و lobby فرستاده می‌شود
  - engine start با delay داخلی انجام می‌شود
- frontend نباید start دستی بفرستد.
- صفحه game بعد از `roomStatus=IN_PROGRESS` باید منتظر `BACCARAT_ROUND_STARTED` بماند.

### نتیجه مهم برای UI

- `ROOM_DETAILS.roomStatus === IN_PROGRESS` به معنی شروع gameplay websocket events در لحظه بعد است، نه اینکه state gameplay already موجود باشد.

---

## 10. Boot Flow صفحه بازی

در mount صفحه:

1. listener `GAME_ACTION` را register کن.
2. listenerهای room-level لازم را register کن.
3. اگر room object آماده نیست، `GET_ROOM` بزن.
4. وارد صفحه gameplay شو و منتظر اولین `BACCARAT_ROUND_STARTED` یا eventهای بعدی بمان.
5. state reducer را روی payloadهای `BACCARAT_*` بنا کن، نه روی UI local.

### eventهایی که صفحه بازی باید handle کند

- `BACCARAT_ROUND_STARTED`
- `BACCARAT_SIDE_PICKED`
- `BACCARAT_SIDE_AUTO_PICKED`
- `BACCARAT_HAND_REVEALED`
- `BACCARAT_ROUND_RESULT`
- `BACCARAT_GAME_FINISHED`
- `BOT_DECISION_DEBUG`

---

## 11. Baccarat Gameplay Action Catalog

تنها action اختصاصی بازی:

```json
{
  "type": "GAME_ACTION",
  "action": "BACCARAT_PICK_SIDE",
  "roomId": 123,
  "data": {
    "gameStateId": 456,
    "betSide": "PLAYER"
  }
}
```

### validation قبل از ارسال

- `gameStateId` باید موجود باشد.
- `betSide` فقط `PLAYER | BANKER | TIE`
- فقط وقتی `myUserId === currentPickerPlayerId`
- فقط وقتی `betSide` داخل `availableBetSides` باشد
- اگر `_currentPickerPlayerId == null` اکشن نفرست

### validation سمت backend

- `gameStateId` و `betSide` اجباری
- `betSide` نامعتبر -> reject
- بازیکن خارج از turn -> reject
- side گرفته‌شده قبلی -> reject

---

## 12. Baccarat Event Catalog

## 12.1 Base fields

این فیلدها تقریباً در همه eventهای باکارات وجود دارند:

- `gameStateId`
- `roomId`
- `currentRound`
- `scheduledHands`
- `suddenDeath`
- `currentPickerPlayerId`
- `scores`
- `finalScores`
- `players`

`players[]`:

```ts
export interface BaccaratPlayerView {
  playerId: number;
  username: string;
  seatNumber: number;
  score: number;
  isCurrentPicker: boolean;
  selectedSide?: "PLAYER" | "BANKER" | "TIE" | null;
  isBot: boolean;
  botDifficulty?: string | null;
}
```

## 12.2 `BACCARAT_ROUND_STARTED`

```ts
export interface BaccaratRoundStartedPayload {
  gameStateId: number;
  roomId: number;
  currentRound: number;
  scheduledHands: number;
  suddenDeath: boolean;
  currentPickerPlayerId: number | null;
  scores: Record<string, number>;
  finalScores: Record<string, number>;
  players: BaccaratPlayerView[];
  availableBetSides: Array<"BANKER" | "PLAYER" | "TIE">;
  lockedSelections: Record<string, "BANKER" | "PLAYER" | "TIE">;
  selectionTimeoutSeconds: number;
  shoeRemaining: number;
}
```

UI effect:

- reset reveal state
- reset round outcome
- reset deltas
- start selection timer

## 12.3 `BACCARAT_SIDE_PICKED`

فیلدهای جدید:

- `playerId`
- `betSide`
- `availableBetSides`
- `lockedSelections`
- `selectionTimeoutSeconds`

UI effect:

- side انتخاب‌شده را قفل کن
- message مناسب نشان بده
- اگر picker جدید وجود دارد، timer را resync کن

## 12.4 `BACCARAT_SIDE_AUTO_PICKED`

- payload همان `BACCARAT_SIDE_PICKED`
- فقط label/UX فرق دارد

UI effect:

- همان side picked
- label باید auto-pick را از pick دستی distinguish کند

## 12.5 `BACCARAT_HAND_REVEALED`

```ts
export interface BaccaratHandRevealedPayload {
  gameStateId: number;
  roomId: number;
  currentRound: number;
  scheduledHands: number;
  suddenDeath: boolean;
  currentPickerPlayerId: null;
  scores: Record<string, number>;
  finalScores: Record<string, number>;
  players: BaccaratPlayerView[];
  lockedSelections: Record<string, "BANKER" | "PLAYER" | "TIE">;
  playerCards: string[];
  bankerCards: string[];
  playerTotal: number;
  bankerTotal: number;
  playerThirdCard?: string | null;
  bankerThirdCard?: string | null;
  playerNatural: boolean;
  bankerNatural: boolean;
  roundOutcome: "PLAYER" | "BANKER" | "TIE";
  scoreDeltas: Record<string, number>;
  shoeRemaining: number;
}
```

UI effect:

- reveal cards
- stop timer
- توضیح reveal نشان بده:
  - natural
  - فقط Player کارت سوم گرفت
  - فقط Banker کارت سوم گرفت
  - هر دو کارت سوم گرفتند

## 12.6 `BACCARAT_ROUND_RESULT`

فیلدهای مهم:

- `lockedSelections`
- `roundOutcome`
- `scoreDeltas`
- `playerCards`
- `bankerCards`
- `playerTotal`
- `bankerTotal`
- `shoeRemaining`
- `isScheduledHandsComplete`

UI effect:

- scoreboard را از `finalScores` آپدیت کن
- message نتیجه دست را بساز
- اگر `isScheduledHandsComplete=true` و `suddenDeath=false` است، منتظر finish یا sudden-death hand بعدی بمان

## 12.7 `BACCARAT_GAME_FINISHED`

```ts
export interface BaccaratGameFinishedPayload {
  gameId: number;
  winnerId?: number | null;
  winnerUsername?: string | null;
  finalScores: Record<string, number>;
  scores: Record<string, number>;
  scheduledHands: number;
  actualHandsPlayed: number;
  suddenDeath: boolean;
  coinRewards: Record<string, number>;
  xpRewards: Record<string, number>;
  reason?: "FORFEIT" | string;
  leavingPlayer?: string;
}
```

UI effect:

- game را finished mark کن
- scoreهای نهایی را از `finalScores` بردار
- dialog پایان بازی را باز کن
- اگر `reason === "FORFEIT"` بود:
  - متن مخصوص ترک بازیکن
  - `leavingPlayer` را نمایش بده

## 12.8 `BOT_DECISION_DEBUG`

- فقط برای internal test room مهم است.
- user panel عمومی می‌تواند نادیده‌اش بگیرد.

---

## 13. Payload Semantics

### `availableBetSides`

- شروع هر hand:
  - `["BANKER","PLAYER","TIE"]`
- بعد از هر pick کوچک‌تر می‌شود.

### `lockedSelections`

- map با key از نوع `playerId` string
- مثال:

```json
{
  "41": "BANKER",
  "77": "PLAYER"
}
```

### `scoreDeltas`

- map با key از نوع `playerId` string
- مقدار raw scaled integer

### `scores`

- map با key از نوع username
- فقط convenience است
- برای state پایدار روی آن تکیه نکن

### `finalScores`

- map با key از نوع `playerId` string
- مرجع نهایی rendering همین map است

### `playerCards` / `bankerCards`

- string array
- مثال:

```json
["A♠", "10♦", "6♣"]
```

### `currentPickerPlayerId = null`

- یعنی فاز انتخاب تمام شده و hand در حال reveal / result است

---

## 14. Formatting Rules

backend scoreها را display-ready برنمی‌گرداند.

### هرجا score باکارات می‌بینی، raw است

- `players[].score`
- `scoreDeltas`
- `finalScores`
- `GAME_HISTORY_USER.sessions[].score`
- `GAME_HISTORY_USER.sessions[].participants[].finalScore`
- `GAME_RECENT_USER.sessions[].score`
- `GAME_RECENT_USER.sessions[].participants[].finalScore`
- `AdminGameResultDto.participantsScores`

### display formatter

```ts
export function formatBaccaratScore(raw: number | null | undefined): string {
  return ((raw ?? 0) / 100).toFixed(2);
}
```

### نمونه

- `95 -> "0.95"`
- `-100 -> "-1.00"`
- `800 -> "8.00"`

---

## 15. History / Recent Contracts

## 15.1 `GET_GAME_HISTORY_USER`

- request:

```json
{
  "type": "GET_GAME_HISTORY_USER",
  "limit": 100
}
```

- `limit` اختیاری است.
- backend مقدار را بین `1..100` clamp می‌کند.
- مقدار پیش‌فرض `100` است.

- response:
  - `GAME_HISTORY_USER`
  - `data.sessions: Array<Record<string, unknown>>`

### فیلدهای مهم برای باکارات

- `id`
- `gameRoomId`
- `gameType`
- `winnerId`
- `totalRounds`
- `durationMinutes`
- `startedAt`
- `finishedAt`
- `createdAt`
- `score`
- `won`
- `entryFee`
- `roomType`
- `roomCode`
- `maxPlayers`
- `participants[]`

`participants[]`:

- `id`
- `username`
- `email`
- `avatarUrl`
- `level`
- `coins`
- `xp`
- `seatNumber`
- `teamId`
- `finalScore`

### نکته مهم

- `score` و `participants[].finalScore` برای باکارات raw scaled integer هستند.

## 15.2 `GET_GAME_RECENT_USER`

- request:

```json
{
  "type": "GET_GAME_RECENT_USER",
  "limit": 20
}
```

- `limit` اختیاری است.
- backend مقدار را بین `1..100` clamp می‌کند.
- مقدار پیش‌فرض `20` است.

- response type:
  - `GAME_RECENT_USER`

---

## 16. UI Requirements

- route بازی:
  - `/game/baccarat/:roomId`
- room creation:
  - فقط این score optionها:
    - `BACCARAT_TEN`
    - `BACCARAT_FIFTEEN`
    - `BACCARAT_TWENTY`
  - label نمایشی:
    - `10 دست`
    - `15 دست`
    - `20 دست`
- `maxPlayers` برای باکارات editable نیست.
- selector side:
  - فقط وقتی `myUserId === currentPickerPlayerId`
  - فقط روی sideهای داخل `availableBetSides`
- timer:
  - از `selectionTimeoutSeconds`
  - در `ROUND_STARTED`
  - بعد از pick اول هم resync
- scoreboard:
  - row هر بازیکن باید score raw را decimal نشان دهد
- hand reveal:
  - Player و Banker panel جدا
  - نمایش total
  - نمایش third-card explanation
  - نمایش natural flag
- sudden death:
  - باید indicator واضح داشته باشد
- finish dialog:
  - winner
  - final scores
  - reward summary
  - forfeit message در صورت لزوم

---

## 17. Validation / Error Handling

## 17.1 خطاهای مهم create/join

- بازی disabled:
  - create/join باید fail شود
- room full:
  - join fail
- coin ناکافی:
  - create/join fail
- room started:
  - join fail

UI fallback برای error body:

- `body.error`
- `body.message`
- status text

## 17.2 خطاهای مهم gameplay

- `Missing BACCARAT_PICK_SIDE data`
- `Invalid baccarat side`
- `It is not your turn to pick a baccarat side`
- `Side is not available`

قانون UI:

- قبل از ارسال local-validate کن
- اگر با وجود validate، `ERROR` رسید:
  - toast نشان بده
  - local optimistic state را authoritative فرض نکن

---

## 18. Acceptance Checklist

- create room بدون `gameScore` باید در runtime به `BACCARAT_TEN` برسد.
- باکارات در UI همیشه 2 نفره باشد.
- room وقتی full شد بدون action دستی start شود.
- نفر دوم side انتخاب‌شده نفر اول را نبیند.
- timeout باید event `BACCARAT_SIDE_AUTO_PICKED` تولید کند.
- بعد از reveal، `BACCARAT_ROUND_RESULT` باید score delta و outcome بدهد.
- اگر امتیازها بعد از scheduled hands مساوی بود، `suddenDeath=true` در payload دیده شود.
- در `BACCARAT_GAME_FINISHED` اگر reason=`FORFEIT` بود، UI متن مناسب بسازد.
- history/recent و scoreboard باید raw score را decimal نمایش دهند، نه integer خام.

---

## 19. Out Of Scope

- side betها
- no-commission baccarat
- house-banked single-player flow
- burn card / cut card / squeeze animation
- admin gameplay controls
