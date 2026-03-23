# گزارش کامل و دقیق فیچر Statistics (آمار)

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

#### 1. **صفحه تاریخچه بازی - تب آمار (GameHistoryPage - Stats Tab)**
- ✅ Hero Stats Card با gradient background
- ✅ نمایش 3 کارت اصلی: تعداد بازی‌ها، بردها، باخت‌ها
- ✅ نمایش Win Rate (نرخ برد)
- ✅ Performance Insights Cards:
  - "بهترین عملکرد" (برد متوالی) - اما داده واقعی ندارد
  - "آخرین بازی" (باخت) - اما داده واقعی ندارد
- ✅ Achievement Card بر اساس Win Rate:
  - قهرمان (≥80%)
  - بازیکن حرفه‌ای (≥60%)
  - در حال پیشرفت (≥40%)
  - نیاز به تمرین (<40%)
- ✅ UI مدرن با animations و gradients
- ✅ Empty states و Error handling
- ✅ Skeleton Loading
- ✅ Retry Mechanism

#### 2. **صفحه پروفایل - بخش آمار بازی (ProfilePage - Game Stats Section)**
- ✅ نمایش آمار بر اساس نوع بازی (`user.gameStats`)
- ✅ برای هر نوع بازی نمایش:
  - تعداد بازی‌های انجام شده (played)
  - تعداد بردها (wins)
  - تعداد باخت‌ها (losses)
- ✅ UI با Card layout
- ⚠️ **مشکل**: `gameStats` در `UserModel` وجود دارد اما backend آن را populate نمی‌کند

#### 3. **صفحه اصلی - آمار کلی (HomePage)**
- ✅ نمایش Coins در AppBar
- ✅ نمایش XP و Level در Progress Section
- ✅ Progress bar برای Level
- ✅ نمایش اطلاعات کاربر

#### 4. **State Management (Riverpod)**
- ✅ `userGameStatsProvider`: آمار بازی‌های کاربر
- ✅ `userProfileProviderV2`: پروفایل کاربر با `gameStats`
- ✅ WebSocket callbacks برای real-time updates

#### 5. **Models**
- ✅ `GameStats`: مدل آمار بازی (played, wins, losses)
- ✅ `UserModel`: شامل `gameStats: Map<String, GameStats>`

### Backend (Spring Boot)

#### 1. **Service (GameResultService)**
- ✅ `getUserGameStats(User user)`: آمار بازی‌های کاربر
  - totalGames
  - wins
  - losses
  - winRate
  - averageDuration
  - lastPlayed
- ✅ `getGameStatistics()`: آمار کلی سیستم
  - totalGames
  - todayGames
- ✅ `getTopPlayersByGameType(String gameType)`: برترین بازیکنان

#### 2. **Service (GameHistoryService)**
- ✅ `getUserGameStatsNew(User user)`: آمار جدید (ساده)
- ⚠️ `getUserGameStats(Long userId)`: آمار قدیمی (legacy)
  - gamesByType: آمار بر اساس نوع بازی
  - gamesByMonth: آمار بر اساس ماه
- ⚠️ `getRoomGameStats(Long roomId)`: آمار روم (TODO ها)

#### 3. **Repository (GameResultRepository)**
- ✅ `countWinsByUser(User user)`: شمارش بردها
- ✅ `findTopPlayersByGameType(String gameType)`: برترین بازیکنان

#### 4. **WebSocket Handlers (ImprovedWebSocketConfig)**
- ✅ `handleGetGameStatsUser()`: GET_GAME_STATS_USER
- ⚠️ `handleGetProfile()`: GET_PROFILE - **gameStats را شامل نمی‌شود**

---

## ⚠️ مشکلات شناسایی شده

### Frontend

#### 1. **مشکل در Game History Stats Tab**
- ⚠️ "بهترین عملکرد" و "آخرین بازی" داده واقعی ندارند (hardcoded)
- ⚠️ هیچ آمار بر اساس نوع بازی نمایش داده نمی‌شود
- ⚠️ هیچ آمار بر اساس تاریخ نمایش داده نمی‌شود
- ⚠️ هیچ نمودار یا visualization وجود ندارد
- ⚠️ `averageDuration` و `lastPlayed` از backend می‌آید اما نمایش داده نمی‌شود

#### 2. **مشکل در Profile Page**
- ❌ `gameStats` در `UserModel` وجود دارد اما backend آن را populate نمی‌کند
- ❌ `handleGetProfile()` در backend فقط اطلاعات پایه کاربر را برمی‌گرداند
- ❌ هیچ WebSocket handler برای دریافت `gameStats` در profile وجود ندارد
- ⚠️ آمار فقط نمایش داده می‌شود اما هیچ جزئیات بیشتری ندارد

#### 3. **مشکل در Data Consistency**
- ⚠️ `gameStats` در frontend از `UserModel` می‌آید اما backend آن را محاسبه نمی‌کند
- ⚠️ دو منبع مختلف برای آمار:
  - `userGameStatsProvider` (از GameResultService)
  - `user.gameStats` (از UserModel - اما خالی است)

#### 4. **مشکل در UI/UX**
- ⚠️ هیچ نمودار یا chart وجود ندارد
- ⚠️ هیچ breakdown بر اساس نوع بازی در Stats Tab وجود ندارد
- ⚠️ هیچ trend analysis وجود ندارد
- ⚠️ آمار static است (real-time updates ندارد)

#### 5. **مشکل در Performance**
- ⚠️ در `getUserGameStats()`: limit 1000 برای آمار (ممکن است slow باشد)
- ⚠️ محاسبه win/loss برای بازی‌های تیمی پیچیده است (loop در loop)
- ⚠️ هیچ caching برای statistics وجود ندارد

### Backend

#### 1. **مشکل در Duplication**
- ⚠️ هم `GameResultService.getUserGameStats()` و هم `GameHistoryService.getUserGameStatsNew()` وجود دارند
- ⚠️ `GameHistoryService.getUserGameStats()` (legacy) هنوز وجود دارد
- ⚠️ آمار در دو جا محاسبه می‌شود

#### 2. **مشکل در Profile Handler**
- ❌ `handleGetProfile()` آمار بازی (`gameStats`) را شامل نمی‌شود
- ❌ باید `gameStats` را از `GameResultService` بگیرد و به profile اضافه کند

#### 3. **مشکل در Statistics Calculation**
- ⚠️ `getUserGameStats()` آمار بر اساس نوع بازی محاسبه نمی‌کند
- ⚠️ `getUserGameStats()` آمار بر اساس تاریخ محاسبه نمی‌کند
- ⚠️ `getUserGameStats()` فقط آمار کلی را برمی‌گرداند

#### 4. **مشکل در Performance**
- ⚠️ در `getUserGameStats()`: limit 1000 برای آمار
- ⚠️ محاسبه win/loss برای بازی‌های تیمی نیاز به loop در GameRoom.players دارد
- ⚠️ هیچ caching وجود ندارد
- ⚠️ Query های پیچیده ممکن است slow باشند

#### 5. **مشکل در Data Structure**
- ⚠️ `gameStats` در frontend به صورت `Map<String, GameStats>` است
- ⚠️ اما backend آن را به این فرمت برنمی‌گرداند
- ⚠️ نیاز به transformation دارد

#### 6. **مشکل در Legacy Code**
- ⚠️ `GameHistoryService.getUserGameStats()` (legacy) هنوز وجود دارد
- ⚠️ از `GameSession` استفاده می‌کند نه `GameResult`

---

## 🔧 بهبودهای پیشنهادی

### Frontend

#### 1. **بهبود Game History Stats Tab**
- ✅ اضافه کردن آمار بر اساس نوع بازی (breakdown)
- ✅ اضافه کردن نمودارها (charts):
  - Pie chart برای breakdown بر اساس نوع بازی
  - Line chart برای trend بر اساس تاریخ
  - Bar chart برای مقایسه برد/باخت
- ✅ نمایش `averageDuration` و `lastPlayed`
- ✅ محاسبه و نمایش "بهترین عملکرد" واقعی (برد متوالی)
- ✅ اضافه کردن فیلتر بر اساس بازه زمانی

#### 2. **بهبود Profile Page**
- ✅ اضافه کردن WebSocket handler برای دریافت `gameStats`
- ✅ اضافه کردن جزئیات بیشتر برای هر نوع بازی
- ✅ اضافه کردن نمودار برای هر نوع بازی
- ✅ اضافه کردن win rate برای هر نوع بازی

#### 3. **یکپارچه کردن Data Sources**
- ✅ استفاده از یک منبع واحد برای آمار
- ✅ حذف duplication
- ✅ بهبود consistency

#### 4. **بهبود UI/UX**
- ✅ اضافه کردن charts با `fl_chart` package
- ✅ اضافه کردن animations
- ✅ بهبود visualizations
- ✅ اضافه کردن real-time updates

#### 5. **بهبود Performance**
- ✅ اضافه کردن caching برای statistics
- ✅ Lazy loading برای charts
- ✅ بهینه‌سازی rendering

### Backend

#### 1. **بهبود Profile Handler**
- ✅ اضافه کردن `gameStats` به `handleGetProfile()`
- ✅ محاسبه `gameStats` از `GameResultService`
- ✅ تبدیل به فرمت `Map<String, GameStats>`

#### 2. **بهبود Statistics Calculation**
- ✅ اضافه کردن آمار بر اساس نوع بازی در `getUserGameStats()`
- ✅ اضافه کردن آمار بر اساس تاریخ در `getUserGameStats()`
- ✅ اضافه کردن آمار پیشرفته:
  - برد متوالی (win streak)
  - بهترین امتیاز
  - میانگین امتیاز
  - تعداد دورها

#### 3. **بهبود Performance**
- ✅ اضافه کردن caching برای statistics
- ✅ بهینه‌سازی محاسبه win/loss برای بازی‌های تیمی
- ✅ استفاده از aggregation queries

#### 4. **حذف Legacy Code**
- ✅ حذف `GameHistoryService.getUserGameStats()` (legacy)
- ✅ یکپارچه کردن استفاده از `GameResultService`

#### 5. **بهبود Code Quality**
- ✅ استخراج Helper Methods
- ✅ حذف duplication
- ✅ بهبود error handling

---

## 🚀 امکانات جدید پیشنهادی

### Frontend

#### 1. **نمودارها و Visualizations**
- Pie chart برای breakdown بر اساس نوع بازی
- Line chart برای trend بر اساس تاریخ (هفته، ماه، سال)
- Bar chart برای مقایسه برد/باخت
- Radar chart برای مقایسه عملکرد در انواع مختلف بازی
- Heatmap برای فعالیت بر اساس روز هفته و ساعت

#### 2. **آمار پیشرفته**
- Win Streak (برد متوالی)
- Best Score (بهترین امتیاز)
- Average Score (میانگین امتیاز)
- Total Play Time (کل زمان بازی)
- Favorite Game Type (بازی محبوب)
- Performance Trend (روند عملکرد)

#### 3. **مقایسه و رقابت**
- مقایسه آمار با دوستان
- Leaderboard برای هر نوع بازی
- Ranking بر اساس win rate
- Ranking بر اساس تعداد بازی‌ها
- Global vs Friend comparison

#### 4. **فیلترها و بازه‌های زمانی**
- فیلتر بر اساس بازه زمانی (امروز، هفته، ماه، سال، سفارشی)
- فیلتر بر اساس نوع بازی
- فیلتر بر اساس نتیجه (برد، باخت)

#### 5. **Export و Share**
- Export آمار به CSV
- Export آمار به PDF
- Share آمار در شبکه‌های اجتماعی
- Screenshot از آمار

### Backend

#### 1. **Advanced Statistics**
- آمار بر اساس نوع بازی (detailed breakdown)
- آمار بر اساس تاریخ (روز، هفته، ماه، سال)
- آمار بر اساس زمان روز (صبح، ظهر، شب)
- Win Streak calculation
- Best Score tracking
- Average Score calculation
- Performance Trend analysis

#### 2. **Leaderboard System**
- Leaderboard برای هر نوع بازی
- Global leaderboard
- Friend leaderboard
- Weekly/Monthly leaderboards
- Ranking calculation

#### 3. **Analytics Service**
- Aggregation queries
- Caching strategy
- Scheduled jobs برای pre-compute statistics
- Incremental updates

#### 4. **Performance Optimization**
- Database indexes
- Query optimization
- Caching layer
- Batch processing

---

## 💡 بهبودهای امکانات فعلی

### Frontend

#### 1. **بهبود Game History Stats Tab**
- ✅ اضافه کردن breakdown بر اساس نوع بازی
- ✅ اضافه کردن charts
- ✅ نمایش `averageDuration` و `lastPlayed`
- ✅ محاسبه win streak واقعی
- ✅ اضافه کردن فیلتر بازه زمانی

#### 2. **بهبود Profile Page**
- ✅ اضافه کردن `gameStats` از backend
- ✅ اضافه کردن جزئیات بیشتر
- ✅ اضافه کردن charts
- ✅ اضافه کردن win rate برای هر نوع بازی

#### 3. **بهبود Home Page**
- ✅ اضافه کردن quick stats card
- ✅ اضافه کردن recent achievements
- ✅ اضافه کردن performance indicators

### Backend

#### 1. **بهبود Performance**
- ✅ اضافه کردن caching
- ✅ بهینه‌سازی queries
- ✅ اضافه کردن indexes

#### 2. **بهبود Data Consistency**
- ✅ یکپارچه کردن استفاده از `GameResultService`
- ✅ حذف legacy code

#### 3. **بهبود Code Quality**
- ✅ حذف duplication
- ✅ استخراج helper methods
- ✅ بهبود error handling

---

## 🔍 جزئیات فنی

### Frontend Architecture

```
lib/features/
├── game/
│   ├── ui/
│   │   └── game_history_page.dart          ✅ Stats Tab (اما نیاز به بهبود)
│   └── providers/
│       └── game_history_provider.dart      ✅ userGameStatsProvider
├── profile/
│   ├── ui/
│   │   └── profile_page.dart               ⚠️ Game Stats Section (اما gameStats خالی است)
│   └── providers/
│       └── profile_provider_v2.dart        ✅ userProfileProviderV2
└── home/
    ├── ui/
    │   └── home_page.dart                  ✅ Basic stats (coins, xp, level)
    └── data/
        └── models/
            └── game_stats.dart             ✅ GameStats model
```

### Backend Architecture

```
src/main/java/com/gameapp/game/
├── services/
│   ├── GameResultService.java              ✅ getUserGameStats() (اما ناقص)
│   └── GameHistoryService.java             ⚠️ Legacy methods
├── repositories/
│   └── GameResultRepository.java           ✅ countWinsByUser(), findTopPlayersByGameType()
└── ImprovedWebSocketConfig.java
    ├── handleGetGameStatsUser()            ✅ GET_GAME_STATS_USER
    └── handleGetProfile()                  ❌ gameStats را شامل نمی‌شود
```

### WebSocket Message Types

#### Frontend → Backend
- `GET_GAME_STATS_USER`
- `GET_PROFILE`

#### Backend → Frontend
- `GAME_STATS_USER`
- `USER_PROFILE` (اما gameStats ندارد)

### Data Flow

#### Current Flow (Game Stats Tab)
```
Frontend: userGameStatsProvider
  ↓
WebSocket: GET_GAME_STATS_USER
  ↓
Backend: handleGetGameStatsUser()
  ↓
Backend: GameResultService.getUserGameStats()
  ↓
Backend: GameResultRepository queries
  ↓
Response: GAME_STATS_USER
  ↓
Frontend: Display in Stats Tab
```

#### Current Flow (Profile Page)
```
Frontend: userProfileProviderV2
  ↓
WebSocket: GET_PROFILE
  ↓
Backend: handleGetProfile()
  ↓
Backend: UserRepository.findById()
  ↓
Response: USER_PROFILE (بدون gameStats)
  ↓
Frontend: Display gameStats (اما خالی است)
```

#### Expected Flow (Profile Page - Fixed)
```
Frontend: userProfileProviderV2
  ↓
WebSocket: GET_PROFILE
  ↓
Backend: handleGetProfile()
  ↓
Backend: UserRepository.findById()
  ↓
Backend: GameResultService.getUserGameStatsByType()
  ↓
Backend: Transform to Map<String, GameStats>
  ↓
Response: USER_PROFILE (با gameStats)
  ↓
Frontend: Display gameStats
```

### Statistics Data Structure

#### Current (GameResultService.getUserGameStats)
```java
{
  "totalGames": 100,
  "wins": 60,
  "losses": 40,
  "winRate": 60.0,
  "averageDuration": 15,
  "lastPlayed": "2024-01-15T10:30:00"
}
```

#### Expected (Enhanced)
```java
{
  "totalGames": 100,
  "wins": 60,
  "losses": 40,
  "winRate": 60.0,
  "averageDuration": 15,
  "lastPlayed": "2024-01-15T10:30:00",
  "winStreak": 5,
  "bestScore": 1000,
  "averageScore": 500,
  "gamesByType": {
    "HOKM": { "played": 30, "wins": 20, "losses": 10 },
    "ROCK_PAPER_SCISSORS": { "played": 70, "wins": 40, "losses": 30 }
  },
  "gamesByMonth": {
    "2024-01": 50,
    "2024-02": 50
  }
}
```

#### Profile Format (Expected)
```java
{
  "id": 1,
  "username": "user1",
  "email": "user1@example.com",
  // ... other fields
  "gameStats": {
    "HOKM": { "played": 30, "wins": 20, "losses": 10 },
    "ROCK_PAPER_SCISSORS": { "played": 70, "wins": 40, "losses": 30 }
  }
}
```

---

## 📊 خلاصه

### نقاط قوت
- ✅ UI مدرن برای Stats Tab
- ✅ Achievement system بر اساس win rate
- ✅ Service برای محاسبه آمار (`GameResultService`)
- ✅ WebSocket handler برای دریافت آمار
- ✅ Model برای آمار (`GameStats`)

### نقاط ضعف
- ❌ `gameStats` در Profile populate نمی‌شود
- ❌ آمار بر اساس نوع بازی محاسبه نمی‌شود
- ❌ آمار بر اساس تاریخ محاسبه نمی‌شود
- ❌ هیچ نمودار یا visualization وجود ندارد
- ❌ "بهترین عملکرد" و "آخرین بازی" داده واقعی ندارند
- ⚠️ Duplication: `GameResultService` و `GameHistoryService`
- ⚠️ Performance: limit 1000، بدون caching

### اولویت‌های بهبود
1. **بالا**: اضافه کردن `gameStats` به `handleGetProfile()`
2. **بالا**: اضافه کردن آمار بر اساس نوع بازی در `getUserGameStats()`
3. **بالا**: اضافه کردن آمار بر اساس تاریخ
4. **متوسط**: اضافه کردن نمودارها (charts)
5. **متوسط**: محاسبه win streak و آمار پیشرفته
6. **متوسط**: بهبود Performance (caching, optimization)
7. **پایین**: Leaderboard system
8. **پایین**: Export و Share features

---

**تاریخ گزارش**: $(date)
**نسخه**: 1.0.0
