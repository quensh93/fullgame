# مستند اجرایی ۴ برگ برای ایجنت فرانت وب

- نسخه: `1.0`
- تاریخ: `2026-03-11`
- وضعیت: `Frontend Agent Ready`
- دامنه: `Gameplay ۴ برگ روی وب + قرارداد WS لازم برای بازی`

---

## 1. هدف این سند

این سند باید برای ایجنت فرانت کافی باشد تا gameplay وب بازی ۴ برگ را بدون رجوع به Flutter فعلی پیاده کند؛ شامل:

- state model لازم برای UI
- actionهای قابل ارسال به سرور
- eventهای دریافتی از سرور
- validationهای لازم قبل از ارسال
- رفتار UI در هر حالت بازی
- gapهای runtime فعلی که نباید کورکورانه از reference موبایل کپی شوند

این سند فقط gameplay را پوشش می‌دهد. ساخت روم، لیست روم‌ها، wallet، friends و featureهای خارج از میز بازی در این سند نیستند.

---

## 2. Source Of Truth

مرجع قطعی این سند backend runtime فعلی است.

### فایل‌های مرجع

- `gameBackend/src/main/java/com/gameapp/game/services/ChaharBargEngineService.java`
- `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
- `gameBackend/src/main/java/com/gameapp/game/core/common/CardUtils.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameState.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameRoom.java`
- `gameBackend/src/main/java/com/gameapp/game/models/PlayerState.java`
- `gameapp/lib/features/game/ui/game_ui/chahar_barg_game_ui.dart`
- `gameapp/lib/core/websocket/ws_contract_catalog.dart`
- `docs/OPUS_WS_V3_IMPLEMENTATION_GUIDE.md`
- `docs/WS_V3_PAYLOAD_INVENTORY.md`

### اصل مهم

- اگر بین Flutter فعلی و backend اختلاف بود، backend معتبر است.
- اگر بین catalog عمومی WS و runtime ۴ برگ اختلاف بود، runtime معتبر است.

---

## 3. خلاصه قوانین runtime که روی فرانت اثر دارند

این بخش As-Is است؛ دقیقاً مطابق engine فعلی.

- بازی فقط `2` نفره است.
- match چند-handی است، نه تک‌راندی.
- target score بسته به `gameScore` روم:
  - `CHAHAR_BARG_62 -> 62`
  - `CHAHAR_BARG_104 -> 104`
  - `CHAHAR_BARG_152 -> 152`
- در شروع هر hand:
  - به هر بازیکن `4` کارت داده می‌شود.
  - `4` کارت روی میز قرار می‌گیرد.
  - engine تا حد ممکن اجازه نمی‌دهد `J` در ۴ کارت اولیه میز باشد.
- در طول hand:
  - هر زمان hand هر دو بازیکن خالی شود و deck هنوز کارت داشته باشد:
    - دوباره به هر بازیکن `4` کارت داده می‌شود.
    - اگر قبل از deal بعدی حداکثر `8` کارت در deck مانده باشد، `isFinalDeal=true` می‌شود.
- اگر deck دیگر کارت نداشته باشد و hand هر دو بازیکن خالی شود، hand تمام می‌شود.
- هر بازیکن در turn خودش فقط یکی از کارت‌های hand خودش را بازی می‌کند.
- هیچ follow-suit یا trump در این بازی وجود ندارد.

### قواعد capture در runtime فعلی

- اگر کارت بازی‌شده `J` باشد:
  - تمام کارت‌های روی میز به‌جز `Q` و `K` قابل جمع‌کردن هستند.
  - اگر روی میز فقط `Q/K` باشد یا میز خالی باشد، capture وجود ندارد.
  - این حالت همیشه فقط یک option تولید می‌کند.
- اگر کارت بازی‌شده `Q` یا `K` باشد:
  - فقط کارت‌های هم‌رتبه روی میز قابل جمع‌کردن هستند.
  - اگر چند `Q` یا چند `K` روی میز باشد، برای هر کدام یک option جدا تولید می‌شود.
- اگر کارت بازی‌شده `A` یا `2..10` باشد:
  - فقط کارت‌های عددی میز وارد محاسبه می‌شوند.
  - target برابر `11 - playedValue` است.
  - همه combinationهایی که جمع عددی آن‌ها به target برسد، option معتبر هستند.
  - `A` ارزش `1` دارد.
  - `J/Q/K` در محاسبه ترکیب‌های عددی شرکت نمی‌کنند.
- اگر هیچ optionی پیدا نشود:
  - کارت بازی‌شده روی میز گذاشته می‌شود.
- اگر دقیقاً یک option وجود داشته باشد:
  - server همان را auto-resolve می‌کند.
- اگر بیشتر از یک option وجود داشته باشد:
  - بازی وارد `waitingForCaptureSelection=true` می‌شود.
  - فقط همان بازیکن، event `CHAHAR_BARG_CAPTURE_OPTIONS` را دریافت می‌کند.

### سور (`sur`) در runtime فعلی

- اگر capture باعث خالی شدن کامل میز شود و `isFinalDeal=false` باشد و کارت بازی‌شده `J` نباشد: `sur +1`
- اگر کارت بازی‌شده `J` باشد، حتی اگر میز را کامل خالی کند، `sur` حساب نمی‌شود.
- اگر `isFinalDeal=true` باشد، پاک‌کردن کامل میز سور نمی‌دهد.
- هر `sur` در پایان hand برابر `5` امتیاز است.

### پایان hand

- اگر روی میز هنوز کارت مانده باشد و `lastCapturerId` وجود داشته باشد:
  - همه کارت‌های باقی‌مانده میز به آخرین capture کننده داده می‌شود.
- سپس hand points محاسبه می‌شود و به cumulative score هر بازیکن اضافه می‌شود.
- اگر winner تعیین نشود:
  - `CHAHAR_BARG_HAND_FINISHED` broadcast می‌شود.
  - `3` ثانیه بعد hand بعدی شروع می‌شود.

### scoring hand

- بازیکنی که به‌تنهایی majority کارت‌های `♣` را گرفته باشد و حداقل `7` عدد club گرفته باشد:
  - `+7`
- `10♦`:
  - `+3`
- `2♣`:
  - `+2`
- هر `A`:
  - `+1`
- هر `J`:
  - `+1`
- هر `sur`:
  - `+5`

### پایان match

- winner فقط وقتی مشخص می‌شود که:
  - حداقل یکی از بازیکنان به target score برسد یا از آن عبور کند
  - و score دو بازیکن مساوی نباشد
- اگر هر دو بازیکن به target برسند ولی مساوی باشند:
  - match تمام نمی‌شود
  - hand بعدی شروع می‌شود

### timeout

- timeout هر turn برابر `25` ثانیه است.
- اگر timeout در حالت pending capture رخ دهد:
  - server خودش `optionIndex=0` را auto-select می‌کند.
- اگر timeout در حالت عادی رخ دهد:
  - server خودش اولین کارت hand بازیکن فعلی را auto-play می‌کند.
- برای ۴ برگ action جداگانه‌ای مثل `CHAHAR_BARG_TURN_TIMEOUT` وجود ندارد.

### payout

- winner XP: `50`
- loser XP: `10`
- coin reward در roomهای non-bot:
  - `90%` pot برای winner
  - `10%` platform fee

---

## 4. Boot Flow صفحه وب

پیش‌نیازهای mount:

- کاربر authenticate شده باشد.
- WebSocket روی `/ws-v3` وصل و `AUTH` شده باشد.
- `roomId` مشخص باشد.
- user profile فعلی برای به‌دست‌آوردن `playerId` در دسترس باشد.

### Boot Flow

در mount صفحه:

1. listenerهای `GAME_ACTION` و `GAME_STATE` را register کن.
2. `GET_GAME_STATE_BY_ROOM` را با `roomId` بفرست.
3. `STATE_SNAPSHOT` را normalize کن و به state مشترک ۴ برگ تبدیل کن.
4. بعد از آن full-state eventهای زیر را روی همان reducer مشترک apply کن:
   - `CHAHAR_BARG_GAME_STARTED`
   - `CHAHAR_BARG_STATE_UPDATED`
5. eventهای زیر فقط overlay یا modal هستند و نباید منبع اصلی state باشند:
   - `CHAHAR_BARG_CAPTURE_OPTIONS`
   - `CHAHAR_BARG_HAND_FINISHED`
   - `CHAHAR_BARG_GAME_FINISHED`

### نکته مهم

- روی `GAME_STARTED` عمومی تکیه نکن.
- روی `TURN_TIMER_STARTED` تکیه نکن؛ برای ۴ برگ وجود ندارد.
- `STATE_SNAPSHOT` برای ۴ برگ raw `GameState` برمی‌گرداند و shape آن با `CHAHAR_BARG_*` full-state eventها یکی نیست.

---

## 5. مدل داده‌ای پیشنهادی برای فرانت

```ts
export type ChaharBargCard = string; // examples: "A♣", "10♦", "7h"

export interface ChaharBargPlayer {
  playerId: number;
  username: string;
  seatNumber: number;
  cardsCount: number;
  capturedCount: number;
  surCount: number;
  score: number;
  isCurrentTurn: boolean;
  status?: string;
}

export interface ChaharBargCaptureOption {
  index: number;
  cards: ChaharBargCard[];
}

export interface ChaharBargGameState {
  roomId: number;
  gameStateId: number;
  handNumber: number;
  currentRoundLabel: number;
  currentPlayerId: number | null;
  currentPlayerIndex: number;
  targetScore: number;
  turnTimeoutSeconds: number;
  tableCards: ChaharBargCard[];
  myHandCards: ChaharBargCard[];
  players: ChaharBargPlayer[];
  cumulativePointsByPlayer: Record<string, number>;
  surByPlayer: Record<string, number>;
  capturedCardsCount: Record<string, number>;
  waitingForCaptureSelection: boolean;
  pendingCapturePlayerId: number | null;
  isFinalDeal: boolean;
  stateVersion: number;
}

export interface ChaharBargHandFinishedPayload {
  roomId: number;
  gameStateId: number;
  handNumber: number;
  targetScore: number;
  handPoints: Record<string, number>;
  handPointsByPlayer: Record<string, number>;
  cumulativePoints: Record<string, number>;
  cumulativePointsByUsername: Record<string, number>;
  surByPlayer: Record<string, number>;
  capturedCardsCount: Record<string, number>;
}

export interface ChaharBargGameFinishedPayload {
  roomId: number;
  gameId: number;
  winnerId: number | null;
  winnerUsername: string | null;
  finalScores: Record<string, number>;
  xpRewards: {
    winner?: number;
    participants?: number;
  };
  coinRewards: {
    winner?: number;
    totalPot?: number;
    platformFee?: number;
  };
  reason?: "FORFEIT";
  leavingPlayer?: string;
}

export interface ChaharBargUiState {
  game: ChaharBargGameState | null;
  selectedCard?: ChaharBargCard;
  captureOptions?: {
    gameStateId: number;
    playerId: number;
    playedCard: ChaharBargCard;
    options: ChaharBargCaptureOption[];
  };
  pendingAction?: {
    clientActionId: string;
    action: "CHAHAR_BARG_PLAY_CARD" | "CHAHAR_BARG_SELECT_CAPTURE";
  };
  turnTimerSeconds: number;
  handFinishedSummary?: ChaharBargHandFinishedPayload;
  finishModal?: ChaharBargGameFinishedPayload;
}
```

### قواعد مربوط به کارت

- backend ورودی‌های compact مثل `Ah`, `10d`, `7c` را normalize می‌کند.
- runtime eventها معمولاً کارت را به شکل symbol-based مثل `A♥`, `10♦`, `7♣` می‌فرستند.
- فرانت بهتر است همان string دریافتی از state را بدون تغییر برای actionها reuse کند.
- اگر UI مجبور به ساخت string کارت باشد، باید با normalization backend سازگار باشد.

---

## 6. نرمال‌سازی `STATE_SNAPSHOT`

برای ۴ برگ، `STATE_SNAPSHOT` raw `GameState` برمی‌گرداند و shape آن با `CHAHAR_BARG_GAME_STARTED` و `CHAHAR_BARG_STATE_UPDATED` فرق دارد.

### shape تقریبی snapshot

```ts
{
  id: number;
  currentRound?: number;
  currentPlayerId?: number;
  gameSpecificData?: {
    targetScore?: number;
    handNumber?: number;
    playerOrderIds?: number[];
    currentPlayerIndex?: number;
    cumulativePointsByPlayer?: Record<string, number>;
    handsByPlayer?: Record<string, string[]>;
    deckCards?: string[];
    tableCards?: string[];
    capturedCardsByPlayer?: Record<string, string[]>;
    surByPlayer?: Record<string, number>;
    isFinalDeal?: boolean;
    lastCapturerId?: number | null;
    pendingCaptureOptions?: {
      playerId: number;
      playedCard: string;
      options: string[][];
    } | null;
    stateVersion?: number;
  };
  gameRoom?: {
    id?: number;
    gameScore?: string;
    roomStatus?: string;
    players?: Array<{
      seatNumber?: number;
      score?: number;
      cardsInHand?: number;
      handCards?: string[];
      status?: string;
      user?: {
        id?: number;
        username?: string;
        email?: string;
      };
    }>;
  };
}
```

### تبدیل snapshot به state مشترک

- `roomId = envelope.roomId ?? data.gameRoom.id`
- `gameStateId = Number(data.id)`
- `handNumber = gameSpecificData.handNumber ?? data.currentRound ?? 1`
- `currentRoundLabel = handNumber`
- `currentPlayerId = data.currentPlayerId ?? null`
- `currentPlayerIndex = gameSpecificData.currentPlayerIndex ?? indexOf(currentPlayerId in playerOrderIds) ?? 0`
- `targetScore = gameSpecificData.targetScore ?? resolveFromRoomGameScore(gameRoom.gameScore) ?? 62`
- `turnTimeoutSeconds = 25`
- `tableCards = gameSpecificData.tableCards ?? []`
- `cumulativePointsByPlayer = gameSpecificData.cumulativePointsByPlayer ?? {}`
- `surByPlayer = gameSpecificData.surByPlayer ?? {}`
- `capturedCardsCount = count lengths of gameSpecificData.capturedCardsByPlayer`
- `waitingForCaptureSelection = !!gameSpecificData.pendingCaptureOptions`
- `pendingCapturePlayerId = gameSpecificData.pendingCaptureOptions?.playerId ?? null`
- `isFinalDeal = !!gameSpecificData.isFinalDeal`
- `stateVersion = envelope.stateVersion ?? gameSpecificData.stateVersion ?? 0`

### ساخت `myHandCards`

- `myHandCards = gameSpecificData.handsByPlayer[String(myPlayerId)] ?? ownPlayer.handCards ?? []`

### ساخت `players`

از `gameRoom.players` استفاده کن و آن‌ها را بر اساس `seatNumber` sort کن:

- `playerId = player.user.id`
- `username = player.user.username ?? player.user.email ?? "نامشخص"`
- `seatNumber = player.seatNumber ?? 0`
- `cardsCount = length(gameSpecificData.handsByPlayer[playerId]) ?? player.cardsInHand ?? 0`
- `capturedCount = length(gameSpecificData.capturedCardsByPlayer[playerId])`
- `surCount = gameSpecificData.surByPlayer[playerId] ?? 0`
- `score = gameSpecificData.cumulativePointsByPlayer[playerId] ?? player.score ?? 0`
- `isCurrentTurn = playerId === currentPlayerId`
- `status = player.status`

### recovery مهم برای reconnect

اگر snapshot در لحظه pending capture گرفته شود:

- `pendingCaptureOptions` داخل `gameSpecificData` شامل خود optionها هم هست.
- فرانت باید بتواند از snapshot دوباره `captureOptions` modal را بازسازی کند.
- این برای حالتی لازم است که کاربر event `CHAHAR_BARG_CAPTURE_OPTIONS` را از دست داده ولی هنوز pending selection پابرجاست.

### rule امنیتی

- raw snapshot ممکن است `handCards` بازیکن‌های دیگر را هم حمل کند.
- فرانت وب باید فقط `myHandCards` را render کند و hand بازیکن مقابل را همیشه mask کند.

---

## 7. چیدمان و رفتار بصری

### layout پایه

- پایین صفحه: بازیکن فعلی
- بالای صفحه: حریف
- وسط صفحه: `tableCards`
- header:
  - `handNumber`
  - `targetScore`
  - timer
  - cumulative score هر بازیکن
  - sur هر بازیکن

### چیزهایی که همیشه باید نمایش داده شوند

- نام دو بازیکن
- نوبت فعلی
- تعداد کارت‌های hand هر بازیکن
- امتیاز cumulative هر بازیکن
- تعداد `sur` هر بازیکن
- `targetScore`
- `handNumber`
- countdown محلی بر اساس `turnTimeoutSeconds`

### نمایش handها

- `myHandCards` باید face-up باشد.
- hand حریف همیشه hidden باشد.
- تعداد card backهای حریف باید بر اساس `cardsCount` باشد.
- حتی اگر snapshot یا room data کارت‌های حریف را بدهد، render آن‌ها ممنوع است.

### UI برای pending capture

- اگر `waitingForCaptureSelection=true` و `pendingCapturePlayerId === myPlayerId`:
  - hand باید disabled شود.
  - modal یا bottom sheet انتخاب capture باز شود.
  - هر option باید `index` و `cards[]` را نشان دهد.
  - `playedCard` هم باید در UI مشخص باشد.
- اگر `waitingForCaptureSelection=true` ولی `pendingCapturePlayerId !== myPlayerId`:
  - فقط پیام waiting نشان داده شود.
  - هیچ control فعالی برای کاربر فعلی وجود نداشته باشد.

### final deal

- اگر `isFinalDeal=true`:
  - بهتر است badge یا label کوچک نمایش داده شود.
  - فرانت نباید خودش از این flag rule جدید بسازد؛ فقط indicator نمایشی است.

### پایان hand

- بعد از `CHAHAR_BARG_HAND_FINISHED`:
  - summary امتیاز hand و cumulative نمایش داده شود.
  - inputهای play/capture موقتاً disable شوند.
  - انتظار برای state جدید حدود `3` ثانیه‌ای طبیعی است.

---

## 8. State Authority

### authoritative sources

- `STATE_SNAPSHOT`
- `CHAHAR_BARG_GAME_STARTED`
- `CHAHAR_BARG_STATE_UPDATED`

این سه منبع باید کل room gameplay state را replace کنند، نه merge ناقص و patchy.

### non-authoritative overlays

- `CHAHAR_BARG_CAPTURE_OPTIONS`
  - فقط برای actor modal data می‌آورد.
  - authority اصلی waiting state همچنان full-state events هستند.
- `CHAHAR_BARG_HAND_FINISHED`
  - فقط برای summary و interstitial است.
  - منبع اصلی state hand بعدی نیست.
- `CHAHAR_BARG_GAME_FINISHED`
  - پایان match را authoritative می‌کند ولی board state را تکمیل نمی‌کند.

### optimistic UI policy

- حذف کارت از hand قبل از دریافت state جدید ممنوع است.
- حذف کارت‌های میز قبل از resolve server ممنوع است.
- تنها optimistic change مجاز:
  - disable کردن interaction
  - spinner/pending marker

---

## 9. Action Catalog

همه actionها باید با envelope استاندارد `GAME_ACTION` ارسال شوند:

```json
{
  "type": "GAME_ACTION",
  "action": "CHAHAR_BARG_PLAY_CARD",
  "roomId": 4101,
  "clientActionId": "ca_1762000000001",
  "data": {
    "gameStateId": 981,
    "playerId": 120,
    "card": "A♣",
    "stateVersion": 14
  }
}
```

### قوانین عمومی همه actionها

- `type=GAME_ACTION`
- `action` اجباری
- `roomId` top-level اجباری
- `clientActionId` اجباری
- `data.stateVersion` اجباری
- برای ۴ برگ، بر خلاف CE:
  - `data.roomId` لازم نیست
- `playerId` باید شناسه user لاگین‌شده فعلی باشد
- `stateVersion` باید جدیدترین نسخه state باشد
- gameplay optimistic ممنوع است

### 9.1 `CHAHAR_BARG_PLAY_CARD`

#### ورودی

```ts
{
  gameStateId: number;
  playerId: number;
  card: ChaharBargCard;
  stateVersion: number;
}
```

#### ولیدیشن قبل از ارسال

- state باید موجود باشد.
- match نباید finished شده باشد.
- user فعلی باید همان `currentPlayerId` باشد.
- `waitingForCaptureSelection` باید `false` باشد.
- `card` باید در `myHandCards` وجود داشته باشد.
- اگر UI از string compact استفاده می‌کند:
  - قبل از compare با hand باید normalize سازگار انجام دهد.
- در صورت وجود pending action حل‌نشده از همین room:
  - dispatch دوباره انجام نشود.

#### خروجی مورد انتظار

- فوری:
  - `ACTION_ACK`
- async:
  - اگر capture optionی وجود نداشته باشد:
    - `CHAHAR_BARG_STATE_UPDATED`
  - اگر دقیقاً یک capture option وجود داشته باشد:
    - `CHAHAR_BARG_STATE_UPDATED`
  - اگر چند capture option وجود داشته باشد:
    - `CHAHAR_BARG_STATE_UPDATED`
    - `CHAHAR_BARG_CAPTURE_OPTIONS`
  - در ادامه ممکن است:
    - `CHAHAR_BARG_HAND_FINISHED`
    - `CHAHAR_BARG_GAME_FINISHED`

#### نکته مهم

- فرانت نباید خودش capture outcome را پیش‌بینی و render کند.
- فقط card selected را pending نشان بدهد و منتظر state جدید بماند.

### 9.2 `CHAHAR_BARG_SELECT_CAPTURE`

#### ورودی

```ts
{
  gameStateId: number;
  playerId: number;
  optionIndex: number;
  stateVersion: number;
}
```

#### ولیدیشن قبل از ارسال

- state باید موجود باشد.
- match نباید finished شده باشد.
- `waitingForCaptureSelection` باید `true` باشد.
- `pendingCapturePlayerId` باید برابر user فعلی باشد.
- `currentPlayerId` باید همان user فعلی باشد.
- `captureOptions` باید locally موجود باشد.
- `optionIndex` باید داخل range optionهای موجود باشد.
- در صورت وجود pending action حل‌نشده:
  - dispatch دوباره انجام نشود.

#### خروجی مورد انتظار

- فوری:
  - `ACTION_ACK`
- async:
  - `CHAHAR_BARG_STATE_UPDATED`
  - و در ادامه بسته به پایان hand:
    - `CHAHAR_BARG_HAND_FINISHED`
    - یا `CHAHAR_BARG_GAME_FINISHED`

---

## 10. Event Catalog

## 10.1 `CHAHAR_BARG_GAME_STARTED`

full-state event شروع match/hand اول است.

### payload observed

```ts
{
  roomId: number;
  gameStateId: number;
  handNumber: number;
  targetScore: number;
  currentPlayerId: number;
  currentPlayerIndex: number;
  tableCards: string[];
  myHandCards: string[];
  players: Array<{
    playerId: number;
    username: string;
    seatNumber: number;
    cardsCount: number;
    capturedCount: number;
    surCount: number;
    score: number;
    isCurrentTurn: boolean;
  }>;
  cumulativePointsByPlayer: Record<string, number>;
  surByPlayer: Record<string, number>;
  capturedCardsCount: Record<string, number>;
  waitingForCaptureSelection: boolean;
  pendingCapturePlayerId: number | null;
  isFinalDeal: boolean;
  turnTimeoutSeconds: number;
}
```

### رفتار فرانت

- کل room state را replace کند.
- timer را reset کند.
- اگر از state جدید معلوم است pending capture برای خود کاربر فعال است و optionها از snapshot/recovery موجودند:
  - modal را باز کند.

## 10.2 `CHAHAR_BARG_STATE_UPDATED`

همان shape `CHAHAR_BARG_GAME_STARTED` را دارد و full-state authoritative اصلی بازی است.

### رفتار فرانت

- کل room state را replace کند.
- `selectedCard` را اگر دیگر در `myHandCards` نیست پاک کند.
- timer را reset کند.
- اگر `waitingForCaptureSelection=false` شد:
  - `captureOptions` local را پاک کند.

### نکته مهم

- برخلاف snapshot، این payload `currentRound` ندارد.
- برای label راند در UI از `handNumber` استفاده کن.

## 10.3 `CHAHAR_BARG_CAPTURE_OPTIONS`

این event فقط برای همان بازیکنی ارسال می‌شود که باید capture option را انتخاب کند.

### payload observed

```ts
{
  roomId: number;
  gameStateId: number;
  playerId: number;
  playedCard: string;
  options: Array<{
    index: number;
    cards: string[];
  }>;
}
```

### رفتار فرانت

- فقط اگر `playerId === myPlayerId` باشد آن را consume کند.
- `captureOptions` local را set کند.
- modal را باز کند.
- برای playerهای دیگر این event بی‌اثر است.

### authority rule

- این event به‌تنهایی state اصلی اتاق نیست.
- فقط data لازم برای انتخاب option را می‌دهد.

## 10.4 `CHAHAR_BARG_HAND_FINISHED`

summary پایان hand است.

### payload observed

```ts
{
  roomId: number;
  gameStateId: number;
  handNumber: number;
  targetScore: number;
  handPoints: Record<string, number>;
  handPointsByPlayer: Record<string, number>;
  cumulativePoints: Record<string, number>;
  cumulativePointsByUsername: Record<string, number>;
  surByPlayer: Record<string, number>;
  capturedCardsCount: Record<string, number>;
}
```

### رفتار فرانت

- summary یا snackbar یا modal کوتاه نمایش دهد.
- از این event به‌تنهایی board state جدید نسازد.
- منتظر `CHAHAR_BARG_STATE_UPDATED` بعدی یا `CHAHAR_BARG_GAME_FINISHED` بماند.

## 10.5 `CHAHAR_BARG_GAME_FINISHED`

پایان match.

### payload observed

```ts
{
  roomId: number;
  gameId: number;
  winnerId: number | null;
  winnerUsername: string | null;
  finalScores: Record<string, number>;
  xpRewards: {
    winner?: number;
    participants?: number;
  };
  coinRewards: {
    winner?: number;
    totalPot?: number;
    platformFee?: number;
  };
  reason?: "FORFEIT";
  leavingPlayer?: string;
}
```

### رفتار فرانت

- match را finished mark کند.
- timer را stop کند.
- finish modal را نشان دهد.
- XP کاربر:
  - اگر winner است: `xpRewards.winner`
  - در غیر این صورت: `xpRewards.participants`
- coin کاربر:
  - فقط winner مقدار غیرصفر دارد.

### adapter اجباری

- این event از `gameId` استفاده می‌کند، نه `gameStateId`.
- فرانت باید:

```ts
finishedGameStateId = Number(payload.gameId)
```

## 10.6 `ACTION_ACK`

برای correlation actionهای ارسالی استفاده شود.

### رفتار فرانت

- pending action را تا رسیدن state جدید نگه دارد یا با `ACTION_ACK` accepted mark کند.
- اگر `duplicate=true` یا `accepted=false` بود، pending UI را پاک کند.

## 10.7 `ERROR`

generic errorهای gameplay ممکن است به شکل `ERROR` یا `sendError(session, ...)` برگردند.

### خطاهای runtime محتمل

- `Missing CHAHAR_BARG_PLAY_CARD data`
- `Missing CHAHAR_BARG_SELECT_CAPTURE data`
- `Error: Game state not found`
- `Error: Game is not in progress`
- `Error: Capture selection is pending`
- `Error: It is not your turn`
- `Error: Card is not in player's hand`
- `Error: No capture options are pending`
- `Error: Pending capture belongs to another player`
- `Error: Invalid capture option index`

### رفتار فرانت

- error را فقط برای همان user session نمایش دهد.
- pending action را clear کند.
- اگر errorCode=`STATE_RESYNC_REQUIRED` بود:
  - فوراً `GET_GAME_STATE_BY_ROOM` بفرست
  - state محلی را با snapshot replace کن

---

## 11. Timer Policy

- duration authoritative از runtime برابر `25` ثانیه است.
- full-state eventها فیلد `turnTimeoutSeconds` را می‌دهند.
- برای ۴ برگ:
  - `TURN_TIMER_STARTED` وجود ندارد
  - `CHAHAR_BARG_TURN_TIMEOUT` هم وجود ندارد

### سیاست فرانت

- روی هر `CHAHAR_BARG_GAME_STARTED`
- روی هر `CHAHAR_BARG_STATE_UPDATED`
- و روی bootstrap از `STATE_SNAPSHOT`

timer محلی را به `turnTimeoutSeconds ?? 25` reset کن.

### وقتی تایمر محلی صفر شد

- interaction را غیرفعال کن.
- هیچ action timeout از سمت client نفرست.
- منتظر update سرور بمان.

### pending capture

- timer برای pending capture هم همان timer turn است.
- `CHAHAR_BARG_CAPTURE_OPTIONS` به‌تنهایی timer جدید authoritative شروع نمی‌کند.
- reset timer باید از full-state update انجام شود.

---

## 12. Derived UI Modes

### `bootstrapping`

- شرط:
  - `game == null`
- UI:
  - loading
  - بدون interaction

### `myTurnPlay`

- شرط:
  - `game != null`
  - `currentPlayerId === myPlayerId`
  - `waitingForCaptureSelection === false`
  - match finished نشده
- UI:
  - hand فعال
  - card select/play فعال

### `myTurnCaptureChoice`

- شرط:
  - `game != null`
  - `currentPlayerId === myPlayerId`
  - `waitingForCaptureSelection === true`
  - `pendingCapturePlayerId === myPlayerId`
- UI:
  - hand غیرفعال
  - modal انتخاب option فعال

### `opponentTurn`

- شرط:
  - `game != null`
  - `currentPlayerId !== myPlayerId`
  - match finished نشده
- UI:
  - همه controlهای gameplay غیرفعال
  - فقط waiting indicator

### `betweenHands`

- شرط:
  - `CHAHAR_BARG_HAND_FINISHED` دریافت شده
  - ولی هنوز full-state hand بعدی یا game finished نرسیده
- UI:
  - hand summary
  - board interaction غیرفعال

### `gameFinished`

- شرط:
  - `CHAHAR_BARG_GAME_FINISHED` دریافت شده
- UI:
  - finish modal
  - board interaction غیرفعال

---

## 13. ولیدیشن‌های UI به تفکیک حالت

### در `bootstrapping`

- هیچ action gameplay ارسال نشود.

### در `myTurnPlay`

- فقط cardهایی که در `myHandCards` هستند clickable باشند.
- دوبار tap روی همان card یا دکمه confirm می‌تواند play را dispatch کند.
- بعد از dispatch:
  - hand موقتاً disable شود
  - ولی optimistic remove انجام نشود

### در `myTurnCaptureChoice`

- hand باید disable باشد.
- فقط optionهای capture قابل کلیک باشند.
- close کردن modal بدون انتخاب نباید allowed باشد، مگر UX جداگانه برای wait داشته باشی.

### در `opponentTurn`

- هیچ play یا selectCapture ارسال نشود.

### در `betweenHands`

- هیچ play یا selectCapture ارسال نشود.

### برای ترک بازی

- قبل از `LEAVE_ROOM` confirmation dialog لازم است.
- UX باید صریح بگوید خروج از بازی معادل باخت است.

---

## 14. محاسباتی که فرانت نباید خودش authoritative انجام دهد

- capture option generation
- resolve capture outcome
- تشخیص `sur`
- محاسبه امتیاز hand
- تعیین winner match
- auto-play timeout
- auto-select timeout option
- starter hand بعدی

فرانت می‌تواند این‌ها را برای preview غیرauthoritative محاسبه کند، اما نباید روی آن‌ها action gating یا state mutation اصلی بسازد.

---

## 15. Gap Register

### GAP-01: `STATE_SNAPSHOT` shape متفاوتی با `CHAHAR_BARG_*` state eventها دارد

- snapshot raw `GameState` است.
- full-state eventها already-adapted gameplay payload هستند.
- فرانت وب باید normalizer جدا برای snapshot داشته باشد.

### GAP-02: `myHandCards` در runtime وجود دارد ولی catalog آن را صریح نشان نمی‌دهد

- engine در `broadcastState` برای هر user یک payload شخصی می‌فرستد.
- این payload شامل `myHandCards` است.
- فرانت نباید انتظار داشته باشد hand داخل `players[]` باشد.

### GAP-03: `currentRound` در state eventها وجود ندارد

- `CHAHAR_BARG_GAME_STARTED` و `CHAHAR_BARG_STATE_UPDATED` فقط `handNumber` می‌دهند.
- اگر UI label راند می‌خواهد، از `handNumber` استفاده کند.

### GAP-04: `CHAHAR_BARG_GAME_FINISHED` از `gameId` استفاده می‌کند، نه `gameStateId`

- این در پایان match با eventهای دیگر فرق دارد.
- adapter اجباری است.

### GAP-05: برای ۴ برگ `TURN_TIMER_STARTED` و timeout action وجود ندارد

- برخلاف بعضی بازی‌ها، client fallback action ندارد.
- countdown وب فقط display state است.

### GAP-06: reconnect وسط pending capture فقط با snapshot recover می‌شود

- full-state update فقط `waitingForCaptureSelection=true` را می‌دهد.
- خود optionها در event جدا و user-scoped هستند.
- اگر آن event از دست برود، باید از `STATE_SNAPSHOT.gameSpecificData.pendingCaptureOptions` recovery کرد.

### GAP-07: raw snapshot ممکن است hand همه بازیکنان را حمل کند

- این یک fairness risk است.
- فرانت وب فقط hand خودی را render کند.

### GAP-08: handler runtime روی `playerId` تکیه می‌کند

- actionها فقط با `gameStateId` کافی نیستند.
- `playerId` باید صریح و صحیح ارسال شود.

---

## 16. ترتیب پیاده‌سازی پیشنهادی

1. state model مشترک ۴ برگ را بساز.
2. snapshot normalizer را پیاده کن.
3. reducer مشترک برای `CHAHAR_BARG_GAME_STARTED` و `CHAHAR_BARG_STATE_UPDATED` بنویس.
4. masking قطعی hand حریف را enforce کن.
5. countdown محلی مبتنی بر full-state eventها را بساز.
6. action sender با `clientActionId` و `stateVersion` را وصل کن.
7. play-card validation و pending UI را اضافه کن.
8. capture-options modal و snapshot recovery آن را بساز.
9. hand-finished summary و interstitial سه‌ثانیه‌ای را نهایی کن.
10. finish modal و error/resync handling را کامل کن.

---

## 17. Definition Of Done

- bootstrap صفحه با `GET_GAME_STATE_BY_ROOM` کار می‌کند.
- `STATE_SNAPSHOT` به state مشترک ۴ برگ درست normalize می‌شود.
- `CHAHAR_BARG_GAME_STARTED` و `CHAHAR_BARG_STATE_UPDATED` کل state را درست replace می‌کنند.
- hand حریف هرگز render نمی‌شود.
- `CHAHAR_BARG_PLAY_CARD` فقط در turn مجاز و با card معتبر ارسال می‌شود.
- `CHAHAR_BARG_SELECT_CAPTURE` فقط برای actor و با option معتبر ارسال می‌شود.
- reconnect وسط pending capture optionها را از snapshot recover می‌کند.
- timer روی هر full-state update reset می‌شود.
- وقتی timer محلی صفر می‌شود، client هیچ timeout actionی نمی‌فرستد.
- `CHAHAR_BARG_HAND_FINISHED` summary درست نشان داده می‌شود.
- `CHAHAR_BARG_GAME_FINISHED` winner/coins/xp را درست نشان می‌دهد.

---

## 18. نمونه payloadهای آماده

### 18.1 درخواست snapshot

```json
{
  "type": "GET_GAME_STATE_BY_ROOM",
  "roomId": 4101
}
```

### 18.2 خروجی snapshot خام

```json
{
  "type": "STATE_SNAPSHOT",
  "roomId": 4101,
  "success": true,
  "stateVersion": 14,
  "data": {
    "id": 981,
    "currentRound": 2,
    "currentPlayerId": 120,
    "gameSpecificData": {
      "targetScore": 62,
      "handNumber": 2,
      "playerOrderIds": [120, 121],
      "currentPlayerIndex": 0,
      "cumulativePointsByPlayer": { "120": 18, "121": 11 },
      "handsByPlayer": {
        "120": ["A♣", "7♦", "Q♠", "2♣"],
        "121": ["5♥", "6♠", "K♦", "J♣"]
      },
      "tableCards": ["4♣", "3♦", "8♥"],
      "capturedCardsByPlayer": {
        "120": ["10♦", "A♥"],
        "121": ["J♠"]
      },
      "surByPlayer": { "120": 1, "121": 0 },
      "isFinalDeal": false,
      "pendingCaptureOptions": null,
      "stateVersion": 14
    },
    "gameRoom": {
      "id": 4101,
      "gameScore": "CHAHAR_BARG_62",
      "roomStatus": "IN_PROGRESS",
      "players": [
        {
          "seatNumber": 0,
          "score": 18,
          "cardsInHand": 4,
          "user": { "id": 120, "username": "ali" }
        },
        {
          "seatNumber": 1,
          "score": 11,
          "cardsInHand": 4,
          "user": { "id": 121, "username": "reza" }
        }
      ]
    }
  }
}
```

### 18.3 `CHAHAR_BARG_PLAY_CARD`

```json
{
  "type": "GAME_ACTION",
  "action": "CHAHAR_BARG_PLAY_CARD",
  "roomId": 4101,
  "clientActionId": "ca_play_001",
  "data": {
    "gameStateId": 981,
    "playerId": 120,
    "card": "A♣",
    "stateVersion": 14
  }
}
```

### 18.4 `CHAHAR_BARG_SELECT_CAPTURE`

```json
{
  "type": "GAME_ACTION",
  "action": "CHAHAR_BARG_SELECT_CAPTURE",
  "roomId": 4101,
  "clientActionId": "ca_capture_001",
  "data": {
    "gameStateId": 981,
    "playerId": 120,
    "optionIndex": 1,
    "stateVersion": 15
  }
}
```

### 18.5 `CHAHAR_BARG_STATE_UPDATED`

```json
{
  "type": "GAME_ACTION",
  "action": "CHAHAR_BARG_STATE_UPDATED",
  "roomId": 4101,
  "stateVersion": 15,
  "data": {
    "roomId": 4101,
    "gameStateId": 981,
    "handNumber": 2,
    "targetScore": 62,
    "currentPlayerId": 120,
    "currentPlayerIndex": 0,
    "tableCards": ["4♣", "3♦", "8♥"],
    "myHandCards": ["A♣", "7♦", "Q♠", "2♣"],
    "waitingForCaptureSelection": false,
    "pendingCapturePlayerId": null,
    "cumulativePointsByPlayer": { "120": 18, "121": 11 },
    "surByPlayer": { "120": 1, "121": 0 },
    "capturedCardsCount": { "120": 2, "121": 1 },
    "isFinalDeal": false,
    "turnTimeoutSeconds": 25,
    "players": [
      {
        "playerId": 120,
        "username": "ali",
        "seatNumber": 0,
        "cardsCount": 4,
        "capturedCount": 2,
        "surCount": 1,
        "score": 18,
        "isCurrentTurn": true
      },
      {
        "playerId": 121,
        "username": "reza",
        "seatNumber": 1,
        "cardsCount": 4,
        "capturedCount": 1,
        "surCount": 0,
        "score": 11,
        "isCurrentTurn": false
      }
    ]
  }
}
```

### 18.6 `CHAHAR_BARG_CAPTURE_OPTIONS`

```json
{
  "type": "GAME_ACTION",
  "action": "CHAHAR_BARG_CAPTURE_OPTIONS",
  "roomId": 4101,
  "stateVersion": 16,
  "data": {
    "roomId": 4101,
    "gameStateId": 981,
    "playerId": 120,
    "playedCard": "8♦",
    "options": [
      { "index": 0, "cards": ["3♦"] },
      { "index": 1, "cards": ["A♣", "2♠"] }
    ]
  }
}
```

### 18.7 `CHAHAR_BARG_HAND_FINISHED`

```json
{
  "type": "GAME_ACTION",
  "action": "CHAHAR_BARG_HAND_FINISHED",
  "roomId": 4101,
  "stateVersion": 21,
  "data": {
    "roomId": 4101,
    "gameStateId": 981,
    "handNumber": 2,
    "targetScore": 62,
    "handPoints": {
      "ali": 17,
      "reza": 8
    },
    "handPointsByPlayer": {
      "120": 17,
      "121": 8
    },
    "cumulativePoints": {
      "120": 35,
      "121": 19
    },
    "cumulativePointsByUsername": {
      "ali": 35,
      "reza": 19
    },
    "surByPlayer": {
      "120": 2,
      "121": 0
    },
    "capturedCardsCount": {
      "120": 12,
      "121": 8
    }
  }
}
```

### 18.8 `CHAHAR_BARG_GAME_FINISHED`

```json
{
  "type": "GAME_ACTION",
  "action": "CHAHAR_BARG_GAME_FINISHED",
  "roomId": 4101,
  "stateVersion": 28,
  "data": {
    "roomId": 4101,
    "gameId": 981,
    "winnerId": 120,
    "winnerUsername": "ali",
    "finalScores": {
      "ali": 66,
      "reza": 51
    },
    "xpRewards": {
      "winner": 50,
      "participants": 10
    },
    "coinRewards": {
      "winner": 1800,
      "totalPot": 2000,
      "platformFee": 200
    }
  }
}
```
