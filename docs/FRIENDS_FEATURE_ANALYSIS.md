# گزارش کامل و دقیق فیچر دوستان (Friends Feature)

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

#### 1. **صفحه اصلی دوستان (FriendsPage)**
- ✅ 3 تب: لیست دوستان، درخواست‌ها، جستجو
- ✅ Auto-refresh هنگام بازگشت به اپ
- ✅ دکمه Refresh دستی
- ✅ UI مدرن با Material Design

#### 2. **تب لیست دوستان (FriendsListTab)**
- ✅ نمایش لیست دوستان با آواتار
- ✅ نمایش وضعیت آنلاین/آفلاین
- ✅ نمایش بازی فعلی (currentGame)
- ✅ نمایش سطح (level)
- ✅ منوی عملیات: پیام، دعوت به بازی، حذف، بلاک
- ✅ Empty state برای لیست خالی
- ✅ Error handling و retry

#### 3. **تب درخواست‌های دوستی (FriendRequestsTab)**
- ✅ نمایش درخواست‌های ورودی
- ✅ دکمه‌های Accept/Reject
- ✅ نمایش آواتار و سطح کاربر
- ✅ Empty state
- ✅ Error handling

#### 4. **تب جستجوی کاربران (SearchUsersTab)**
- ✅ جستجو با debounce (500ms)
- ✅ حداقل 3 کاراکتر برای جستجو
- ✅ نمایش نتایج با وضعیت رابطه (FRIEND, PENDING, BLOCKED, NONE)
- ✅ دکمه‌های عملیات بر اساس وضعیت
- ✅ Empty state و error handling

#### 5. **State Management (Riverpod)**
- ✅ `FriendsNotifierV2`: مدیریت لیست دوستان
- ✅ `FriendRequestsNotifierV2`: مدیریت درخواست‌ها
- ✅ `SearchUsersNotifierV2`: مدیریت جستجو
- ✅ WebSocket callbacks برای real-time updates
- ✅ Auto-reload بعد از عملیات

#### 6. **WebSocket Integration**
- ✅ استفاده از `WebSocketManager` برای ارتباط real-time
- ✅ Callbacks برای: FRIENDS_LIST, FRIEND_REQUESTS, USER_STATUS
- ✅ Auto-reload بعد از: FRIEND_REQUEST_SENT, FRIEND_REQUEST_ACCEPTED, FRIEND_REMOVED, USER_BLOCKED, USER_UNBLOCKED

#### 7. **Models**
- ✅ `FriendModel`: مدل کامل دوست با تمام فیلدها
- ✅ `FriendRequestModel`: مدل درخواست دوستی
- ✅ `GameInvitationModel`: مدل دعوت به بازی

### Backend (Spring Boot)

#### 1. **Entity (Friendship)**
- ✅ Entity با status: PENDING, ACCEPTED, REJECTED, BLOCKED
- ✅ Helper methods: `getOtherUser()`, `isSender()`, `isReceiver()`, `isBlockedBy()`
- ✅ Unique constraint روی (sender_id, receiver_id)

#### 2. **Service (FriendshipService)**
- ✅ `sendFriendRequest()`: ارسال درخواست دوستی
- ✅ `acceptRequest()`: تایید درخواست
- ✅ `rejectRequest()`: رد درخواست
- ✅ `respondToRequest()`: پاسخ به درخواست (accept/reject)
- ✅ `getFriends()`: دریافت لیست دوستان
- ✅ `getIncomingRequests()`: دریافت درخواست‌های ورودی
- ✅ `removeFriend()`: حذف دوست
- ✅ `blockUser()`: بلاک کاربر
- ✅ `unblockUser()`: آنبلاک کاربر
- ✅ `searchUsers()`: جستجوی کاربران
- ✅ `getFriendshipInfo()`: دریافت اطلاعات رابطه

#### 3. **Repository (FriendshipRepository)**
- ✅ `findByUserIds()`: پیدا کردن رابطه بین دو کاربر
- ✅ `findBySenderAndReceiver()`: پیدا کردن رابطه خاص
- ✅ `findAcceptedFriends()`: پیدا کردن دوستان تایید شده
- ✅ `findByReceiverAndStatus()`: پیدا کردن درخواست‌ها بر اساس status
- ✅ `findAllByUserId()`: پیدا کردن تمام روابط یک کاربر

#### 4. **WebSocket Handlers (ImprovedWebSocketConfig)**
- ✅ `handleGetFriends()`: GET_FRIENDS
- ✅ `handleGetFriendRequests()`: GET_FRIEND_REQUESTS
- ✅ `handleSendFriendRequest()`: SEND_FRIEND_REQUEST
- ✅ `handleAcceptFriendRequest()`: ACCEPT_FRIEND_REQUEST
- ✅ `handleRejectFriendRequest()`: REJECT_FRIEND_REQUEST
- ✅ `handleRemoveFriend()`: REMOVE_FRIEND
- ✅ `handleBlockUser()`: BLOCK_USER
- ✅ `handleUnblockUser()`: UNBLOCK_USER
- ✅ `handleSearchUsers()`: SEARCH_USERS

#### 5. **WebSocket Broadcasting (WebSocketRoomService)**
- ✅ `broadcastFriendsUpdate()`: بروزرسانی لیست دوستان
- ✅ `broadcastFriendRequests()`: بروزرسانی درخواست‌ها
- ✅ `broadcastUserStatus()`: بروزرسانی وضعیت کاربر

#### 6. **DTOs**
- ✅ `FriendDto`: DTO برای دوست
- ✅ `FriendRequestDto`: DTO برای درخواست دوستی

---

## ⚠️ مشکلات شناسایی شده

### Frontend

#### 1. **مشکل در دعوت به بازی (Game Invitation)**
- ❌ در `friends_list_tab.dart` خط 456: TODO comment وجود دارد
- ❌ `_sendGameInvitation()` فقط یک SnackBar نشان می‌دهد و واقعاً دعوت ارسال نمی‌کند
- ❌ اطلاعات entry fee و maxPlayers از کاربر گرفته نمی‌شود
- ❌ Dialog دعوت به بازی کامل نیست

#### 2. **مشکل در Repository**
- ❌ `FriendsRepository` وجود دارد اما استفاده نمی‌شود (همه چیز از WebSocket می‌آید)
- ❌ کدهای legacy در repository باقی مانده (REST API endpoints)
- ❌ Duplication: هم REST API و هم WebSocket

#### 3. **مشکل در Error Handling**
- ⚠️ در `search_users_tab.dart` خط 549: error handling فقط SnackBar نشان می‌دهد
- ⚠️ در `friends_list_tab.dart` خط 549: error handling فقط notification provider استفاده می‌کند
- ⚠️ هیچ retry mechanism برای failed requests وجود ندارد

#### 4. **مشکل در UI/UX**
- ⚠️ در `friends_list_tab.dart` خط 228: `onTap` روی friend card هیچ کاری نمی‌کند
- ⚠️ هیچ صفحه Profile برای دوستان وجود ندارد
- ⚠️ هیچ صفحه Chat وجود ندارد (فقط SnackBar "به زودی اضافه خواهد شد")

#### 5. **مشکل در State Management**
- ⚠️ `FriendsNotificationNotifier` و `FriendRequestsNotificationNotifier` جدا هستند اما کار مشابهی انجام می‌دهند
- ⚠️ هیچ caching mechanism برای friends list وجود ندارد
- ⚠️ هیچ offline support وجود ندارد

#### 6. **مشکل در Real-time Updates**
- ⚠️ `USER_STATUS` فقط برای دوستان broadcast می‌شود، نه برای search results
- ⚠️ هیچ mechanism برای update کردن search results بعد از تغییر وضعیت وجود ندارد

### Backend

#### 1. **مشکل در Service Logic**
- ⚠️ در `FriendshipService.acceptRequest()` خط 66-77: منطق authorization پیچیده و ممکن است bug داشته باشد
- ⚠️ در `FriendshipService.respondToRequest()` خط 134-152: دو بار `getFriends()` صدا زده می‌شود (برای هر دو کاربر)
- ⚠️ در `FriendshipService.searchUsers()` خط 256: `online` همیشه false است (برای search results)

#### 2. **مشکل در WebSocket Handlers**
- ⚠️ در `handleAcceptFriendRequest()` خط 531-538: try-catch برای broadcast اما error فقط log می‌شود
- ⚠️ هیچ validation برای query length در `handleSearchUsers()` وجود ندارد
- ⚠️ هیچ rate limiting برای search requests وجود ندارد

#### 3. **مشکل در Database Queries**
- ⚠️ در `FriendshipRepository.findByUserIds()`: query ممکن است slow باشد برای تعداد زیاد friendships
- ⚠️ هیچ index روی `status` column وجود ندارد
- ⚠️ هیچ pagination برای `getFriends()` وجود ندارد

#### 4. **مشکل در Broadcasting**
- ⚠️ در `WebSocketRoomService.broadcastFriendsUpdate()`: فقط به یک کاربر broadcast می‌شود
- ⚠️ هیچ mechanism برای broadcast به تمام دوستان یک کاربر هنگام تغییر وضعیت وجود ندارد

#### 5. **مشکل در Error Handling**
- ⚠️ در `FriendshipService`: بعضی exception ها فقط RuntimeException هستند
- ⚠️ هیچ custom exception برای friendship operations وجود ندارد
- ⚠️ Error messages به فارسی و انگلیسی مخلوط هستند

#### 6. **مشکل در Security**
- ⚠️ هیچ validation برای prevent self-friend request در frontend وجود ندارد
- ⚠️ هیچ rate limiting برای friend requests وجود ندارد
- ⚠️ هیچ mechanism برای prevent spam friend requests وجود ندارد

---

## 🔧 بهبودهای پیشنهادی

### Frontend

#### 1. **بهبود Game Invitation**
- ✅ پیاده‌سازی کامل `_sendGameInvitation()` با استفاده از `WebSocketApiService`
- ✅ اضافه کردن Dialog برای انتخاب entry fee و maxPlayers
- ✅ اضافه کردن validation برای entry fee (باید کافی باشد)
- ✅ اضافه کردن loading state هنگام ارسال دعوت

#### 2. **پاکسازی Repository**
- ✅ حذف `FriendsRepository` یا تبدیل آن به legacy fallback
- ✅ حذف تمام REST API calls از repository
- ✅ استفاده فقط از WebSocket

#### 3. **بهبود Error Handling**
- ✅ اضافه کردن retry mechanism برای failed requests
- ✅ اضافه کردن error recovery strategies
- ✅ اضافه کردن user-friendly error messages
- ✅ اضافه کردن error logging به `LogService`

#### 4. **بهبود UI/UX**
- ✅ اضافه کردن صفحه Profile برای دوستان
- ✅ اضافه کردن صفحه Chat (یا حداقل placeholder)
- ✅ اضافه کردن pull-to-refresh
- ✅ اضافه کردن infinite scroll برای search results
- ✅ اضافه کردن skeleton loading

#### 5. **بهبود State Management**
- ✅ یکپارچه کردن notification providers
- ✅ اضافه کردن caching با `SharedPreferences`
- ✅ اضافه کردن offline support با local storage

#### 6. **بهبود Real-time Updates**
- ✅ اضافه کردن mechanism برای update کردن search results
- ✅ اضافه کردن optimistic updates برای actions

### Backend

#### 1. **بهبود Service Logic**
- ✅ ساده‌سازی منطق authorization در `acceptRequest()`
- ✅ بهینه‌سازی `respondToRequest()` برای جلوگیری از duplicate calls
- ✅ اضافه کردن real-time online status در `searchUsers()`

#### 2. **بهبود WebSocket Handlers**
- ✅ اضافه کردن proper error handling و broadcasting
- ✅ اضافه کردن validation برای query length
- ✅ اضافه کردن rate limiting

#### 3. **بهبود Database Queries**
- ✅ اضافه کردن index روی `status` column
- ✅ اضافه کردن pagination برای `getFriends()`
- ✅ بهینه‌سازی queries با استفاده از `@EntityGraph`

#### 4. **بهبود Broadcasting**
- ✅ اضافه کردن mechanism برای broadcast به تمام دوستان
- ✅ اضافه کردن batching برای multiple broadcasts

#### 5. **بهبود Error Handling**
- ✅ اضافه کردن custom exceptions
- ✅ یکپارچه کردن error messages (فقط فارسی یا فقط انگلیسی)
- ✅ اضافه کردن proper logging

#### 6. **بهبود Security**
- ✅ اضافه کردن validation در frontend
- ✅ اضافه کردن rate limiting
- ✅ اضافه کردن mechanism برای prevent spam

---

## 🚀 امکانات جدید پیشنهادی

### Frontend

#### 1. **صفحه Profile دوست**
- نمایش کامل اطلاعات دوست
- نمایش آمار بازی (wins, losses, win rate)
- نمایش achievements
- نمایش تاریخ دوستی
- دکمه‌های عملیات: پیام، دعوت به بازی، حذف، بلاک

#### 2. **صفحه Chat**
- چت real-time با دوستان
- ارسال استیکر
- ارسال پیام سریع
- تاریخچه چت
- Notification برای پیام‌های جدید

#### 3. **Friend Groups/Categories**
- گروه‌بندی دوستان (مثلاً: خانواده، دوستان نزدیک، هم‌تیمی‌ها)
- فیلتر کردن بر اساس گروه
- اضافه/حذف دوست از گروه

#### 4. **Friend Activity Feed**
- نمایش فعالیت‌های دوستان (شروع بازی، برد، باخت)
- نمایش achievements جدید
- نمایش level up

#### 5. **Friend Recommendations**
- پیشنهاد دوستان بر اساس:
  - دوستان مشترک
  - بازی‌های مشترک
  - سطح مشابه
  - منطقه جغرافیایی

#### 6. **Friend Statistics**
- نمایش آمار دوستان (تعداد، آنلاین، در بازی)
- نمایش نمودار فعالیت
- نمایش top friends (بر اساس بازی‌های مشترک)

#### 7. **Friend Notifications**
- Notification برای:
  - درخواست دوستی جدید
  - تایید درخواست
  - دوست آنلاین شد
  - دوست شروع به بازی کرد
  - پیام جدید

#### 8. **Friend Search Filters**
- فیلتر بر اساس:
  - وضعیت (آنلاین/آفلاین)
  - سطح
  - بازی فعلی
  - تاریخ آخرین فعالیت

### Backend

#### 1. **Friend Activity Tracking**
- ذخیره فعالیت‌های دوستان
- Query برای activity feed
- Aggregation برای statistics

#### 2. **Friend Recommendations Service**
- الگوریتم recommendation بر اساس:
  - Mutual friends
  - Common games
  - Similar level
  - Geographic proximity

#### 3. **Friend Groups/Categories**
- Entity برای FriendGroup
- Service برای مدیریت گروه‌ها
- Repository برای queries

#### 4. **Friend Statistics Service**
- Aggregation queries برای statistics
- Caching برای performance
- Real-time updates

#### 5. **Notification Service**
- Service برای مدیریت notifications
- Integration با WebSocket
- Push notifications (برای آینده)

#### 6. **Rate Limiting**
- Rate limiting برای friend requests
- Rate limiting برای search
- Rate limiting برای actions

#### 7. **Friend Activity Feed**
- Entity برای FriendActivity
- Service برای مدیریت feed
- Query optimization

#### 8. **Advanced Search**
- Full-text search
- Filtering
- Sorting
- Pagination

---

## 💡 بهبودهای امکانات فعلی

### Frontend

#### 1. **بهبود Friends List**
- ✅ اضافه کردن pull-to-refresh
- ✅ اضافه کردن infinite scroll
- ✅ اضافه کردن search در لیست دوستان
- ✅ اضافه کردن sort options (نام، سطح، آخرین فعالیت)
- ✅ اضافه کردن filter options (آنلاین، در بازی، آفلاین)

#### 2. **بهبود Friend Requests**
- ✅ اضافه کردن نمایش تاریخ درخواست
- ✅ اضافه کردن نمایش اطلاعات بیشتر sender
- ✅ اضافه کردن bulk actions (accept/reject all)
- ✅ اضافه کردن notification badge برای درخواست‌های جدید

#### 3. **بهبود Search**
- ✅ اضافه کردن search history
- ✅ اضافه کردن recent searches
- ✅ اضافه کردن suggested users
- ✅ اضافه کردن advanced filters

#### 4. **بهبود Real-time Updates**
- ✅ اضافه کردن optimistic updates
- ✅ اضافه کردن conflict resolution
- ✅ اضافه کردن offline queue

#### 5. **بهبود UI/UX**
- ✅ اضافه کردن animations
- ✅ اضافه کردن transitions
- ✅ اضافه کردن haptic feedback
- ✅ اضافه کردن accessibility features

### Backend

#### 1. **بهبود Performance**
- ✅ اضافه کردن caching برای friends list
- ✅ اضافه کردن pagination
- ✅ بهینه‌سازی queries
- ✅ اضافه کردن database indexes

#### 2. **بهبود Real-time**
- ✅ بهبود broadcasting mechanism
- ✅ اضافه کردن batching
- ✅ اضافه کردن priority queue

#### 3. **بهبود Security**
- ✅ اضافه کردن rate limiting
- ✅ اضافه کردن validation
- ✅ اضافه کردن audit logging

#### 4. **بهبود Error Handling**
- ✅ اضافه کردن custom exceptions
- ✅ اضافه کردن proper logging
- ✅ اضافه کردن error recovery

---

## 🔍 جزئیات فنی

### Frontend Architecture

```
lib/features/friends/
├── data/
│   ├── models/
│   │   ├── friend_model.dart          ✅ کامل
│   │   ├── friend_request_model.dart  ✅ کامل
│   │   └── game_invitation_model.dart ✅ کامل
│   └── repositories/
│       └── friends_repository.dart    ⚠️ Legacy (استفاده نمی‌شود)
├── providers/
│   └── friends_provider_v2.dart      ✅ کامل (WebSocket-based)
└── ui/
    ├── friends_page.dart              ✅ کامل
    ├── friends_list_tab.dart          ⚠️ نیاز به بهبود (Game Invitation)
    ├── friend_requests_tab.dart       ✅ کامل
    └── search_users_tab.dart          ✅ کامل
```

### Backend Architecture

```
src/main/java/com/gameapp/game/
├── models/
│   ├── Friendship.java               ✅ کامل
│   ├── FriendDto.java                ✅ کامل
│   └── FriendRequestDto.java         ✅ کامل
├── repositories/
│   └── FriendshipRepository.java     ✅ کامل
├── services/
│   ├── FriendshipService.java        ⚠️ نیاز به بهبود
│   └── WebSocketRoomService.java     ✅ کامل (broadcasting)
└── ImprovedWebSocketConfig.java      ✅ کامل (handlers)
```

### WebSocket Message Types

#### Frontend → Backend
- `GET_FRIENDS`
- `GET_FRIEND_REQUESTS`
- `SEND_FRIEND_REQUEST`
- `ACCEPT_FRIEND_REQUEST`
- `REJECT_FRIEND_REQUEST`
- `REMOVE_FRIEND`
- `BLOCK_USER`
- `UNBLOCK_USER`
- `SEARCH_USERS`

#### Backend → Frontend
- `FRIENDS_LIST`
- `FRIEND_REQUESTS`
- `FRIEND_REQUEST_SENT`
- `FRIEND_REQUEST_ACCEPTED`
- `FRIEND_REQUEST_REJECTED`
- `FRIEND_REMOVED`
- `USER_BLOCKED`
- `USER_UNBLOCKED`
- `USER_STATUS`
- `SEARCH_RESULTS`

### Database Schema

```sql
CREATE TABLE friendships (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    sender_id BIGINT NOT NULL,
    receiver_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL, -- PENDING, ACCEPTED, REJECTED, BLOCKED
    UNIQUE KEY unique_friendship (sender_id, receiver_id),
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id)
);
```

---

## 📊 خلاصه

### نقاط قوت
- ✅ معماری خوب با separation of concerns
- ✅ Real-time updates با WebSocket
- ✅ UI مدرن و user-friendly
- ✅ State management مناسب با Riverpod
- ✅ Error handling پایه

### نقاط ضعف
- ❌ Game Invitation کامل نیست
- ❌ Repository legacy باقی مانده
- ❌ Error handling کامل نیست
- ❌ UI features محدود (بدون Profile, Chat)
- ❌ Performance optimization نیاز دارد

### اولویت‌های بهبود
1. **بالا**: تکمیل Game Invitation
2. **بالا**: اضافه کردن Profile page
3. **متوسط**: بهبود Error Handling
4. **متوسط**: Performance optimization
5. **پایین**: اضافه کردن Chat
6. **پایین**: Friend Groups

---

**تاریخ گزارش**: $(date)
**نسخه**: 1.0.0
