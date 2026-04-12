# Ludo (`LUDO`) Rules Spec

- Variant: digital Ludo / منچ با runtime server-authoritative
- Players: `2..6`
- Supported modes:
  - `FFA_2`
  - `FFA_3`
  - `FFA_4`
  - `FFA_5`
  - `FFA_6`
  - `TEAM_2V2`
  - `TEAM_3V3`
- Boards:
  - `CLASSIC_4` برای `2/3/4` نفر
  - `CLASSIC_6` برای `5/6` نفر
- Team assignment:
  - `TEAM_2V2`: صندلی‌های روبه‌رو هم‌تیم
  - `TEAM_3V3`: صندلی‌های یکی‌درمیان هم‌تیم

## Turn Flow

- هر نوبت با یک roll شروع می‌شود.
- ورود مهره از yard فقط با `6` ممکن است.
- حرکت‌ها clockwise هستند.
- رسیدن به خانه نهایی باید `exact` باشد.
- روی `6` یک bonus roll داده می‌شود.
- capture و finish-token نیز bonus roll می‌دهند.
- اگر سه `6` پشت‌سرهم بیاید:
  - move مربوط به رول سوم اعمال نمی‌شود
  - turn فوراً terminate می‌شود
- اگر بعد از roll هیچ move قانونی نباشد:
  - server نوبت را auto-skip می‌کند

## Safety, Stacking, Capture

- `safe cells` شامل این‌هاست:
  - start cell هر رنگ
  - star/safe track cells
  - کل home lane همان رنگ
- pair blockade در v1 وجود ندارد.
- روی خانه‌های safe می‌توان روی مهره خودی فرود آمد.
- روی non-safe main track، فرود روی مهره خودی illegal است.
- capture فقط وقتی مجاز است که:
  - خانه non-safe باشد
  - فقط یک مهره حریف روی آن خانه باشد
- مهره captureشده به yard برمی‌گردد.

## Match, Round, Takeover

- round در حالت فردی وقتی تمام می‌شود که یک بازیکن هر 4 مهره خود را home کند.
- round در حالت تیمی وقتی تمام می‌شود که همه مهره‌های یک تیم home شوند.
- match چند-roundی است و از `gameScore` می‌آید:
  - `LUDO_ONE -> 1`
  - `LUDO_THREE -> 3`
  - `LUDO_FIVE -> 5`
- settlement فقط در پایان match انجام می‌شود.

## Team Takeover

- اگر بازیکنی در حالت تیمی هر 4 مهره خود را home کند:
  - server کنترل صندلی(های) unfinished هم‌تیمی را به همان user منتقل می‌کند
  - این takeover فقط برای جلوگیری از dual-control race است
- `controllerBySeat` و `turnOwnerUserId` source of truth سمت UI هستند.

## Runtime Notes

- turn timeout پیش‌فرض: `18s`
- reconnect/resync از `GET_GAME_STATE_BY_ROOM`
- فاصله شروع round بعدی: `3s`
- actionهای اصلی:
  - `LUDO_ROLL_DICE`
  - `LUDO_MOVE_TOKEN`
- eventهای اصلی:
  - `LUDO_GAME_STARTED`
  - `LUDO_STATE_UPDATED`
  - `LUDO_ROUND_FINISHED`
  - `LUDO_GAME_FINISHED`
  - `LUDO_ERROR`
  - `TURN_TIMER_STARTED`
