# مستند اجرایی رامی برای ایجنت فرانت وب

- نسخه: `1.0`
- تاریخ: `2026-03-12`
- وضعیت: `Frontend Agent Ready`
- دامنه: `Gameplay رامی روی وب + قرارداد WS لازم برای بازی`

---

## 1. هدف این سند

این سند باید برای ایجنت فرانت کافی باشد تا gameplay وب بازی رامی را بدون رجوع به Flutter فعلی پیاده کند؛ شامل:

- state model لازم برای UI
- actionهای قابل ارسال به سرور
- eventهای دریافتی از سرور
- validationهای لازم قبل از ارسال
- رفتار UI در هر فاز
- boot/reconnect/resync flow
- gapهای runtime فعلی که نباید کورکورانه از reference موبایل کپی شوند

این سند فقط gameplay میز بازی را پوشش می‌دهد. ساخت روم، join، invitation، history، wallet، friends و featureهای خارج از میز در این سند فقط به‌عنوان dependency summary می‌آیند.

---

## 2. Source Of Truth

مرجع قطعی این سند runtime فعلی backend است.

### فایل‌های مرجع

- `gameBackend/src/main/java/com/gameapp/game/services/RimEngineService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/RimBotStrategy.java`
- `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WsEnvelopeService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/WebSocketRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameEngineService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/core/common/CardUtils.java`
- `gameBackend/src/main/java/com/gameapp/game/core/common/DeckService.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameState.java`
- `gameBackend/src/main/java/com/gameapp/game/models/GameRoom.java`
- `gameBackend/src/main/java/com/gameapp/game/models/PlayerState.java`
- `gameapp/lib/features/game/data/models/rim_game_state.dart`
- `gameapp/lib/features/game/ui/game_ui/rim_game_ui.dart`
- `gameapp/lib/core/websocket/ws_contract_catalog.dart`
- `docs/RUMMY_RULES_SPEC.md`
- `docs/OPUS_WS_V3_IMPLEMENTATION_GUIDE.md`
- `docs/WS_V3_PAYLOAD_INVENTORY.md`
- `docs/opus_ws_v3_contract.json`

### اصل مهم

- اگر بین Flutter فعلی و backend اختلاف بود، backend معتبر است.
- اگر بین catalog عمومی WS و runtime رامی اختلاف بود، runtime رامی معتبر است.
- اگر بین `STATE_SNAPSHOT` خام و full-state eventهای `RIM_*` اختلاف شکل بود، reducer وب باید full-state eventها را مرجع نهایی state بداند.

---

## 3. Dependency Summary

این موارد برای mount صفحه لازم‌اند ولی این سند آن‌ها را fully specify نمی‌کند:

- کاربر authenticate شده باشد.
- WebSocket روی `/ws-v3` وصل و `AUTH` شده باشد.
- `roomId` و اطلاعات پایه روم در دسترس باشد.
- room gameplay وقتی mount می‌شود که روم قبلا `IN_PROGRESS` شده باشد یا بلافاصله شروع شود.

برای این فاز روی این featureها تکیه نکن:

- create room flow
- join/cancel/invitation UI
- game history UI
- social/chat/wallet behavior

---

## 4. خلاصه قوانین runtime که روی فرانت اثر دارند

این بخش As-Is است؛ دقیقاً مطابق engine فعلی.

- variant بازی `Straight / Basic Rummy` است.
- تعداد بازیکن مجاز: `2..6`
- deck:
  - یک deck `52` کارتی
  - بدون joker
- deal:
  - `2` نفر: `10` کارت
  - `3..4` نفر: `7` کارت
  - `5..6` نفر: `6` کارت
- match چند-handی است.
- target score از `gameScore` روم می‌آید:
  - `RIM_HUNDRED -> 100`
  - `RIM_ONE_FIFTY -> 150`
  - `RIM_TWO_HUNDRED -> 200`
  - `RIM_TWO_FIFTY -> 250`
  - `RIM_THREE_HUNDRED -> 300`
- hand اول از seat `0` شروع می‌شود.
- starter هر hand بعدی به active seat بعدی rotate می‌شود.

### turn flow

- فازهای turn فقط دو مقدار دارند:
  - `DRAW`
  - `DISCARD`
- در `DRAW`:
  - بازیکن باید از `STOCK` یا top `DISCARD` یک کارت بکشد.
- بعد از draw، turn وارد `DISCARD` می‌شود.
- در `DISCARD`:
  - بازیکن می‌تواند هر تعداد meld جدید بخواباند.
  - می‌تواند هر تعداد add-to-meld انجام دهد.
  - سپس باید یک کارت discard کند.
- اگر hand بازیکن بعد از lay/add خالی شود:
  - hand همان‌جا تمام می‌شود.
  - discard نهایی لازم نیست.

### meld validity

- `SET`
  - فقط `3` یا `4` کارت
  - همه هم‌رتبه
  - suitها باید distinct باشند
- `RUN`
  - حداقل `3` کارت
  - همه از یک suit
  - باید consecutive باشند
- Ace فقط low است:
  - `A-2-3` معتبر
  - `Q-K-A` نامعتبر

### add-to-meld

- add به `SET`:
  - فقط اگر set فعلی معتبر باشد
  - حداکثر تا `4` کارت
  - rank باید match باشد
  - suit تکراری مجاز نیست
- add به `RUN`:
  - فقط به `START` یا `END`
  - suit باید match باشد
  - کارت جدید باید دقیقاً یک step قبل یا بعد run باشد
  - wraparound وجود ندارد

### discard restriction

- اگر بازیکن از `DISCARD` draw کند:
  - همان کارت را در همان turn نمی‌تواند discard کند.

### stock exhaustion

- اگر stock خالی شود:
  - همه discard pile به‌جز top card shuffle می‌شود و stock جدید می‌سازد.
- اگر discard pile فقط top card داشته باشد و recycle ممکن نباشد:
  - hand blocked می‌شود.
- در blocked hand:
  - بازیکن با کمترین deadwood برنده hand می‌شود.
  - اگر tie در کمترین deadwood وجود داشته باشد:
    - نتیجه hand برابر `BLOCKED_TIE` است.
    - score هیچ‌کس تغییر نمی‌کند.

### deadwood و scoring

- deadwood value:
  - `A = 1`
  - `2..10 = face value`
  - `J/Q/K = 10`
- winner hand مجموع deadwood همه حریف‌های active را می‌گیرد.
- bonus جداگانه برای gin/knock/rummy وجود ندارد.
- اگر winner score به target room برسد یا از آن عبور کند:
  - match تمام می‌شود.

### forfeit و timeout

- اگر بازیکن از game خارج شود:
  - از activePlayerIds حذف می‌شود.
  - اگر فقط یک active player بماند، match با reason=`FORFEIT` تمام می‌شود.
- turn timeout:
  - `20` ثانیه
  - اگر فاز `DRAW` باشد:
    - server خودش draw انجام می‌دهد.
  - اگر فاز `DISCARD` باشد:
    - server خودش یک کارت auto-discard می‌کند.
    - اگر forbidden discard card وجود داشته باشد، server کارت دیگری را انتخاب می‌کند.

---

## 5. WS Endpoint, Envelope, Connection Rules

## 5.1 Endpoint

- `endpoint`: `/ws-v3`

## 5.2 Envelope baseline

پیام‌های فرانت باید با envelope استاندارد WS v3 ارسال شوند.

نمونه generic:

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_DRAW_CARD",
  "roomId": 321,
  "clientActionId": "7f55912b-6bfb-4e17-8e17-2f9912856d1e",
  "data": {
    "roomId": 321,
    "stateVersion": 14,
    "source": "STOCK"
  }
}
```

### فیلدهای envelope که باید parse شوند

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

## 5.3 WS rules که وب باید رعایت کند

- برای همه `GAME_ACTION`ها این فیلدها را همیشه بفرست:
  - top-level `roomId`
  - top-level `clientActionId`
  - nested `data.stateVersion`
- حتی اگر بعضی فیلدها در runtime optional خوانده شوند، وب باید آن‌ها را mandatory فرض کند.
- `playerId` را نفرست یا اگر می‌فرستی، باید با user authenticated یکسان باشد.
- فرانت باید روی `ACTION_ACK` به‌عنوان state source تکیه نکند؛ state نهایی از `RIM_*` eventها یا resnapshot می‌آید.

## 5.4 دو کلاس خطا که باید جدا handle شوند

1. `type=ERROR`
- برای stale state، auth، rate limit، missing envelope fields و validationهای لایه WS

2. `type=GAME_ACTION + action=RIM_ERROR`
- برای validationهای game-specific رامی

---

## 6. Card Format و Normalization Rules

server internally و در state payloadها کارت‌ها را با suit symbol می‌فرستد:

- `A♣`
- `10♦`
- `7♥`
- `K♠`

backend هنگام دریافت input، aliasهای رایج را normalize می‌کند:

- `Ah -> A♥`
- `AS -> A♠`
- `Td -> 10♦`
- `10c -> 10♣`

### قرارداد پیشنهادی برای فرانت

- کارت انتخاب‌شده را دقیقاً با همان stringی که server در state داده دوباره send کن.
- برای state داخلی اگر خواستی card object داشته باشی، card string خام را هم نگه دار.
- روی ترتیب suit symbol یا rank casing normalization سمت UI حساب باز نکن؛ string خام server source of truth است.

### Type های پیشنهادی

```ts
export type CardSuit = "hearts" | "spades" | "diamonds" | "clubs";
export type CardRank = "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "10" | "J" | "Q" | "K" | "A";
export type RimCardWire = string; // example: "A♣"

export interface RimCard {
  raw: RimCardWire;
  rank: CardRank;
  suit: CardSuit;
}
```

---

## 7. Boot Flow و Snapshot Normalization

## 7.1 mount prerequisites

- user authenticated
- ws authenticated
- `roomId` معلوم
- game page route current user id را می‌داند

## 7.2 boot flow

در mount صفحه:

1. listenerهای زیر register شوند:
  - `STATE_SNAPSHOT`
  - `RIM_GAME_STARTED`
  - `RIM_STATE_UPDATED`
  - `RIM_HAND_FINISHED`
  - `RIM_GAME_FINISHED`
  - `RIM_ERROR`
  - `TURN_TIMER_STARTED`
  - generic `ERROR`
2. یک `GET_GAME_STATE_BY_ROOM` برای `roomId` ارسال شود.
3. اولین `STATE_SNAPSHOT` normalize شود.
4. بعد از آن full-state eventهای `RIM_GAME_STARTED` و `RIM_STATE_UPDATED` روی همان reducer مشترک اعمال شوند.

### نمونه request

```json
{
  "type": "GET_GAME_STATE_BY_ROOM",
  "roomId": 321
}
```

## 7.3 shape خام `STATE_SNAPSHOT`

برای رامی، snapshot raw `GameState` entity برمی‌گرداند، نه همان shape eventهای `RIM_STATE_UPDATED`.

shape تقریبی:

```ts
export interface RawGameStateSnapshot {
  id: number;
  currentRound?: number | null;
  currentPlayerId?: number | null;
  gameSpecificData?: {
    stateVersion?: number;
    targetScore?: number;
    handNumber?: number;
    scores?: Record<string, number>;
    activePlayerIds?: number[];
    handStarterIndex?: number;
    currentPlayerIndex?: number;
    turnPhase?: "DRAW" | "DISCARD";
    tableMelds?: Array<{ id?: string; type?: "SET" | "RUN"; cards?: string[] }>;
    playerHands?: Record<string, string[]>;
    stockCards?: string[];
    discardPile?: string[];
    mustNotDiscardCard?: string;
  };
  gameRoom?: {
    id: number;
    gameType?: string;
    gameScore?: string;
    roomStatus?: string;
    players?: Array<{
      id?: number;
      status?: string;
      seatNumber?: number;
      score?: number;
      cardsInHand?: number;
      handCards?: string[];
      user?: {
        id?: number;
        username?: string;
        email?: string;
      };
    }>;
  };
}
```

## 7.4 normalized state پیشنهادی برای UI

```ts
export type RimTurnPhase = "DRAW" | "DISCARD";

export interface RimMeld {
  id: string;
  type: "SET" | "RUN";
  cards: RimCardWire[];
}

export interface RimPlayerState {
  playerId: number;
  username: string;
  seatNumber: number;
  cardsCount: number;
  isCurrentTurn: boolean;
  isActive: boolean;
  score: number;
  isBot: boolean;
  botDifficulty?: string | null;
}

export interface RimGameState {
  roomId: number;
  gameStateId: number;
  handNumber: number;
  targetScore: number;
  currentPlayerId: number | null;
  turnPhase: RimTurnPhase;
  stockCount: number;
  discardTopCard: RimCardWire | null;
  tableMelds: RimMeld[];
  players: RimPlayerState[];
  myHandCards: RimCardWire[];
  scores: Record<number, number>;
  stateVersion: number;
}

export interface RimUiState {
  game: RimGameState | null;
  selectedHandIndices: number[];
  pendingAction?: {
    clientActionId: string;
    action:
      | "RIM_DRAW_CARD"
      | "RIM_LAY_MELD"
      | "RIM_ADD_TO_MELD"
      | "RIM_DISCARD_CARD";
  };
  turnTimer?: {
    totalSeconds: number;
    remainingSeconds: number;
    startedAtServerTime?: string;
  };
  lastHandFinished?: RimHandFinishedPayload;
  lastGameFinished?: RimGameFinishedPayload;
}
```

## 7.5 mapping snapshot -> normalized state

- `roomId = snapshot.gameRoom?.id ?? routeRoomId`
- `gameStateId = snapshot.id`
- `handNumber = snapshot.gameSpecificData.handNumber ?? snapshot.currentRound ?? 1`
- `targetScore = snapshot.gameSpecificData.targetScore ?? resolveFromRoomGameScore(snapshot.gameRoom?.gameScore) ?? 100`
- `currentPlayerId = snapshot.currentPlayerId ?? null`
- `turnPhase = snapshot.gameSpecificData.turnPhase ?? "DRAW"`
- `stockCount = snapshot.gameSpecificData.stockCards?.length ?? 0`
- `discardTopCard = last(snapshot.gameSpecificData.discardPile) ?? null`
- `tableMelds = normalize(snapshot.gameSpecificData.tableMelds ?? [])`
- `scores = parse string-key map to number-key map`
- `myHandCards = snapshot.gameSpecificData.playerHands[String(currentUserId)] ?? []`
- `players = snapshot.gameRoom.players -> normalized seat/player summary`
- `stateVersion = envelope.stateVersion`

### نکته مهم

- برای playerهای دیگر hand واقعی نمایش داده نمی‌شود.
- `myHandCards` باید از `playerHands[currentUserId]` در snapshot یا از `myHandCards` در `RIM_*` full-state eventها پر شود.

---

## 8. Server Signal Catalog

## 8.1 full-state events

این دو event مرجع اصلی state بعد از bootstrap هستند:

- `RIM_GAME_STARTED`
- `RIM_STATE_UPDATED`

shape مشترک:

```ts
export interface RimStatePayload {
  roomId: number;
  gameStateId: number;
  handNumber: number;
  targetScore: number;
  currentPlayerId: number | null;
  turnPhase: "DRAW" | "DISCARD";
  stockCount: number;
  discardTopCard: RimCardWire | null;
  tableMelds: RimMeld[];
  players: RimPlayerState[];
  myHandCards: RimCardWire[];
  scores: Record<string, number>;
  stateVersion?: number;
}
```

### نکته مربوط به bot-assisted rooms

- برای `internal/tester rooms` ممکن است بعضی playerها این فیلدها را داشته باشند:
  - `isBot = true`
  - `botDifficulty = "NOVICE" | "STANDARD" | "EXPERT"`
- این فیلدها additive هستند و در roomهای عادی می‌توانند غایب باشند.

### نمونه

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_STATE_UPDATED",
  "roomId": 321,
  "stateVersion": 18,
  "data": {
    "roomId": 321,
    "gameStateId": 999,
    "handNumber": 2,
    "targetScore": 150,
    "currentPlayerId": 77,
    "turnPhase": "DISCARD",
    "stockCount": 27,
    "discardTopCard": "7♣",
    "tableMelds": [
      { "id": "meld-ab12", "type": "RUN", "cards": ["A♥", "2♥", "3♥"] }
    ],
    "players": [
      {
        "playerId": 77,
        "username": "alpha",
        "seatNumber": 0,
        "cardsCount": 6,
        "isCurrentTurn": true,
        "isActive": true,
        "score": 24
      }
    ],
    "myHandCards": ["4♦", "5♦", "6♦", "K♠", "K♥", "K♣"],
    "scores": { "77": 24, "88": 19 }
  }
}
```

## 8.2 `TURN_TIMER_STARTED`

```ts
export interface TurnTimerStartedPayload {
  gameStateId: number;
  timeoutSeconds: number;
}
```

نمونه:

```json
{
  "type": "GAME_ACTION",
  "action": "TURN_TIMER_STARTED",
  "roomId": 321,
  "stateVersion": 18,
  "data": {
    "gameStateId": 999,
    "timeoutSeconds": 20
  }
}
```

رفتار پیشنهادی:

- با هر `TURN_TIMER_STARTED` تایمر local reset شود.
- countdown فقط برای `currentPlayerId` نمایش داده شود.
- اگر `RIM_HAND_FINISHED` یا `RIM_GAME_FINISHED` رسید، تایمر stop شود.

## 8.2.1 `BOT_DECISION_DEBUG`

- فقط برای `internal/tester rooms` مهم است.
- برای roomهای عمومی می‌توان آن را ignore کرد.
- actionهای رایج:
  - `DRAW_CARD`
  - `LAY_MELD`
  - `ADD_TO_MELD`
  - `DISCARD_CARD`
- UX پیشنهادی:
  - `DRAW_CARD` با source `DISCARD` => `"<username>: برداشت از دورریز"`
  - `DRAW_CARD` با source `STOCK` => `"<username>: برداشت از دسته بسته"`
  - `LAY_MELD` => `"<username>: خواباندن <n> کارت"`
  - `ADD_TO_MELD` => `"<username>: افزودن <card> به ترکیب"`
  - `DISCARD_CARD` => `"<username>: دور انداختن <card>"`

## 8.3 `RIM_HAND_FINISHED`

```ts
export interface RimHandFinishedPayload {
  roomId: number;
  gameStateId: number;
  handNumber: number;
  winnerId: number | null;
  winnerUsername: string | null;
  handPoints: number;
  handDeadwood: Record<string, number>;
  scores: Record<string, number>;
  scoresByUsername: Record<string, number>;
  reason?: "RIM" | "STOCK_EXHAUSTED" | "TIMEOUT" | "BLOCKED_TIE";
}
```

### blocked tie نمونه

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_HAND_FINISHED",
  "roomId": 321,
  "stateVersion": 25,
  "data": {
    "roomId": 321,
    "gameStateId": 999,
    "handNumber": 4,
    "winnerId": null,
    "winnerUsername": null,
    "handPoints": 0,
    "handDeadwood": { "77": 9, "88": 9 },
    "scores": { "77": 43, "88": 52 },
    "scoresByUsername": { "alpha": 43, "beta": 52 },
    "reason": "BLOCKED_TIE"
  }
}
```

## 8.4 `RIM_GAME_FINISHED`

```ts
export interface RimGameFinishedPayload {
  roomId: number;
  gameId: number;
  winnerId: number | null;
  winnerUsername: string | null;
  finalScores: Record<string, number>;
  xpRewards?: Record<string, number>;
  coinRewards?: Record<string, number>;
  reason?: "FORFEIT";
  leavingPlayer?: string;
}
```

### نمونه

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_GAME_FINISHED",
  "roomId": 321,
  "stateVersion": 41,
  "data": {
    "gameId": 999,
    "roomId": 321,
    "winnerId": 77,
    "winnerUsername": "alpha",
    "finalScores": { "alpha": 151, "beta": 84 },
    "xpRewards": { "winner": 50, "participants": 10 },
    "coinRewards": { "winner": 180, "totalPot": 200, "platformFee": 20 }
  }
}
```

## 8.5 `RIM_ERROR`

```ts
export interface RimErrorPayload {
  roomId: number;
  error: string;
}
```

نمونه:

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_ERROR",
  "roomId": 321,
  "stateVersion": 18,
  "data": {
    "roomId": 321,
    "error": "فاز فعلی برای این عمل معتبر نیست"
  }
}
```

---

## 9. Client Action Contract

## 9.1 `RIM_DRAW_CARD`

### payload

```ts
export interface RimDrawCardInput {
  roomId: number;
  stateVersion: number;
  source: "STOCK" | "DISCARD";
}
```

### example

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_DRAW_CARD",
  "roomId": 321,
  "clientActionId": "5d67054f-4b89-4045-bc32-e584e20d3249",
  "data": {
    "roomId": 321,
    "stateVersion": 14,
    "source": "DISCARD"
  }
}
```

### client prechecks

- game موجود باشد
- current user همان `currentPlayerId` باشد
- `turnPhase === "DRAW"`
- `source` فقط `STOCK` یا `DISCARD`
- اگر `source === "DISCARD"` و `discardTopCard == null` است، button را disable کن

### server-side rejects محتمل

- `نوبت شما نیست`
- `فاز فعلی برای این عمل معتبر نیست`
- `بازیکن فعال نیست`
- `دیسکارد خالی است`

### expected outputs

- `ACTION_ACK`
- سپس یکی از این‌ها:
  - `RIM_STATE_UPDATED`
  - `RIM_HAND_FINISHED` در حالت stock exhaustion blocked

## 9.2 `RIM_LAY_MELD`

### payload

```ts
export interface RimLayMeldInput {
  roomId: number;
  stateVersion: number;
  cards: RimCardWire[];
}
```

### example

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_LAY_MELD",
  "roomId": 321,
  "clientActionId": "fcd1312d-aac9-41f7-aeb1-df31ded402d8",
  "data": {
    "roomId": 321,
    "stateVersion": 18,
    "cards": ["4♦", "5♦", "6♦"]
  }
}
```

### client prechecks

- current user turn باشد
- `turnPhase === "DISCARD"`
- حداقل `3` کارت انتخاب شده باشد
- همه کارت‌ها distinct باشند
- کارت‌ها واقعاً در `myHandCards` باشند
- UI بهتر است قبل از send نوع meld را locally validate کند، ولی validation نهایی با server است

### server-side rejects محتمل

- `ملد باید حداقل ۳ کارت داشته باشد`
- `کارت‌های انتخاب‌شده در دست بازیکن نیست`
- `ترکیب کارت معتبر نیست`
- `نوبت شما نیست`
- `فاز فعلی برای این عمل معتبر نیست`

### expected outputs

- `ACTION_ACK`
- سپس:
  - `RIM_STATE_UPDATED`
  - یا `RIM_HAND_FINISHED` اگر hand خالی شود

## 9.3 `RIM_ADD_TO_MELD`

### payload

```ts
export interface RimAddToMeldInput {
  roomId: number;
  stateVersion: number;
  meldId: string;
  card: RimCardWire;
  side: "START" | "END";
}
```

### example

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_ADD_TO_MELD",
  "roomId": 321,
  "clientActionId": "3fe6dc83-8ad6-45af-98e5-a7a5d8b8b596",
  "data": {
    "roomId": 321,
    "stateVersion": 19,
    "meldId": "meld-ab12",
    "card": "7♦",
    "side": "END"
  }
}
```

### client prechecks

- current user turn باشد
- `turnPhase === "DISCARD"`
- دقیقاً یک کارت از hand انتخاب شده باشد
- meld target وجود داشته باشد
- `side` فقط `START` یا `END`
- اگر meld از نوع `SET` است، UI می‌تواند `END` را به‌صورت پیش‌فرض بفرستد؛ backend برای set عملاً side را نادیده می‌گیرد

### server-side rejects محتمل

- `کارت انتخاب‌شده در دست بازیکن نیست`
- `ملد موردنظر پیدا نشد`
- `مقدار side نامعتبر است`
- `افزودن کارت به این set مجاز نیست`
- `افزودن کارت به این run مجاز نیست`
- `نوع meld نامعتبر است`
- `نوبت شما نیست`
- `فاز فعلی برای این عمل معتبر نیست`

### expected outputs

- `ACTION_ACK`
- سپس:
  - `RIM_STATE_UPDATED`
  - یا `RIM_HAND_FINISHED` اگر hand خالی شود

## 9.4 `RIM_DISCARD_CARD`

### payload

```ts
export interface RimDiscardCardInput {
  roomId: number;
  stateVersion: number;
  card: RimCardWire;
}
```

### example

```json
{
  "type": "GAME_ACTION",
  "action": "RIM_DISCARD_CARD",
  "roomId": 321,
  "clientActionId": "2f7a1fa0-8ebf-4b30-815d-32e3ab3bf05e",
  "data": {
    "roomId": 321,
    "stateVersion": 20,
    "card": "K♠"
  }
}
```

### client prechecks

- current user turn باشد
- `turnPhase === "DISCARD"`
- دقیقاً یک کارت انتخاب شده باشد
- کارت در `myHandCards` باشد
- اگر کاربر این turn از discard draw کرده، UI بهتر است همان کارت را locally disable کند

### server-side rejects محتمل

- `این کارت در دست بازیکن نیست`
- `کارتی که از discard کشیده‌اید را نمی‌توانید همان نوبت دور بیندازید`
- `نوبت شما نیست`
- `فاز فعلی برای این عمل معتبر نیست`

### expected outputs

- `ACTION_ACK`
- سپس یکی از این‌ها:
  - `RIM_STATE_UPDATED` برای شروع turn بعدی
  - `RIM_HAND_FINISHED` اگر discard آخر hand را خالی کند
  - `RIM_GAME_FINISHED` اگر match روی همین hand تمام شود

---

## 10. UI State Machine و Interaction Rules

## 10.1 phase = `DRAW`

در این فاز فقط این actionها active هستند:

- `Draw From Stock`
- `Draw From Discard`

این actionها باید disabled باشند:

- `Lay Meld`
- `Add To Meld`
- `Discard`

### selection behavior

- اگر phase `DRAW` است، hand selection می‌تواند purely visual باشد، ولی نباید action bar را enable کند.
- اگر reconnect یا full-state update آمد و phase از `DISCARD` به `DRAW` برگشت، selection قبلی پاک شود.

## 10.2 phase = `DISCARD`

در این فاز:

- draw buttonها disabled
- lay/add/discard فعال
- user می‌تواند چند بار lay یا add انجام دهد
- state هر بار فقط از response server update می‌شود

### recommended button policy

- `Lay Meld`
  - وقتی `selectedHandIndices.length >= 3`
- `Add To Meld`
  - وقتی `selectedHandIndices.length === 1`
  - و حداقل یک meld روی میز وجود دارد
- `Discard`
  - وقتی `selectedHandIndices.length === 1`

## 10.3 reconnect/resync policy

- اگر event stream را از دست دادی یا `ERROR` با `errorCode=STATE_RESYNC_REQUIRED` گرفتی:
  - فوراً `GET_GAME_STATE_BY_ROOM` بزن
  - local pending action را clear کن
  - selection را clear کن
- هر full-state update جدید باید selection نامعتبر را پاک کند:
  - indexهای خارج از range
  - selection روی cardی که دیگر در hand نیست

## 10.4 hand/game finish UX

- روی `RIM_HAND_FINISHED`
  - selection پاک شود
  - timer متوقف شود
  - hand نتیجه نمایش داده شود
  - UI برای `BLOCKED_TIE` متن مخصوص داشته باشد
- روی `RIM_GAME_FINISHED`
  - timer متوقف شود
  - action bar غیرفعال شود
  - modal نهایی نتیجه match نمایش داده شود

---

## 11. Error Handling Matrix

## 11.1 generic WS `ERROR`

این خطاها را global handle کن:

| `errorCode` | معنی | رفتار اجباری فرانت |
|---|---|---|
| `AUTH_REQUIRED` | session معتبر نیست | logout/reauth flow |
| `ACTION_REJECTED` | payload/game action envelope ناقص یا invalid | toast + clear pending |
| `RATE_LIMITED` | کاربر خیلی سریع action فرستاده | toast + retry later |
| `STATE_RESYNC_REQUIRED` | stateVersion کلاینت stale است | `GET_GAME_STATE_BY_ROOM` |

نمونه stale state:

```json
{
  "type": "ERROR",
  "action": "GAME_ACTION",
  "roomId": 321,
  "success": false,
  "errorCode": "STATE_RESYNC_REQUIRED",
  "error": "Client state is stale. Snapshot required.",
  "stateVersion": 21,
  "clientActionId": "..."
}
```

## 11.2 game-specific `RIM_ERROR`

فهرست خطاهای دیده‌شده در runtime:

- `بازیکن فعال نیست`
- `دیسکارد خالی است`
- `ملد باید حداقل ۳ کارت داشته باشد`
- `کارت‌های انتخاب‌شده در دست بازیکن نیست`
- `ترکیب کارت معتبر نیست`
- `کارت انتخاب‌شده در دست بازیکن نیست`
- `ملد موردنظر پیدا نشد`
- `مقدار side نامعتبر است`
- `افزودن کارت به این set مجاز نیست`
- `افزودن کارت به این run مجاز نیست`
- `نوع meld نامعتبر است`
- `این کارت در دست بازیکن نیست`
- `کارتی که از discard کشیده‌اید را نمی‌توانید همان نوبت دور بیندازید`
- `نوبت شما نیست`
- `فاز فعلی برای این عمل معتبر نیست`

رفتار پیشنهادی:

- toast/snackbar کوتاه
- pending action پاک شود
- state فعلی حفظ شود
- در خطاهای turn/phase mismatch، اگر احتمال drift وجود داشت resnapshot بگیر

---

## 12. GAP Log

### GAP-001: `STATE_SNAPSHOT` shape خام با `RIM_STATE_UPDATED` هم‌شکل نیست

- snapshot raw `GameState` entity است.
- full-state eventهای رامی shape ساده‌تر و gameplay-friendly دارند.
- وب باید adapter مستقل برای snapshot داشته باشد.

### GAP-002: `myHandCards` فقط در personal payloadها explicit است

- در `RIM_GAME_STARTED` و `RIM_STATE_UPDATED` این فیلد per-user ارسال می‌شود.
- برای snapshot raw باید hand خود کاربر از `gameSpecificData.playerHands[currentUserId]` استخراج شود.

### GAP-003: map keyها stringified id هستند

- `scores`
- `handDeadwood`

وب نباید این mapها را `Record<number, ...>` خام parse کند؛ باید keyها را number-normalize کند.

### GAP-004: `RIM_ERROR` خطای gameplay است، نه `ERROR` envelope

- بنابراین reducer خطا فقط روی `type=ERROR` ننشیند.
- `GAME_ACTION/RIM_ERROR` هم باید جدا شنیده شود.

### GAP-005: `winnerId` و `winnerUsername` در hand-finished همیشه non-null نیستند

- در `BLOCKED_TIE` هر دو `null` می‌شوند.
- UI نباید روی وجود winner در hand modal فرض سخت داشته باشد.

### GAP-006: `ACTION_ACK` فقط دریافت server است، نه confirmation state transition

- ممکن است action accept شود ولی state نهایی کمی بعد با `RIM_STATE_UPDATED` یا finish event برسد.
- UI optimistic-reducer کامل ننویسد مگر با rollback واضح.

---

## 13. Acceptance Checklist

پیاده‌سازی وب فقط وقتی complete محسوب می‌شود که این سناریوها pass شوند:

1. user وارد room فعال می‌شود و فقط با `GET_GAME_STATE_BY_ROOM` state کامل را reconstruct می‌کند.
2. flow کامل `draw -> lay/add -> discard` بدون reliance به Flutter reference کار می‌کند.
3. `TURN_TIMER_STARTED` countdown را reset می‌کند و روی hand/game finish متوقف می‌شود.
4. draw از discard و ممنوعیت discard همان کارت در UI و server هر دو رعایت می‌شود.
5. blocked hand tie با winner null درست render می‌شود.
6. reconnect وسط hand بدون reload کامل صفحه recover می‌شود.
7. stale state با `STATE_RESYNC_REQUIRED` و resnapshot recover می‌شود.
