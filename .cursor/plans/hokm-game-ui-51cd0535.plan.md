<!-- 51cd0535-4bd6-43f9-846a-a8c9feb6974d 1292faf5-c059-41ca-aec5-eb1730d30dbf -->
# بهبود UI و منطق بازی حکم

## مرحله 1: بهبود UI و Layout

### 1.1 طراحی مجدد HokmGameUI

**فایل**: `gameapp/lib/features/game/ui/game_ui/hokm_game_ui.dart`

**تغییرات UI**:

- حذف AppBar و جایگزینی با Custom Header شامل:
- نتیجه کل بازی (تیم 1 vs تیم 2)
- نتیجه راند فعلی
- نمایش حکم (خال)
- دکمه خروج از اتاق
- تغییر نمایش بازیکنان:
- استفاده از `username` به جای `email`
- کوچک‌تر کردن باکس‌های بازیکن
- کاهش CircleAvatar radius از 24 به 16
- کاهش padding و spacing
- حذف کادر وسط صفحه (که برای نتیجه بود)
- اضافه کردن ناحیه وسط برای نمایش کارت‌های بازی شده (4 کارت در مربع)
- نمایش کارت‌های خود بازیکن با Fan/Carousel Layout:
- استفاده از Stack و Positioned
- کارت‌ها روی هم با overlap
- هر کارت کمی چرخیده (rotation) مثل دست کارت واقعی
- قابلیت کلیک برای انتخاب کارت

### 1.2 اضافه کردن تایمر بازیکن

**فایل**: `gameapp/lib/features/game/ui/game_ui/hokm_game_ui.dart`

- اضافه کردن `CircularProgressIndicator` دور آواتار بازیکن فعلی
- نمایش countdown با تغییر رنگ (سبز → نارنجی → قرمز)
- مدیریت تایمر با Timer.periodic
- ارسال پیام timeout به backend اگر زمان تمام شد

## مرحله 2: پیاده‌سازی منطق بازی کارت (Frontend)

### 2.1 مدیریت انتخاب و بازی کارت

**فایل**: `gameapp/lib/features/game/ui/game_ui/hokm_game_ui.dart`

- اضافه کردن متد `_onCardTap(Card card)`:
- چک کردن اینکه آیا نوبت بازیکن است
- ارسال پیام `PLAY_CARD` به backend
- انیمیشن حرکت کارت از دست به میز
- اضافه کردن state برای کارت‌های بازی شده فعلی
- مدیریت disabled state برای کارت‌ها (فقط در نوبت خودش فعال)

### 2.2 آپدیت HokmGameState Model

**فایل**: `gameapp/lib/features/game/data/models/hokm_game_state.dart`

- اضافه کردن فیلدهای:
- `teamAScore`, `teamBScore` (امتیاز تیم‌ها)
- `currentRoundWins` (برد‌های راند فعلی)
- `leadSuit` (خال شروع‌کننده دست)
- `remainingTime` (زمان باقی‌مانده)

## مرحله 3: پیاده‌سازی منطق بازی (Backend)

### 3.1 تکمیل playCard Method

**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameEngineService.java`

متد `playCard` موجود است اما نیاز به تکمیل دارد:

- اضافه کردن validation برای رعایت خال (lead suit)
- broadcast کردن GAME_STATE_UPDATED بعد از هر card play
- مدیریت صحیح playedCards و leadSuit

### 3.2 تایمر برای بازی خودکار

**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameEngineService.java`

- اضافه کردن متد `scheduleAutoCardPlay(gameStateId, playerId)`:
- تایمر 30 ثانیه برای هر نوبت
- اگر تایمر تمام شد، یک کارت valid رندوم انتخاب کن
- رعایت قوانین (lead suit, trump)
- مدیریت cancel کردن تایمر وقتی بازیکن کارت بازی کرد

### 3.3 تکمیل determineHandWinner

**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameEngineService.java`

متد موجود است اما نیاز به بهبود:

- اضافه کردن logging دقیق
- broadcast نتیجه دست به همه
- مدیریت شروع دست بعدی
- چک کردن پایان راند (7 امتیاز)

### 3.4 مدیریت پایان راند و شروع راند جدید

**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameEngineService.java`

- اضافه کردن متد `startNewRound(gameStateId)`:
- ریست کردن امتیازات راند
- تغییر حاکم به بازیکن بعدی
- پخش کارت‌های جدید
- broadcast وضعیت جدید
- آپدیت نتیجه کل بازی

### 3.5 مدیریت WebSocket برای PLAY_CARD

**فایل**: `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`

- اضافه کردن case "PLAY_CARD" در handleGameAction:
- دریافت card, gameStateId, playerId
- فراخوانی `gameEngineService.playCard()`
- ارسال success/error response

## مرحله 4: ویجت‌های سفارشی

### 4.1 ساخت CardFanWidget

**فایل جدید**: `gameapp/lib/features/game/ui/widgets/card_fan_widget.dart`

- ویجت برای نمایش کارت‌ها به صورت fan
- استفاده از Stack و Transform.rotate
- کارت‌ها با overlap و rotation
- قابلیت کلیک برای هر کارت
- highlight کردن کارت انتخاب شده

### 4.2 ساخت PlayingTableWidget

**فایل جدید**: `gameapp/lib/features/game/ui/widgets/playing_table_widget.dart`

- نمایش 4 کارت بازی شده در مربع (بالا، پایین، چپ، راست)
- انیمیشن ظاهر شدن کارت‌ها
- highlight کردن کارت برنده

### 4.3 ساخت GameHeaderWidget

**فایل جدید**: `gameapp/lib/features/game/ui/widgets/game_header_widget.dart`

- Card با elevation
- نمایش تیم 1 - حکم - تیم 2
- نمایش نتیجه راند فعلی
- دکمه خروج

### 4.4 ساخت PlayerTimerWidget

**فایل جدید**: `gameapp/lib/features/game/ui/widgets/player_timer_widget.dart`

- CircularProgressIndicator دور آواتار
- تغییر رنگ بر اساس زمان باقی‌مانده
- نمایش عدد countdown

## مرحله 5: منطق Game Flow

### 5.1 WebSocket Message Handlers (Frontend)

**فایل**: `gameapp/lib/features/game/ui/game_ui/hokm_game_ui.dart`

- Handle کردن `CARD_PLAYED`: آپدیت playedCards
- Handle کردن `HAND_WON`: نمایش برنده + آپدیت scores
- Handle کردن `ROUND_ENDED`: نمایش نتیجه راند
- Handle کردن `TURN_CHANGED`: آپدیت currentTurnPlayerId + شروع تایمر

### 5.2 Validation منطق بازی (Backend)

**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameEngineService.java`

- متد `validateCardPlay(card, leadSuit, trumpSuit, playerHand)`:
- اگر lead suit در دست هست، باید همان را بازی کند
- اگر lead suit نداشت، هر کارتی می‌تواند بازی کند
- متد `getValidCards(playerHand, leadSuit)`:
- لیست کارت‌های قابل بازی
- برای auto-play استفاده می‌شود

## TODO Items

- **hokm_ui_redesign**: طراحی مجدد layout صفحه حکم با header, table, fan cards
- **hokm_card_fan**: پیاده‌سازی CardFanWidget برای نمایش کارت‌ها
- **hokm_playing_table**: پیاده‌سازی PlayingTableWidget برای نمایش کارت‌های بازی شده
- **hokm_game_header**: پیاده‌سازی GameHeaderWidget برای نمایش امتیازات و حکم
- **hokm_player_timer**: پیاده‌سازی PlayerTimerWidget برای نمایش تایمر
- **hokm_card_play_frontend**: پیاده‌سازی منطق کلیک و بازی کارت در frontend
- **hokm_backend_play_card**: تکمیل متد playCard در backend با validation
- **hokm_backend_timer**: پیاده‌سازی تایمر 30 ثانیه و auto-play
- **hokm_backend_hand_winner**: تکمیل determineHandWinner و broadcast نتیجه
- **hokm_backend_round_management**: پیاده‌سازی مدیریت پایان راند و شروع راند جدید
- **hokm_websocket_handlers**: اضافه کردن handler برای PLAY_CARD در ImprovedWebSocketConfig
- **hokm_test_complete_flow**: تست کامل جریان بازی از شروع تا پایان

### To-dos

- [ ] طراحی مجدد layout صفحه حکم با header, table, fan cards
- [ ] پیاده‌سازی CardFanWidget برای نمایش کارت‌ها
- [ ] پیاده‌سازی PlayingTableWidget برای نمایش کارت‌های بازی شده
- [ ] پیاده‌سازی GameHeaderWidget برای نمایش امتیازات و حکم
- [ ] پیاده‌سازی PlayerTimerWidget برای نمایش تایمر
- [ ] پیاده‌سازی منطق کلیک و بازی کارت در frontend
- [ ] تکمیل متد playCard در backend با validation
- [ ] پیاده‌سازی تایمر 30 ثانیه و auto-play
- [ ] تکمیل determineHandWinner و broadcast نتیجه
- [ ] پیاده‌سازی مدیریت پایان راند و شروع راند جدید
- [ ] اضافه کردن handler برای PLAY_CARD در ImprovedWebSocketConfig
- [ ] تست کامل جریان بازی از شروع تا پایان