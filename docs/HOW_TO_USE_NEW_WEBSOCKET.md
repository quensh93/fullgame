# 📖 راهنمای استفاده از WebSocket جدید

## 🎯 دو روش استفاده

### روش 1: استفاده موازی (فعلی) - برای Testing
هم `WebSocketService` قدیمی و هم `WebSocketManager` جدید فعال هستند.

**مزایا:**
- ✅ می‌تونی تدریجی migrate کنی
- ✅ اگه مشکلی پیش اومد برگردی به قدیمی
- ✅ بدون risk

**نحوه استفاده:**
```dart
// قدیمی (فعلاً کار می‌کنه)
final oldWs = getIt<WebSocketService>();
oldWs.connect();

// جدید (برای testing)
final newWs = ref.watch(websocketProvider);
newWs.connect();
```

### روش 2: استفاده کامل از جدید (بعد از تست)
وقتی مطمئن شدی جدید کار می‌کنه، قدیمی رو حذف می‌کنی.

---

## 🚀 Migration یک Provider

### قبل:
```dart
// OLD: friends_provider.dart
final friendsProvider = StateNotifierProvider.autoDispose<FriendsNotifier, AsyncValue<List<FriendModel>>>((ref) {
  return FriendsNotifier();
});

class FriendsNotifier extends StateNotifier<AsyncValue<List<FriendModel>>> {
  final WebSocketService _ws = getIt<WebSocketService>();
  Function(Map<String, dynamic>)? _friendsListCallback;
  // 4 callback دیگه...

  FriendsNotifier() : super(const AsyncValue.loading()) {
    _setupWebSocketListeners();  // 30 خط کد
    loadFriends();
  }

  void _setupWebSocketListeners() {
    _friendsListCallback = (data) { /* ... */ };
    _ws.addFriendsListCallback(_friendsListCallback!);
    // 4 تا دیگه...
  }

  @override
  void dispose() {
    _ws.removeFriendsListCallback(_friendsListCallback!);
    // 4 remove دیگه...
    super.dispose();
  }

  void loadFriends() {
    state = const AsyncValue.loading();
    _ws.getFriends();
  }
}
```

### بعد:
```dart
// NEW: friends_provider.dart
final friendsProvider = StateNotifierProvider.autoDispose<FriendsNotifier, AsyncValue<List<FriendModel>>>((ref) {
  final ws = ref.watch(websocketProvider);
  return FriendsNotifier(ws);
});

class FriendsNotifier extends StateNotifier<AsyncValue<List<FriendModel>>> {
  final WebSocketManager _ws;

  FriendsNotifier(this._ws) : super(const AsyncValue.loading()) {
    _ws.on('FRIENDS_LIST', _handleFriendsList);
    loadFriends();
  }

  void _handleFriendsList(Map<String, dynamic> data) {
    if (data['success'] == true) {
      final friends = (data['data'] as List)
          .map((json) => FriendModel.fromJson(json))
          .toList();
      state = AsyncValue.data(friends);
    }
  }

  @override
  void dispose() {
    _ws.clearCallbacks('FRIENDS_LIST');
    super.dispose();
  }

  void loadFriends() {
    state = const AsyncValue.loading();
    _ws.send({'type': 'GET_FRIENDS'});
  }
}
```

**کاهش کد: 80 خط → 35 خط (56% کاهش!)** 🎉

---

## 🔧 تنظیمات اولیه

### 1. آپدیت `injection.dart`:

```dart
Future<void> configureDependencies() async {
  // ... existing services ...
  
  // فعلاً هر دو رو نگهداری کن
  getIt.registerSingleton<WebSocketService>(WebSocketService());
  getIt.registerSingleton<WebSocketManager>(WebSocketManager());
}
```

### 2. آپدیت `constants/endpoints.dart`:

```dart
class Endpoints {
  // ... existing endpoints ...
  
  // WebSocket URLs
  static const String websocketUrl = 'ws://10.0.2.2:8080/ws-v2';  // جدید
  static const String websocketUrlOld = 'ws://10.0.2.2:8080/raw-ws';  // قدیمی
}
```

### 3. اتصال در `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  
  // اتصال به WebSocket (اختیاری - providers خودشون connect می‌کنن)
  // final wsManager = getIt<WebSocketManager>();
  // await wsManager.connect();
  
  runApp(ProviderScope(child: MyApp()));
}
```

---

## 📊 Connection State در UI

```dart
// نمایش banner وقتی reconnecting
Consumer(
  builder: (context, ref, child) {
    final state = ref.watch(websocketManagerProvider);
    
    if (state == ConnectionState.reconnecting) {
      return MaterialBanner(
        content: Text('در حال اتصال مجدد...'),
        actions: [
          TextButton(
            onPressed: () => ref.read(websocketProvider).connect(),
            child: Text('تلاش مجدد'),
          ),
        ],
      );
    }
    
    return SizedBox.shrink();
  },
)
```

---

## 🔄 Migration Plan

### مرحله 1: تست جدید در کنار قدیمی
```
Week 1:
- ✅ فایل‌های جدید ساخته شد
- ✅ Backend integration کامل شد
- ⏳ یک provider رو migrate کن (مثلاً friends)
- ⏳ تست کامل
```

### مرحله 2: migrate بقیه providers
```
Week 2:
- ⏳ game_rooms_provider
- ⏳ user_provider
- ⏳ wallet_provider
- ⏳ تست هر کدوم
```

### مرحله 3: حذف قدیمی
```
Week 3:
- ⏳ اطمینان از کار کردن همه چیز
- ⏳ حذف WebSocketService قدیمی
- ⏳ حذف WebSocketConfig قدیمی
- ⏳ cleanup imports
```

---

## ⚡ Quick Start

### برای تست سریع:

1. **Backend restart کن**
2. **Flutter hot restart کن**  
3. **تست connection**:
   ```dart
   // در هر provider
   final ws = ref.watch(websocketProvider);
   print('Connection state: ${ref.watch(websocketManagerProvider)}');
   ```

4. **یک feature رو تست کن** (مثلاً friends list)

---

## 🐛 Troubleshooting

### مشکل: Connection برقرار نمیشه
```dart
// چک کن URL درست باشه
print('WebSocket URL: ${Endpoints.websocketUrl}');

// چک کن backend روی /ws-v2 listen میکنه
// Log backend: "New WebSocket connection: ..."
```

### مشکل: Callbacks execute نمیشن
```dart
// چک کن callback ثبت شده
_ws.on('MESSAGE_TYPE', (data) {
  print('Callback executed!');
});

// چک کن message type درسته
// Log: "Received message type: ..."
```

### مشکل: Auto-reconnect کار نمیکنه
```dart
// چک کن state changes
ref.listen(websocketManagerProvider, (prev, next) {
  print('State changed: $prev → $next');
});
```

---

## 📱 Production Checklist

- [ ] تست تمام features با WebSocket جدید
- [ ] تست reconnection scenarios
- [ ] تست offline mode
- [ ] تست concurrent users
- [ ] Load testing
- [ ] حذف WebSocket قدیمی
- [ ] حذف REST API endpoints deprecated
- [ ] آپدیت documentation
- [ ] Code review
- [ ] Deploy به staging
- [ ] Monitor logs
- [ ] Deploy به production

---

**همه چیز آماده‌ست! فقط باید تست کنی.** 🎉

