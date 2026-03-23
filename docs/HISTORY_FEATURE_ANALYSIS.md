# گزارش کامل و دقیق فیچر History (تاریخچه)

## 📋 فهرست مطالب
1. [امکانات موجود](#امکانات-موجود)
2. [مشکلات شناسایی شده](#مشکلات-شناسایی-شده)
3. [بهبودهای پیشنهادی](#بهبودهای-پیشنهادی)
4. [امکانات جدید پیشنهادی](#امکانات-جدید-پیشنهادی)
5. [بهبودهای امکانات فعلی](#بهبودهای-امکانات-فعلی)
6. [جزئیات فنی](#جزئیات-فنی)

---

## 🎯 امکانات موجود

### Frontend (Flutter)

#### 1. **صفحه تاریخچه بازی (GameHistoryPage)**
- ✅ 3 تب: آمار (Stats)، بازی‌های اخیر (Recent)، بهترین بازی‌ها (Best)
- ✅ UI مدرن با SliverAppBar و TabBar
- ✅ نمایش آمار کلی: تعداد بازی‌ها، بردها، باخت‌ها، نرخ برد
- ✅ نمایش Achievement بر اساس win rate
- ✅ نمایش جزئیات بازی در Dialog
- ✅ نمایش اطلاعات تیم‌ها و شرکت‌کنندگان
- ✅ Empty states و Error handling

#### 2. **تب تراکنش‌ها (TransactionsTab)**
- ✅ نمایش لیست تراکنش‌های سکه
- ✅ نمایش نوع تراکنش (واریز، برداشت، پاداش، هزینه ورودی)
- ✅ نمایش مبلغ و موجودی بعد از تراکنش
- ✅ نمایش تاریخ و زمان
- ✅ Empty state
- ✅ Error handling

#### 3. **State Management (Riverpod)**
- ✅ `userGameHistoryProvider`: تاریخچه کامل بازی‌ها
- ✅ `userRecentGamesProvider`: بازی‌های اخیر
- ✅ `userBestGamesProvider`: بهترین بازی‌ها
- ✅ `userGameStatsProvider`: آمار بازی‌ها
- ✅ `transactionsProviderV2`: تراکنش‌های سکه
- ✅ `xpHistoryProviderV2`: تاریخچه XP
- ✅ WebSocket callbacks برای real-time updates

#### 4. **Models**
- ✅ `GameSession`: مدل کامل بازی با تمام فیلدها
- ✅ `CoinTransaction`: مدل تراکنش سکه
- ✅ `XpTransaction`: مدل تراکنش XP (در backend)

### Backend (Spring Boot)

#### 1. **Entity (GameResult)**
- ✅ Entity جدید برای ذخیره نتایج بازی
- ✅ پشتیبانی از بازی‌های انفرادی و تیمی
- ✅ ذخیره امتیازات شرکت‌کنندگان در JSON
- ✅ ذخیره اطلاعات تیم‌ها
- ✅ ذخیره آمار بازی (تعداد دورها، مدت زمان)

#### 2. **Entity (GameSession) - Legacy**
- ⚠️ Entity قدیمی که هنوز استفاده می‌شود
- ⚠️ Duplication با GameResult

#### 3. **Service (GameResultService)**
- ✅ `saveIndividualGameResult()`: ذخیره نتیجه بازی انفرادی
- ✅ `saveTeamGameResult()`: ذخیره نتیجه بازی تیمی
- ✅ `getRecentResultsByUser()`: دریافت بازی‌های اخیر کاربر
- ✅ `getWinCountByUser()`: شمارش بردها
- ✅ `getUserGameStats()`: آمار بازی‌های کاربر
- ✅ `getGameStatistics()`: آمار کلی بازی‌ها

#### 4. **Service (GameHistoryService)**
- ✅ `getUserGameHistory()`: تاریخچه بازی‌ها (legacy)
- ✅ `getUserGameHistoryNew()`: تاریخچه بازی‌ها (جدید)
- ✅ `getUserGameStats()`: آمار بازی‌ها
- ✅ `getUserBestGames()`: بهترین بازی‌ها
- ✅ `getUserRecentGames()`: بازی‌های اخیر

#### 5. **Service (CoinTransactionService)**
- ✅ `getUserTransactions()`: دریافت تراکنش‌های کاربر
- ✅ `createTransaction()`: ایجاد تراکنش جدید

#### 6. **Repository (GameResultRepository)**
- ✅ `findRecentResultsByWinner()`: بازی‌های برنده
- ✅ `findRecentResultsByParticipant()`: بازی‌های شرکت‌کننده
- ✅ `findResultsByParticipantInScores()`: بازی‌ها از طریق JSON scores
- ✅ `countWinsByUser()`: شمارش بردها
- ✅ `findTopPlayersByGameType()`: برترین بازیکنان

#### 7. **WebSocket Handlers (ImprovedWebSocketConfig)**
- ✅ `handleGetGameHistoryUser()`: GET_GAME_HISTORY_USER
- ✅ `handleGetGameRecentUser()`: GET_GAME_RECENT_USER
- ✅ `handleGetGameBestUser()`: GET_GAME_BEST_USER
- ✅ `handleGetGameStatsUser()`: GET_GAME_STATS_USER
- ✅ `handleGetTransactions()`: GET_TRANSACTIONS
- ✅ `handleGetXpHistory()`: GET_XP_HISTORY

---

## ⚠️ مشکلات شناسایی شده

### Frontend

#### 1. **مشکل در Game History**
- ⚠️ استفاده از `GameSession` (legacy) به جای `GameResult` (جدید)
- ⚠️ `GameHistoryRepository` هنوز از REST API استفاده می‌کند (legacy)
- ⚠️ هیچ صفحه جداگانه برای XP History وجود ندارد
- ⚠️ هیچ فیلتر یا جستجو در تاریخچه بازی وجود ندارد
- ⚠️ هیچ pagination وجود ندارد (همه بازی‌ها یکجا لود می‌شوند)
- ⚠️ هیچ sort option وجود ندارد

#### 2. **مشکل در Transaction History**
- ⚠️ هیچ فیلتر بر اساس نوع تراکنش وجود ندارد
- ⚠️ هیچ فیلتر بر اساس تاریخ وجود ندارد
- ⚠️ هیچ جستجو وجود ندارد
- ⚠️ هیچ pagination وجود ندارد
- ⚠️ نمایش تاریخ به صورت ساده (بدون relative time)

#### 3. **مشکل در XP History**
- ❌ هیچ UI برای نمایش XP History وجود ندارد
- ❌ Provider وجود دارد اما استفاده نمی‌شود
- ❌ هیچ صفحه یا تب برای XP History وجود ندارد

#### 4. **مشکل در UI/UX**
- ⚠️ هیچ pull-to-refresh وجود ندارد
- ⚠️ هیچ skeleton loading وجود ندارد
- ⚠️ هیچ infinite scroll وجود ندارد
- ⚠️ Dialog جزئیات بازی ممکن است برای بازی‌های طولانی بزرگ شود

#### 5. **مشکل در Error Handling**
- ⚠️ Error handling فقط SnackBar یا error state
- ⚠️ هیچ retry mechanism وجود ندارد
- ⚠️ هیچ offline support وجود ندارد

### Backend

#### 1. **مشکل در Duplication**
- ⚠️ هم `GameResult` (جدید) و هم `GameSession` (legacy) وجود دارند
- ⚠️ `GameHistoryService` از هر دو استفاده می‌کند
- ⚠️ `GameHistoryController` (REST API) هنوز وجود دارد اما deprecated است

#### 2. **مشکل در Performance**
- ⚠️ در `getRecentResultsByUser()`: 3 query مختلف اجرا می‌شود (room membership, JSON scores, winner)
- ⚠️ هیچ pagination وجود ندارد
- ⚠️ هیچ caching وجود ندارد
- ⚠️ Query های پیچیده ممکن است slow باشند

#### 3. **مشکل در Data Consistency**
- ⚠️ `GameResult` و `GameSession` ممکن است data inconsistency داشته باشند
- ⚠️ Migration از GameSession به GameResult کامل نیست

#### 4. **مشکل در WebSocket Handlers**
- ⚠️ در `handleGetGameHistoryUser()`: limit hardcoded به 100 است
- ⚠️ هیچ validation برای limit وجود ندارد
- ⚠️ Format کردن GameResult به Map پیچیده و تکراری است

#### 5. **مشکل در Statistics**
- ⚠️ در `getUserGameStats()`: limit 1000 برای آمار (ممکن است slow باشد)
- ⚠️ محاسبه win/loss برای بازی‌های تیمی پیچیده است
- ⚠️ هیچ caching برای statistics وجود ندارد

#### 6. **مشکل در XP History**
- ⚠️ هیچ service یا repository برای XP History وجود ندارد
- ⚠️ فقط `XpTransaction` entity وجود دارد

---

## 🔧 بهبودهای پیشنهادی

### Frontend

#### 1. **بهبود Game History**
- ✅ حذف `GameHistoryRepository` (legacy REST API)
- ✅ استفاده فقط از WebSocket
- ✅ اضافه کردن pull-to-refresh
- ✅ اضافه کردن pagination یا infinite scroll
- ✅ اضافه کردن فیلتر بر اساس نوع بازی
- ✅ اضافه کردن فیلتر بر اساس تاریخ
- ✅ اضافه کردن sort options (تاریخ، امتیاز، نوع بازی)

#### 2. **بهبود Transaction History**
- ✅ اضافه کردن فیلتر بر اساس نوع تراکنش
- ✅ اضافه کردن فیلتر بر اساس تاریخ (امروز، هفته، ماه)
- ✅ اضافه کردن جستجو
- ✅ اضافه کردن pagination
- ✅ بهبود نمایش تاریخ (relative time: "2 ساعت پیش")
- ✅ اضافه کردن grouping بر اساس تاریخ

#### 3. **پیاده‌سازی XP History**
- ✅ اضافه کردن تب XP History در WalletPage
- ✅ اضافه کردن UI برای نمایش XP transactions
- ✅ اضافه کردن فیلتر و sort

#### 4. **بهبود UI/UX**
- ✅ اضافه کردن skeleton loading
- ✅ اضافه کردن animations
- ✅ بهبود Dialog جزئیات (scrollable)
- ✅ اضافه کردن export به CSV/PDF (اختیاری)

#### 5. **بهبود Error Handling**
- ✅ اضافه کردن retry mechanism
- ✅ بهبود error messages
- ✅ اضافه کردن error logging

### Backend

#### 1. **حذف Legacy Code**
- ✅ حذف `GameHistoryController` (REST API deprecated)
- ✅ حذف `GameSession` entity (یا migration کامل)
- ✅ یکپارچه کردن استفاده از `GameResult`

#### 2. **بهبود Performance**
- ✅ اضافه کردن pagination برای queries
- ✅ اضافه کردن caching برای statistics
- ✅ بهینه‌سازی `getRecentResultsByUser()` (یک query به جای 3)
- ✅ اضافه کردن database indexes

#### 3. **بهبود WebSocket Handlers**
- ✅ اضافه کردن limit parameter (با default و max)
- ✅ اضافه کردن validation
- ✅ استخراج format کردن GameResult به یک helper method

#### 4. **بهبود Statistics**
- ✅ اضافه کردن caching
- ✅ بهینه‌سازی محاسبات
- ✅ اضافه کردن incremental updates

#### 5. **پیاده‌سازی XP History Service**
- ✅ اضافه کردن `XpHistoryService`
- ✅ اضافه کردن repository methods
- ✅ اضافه کردن WebSocket handler

---

## 🚀 امکانات جدید پیشنهادی

### Frontend

#### 1. **فیلترها و جستجو**
- فیلتر بر اساس نوع بازی
- فیلتر بر اساس تاریخ (امروز، هفته، ماه، سال، محدوده سفارشی)
- فیلتر بر اساس نتیجه (برد، باخت)
- جستجو در تاریخچه بازی‌ها
- فیلتر بر اساس نوع تراکنش
- فیلتر بر اساس مبلغ تراکنش

#### 2. **آمار پیشرفته**
- نمودار تعداد بازی‌ها بر اساس تاریخ
- نمودار win rate بر اساس تاریخ
- نمودار امتیازات بر اساس تاریخ
- آمار بر اساس نوع بازی
- آمار بر اساس زمان روز (صبح، ظهر، شب)
- آمار بر اساس روز هفته

#### 3. **مقایسه و رقابت**
- مقایسه آمار با دوستان
- Leaderboard برای هر نوع بازی
- Ranking بر اساس win rate
- Ranking بر اساس تعداد بازی‌ها

#### 4. **Export و Share**
- Export تاریخچه به CSV
- Export آمار به PDF
- Share آمار در شبکه‌های اجتماعی
- Screenshot از آمار

#### 5. **یادآوری و اعلان**
- یادآوری برای بازی نکردن (اختیاری)
- اعلان برای دستاوردهای جدید
- اعلان برای ranking changes

### Backend

#### 1. **Advanced Statistics**
- آمار بر اساس نوع بازی
- آمار بر اساس تاریخ
- آمار بر اساس زمان روز
- Trend analysis
- Predictive analytics (اختیاری)

#### 2. **Leaderboard System**
- Leaderboard برای هر نوع بازی
- Global leaderboard
- Friend leaderboard
- Weekly/Monthly leaderboards

#### 3. **Analytics Service**
- Aggregation queries
- Caching strategy
- Scheduled jobs برای pre-compute statistics

#### 4. **Export Service**
- CSV export
- PDF generation
- Data formatting

---

## 💡 بهبودهای امکانات فعلی

### Frontend

#### 1. **بهبود Game History Page**
- ✅ اضافه کردن pull-to-refresh
- ✅ اضافه کردن infinite scroll
- ✅ اضافه کردن فیلترها
- ✅ اضافه کردن sort options
- ✅ بهبود Dialog جزئیات (scrollable, compact)
- ✅ اضافه کردن skeleton loading

#### 2. **بهبود Transactions Tab**
- ✅ اضافه کردن pull-to-refresh
- ✅ اضافه کردن فیلترها
- ✅ اضافه کردن grouping (بر اساس تاریخ)
- ✅ بهبود نمایش تاریخ
- ✅ اضافه کردن search

#### 3. **بهبود Stats Tab**
- ✅ اضافه کردن charts (نمودارها)
- ✅ اضافه کردن breakdown بر اساس نوع بازی
- ✅ اضافه کردن trend indicators
- ✅ بهبود visualizations

### Backend

#### 1. **بهبود Performance**
- ✅ اضافه کردن pagination
- ✅ اضافه کردن caching
- ✅ بهینه‌سازی queries
- ✅ اضافه کردن indexes

#### 2. **بهبود Data Consistency**
- ✅ Migration کامل از GameSession به GameResult
- ✅ حذف GameSession یا نگه داشتن فقط برای backward compatibility

#### 3. **بهبود Code Quality**
- ✅ حذف duplication
- ✅ استخراج helper methods
- ✅ بهبود error handling
- ✅ بهبود logging

---

## 🔍 جزئیات فنی

### Frontend Architecture

```
lib/features/
├── game/
│   ├── ui/
│   │   └── game_history_page.dart          ✅ کامل (اما نیاز به بهبود)
│   ├── providers/
│   │   └── game_history_provider.dart      ✅ کامل (WebSocket-based)
│   └── data/
│       ├── models/
│       │   └── game_session.dart           ⚠️ Legacy (باید به GameResult تبدیل شود)
│       └── repositories/
│           └── game_history_repository.dart ⚠️ Legacy (REST API - باید حذف شود)
└── wallet/
    ├── ui/
    │   ├── wallet_page.dart                ✅ کامل
    │   └── transactions_tab.dart            ⚠️ نیاز به بهبود (فیلتر، pagination)
    └── providers/
        └── wallet_provider_v2.dart          ✅ کامل (WebSocket-based)
```

### Backend Architecture

```
src/main/java/com/gameapp/game/
├── models/
│   ├── GameResult.java                     ✅ کامل (جدید)
│   ├── GameSession.java                    ⚠️ Legacy (باید حذف یا migrate شود)
│   ├── CoinTransaction.java                ✅ کامل
│   └── XpTransaction.java                  ✅ کامل
├── repositories/
│   ├── GameResultRepository.java           ✅ کامل
│   ├── GameSessionRepository.java          ⚠️ Legacy
│   ├── CoinTransactionRepository.java      ✅ کامل
│   └── XpTransactionRepository.java        ✅ کامل
├── services/
│   ├── GameResultService.java              ✅ کامل
│   ├── GameHistoryService.java             ⚠️ Legacy + New (duplication)
│   └── CoinTransactionService.java         ✅ کامل
└── controllers/
    └── GameHistoryController.java          ⚠️ Deprecated (REST API)
```

### WebSocket Message Types

#### Frontend → Backend
- `GET_GAME_HISTORY_USER`
- `GET_GAME_RECENT_USER`
- `GET_GAME_BEST_USER`
- `GET_GAME_STATS_USER`
- `GET_TRANSACTIONS`
- `GET_XP_HISTORY`

#### Backend → Frontend
- `GAME_HISTORY_USER`
- `GAME_RECENT_USER`
- `GAME_BEST_USER`
- `GAME_STATS_USER`
- `TRANSACTIONS_LIST`
- `XP_HISTORY`

### Database Schema

```sql
-- Game Results (جدید)
CREATE TABLE game_results (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    game_room_id BIGINT NOT NULL,
    game_type VARCHAR(50) NOT NULL,
    winner_id BIGINT,
    winner_team_id INT,
    participants_scores_json TEXT,
    team_a_final_score INT,
    team_b_final_score INT,
    total_rounds INT,
    duration_minutes INT,
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Coin Transactions
CREATE TABLE coin_transactions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    amount INT NOT NULL,
    balance_after INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- XP Transactions
CREATE TABLE xp_transactions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    amount INT NOT NULL,
    xp_after INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 📊 خلاصه

### نقاط قوت
- ✅ معماری خوب با separation of concerns
- ✅ Real-time updates با WebSocket
- ✅ UI مدرن برای Game History
- ✅ Entity جدید GameResult برای نتایج بازی
- ✅ پشتیبانی از بازی‌های انفرادی و تیمی

### نقاط ضعف
- ❌ Duplication: GameResult و GameSession
- ❌ Legacy code: GameHistoryController, GameHistoryRepository
- ❌ XP History UI وجود ندارد
- ❌ فیلترها و pagination وجود ندارد
- ❌ Performance optimization نیاز دارد

### اولویت‌های بهبود
1. **بالا**: حذف Legacy Code (GameSession, GameHistoryController)
2. **بالا**: پیاده‌سازی XP History UI
3. **متوسط**: اضافه کردن فیلترها و pagination
4. **متوسط**: بهبود Performance (caching, indexes)
5. **پایین**: اضافه کردن Charts و Analytics
6. **پایین**: Export و Share features

---

**تاریخ گزارش**: $(date)
**نسخه**: 1.0.0
