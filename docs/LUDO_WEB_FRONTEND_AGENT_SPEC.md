# مستند اجرایی منچ برای ایجنت فرانت وب

- نسخه: `1.0`
- تاریخ: `2026-04-09`
- وضعیت: `Frontend Agent Ready`
- دامنه: `Lobby + Room + Gameplay + Resync contract برای LUDO`

---

## 1. هدف

این سند باید برای ایجنت فرانت کافی باشد تا gameplay وب منچ را بدون رجوع به Flutter فعلی پیاده کند؛ شامل:

- state model لازم برای UI
- actionهای قابل ارسال
- eventهای realtime
- boot / reconnect / resync flow
- rule mapping لازم برای highlight و CTA
- قرارداد UI برای modeهای `FFA` و `TEAM`

---

## 2. Source Of Truth

مرجع قطعی runtime backend است.

### فایل‌های مرجع

- `gameBackend/src/main/java/com/gameapp/game/services/LudoEngineService.java`
- `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java`
- `gameBackend/src/main/java/com/gameapp/game/services/GameTimerSettingsService.java`
- `gameBackend/src/main/java/com/gameapp/game/models/Enums.java`
- `gameBackend/src/main/resources/db/v3/V63__ludo_runtime_support.sql`
- `gameapp/lib/features/game/data/models/ludo_game_state.dart`
- `gameapp/lib/features/game/ui/game_ui/ludo_game_ui.dart`
- `docs/LUDO_RULES_SPEC.md`

### اصل مهم

- اگر بین کلاینت و backend اختلاف بود، backend معتبر است.
- اگر `STATE_SNAPSHOT` خام با `LUDO_*` full-state eventها اختلاف شکل داشت، reducer باید `LUDO_*` eventها را state نهایی بداند.
- `turnOwnerUserId` و `controllerBySeat` مرجع واقعی turn authority هستند، نه صرفاً seat active.

---

## 3. Dependency Summary

- کاربر باید authenticate شده باشد.
- WS v3 باید وصل و `AUTH` شده باشد.
- صفحه gameplay با `roomId` mount می‌شود.
- room معمولاً بعد از `IN_PROGRESS` mount می‌شود، ولی باید bootstrap snapshot را هم تحمل کند.

---

## 4. Gameplay Contract Summary

- gameType: `LUDO`
- roomMode یکی از این‌هاست:
  - `FFA_2`
  - `FFA_3`
  - `FFA_4`
  - `FFA_5`
  - `FFA_6`
  - `TEAM_2V2`
  - `TEAM_3V3`
- boardVariant:
  - `CLASSIC_4`
  - `CLASSIC_6`
- phase:
  - `ROLLING_DICE`
  - `MOVING_TOKEN`
  - `ROUND_FINISHED`
  - `FINISHED`

### مهم برای UI

- اگر phase=`ROLLING_DICE` و `turnOwnerUserId == myUserId`:
  - CTA اصلی: `تاس بریز`
- اگر phase=`MOVING_TOKEN` و `turnOwnerUserId == myUserId`:
  - فقط tokenهای موجود در `legalMoves[]` clickable هستند
- اگر `turnOwnerUserId != myUserId`:
  - UI باید spectator-turn mode نشان دهد
- اگر playerی `controllerUserId != userId` داشته باشد:
  - takeover banner / indicator لازم است

---

## 5. WS Actions

### 5.1 `LUDO_ROLL_DICE`

```json
{
  "type": "GAME_ACTION",
  "action": "LUDO_ROLL_DICE",
  "roomId": 321,
  "clientActionId": "uuid",
  "data": {
    "roomId": 321
  }
}
```

### 5.2 `LUDO_MOVE_TOKEN`

```json
{
  "type": "GAME_ACTION",
  "action": "LUDO_MOVE_TOKEN",
  "roomId": 321,
  "clientActionId": "uuid",
  "data": {
    "roomId": 321,
    "tokenId": "seat-2-token-1"
  }
}
```

### Client Rules

- فقط وقتی CTA واقعاً legal است action بفرست.
- روی optimistic local move حساب نکن؛ state نهایی از event برمی‌گردد.
- duplicate tap باید client-side throttle شود، ولی reducer باید idempotent بماند.

---

## 6. Runtime Events

- `LUDO_GAME_STARTED`
- `LUDO_STATE_UPDATED`
- `LUDO_ROUND_FINISHED`
- `LUDO_GAME_FINISHED`
- `LUDO_ERROR`
- `TURN_TIMER_STARTED`
- `PLAYER_CONTROL_CHANGED`

### نکته

- `LUDO_ROUND_FINISHED` و `LUDO_GAME_FINISHED` full-state payload می‌فرستند؛ آن‌ها را patch جزئی فرض نکن.
- `TURN_TIMER_STARTED` فقط countdown metadata است؛ state board را از این event نساز.

---

## 7. State Shape

فیلدهای لازم برای فرانت:

- `roomId`
- `gameStateId`
- `boardVariant`
- `mode`
- `phase`
- `roundNumber`
- `targetRounds`
- `activeSeat`
- `turnOwnerUserId`
- `currentRoll`
- `queuedBonusRolls`
- `consecutiveSixCount`
- `safeCellIds[]`
- `boardSlotBySeat{}`
- `controllerBySeat{}`
- `roundWinsByUserId{}`
- `teamRoundWins{}`
- `lastTransition{}`
- `winner{}`
- `players[]`
- `tokens[]`
- `legalMoves[]`
- `participantResults`

### players[]

- `userId`
- `username`
- `seatNumber`
- `teamId`
- `boardSlot`
- `colorKey`
- `controllerUserId`
- `controllerUsername`
- `isSeatController`
- `controlMode`
- `isConnected`
- `forfeitLocked`
- `status`
- `isBot`
- `score`
- `finishedTokenCount`
- `tokensInYard`
- `allTokensHome`
- `roundWins`

### tokens[]

- `tokenId`
- `userId`
- `seatNumber`
- `teamId`
- `boardSlot`
- `colorKey`
- `progress`
- `cellId`
- `trackIndex`
- `homeIndex`
- `isInYard`
- `isFinished`

### legalMoves[]

- `tokenId`
- `seatNumber`
- `userId`
- `teamId`
- `dieValue`
- `fromProgress`
- `targetProgress`
- `fromCellId`
- `toCellId`
- `spawn`
- `captureTokenId`
- `captureUserId`
- `reachesHome`
- `finishToken`
- `safeDestination`

---

## 8. Resync Flow

### initial mount

1. route با `roomId` باز می‌شود.
2. فرانت `GET_GAME_STATE_BY_ROOM` می‌زند.
3. اگر `STATE_SNAPSHOT` خام برگشت:
   - آن را normalize کن
   - ولی full-state eventهای بعدی را authoritative بدان
4. اگر هم‌زمان `LUDO_STATE_UPDATED` رسید:
   - stateVersion جدیدتر باید state فعلی را replace کند

### reconnect

- reconnect باید دوباره `GET_GAME_STATE_BY_ROOM` بزند.
- token positionها از snapshot تازه rebuild شوند.
- turn timer را از `TURN_TIMER_STARTED` تازه sync کن.

---

## 9. UI Rules

- برد باید center-stage باشد؛ HUD نباید playfield را خفه کند.
- مهره‌های legal move باید clear highlight داشته باشند.
- safe cellها glow مشخص داشته باشند.
- board باید mode `4-seat` و `6-seat` را از data بگیرد، نه hardcode route.
- در team mode:
  - team score strip لازم است
  - takeover indicator لازم است
- reduced-motion toggle باید non-essential animationها را کوتاه یا خاموش کند.
- mute و haptic toggle محلی قابل قبول است.

---

## 10. Acceptance Checklist

- `FFA_2`, `FFA_4`, `FFA_6`, `TEAM_2V2`, `TEAM_3V3` mount می‌شوند.
- `ROLLING_DICE` CTA فقط برای turn owner فعال است.
- `MOVING_TOKEN` فقط روی legal tokenها tap می‌خورد.
- capture, finish-token, three-sixes-bust و no-legal-move از `lastTransition` در UI بازتاب پیدا می‌کنند.
- takeover در player rail دیده می‌شود.
- `LUDO_GAME_FINISHED` overlay نهایی را باز می‌کند.
- reconnect وسط بازی state صحیح را برمی‌گرداند.
