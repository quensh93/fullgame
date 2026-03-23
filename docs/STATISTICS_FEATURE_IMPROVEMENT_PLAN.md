# پلن اجرایی بهبود فیچر Statistics (آمار)

## 📋 فهرست کارها

### فاز 1: رفع مشکلات اصلی Backend (اولویت بالا)
1. ⬜ اضافه کردن `gameStats` به `handleGetProfile()` در backend
2. ⬜ اضافه کردن متد `getUserGameStatsByType()` در `GameResultService`
3. ⬜ اضافه کردن آمار بر اساس نوع بازی در `getUserGameStats()`
4. ⬜ اضافه کردن آمار بر اساس تاریخ در `getUserGameStats()`
5. ⬜ محاسبه Win Streak (برد متوالی) در `getUserGameStats()`
6. ⬜ حذف Legacy Code: `GameHistoryService.getUserGameStats()` (legacy)

### فاز 2: بهبود محاسبات و آمار پیشرفته (اولویت بالا)
7. ⬜ محاسبه Best Score (بهترین امتیاز) در `getUserGameStats()`
8. ⬜ محاسبه Average Score (میانگین امتیاز) در `getUserGameStats()`
9. ⬜ محاسبه Total Play Time (کل زمان بازی) در `getUserGameStats()`
10. ⬜ محاسبه Favorite Game Type (بازی محبوب) در `getUserGameStats()`
11. ⬜ بهینه‌سازی محاسبه win/loss برای بازی‌های تیمی

### فاز 3: بهبود Frontend - Game History Stats Tab (اولویت بالا)
12. ⬜ اضافه کردن Breakdown بر اساس نوع بازی در Stats Tab
13. ⬜ نمایش `averageDuration` و `lastPlayed` در Stats Tab
14. ⬜ محاسبه و نمایش Win Streak واقعی (جایگزین hardcoded)
15. ⬜ اضافه کردن فیلتر بازه زمانی (امروز، هفته، ماه، سال)
16. ⬜ اضافه کردن Pie Chart برای breakdown بر اساس نوع بازی
17. ⬜ اضافه کردن Line Chart برای trend بر اساس تاریخ

### فاز 4: بهبود Frontend - Profile Page (اولویت بالا)
18. ⬜ اطمینان از دریافت `gameStats` از backend در Profile
19. ⬜ اضافه کردن Win Rate برای هر نوع بازی در Profile
20. ⬜ اضافه کردن جزئیات بیشتر برای هر نوع بازی (average duration, last played)
21. ⬜ بهبود UI برای نمایش آمار در Profile

### فاز 5: بهبود Performance (اولویت متوسط)
22. ⬜ اضافه کردن Caching برای statistics در backend
23. ⬜ بهینه‌سازی Query های statistics
24. ⬜ اضافه کردن Database Indexes برای statistics queries
25. ⬜ کاهش limit از 1000 به مقدار منطقی‌تر (مثلاً 500)
26. ⬜ اضافه کردن Lazy Loading برای charts در frontend

### فاز 6: بهبود UI/UX - Charts و Visualizations (اولویت متوسط)
27. ⬜ اضافه کردن `fl_chart` package به `pubspec.yaml`
28. ⬜ اضافه کردن Bar Chart برای مقایسه برد/باخت
29. ⬜ اضافه کردن Radar Chart برای مقایسه عملکرد در انواع بازی
30. ⬜ اضافه کردن Heatmap برای فعالیت بر اساس روز هفته
31. ⬜ بهبود Animations برای charts

### فاز 7: بهبود Code Quality (اولویت متوسط)
32. ⬜ استخراج Helper Methods برای محاسبه statistics
33. ⬜ حذف Code Duplication بین `GameResultService` و `GameHistoryService`
34. ⬜ بهبود Error Handling در statistics calculations
35. ⬜ اضافه کردن Unit Tests برای statistics calculations (اختیاری)

### فاز 8: امکانات پیشرفته (اولویت پایین)
36. ⬜ اضافه کردن Leaderboard برای هر نوع بازی
37. ⬜ اضافه کردن مقایسه آمار با دوستان
38. ⬜ اضافه کردن Export آمار به CSV/PDF
39. ⬜ اضافه کردن Share آمار در شبکه‌های اجتماعی

---

## 🎯 جزئیات اجرایی

### فاز 1: رفع مشکلات اصلی Backend

#### 1.1 اضافه کردن `gameStats` به `handleGetProfile()`
**فایل**: `gameBackend/src/main/java/com/gameapp/game/ImprovedWebSocketConfig.java`

**تغییرات**:
- در متد `handleGetProfile()`:
  - فراخوانی `GameResultService.getUserGameStatsByType(user)`
  - تبدیل نتیجه به `Map<String, GameStats>`
  - اضافه کردن `gameStats` به `profile` map

**کد نمونه**:
```java
private void handleGetProfile(WebSocketSession session, Map<String, Object> data) throws Exception {
    // ... existing code ...
    
    // اضافه کردن gameStats
    Map<String, Object> gameStatsMap = gameResultService.getUserGameStatsByType(user);
    profile.put("gameStats", gameStatsMap);
    
    messageHandler.sendSuccess(session, "USER_PROFILE", profile);
}
```

#### 1.2 اضافه کردن متد `getUserGameStatsByType()` در `GameResultService`
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- ایجاد متد جدید `getUserGameStatsByType(User user)`
- محاسبه آمار برای هر نوع بازی:
  - تعداد بازی‌ها
  - تعداد بردها
  - تعداد باخت‌ها
- بازگشت `Map<String, Map<String, Object>>` با فرمت:
  ```java
  {
    "HOKM": { "played": 30, "wins": 20, "losses": 10 },
    "ROCK_PAPER_SCISSORS": { "played": 70, "wins": 40, "losses": 30 }
  }
  ```

**الگوریتم**:
1. دریافت تمام `GameResult` های کاربر
2. Grouping بر اساس `gameType`
3. برای هر نوع بازی:
   - شمارش کل بازی‌ها
   - شمارش بردها (بر اساس winner یا winnerTeamId)
   - شمارش باخت‌ها (total - wins)

#### 1.3 اضافه کردن آمار بر اساس نوع بازی در `getUserGameStats()`
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- اضافه کردن `gamesByType` به response
- استفاده از `getUserGameStatsByType()` برای محاسبه

#### 1.4 اضافه کردن آمار بر اساس تاریخ در `getUserGameStats()`
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- اضافه کردن `gamesByMonth` به response
- Grouping بر اساس `finishedAt` (ماه/سال)
- فرمت: `Map<String, Long>` با کلید `"YYYY-MM"`

#### 1.5 محاسبه Win Streak (برد متوالی)
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- اضافه کردن متد `calculateWinStreak(List<GameResult> games, User user)`
- مرتب‌سازی بازی‌ها بر اساس `finishedAt` (نزولی)
- شمارش بردهای متوالی از آخرین بازی

**الگوریتم**:
```java
int winStreak = 0;
for (GameResult game : gamesSortedByDate) {
    if (isWinner(game, user)) {
        winStreak++;
    } else {
        break; // اولین باخت، streak تمام می‌شود
    }
}
```

#### 1.6 حذف Legacy Code
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameHistoryService.java`

**تغییرات**:
- حذف یا deprecate کردن `getUserGameStats(Long userId)` (legacy)
- بررسی استفاده‌ها و جایگزینی با `GameResultService.getUserGameStats()`

---

### فاز 2: بهبود محاسبات و آمار پیشرفته

#### 2.1 محاسبه Best Score
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- اضافه کردن `bestScore` به response
- پیدا کردن بالاترین امتیاز از `participantsScoresJson`
- برای بازی‌های تیمی: استفاده از `teamAFinalScore` یا `teamBFinalScore`

#### 2.2 محاسبه Average Score
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- اضافه کردن `averageScore` به response
- محاسبه میانگین امتیاز از `participantsScoresJson`

#### 2.3 محاسبه Total Play Time
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- اضافه کردن `totalPlayTimeMinutes` به response
- جمع کردن `durationMinutes` تمام بازی‌ها

#### 2.4 محاسبه Favorite Game Type
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- اضافه کردن `favoriteGameType` به response
- پیدا کردن نوع بازی با بیشترین تعداد بازی

#### 2.5 بهینه‌سازی محاسبه win/loss برای بازی‌های تیمی
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- استخراج متد `isUserWinner(GameResult game, User user)`
- Cache کردن `GameRoom.players` برای جلوگیری از query های تکراری
- استفاده از Map برای ذخیره `userId -> teamId` mapping

---

### فاز 3: بهبود Frontend - Game History Stats Tab

#### 3.1 اضافه کردن Breakdown بر اساس نوع بازی
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- اضافه کردن Section "آمار بر اساس نوع بازی"
- استفاده از `stats['gamesByType']` از backend
- نمایش Card برای هر نوع بازی با:
  - نام بازی
  - تعداد بازی‌ها
  - تعداد بردها
  - تعداد باخت‌ها
  - Win Rate

#### 3.2 نمایش `averageDuration` و `lastPlayed`
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- اضافه کردن Card برای "میانگین مدت زمان بازی"
- اضافه کردن Card برای "آخرین بازی"
- استفاده از `DateFormatter.formatRelativeTime()` برای `lastPlayed`

#### 3.3 محاسبه و نمایش Win Streak واقعی
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- استفاده از `stats['winStreak']` از backend
- جایگزین کردن hardcoded value در `_buildInsightCard()`
- نمایش "X برد متوالی" به جای hardcoded

#### 3.4 اضافه کردن فیلتر بازه زمانی
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- اضافه کردن `_selectedTimeRange` state (امروز، هفته، ماه، سال، همه)
- اضافه کردن Dropdown برای انتخاب بازه زمانی
- فیلتر کردن `gamesByMonth` بر اساس بازه انتخاب شده
- ارسال `timeRange` به backend در `GET_GAME_STATS_USER` (اگر نیاز باشد)

#### 3.5 اضافه کردن Pie Chart برای breakdown
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- اضافه کردن `fl_chart` package
- ایجاد `_buildGamesByTypePieChart()` widget
- استفاده از `PieChart` از `fl_chart`
- نمایش درصد هر نوع بازی

#### 3.6 اضافه کردن Line Chart برای trend
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- ایجاد `_buildGamesByMonthLineChart()` widget
- استفاده از `LineChart` از `fl_chart`
- نمایش روند تعداد بازی‌ها بر اساس ماه

---

### فاز 4: بهبود Frontend - Profile Page

#### 4.1 اطمینان از دریافت `gameStats` از backend
**فایل**: `gameapp/lib/features/profile/providers/profile_provider_v2.dart`

**تغییرات**:
- بررسی اینکه `gameStats` در response وجود دارد
- Logging در صورت نبودن `gameStats`
- Fallback به empty map

#### 4.2 اضافه کردن Win Rate برای هر نوع بازی
**فایل**: `gameapp/lib/features/profile/ui/profile_page.dart`

**تغییرات**:
- محاسبه Win Rate برای هر نوع بازی: `(wins / played) * 100`
- نمایش Win Rate در Card هر نوع بازی
- استفاده از Progress Indicator برای نمایش Win Rate

#### 4.3 اضافه کردن جزئیات بیشتر
**فایل**: `gameapp/lib/features/profile/ui/profile_page.dart`

**تغییرات**:
- اضافه کردن ExpansionTile برای هر نوع بازی
- نمایش جزئیات:
  - Average Duration
  - Last Played
  - Best Score (اگر موجود باشد)
- استفاده از `DateFormatter` برای نمایش تاریخ

#### 4.4 بهبود UI
**فایل**: `gameapp/lib/features/profile/ui/profile_page.dart`

**تغییرات**:
- بهبود Card layout
- اضافه کردن Icons برای هر نوع بازی
- اضافه کردن Colors مختلف برای هر نوع بازی
- بهبود Typography

---

### فاز 5: بهبود Performance

#### 5.1 اضافه کردن Caching برای statistics
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- استفاده از `@Cacheable` برای `getUserGameStats()`
- Cache key: `"userStats:${user.getId()}"`
- Cache TTL: 5 دقیقه (قابل تنظیم)

**نکته**: نیاز به Spring Cache (Redis یا Caffeine)

#### 5.2 بهینه‌سازی Query های statistics
**فایل**: `gameBackend/src/main/java/com/gameapp/game/repositories/GameResultRepository.java`

**تغییرات**:
- اضافه کردن Native Query برای آمار بر اساس نوع بازی
- استفاده از Aggregation queries
- کاهش تعداد queries

#### 5.3 اضافه کردن Database Indexes
**فایل**: `gameBackend/src/main/resources/db/migration/V13__add_statistics_indexes.sql`

**تغییرات**:
```sql
-- Indexes for statistics queries
CREATE INDEX IF NOT EXISTS idx_game_results_user_finished ON game_results(user_id, finished_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_results_type_finished ON game_results(game_type, finished_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_results_winner_finished ON game_results(winner_id, finished_at DESC);
```

#### 5.4 کاهش limit
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- تغییر limit از 1000 به 500 در `getUserGameStats()`
- اضافه کردن parameter برای limit (قابل تنظیم)
- Validation برای limit (min: 1, max: 1000)

#### 5.5 اضافه کردن Lazy Loading برای charts
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- استفاده از `FutureBuilder` برای charts
- Lazy loading: فقط زمانی که tab باز می‌شود
- Caching chart data

---

### فاز 6: بهبود UI/UX - Charts و Visualizations

#### 6.1 اضافه کردن `fl_chart` package
**فایل**: `gameapp/pubspec.yaml`

**تغییرات**:
```yaml
dependencies:
  fl_chart: ^0.68.0
```

#### 6.2 اضافه کردن Bar Chart
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- ایجاد `_buildWinsLossesBarChart()` widget
- استفاده از `BarChart` از `fl_chart`
- نمایش مقایسه برد/باخت

#### 6.3 اضافه کردن Radar Chart
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- ایجاد `_buildPerformanceRadarChart()` widget
- استفاده از `RadarChart` از `fl_chart`
- نمایش عملکرد در انواع مختلف بازی

#### 6.4 اضافه کردن Heatmap
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- ایجاد `_buildActivityHeatmap()` widget
- Custom widget برای Heatmap (fl_chart ندارد)
- نمایش فعالیت بر اساس روز هفته و ساعت

#### 6.5 بهبود Animations
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- اضافه کردن `AnimatedContainer` برای cards
- اضافه کردن `Hero` animations
- بهبود transitions

---

### فاز 7: بهبود Code Quality

#### 7.1 استخراج Helper Methods
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- استخراج `isUserWinner(GameResult game, User user)`
- استخراج `getUserTeamId(GameResult game, User user)`
- استخراج `calculateWinRate(long wins, long total)`

#### 7.2 حذف Code Duplication
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameHistoryService.java`

**تغییرات**:
- حذف `getUserGameStatsNew()` (duplicate)
- استفاده از `GameResultService` به جای duplicate logic

#### 7.3 بهبود Error Handling
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/GameResultService.java`

**تغییرات**:
- اضافه کردن try-catch برای statistics calculations
- Logging errors
- Fallback values در صورت خطا

#### 7.4 اضافه کردن Unit Tests (اختیاری)
**فایل**: `gameBackend/src/test/java/com/gameapp/game/services/GameResultServiceTest.java`

**تغییرات**:
- Test برای `getUserGameStats()`
- Test برای `getUserGameStatsByType()`
- Test برای `calculateWinStreak()`

---

### فاز 8: امکانات پیشرفته (اولویت پایین)

#### 8.1 Leaderboard System
**فایل**: `gameBackend/src/main/java/com/gameapp/game/services/LeaderboardService.java` (جدید)

**تغییرات**:
- ایجاد Service جدید برای Leaderboard
- محاسبه Ranking بر اساس win rate
- محاسبه Ranking بر اساس تعداد بازی‌ها
- Caching برای Leaderboard

#### 8.2 مقایسه آمار با دوستان
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- اضافه کردن Section "مقایسه با دوستان"
- دریافت آمار دوستان از backend
- نمایش مقایسه در Chart

#### 8.3 Export آمار
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- اضافه کردن Button "Export"
- استفاده از `csv` package برای CSV
- استفاده از `pdf` package برای PDF

#### 8.4 Share آمار
**فایل**: `gameapp/lib/features/game/ui/game_history_page.dart`

**تغییرات**:
- اضافه کردن Button "Share"
- استفاده از `share_plus` package
- ایجاد Screenshot از آمار

---

## 📊 خلاصه اولویت‌ها

### اولویت بالا (فاز 1-4)
- رفع مشکلات اصلی backend
- اضافه کردن `gameStats` به profile
- بهبود محاسبات
- بهبود UI در Stats Tab و Profile

### اولویت متوسط (فاز 5-7)
- بهبود Performance
- اضافه کردن Charts
- بهبود Code Quality

### اولویت پایین (فاز 8)
- امکانات پیشرفته (Leaderboard, Export, Share)

---

## 🔄 ترتیب اجرا

1. **فاز 1**: رفع مشکلات اصلی Backend (اولویت بالا)
2. **فاز 2**: بهبود محاسبات (اولویت بالا)
3. **فاز 3**: بهبود Frontend Stats Tab (اولویت بالا)
4. **فاز 4**: بهبود Frontend Profile (اولویت بالا)
5. **فاز 5**: بهبود Performance (اولویت متوسط)
6. **فاز 6**: اضافه کردن Charts (اولویت متوسط)
7. **فاز 7**: بهبود Code Quality (اولویت متوسط)
8. **فاز 8**: امکانات پیشرفته (اولویت پایین)

---

**تاریخ ایجاد**: $(date)
**نسخه**: 1.0.0
