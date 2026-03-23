# حذف/Deprecate کردن REST API Controllers

## کنترلرهایی که باید نگهداری شوند (مهم برای Auth اولیه):

### 1. AuthController ✅
**نگهداری کامل** - این endpointها برای authentication اولیه ضروری هستند:
- `POST /api/auth/signup` - ثبت‌نام
- `POST /api/auth/login` - ورود
- `POST /api/auth/logout` - خروج
- `POST /api/auth/refresh` - رفرش توکن
- `GET /api/auth/check-username` - بررسی username
- `GET /api/auth/check-email` - بررسی email
- `POST /api/auth/forgot-password` - فراموشی رمز
- `POST /api/auth/reset-password` - بازنشانی رمز
- `POST /api/auth/avatar` - آپلود آواتار (نیاز به HTTP برای file upload)

**حذف از AuthController:**
- ~~`GET /api/auth/me`~~ → WebSocket: `GET_PROFILE`
- ~~`PATCH /api/auth/profile`~~ → WebSocket: `UPDATE_PROFILE`
- ~~`POST /api/auth/set-inactive-offline`~~ → از طریق heartbeat handle می‌شود

---

## کنترلرهایی که باید حذف شوند:

### 2. GameRoomController ❌
**حذف کامل** - همه از طریق WebSocket handle می‌شوند:
- ~~`POST /api/game-room/create`~~ → WebSocket
- ~~`POST /api/game-room/join`~~ → WebSocket
- ~~`GET /api/game-room/list`~~ → WebSocket
- ~~`GET /api/game-room/{roomId}`~~ → WebSocket: `GET_ROOM`
- ~~`POST /api/game-room/cancel`~~ → WebSocket: `CANCEL_ROOM`
- ~~`POST /api/game-room/{roomId}/cancel`~~ → WebSocket: `CANCEL_ROOM`
- ~~`POST /api/game-room/{roomId}/start`~~ → WebSocket
- ~~`POST /api/game-room/leave`~~ → WebSocket: `LEAVE_ROOM`
- ~~`POST /api/game-room/update-existing-rooms`~~ → Maintenance endpoint (می‌تواند حذف شود)
- ~~`GET /api/game-room/debug/all`~~ → Debug endpoint (می‌تواند حذف شود)

### 3. FriendshipController ❌
**حذف کامل** - همه از طریق WebSocket:
- ~~`POST /api/friends/request/{userId}`~~ → WebSocket: `SEND_FRIEND_REQUEST`
- ~~`POST /api/friends/accept/{senderId}`~~ → WebSocket: `ACCEPT_FRIEND_REQUEST`
- ~~`POST /api/friends/reject/{senderId}`~~ → WebSocket: `REJECT_FRIEND_REQUEST`
- ~~`POST /api/friends/block/{targetUserId}`~~ → WebSocket: `BLOCK_USER`
- ~~`POST /api/friends/unblock/{targetUserId}`~~ → WebSocket: `UNBLOCK_USER`
- ~~`GET /api/friends/list`~~ → WebSocket: `GET_FRIENDS`
- ~~`GET /api/friends/requests`~~ → WebSocket: `GET_FRIEND_REQUESTS`
- ~~`POST /api/friends/respond`~~ → WebSocket
- ~~`DELETE /api/friends/remove/{otherUserId}`~~ → WebSocket: `REMOVE_FRIEND`
- ~~`GET /api/friends/search`~~ → WebSocket: `SEARCH_USERS`
- ~~`GET /api/friends/debug/{userId}`~~ → Debug endpoint (می‌تواند حذف شود)

### 4. GameInvitationController ❌
**حذف کامل** - همه از طریق WebSocket:
- ~~`POST /api/game-invitations/send`~~ → WebSocket: `SEND_GAME_INVITATION`
- ~~`POST /api/game-invitations/accept/{id}`~~ → WebSocket: `ACCEPT_GAME_INVITATION`
- ~~`POST /api/game-invitations/reject/{id}`~~ → WebSocket: `REJECT_GAME_INVITATION`
- ~~`POST /api/game-invitations/cancel/{id}`~~ → WebSocket: `CANCEL_GAME_INVITATION`
- ~~`GET /api/game-invitations/received`~~ → WebSocket: `GET_RECEIVED_INVITATIONS`
- ~~`GET /api/game-invitations/sent`~~ → WebSocket: `GET_SENT_INVITATIONS`

### 5. UserStatusController ❌
**حذف کامل** - همه از طریق WebSocket handle می‌شوند:
- ~~`POST /api/user-status/online`~~ → WebSocket connection
- ~~`POST /api/user-status/offline`~~ → WebSocket disconnect
- ~~`POST /api/user-status/in-game`~~ → WebSocket
- ~~`POST /api/user-status/in-lobby`~~ → WebSocket
- ~~`POST /api/user-status/idle`~~ → WebSocket heartbeat

### 6. CoinTransactionController ❌
**حذف کامل** - همه از طریق WebSocket:
- ~~`GET /api/transactions`~~ → WebSocket: `GET_TRANSACTIONS`
- ~~`POST /api/transactions/topup`~~ → می‌تواند نگهداری شود برای integration با payment gateway

### 7. WithdrawController ❌
**حذف کامل** - همه از طریق WebSocket:
- ~~`GET /api/withdraw`~~ → WebSocket: `GET_WITHDRAW_REQUESTS`
- ~~`POST /api/withdraw`~~ → WebSocket: `REQUEST_WITHDRAW`
- ~~`PATCH /api/withdraw/{id}`~~ → Admin panel (می‌تواند نگهداری شود)

### 8. XpController ❌
**حذف کامل** - همه از طریق WebSocket:
- ~~`GET /api/xp/history`~~ → WebSocket: `GET_XP_HISTORY`

### 9. GameController ❌
**حذف کامل** - همه از طریق WebSocket:
- ~~`POST /api/game/start/{roomId}`~~ → WebSocket
- ~~`GET /api/game/state/{gameStateId}`~~ → WebSocket: `GET_GAME_STATE`
- ~~`GET /api/game/state/room/{roomId}`~~ → WebSocket: `GET_GAME_STATE_BY_ROOM`
- ~~`POST /api/game/hokm/choose-trump`~~ → WebSocket
- ~~`POST /api/game/shalem/bid`~~ → WebSocket
- ~~`POST /api/game/rps/choice`~~ → WebSocket
- ~~`POST /api/game/play-card`~~ → WebSocket
- ~~`POST /api/game/backgammon/roll-dice`~~ → WebSocket
- ~~`POST /api/game/backgammon/move-piece`~~ → WebSocket
- ~~`POST /api/game/end-game`~~ → WebSocket

---

## استراتژی حذف:

### مرحله 1: Deprecate کردن (ایمن‌تر) ✅
ابتدا تمام endpointها را `@Deprecated` می‌کنیم و یک endpoint جایگزین WebSocket معرفی می‌کنیم.

### مرحله 2: حذف کامل (بعد از تست) ⏳
پس از اطمینان از کارکرد صحیح WebSocket، فایل‌های کنترلر را حذف می‌کنیم.

---

## Controllers باقی‌مانده:

1. ✅ **AuthController** - فقط endpointهای ضروری authentication
2. ✅ **TestController** - برای testing (اختیاری)
3. ✅ **HeartbeatController** - برای WebSocket heartbeat
4. ✅ **WebSocketController** - برای WebSocket message handling

---

## تعداد کنترلرهای حذف شده:
- GameRoomController ❌
- FriendshipController ❌
- GameInvitationController ❌
- UserStatusController ❌
- CoinTransactionController ❌
- WithdrawController ❌ (جز admin endpoint)
- XpController ❌
- GameController ❌
- GameHistoryController ❌ (اگر وجود داشته باشد)

**جمع: 8-9 کنترلر حذف می‌شود**

