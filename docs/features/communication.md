# Cross-Service Communication Guide

## Overview

ReactiveNotifier provides a robust communication system for cross-service and cross-ViewModel interactions. This guide covers the `listen()` and `listenVM()` methods that enable reactive data flow between different parts of your application.

**Key Philosophy**: ReactiveNotifier uses **explicit communication** - you always reference specific service instances directly, not through magic type lookups. This approach supports multiple instances of the same type and maintains clear, traceable data flows.

## Communication Methods Summary

| Method | Class | Returns | Use Case |
|--------|-------|---------|----------|
| `listen()` | `NotifierImpl<T>` | `T` (current value) | Simple ReactiveNotifier communication |
| `listenVM()` | `ViewModel<T>` | `T` (current value) | ViewModel-to-ViewModel communication |
| `listenVM()` | `AsyncViewModelImpl<T>` | `Future<AsyncState<T>>` | Async ViewModel communication |

---

## ReactiveNotifier.listen()

### How It Works

The `listen()` method on `NotifierImpl<T>` (the base class for ReactiveNotifier) provides a simple way to observe state changes in a ReactiveNotifier instance.

**Source location**: `lib/src/notifier/notifier_impl.dart`

### Signature

```dart
T listen(void Function(T data) value)
```

### Behavior

1. **Removes any previously registered listener** - Only one listener can be active at a time per `listen()` call
2. **Registers the new callback** - Wraps your callback and adds it to the ChangeNotifier
3. **Returns the current value immediately** - Allows you to sync with the initial state

### Basic Usage

```dart
mixin CounterService {
  static final ReactiveNotifier<int> count = ReactiveNotifier<int>(() => 0);
}

// In another service or ViewModel
void setupCounter() {
  // Returns current value AND sets up listener
  final currentCount = CounterService.count.listen((newCount) {
    log('Count changed to: $newCount');
    handleCountChange(newCount);
  });

  log('Initial count: $currentCount'); // Immediate access to current state
}
```

### stopListening()

To stop listening and clean up the listener:

```dart
void cleanup() {
  CounterService.count.stopListening();
}
```

**Important**: `stopListening()` is automatically called during `dispose()`, so manual cleanup is typically only needed for temporary listeners.

### Memory Considerations

- Only **one listener** can be active per `listen()` call on a NotifierImpl
- Calling `listen()` again automatically removes the previous listener
- Always call `stopListening()` or rely on `dispose()` to prevent memory leaks

---

## ViewModel.listenVM()

### How It Works

The `listenVM()` method provides enhanced listener management for ViewModel-to-ViewModel communication with automatic tracking and cleanup.

**Source location**: `lib/src/viewmodel/viewmodel_impl.dart`

### Signature

```dart
T listenVM(void Function(T data) value, {bool callOnInit = false})
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `value` | `void Function(T data)` | required | Callback invoked when state changes |
| `callOnInit` | `bool` | `false` | If true, immediately invokes the callback with current state |

### Return Value

Returns the **current value** of type `T`, allowing immediate synchronization with the ViewModel's state.

### Internal Tracking

Each listener is assigned a unique key and tracked in internal maps:

```dart
// Internal tracking maps in ViewModel
final Map<String, VoidCallback> _listeners = {};
final Map<String, int> _listeningTo = {};
```

This enables:
- Multiple listeners per ViewModel
- Individual listener removal
- Automatic cleanup on disposal
- Debug information about active listeners

### Basic Usage

```dart
class NotificationViewModel extends ViewModel<NotificationModel> {
  NotificationViewModel() : super(NotificationModel.empty());

  // Instance variable to hold current state from other ViewModel
  UserModel? currentUser;

  @override
  void init() {
    // Listen to user changes reactively
    currentUser = UserService.userState.notifier.listenVM((userData) {
      // Update instance variable
      currentUser = userData;

      // React to changes
      updateNotificationsForUser(userData);
    });

    // Use the returned value for initial setup
    if (currentUser != null) {
      loadInitialNotifications(currentUser!);
    }
  }

  void updateNotificationsForUser(UserModel user) {
    transformState((state) => state.copyWith(
      userId: user.id,
      userName: user.name,
    ));
  }
}
```

### Using callOnInit

When `callOnInit: true`, the callback is invoked immediately with the current state:

```dart
@override
void init() {
  // Callback fires immediately with current user data
  UserService.userState.notifier.listenVM((userData) {
    currentUser = userData;
    syncWithUser(userData);
  }, callOnInit: true);

  // No need to manually call syncWithUser here - it's already done
}
```

### Storing Instance Variables

**Best Practice**: Store the current state in instance variables for access throughout the ViewModel:

```dart
class DashboardViewModel extends ViewModel<DashboardModel> {
  DashboardViewModel() : super(DashboardModel.initial());

  // Instance variables for cross-service state
  UserModel? currentUser;
  SettingsModel? currentSettings;
  List<CartItem>? currentCartItems;

  @override
  void init() {
    // Listen to multiple services
    currentUser = UserService.userState.notifier.listenVM((user) {
      currentUser = user;
      _updateDashboard();
    });

    currentSettings = SettingsService.settings.notifier.listenVM((settings) {
      currentSettings = settings;
      _updateDashboard();
    });

    currentCartItems = CartService.cartItems.notifier.listenVM((items) {
      currentCartItems = items;
      _updateDashboard();
    });

    // Initial dashboard update
    _updateDashboard();
  }

  void _updateDashboard() {
    if (currentUser == null) return;

    transformState((state) => state.copyWith(
      userName: currentUser!.name,
      itemCount: currentCartItems?.length ?? 0,
      isDarkMode: currentSettings?.isDarkMode ?? false,
    ));
  }
}
```

### stopListeningVM()

Removes **all** listeners registered via `listenVM()`:

```dart
void cleanupAllListeners() {
  // Removes all listeners and clears tracking maps
  stopListeningVM();
}
```

This is called automatically during `dispose()`.

### stopSpecificListener(listenerKey)

For granular control, you can stop a specific listener by its key:

```dart
// Note: Listener keys are auto-generated in format:
// 'vm_{hashCode}_{microsecondsSinceEpoch}'

void removeUserListener(String listenerKey) {
  stopSpecificListener(listenerKey);
}
```

**Usage Note**: To use `stopSpecificListener()`, you would need to capture the listener key or track it yourself. The keys are generated internally using the format `'vm_${hashCode}_${DateTime.now().microsecondsSinceEpoch}'`.

### activeListenerCount Getter

Monitor the number of active listeners for debugging:

```dart
void debugListenerStatus() {
  log('Active listeners: ${myViewModel.activeListenerCount}');
}

// In tests
test('listeners are properly tracked', () {
  final vm = MyViewModel();

  OtherService.state.notifier.listenVM((data) { /* listener 1 */ });
  AnotherService.state.notifier.listenVM((data) { /* listener 2 */ });

  expect(vm.activeListenerCount, equals(0)); // Note: listenVM is called ON the notifier, not FROM the vm

  // To track listeners TO this ViewModel:
  expect(OtherService.state.notifier.activeListenerCount, greaterThan(0));
});
```

---

## AsyncViewModelImpl.listenVM()

### How It Works

The async version of `listenVM()` works similarly to the synchronous version but handles `AsyncState<T>` and returns a `Future`.

**Source location**: `lib/src/viewmodel/async_viewmodel_impl.dart`

### Signature

```dart
Future<AsyncState<T>> listenVM(
  void Function(AsyncState<T> data) value,
  {bool callOnInit = false}
)
```

### Key Difference: Returns Future

Unlike `ViewModel.listenVM()` which returns `T` directly, the async version returns `Future<AsyncState<T>>`:

```dart
class OrderViewModel extends AsyncViewModelImpl<List<Order>> {
  OrderViewModel() : super(AsyncState.initial());

  AsyncState<UserModel>? userState;

  @override
  Future<List<Order>> init() async {
    // Listen to async user state
    userState = await UserService.userState.notifier.listenVM((state) {
      userState = state;

      // Handle different async states
      state.when(
        initial: () => log('User not loaded'),
        loading: () => log('User loading...'),
        success: (user) => reloadOrdersForUser(user),
        error: (err, stack) => handleUserError(err),
      );
    });

    // Load initial orders based on current user state
    if (userState?.isSuccess == true && userState?.data != null) {
      return await fetchOrdersForUser(userState!.data!);
    }
    return [];
  }
}
```

### Handling AsyncState in Callbacks

```dart
@override
Future<DataModel> init() async {
  // The callback receives AsyncState<T>, not just T
  await OtherAsyncService.state.notifier.listenVM((asyncState) {
    // Use pattern matching for different states
    asyncState.when(
      initial: () {
        // Handle initial state
        log('Other service not initialized');
      },
      loading: () {
        // Handle loading state
        loadingState(); // Set our state to loading too
      },
      success: (data) {
        // Handle success state
        reactToOtherData(data);
      },
      error: (error, stackTrace) {
        // Handle error state
        handleOtherServiceError(error);
      },
    );
  }, callOnInit: true);

  return await loadInitialData();
}
```

---

## Explicit Sandbox Architecture Pattern

### Philosophy

ReactiveNotifier enforces **explicit communication** between services. This means:

1. **No magic type lookups** - You reference specific service instances directly
2. **Multiple instances supported** - The same type can exist in different services
3. **Clear data flow** - Easy to trace where data comes from
4. **Isolated sandboxes** - Each service mixin is an independent namespace

### Pattern: Mixin Namespacing

```dart
// User Service (Sandbox 1)
mixin UserService {
  static final ReactiveNotifier<UserViewModel> currentUser =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());

  static final ReactiveNotifier<UserPreferences> preferences =
    ReactiveNotifier<UserPreferences>(() => UserPreferences());
}

// Notification Service (Sandbox 2)
mixin NotificationService {
  static final ReactiveNotifier<NotificationViewModel> notifications =
    ReactiveNotifier<NotificationViewModel>(() => NotificationViewModel());
}

// Cart Service (Sandbox 3)
mixin CartService {
  static final ReactiveNotifier<CartViewModel> cart =
    ReactiveNotifier<CartViewModel>(() => CartViewModel());
}
```

### Cross-Service Communication

```dart
class NotificationViewModel extends ViewModel<NotificationModel> {
  NotificationViewModel() : super(NotificationModel.empty());

  UserModel? currentUser;

  @override
  void init() {
    // EXPLICIT: Reference specific service instance
    currentUser = UserService.currentUser.notifier.listenVM((userData) {
      currentUser = userData;
      updateNotificationsForUser(userData);
    });
  }
}
```

### Benefits of Explicit Communication

1. **IDE Support**: Full autocomplete and navigation
2. **Refactoring Safety**: Rename refactoring works correctly
3. **Clear Dependencies**: Easy to see what a ViewModel depends on
4. **Testing**: Simple to mock specific service instances
5. **No Ambiguity**: Clear which instance you're referencing

---

## Multiple Instances of Same Type

### The Problem (Other Libraries)

In some state management solutions, you might have issues when you need multiple instances of the same type:

```dart
// Ambiguous - which UserViewModel?
final user = ref.read<UserViewModel>(); // Which one?
```

### The ReactiveNotifier Solution

ReactiveNotifier's explicit approach naturally handles this:

```dart
mixin UserService {
  // Main user state
  static final ReactiveNotifier<UserViewModel> mainUser =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());

  // Guest user state (same type, different instance)
  static final ReactiveNotifier<UserViewModel> guestUser =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

mixin AdminService {
  // Admin user (same type, different service)
  static final ReactiveNotifier<UserViewModel> adminUser =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}
```

### Accessing Multiple Instances

```dart
class DashboardViewModel extends ViewModel<DashboardModel> {
  DashboardViewModel() : super(DashboardModel.initial());

  UserModel? mainUser;
  UserModel? guestUser;
  UserModel? adminUser;

  @override
  void init() {
    // EXPLICIT: Each reference is unambiguous
    mainUser = UserService.mainUser.notifier.listenVM((user) {
      mainUser = user;
      _updateDashboardForMainUser(user);
    });

    guestUser = UserService.guestUser.notifier.listenVM((user) {
      guestUser = user;
      _updateDashboardForGuest(user);
    });

    adminUser = AdminService.adminUser.notifier.listenVM((user) {
      adminUser = user;
      _updateDashboardForAdmin(user);
    });
  }
}
```

---

## Complete Usage Examples

### Example 1: E-Commerce Cart Integration

```dart
// Models
class CartModel {
  final List<CartItem> items;
  final double total;
  final bool isReady;

  CartModel({required this.items, required this.total, required this.isReady});

  CartModel copyWith({List<CartItem>? items, double? total, bool? isReady}) {
    return CartModel(
      items: items ?? this.items,
      total: total ?? this.total,
      isReady: isReady ?? this.isReady,
    );
  }

  static CartModel empty() => CartModel(items: [], total: 0, isReady: false);
}

// Services
mixin CartService {
  static final ReactiveNotifier<CartViewModel> cart =
    ReactiveNotifier<CartViewModel>(() => CartViewModel());
}

mixin SalesService {
  static final ReactiveNotifier<SalesViewModel> sales =
    ReactiveNotifier<SalesViewModel>(() => SalesViewModel());
}

// ViewModels
class CartViewModel extends ViewModel<CartModel> {
  CartViewModel() : super(CartModel.empty());

  @override
  void init() {
    // Load initial cart
    updateSilently(CartModel.empty());
  }

  void addItem(CartItem item) {
    transformState((state) {
      final newItems = [...state.items, item];
      final newTotal = newItems.fold(0.0, (sum, i) => sum + i.price);
      return state.copyWith(items: newItems, total: newTotal);
    });
  }

  void markReady() {
    transformState((state) => state.copyWith(isReady: true));
  }
}

class SalesViewModel extends AsyncViewModelImpl<SaleModel> {
  SalesViewModel() : super(AsyncState.initial(), loadOnInit: false);

  CartModel? currentCart;

  @override
  Future<SaleModel> init() async {
    // Listen to cart changes
    currentCart = CartService.cart.notifier.listenVM((cart) {
      currentCart = cart;

      // Automatically process sale when cart is ready
      if (cart.isReady && cart.items.isNotEmpty) {
        _processSale(cart);
      }
    });

    return SaleModel.initial();
  }

  Future<void> _processSale(CartModel cart) async {
    loadingState();

    try {
      final sale = await _saleRepository.createSale(cart.items);
      updateState(sale);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}
```

### Example 2: Authentication Flow

```dart
// Services
mixin AuthService {
  static final ReactiveNotifier<AuthViewModel> auth =
    ReactiveNotifier<AuthViewModel>(() => AuthViewModel());
}

mixin ProfileService {
  static final ReactiveNotifier<ProfileViewModel> profile =
    ReactiveNotifier<ProfileViewModel>(() => ProfileViewModel());
}

mixin SettingsService {
  static final ReactiveNotifier<SettingsViewModel> settings =
    ReactiveNotifier<SettingsViewModel>(() => SettingsViewModel());
}

// Auth ViewModel
class AuthViewModel extends ViewModel<AuthState> {
  AuthViewModel() : super(AuthState.unauthenticated());

  @override
  void init() {
    // Check stored credentials
    _checkStoredAuth();
  }

  Future<void> login(String email, String password) async {
    // Login logic
    final user = await _authRepository.login(email, password);
    updateState(AuthState.authenticated(user));
  }

  void logout() {
    updateState(AuthState.unauthenticated());
  }
}

// Profile ViewModel - reacts to auth changes
class ProfileViewModel extends AsyncViewModelImpl<UserProfile> {
  ProfileViewModel() : super(AsyncState.initial());

  AuthState? currentAuthState;

  @override
  Future<UserProfile> init() async {
    // Listen to auth state changes
    currentAuthState = AuthService.auth.notifier.listenVM((authState) {
      currentAuthState = authState;

      if (authState.isAuthenticated) {
        // Load profile when user logs in
        _loadProfileForUser(authState.user!);
      } else {
        // Clear profile when user logs out
        cleanState();
      }
    }, callOnInit: true);

    // Load initial profile if authenticated
    if (currentAuthState?.isAuthenticated == true) {
      return await _loadProfile(currentAuthState!.user!.id);
    }

    return UserProfile.guest();
  }

  Future<void> _loadProfileForUser(User user) async {
    loadingState();
    try {
      final profile = await _loadProfile(user.id);
      updateState(profile);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}

// Settings ViewModel - reacts to both auth and profile
class SettingsViewModel extends ViewModel<SettingsModel> {
  SettingsViewModel() : super(SettingsModel.defaults());

  AuthState? currentAuth;
  AsyncState<UserProfile>? currentProfile;

  @override
  void init() {
    // Listen to auth
    currentAuth = AuthService.auth.notifier.listenVM((auth) {
      currentAuth = auth;
      _updateSettingsVisibility();
    });

    // Listen to profile (async)
    _listenToProfile();
  }

  Future<void> _listenToProfile() async {
    currentProfile = await ProfileService.profile.notifier.listenVM((profile) {
      currentProfile = profile;
      _applyProfileSettings();
    });
  }

  void _updateSettingsVisibility() {
    transformState((state) => state.copyWith(
      showAuthenticatedSettings: currentAuth?.isAuthenticated ?? false,
    ));
  }

  void _applyProfileSettings() {
    if (currentProfile?.isSuccess == true && currentProfile?.data != null) {
      final profile = currentProfile!.data!;
      transformState((state) => state.copyWith(
        theme: profile.preferredTheme,
        language: profile.preferredLanguage,
      ));
    }
  }
}
```

### Example 3: Real-Time Data Synchronization

```dart
mixin WebSocketService {
  static final ReactiveNotifier<WebSocketViewModel> socket =
    ReactiveNotifier<WebSocketViewModel>(() => WebSocketViewModel());
}

mixin ChatService {
  static final ReactiveNotifier<ChatViewModel> chat =
    ReactiveNotifier<ChatViewModel>(() => ChatViewModel());
}

class WebSocketViewModel extends ViewModel<WebSocketState> {
  WebSocketViewModel() : super(WebSocketState.disconnected());

  @override
  void init() {
    _connect();
  }

  void _connect() async {
    updateState(WebSocketState.connecting());

    try {
      await _webSocket.connect();
      updateState(WebSocketState.connected());

      _webSocket.onMessage.listen((message) {
        transformState((state) => state.copyWith(
          lastMessage: message,
          messageCount: state.messageCount + 1,
        ));
      });
    } catch (e) {
      updateState(WebSocketState.error(e));
    }
  }
}

class ChatViewModel extends ViewModel<ChatState> {
  ChatViewModel() : super(ChatState.initial());

  WebSocketState? socketState;

  @override
  void init() {
    // Listen to WebSocket state
    socketState = WebSocketService.socket.notifier.listenVM((state) {
      socketState = state;

      // React to connection status
      if (state.isConnected) {
        _subscribeToChat();
      } else if (state.isError) {
        _handleConnectionError(state.error);
      }

      // React to new messages
      if (state.lastMessage != null && state.lastMessage!.type == 'chat') {
        _handleChatMessage(state.lastMessage!);
      }
    });
  }

  void _subscribeToChat() {
    transformState((state) => state.copyWith(isSubscribed: true));
  }

  void _handleChatMessage(WebSocketMessage message) {
    transformState((state) => state.copyWith(
      messages: [...state.messages, ChatMessage.fromWs(message)],
    ));
  }

  void _handleConnectionError(Object? error) {
    transformState((state) => state.copyWith(
      connectionError: error?.toString(),
      isSubscribed: false,
    ));
  }
}
```

---

## Best Practices

### 1. Always Store Current State in Instance Variables

```dart
class MyViewModel extends ViewModel<MyState> {
  // Store state from other services
  UserModel? currentUser;
  SettingsModel? currentSettings;

  @override
  void init() {
    currentUser = UserService.user.notifier.listenVM((user) {
      currentUser = user; // Always update instance variable
      _react();
    });
  }
}
```

### 2. Use callOnInit for Immediate Synchronization

```dart
// When you need the callback to fire immediately
service.notifier.listenVM((data) {
  processData(data);
}, callOnInit: true);
```

### 3. Handle Null States Gracefully

```dart
void _updateState() {
  // Guard against null states
  if (currentUser == null) return;
  if (currentSettings == null) return;

  // Safe to use both states now
  transformState((state) => state.copyWith(
    userName: currentUser!.name,
    theme: currentSettings!.theme,
  ));
}
```

### 4. Use hasInitializedListenerExecution for Async Safety

```dart
Future<void> _handleUserChange(UserModel user) async {
  // Prevent duplicate execution during initialization
  if (!hasInitializedListenerExecution) return;

  await loadDataForUser(user);
}
```

### 5. Explicit Service References

```dart
// GOOD: Explicit and traceable
UserService.currentUser.notifier.listenVM((user) { ... });

// BAD: Implicit/magic lookups (not how ReactiveNotifier works)
// getIt<UserViewModel>().listen((user) { ... });
```

### 6. Clean Architecture with Mixins

```dart
// Each service is a clear namespace
mixin UserService { ... }
mixin CartService { ... }
mixin NotificationService { ... }

// Never use global variables
// final userState = ReactiveNotifier(...); // BAD
```

---

## Common Patterns

### NotificationService Listening to UserService

```dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> user =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

mixin NotificationService {
  static final ReactiveNotifier<NotificationViewModel> notifications =
    ReactiveNotifier<NotificationViewModel>(() => NotificationViewModel());
}

class NotificationViewModel extends ViewModel<NotificationState> {
  NotificationViewModel() : super(NotificationState.empty());

  UserModel? currentUser;

  @override
  void init() {
    // React to user changes
    currentUser = UserService.user.notifier.listenVM((user) {
      currentUser = user;

      // Clear notifications on logout
      if (!user.isLoggedIn) {
        updateState(NotificationState.empty());
        return;
      }

      // Load notifications for user
      _loadNotificationsForUser(user.id);
    });
  }

  Future<void> _loadNotificationsForUser(String userId) async {
    final notifications = await _repository.getNotifications(userId);
    updateState(NotificationState(
      notifications: notifications,
      userId: userId,
    ));
  }
}
```

### Multi-Source Aggregation

```dart
class AggregatedViewModel extends ViewModel<AggregatedState> {
  AggregatedViewModel() : super(AggregatedState.initial());

  DataA? dataA;
  DataB? dataB;
  DataC? dataC;

  @override
  void init() {
    dataA = ServiceA.state.notifier.listenVM((a) {
      dataA = a;
      _aggregate();
    });

    dataB = ServiceB.state.notifier.listenVM((b) {
      dataB = b;
      _aggregate();
    });

    dataC = ServiceC.state.notifier.listenVM((c) {
      dataC = c;
      _aggregate();
    });
  }

  void _aggregate() {
    // Only aggregate when all data is available
    if (dataA == null || dataB == null || dataC == null) return;

    transformState((state) => state.copyWith(
      combinedValue: dataA!.value + dataB!.value + dataC!.value,
      lastUpdated: DateTime.now(),
    ));
  }
}
```

### Conditional Listening

```dart
class ConditionalViewModel extends ViewModel<ConditionalState> {
  ConditionalViewModel() : super(ConditionalState.initial());

  bool _isListeningToExpensiveService = false;

  @override
  void init() {
    // Always listen to auth
    AuthService.auth.notifier.listenVM((auth) {
      if (auth.isAuthenticated && !_isListeningToExpensiveService) {
        // Start listening to expensive service only when authenticated
        _startExpensiveServiceListener();
      } else if (!auth.isAuthenticated && _isListeningToExpensiveService) {
        // Stop listening when logged out
        ExpensiveService.data.notifier.stopListening();
        _isListeningToExpensiveService = false;
      }
    });
  }

  void _startExpensiveServiceListener() {
    ExpensiveService.data.notifier.listenVM((data) {
      processExpensiveData(data);
    });
    _isListeningToExpensiveService = true;
  }
}
```

---

## Memory Management

### Automatic Cleanup

All listeners registered via `listenVM()` are automatically cleaned up when `dispose()` is called:

```dart
@override
void dispose() {
  // Automatic:
  // 1. removeListeners() - external listeners from setupListeners()
  // 2. stopListeningVM() - all listenVM() connections
  // 3. Clear tracking maps
  // 4. Notify ReactiveNotifier for cleanup
  super.dispose();
}
```

### Debug Monitoring

```dart
void debugCommunication() {
  assert(() {
    log('''
Communication Debug:
- Active listeners: ${activeListenerCount}
- Listening to ${_listeningTo.length} ViewModels
- Listener keys: ${_listeners.keys.toList()}
''');
    return true;
  }());
}
```

### Testing Cleanup

```dart
test('listeners are cleaned up properly', () {
  final userVM = UserService.user.notifier;
  final notificationVM = NotificationService.notifications.notifier;

  // Verify initial state
  expect(userVM.activeListenerCount, 0);

  // Set up listener
  userVM.listenVM((user) {
    // Listener logic
  });

  expect(userVM.activeListenerCount, greaterThan(0));

  // Dispose should clean up
  notificationVM.dispose();

  // Verify cleanup
  expect(notificationVM.activeListenerCount, 0);
});
```

---

## Summary

ReactiveNotifier's communication system provides:

- **`listen()`**: Simple, single-listener pattern for ReactiveNotifier
- **`listenVM()`**: Enhanced multi-listener pattern with automatic tracking
- **Explicit Architecture**: Clear, traceable dependencies between services
- **Multiple Instance Support**: Same type can exist in different services
- **Automatic Cleanup**: Memory-safe listener management
- **Debug Tools**: `activeListenerCount` and listener tracking

By following the explicit sandbox architecture pattern and using `listenVM()` for cross-service communication, you build maintainable, memory-safe applications with clear data flow.
