# Belote Implementation Audit

Date: 2026-04-12

## خلاصه وضعیت

وضعیت فعلی Belote در کدبیس `partial backend / missing frontend` است.

- Backend:
  - بخش زیادی از runtime و room integration پیاده شده است.
  - engine، timer، rematch، continuity، surrender، bot settings و WS action routing برای Belote وجود دارد.
- Frontend:
  - Belote هنوز وارد زنجیره اصلی app نشده است.
  - enum/mapping/route/room-list/join-link/history/ws-contract برای `BELOTE` وجود ندارد.
  - فایل‌های `belote_*` موجود در app در عمل placeholder های Tarneeb هستند و استفاده نمی‌شوند.
- Tests/Docs:
  - تست اختصاصی backend/frontend برای Belote وجود ندارد.
  - فایل `docs/BELOTE_WEB_FRONTEND_SPEC.md` هنوز ساخته نشده است.

## آنچه واقعاً پیاده شده

### 1. Backend enum/config/room wiring

- `Enums.GameType.BELOTE` و `Enums.GameScore.BELOTE_151` اضافه شده‌اند:
  - `gameBackend/src/main/java/com/gameapp/game/models/Enums.java`
- migration کاتالوگ و config برای Belote وجود دارد:
  - `gameBackend/src/main/resources/db/v3/V90__belote_catalog_and_config.sql`
- timer key `declaration` و default timer های Belote اضافه شده‌اند:
  - `gameBackend/src/main/java/com/gameapp/game/services/GameTimerSettingsService.java`
- `GameRoomService` برای Belote:
  - score پیش‌فرض `BELOTE_151` می‌گذارد
  - start engine را به `BeloteEngineService` route می‌کند

### 2. Backend runtime

- `BeloteEngineService` وجود دارد و phase های اصلی را نگه می‌دارد:
  - `bidding`
  - `declaring`
  - `playing`
  - `roundFinished`
  - `finished`
- موارد زیر در engine وجود دارد:
  - seating تیمی 0+2 مقابل 1+3
  - deal اولیه `3 + 2`
  - bidding روی suit / no trump / all trumps
  - pass / double / redouble
  - redeal بعد از 4 pass اول
  - lock contract
  - deal سه کارت آخر
  - declaration step
  - 8 trick play
  - scoring round و end match
  - rematch / surrender / disconnect handoff parity hooks

### 3. Realtime / snapshot

- action های backend برای Belote route شده‌اند:
  - `BELOTE_SUBMIT_BID`
  - `BELOTE_PASS_BID`
  - `BELOTE_DOUBLE`
  - `BELOTE_REDUBLE`
  - `BELOTE_SUBMIT_DECLARATION`
  - `BELOTE_PLAY_CARD`
- `GAME_STATE` و `STATE_SNAPSHOT` برای Belote از `buildViewerSnapshot(...)` تغذیه می‌شوند و raw entity برنمی‌گردانند.

### 4. Team parity hooks

- `TeamGameContinuityService` از Belote پشتیبانی می‌کند.
- `RematchService` Belote را داخل بازی‌های گروهی/rematch-capable می‌شناسد.
- `BeloteBotStrategy` و `BeloteBotSettingsService` وجود دارند.

## آنچه هنوز پیاده نشده یا ناقص است

### P0. Frontend Belote عملاً وصل نشده

این بزرگ‌ترین شکاف فعلی است.

- در `gameapp/lib/core/constants/game_types.dart` اصلاً `GameType.belote` وجود ندارد.
- در route bootstrap، navigation و router هیچ case برای `BELOTE` وجود ندارد.
- در `ws_contract_catalog.dart` هیچ schema ای برای action های Belote وجود ندارد.
- در surfaces مربوط به room list / create room / join-room / history / active config cache / labels هنوز Belote وارد نشده است.

نتیجه:

- حتی اگر backend آماده باشد، client اصلی هنوز Belote را به عنوان یک game type واقعی نمی‌شناسد.
- resync / validation / route resume / join-link parity روی app برای Belote کامل نشده است.

### P0. فایل‌های frontend Belote فقط placeholder های Tarneeb هستند

فایل‌های زیر Belote واقعی نیستند:

- `gameapp/lib/features/game/data/models/belote_game_state.dart`
- `gameapp/lib/features/game/ui/game_ui/belote_game_ui.dart`
- `gameapp/lib/features/game/ui/game_ui/belote_result_resolver.dart`

این فایل‌ها هنوز:

- type های `TarneebPhase`, `TarneebGameState`, `TarneebGameUI`, `TarneebResultResolver` را نگه داشته‌اند
- import های Tarneeb دارند
- action های `TARNEEB_*` می‌فرستند
- با contract و phase های واقعی Belote هم‌راستا نیستند

نتیجه:

- مدل، UI و resolver اختصاصی Belote هنوز شروع نشده یا از scaffold اشتباه کپی شده است.

### P0. سند قرارداد frontend هنوز وجود ندارد

فایل زیر هنوز در repo نیست:

- `docs/BELOTE_WEB_FRONTEND_SPEC.md`

در نتیجه:

- قرارداد نهایی state/action/event قبل از تکمیل frontend تثبیت نشده است.
- ریسک mismatch بین backend snapshot و client parsing بالاست.

### P0. تست اختصاصی Belote وجود ندارد

در `gameBackend/src/test/java` تست Belote پیدا نشد.
در `gameapp/test` هم تست Belote پیدا نشد.

در نتیجه:

- بخش مهمی از rule engine بدون regression harness مانده است.
- parity regression برای mapping های shared card-game UI هنوز پوشش ندارد.

### P1. منطق belote/rebelote در backend دقیقاً با rule مورد نظر نهایی نشده

در `BeloteEngineService.processBelotePlay(...)` امتیاز 20 بلافاصله با اولین play از `K` یا `Q` همان suit ثبت می‌شود و player در `beloteAwardedPlayers` قفل می‌شود.

این behavior با interpretation سخت‌گیرانه‌ی plan که می‌گوید award باید بر اساس play شدن واقعی pair مدیریت شود، نیاز به بازبینی دارد.

### P1. scoring در contract failure به احتمال زیاد belote points را به تیم مدافع منتقل می‌کند

در `finishRound(...)` ابتدا `rawTeamA/rawTeamB` با declaration و belote جمع می‌شوند، اما اگر declarer contract را نبرد:

- امتیاز awarded روی `totalRaw` برای تیم مدافع set می‌شود
- این منطق belote points را هم داخل sweep مدافع می‌برد

برای rule کلاسیک Belote، belote/rebelote معمولاً حتی در صورت fail شدن contract نزد همان تیم باقی می‌ماند؛ بنابراین این بخش باید با rule target دقیق پروژه تثبیت و تست شود.

### P1. Belote bot parity کامل نیست

`BeloteBotStrategy` فقط این action ها را تولید می‌کند:

- `PASS_BID`
- `SUBMIT_BID`
- `SUBMIT_DECLARATION`
- `PLAY_CARD`

ولی برای:

- `BELOTE_DOUBLE`
- `BELOTE_REDUBLE`

تصمیم‌گیری ندارد.

پس disconnect handoff وجود دارد، اما parity کامل bidding behavior هنوز کامل نشده است.

## جمع‌بندی وضعیت نسبت به پلن اولیه

### انجام شده

- Backend `GameType/GameScore` و migration
- Timer settings برای declaration
- Start routing از room به engine
- WS backend action routing
- `STATE_SNAPSHOT` و `GAME_STATE` سفارشی
- core engine flow
- team surrender / rematch / continuity hooks
- bot settings + bot strategy skeleton

### انجام نشده یا ناقص

- `docs/BELOTE_WEB_FRONTEND_SPEC.md`
- frontend models واقعی Belote
- frontend route/bootstrap/navigation/create-room/join-room/history mappings
- frontend WS contract schemas
- `BeloteHeaderWidget`
- UI parity کامل با shared widgets و flows
- frontend resync flows برای Belote
- backend rule-hardening برای belote/rebelote و contract-fail scoring
- backend test suite
- frontend test suite
- regression suite برای shared mappings

## پلن تکمیلی اجرا

### فاز 1. Freeze contract و rule decisions

هدف: قبل از هر تغییر client، contract و rule edge case ها نهایی شوند.

کارها:

1. ساخت `docs/BELOTE_WEB_FRONTEND_SPEC.md`
2. ثبت payload shape نهایی برای:
   - `GAME_STATE_UPDATED`
   - `STATE_SNAPSHOT`
   - `BELOTE_BID_WON`
   - `BELOTE_DECLARATIONS_RESOLVED`
   - `ROUND_ENDED`
   - `GAME_FINISHED`
3. نهایی کردن rule decisions برای:
   - timing دقیق `belote/rebelote`
   - نگه‌داشتن یا ندادن belote points در contract failure
   - tie / hanging behavior
   - declaration tie resolution

خروجی acceptance:

- یک spec واحد که backend و app هر دو از آن تبعیت کنند.

### فاز 2. Harden backend rules

هدف: قبل از وصل کردن UI، engine از نظر correctness قابل اتکا شود.

کارها:

1. بازبینی `processBelotePlay(...)` برای belote/rebelote
2. بازبینی `finishRound(...)` برای failure scoring و belote preservation
3. اگر rule target لازم دارد، کامل کردن declaration conflict logic
4. در صورت نیاز، افزودن bot support برای `DOUBLE` و `REDUBLE`

خروجی acceptance:

- rule engine با spec نهایی align باشد.

### فاز 3. Add backend tests

کارها:

1. engine unit tests برای:
   - bid ordering
   - four-pass redeal
   - contract lock
   - declaration eligibility / comparison
   - trick winner logic برای suit / NT / AT
   - must-trump / overtrump
   - belote/rebelote timing
   - hanging
   - doubled / redoubled rounds
   - valat
   - match finish at 151
2. integration tests برای:
   - `GameRoomService`
   - `GameTimerSettingsService`
   - `STATE_SNAPSHOT`
   - rematch / surrender / continuity handoff

خروجی acceptance:

- حداقل یک test suite Belote در backend وجود داشته باشد و rule regressions را بگیرد.

### فاز 4. Wire frontend game-type surfaces

کارها:

1. افزودن `GameType.belote`
2. افزودن `GameScore.belote151`
3. افزودن mapping در:
   - game type parsing
   - room list
   - create-room sheet
   - join-room link
   - history labels
   - navigation
   - route URLs
   - active config cache
4. افزودن route:
   - `/game/belote/:roomId`

خروجی acceptance:

- app بتواند room های `BELOTE` را بشناسد، route کند و create/join/history parity داشته باشد.

### فاز 5. Replace placeholders with real Belote frontend

کارها:

1. حذف یا بازنویسی کامل placeholder های `belote_*`
2. ساخت model های واقعی:
   - `BeloteGameState`
   - `BelotePlayerState`
   - `BelotePhase`
   - `BeloteContractType`
   - declaration DTOs
3. ساخت `BeloteGameUI`
4. ساخت `BeloteHeaderWidget`
5. استفاده از shared widgets:
   - `CardFanWidget`
   - `PlayingTableWidget`
   - timer widgets
   - result dialog
   - chat
   - spectator entry
6. پشتیبانی از action های:
   - `BELOTE_SUBMIT_BID`
   - `BELOTE_PASS_BID`
   - `BELOTE_DOUBLE`
   - `BELOTE_REDUBLE`
   - `BELOTE_SUBMIT_DECLARATION`
   - `BELOTE_PLAY_CARD`

خروجی acceptance:

- full playable Belote UI با room parity موجود.

### فاز 6. Add frontend contract + UI tests

کارها:

1. contract/runtime tests برای WS schemas و resync
2. UI tests برای:
   - bootstrap
   - bidding
   - declaration
   - trick updates
   - round/game result dialogs
   - join-room links
   - history labels
3. regression tests برای عدم شکستن Hokm / Shelem / Hearts / Hav7khabis

خروجی acceptance:

- Belote path در app testable و shared card-game regressions پوشش داده شده باشد.

## اولویت اجرای پیشنهادی

1. فاز 1 و 2
2. فاز 3
3. فاز 4
4. فاز 5
5. فاز 6

## نتیجه نهایی audit

اگر تعریف “پیاده‌سازی شده” را end-to-end و room-parity کامل بگیریم، Belote هنوز کامل نشده است.

وضعیت واقعی:

- Backend core: حدوداً پیاده شده
- Backend correctness hardening: ناقص
- Frontend integration: عملاً انجام نشده
- Tests/docs: انجام نشده

بنابراین Belote در حال حاضر بیشتر در وضعیت `backend-first partial implementation` قرار دارد، نه `full room parity`.
