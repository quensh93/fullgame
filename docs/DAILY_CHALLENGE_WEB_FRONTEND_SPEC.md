# مستند کامل سیستم Daily Challenge برای فرانت وب

- نسخه: `1.0`
- تاریخ: `2026-03-08`
- وضعیت: `Ready for Frontend Implementation`
- دامنه: `User Panel + Admin Panel + WS/REST Contracts + Runtime Gaps`

---

## 1. هدف این سند

این سند برای پیاده‌سازی وب در دو بخش نوشته شده است:

- پنل کاربر
- پنل ادمین

مرجع اصلی این سند رفتار واقعی runtime بک‌اند است، نه صرفا اسم endpointها. هر جا بین config، event یا API و رفتار واقعی اختلاف وجود دارد، با برچسب `GAP-*` ثبت شده است.

---

## 2. Source of Truth

فایل‌های مرجع اصلی:

- Backend business logic:
  - `gameBackend/src/main/java/com/gameapp/game/services/DailyChallengeService.java`
  - `gameBackend/src/main/java/com/gameapp/game/services/AdminChallengeService.java`
  - `gameBackend/src/main/java/com/gameapp/game/services/DailyChallengeSchedulerService.java`
  - `gameBackend/src/main/java/com/gameapp/game/services/ChallengeLeaderboardService.java`
  - `gameBackend/src/main/java/com/gameapp/game/services/DailyRewardService.java`
- Backend controllers:
  - `gameBackend/src/main/java/com/gameapp/game/controllers/AdminDailyChallengeController.java`
  - `gameBackend/src/main/java/com/gameapp/game/controllers/AdminChallengeTemplateController.java`
  - `gameBackend/src/main/java/com/gameapp/game/controllers/AdminChallengeConfigController.java`
  - `gameBackend/src/main/java/com/gameapp/game/controllers/ChallengeLeaderboardController.java`
  - `gameBackend/src/main/java/com/gameapp/game/controllers/DailyRewardController.java`
- WS router and error codes:
  - `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`
  - `gameBackend/src/main/java/com/gameapp/game/constants/WsErrorCodes.java`
- Mobile reference implementation:
  - `gameapp/lib/features/daily_challenges/providers/daily_challenges_provider.dart`
  - `gameapp/lib/features/daily_challenges/data/models/daily_challenge_models.dart`
  - `gameapp/lib/features/daily_challenges/ui/daily_challenges_page.dart`
  - `gameapp/lib/core/websocket/ws_contract_catalog.dart`

---

## 3. تصویر کلی سیستم

سیستم Daily Challenge در runtime فعلی 6 جزء دارد:

1. `Daily Challenges`
چالش‌های روزانه‌ی هر کاربر که با بازی کردن کامل می‌شوند.

2. `Complete All Bonus`
اگر همه‌ی چالش‌های روز کامل شوند، یک bonus جدا باز می‌شود.

3. `Daily Login Reward`
پاداش claim روزانه که به streak ورود متصل است.

4. `Streak Milestones`
پاداش milestone برای streakهای خاص مثل 3 یا 5 یا 7 روز.

5. `Challenge History`
تاریخچه‌ی چالش‌های روزهای قبل.

6. `Challenge Leaderboard`
لیدربورد challenge بر اساس period.

---

## 4. مدل مفهومی و قواعد بیزنس

### 4.1 چالش‌های روزانه چگونه ساخته می‌شوند

- چالش‌ها `batch pre-generate` نمی‌شوند.
- برای هر کاربر، چالش‌های همان روز وقتی ساخته می‌شوند که کاربر اولین بار payload امروز را بخواهد.
- اگر برای امروز قبلا رکورد وجود داشته باشد، همان رکورد برمی‌گردد.
- اگر برای امروز رکوردی وجود نداشته باشد، از روی `Challenge Templates + Challenge Config` ساخته می‌شود.

نتیجه مهم برای فرانت و ادمین:

- تغییر template یا config فقط روی کاربرانی اثر می‌گذارد که هنوز challenge روز جاری برایشان generate نشده است.
- تغییر config/template چالش‌های امروز کاربرانی را که قبلا challenge گرفته‌اند retroactive عوض نمی‌کند.

### 4.2 الگوریتم انتخاب template

- فقط templateهای `isActive=true` وارد pool می‌شوند.
- config مشخص می‌کند روزانه چند challenge ساخته شود:
  - `challengesPerDay`
  - `easyCount`
  - `mediumCount`
  - `hardCount`
- برای هر difficulty از pool همان difficulty انتخاب انجام می‌شود.
- اگر برای difficulty خاص template نداشته باشیم، fallback روی کل pool فعال انجام می‌شود.
- انتخاب با `weight` وزندار است.
- انتخاب `with replacement` است.

نتیجه مهم:

- یک template می‌تواند در یک روز چند بار برای یک کاربر تکرار شود.
- کلید یکتای فرانت همیشه فقط `challengeId` است.
- روی `type + gameId + difficulty` برای uniqueness تکیه نکنید.

### 4.3 seed تولید روزانه

- random با `date.toEpochDay() ^ userId` seed می‌شود.
- بنابراین selection برای یک user/date مشخص deterministic است.
- ولی اگر قبل از اولین load، template/config عوض شود، خروجی generate می‌تواند عوض شود.

### 4.4 ساخت target, reward, xp

- `total` به‌صورت تصادفی بین `minTarget` و `maxTarget` همان template انتخاب می‌شود.
- reward/xp از template می‌آید:
  - `EASY`: base
  - `MEDIUM`: `base * rewardMultiplier`
  - `HARD`: `base * rewardMultiplier^2`
- گرد کردن با `HALF_UP` انجام می‌شود.

### 4.5 وضعیت‌های challenge

مقادیر معتبر runtime:

- `IN_PROGRESS`
- `COMPLETED`
- `CLAIMED`
- `EXPIRED`

معنا:

- `IN_PROGRESS`: هنوز objective کامل نشده
- `COMPLETED`: objective کامل شده ولی reward claim نشده
- `CLAIMED`: reward گرفته شده
- `EXPIRED`: منقضی شده

### 4.6 قواعد پیشرفت challenge

پیشرفت challenge فقط از روی `processGameResult(...)` در بک‌اند جلو می‌رود. یعنی فقط نتیجه‌ی نهایی بازی‌ها روی challenge اثر می‌گذارد.

قواعد:

- `PLAY`: هر بازی معتبر +1
- `WIN`: فقط اگر کاربر winner باشد +1
- `STREAK`: اگر winner باشد +1، در غیر این صورت progress به `0` برمی‌گردد
- `SCORE`: `progress = max(previousProgress, scoreValue)` و تجمعی نیست

نکته مهم:

- `SCORE` cumulative نیست؛ اگر قبلا 120 داشته باشی و در بازی بعد 90 بگیری، progress همان 120 می‌ماند.

### 4.7 تکمیل challenge

- وقتی progress به `total` برسد:
  - status از `IN_PROGRESS` به `COMPLETED` می‌رود
  - `completedAt` ثبت می‌شود
  - `CHALLENGE_COMPLETED` برای کاربر emit می‌شود
- reward در این لحظه auto-credit نمی‌شود.
- کاربر باید جداگانه `CLAIM_CHALLENGE_REWARD` بزند.

### 4.8 Complete All Bonus

- وقتی همه‌ی challengeهای روز status غیر از `IN_PROGRESS` داشته باشند، complete-all unlock می‌شود.
- claim آن جدا از claim خود challengeها است.
- state آن در `DailyChallengeDayState` نگه‌داری می‌شود.

### 4.9 Daily Login Reward

- daily login reward از streak ورود روزانه استفاده می‌کند.
- در WS challenge flow، reward و XP برمی‌گردد.
- در REST daily reward flow، reward به‌صورت decimal amount برمی‌گردد و XP ندارد.

این اختلاف در بخش gapها مستند شده است.

### 4.10 Streak Milestone

- milestoneها از config می‌آیند.
- claim هر milestone فقط یک بار ممکن است.
- اگر قبلا claim شده باشد، backend دوباره reward نمی‌دهد و `alreadyClaimed=true` برمی‌گرداند.

### 4.11 History

- history فقط روزهای قبل از امروز را برمی‌گرداند.
- challengeهای امروز داخل history نیستند.

### 4.12 Leaderboard ranking order

ترتیب rank:

1. `challengesCompleted DESC`
2. `totalRewardsEarned DESC`
3. `totalXpEarned DESC`
4. `currentStreak DESC`
5. `userId ASC`

---

## 5. Enumها و mappingهای مهم

### 5.1 Challenge Type

- `PLAY`
- `WIN`
- `STREAK`
- `SCORE`

### 5.2 Difficulty

- `EASY`
- `MEDIUM`
- `HARD`

### 5.3 Status

- `IN_PROGRESS`
- `COMPLETED`
- `CLAIMED`
- `EXPIRED`

### 5.4 Game IDهای فعلی As-Is

مقادیر map شده در runtime:

- `hokm`
- `shelem`
- `hearts`
- `haft`
- `backgammon`
- `rps`
- `dice`
- `casinowar`
- `blackjack`
- `rummy`
- `chaharbarg`

### 5.5 Mapping پیشنهادی gameId به GameType فرانت

```ts
export const gameIdToGameType: Record<string, string> = {
  hokm: "HOKM",
  shelem: "SHELEM",
  hearts: "HEARTS",
  haft: "HAV7KHABIS",
  backgammon: "BACKGAMMON",
  rps: "ROCK_PAPER_SCISSORS",
  dice: "DICE",
  casinowar: "CASINO_WAR",
  blackjack: "BLACKJACK",
  rummy: "RIM",
  chaharbarg: "CHAHAR_BARG",
};
```

---

## 6. قرارداد پنل کاربر

## 6.1 Transport

برای challengeهای active کاربر، contract اصلی در runtime فعلی `WebSocket /ws-v3` است.

پیش‌نیاز:

- اتصال به `/ws-v3`
- انجام `AUTH`
- سپس ارسال actionهای challenge

فرمت کلی envelope:

```ts
export interface WsEnvelope<T = unknown> {
  type: string;
  success?: boolean;
  action?: string;
  data?: T;
  errorCode?: string;
  error?: string;
  eventId?: string;
  traceId?: string;
  serverTime?: string;
  protocolVersion?: string;
  stateVersion?: number;
  clientActionId?: string;
}
```

## 6.2 مدل‌های TypeScript پیشنهادی برای کاربر

```ts
export type ChallengeStatus = "IN_PROGRESS" | "COMPLETED" | "CLAIMED" | "EXPIRED";
export type ChallengeType = "PLAY" | "WIN" | "STREAK" | "SCORE";
export type ChallengeDifficulty = "EASY" | "MEDIUM" | "HARD";

export interface DailyChallengeItem {
  challengeId: string;
  type: ChallengeType | string;
  gameId: string;
  difficulty: ChallengeDifficulty | string;
  titleKey: string;
  descKey: string;
  reward: number;
  xpReward: number;
  progress: number;
  total: number;
  status: ChallengeStatus | string;
  expiresAt?: string | null;
  completedAt?: string | null;
  claimedAt?: string | null;
}

export interface CompleteAllBonus {
  reward: number;
  xpReward: number;
  isUnlocked: boolean;
  isClaimed: boolean;
}

export interface WeeklyRewardSlot {
  day: number;
  reward: number;
  xpReward?: number | null;
  claimed: boolean;
}

export interface StreakMilestone {
  streak: number;
  reward: number;
  reached: boolean;
  claimed: boolean;
}

export interface WeeklyBonus {
  currentStreak: number;
  totalDays: number;
  rewards: WeeklyRewardSlot[];
  streakMilestones: StreakMilestone[];
  totalWeeklyReward: number;
}

export interface ChallengeStats {
  totalChallengesCompleted: number;
  totalRewardsEarned: number;
  totalXpEarned: number;
  currentConsecutiveDays: number;
  bestConsecutiveDays: number;
  currentLoginStreak: number;
  bestLoginStreak: number;
}

export interface DailyChallengesPayload {
  challenges: DailyChallengeItem[];
  completeAllBonus: CompleteAllBonus;
  weeklyBonus: WeeklyBonus;
  stats: ChallengeStats;
  expiresAt?: string | null;
}

export interface ChallengeHistoryItem {
  challengeId: string;
  type: string;
  gameId: string;
  difficulty: string;
  titleKey: string;
  descKey: string;
  reward: number;
  xpReward: number;
  progress: number;
  total: number;
  status: string;
  challengeDate?: string | null;
  completedAt?: string | null;
  claimedAt?: string | null;
}

export interface ChallengeHistoryPayload {
  challenges: ChallengeHistoryItem[];
  totalElements: number;
  totalPages: number;
  page: number;
  size: number;
}

export interface DailyChallengeSummary {
  featuredChallenge: null | {
    challengeId: string;
    titleKey: string;
    gameId: string;
    reward: number;
    progress: number;
    total: number;
  };
  totalChallenges: number;
  completedChallenges: number;
  expiresAt?: string | null;
}
```

## 6.3 سیگنال‌های ورودی و خروجی WS

### 6.3.1 دریافت بسته کامل challengeهای امروز

ورودی:

```json
{ "type": "GET_DAILY_CHALLENGES" }
```

خروجی موفق:

- signal: `DAILY_CHALLENGES_DATA`
- payload: `DailyChallengesPayload`

خطاها:

- `AUTH_REQUIRED`

رفتار فرانت:

- این response، منبع اصلی state صفحه‌ی Daily Challenges است.
- در refresh اولیه و هر resync کامل از همین action استفاده کن.

### 6.3.2 دریافت summary فشرده برای home/widget

ورودی:

```json
{ "type": "GET_DAILY_CHALLENGE_SUMMARY" }
```

خروجی موفق:

- signal: `DAILY_CHALLENGE_SUMMARY`
- payload:

```json
{
  "featuredChallenge": {
    "challengeId": "uuid",
    "titleKey": "challenge.win.backgammon.3.title",
    "gameId": "backgammon",
    "reward": 25,
    "progress": 1,
    "total": 3
  },
  "totalChallenges": 6,
  "completedChallenges": 2,
  "expiresAt": "2026-03-09T00:00:00Z"
}
```

خطاها:

- `AUTH_REQUIRED`

### 6.3.3 claim reward یک challenge

ورودی:

```json
{
  "type": "CLAIM_CHALLENGE_REWARD",
  "challengeId": "550e8400-e29b-41d4-a716-446655440001"
}
```

خروجی موفق:

- signal: `CHALLENGE_REWARD_CLAIMED`

```json
{
  "challengeId": "550e8400-e29b-41d4-a716-446655440001",
  "reward": 25,
  "xpReward": 150,
  "newBalance": 12345,
  "newXp": 6789
}
```

خطاها:

- `AUTH_REQUIRED`
- `ACTION_REJECTED`
- `CHALLENGE_NOT_FOUND`
- `CHALLENGE_NOT_COMPLETED`
- `CHALLENGE_ALREADY_CLAIMED`
- `CHALLENGE_EXPIRED`

رفتار فرانت:

- روی success status همان challenge را `CLAIMED` کن.
- wallet/xp global state را patch یا refresh کن.

### 6.3.4 claim complete all bonus

ورودی:

```json
{ "type": "CLAIM_COMPLETE_ALL_BONUS" }
```

خروجی موفق:

- signal: `COMPLETE_ALL_BONUS_CLAIMED`

```json
{
  "reward": 50,
  "xpReward": 300,
  "newBalance": 12345,
  "newXp": 6789
}
```

خطاها:

- `AUTH_REQUIRED`
- `COMPLETE_ALL_NOT_UNLOCKED`
- `COMPLETE_ALL_ALREADY_CLAIMED`

رفتار فرانت:

- `completeAllBonus.isClaimed = true`
- wallet/xp را sync کن

### 6.3.5 claim daily login reward از flow challenge

ورودی:

```json
{ "type": "CLAIM_DAILY_LOGIN_REWARD" }
```

خروجی موفق:

- signal: `DAILY_LOGIN_REWARD_CLAIMED`

```json
{
  "day": 3,
  "reward": 10,
  "xpReward": 50,
  "newStreak": 3,
  "newBalance": 1250,
  "newXp": 3400
}
```

خطاها:

- `AUTH_REQUIRED`
- `DAILY_LOGIN_ALREADY_CLAIMED`
- `DAILY_LOGIN_EXPIRED`

رفتار فرانت:

- slot مربوط به `day` را claimed کن
- `weeklyBonus.currentStreak` را update کن
- `stats.totalRewardsEarned` و `stats.totalXpEarned` را patch کن

### 6.3.6 claim streak milestone

ورودی:

```json
{
  "type": "CLAIM_STREAK_MILESTONE",
  "streak": 3
}
```

خروجی موفق:

- signal: `STREAK_MILESTONE_CLAIMED`

```json
{
  "streak": 3,
  "reward": 20,
  "xpReward": 100,
  "newBalance": 1300,
  "alreadyClaimed": false
}
```

یا اگر قبلا claim شده:

```json
{
  "streak": 3,
  "reward": 20,
  "xpReward": 100,
  "newBalance": 1300,
  "alreadyClaimed": true
}
```

خطاها:

- `AUTH_REQUIRED`
- `STREAK_MILESTONE_NOT_REACHED`
- `STREAK_MILESTONE_NOT_FOUND`

رفتار فرانت:

- اگر `alreadyClaimed=false` باشد، stats را patch کن
- milestone را claimed کن

نکته مهم:

- این response در runtime فعلی `newXp` ندارد.

### 6.3.7 دریافت history

ورودی:

```json
{
  "type": "GET_CHALLENGE_HISTORY",
  "page": 0,
  "size": 20
}
```

خروجی موفق:

- signal: `CHALLENGE_HISTORY_DATA`
- payload: `ChallengeHistoryPayload`

خطاها:

- `AUTH_REQUIRED`

## 6.4 سیگنال‌های push / realtime

### 6.4.1 بروزرسانی progress

signal:

- `CHALLENGE_PROGRESS_UPDATED`

payload:

```json
{
  "challengeId": "uuid",
  "progress": 2,
  "total": 3,
  "status": "IN_PROGRESS"
}
```

trigger:

- بعد از پردازش نتیجه‌ی بازی

رفتار فرانت:

- همان row را patch کن
- اگر همه‌ی itemها دیگر `IN_PROGRESS` نبودند، complete-all را unlock کن

### 6.4.2 تکمیل challenge

signal:

- `CHALLENGE_COMPLETED`

payload:

```json
{
  "challengeId": "uuid",
  "reward": 25,
  "xpReward": 150,
  "allCompleted": false
}
```

trigger:

- وقتی progress از threshold عبور کند

رفتار فرانت:

- status را `COMPLETED` کن
- progress را برابر total قرار بده
- اگر `allCompleted=true` بود complete-all را unlock کن

### 6.4.3 reset broadcast

signal:

- `DAILY_CHALLENGES_RESET`

payload:

```json
{}
```

trigger:

- scheduler ساعتی

رفتار فرانت:

- بدون patch جزئی، یک `GET_DAILY_CHALLENGES` و در صورت نیاز `GET_DAILY_CHALLENGE_SUMMARY` بزن

نکته مهم:

- این event ممکن است فقط `type` و `data` داشته باشد و `success` نداشته باشد.

## 6.5 خطای WS

فرمت کلی خطا:

```json
{
  "type": "ERROR",
  "success": false,
  "action": "CLAIM_CHALLENGE_REWARD",
  "errorCode": "CHALLENGE_NOT_COMPLETED",
  "error": "Challenge is not completed yet",
  "eventId": "uuid",
  "traceId": "uuid",
  "serverTime": "2026-03-08T10:00:00Z",
  "protocolVersion": "v3"
}
```

کدهای مهم:

- `AUTH_REQUIRED`
- `CHALLENGE_NOT_FOUND`
- `CHALLENGE_NOT_COMPLETED`
- `CHALLENGE_ALREADY_CLAIMED`
- `CHALLENGE_EXPIRED`
- `COMPLETE_ALL_NOT_UNLOCKED`
- `COMPLETE_ALL_ALREADY_CLAIMED`
- `DAILY_LOGIN_ALREADY_CLAIMED`
- `DAILY_LOGIN_EXPIRED`
- `STREAK_MILESTONE_NOT_REACHED`
- `STREAK_MILESTONE_NOT_FOUND`

## 6.6 Leaderboard کاربر

REST endpoint:

- `GET /api/challenges/leaderboard?period=daily|weekly|monthly|all_time&limit=20`

نیازمندی:

- user authenticated

response:

```ts
export interface ChallengeLeaderboardEntry {
  rank: number;
  userId: number;
  username: string;
  avatarUrl: string | null;
  challengesCompleted: number;
  totalRewardsEarned: number;
  totalXpEarned: number;
  currentStreak: number;
}

export interface ChallengeLeaderboardResponse {
  period: "daily" | "weekly" | "monthly" | "all_time";
  entries: ChallengeLeaderboardEntry[];
  myRank: ChallengeLeaderboardEntry | null;
}
```

نمونه:

```json
{
  "period": "weekly",
  "entries": [
    {
      "rank": 1,
      "userId": 42,
      "username": "ali",
      "avatarUrl": null,
      "challengesCompleted": 11,
      "totalRewardsEarned": 245,
      "totalXpEarned": 1200,
      "currentStreak": 4
    }
  ],
  "myRank": {
    "rank": 9,
    "userId": 99,
    "username": "me",
    "avatarUrl": null,
    "challengesCompleted": 3,
    "totalRewardsEarned": 70,
    "totalXpEarned": 250,
    "currentStreak": 2
  }
}
```

## 6.7 Daily Reward REST جدا از challenge flow

این بخش از نظر state با challenge share می‌کند، اما contract آن جداست.

endpointها:

- `GET /api/rewards/daily`
- `POST /api/rewards/daily/claim`

نیازمندی:

- auth
- برای claim می‌توان `Idempotency-Key` فرستاد

response status:

```json
{
  "currentStreak": 3,
  "lastClaimedAt": "2026-03-01T08:30:00Z",
  "todayClaimed": false,
  "rewards": [
    {
      "day": 1,
      "amount": 5.00,
      "currency": "USDT",
      "claimed": true,
      "claimedAt": "2026-02-27T09:00:00Z"
    }
  ],
  "cycleStartDate": "2026-02-27",
  "isSpecialDay7": true
}
```

response claim:

```json
{
  "day": 4,
  "amount": 10.00,
  "currency": "USDT",
  "newBalance": 110.00,
  "newStreak": 4,
  "claimedAt": "2026-03-02T09:15:00Z",
  "bonusAmount": 0.00,
  "nextReward": {
    "day": 5,
    "amount": 15.00
  }
}
```

توصیه:

- اگر قرار است وب همان behavior فعلی صفحه challenge موبایل را تکرار کند، از WS challenge flow استفاده کن.
- اگر قرار است صفحه‌ی مستقل Daily Reward بسازی، REST contract جدا را استفاده کن.
- این دو contract را در یک widget بدون تصمیم معماری مشخص mix نکن.

---

## 7. قرارداد پنل ادمین

پنل ادمین برای Daily Challenge عملا باید 4 زیر‌بخش داشته باشد:

1. `Challenge Instances`
رکوردهای واقعی challengeهای ساخته‌شده برای کاربران

2. `Challenge Stats`
آمار aggregate

3. `Challenge Templates`
الگوهای مولد challenge

4. `Challenge Config`
تنظیمات global generation, weekly rewards, streak milestones

## 7.1 Challenge Instances API

### 7.1.1 لیست challengeها

- `GET /api/admin/challenges`

query params:

- `search`
- `status`
- `type`
- `gameId`
- `difficulty`
- `fromDate`
- `toDate`
- `sortBy`
- `sortDir`
- `page`
- `size`

`search` روی این فیلدها عمل می‌کند:

- `user.email`
- `gameId`
- اگر عدد باشد: `user.id`

`sortBy`های معتبر:

- `id`
- `createdAt`
- `challengeDate`
- `reward`
- `progress`
- `status`
- `type`
- `difficulty`
- `gameId`
- `userEmail`

response:

- Spring `Page<AdminDailyChallengeDto>`

مدل:

```ts
export interface AdminDailyChallengeDto {
  id: number;
  challengeId: string;
  userId: number;
  userEmail: string;
  challengeDate: string;
  type: string;
  gameId: string;
  difficulty: string;
  titleKey: string;
  descKey: string;
  reward: number;
  xpReward: number;
  progress: number;
  total: number;
  status: string;
  expiresAt?: string | null;
  completedAt?: string | null;
  claimedAt?: string | null;
  createdAt?: string | null;
}
```

نمونه response:

```json
{
  "content": [
    {
      "id": 1,
      "challengeId": "uuid",
      "userId": 12,
      "userEmail": "user@gmail.com",
      "challengeDate": "2026-03-08",
      "type": "WIN",
      "gameId": "backgammon",
      "difficulty": "MEDIUM",
      "titleKey": "challenge.win.backgammon.3.title",
      "descKey": "challenge.win.backgammon.3.desc",
      "reward": 25,
      "xpReward": 150,
      "progress": 0,
      "total": 3,
      "status": "IN_PROGRESS",
      "expiresAt": "2026-03-09T00:00:00Z",
      "completedAt": null,
      "claimedAt": null,
      "createdAt": "2026-03-08T09:00:00"
    }
  ],
  "number": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1,
  "first": true,
  "last": true
}
```

### 7.1.2 ساخت challenge دستی

- `POST /api/admin/challenges`

body:

```ts
export interface AdminDailyChallengeCreateRequest {
  userId: number;
  type: string;
  gameId: string;
  difficulty: string;
  reward: number;
  xpReward: number;
  total: number;
}
```

نمونه:

```json
{
  "userId": 12,
  "type": "WIN",
  "gameId": "backgammon",
  "difficulty": "MEDIUM",
  "reward": 25,
  "xpReward": 150,
  "total": 3
}
```

نکات As-Is:

- این API challenge را فقط برای `امروز UTC` می‌سازد.
- `challengeDate` قابل انتخاب نیست.
- check برای سقف `challengesPerDay` ندارد.
- check برای duplicate ندارد.
- اگر کاربر امروز 6 challenge داشته باشد، ادمین می‌تواند challenge هفتم هم بسازد.

### 7.1.3 ویرایش challenge دستی

- `PUT /api/admin/challenges/{id}`

body:

```ts
export interface AdminDailyChallengeUpdateRequest {
  type?: string;
  gameId?: string;
  difficulty?: string;
  reward?: number;
  xpReward?: number;
  total?: number;
  status?: string;
}
```

نکات As-Is:

- اگر `type` یا `gameId` یا `total` عوض شود، `titleKey/descKey` regenerate می‌شود.
- تغییر `status` side-effect مالی ایجاد نمی‌کند.
- تغییر `status` لزوما `completedAt` یا `claimedAt` را sync نمی‌کند.
- این endpoint برای عملیات مالی یا reconciliation مناسب نیست؛ فقط data patch است.

### 7.1.4 حذف challenge

- `DELETE /api/admin/challenges/{id}`

response:

```json
{ "message": "Challenge deleted successfully" }
```

نکته:

- حذف challenge هیچ rollback مالی یا اصلاح stats انجام نمی‌دهد.

## 7.2 Challenge Stats API

- `GET /api/admin/challenges/stats?fromDate=2026-03-01&toDate=2026-03-08`

response:

```ts
export interface AdminChallengeBreakdownItemDto {
  total: number;
  completed: number;
  rate: number;
}

export interface AdminChallengeGameBreakdownDto {
  gameId: string;
  total: number;
  completed: number;
  rate: number;
}

export interface AdminChallengeStatsDto {
  totalGenerated: number;
  totalCompleted: number;
  totalClaimed: number;
  totalExpired: number;
  completionRate: number;
  claimRate: number;
  totalRewardsPaid: number;
  totalXpPaid: number;
  avgCompletionTimeMinutes: number;
  byType: Record<string, AdminChallengeBreakdownItemDto>;
  byDifficulty: Record<string, AdminChallengeBreakdownItemDto>;
  byGame: AdminChallengeGameBreakdownDto[];
}
```

قواعد محاسبه:

- `completionRate = totalCompleted / totalGenerated * 100`
- `claimRate = totalClaimed / totalCompleted * 100`
- `avgCompletionTimeMinutes` فقط از challengeهایی حساب می‌شود که `createdAt` و `completedAt` دارند
- `totalRewardsPaid` و `totalXpPaid` فقط challenge claimها نیست؛ complete-all, daily-login و streak-milestone را هم جمع می‌کند

## 7.3 Challenge Templates API

### 7.3.1 لیست templateها

- `GET /api/admin/challenge-templates`

query params:

- `page`
- `size`
- `type`
- `gameId`
- `difficulty`
- `isActive`
- `sortBy`
- `sortDir`

`sortBy`های معتبر:

- `id`
- `createdAt`
- `updatedAt`
- `type`
- `gameId`
- `difficulty`
- `weight`
- `isActive`
- `baseReward`
- `baseXpReward`
- `minTarget`
- `maxTarget`

response:

- Spring `Page<ChallengeTemplateDto>`

### 7.3.2 مدل template

```ts
export interface ChallengeTemplateDto {
  id: number;
  type: string;
  gameId: string;
  difficulty: string;
  titleKey: string;
  descKey: string;
  minTarget: number;
  maxTarget: number;
  baseReward: number;
  baseXpReward: number;
  rewardMultiplier: number;
  isActive: boolean;
  weight: number;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export interface ChallengeTemplateUpsertRequest {
  type: string;
  gameId: string;
  difficulty: string;
  titleKey: string;
  descKey: string;
  minTarget: number;
  maxTarget: number;
  baseReward: number;
  baseXpReward: number;
  rewardMultiplier: number;
  isActive: boolean;
  weight: number;
}
```

validation rules:

- `type` باید یکی از `PLAY|WIN|STREAK|SCORE` باشد
- `difficulty` باید یکی از `EASY|MEDIUM|HARD` باشد
- `gameId` باید در game configs backend وجود داشته باشد
- `minTarget > 0`
- `maxTarget > 0`
- `minTarget <= maxTarget`
- `baseReward >= 0`
- `baseXpReward >= 0`
- `rewardMultiplier > 0`
- `weight > 0`
- `titleKey` باید placeholder `{target}` داشته باشد
- `descKey` باید placeholder `{target}` داشته باشد

مثال:

```json
{
  "type": "WIN",
  "gameId": "backgammon",
  "difficulty": "MEDIUM",
  "titleKey": "challenge.win.backgammon.{target}.title",
  "descKey": "challenge.win.backgammon.{target}.desc",
  "minTarget": 2,
  "maxTarget": 4,
  "baseReward": 25,
  "baseXpReward": 150,
  "rewardMultiplier": 1.5,
  "isActive": true,
  "weight": 3
}
```

APIها:

- `POST /api/admin/challenge-templates`
- `PUT /api/admin/challenge-templates/{id}`
- `DELETE /api/admin/challenge-templates/{id}`

نکته:

- delete template، response `204 No Content` دارد.

## 7.4 Challenge Config API

- `GET /api/admin/challenge-config`
- `PUT /api/admin/challenge-config`

مدل:

```ts
export interface ChallengeConfigWeeklyRewardDto {
  day: number;
  reward: number;
}

export interface ChallengeConfigStreakMilestoneDto {
  streak: number;
  reward: number;
}

export interface ChallengeConfigDto {
  challengesPerDay: number;
  easyCount: number;
  mediumCount: number;
  hardCount: number;
  completeAllBonusReward: number;
  completeAllBonusXp: number;
  resetHourUtc: number;
  weeklyRewards: ChallengeConfigWeeklyRewardDto[];
  streakMilestones: ChallengeConfigStreakMilestoneDto[];
}
```

validation rules:

- `challengesPerDay > 0`
- `easyCount >= 0`
- `mediumCount >= 0`
- `hardCount >= 0`
- `easyCount + mediumCount + hardCount == challengesPerDay`
- `completeAllBonusReward >= 0`
- `completeAllBonusXp >= 0`
- `resetHourUtc` بین `0..23`
- `weeklyRewards` خالی نباشد
- dayهای weekly reward یکتا و در بازه `1..7`
- `streakMilestones` خالی نباشد
- streakهای milestone یکتا و مثبت باشند

defaultهای runtime اگر config وجود نداشته باشد:

- `challengesPerDay = 6`
- `easyCount = 2`
- `mediumCount = 2`
- `hardCount = 2`
- `completeAllBonusReward = 50`
- `completeAllBonusXp = 300`
- `resetHourUtc = 0`

---

## 8. توصیه‌ی UX و state management برای فرانت

## 8.1 صفحه کاربر

پیشنهاد layout:

1. summary header
2. challenge list today
3. complete-all bonus card
4. weekly login rewards + streak milestones
5. history tab
6. leaderboard tab

## 8.2 رفتار state

- key اصلی row فقط `challengeId`
- برای eventهای `CHALLENGE_PROGRESS_UPDATED` و `CHALLENGE_COMPLETED` patch جزئی کافی است
- برای `DAILY_CHALLENGES_RESET` و خطاهای expiry بهتر است reload کامل بزنید
- اگر global wallet/xp store دارید، success responseهای claim باید آن store را sync کنند

## 8.3 title/description challenge

در runtime فعلی:

- backend `titleKey/descKey` semantic می‌فرستد
- ولی translation key متناظر در ARB فعلی وجود ندارد
- در history ممکن است هنوز keyهای legacy از جنس `challenge.cN.title|desc` هم وجود داشته باشد

توصیه:

- اگر key از نوع legacy بود، title/description عمومی slot-style نمایش بده
- در غیر این صورت متن challenge را از `type + gameId + total` fallback بساز
- `titleKey/descKey` را صرفا metadata در نظر بگیر، نه source قطعی UI text

پیشنهاد fallback:

- title: `{typeLabel} در {gameLabel}`
- description:
  - PLAY: `X بازی در Y انجام بده`
  - WIN: `X بازی در Y ببر`
  - STREAK: `در Y استریک X برد بگیر`
  - SCORE: `در Y به امتیاز X برس`

## 8.4 timezone

- منطق backend برای challenge date و claimها روی `UTC` است
- `expiresAt` را بر اساس UTC تفسیر کن
- UI می‌تواند localize کند، ولی rule engine باید UTC را truth بداند

---

## 9. GAPها و نکات As-Is که باید شفاف بمانند

### GAP-001: resetHourUtc فقط broadcast را کنترل می‌کند، نه expiry واقعی challenge

As-Is:

- `resetHourUtc` در scheduler برای emit `DAILY_CHALLENGES_RESET` استفاده می‌شود
- ولی expiry واقعی challenge و `expiresAt` در `DailyChallengeService` با `UTC midnight` محاسبه می‌شود

اثر:

- اگر `resetHourUtc != 0` باشد، event reset و انقضای واقعی data ممکن است هم‌زمان نباشند

توصیه فرانت:

- `expiresAt` payload را truth اصلی بدان
- `DAILY_CHALLENGES_RESET` را فقط trigger reload فرض کن

### GAP-002: دو contract متفاوت برای Daily Login Reward وجود دارد

As-Is:

- WS challenge flow:
  - integer reward
  - XP هم می‌دهد
  - response شامل `newXp`
- REST daily reward flow:
  - decimal amount با currency
  - day7 multiplier دارد
  - XP ندارد
  - idempotency header دارد

اثر:

- یک business capability با دو contract و دو reward semantics متفاوت وجود دارد

توصیه:

- برای web challenge screen فقط یکی را انتخاب کن
- بدون تصمیم محصولی، این دو flow را merge نکن

### GAP-003: titleKey/descKey semantic هستند ولی translation bundle متناظر فعلا وجود ندارد

As-Is:

- keyها از جنس `challenge.win.backgammon.3.title` هستند
- در ARB فعلی translation dynamic متناظر برای این keyها وجود ندارد

اثر:

- اگر فرانت بخواهد مستقیم با key lookup متن بسازد، به متن خالی یا fallback می‌رسد

توصیه:

- متن را client-side fallback بساز

### GAP-004: Admin challenge instance CRUD side-effect مالی و state normalization ندارد

As-Is:

- تغییر status در update لزوما `completedAt` یا `claimedAt` را درست نمی‌کند
- create/delete/update روی stats یا wallet side-effect مالی انجام نمی‌دهد

اثر:

- پنل ادمین نباید این بخش را معادل settlement یا manual payout فرض کند

توصیه:

- در UI این بخش را با label واضح مثل `Challenge Data Override` یا `Manual Challenge Instance` نمایش بده

### GAP-005: Admin create/update برای challenge instance validation سخت template/config را ندارد

As-Is:

- create/update challenge instance enum validation سفت templateها را ندارد

اثر:

- UI اگر free-text بدهد، داده‌ی ناسازگار تولید می‌شود

توصیه:

- در فرانت فقط dropdownهای controlled برای:
  - type
  - gameId
  - difficulty
  - status
استفاده شود

---

## 10. چک‌لیست اجرایی برای ایجنت فرانت

### 10.1 User Panel

- WS client با support برای reconnect و event patching
- صفحه Daily Challenges با load از `GET_DAILY_CHALLENGES`
- widget summary با `GET_DAILY_CHALLENGE_SUMMARY`
- claim actions:
  - challenge reward
  - complete all
  - daily login reward
  - streak milestone
- history با pagination
- leaderboard با REST
- fallback text برای challenge title/desc
- UTC-aware expiry rendering

### 10.2 Admin Panel

- tab `Instances`
- tab `Stats`
- tab `Templates`
- tab `Config`
- filters, sorting, pagination برای listها
- controlled forms برای enumها
- warning text روی manual override behavior

### 10.3 چیزهایی که فرانت نباید فرض کند

- تعداد challenge همیشه 6 نیست
- templateها unique نیستند
- `resetHourUtc` لزوما برابر expire واقعی data نیست
- `titleKey/descKey` لزوما text-ready نیستند
- update status در پنل ادمین reward مالی نمی‌دهد

---

## 11. جمع‌بندی تصمیم‌گیری برای پیاده‌سازی

اگر هدف شما پیاده‌سازی کامل و faithful به runtime فعلی است:

- User active challenges را با WS پیاده کن
- Leaderboard را با REST پیاده کن
- Admin را در 4 tab پیاده کن: `Instances / Stats / Templates / Config`
- Daily Login Reward را یا درون همان challenge page با WS نگه دار، یا اگر صفحه مستقل reward می‌خواهی، REST را جداگانه و شفاف پیاده کن

این ترکیب کم‌ریسک‌ترین مدل برای انطباق با backend فعلی است.
