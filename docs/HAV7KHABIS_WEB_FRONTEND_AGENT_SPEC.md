# مستند اجرایی هفت خبیث برای ایجنت فرانت وب

- نسخه: `1.0`
- تاریخ: `2026-03-11`
- وضعیت: `Frontend Agent Ready`
- دامنه: `Gameplay هفت خبیث روی وب + قرارداد WS لازم برای بازی`

---

## 1. هدف این سند

این سند باید برای ایجنت فرانت کافی باشد تا gameplay وب بازی هفت خبیث را بدون رجوع به Flutter فعلی پیاده کند؛ شامل:

- state model لازم برای UI
- actionهای قابل ارسال به سرور
- eventهای دریافتی از سرور
- validationهای لازم قبل از ارسال
- رفتار UI در هر حالت بازی
- gapهای runtime فعلی که نباید کورکورانه از reference موبایل کپی شوند

این سند فقط برای gameplay است. ساخت روم، join/leave عمومی، wallet، friends و featureهای خارج از میز بازی در این سند نیستند.

---

## 2. Source Of Truth

مرجع قطعی این سند backend runtime فعلی است.

### فایل‌های مرجع

- `gameBackend/src/main/java/com/gameapp/game/services/CrazyEightsEngineService.java`
- `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
- `gameBackend/src/main/java/com/gameapp/game/core/common/CardUtils.java`
- `gameapp/lib/features/game/data/models/crazy_eights_game_state.dart`
- `gameapp/lib/features/game/ui/game_ui/crazy_eights_game_ui.dart`
- `docs/OPUS_WS_V3_IMPLEMENTATION_GUIDE.md`
- `docs/WS_V3_PAYLOAD_INVENTORY.md`

### اصل مهم

- اگر بین Flutter فعلی و backend اختلاف بود، backend معتبر است.
- اگر بین contract عمومی WS و runtime هفت خبیث اختلاف بود، runtime معتبر است.

---

## 3. خلاصه قوانین runtime که روی فرانت اثر دارند

این بخش As-Is است؛ دقیقاً مطابق engine فعلی.

- بازی انفرادی و تک‌راندی است.
- تعداد بازیکن مجاز: `4..7`
- اگر تعداد بازیکن `<= 4` باشد:
  - از یک deck استفاده می‌شود.
  - هر بازیکن `8` کارت می‌گیرد.
- اگر تعداد بازیکن `5..7` باشد:
  - از two-deck استفاده می‌شود.
  - هر بازیکن `10` کارت می‌گیرد.
- هدف بازی: اولین بازیکنی که hand خودش را خالی کند برنده است.
- starter card:
  - از روی deck انتخاب می‌شود.
  - rankهای `7`, `8`, `2` برای starter مجاز نیستند.
  - اگر همه گزینه‌ها special بودند، fallback روی اولین کارت ممکن انجام می‌شود.
- شروع بازی:
  - بازیکن صندلی `0` شروع‌کننده است.
  - `currentSuit` و `currentRank` از starter card تنظیم می‌شوند.
- جهت بازی:
  - `1 = normal`
  - `-1 = reverse`

### قوانین playability در runtime

- اگر `pendingDrawCount > 0` باشد:
  - فقط کارت `7` قابل بازی است.
  - هیچ کارت دیگری، حتی `8`، مجاز نیست.
- اگر pending draw فعال نباشد:
  - `8` همیشه قابل بازی است.
  - سایر کارت‌ها فقط اگر suit یا rank با `currentSuit/currentRank` match کنند مجازند.

### معنی کارت‌های خاص در runtime فعلی

- `8`
  - نوبت اضافه برای همان بازیکن
  - خال انتخاب نمی‌شود
- `J`
  - وارد `waitingForSuitChoice=true` می‌شود
  - بازیکن باید یکی از ۴ خال را انتخاب کند
  - بعد از انتخاب خال، نوبت به بازیکن بعدی می‌رسد
- `A`
  - نوبت بازیکن بعدی می‌پرد
- `10`
  - جهت بازی برعکس می‌شود
- `2`
  - بازیکن باید یک target player انتخاب کند
  - یک کارت از deck به آن بازیکن داده می‌شود
  - سپس نوبت به بازیکن بعدی می‌رسد
- `7`
  - `pendingDrawCount += 2`
  - نوبت به بازیکن بعدی می‌رسد
  - بازیکن بعدی یا باید `7` بازی کند یا همه جریمه را بکشد

### رفتار draw در runtime فعلی

- اگر `pendingDrawCount > 0` باشد:
  - بازیکن همه جریمه را می‌کشد
  - `pendingDrawCount = 0`
  - نوبت او رد می‌شود
- اگر pending draw فعال نباشد:
  - فقط ۱ کارت می‌کشد
  - `hasDrawnThisTurn = true`
  - اگر بعد از draw کارت playable داشته باشد، نوبت خودش باقی می‌ماند
  - اگر کارت playable نداشته باشد، نوبت به بازیکن بعدی می‌رسد و `hasDrawnThisTurn=false`

### deck empty

- اگر deck خالی شود، از discard pile به‌جز top card reshuffle می‌شود.

### پایان بازی

- اولین بازیکنی که hand او صفر شود برنده است.
- مدل payout:
  - `90%` pot برای برنده
  - `10%` کمیسیون
- XP:
  - winner: `50`
  - loser: `10`

---

## 4. Boot Flow صفحه وب

پیش‌نیازهای mount:

- کاربر authenticate شده باشد.
- WebSocket روی `/ws-v3` وصل و `AUTH` شده باشد.
- `roomId` مشخص باشد.
- اطلاعات پایه روم مثل `entryFee` و تعداد بازیکنان روم در دسترس باشد.

### Boot Flow

در mount صفحه:

1. listenerهای CE register شوند.
2. یک `GET_GAME_STATE_BY_ROOM` با `roomId` ارسال شود.
3. `STATE_SNAPSHOT` normalize و به state صفحه تبدیل شود.
4. سپس eventهای full-state زیر روی همان reducer اعمال شوند:
   - `CE_GAME_STARTED`
   - `CE_CARD_PLAYED`
   - `CE_CARD_DRAWN`
   - `CE_CARD_GIVEN`
   - `CE_SUIT_CHANGED`
   - `CE_PLAYER_LEFT`

### نکته مهم

- روی `CE_GAME_STATE` تکیه نکنید؛ runtime فعلی آن را emit نمی‌کند.
- روی `CE_SUIT_CHOSEN` تکیه نکنید؛ runtime فعلی `CE_SUIT_CHANGED` می‌فرستد.

---

## 5. مدل داده‌ای پیشنهادی برای فرانت

```ts
export type CardSuit = "hearts" | "spades" | "diamonds" | "clubs";
export type CardRank = "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "10" | "J" | "Q" | "K" | "A";
export type CardWire = `${CardRank}${"h" | "s" | "d" | "c"}`;

export interface CeCard {
  suit: CardSuit;
  rank: CardRank;
}

export interface CePlayer {
  playerId: number;
  username: string;
  seatNumber: number;
  cardsCount: number;
  isCurrentTurn: boolean;
  handCards: CeCard[];
}

export interface CeGameState {
  roomId: number;
  gameStateId: number;
  currentPlayerId: number;
  currentSuit: CardSuit | "";
  currentRank: CardRank | "";
  topCard?: CeCard;
  direction: 1 | -1;
  pendingDrawCount: number;
  waitingForSuitChoice: boolean;
  waitingForGiveCard: boolean;
  lastPlayedSpecial: "" | "7" | "8" | "10" | "J" | "A" | "2";
  hasDrawnThisTurn: boolean;
  deckRemaining: number;
  players: CePlayer[];
  isFinished: boolean;
  winnerId?: number;
  stateVersion: number;
}

export interface CeUiState {
  game: CeGameState | null;
  selectedCard?: CardWire;
  pendingAction?: {
    clientActionId: string;
    action:
      | "CE_PLAY_CARD"
      | "CE_DRAW_CARD"
      | "CE_CHOOSE_SUIT"
      | "CE_GIVE_CARD"
      | "CE_FORFEIT"
      | "CE_TURN_TIMEOUT";
  };
  turnTimerSeconds: number;
  giveCardMode: boolean;
  finishModal?: CeGameFinishedPayload;
}
```

### Adapter اجباری

- در CE full-state eventها فیلد `gameId` می‌آید.
- فرانت باید آن را به `gameStateId = Number(gameId)` تبدیل کند.
- `stateVersion` را از envelope top-level بخواند، نه از data payload.

---

## 6. نرمال‌سازی `STATE_SNAPSHOT`

برای هفت خبیث، `STATE_SNAPSHOT` raw `GameState` برمی‌گرداند و shape آن با eventهای `CE_*` یکی نیست.

### shape تقریبی snapshot

```ts
{
  id: number;
  currentRound: number;
  currentPlayerId: number;
  gameSpecificData: {
    deckCards?: string[];
    discardPile?: string[];
    currentSuit?: CardSuit;
    currentRank?: CardRank;
    direction?: 1 | -1;
    pendingDrawCount?: number;
    currentPlayerIndex?: number;
    waitingForSuitChoice?: boolean;
    waitingForGiveCard?: boolean;
    lastPlayedSpecial?: string;
    hasDrawnThisTurn?: boolean;
    stateVersion?: number;
  };
  gameRoom?: {
    id: number;
    players?: Array<{
      seatNumber?: number;
      handCards?: string[];
      user?: { id: number; username?: string; email?: string };
    }>;
  };
}
```

### normalizer پیشنهادی

```ts
function normalizeCeSnapshot(snapshot: any, roomId: number): CeGameState {
  const gs = snapshot?.gameSpecificData ?? {};
  const discardPile = Array.isArray(gs?.discardPile) ? gs.discardPile : [];
  const topCardRaw = discardPile.length > 0 ? discardPile[discardPile.length - 1] : undefined;

  const players = (snapshot?.gameRoom?.players ?? []).map((p: any) => {
    const hand = (p?.handCards ?? []).map(parseCompactCard);
    const userId = Number(p?.user?.id ?? 0);
    return {
      playerId: userId,
      username: String(p?.user?.username || p?.user?.email || ""),
      seatNumber: Number(p?.seatNumber ?? 0),
      cardsCount: hand.length,
      isCurrentTurn: userId === Number(snapshot?.currentPlayerId ?? 0),
      handCards: hand,
    };
  });

  return {
    roomId,
    gameStateId: Number(snapshot?.id ?? 0),
    currentPlayerId: Number(snapshot?.currentPlayerId ?? 0),
    currentSuit: (gs?.currentSuit ?? "") as CeGameState["currentSuit"],
    currentRank: (gs?.currentRank ?? "") as CeGameState["currentRank"],
    topCard: topCardRaw ? parseCompactCard(topCardRaw) : undefined,
    direction: Number(gs?.direction ?? 1) === -1 ? -1 : 1,
    pendingDrawCount: Number(gs?.pendingDrawCount ?? 0),
    waitingForSuitChoice: Boolean(gs?.waitingForSuitChoice),
    waitingForGiveCard: Boolean(gs?.waitingForGiveCard),
    lastPlayedSpecial: String(gs?.lastPlayedSpecial ?? "") as CeGameState["lastPlayedSpecial"],
    hasDrawnThisTurn: Boolean(gs?.hasDrawnThisTurn),
    deckRemaining: Array.isArray(gs?.deckCards) ? gs.deckCards.length : 0,
    players,
    isFinished: false,
    stateVersion: Number(gs?.stateVersion ?? 0),
  };
}
```

### parse helper

```ts
function parseCompactCard(card: string): CeCard {
  const suit = card.at(-1);
  const rank = card.slice(0, -1).toUpperCase();
  return {
    rank: rank === "T" ? "10" : (rank as CardRank),
    suit:
      suit === "h" || suit === "♥" ? "hearts" :
      suit === "d" || suit === "♦" ? "diamonds" :
      suit === "c" || suit === "♣" ? "clubs" :
      "spades",
  };
}
```

---

## 7. چیدمان و رفتار بصری

### 7.1 نمایش بازیکنان

- خود بازیکن پایین
- سایر بازیکنان دور میز
- seatNumber را برای ordering استفاده کنید، نه فقط آرایه ورودی

### 7.2 مواردی که باید همیشه نمایش داده شوند

- top card وسط میز
- current suit
- جهت بازی
- deck remaining
- pending draw badge وقتی `pendingDrawCount > 0`
- countdown محلی نوبت
- تعداد کارت باقی‌مانده هر حریف
- mode indicator برای:
  - `waitingForSuitChoice`
  - `waitingForGiveCard`
  - penalty mode

### 7.3 نمایش کارت‌ها

- فقط hand بازیکن فعلی باید face-up رندر شود.
- hand سایر بازیکنان باید hidden باشد.
- حتی اگر backend handCards همه بازیکنان را می‌فرستد، فرانت وب نباید آن‌ها را نمایش دهد.

---

## 8. State Authority

برای هفت خبیث state اصلی از این eventها می‌آید:

- `STATE_SNAPSHOT` بعد از normalize
- `CE_GAME_STARTED`
- `CE_CARD_PLAYED`
- `CE_CARD_DRAWN`
- `CE_CARD_GIVEN`
- `CE_SUIT_CHANGED`
- `CE_PLAYER_LEFT`

### رویدادهای non-state

- `CE_PLAY_ERROR`
- `CE_GAME_FINISHED`

### قاعده

- eventهای full-state همیشه replace کامل state هستند، نه merge سطحی.
- `CE_GAME_FINISHED` نتیجه نهایی است، نه state کامل gameplay.

---

## 9. Action Catalog

همه actionها باید با envelope استاندارد `GAME_ACTION` ارسال شوند:

```json
{
  "type": "GAME_ACTION",
  "action": "CE_PLAY_CARD",
  "roomId": 4101,
  "clientActionId": "ca_1762000000001",
  "data": {
    "roomId": 4101,
    "card": "7h",
    "stateVersion": 12
  }
}
```

### قوانین عمومی همه actionها

- `type=GAME_ACTION`
- `action` اجباری
- `roomId` top-level اجباری
- `clientActionId` اجباری
- `data.stateVersion` اجباری
- As-Is runtime:
  - برای `CE_*` علاوه بر `roomId` top-level باید `data.roomId` هم ارسال شود
- `stateVersion` جدیدترین نسخه room state باشد
- gameplay optimistic ممنوع است

### 9.1 `CE_PLAY_CARD`

#### ورودی

```ts
{
  roomId: number; // داخل data
  card: CardWire;
  stateVersion: number;
}
```

#### ولیدیشن قبل از ارسال

- کاربر باید `currentPlayerId` باشد.
- `waitingForSuitChoice` نباید true باشد.
- `waitingForGiveCard` نباید true باشد.
- کارت باید در hand بازیکن وجود داشته باشد.
- اگر `pendingDrawCount > 0` باشد:
  - فقط `7` مجاز است.
- اگر `pendingDrawCount === 0` باشد:
  - `8` همیشه مجاز است.
  - یا suit باید با `currentSuit` match کند
  - یا rank باید با `currentRank` match کند

#### خروجی مورد انتظار

- فوری:
  - `ACTION_ACK`
- async:
  - `CE_CARD_PLAYED`
  - یا اگر hand خالی شود:
    - `CE_GAME_FINISHED`

### 9.2 `CE_DRAW_CARD`

#### ورودی

```ts
{
  roomId: number;
  stateVersion: number;
}
```

#### ولیدیشن قبل از ارسال

- کاربر باید `currentPlayerId` باشد.
- `waitingForSuitChoice` و `waitingForGiveCard` false باشند.
- `hasDrawnThisTurn` false باشد.

#### توضیح مهم

runtime فعلی draw را حتی وقتی بازیکن playable card دارد هم اجازه می‌دهد.  
اگر محصول بخواهد draw فقط در نبود playable card مجاز باشد، این change نیازمند backend change است.

#### خروجی مورد انتظار

- فوری:
  - `ACTION_ACK`
- async:
  - `CE_CARD_DRAWN`

#### اثر UI

- اگر بعد از draw هنوز نوبت با بازیکن بماند، draw button باید غیرفعال بماند چون `hasDrawnThisTurn=true` شده است.

### 9.3 `CE_CHOOSE_SUIT`

#### ورودی

```ts
{
  roomId: number;
  suit: CardSuit;
  stateVersion: number;
}
```

#### ولیدیشن قبل از ارسال

- کاربر باید `currentPlayerId` باشد.
- `waitingForSuitChoice` باید true باشد.
- `suit` فقط یکی از این ۴ مقدار باشد:
  - `hearts`
  - `diamonds`
  - `clubs`
  - `spades`

#### خروجی مورد انتظار

- فوری:
  - `ACTION_ACK`
- async:
  - `CE_SUIT_CHANGED`

### 9.4 `CE_GIVE_CARD`

#### ورودی

```ts
{
  roomId: number;
  targetPlayerId: number;
  stateVersion: number;
}
```

#### ولیدیشن قبل از ارسال

- کاربر باید `currentPlayerId` باشد.
- `waitingForGiveCard` باید true باشد.
- `targetPlayerId` باید یکی از بازیکنان موجود به‌جز خود کاربر باشد.

#### خروجی مورد انتظار

- فوری:
  - `ACTION_ACK`
- async:
  - `CE_CARD_GIVEN`

### 9.5 `CE_FORFEIT`

#### ورودی

```ts
{
  roomId: number;
  stateVersion: number;
}
```

#### ولیدیشن قبل از ارسال

- اگر بازی active است، action مجاز است.
- ترجیحاً قبل از ارسال confirmation dialog نمایش داده شود.

#### خروجی مورد انتظار

- فوری:
  - `ACTION_ACK`
- async:
  - اگر بازیکنان کافی باقی بمانند:
    - `CE_PLAYER_LEFT`
  - اگر فقط یک نفر بماند:
    - `CE_GAME_FINISHED`

### 9.6 `CE_TURN_TIMEOUT`

#### ورودی

```ts
{
  roomId: number;
  stateVersion: number;
}
```

#### توضیح

- fallback است.
- backend خودش هم timer server-side دارد.
- اگر countdown محلی صفر شد و هنوز update نیامده بود، می‌توان این action را ارسال کرد.

#### رفتار runtime

- اگر `waitingForSuitChoice` باشد: suit تصادفی انتخاب می‌شود
- اگر `waitingForGiveCard` باشد: target تصادفی انتخاب می‌شود
- در غیر این صورت: draw انجام می‌شود

---

## 10. Event Catalog

### 10.1 Full-state CE events

این eventها همگی shape تقریباً یکسان دارند:

```ts
{
  gameId: number;
  roomId: number;
  currentPlayerId: number;
  direction: 1 | -1;
  pendingDrawCount: number;
  waitingForSuitChoice: boolean;
  waitingForGiveCard: boolean;
  lastPlayedSpecial: string;
  hasDrawnThisTurn: boolean;
  currentSuit: CardSuit;
  currentRank: CardRank;
  topCard: string;
  topCardSuit: CardSuit;
  topCardRank: CardRank;
  deckRemaining: number;
  players: Array<{
    playerId: number;
    username: string;
    seatNumber: number;
    cardsCount: number;
    isCurrentTurn: boolean;
    handCards: Array<{ suit: CardSuit; rank: CardRank }>;
  }>;
}
```

این actionها full-state هستند:

- `CE_GAME_STARTED`
- `CE_CARD_PLAYED`
- `CE_CARD_DRAWN`
- `CE_CARD_GIVEN`
- `CE_SUIT_CHANGED`
- `CE_PLAYER_LEFT`

#### رفتار فرانت

- replace کامل state
- `gameId -> gameStateId`
- `stateVersion` را از envelope بگیرد
- selection محلی و pending ناسازگار reset شود

### 10.2 `CE_PLAY_ERROR`

```ts
{
  error?: string;
  message?: string;
}
```

#### رفتار فرانت

- toast خطا نمایش داده شود
- pending action مرتبط پاک شود
- state اصلی overwrite نشود

#### نکته مهم

runtime فقط برای invalid card play این event را می‌فرستد.  
برای برخی invalid stateها مثل out-of-turn یا waiting mode ممکن است فقط silently ignore شود.
این event actor id ندارد و room-wide broadcast می‌شود؛
پس بهتر است فقط وقتی به‌عنوان خطای شخصی نمایش داده شود که:

- کاربر pending `CE_PLAY_CARD` داشته باشد
- یا کاربر current player فعلی باشد

### 10.3 `CE_GAME_FINISHED`

```ts
export interface CeGameFinishedPayload {
  gameId: number;
  roomId: number;
  winnerId: number;
  winnerCoins: number;
  coinRewards?: Record<string, number>;
  xpRewards?: Record<string, number>;
  players: Array<{
    playerId: number;
    username: string;
    cardsRemaining: number;
    isWinner: boolean;
  }>;
}
```

#### رفتار فرانت

- timer متوقف شود
- modal نتیجه نهایی باز شود
- modal باید حداقل این‌ها را نشان دهد:
  - winner
  - winner coins
  - XP user
  - وضعیت هر بازیکن و `cardsRemaining`

---

## 11. Timer Policy

### واقعیت runtime

- backend timer داخلی `20s` دارد.
- برای هفت خبیث eventی مثل `TURN_TIMER_STARTED` broadcast نمی‌شود.

### نتیجه برای فرانت

- countdown وب فقط local heuristic است.
- countdown باید در هر full-state event از `20` ریست شود:
  - `CE_GAME_STARTED`
  - `CE_CARD_PLAYED`
  - `CE_CARD_DRAWN`
  - `CE_CARD_GIVEN`
  - `CE_SUIT_CHANGED`
  - `CE_PLAYER_LEFT`
- اگر timer محلی صفر شد و هنوز update جدید نرسیده بود، می‌توان `CE_TURN_TIMEOUT` فرستاد.

---

## 12. Derived UI Modes

### 12.1 Normal mode

شرایط:

- `isMyTurn`
- `waitingForSuitChoice=false`
- `waitingForGiveCard=false`
- `pendingDrawCount=0`

اکشن‌های قابل نمایش:

- play card
- draw card

### 12.2 Suit choice mode

شرایط:

- `isMyTurn`
- `waitingForSuitChoice=true`

اکشن‌های قابل نمایش:

- فقط ۴ دکمه انتخاب suit

### 12.3 Give-card mode

شرایط:

- `isMyTurn`
- `waitingForGiveCard=true`

اکشن‌های قابل نمایش:

- کلیک روی هر opponent برای `CE_GIVE_CARD`

### 12.4 Penalty mode

شرایط:

- `isMyTurn`
- `pendingDrawCount > 0`

اکشن‌های قابل نمایش:

- اگر 7 در hand دارد:
  - play 7
  - draw penalty
- اگر 7 ندارد:
  - فقط draw penalty

---

## 13. ولیدیشن‌های UI به تفکیک حالت

### 13.1 play card

- وقتی `waitingForSuitChoice` یا `waitingForGiveCard` فعال است، hand interactive نباشد.
- در penalty mode فقط کارت‌های `7` interactive باشند.
- card selection accidental submit نداشته باشد:
  - click اول select
  - click دوم confirm
  - یا دکمه play مستقل

### 13.2 draw

- وقتی `hasDrawnThisTurn=true` شد، draw button غیرفعال شود.
- در suit/give mode draw نباید نمایش داده شود.

### 13.3 choose suit

- فقط ۴ suit ثابت
- input آزاد متنی ممنوع

### 13.4 give card

- target self ممنوع
- فقط opponentها tappable باشند

### 13.5 finish

- بعد از `CE_GAME_FINISHED` هیچ action gameplay جدیدی نباید ارسال شود.

---

## 14. محاسباتی که فرانت نباید خودش authoritative انجام دهد

فرانت نباید این‌ها را مرجع نهایی حساب کند:

- playable بودن کارت برای ارسال نهایی
- تغییر نوبت
- جهت بازی
- pending draw نهایی
- reshuffle deck
- برنده بازی
- coin reward / xp reward

فرانت فقط برای UX و disable/enable می‌تواند derived state بسازد.

---

## 15. Gap Register

### GAP-01: `CE_GAME_STATE` وجود ندارد

- UI فعلی Flutter به آن گوش می‌دهد.
- runtime فعلی این event را emit نمی‌کند.
- فرانت وب باید روی full-state eventهای واقعی تکیه کند.

### GAP-02: `CE_SUIT_CHOSEN` وجود ندارد

- UI فعلی Flutter به آن گوش می‌دهد.
- backend فقط `CE_SUIT_CHANGED` می‌فرستد.

### GAP-03: `CE_*` actionها به `data.roomId` هم نیاز دارند

- envelope `roomId` به‌تنهایی کافی نیست.
- runtime handler فعلی `roomId` را از nested data هم می‌خواند.
- فرانت وب باید `data.roomId = roomId` را صریح بفرستد.

### GAP-04: `TURN_TIMER_STARTED` برای CE وجود ندارد

- برخلاف شلم، countdown authoritative event نداریم.
- countdown وب باید local heuristic باشد.

### GAP-05: backend hand همه بازیکنان را broadcast می‌کند

- این یک fairness bug است.
- فرانت وب فقط hand خودی را render کند.

### GAP-06: برخی invalid actionها silent ignore می‌شوند

- مثال:
  - out-of-turn play
  - draw در waiting mode
  - chooseSuit وقتی waitingForSuitChoice=false
- همیشه error event برنمی‌گردد.
- بنابراین pre-validation فرانت اهمیت بالایی دارد.

### GAP-07: UI فعلی ۸ را مثل انتخاب خال نمایش می‌دهد

- runtime فعلی برای `8` فقط extra turn دارد.
- `waitingForSuitChoice` فقط برای `J` فعال می‌شود.
- suit chooser نباید بعد از `8` باز شود.

### GAP-08: `CE_PLAY_ERROR` به همه broadcast می‌شود ولی actor ندارد

- اگر بدون فیلتر در UI نمایش داده شود، بازیکنان دیگر هم خطای شخصی اشتباه می‌بینند.
- فرانت وب باید آن را با pending action یا current-turn context scope کند.

---

## 16. ترتیب پیاده‌سازی پیشنهادی

1. state model و snapshot normalizer را بساز.
2. reducer مشترک برای full-state CE eventها بنویس.
3. masking دست حریف را enforce کن.
4. countdown محلی 20 ثانیه‌ای مبتنی بر full-state events بساز.
5. hand interaction و play validation را اضافه کن.
6. draw flow را با `hasDrawnThisTurn` کامل کن.
7. suit chooser برای `J` بساز.
8. give-card mode برای `2` بساز.
9. penalty UI برای `7` بساز.
10. finish modal و error handling را نهایی کن.

---

## 17. Definition Of Done

- bootstrap صفحه با `GET_GAME_STATE_BY_ROOM` کار می‌کند.
- full-state CE eventها state را درست replace می‌کنند.
- `CE_GAME_STATE` یا `CE_SUIT_CHOSEN` dependency وجود ندارد.
- play card فقط در حالت‌های مجاز ارسال می‌شود.
- draw فقط یک‌بار در هر turn عادی از UI مجاز است.
- `J` suit chooser درست کار می‌کند.
- `2` give-card mode درست کار می‌کند.
- penalty chain `7` در UI درست نمایش و کنترل می‌شود.
- countdown در هر update ریست می‌شود و timeout fallback دارد.
- finish modal winner/coins/xp را درست نشان می‌دهد.
- hand حریف‌ها هرگز لو نمی‌روند.

---

## 18. نمونه payloadهای آماده

### Play Card

```json
{
  "type": "GAME_ACTION",
  "action": "CE_PLAY_CARD",
  "roomId": 4101,
  "clientActionId": "ca_1762000000001",
  "data": {
    "roomId": 4101,
    "card": "7h",
    "stateVersion": 12
  }
}
```

### Draw Card

```json
{
  "type": "GAME_ACTION",
  "action": "CE_DRAW_CARD",
  "roomId": 4101,
  "clientActionId": "ca_1762000000002",
  "data": {
    "roomId": 4101,
    "stateVersion": 12
  }
}
```

### Choose Suit

```json
{
  "type": "GAME_ACTION",
  "action": "CE_CHOOSE_SUIT",
  "roomId": 4101,
  "clientActionId": "ca_1762000000003",
  "data": {
    "roomId": 4101,
    "suit": "spades",
    "stateVersion": 13
  }
}
```

### Give Card

```json
{
  "type": "GAME_ACTION",
  "action": "CE_GIVE_CARD",
  "roomId": 4101,
  "clientActionId": "ca_1762000000004",
  "data": {
    "roomId": 4101,
    "targetPlayerId": 88,
    "stateVersion": 14
  }
}
```

### Full-state Event Example

```json
{
  "type": "GAME_ACTION",
  "action": "CE_CARD_PLAYED",
  "roomId": 4101,
  "stateVersion": 15,
  "data": {
    "gameId": 9201,
    "roomId": 4101,
    "currentPlayerId": 88,
    "direction": 1,
    "pendingDrawCount": 2,
    "waitingForSuitChoice": false,
    "waitingForGiveCard": false,
    "lastPlayedSpecial": "7",
    "hasDrawnThisTurn": false,
    "currentSuit": "hearts",
    "currentRank": "7",
    "topCard": "7♥",
    "topCardSuit": "hearts",
    "topCardRank": "7",
    "deckRemaining": 21,
    "players": [
      {
        "playerId": 77,
        "username": "ali",
        "seatNumber": 0,
        "cardsCount": 4,
        "isCurrentTurn": false,
        "handCards": []
      },
      {
        "playerId": 88,
        "username": "mina",
        "seatNumber": 1,
        "cardsCount": 6,
        "isCurrentTurn": true,
        "handCards": []
      }
    ]
  }
}
```

### Game Finished

```json
{
  "type": "GAME_ACTION",
  "action": "CE_GAME_FINISHED",
  "roomId": 4101,
  "stateVersion": 22,
  "data": {
    "gameId": 9201,
    "roomId": 4101,
    "winnerId": 77,
    "winnerCoins": 180,
    "coinRewards": {
      "winner": 180
    },
    "xpRewards": {
      "winner": 50,
      "loser": 10
    },
    "players": [
      {
        "playerId": 77,
        "username": "ali",
        "cardsRemaining": 0,
        "isWinner": true
      },
      {
        "playerId": 88,
        "username": "mina",
        "cardsRemaining": 3,
        "isWinner": false
      }
    ]
  }
}
```
