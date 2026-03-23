# 📘 راهنمای کامل Migration به WebSocket v2

## 🎯 خلاصه تغییرات

### فایل‌های جدید ایجاد شده:

#### Backend (Spring Boot) - 4 فایل:
1. ✅ `config/ObjectMapperConfig.java` - Bean configuration
2. ✅ `services/WebSocketSessionManager.java` - Session management
3. ✅ `services/WebSocketMessageHandler.java` - Message routing
4. ✅ `ImprovedWebSocketConfig.java` - WebSocket configuration روی `/ws-v2`

#### Flutter (Riverpod) - 8 فایل:
1. ✅ `core/services/websocket_manager.dart` - Core manager با StateNotifier
2. ✅ `core/services/websocket_api_service.dart` - Type-safe API wrapper
3. ✅ `core/providers/websocket_providers.dart` - Export همه providers
4. ✅ `features/game/providers/game_rooms_provider_v2.dart`
5. ✅ `features/game/providers/game_provider_v2.dart`
6. ✅ `features/friends/providers/friends_provider_v2.dart`
7. ✅ `features/profile/providers/profile_provider_v2.dart`
8. ✅ `features/wallet/providers/wallet_provider_v2.dart`

---

## 🔄 نحوه استفاده

### در UI/Page:

#### قبل (قدیمی):
```dart
import '../providers/friends_provider.dart';

class FriendsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsNotifierProvider);
    // ...
  }
}
```

#### بعد (جدید):
```dart
import '../../../core/providers/websocket_providers.dart';

class FriendsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connection state
    final connectionState = ref.watch(websocketManagerProvider);
    
    // Watch data
    final friends = ref.watch(friendsProviderV2);
    
    // نمایش connection indicator
    if (connectionState == ConnectionState.reconnecting) {
      return ReconnectingBanner();
    }
    
    // ...
  }
}
```

---

## 📝 Checklist برای هر Provider

### ✅ game_rooms_provider
- [x] `game_rooms_provider_v2.dart` ایجاد شد
- [ ] UI pages آپدیت شوند (game_rooms_page.dart)
- [ ] تست شود

### ✅ friends_provider
- [x] `friends_provider_v2.dart` ایجاد شد
- [ ] UI pages آپدیت شوند
- [ ] تست شود

### ✅ profile_provider
- [x] `profile_provider_v2.dart` ایجاد شد
- [ ] UI pages آپدیت شوند
- [ ] تست شود

### ✅ wallet_provider
- [x] `wallet_provider_v2.dart` ایجاد شد
- [ ] UI pages آپدیت شوند
- [ ] تست شود

### ✅ game_provider
- [x] `game_provider_v2.dart` ایجاد شد
- [ ] UI pages آپدیت شوند
- [ ] تست شود

---

## 🚀 مراحل Rollout

### مرحله 1: Backend Ready ✅
```bash
# Backend آماده است
# ImprovedWebSocketConfig روی /ws-v2 فعال است
# WebSocketSessionManager و MessageHandler registered هستند
```

### مرحله 2: Flutter Setup ✅
```dart
// در main.dart - اطمینان حاصل کن که WebSocketManager connect میشه
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// در MyApp - auto-connect when app starts
class MyApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Auto-connect to WebSocket v2
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = ref.read(websocketProvider);
      ws.connect();
      
      // Monitor connection state
      ref.listen(websocketManagerProvider, (prev, next) {
        print('WebSocket state: $prev → $next');
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
    );
  }
}
```

### مرحله 3: یک صفحه رو migrate کن (مثال: Friends)
```dart
// قبل
import '../providers/friends_provider.dart';
final friends = ref.watch(friendsNotifierProvider);

// بعد
import '../../../core/providers/websocket_providers.dart';
final friends = ref.watch(friendsProviderV2);
```

### مرحله 4: تست کن
- [ ] صفحه باز میشه
- [ ] داده‌ها load میشن
- [ ] Actions کار می‌کنن
- [ ] Reconnection کار می‌کنه
- [ ] Error handling درسته

### مرحله 5: بقیه صفحات رو migrate کن
یکی یکی هر صفحه رو به `_v2` providers تبدیل کن

### مرحله 6: Cleanup
وقتی همه چیز کار کرد، فایل‌های قدیمی رو حذف کن:
- [x] `websocket_service.dart` *(در نسخه فعلی حذف و با WebSocketManager + LogService جایگزین شد)*
- [ ] `WebSocketConfig.java`
- [ ] `*_provider.dart` (بدون _v2)

---

## 📊 مقایسه Code

### Provider Code Reduction:

| Provider | قبل | بعد | کاهش |
|----------|-----|-----|-------|
| friends_provider | 226 خط | 183 خط | 19% |
| game_rooms_provider | 361 خط | 175 خط | 52% |
| wallet_provider | 118 خط | 152 خط | -29% (features +) |
| user_provider | 78 خط | 91 خط | -17% (features +) |

### ویژگی‌های اضافه شده:
- ✅ Auto-reconnection
- ✅ Message queue
- ✅ Connection state monitoring
- ✅ Better error handling
- ✅ Heartbeat
- ✅ Cleaner API

---

## ⚠️ نکات مهم

### 1. Backend دارای دو WebSocket endpoint:
- `/raw-ws` - قدیمی (WebSocketConfig.java)
- `/ws-v2` - جدید (ImprovedWebSocketConfig.java)

می‌تونی تدریجی migrate کنی بدون اینکه قدیمی break بشه.

### 2. Flutter providers:
- `*_provider.dart` - قدیمی (با WebSocketService)
- `*_provider_v2.dart` - جدید (با WebSocketManager)

### 3. Import ها:
```dart
// برای استفاده از نسخه جدید
import 'package:gameapp/core/providers/websocket_providers.dart';

// یا مستقیماً
import 'package:gameapp/core/services/websocket_manager.dart';
```

### 4. Connection Management:
```dart
// WebSocketManager خودش connect میکنه
// اما می‌تونی manual هم کنترل کنی:

final ws = ref.read(websocketProvider);
await ws.connect();  // Manual connect
ws.disconnect();     // Manual disconnect

// یا watch کنی که auto manage بشه
ref.listen(websocketManagerProvider, (prev, next) {
  if (next == ConnectionState.error) {
    // Show error
  }
});
```

---

## 🧪 تست Plan

### Test 1: Connection
```dart
test('WebSocketManager connects successfully', () async {
  final ws = WebSocketManager();
  await ws.connect();
  expect(ws.state, ConnectionState.connected);
});
```

### Test 2: Auto-reconnect
```dart
test('Auto-reconnect works', () async {
  final ws = WebSocketManager();
  await ws.connect();
  
  // Simulate disconnect
  ws.disconnect();
  
  // Should reconnect
  await Future.delayed(Duration(seconds: 2));
  expect(ws.state, ConnectionState.connected);
});
```

### Test 3: Message Queue
```dart
test('Messages are queued when offline', () {
  final ws = WebSocketManager();
  
  // Send while disconnected
  ws.send({'type': 'GET_FRIENDS'});
  
  expect(ws.queuedMessagesCount, 1);
  
  // Connect and flush
  await ws.connect();
  expect(ws.queuedMessagesCount, 0);
});
```

---

## 📦 فایل‌هایی که نیاز به آپدیت دارند

### در gameapp/lib/:

#### features/game/ui/:
- [ ] `game_rooms_page.dart` - تبدیل به `gameRoomsProviderV2`
- [ ] `game_room_page.dart` - تبدیل به `currentGameRoomProviderV2`
- [ ] `game_start_page.dart` - بررسی callbacks

#### features/friends/ui/:
- [ ] `friends_page.dart` - تبدیل به `friendsProviderV2`
- [ ] هر page دیگه‌ای که از friends استفاده میکنه

#### features/profile/ui/:
- [ ] `profile_page.dart` - تبدیل به `userProfileProviderV2`
- [ ] `edit_profile_page.dart` - تبدیل به `userProfileProviderV2`

#### features/wallet/ui/:
- [ ] `wallet_page.dart` - تبدیل به `transactionsProviderV2`
- [ ] صفحات withdraw

---

## ✅ فایل‌هایی که آماده هستند

### Backend:
- ✅ `ImprovedWebSocketConfig.java` - آماده و روی `/ws-v2`
- ✅ `WebSocketSessionManager.java` - registered
- ✅ `WebSocketMessageHandler.java` - registered
- ✅ `WebSocketRoomService.java` - uses SessionManager
- ✅ `SecurityConfig.java` - `/ws-v2` permitted

### Flutter:
- ✅ همه `*_provider_v2.dart` files آماده
- ✅ `websocket_manager.dart` - کامل
- ✅ `websocket_api_service.dart` - کامل
- ✅ `endpoints.dart` - آپدیت شده
- ✅ `injection.dart` - documented

---

## 🎯 خطوات بعدی (برای شما)

1. **Backend را restart کن** ✨
   ```bash
   cd gameBackend
   ./gradlew bootRun
   ```

2. **Flutter را restart کن** ✨
   ```bash
   cd gameapp
   flutter run
   ```

3. **یک provider رو test کن** (مثلاً friends):
   - Import کن: `friends_provider_v2.dart`
   - در UI بجای `friendsNotifierProvider` از `friendsProviderV2` استفاده کن
   - Run و test کن

4. **اگه کار کرد:**
   - یکی یکی بقیه رو migrate کن
   - قدیمی‌ها رو حذف کن

5. **اگه مشکلی بود:**
   - برگرد به قدیمی
   - بهم بگو تا fix کنم

---

**همه چیز آماده‌ست! فقط backend و flutter restart کن.** 🚀

