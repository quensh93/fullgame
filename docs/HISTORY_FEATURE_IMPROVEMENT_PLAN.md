# پلن اجرایی بهبود فیچر History

## 📋 فهرست کارها

### فاز 1: پاکسازی Legacy Code (اولویت بالا)
1. ✅ حذف `GameHistoryController` (REST API deprecated)
2. ✅ حذف `GameHistoryRepository` در frontend (REST API)
3. ✅ بررسی و حذف استفاده از `GameSession` در frontend (تبدیل به `GameResult`)
4. ✅ یکپارچه کردن استفاده از `GameResult` در backend

### فاز 2: پیاده‌سازی XP History UI (اولویت بالا)
5. ✅ ایجاد مدل `XpTransaction` در frontend
6. ✅ ایجاد تب XP History در WalletPage
7. ✅ ایجاد UI برای نمایش XP transactions
8. ✅ اضافه کردن WebSocket handler برای XP History در backend (اگر نیاز باشد)

### فاز 3: اضافه کردن فیلترها و Pagination (اولویت بالا)
9. ✅ اضافه کردن فیلتر بر اساس نوع بازی در Game History
10. ✅ اضافه کردن فیلتر بر اساس تاریخ در Game History
11. ✅ اضافه کردن فیلتر بر اساس نتیجه (برد/باخت) در Game History
12. ✅ اضافه کردن Pagination در Game History
13. ✅ اضافه کردن فیلتر بر اساس نوع تراکنش در Transaction History
14. ✅ اضافه کردن فیلتر بر اساس تاریخ در Transaction History
15. ✅ اضافه کردن Pagination در Transaction History

### فاز 4: بهبود Performance (اولویت متوسط)
16. ✅ اضافه کردن Database Indexes برای History queries
17. ✅ بهینه‌سازی `getRecentResultsByUser()` در backend
18. ✅ اضافه کردن Pagination در backend WebSocket handlers
19. ✅ اضافه کردن Validation برای limit parameters

### فاز 5: بهبود UI/UX (اولویت متوسط)
20. ✅ اضافه کردن Pull-to-refresh در Game History
21. ✅ اضافه کردن Pull-to-refresh در Transaction History
22. ✅ اضافه کردن Skeleton Loading
23. ✅ بهبود Dialog جزئیات بازی (scrollable)
24. ✅ اضافه کردن Relative Time نمایش (مثلاً "2 ساعت پیش")
25. ✅ اضافه کردن Grouping تراکنش‌ها بر اساس تاریخ

### فاز 6: بهبود Error Handling (اولویت متوسط)
26. ✅ اضافه کردن Retry Mechanism
27. ✅ بهبود Error Messages
28. ✅ اضافه کردن Error Logging با LogService

### فاز 7: بهبود Code Quality (اولویت پایین)
29. ✅ استخراج Helper Methods برای Format کردن GameResult
30. ✅ حذف Code Duplication
31. ✅ بهبود Logging در Backend

---

## 🎯 جزئیات اجرایی

### فاز 1: پاکسازی Legacy Code

#### 1.1 حذف GameHistoryController
- فایل: `gameBackend/src/main/java/com/gameapp/game/controllers/GameHistoryController.java`
- دلیل: REST API deprecated است، فقط WebSocket استفاده می‌شود

#### 1.2 حذف GameHistoryRepository در Frontend
- فایل: `gameapp/lib/features/game/data/repositories/game_history_repository.dart`
- دلیل: فقط WebSocket استفاده می‌شود

#### 1.3 بررسی استفاده از GameSession
- بررسی تمام استفاده‌ها از `GameSession` در frontend
- تبدیل به `GameResult` یا نگه داشتن فقط برای backward compatibility

### فاز 2: پیاده‌سازی XP History UI

#### 2.1 ایجاد مدل XpTransaction در Frontend
- فایل: `gameapp/lib/features/wallet/data/models/xp_transaction_model.dart`
- شامل: id, userId, type, amount, xpAfter, createdAt

#### 2.2 ایجاد تب XP History
- اضافه کردن تب سوم در WalletPage
- ایجاد `xp_history_tab.dart`

#### 2.3 بهبود Provider
- بررسی `xpHistoryProviderV2`
- تبدیل response به `XpTransaction` model

### فاز 3: فیلترها و Pagination

#### 3.1 فیلترهای Game History
- Dropdown برای نوع بازی
- Date picker برای تاریخ
- Toggle برای برد/باخت
- State management با Riverpod

#### 3.2 Pagination
- Infinite scroll یا Load More button
- Limit و offset در backend
- Loading states

#### 3.3 فیلترهای Transaction History
- Dropdown برای نوع تراکنش
- Date range picker
- Grouping بر اساس تاریخ

### فاز 4: بهبود Performance

#### 4.1 Database Indexes
- Migration script برای indexes
- Indexes روی: game_results.finished_at, game_results.game_type, coin_transactions.created_at

#### 4.2 بهینه‌سازی Queries
- یکپارچه کردن `getRecentResultsByUser()`
- استفاده از JOIN به جای multiple queries

#### 4.3 Pagination در Backend
- اضافه کردن limit و offset parameters
- Validation برای limit (max 100)

### فاز 5: بهبود UI/UX

#### 5.1 Pull-to-refresh
- RefreshIndicator در Game History
- RefreshIndicator در Transaction History
- RefreshIndicator در XP History

#### 5.2 Skeleton Loading
- Shimmer effect برای cards
- Loading states بهتر

#### 5.3 بهبود Dialog
- Scrollable content
- Compact layout
- Better spacing

#### 5.4 Relative Time
- Helper function برای format کردن تاریخ
- "2 ساعت پیش"، "دیروز"، "3 روز پیش"

### فاز 6: Error Handling

#### 6.1 Retry Mechanism
- Retry button در error states
- Auto-retry برای network errors

#### 6.2 Error Messages
- پیام‌های واضح و کاربرپسند
- Persian error messages

#### 6.3 Error Logging
- استفاده از LogService
- Logging در catch blocks

### فاز 7: Code Quality

#### 7.1 Helper Methods
- `formatGameResultToMap()` در backend
- `formatRelativeTime()` در frontend

#### 7.2 حذف Duplication
- بررسی و حذف duplicate code
- استخراج common logic

#### 7.3 بهبود Logging
- استفاده از log.info/log.error به جای System.out.println
- Structured logging

---

## 📝 Notes

- تمام تغییرات باید با قوانین پروژه هماهنگ باشند
- استفاده از LogService برای logging
- استفاده از WebSocket به جای REST API
- Persian error messages
- Type safety در Dart
- Null safety در Dart

---

**تاریخ ایجاد**: $(date)
**نسخه**: 1.0.0
