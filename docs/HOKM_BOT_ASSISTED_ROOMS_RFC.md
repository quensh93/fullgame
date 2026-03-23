# RFC: بات حکم برای تست داخلی و Beta Liquidity

- نسخه: `1.0`
- تاریخ: `2026-03-08`
- وضعیت: `Draft - Ready for Implementation`
- دامنه: `Hokm only`
- اولویت: `High`
- مالک فنی: `Backend + WS + Admin`

---

## 1) خلاصه اجرایی

این سند مشخص می‌کند چگونه برای بازی `HOKM` دو قابلیت زیر را پیاده‌سازی کنیم:

1. `Internal Test Mode`
   - یک انسان بتواند با `1 تا 3` بات وارد بازی شود.
   - هدف: حذف نیاز به باز کردن چند مرورگر برای تست end-to-end.

2. `Beta Bot-Assisted Public Tables`
   - اگر روم حکم عمومی با `3 انسان` برای مدت مشخص منتظر ماند، سیستم `1 بات` به صندلی چهارم اضافه کند تا بازی شروع شود.
   - هدف: کاهش زمان انتظار در soft launch و بازار کم‌تراکم.

تصمیم کلیدی این RFC:

- برای `v1` فقط `HOKM` پشتیبانی می‌شود.
- برای `v1` بات‌ها به‌صورت `server-side` پیاده‌سازی می‌شوند، نه با مرورگر/کلاینت fake.
- برای `v1` منطق تصمیم بات فقط برای حکم ساخته می‌شود؛ orchestration مشترک می‌ماند.
- در `internal test`، disclosure لازم نیست.
- در `beta public`, روم باید `bot-assisted` علامت‌گذاری شود و از مسیرهای رقابتی، leaderboard و گزارش‌های عمومی جدا بماند.
- منطق تزریق بات `room-state driven` است، نه `online-percentage driven`. درصد فقط به‌عنوان `safety cap` استفاده می‌شود.

---

## 2) مسئله کسب‌وکار

### 2.1 مسئله

- حکم بازی 4 نفره است و در شروع کار احتمالاً نقدشوندگی پایین خواهد بود.
- منتظر ماندن برای نفر چهارم باعث ریزش کاربر و بی‌استفاده شدن روم‌ها می‌شود.
- برای تست واقعی gameplay نیز در وضعیت فعلی باید چند کلاینت هم‌زمان باز شود.

### 2.2 هدف‌های اصلی

- کاهش `time-to-play` برای حکم.
- ایجاد امکان `single-human realistic test`.
- کنترل کامل ریسک مالی House در میزهای bot-assisted.
- فراهم کردن kill switch و audit کافی برای خاموش‌سازی سریع.

### 2.3 هدف‌های غیرمستقیم

- ایجاد یک لایه reusable برای آینده، بدون overengineering برای همه بازی‌ها.
- حفظ سازگاری با ساختار فعلی backend که per-game engine دارد.

---

## 3) وضعیت فعلی کد و مبنای طراحی

این RFC روی ساختار فعلی پروژه سوار می‌شود:

- حداکثر بازیکن حکم در [GameRoomService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java:430) برابر `4` است.
- شروع بازی وقتی روم پر شود در [GameRoomService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java:280) و [GameRoomService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java:940) انجام می‌شود.
- کسر entry fee برای همه بازیکنان در [GameRoomService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java:961) انجام می‌شود.
- engine اختصاصی حکم در [HokmEngineService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/HokmEngineService.java:19) وجود دارد.
- scheduler مرکزی برای تایمرها در [RoomTimerService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/RoomTimerService.java:1) وجود دارد.
- تنظیمات عمومی از طریق `app_settings` و [AdminAppSettingsController.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/controllers/AdminAppSettingsController.java:1) قابل مدیریت هستند.

نتیجه:

- `bot orchestration` باید متمرکز باشد.
- `decision engine` باید در لایه Hokm جدا باشد.
- اقتصاد و settlement نیاز به انشعاب کنترل‌شده از flow فعلی دارد، چون در flow فعلی از همه seatها entry fee کم می‌شود.

---

## 4) Scope دقیق

## 4.1 In Scope

- بات server-side برای `HOKM`
- پر کردن seat خالی در `internal test`
- پر کردن seat چهارم در `beta public`
- سطح سختی بات در `4` سطح
- admin settings برای روشن/خاموش کردن و تنظیم policy
- house ledger و exposure limits
- audit log برای join, action, settlement
- برچسب‌گذاری room/result به‌عنوان `bot-assisted`

## 4.2 Out of Scope برای v1

- بات برای سایر بازی‌ها
- بات universal برای همه game types
- hot-swap بات در میانه بازی پس از disconnect انسان
- 2 human + 2 bot در public money tables
- bot-vs-bot public rooms
- ML/LLM-based bot
- deception-heavy persona/chat system
- حذف کامل disclosure از میزهای عمومی

---

## 5) اصول طراحی

1. `Server authoritative`
   - بات‌ها باید داخل backend تصمیم بگیرند. نباید برای هر بات session مرورگر یا websocket client جدا بالا بیاید.

2. `Per-game intelligence`
   - orchestration مشترک است، اما منطق حکم اختصاصی می‌ماند.

3. `No hidden information advantage`
   - بات فقط به اطلاعاتی دسترسی دارد که بازیکن انسانی همان seat دارد.

4. `Policy before percentage`
   - تصمیم اصلی بر اساس وضعیت روم است، نه درصد آنلاین‌ها.

5. `Hard financial controls`
   - اگر house بخواهد زیان بات را پوشش دهد، باید ledger و stop-loss جدا داشته باشد.

6. `Easy rollback`
   - با یک feature flag باید کل سیستم bot-assisted خاموش شود.

---

## 6) Operating Modes

### 6.1 Mode A: Internal Test

مخاطب: ادمین، QA، developer

رفتار:

- کاربر انسانی یک روم تست حکم می‌سازد.
- سیستم بر اساس درخواست، `1 تا 3` بات را قبل از شروع بازی به روم اضافه می‌کند.
- روم در lobby عمومی نمایش داده نمی‌شود.
- پیش‌فرض v1: اقتصاد و leaderboard برای این مود غیرفعال است.
- قابلیت debug و replay باید فعال باشد.

هدف:

- تست سریع gameplay
- تست timeout
- تست state sync
- تست outcome و settlement در محیط کنترل‌شده

### 6.2 Mode B: Beta Bot-Assisted Public

مخاطب: soft launch / liquidity bootstrap

رفتار:

- فقط برای `PUBLIC HOKM`
- فقط وقتی `3 انسان` در روم باشند
- فقط پس از گذشت `wait threshold`
- فقط `1 بات` مجاز است
- روم باید `bot-assisted` مارک شود
- میز باید در leaderboard و آمار competitive با برچسب جدا یا exclusion پردازش شود
- house exposure باید محدود و قابل قطع باشد

### 6.3 Mode C: Normal Public

رفتار:

- بدون بات
- مسیر نهایی هدف محصول

---

## 7) تصمیم محصول برای v1

### 7.1 تصمیم اصلی

برای `v1` این policy اعمال می‌شود:

- `internal test`:
  - `1 human + up to 3 bots`
- `public beta liquidity`:
  - فقط `3 humans + 1 bot`
- `private rooms`:
  - فقط در صورت internal test یا override ادمین
- `ranked / tournament / official leaderboard-sensitive tables`:
  - `0 bots`

### 7.2 دلیل این تصمیم

- 3 human + 1 bot برای حکم کم‌ریسک‌ترین حالت public است.
- 2 human + 2 bot در money table از نظر perception و trust ضعیف‌تر است.
- internal test مهم‌ترین immediate win برای تیم توسعه است.

---

## 8) الزامات عملکردی

## 8.1 FR-01: ایجاد روم تست حکم با بات

سیستم باید اجازه دهد ادمین/تستر یک روم حکم تستی بسازد با این ورودی‌ها:

- `fillBotSeats`: عدد بین `0..3`
- `difficulty`: `NOVICE | STANDARD | SKILLED | EXPERT`
- `decisionDelayProfile`: `fast | normal | realistic`
- `seed` اختیاری
- `disableEconomy` پیش‌فرض `true`
- `debugEnabled` پیش‌فرض `true`

## 8.2 FR-02: پر کردن خودکار seat چهارم در public beta

اگر همه شرایط زیر برقرار بود، سیستم باید `1` بات وارد کند:

- room.gameType = `HOKM`
- room.roomType = `PUBLIC`
- room.roomStatus = `PENDING`
- تعداد انسان‌ها = `3`
- تعداد بات‌ها = `0`
- زمان انتظار >= `hokm.bot.public.fill-after-seconds`
- feature flag فعال باشد
- house loss limit فعال نشده باشد
- سقف هم‌زمان bot-assisted rooms پر نشده باشد

## 8.3 FR-03: قابلیت خاموش‌سازی کامل

ادمین باید بتواند به‌صورت فوری:

- internal test را خاموش کند
- beta public را خاموش کند
- join جدید بات را متوقف کند
- تصمیم‌گیری بات را متوقف نکند اگر بازی شروع شده و توقف باعث خراب شدن state می‌شود

## 8.4 FR-04: سطوح سختی

برای حکم 4 سطح تعریف می‌شود:

- `NOVICE`
- `STANDARD`
- `SKILLED`
- `EXPERT`

## 8.5 FR-05: رفتار human-like

بات باید:

- delay تصمیم تصادفی در بازه مجاز داشته باشد
- اشتباه قابل‌کنترل داشته باشد
- legal move validation را رعایت کند
- perfect-information نداشته باشد

## 8.6 FR-06: برچسب‌گذاری bot-assisted

برای هر room و result باید قابل تشخیص باشد که:

- bot-assisted بوده یا نه
- mode چه بوده
- چند بات شرکت کرده‌اند

## 8.7 FR-07: House exposure controls

سیستم باید قبل از تزریق بات بررسی کند:

- daily bot loss cap
- per-room subsidy cap
- max concurrent bot-assisted rooms
- optional max online bot share

## 8.8 FR-08: Auditability

برای هر بازی bot-assisted باید log شود:

- چه باتی join شد
- با چه policy و settingهایی
- هر move بات
- نتیجه نهایی
- subsidy/house payout

---

## 9) الزامات غیرعملکردی

## 9.1 Performance

- تصمیم بات نباید thread-blocking سنگین داشته باشد.
- هر تصمیم باید در `O(number of legal moves)` یا نزدیک به آن باشد.
- زمان محاسبه هدف برای `STANDARD` و `SKILLED` کمتر از `100ms` باشد.

## 9.2 Reliability

- action بات باید idempotent و state-version aware باشد.
- اگر state تغییر کرده باشد، task قدیمی باید no-op شود.

## 9.3 Security

- endpointهای internal test فقط برای admin/tester
- bot settings فقط از admin panel
- room debug data فقط برای internal test

## 9.4 Observability

- metrics
- structured logs
- replayable hand history

---

## 10) معماری پیشنهادی

### 10.1 لایه‌ها

1. `BotPolicyService`
   - تصمیم می‌گیرد آیا باید بات اضافه شود یا نه.

2. `BotSeatFillService`
   - seat مناسب را انتخاب می‌کند و bot user را به روم اضافه می‌کند.

3. `BotSchedulerService`
   - با استفاده از `RoomTimerService` زمان‌بندی join و action را انجام می‌دهد.

4. `BotActionCoordinator`
   - وقتی نوبت بات می‌شود، strategy مناسب را فراخوانی می‌کند.

5. `HokmBotStrategy`
   - منطق تصمیم اختصاصی حکم.

6. `BotSettlementService`
   - settlement و subsidy را برای bot-assisted rooms مدیریت می‌کند.

7. `BotAuditService`
   - log عملیاتی و مالی را ثبت می‌کند.

### 10.2 تصمیم معماری

- orchestration مشترک
- strategy اختصاصی برای حکم
- بدون websocket client مصنوعی
- بدون headless browser

### 10.3 دلیل

- سریع‌تر
- قابل‌کنترل‌تر
- ارزان‌تر
- بدون نیاز به چند session fake

---

## 11) تغییرات پیشنهادی در مدل داده

## 11.1 جدول `users`

افزودن فیلدهای زیر:

- `is_bot boolean not null default false`
- `bot_code varchar(64) null unique`

هدف:

- `PlayerState` و `GameResult` و queryهای فعلی همچنان با `User` کار کنند.
- تشخیص bot در queryهای reports/leaderboard ساده شود.

## 11.2 جدول جدید `bot_profiles`

فیلدهای پیشنهادی:

- `id`
- `user_id` unique fk -> users.id
- `game_type`
- `enabled`
- `skill_level`
- `persona_key`
- `min_delay_ms`
- `max_delay_ms`
- `mistake_rate`
- `risk_style`
- `config_json`
- `created_at`
- `updated_at`

توضیح:

- برای v1 فقط `game_type = HOKM`
- هر bot user یک profile فعال دارد

## 11.3 جدول `game_room`

افزودن فیلدهای زیر:

- `bot_assisted boolean not null default false`
- `bot_mode varchar(32) null`
  - `INTERNAL_TEST`
  - `BETA_PUBLIC`
- `bot_count int not null default 0`
- `bot_config_json text null`

## 11.4 جدول `game_results`

افزودن فیلدهای زیر:

- `bot_assisted boolean not null default false`
- `bot_mode varchar(32) null`
- `excluded_from_leaderboard boolean not null default false`
- `house_subsidy_amount bigint not null default 0`

## 11.5 جدول جدید `bot_house_ledger`

فیلدهای پیشنهادی:

- `id`
- `room_id`
- `game_result_id`
- `bot_user_id`
- `entry_fee_virtual_amount`
- `subsidy_paid_amount`
- `net_house_pnl`
- `reason`
- `created_at`

هدف:

- ثبت شفاف زیان/سود House بابت seat بات

## 11.6 جدول جدید `bot_action_audit`

فیلدهای پیشنهادی:

- `id`
- `room_id`
- `game_state_id`
- `bot_user_id`
- `state_version`
- `action_type`
- `action_payload_json`
- `decision_context_json`
- `decision_ms`
- `created_at`

---

## 12) چرا `User` واقعی برای بات لازم است

در ساختار فعلی:

- `PlayerState.user` اجباری است.
- `GameResult` و چندین query روی `winner_id` و `participants_scores_json` کار می‌کنند.
- flowهای حضور در روم، scoring و outcome با `User` طراحی شده‌اند.

بنابراین برای v1 منطقی‌ترین راه:

- بات‌ها به‌عنوان `user rows` سیستمی ساخته شوند.
- با `is_bot = true` از کاربران واقعی جدا شوند.
- queryهای public و leaderboard بات‌ها را exclude کنند.

این راه نسبت به ساختن participant model جدید، بسیار کم‌ریسک‌تر است.

---

## 13) Admin Settings

برای v1، تنظیمات از طریق `app_settings` مدیریت می‌شوند.

### 13.1 کلیدهای پیشنهادی

- `hokm.bot.internal.enabled = true|false`
- `hokm.bot.public.enabled = true|false`
- `hokm.bot.public.fill-after-seconds = 25`
- `hokm.bot.public.min-human-count = 3`
- `hokm.bot.public.max-bots-per-room = 1`
- `hokm.bot.public.max-concurrent-rooms = 20`
- `hokm.bot.global.max-online-share-percent = 20`
- `hokm.bot.house.daily-loss-limit = 50000`
- `hokm.bot.house.per-room-subsidy-limit = 4000`
- `hokm.bot.house.per-user-net-loss-limit = 10000`
- `hokm.bot.default-difficulty = STANDARD`
- `hokm.bot.public.disclosure-required = true`
- `hokm.bot.test.default-disable-economy = true`
- `hokm.bot.audit.enabled = true`

### 13.2 نکته

`max-online-share-percent` فقط safety cap است. decision engine نباید صرفاً با این درصد تصمیم بگیرد.

---

## 14) API و Contract پیشنهادی

## 14.1 Admin REST: ایجاد روم تست حکم

`POST /api/admin/hokm/test-rooms`

نمونه request:

```json
{
  "entryFee": "FIFTY",
  "gameScore": "HOKM_THREE",
  "fillBotSeats": 3,
  "difficulty": "STANDARD",
  "decisionDelayProfile": "realistic",
  "disableEconomy": true,
  "debugEnabled": true,
  "seed": 123456
}
```

نمونه response:

```json
{
  "roomId": 981,
  "botMode": "INTERNAL_TEST",
  "humanCount": 1,
  "botCount": 3,
  "status": "PENDING"
}
```

## 14.2 Admin REST: تنظیمات بات

ترجیح v1:

- reuse `PUT /api/admin/settings`
- reuse `PUT /api/admin/settings/batch`

## 14.3 WebSocket / Room payload changes

در DTO روم و player summary این فیلدها اضافه شوند:

- `isBot`
- `botDifficulty` اختیاری
- `botMode`
- `botAssisted`

## 14.4 WebSocket / Game state payload changes

در player payloadهای حکم:

- `isBot`
- `botDifficulty`

در room/game meta:

- `botAssisted`
- `botMode`

## 14.5 Debug-only WS events برای internal test

فقط در `INTERNAL_TEST`:

- `BOT_DECISION_DEBUG`
- `BOT_POLICY_APPLIED`

نمونه:

```json
{
  "type": "BOT_DECISION_DEBUG",
  "roomId": 981,
  "gameStateId": 1220,
  "botUserId": 40012,
  "stateVersion": 48,
  "action": "PLAY_CARD",
  "card": "As",
  "decisionMs": 23,
  "legalMoves": ["As", "10s", "3s"],
  "reason": "follow_suit_high_value"
}
```

---

## 15) Flowهای اصلی

## 15.1 Flow A: Internal Test Room

1. ادمین درخواست ساخت روم تست حکم می‌دهد.
2. backend روم را با `bot_mode=INTERNAL_TEST` ایجاد می‌کند.
3. creator join می‌شود.
4. `fillBotSeats` عدد بات به روم اضافه می‌شود.
5. وقتی player count به 4 رسید، flow فعلی start game اجرا می‌شود با این تفاوت که settlement policy مخصوص internal test اعمال می‌شود.

## 15.2 Flow B: Public Beta Fill

1. انسان سوم وارد روم حکم عمومی می‌شود.
2. `BotPolicyService` شرایط را ارزیابی می‌کند.
3. اگر روم واجد شرایط بود، timer با کلید `bot:fill:hokm:<roomId>` ثبت می‌شود.
4. بعد از timeout، روم با lock دوباره لود می‌شود.
5. اگر هنوز `3 human + 0 bot + pending` برقرار بود، بات seat چهارم join می‌شود.
6. `broadcastRoomUpdated` ارسال می‌شود.
7. چون روم full شده، flow فعلی `startGame(roomId)` اجرا می‌شود.

## 15.3 Flow C: Bot Action

1. هر بار state تغییر می‌کند یا turn عوض می‌شود، `BotActionCoordinator` بررسی می‌کند آیا `currentPlayerId` یک bot است یا نه.
2. اگر bot است، task با کلید
   - `bot:turn:<gameStateId>:<stateVersion>:<playerId>`
   زمان‌بندی می‌شود.
3. هنگام اجرا:
   - game state مجدد خوانده می‌شود.
   - اگر `stateVersion` عوض شده، task لغو می‌شود.
   - اگر هنوز نوبت همان bot است، strategy تصمیم می‌گیرد.
4. action مستقیماً به service حکم تزریق می‌شود.
5. audit ثبت می‌شود.

---

## 16) تغییرات لازم در flow مالی

## 16.1 مشکل فعلی

در [GameRoomService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java:961) از همه بازیکنان entry fee کم می‌شود.

اگر bot را مثل user عادی وارد کنیم:

- یا باید برای bot هم balance واقعی نگه داریم
- یا این step را برای botها bypass کنیم

### 16.2 تصمیم v1

برای `INTERNAL_TEST`:

- پیش‌فرض `disableEconomy = true`
- entry fee deduction و payout و leaderboard skip شوند

برای `BETA_PUBLIC`:

- از انسان‌ها entry fee طبق flow فعلی کم شود.
- از bot entry fee واقعی کم نشود.
- سهم ورودی seat بات به‌صورت `virtual contribution` در `bot_house_ledger` ثبت شود.
- اگر تیم حاوی بات ببازد، House فقط subsidy لازم را می‌پردازد.
- اگر تیم حاوی بات ببرد، مازاد house payout ثبت می‌شود ولی نباید به‌عنوان player wallet for bot معنا پیدا کند.

### 16.3 تصمیم درباره payout

در beta public:

- payout کاربران انسانی باید دقیقاً مطابق قرارداد میز باشد.
- bot نباید wallet معنادار و قابل برداشت داشته باشد.
- سود/زیان bot به `house ledger` منتقل می‌شود، نه به اکوسیستم کاربر.

### 16.4 نتیجه

settlement برای bot-assisted rooms باید از flow عمومی outcome جدا شود و branch اختصاصی داشته باشد.

---

## 17) Ruleهای دقیق اقتصاد

## 17.1 Internal Test

- default: `no entry fee deduction`
- default: `no game win reward`
- default: `no leaderboard impact`
- optional override فقط برای تست دستی ادمین

## 17.2 Beta Public

- entry fee از انسان‌ها کسر می‌شود.
- bot contribution مجازی است.
- subsidy House در ledger ثبت می‌شود.
- game result با `excluded_from_leaderboard = true` ذخیره می‌شود.

## 17.3 Stop-loss

اگر هر کدام از شرط‌های زیر hit شود، join جدید بات ممنوع می‌شود:

- `daily-loss-limit`
- `per-room-subsidy-limit`
- `per-user-net-loss-limit`

---

## 18) منطق تصمیم بات حکم

## 18.1 محدودیت اطلاعات

بات فقط باید این داده‌ها را ببیند:

- hand خودش
- کارت‌های بازی‌شده visible
- seat order
- trump suit
- lead suit
- history استنباط‌پذیر از playها

نباید ببیند:

- دست سایر بازیکنان
- deck باقی‌مانده
- state hidden دیگر بازیکنان

## 18.2 انتخاب حکم

heuristic v1:

- تعداد کارت هر suit
- تعداد high cardها در هر suit
- وزن بیشتر به `A/K/Q/J`
- tie-breaker بر اساس longest suit

## 18.3 تصمیم بازی کارت

pipeline تصمیم:

1. ساخت `legalMoves`
2. تشخیص context:
   - lead
   - follow
   - partner currently winning
   - enemy currently winning
3. اعمال heuristic بر اساس difficulty
4. تزریق stochastic error کنترل‌شده
5. انتخاب move نهایی

## 18.4 Difficulty matrix

### `NOVICE`

- random weighted روی legal moves
- خطای زیاد
- حفظ ترامپ ضعیف
- team awareness محدود

### `STANDARD`

- follow suit درست
- basic trump conservation
- basic partner awareness
- delay انسانی

### `SKILLED`

- card counting سبک
- inference از void suits
- trump timing بهتر
- throw-away هوشمندتر

### `EXPERT`

- planning چند trick جلوتر
- inference قوی‌تر
- کمترین mistake rate

### تصمیم v1

برای public beta پیش‌فرض:

- `STANDARD`

برای internal test:

- قابل انتخاب توسط ادمین

---

## 19) Seat assignment و team balance

برای حکم چون تیمی است:

- seat bot نباید تصادفی مطلق باشد.
- bot باید صندلی‌ای را بگیرد که team split نهایی معتبر بماند.

### policy v1

- از ترتیب join فعلی استفاده می‌شود.
- seat چهارم همان seat خالی آخر است.
- چون team assignment در [HokmEngineService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/HokmEngineService.java:25) بر اساس index انجام می‌شود، نباید بعداً reorder غیرمنتظره اعمال کنیم.

### نتیجه

- v1 seat logic را ساده نگه می‌داریم.
- اگر بعداً لازم شد، می‌توان seat balancing پیشرفته‌تر اضافه کرد.

---

## 20) رفتار در disconnect / timeout / leave

### 20.1 قبل از شروع بازی

- اگر انسان از روم beta بیرون رفت، timer bot fill باید cancel شود.
- اگر bot join شده بود و روم دوباره ناقص شد، bot باید از روم حذف شود مگر اینکه بازی start شده باشد.

### 20.2 بعد از شروع بازی

- v1 hot-swap انسان با بات ندارد.
- اگر انسان disconnect شد، flow فعلی timeout/forfeit حکم پابرجا می‌ماند.

### 20.3 نتیجه

v1 فقط `pre-start fill` را پشتیبانی می‌کند.

---

## 21) Leaderboard, Reports, Analytics

### 21.1 Leaderboard

بازی‌های bot-assisted باید:

- یا کامل exclude شوند
- یا حداقل از leaderboard رسمی exclude شوند

تصمیم v1:

- `excluded_from_leaderboard = true`

### 21.2 Reports

در admin reports باید breakdown مستقل داشته باشیم:

- total bot-assisted games
- total internal test games
- total public beta bot games
- total house subsidy
- avg wait time saved

### 21.3 Metrics پیشنهادی

- `hokm_bot_fill_attempt_total`
- `hokm_bot_fill_success_total`
- `hokm_bot_fill_cancel_total`
- `hokm_bot_turn_total`
- `hokm_bot_decision_ms`
- `hokm_bot_house_subsidy_total`
- `hokm_bot_active_rooms`
- `hokm_bot_wait_time_saved_ms`

---

## 22) UI/UX حداقلی

## 22.1 Internal Test

- در admin/test UI دکمه `Create Hokm Test Room`
- امکان انتخاب تعداد بات و difficulty
- نمایش badge `TEST`

## 22.2 Beta Public

- روم bot-assisted باید badge داشته باشد
- بازیکن bot در لیست بازیکنان با badge `BOT` یا equivalent نمایش داده شود
- disclosure متن کوتاه داشته باشد

نمونه copy:

- `This table may include one system player to reduce wait time during beta.`

---

## 23) ریسک‌ها و کنترل‌ها

## 23.1 ریسک اعتماد کاربر

ریسک:

- کاربر حس کند سیستم dead است یا بازی unfair است.

کنترل:

- فقط 1 bot در public beta
- disclosure
- عدم استفاده در ranked/official tables

## 23.2 ریسک مالی

ریسک:

- house subsidy از کنترل خارج شود.

کنترل:

- daily cap
- per-room cap
- kill switch

## 23.3 ریسک فنی

ریسک:

- race condition بین join انسان و join بات

کنترل:

- pessimistic lock / recheck on execution
- timer keys یکتا

## 23.4 ریسک fairness

ریسک:

- بات به hidden state دسترسی داشته باشد.

کنترل:

- strategy فقط از public + self-visible state تغذیه شود
- تست‌های assertion برای no-hidden-data access

---

## 24) فازبندی اجرا

## Phase 1: Internal Test Only

خروجی:

- bot user model
- bot profile
- HokmBotStrategy v1
- admin create test room
- 1 human + 3 bots
- no economy
- debug logs

معیار پذیرش:

- یک انسان بتواند بدون مرورگرهای اضافی کل بازی حکم را کامل تست کند.

## Phase 2: Public Beta Fill

خروجی:

- policy service
- seat fill timer
- public disclosure
- house ledger
- stop-loss
- leaderboard exclusion

معیار پذیرش:

- روم 3 نفره عمومی بعد از threshold با 1 بات شروع شود.

## Phase 3: Hardening

خروجی:

- metrics dashboard
- report breakdown
- tuning difficulty
- rollout by percentage of eligible rooms

---

## 25) تست‌پذیری و Test Plan

## 25.1 Unit Tests

- policy eligibility
- wait-threshold evaluation
- house cap enforcement
- HokmBotStrategy legal move selection
- chooseTrump heuristic
- no-hidden-information assertions

## 25.2 Integration Tests

- create internal test room with 3 bots
- full game completion with 1 human + 3 bots
- public room with 3 humans -> bot fill after threshold
- human leaves before threshold -> bot fill canceled
- bot action stale due to stateVersion change -> no-op
- leaderboard exclusion
- house subsidy ledger write

## 25.3 Manual Tests

- 1 human vs 3 bots on local
- 3 humans + 1 bot on staging
- kill switch during open lobbies
- stress with multiple concurrent pending rooms

---

## 26) Acceptance Criteria

یک implementation وقتی complete محسوب می‌شود که:

1. ادمین بتواند روم تست حکم با `1..3` بات بسازد.
2. بازی حکم با `1 human + 3 bots` کامل تا finish اجرا شود.
3. بات‌ها فقط moveهای قانونی انجام دهند.
4. public beta بتواند `3 human + 1 bot` را بعد از threshold شروع کند.
5. bot-assisted games از leaderboard رسمی حذف شوند.
6. house subsidy در ledger ثبت شود.
7. kill switch بتواند join جدید بات را متوقف کند.
8. audit log برای join/action/settlement وجود داشته باشد.

---

## 27) پیشنهاد پیاده‌سازی در کلاس‌های فعلی

### 27.1 کلاس‌های جدید

- `BotPolicyService`
- `BotSeatFillService`
- `BotSchedulerService`
- `BotActionCoordinator`
- `BotUserService`
- `HokmBotStrategy`
- `HokmBotDecisionService`
- `BotSettlementService`
- `BotAuditService`

### 27.2 کلاس‌های فعلی که تغییر می‌کنند

- [GameRoomService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/GameRoomService.java)
  - room create/join/start flow
  - branch اقتصاد برای bot-assisted rooms

- [HokmEngineService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/HokmEngineService.java)
  - hook برای scheduling bot action after state change

- [GameOutcomeService.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/services/GameOutcomeService.java)
  - settlement branch برای bot-assisted room

- [AdminAppSettingsController.java](/Users/sajadrahmanipour/Documents/game project/gameBackend/src/main/java/com/gameapp/game/controllers/AdminAppSettingsController.java)
  - reuse برای تنظیم policy

---

## 28) تصمیم‌های صریح این RFC

برای جلوگیری از ambiguity، این RFC صریحاً تصمیم می‌گیرد که:

- v1 فقط `HOKM`
- v1 فقط `server-side bot`
- public v1 فقط `3 human + 1 bot`
- internal test پیش‌فرض بدون اقتصاد
- public beta با disclosure
- bot-assisted games خارج از leaderboard رسمی
- درصد آنلاین فقط cap است، نه decision rule
- botها user واقعی با `is_bot=true` هستند

---

## 29) مواردی که عمداً به فاز بعد موکول می‌شوند

- چند persona پیشرفته برای chat/taunt
- adaptive skill در حین بازی
- 2 human + 2 bot public
- جایگزینی bot به‌جای انسان disconnect شده وسط hand
- bot برای سایر بازی‌ها

---

## 30) نتیجه نهایی

بهترین مسیر برای این پروژه:

- اول `Internal Test Mode` را پیاده کنیم تا تیم بتواند سریع و واقعی حکم را تست کند.
- سپس `Public Beta Bot-Assisted` را فقط برای `3 human + 1 bot` اضافه کنیم.
- اقتصاد این میزها را جدا و auditable نگه داریم.
- leaderboard رسمی را از این میزها پاک نگه داریم.

این مسیر هم با معماری فعلی backend سازگار است، هم سریع‌ترین ارزش را می‌دهد، هم ریسک محصول و مالی را قابل‌کنترل نگه می‌دارد.
