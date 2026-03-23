# لیست API ها برای تبدیل به WebSocket

## 1. Authentication APIs (`AuthController`)
- [x] `POST /api/auth/signup` - ثبت‌نام (نگه‌داری - فقط یکبار استفاده می‌شود)
- [x] `POST /api/auth/login` - ورود (نگه‌داری - فقط یکبار استفاده می‌شود)
- [x] `POST /api/auth/logout` - خروج (نگه‌داری - فقط یکبار استفاده می‌شود)
- [x] `POST /api/auth/refresh` - رفرش توکن (نگه‌داری)
- [ ] `GET /api/auth/me` - دریافت اطلاعات کاربر → **WebSocket**
- [ ] `PATCH /api/auth/profile` - ویرایش پروفایل → **WebSocket**
- [ ] `POST /api/auth/avatar` - آپلود آواتار → **نیاز به بررسی** (ممکن است نیاز به HTTP باشد)
- [x] `GET /api/auth/check-username` - بررسی username (نگه‌داری)
- [x] `GET /api/auth/check-email` - بررسی email (نگه‌داری)
- [x] `POST /api/auth/forgot-password` - فراموشی رمز (نگه‌داری)
- [x] `POST /api/auth/reset-password` - بازنشانی رمز (نگه‌داری)

## 2. Game Room APIs (`GameRoomController`)
- [ ] `POST /api/game-room/create` - ساخت روم → **WebSocket** ✅ (قبلاً پیاده‌سازی شده)
- [ ] `POST /api/game-room/join` - جوین به روم → **WebSocket** ✅ (قبلاً پیاده‌سازی شده)
- [x] `GET /api/game-room/list` - لیست روم‌ها (Deprecated - از WebSocket استفاده می‌شود)
- [ ] `GET /api/game-room/{roomId}` - دریافت اطلاعات روم → **WebSocket**
- [ ] `POST /api/game-room/cancel` - لغو روم → **WebSocket**
- [ ] `POST /api/game-room/{roomId}/cancel` - لغو روم با ID → **WebSocket**
- [ ] `POST /api/game-room/{roomId}/start` - شروع بازی → **WebSocket** ✅ (قبلاً پیاده‌سازی شده)
- [ ] `POST /api/game-room/leave` - ترک روم → **WebSocket**

## 3. Friendship APIs (`FriendshipController`)
- [ ] `POST /api/friends/request/{userId}` - ارسال درخواست دوستی → **WebSocket**
- [ ] `POST /api/friends/accept/{senderId}` - قبول درخواست → **WebSocket**
- [ ] `POST /api/friends/reject/{senderId}` - رد درخواست → **WebSocket**
- [ ] `POST /api/friends/block/{targetUserId}` - بلاک کردن → **WebSocket**
- [ ] `POST /api/friends/unblock/{targetUserId}` - آنبلاک کردن → **WebSocket**
- [ ] `GET /api/friends/list` - لیست دوستان → **WebSocket**
- [ ] `GET /api/friends/requests` - درخواست‌های دوستی → **WebSocket**
- [ ] `POST /api/friends/respond` - پاسخ به درخواست → **WebSocket**
- [ ] `DELETE /api/friends/remove/{otherUserId}` - حذف دوست → **WebSocket**
- [ ] `GET /api/friends/search` - جستجوی کاربران → **WebSocket**

## 4. Game Invitation APIs (`GameInvitationController`)
- [ ] `POST /api/game-invitations/send` - ارسال دعوت → **WebSocket**
- [ ] `POST /api/game-invitations/accept/{id}` - قبول دعوت → **WebSocket**
- [ ] `POST /api/game-invitations/reject/{id}` - رد دعوت → **WebSocket**
- [ ] `POST /api/game-invitations/cancel/{id}` - لغو دعوت → **WebSocket**
- [ ] `GET /api/game-invitations/received` - دعوت‌های دریافتی → **WebSocket**
- [ ] `GET /api/game-invitations/sent` - دعوت‌های ارسالی → **WebSocket**

## 5. User Status APIs (`UserStatusController`)
- [x] `POST /api/user-status/online` - آنلاین شدن (از طریق WebSocket handle می‌شود)
- [x] `POST /api/user-status/offline` - آفلاین شدن (از طریق WebSocket handle می‌شود)
- [x] `POST /api/user-status/in-game` - در بازی (از طریق WebSocket handle می‌شود)
- [x] `POST /api/user-status/in-lobby` - در لابی (از طریق WebSocket handle می‌شود)
- [x] `POST /api/user-status/idle` - بیکار (از طریق WebSocket handle می‌شود)

## 6. Coin Transaction APIs (`CoinTransactionController`)
- [ ] `GET /api/transactions` - لیست تراکنش‌ها → **WebSocket**
- [ ] `POST /api/transactions/topup` - افزایش سکه → **WebSocket** (اما ممکن است نیاز به verification باشد)

## 7. Withdraw APIs (`WithdrawController`)
- [ ] `GET /api/withdraw` - لیست درخواست‌های برداشت → **WebSocket**
- [ ] `POST /api/withdraw` - ثبت درخواست برداشت → **WebSocket**
- [ ] `PATCH /api/withdraw/{id}` - به‌روزرسانی وضعیت (Admin) → **WebSocket**

## 8. XP APIs (`XpController`)
- [ ] `GET /api/xp/history` - تاریخچه XP → **WebSocket**

## 9. Game APIs (`GameController`)
- [x] `POST /api/game/start/{roomId}` - شروع بازی (از طریق game-room/start handle می‌شود)
- [ ] `GET /api/game/state/{gameStateId}` - دریافت وضعیت بازی → **WebSocket**
- [ ] `GET /api/game/state/room/{roomId}` - دریافت وضعیت بازی با roomId → **WebSocket**
- [ ] `POST /api/game/hokm/choose-trump` - انتخاب حکم → **WebSocket** ✅ (قبلاً پیاده‌سازی شده)
- [ ] `POST /api/game/shalem/bid` - امتیاز در شلم → **WebSocket**
- [ ] `POST /api/game/rps/choice` - انتخاب در RPS → **WebSocket** ✅ (قبلاً پیاده‌سازی شده)
- [ ] `POST /api/game/play-card` - بازی کردن کارت → **WebSocket**
- [ ] `POST /api/game/backgammon/roll-dice` - پرتاب تاس → **WebSocket**
- [ ] `POST /api/game/backgammon/move-piece` - حرکت مهره → **WebSocket**
- [ ] `POST /api/game/end-game` - پایان بازی → **WebSocket**

---

## خلاصه اولویت‌بندی

### اولویت بالا (Core Features)
1. Game Room: `getRoomById`, `leave`, `cancel`
2. Friends: `list`, `requests`, `search`, `request`, `accept`, `reject`, `remove`
3. Game Invitations: همه endpointها
4. Auth: `me`, `profile`

### اولویت متوسط (Wallet & Transactions)
1. Coin Transactions: `getTransactions`
2. Withdraw: `getWithdraws`, `requestWithdraw`
3. XP: `history`

### اولویت پایین (Game State)
1. Game: `getGameState`, `getGameStateByRoomId`

### نیاز به بررسی بیشتر
1. Avatar upload (ممکن است نیاز به HTTP باشد)
2. Topup (ممکن است نیاز به payment gateway باشد)

---

## استراتژی Migration

### Phase 1: Game Room (در دست انجام)
- [x] Create room
- [x] Join room
- [x] Start game
- [ ] Get room by ID
- [ ] Leave room
- [ ] Cancel room

### Phase 2: Friends & Social
- [ ] Friends list
- [ ] Friend requests
- [ ] Search users
- [ ] Send/accept/reject friend requests
- [ ] Block/unblock users
- [ ] Remove friend

### Phase 3: Game Invitations
- [ ] Send invitation
- [ ] Accept/reject invitation
- [ ] Cancel invitation
- [ ] List sent/received invitations

### Phase 4: Profile & Wallet
- [ ] Get user profile
- [ ] Update profile
- [ ] Transaction history
- [ ] Withdraw requests
- [ ] XP history

### Phase 5: Game State (اگر لازم باشد)
- [ ] Get game state
- [ ] Real-time game state updates

---

## نکات مهم

1. **Authentication**: Login/Signup/Logout باید REST API بمانند چون یکبار استفاده می‌شوند
2. **File Upload**: Avatar upload احتمالاً باید REST API بماند
3. **Payment**: Topup ممکن است نیاز به REST API برای integration با payment gateway داشته باشد
4. **WebSocket Messages**: برای هر API، یک message type مشخص تعریف می‌کنیم
5. **Error Handling**: باید error handling مناسب برای WebSocket پیاده‌سازی شود
6. **Reconnection**: باید reconnection logic و state synchronization پیاده‌سازی شود

