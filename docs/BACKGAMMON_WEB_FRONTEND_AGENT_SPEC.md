# مستند اجرایی تخته‌نرد برای ایجنت فرانت وب

- نسخه: `1.0`
- تاریخ: `2026-03-12`
- وضعیت: `Frontend Agent Ready`
- دامنه: `Lobby + Room + Gameplay + Resync contract برای BACKGAMMON`

---

## 1. هدف این سند

این سند باید برای ایجنت فرانت وب کافی باشد تا surface کاربر تخته‌نرد را روی runtime فعلی پیاده کند؛ شامل:

- قوانین gameplay که روی UI اثر دارند
- state model و shape دقیق payloadها
- actionهای ارسالی و eventهای دریافتی
- validationهای لازم قبل از ارسال action
- bootstrap و resync از طریق snapshot
- رفتار صفحه room و gameplay
- محدودیت‌های قطعی v1

این سند feature جدید تعریف نمی‌کند. مرجع قطعی آن implementation فعلی backend و contract فعلی websocket است.

---

## 2. Source Of Truth

### فایل‌های مرجع

- `gameBackend/src/main/java/com/gameapp/game/services/BackgammonEngineService.java`
- `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameState.java`
- `gameapp/lib/core/services/websocket_manager.dart`
- `gameapp/lib/core/websocket/ws_contract_catalog.dart`
- `gameapp/lib/features/game/data/models/backgammon_game_state.dart`
- `docs/chat2.txt`
- `docs/GameApp_Summary.md`

### اصل مهم

- اگر بین این سند و backend اختلاف بود، backend معتبر است.
- اگر بین shape raw snapshot و eventهای gameplay اختلاف بود، فرانت باید هر دو را parse کند.
- اگر بین `ACTION_ACK` و state نهایی اختلاف بود، state نهایی فقط از event یا snapshot معتبر است.

---

## 3. خلاصه runtime و محدودیت‌های قطعی

- بازی فقط `2` نفره است.
- `seat 1 = WHITE` و جهت حرکت `24 -> 1`
- `seat 2 = BLACK` و جهت حرکت `1 -> 24`
- bot-assisted برای `public rooms` تخته‌نرد پشتیبانی نمی‌شود.
- bot-assisted برای `internal/tester rooms` پشتیبانی می‌شود.
- `doubling cube`, `resign`, `spectator`, `replay`, `admin force move` در v1 وجود ندارند.
- `targetScore` فقط یکی از این سه مقدار است:
  - `BACKGAMMON_THREE -> 3`
  - `BACKGAMMON_FIVE -> 5`
  - `BACKGAMMON_SEVEN -> 7`
- coin reward فقط به برنده نهایی match می‌رسد.
- `GAMMON` و `BACKGAMMON` فقط امتیاز match را بیشتر می‌کنند و coin اضافه نمی‌دهند.
- در `BACKGAMMON_GAME_FINISHED`، `coinRewards` و `xpRewards` فقط با کلید `userId` برمی‌گردند.

---

## 4. قوانین gameplay که روی فرانت اثر دارند

### 4.1 چیدمان اولیه

- سفید:
  - `24:2`
  - `13:5`
  - `8:3`
  - `6:5`
- سیاه:
  - `1:2`
  - `12:5`
  - `17:3`
  - `19:5`

### 4.2 شروع hand

- هر دو بازیکن opening roll می‌زنند.
- در صورت مساوی بودن، reroll می‌شود.
- برنده hand را با همان دو تاس شروع می‌کند.
- بنابراین start hand با `phase = MOVING_PIECES` شروع می‌شود، نه `ROLLING_DICE`.

### 4.3 phases

فقط این phaseها معتبرند:

- `ROLLING_DICE`
- `MOVING_PIECES`
- `HAND_FINISHED`
- `FINISHED`

### 4.4 قواعد حرکت

- هر تاس یک move مستقل است.
- doubles به 4 move از همان مقدار تبدیل می‌شود.
- اگر مهره روی bar باشد، قبل از هر حرکت دیگری باید re-entry انجام شود.
- مقصد فقط وقتی باز است که حریف روی آن کمتر از `2` مهره داشته باشد.
- bearing off فقط وقتی مجاز است که همه مهره‌های بازیکن در home board خودش باشند.
- اگر bearing off exact نباشد، فقط وقتی مجاز است که مهره‌ای دورتر از home باقی نمانده باشد.

### 4.5 قوانین product-specific

- `بزرگ میره تو` enforce شده:
  - اگر تاس‌ها distinct باشند و فقط یکی از آن‌ها قابل استفاده باشد، باید تاس بزرگ‌تر استفاده شود.
- lock after hit in home board enforce شده:
  - اگر بازیکن در home board خودش hit کند، همان مهره تا پایان همان turn قفل می‌شود.
  - این lock در `lockedCountsByPoint` برمی‌گردد.

### 4.6 پایان hand و match

- اگر بازنده حداقل یک مهره borne-off کرده باشد:
  - `SIMPLE = 1 point`
- اگر بازنده هیچ مهره‌ای borne-off نکرده باشد:
  - `GAMMON = 2 points`
- اگر بازنده هیچ مهره‌ای borne-off نکرده باشد و حداقل یک مهره روی bar یا در home حریف داشته باشد:
  - `BACKGAMMON = 3 points`
- match وقتی تمام می‌شود که یک بازیکن به `targetScore` برسد.

### 4.7 timeout

- timeout هر turn = `25s`
- اگر `phase = ROLLING_DICE`:
  - سرور auto-roll می‌کند
- اگر `phase = MOVING_PIECES`:
  - سرور به‌صورت deterministic از اولین optimal sequence auto-play می‌کند
- `3s` بعد از `HAND_FINISHED`، hand بعدی خودکار شروع می‌شود.

---

## 5. Room و Lobby Contract

### 5.1 create room

برای room creation:

- `gameType = BACKGAMMON`
- `roomType = PUBLIC | PRIVATE`
- `entryFee` یکی از enumهای عمومی سیستم
- `gameScore` یکی از:
  - `BACKGAMMON_THREE`
  - `BACKGAMMON_FIVE`
  - `BACKGAMMON_SEVEN`
- اگر `gameScore` ارسال نشود، backend آن را `BACKGAMMON_THREE` می‌گذارد.

### 5.2 قواعد UI برای room creation

- UI باید `maxPlayers = 2` را lock کند.
- UI نباید bot-assisted option برای Backgammon نشان بدهد.
- label کاربر-facing برای score:
  - `3 امتیاز`
  - `5 امتیاز`
  - `7 امتیاز`

---

## 6. WebSocket Baseline

### 6.1 endpoint

- `ws endpoint = /ws-v3`

### 6.2 envelope baseline

برای همه actionهای gameplay این‌ها لازم‌اند:

- `type = GAME_ACTION`
- `action`
- `roomId`
- `clientActionId`
- `data`
- `data.stateVersion`

### 6.3 رفتار عمومی

- `ACTION_ACK` فقط پذیرش در صف است.
- موفقیت نهایی gameplay فقط از `GAME_ACTION` eventها یا `STATE_SNAPSHOT` فهمیده می‌شود.
- اگر `ERROR.errorCode = STATE_RESYNC_REQUIRED` آمد:
  - فوراً `GET_GAME_STATE_BY_ROOM` بزن
  - local state را با `STATE_SNAPSHOT` replace کامل کن
- `playerId` payload باید با کاربر authenticate شده یکی باشد.
- duplicate `clientActionId` باعث `ACTION_ACK` با `duplicate=true` می‌شود.

---

## 7. Action Catalog

## 7.1 GET_GAME_STATE_BY_ROOM

### request

```json
{
  "type": "GET_GAME_STATE_BY_ROOM",
  "roomId": 41
}
```

### response

- `type = STATE_SNAPSHOT`

### نکته مهم

- snapshot raw `GameState` entity است، نه full-state event هم‌شکل gameplay.

## 7.2 BACKGAMMON_ROLL_DICE

### request

```json
{
  "type": "GAME_ACTION",
  "action": "BACKGAMMON_ROLL_DICE",
  "roomId": 41,
  "clientActionId": "bg-roll-41-12",
  "data": {
    "gameStateId": 10,
    "playerId": 300,
    "stateVersion": 12
  }
}
```

### client-side validation

- room باید `IN_PROGRESS` باشد
- نوبت همان بازیکن باشد
- `phase = ROLLING_DICE`

### expected flow

- `ACTION_ACK`
- سپس `BACKGAMMON_STATE_UPDATED`

## 7.3 BACKGAMMON_MOVE_CHECKER

### request

```json
{
  "type": "GAME_ACTION",
  "action": "BACKGAMMON_MOVE_CHECKER",
  "roomId": 41,
  "clientActionId": "bg-move-41-13",
  "data": {
    "gameStateId": 10,
    "playerId": 300,
    "fromPoint": 8,
    "toPoint": 3,
    "usedDie": 5,
    "stateVersion": 13
  }
}
```

### client-side validation

- room باید `IN_PROGRESS` باشد
- نوبت همان بازیکن باشد
- `phase = MOVING_PIECES`
- `remainingDice` خالی نباشد
- `(fromPoint, toPoint, usedDie)` دقیقاً یکی از `legalMoves` باشد

### expected flow

- `ACTION_ACK`
- سپس یکی از این‌ها:
  - `BACKGAMMON_STATE_UPDATED`
  - `BACKGAMMON_HAND_FINISHED`
  - `BACKGAMMON_GAME_FINISHED`

---

## 8. Event Catalog

incoming gameplay eventها فقط این‌ها هستند:

- `BACKGAMMON_GAME_STARTED`
- `BACKGAMMON_STATE_UPDATED`
- `BACKGAMMON_HAND_FINISHED`
- `BACKGAMMON_GAME_FINISHED`
- `BOT_DECISION_DEBUG`

همه این eventها full-state هستند و داخل `data` state کامل دارند.

### فیلدهای مشترک state

```ts
type Phase = 'ROLLING_DICE' | 'MOVING_PIECES' | 'HAND_FINISHED' | 'FINISHED'
type Color = 'WHITE' | 'BLACK'
type MatchResultType = 'SIMPLE' | 'GAMMON' | 'BACKGAMMON'

type BackgammonPoint = {
  point: number
  whiteCount: number
  blackCount: number
}

type BackgammonMove = {
  fromPoint: number
  toPoint: number
  usedDie: number
  hitsOpponent: boolean
  bearsOff: boolean
  fromBar: boolean
  locksChecker: boolean
}

type BackgammonPlayer = {
  playerId: number
  username: string
  seatNumber: 1 | 2
  color: Color
  score: number
  isBot: boolean
  botDifficulty?: string | null
}

type BackgammonState = {
  roomId: number
  gameStateId: number
  stateVersion: number
  phase: Phase
  currentRound: number
  handNumber: number
  targetScore: 3 | 5 | 7
  currentPlayerId: number | null
  currentTurnPlayerId: number | null
  turnTimeoutSeconds: number
  matchPointsByUserId: Record<string, number>
  matchPointsByUsername: Record<string, number>
  colorsByUserId: Record<string, Color>
  points: BackgammonPoint[]
  barByColor: { WHITE: number; BLACK: number }
  borneOffByColor: { WHITE: number; BLACK: number }
  diceValues: number[]
  remainingDice: number[]
  legalMoves: BackgammonMove[]
  lockedCountsByPoint: Record<string, number>
  openingRoll?: {
    WHITE: number
    BLACK: number
    startingColor: Color
    startingPlayerId: number
  } | null
  lastMove?: Record<string, unknown> | null
  players: BackgammonPlayer[]
  winnerId?: number | null
  winnerUsername?: string | null
  resultType?: MatchResultType | null
  awardedPoints?: number | null
  finalScores?: Record<string, number>
  finalScoresByUserId?: Record<string, number>
  coinRewards?: Record<string, number>
  xpRewards?: Record<string, number>
  reason?: string | null
  leavingPlayer?: string | null
}
```

### absolute point contract

- `points` همیشه absolute هستند و `1..24` را پوشش می‌دهند.
- special point mapping:
  - `WHITE bar source = 25`
  - `BLACK bar source = 0`
  - `WHITE bear-off target = 0`
  - `BLACK bear-off target = 25`

### HAND_FINISHED additions

- `winnerId`
- `winnerUsername`
- `resultType`
- `awardedPoints`

### GAME_FINISHED additions

- `winnerId`
- `winnerUsername`
- `finalScores`
- `finalScoresByUserId`
- `coinRewards`
- `xpRewards`
- `reason`
- `leavingPlayer`
- `resultType`

### reward contract

- `coinRewards: Record<userId, number>`
- `xpRewards: Record<userId, number>`
- برنده در `coinRewards` مقدار non-zero می‌گیرد و بقیه بازیکن‌ها `0`
- در rollout مهاجرت، کلاینت‌ها می‌توانند legacy fallback را هم tolerate کنند، ولی contract نهایی backend فقط userId-keyed است.

## 8.1 `BOT_DECISION_DEBUG`

- فقط برای `internal/tester rooms` مهم است.
- roomهای عمومی می‌توانند آن را ignore کنند.

```ts
type BackgammonBotDecisionDebug =
  | {
      roomId: number
      botUserId: number
      action: "ROLL_DICE"
    }
  | {
      roomId: number
      botUserId: number
      action: "MOVE_CHECKER"
      fromPoint: number
      toPoint: number
      usedDie: number
    }
```

- UX پیشنهادی:
  - `ROLL_DICE -> "<username>: تاس ریخت"`
  - `MOVE_CHECKER -> "<username>: <from> -> <to> با تاس <usedDie>"`

### lastMove.kind values

در runtime فعلی این مقادیر ممکن‌اند:

- `HAND_STARTED`
- `ROLL`
- `MOVE`
- `NO_LEGAL_MOVES`
- `TIMEOUT_NO_MOVE`

---

## 9. Snapshot Normalization

برای `STATE_SNAPSHOT`، backend raw entity برمی‌گرداند. فرانت باید آن را به Backgammon UI state normalize کند.

### shape خام snapshot

```json
{
  "type": "STATE_SNAPSHOT",
  "success": true,
  "roomId": 41,
  "data": {
    "id": 10,
    "gameRoomId": 41,
    "currentRound": 2,
    "currentPlayerId": 300,
    "gameSpecificData": {
      "stateVersion": 19,
      "phase": "ROLLING_DICE",
      "handNumber": 2,
      "targetScore": 5,
      "points": [],
      "barByColor": { "WHITE": 0, "BLACK": 1 },
      "borneOffByColor": { "WHITE": 7, "BLACK": 3 },
      "legalMoves": []
    }
  }
}
```

### normalization rules

- `gameStateId = data.id`
- `roomId = envelope.roomId || data.gameRoomId`
- `currentRound = data.currentRound`
- `currentPlayerId = data.currentPlayerId`
- بقیه state از `data.gameSpecificData`
- merge جزئی ممنوع است
- snapshot باید replace کامل local state باشد

---

## 10. UI Behavior Contract

### 10.1 board orientation

UI باید local-player-oriented باشد:

- اگر local color = `WHITE`
  - ردیف بالا: `13..24`
  - ردیف پایین: `12..1`
- اگر local color = `BLACK`
  - ردیف بالا: `12..1`
  - ردیف پایین: `13..24`

### 10.2 الزامات صفحه gameplay

- board با 24 point
- bar zone
- borne-off zone
- نمایش `diceValues`
- نمایش `remainingDice`
- نمایش turn و phase
- نمایش timer
- نمایش match score
- نمایش opening roll summary
- نمایش last move summary
- dialog نتیجه hand
- dialog نتیجه game

### 10.3 interaction rules

- source point فقط از بین pointهایی selectable است که در `legalMoves.fromPoint` باشند
- destination فقط از بین moveهای همان source هایلایت شود
- اگر bar move موجود باشد، فقط همان sourceها/مقصدهای re-entry selectable باشند
- client نباید legality engine محلی داشته باشد
- client نباید چند move را پشت سر هم locally queue کند
- بعد از هر move باید منتظر state جدید سرور بماند
- roll button فقط وقتی فعال باشد که:
  - `phase = ROLLING_DICE`
  - `currentPlayerId == currentUserId`

### 10.4 dialog rules

- `HAND_FINISHED`
  - winner name
  - result type
  - awarded points
- `GAME_FINISHED`
  - winner name
  - final scores
  - coin rewards
  - xp rewards
  - اگر `reason = FORFEIT` بود، `leavingPlayer`
- rewardها باید با `currentUserId` از mapهای `coinRewards/xpRewards` خوانده شوند، نه با کلیدهای نمایشی مثل `winner/participants`

---

## 11. Validation Matrix

| مورد | شرط اعتبار | رفتار UI |
|---|---|---|
| `BACKGAMMON_ROLL_DICE` | `phase = ROLLING_DICE` و نوبت کاربر | دکمه roll فقط همان‌جا فعال |
| `BACKGAMMON_MOVE_CHECKER` | `phase = MOVING_PIECES` و move داخل `legalMoves` | فقط source/destination مجاز selectable |
| move از bar | اگر مهره روی bar باشد | هیچ source دیگری selectable نباشد |
| stale state | `STATE_RESYNC_REQUIRED` | فوری snapshot بگیر و state را replace کن |
| duplicate action | `ACTION_ACK.duplicate = true` | pending action را clear کن، UI را تغییر optimistic نده |
| عدم نوبت کاربر | `currentPlayerId != currentUserId` | همه controls disabled |
| `FINISHED` | match تمام شده | board read-only و dialog نهایی نمایش داده شود |

---

## 12. Acceptance Checklist

- [ ] create room برای Backgammon فقط scoreهای `3/5/7` را نشان می‌دهد.
- [ ] gameplay page روی mount یک `GET_GAME_STATE_BY_ROOM` می‌فرستد.
- [ ] `STATE_SNAPSHOT` raw به state قابل‌استفاده normalize می‌شود.
- [ ] `BACKGAMMON_GAME_STARTED` با `phase = MOVING_PIECES` درست render می‌شود.
- [ ] moveهای legal فقط از `legalMoves` هایلایت می‌شوند.
- [ ] بعد از هر move هیچ optimistic board update انجام نمی‌شود.
- [ ] در stale state، فرانت فوراً resync می‌کند.
- [ ] `GAME_FINISHED` dialog final scores و rewardها را نمایش می‌دهد.
- [ ] `reason = FORFEIT` در UI نهایی قابل مشاهده است.
- [ ] در internal bot room، badge بات و `BOT_DECISION_DEBUG` درست render می‌شوند.

---

## 13. Non-Goals

- local move solver
- doubling cube UI
- bot controls
- spectator mode
- replay/history playback
- admin gameplay controls
