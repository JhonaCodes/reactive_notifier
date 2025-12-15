# listenVM() - ViewModel Communication Method

## Method Signature

```dart
T listenVM(void Function(T data) value, {bool callOnInit = false})
```

## Purpose

`listenVM()` establishes reactive communication between ViewModels by registering a callback that executes whenever the source ViewModel's state changes. It returns the current state immediately, enabling synchronization from the moment of subscription.

This method is the primary mechanism for cross-service communication in ReactiveNotifier, following the "explicit sandbox architecture" pattern where services reference each other directly rather than through magic type lookups.

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `value` | `void Function(T data)` | Yes | - | Callback function invoked with the new state whenever the ViewModel updates |
| `callOnInit` | `bool` | No | `false` | When `true`, executes the callback immediately with the current state upon registration |

## Return Type

**`T`** - Returns the current value of the ViewModel's state (`_data`), allowing immediate access to the initial state without waiting for the first change notification.

## Usage Example: Cross-Service Communication

```dart
// Service definitions using mixin namespacing
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

mixin NotificationService {
  static final ReactiveNotifier<NotificationViewModel> notifications =
    ReactiveNotifier<NotificationViewModel>(() => NotificationViewModel());
}

// UserViewModel - the source of user state
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.guest());

  @override
  void init() {
    final cachedUser = LocalStorage.getUser();
    if (cachedUser != null) {
      updateSilently(cachedUser);
    }
  }

  void login(UserModel user) {
    updateState(user);
  }

  void logout() {
    updateState(UserModel.guest());
  }
}

// NotificationViewModel - listens to user changes
class NotificationViewModel extends ViewModel<NotificationModel> {
  NotificationViewModel() : super(NotificationModel.empty());

  // Instance variable to hold current state from UserService
  UserModel? currentUser;

  @override
  void init() {
    // listenVM returns current value AND sets up listener
    currentUser = UserService.userState.notifier.listenVM((userData) {
      // This callback executes on every user state change
      currentUser = userData;
      _updateNotificationsForUser(userData);
    });

    // Use the returned value for initial setup
    if (currentUser != null && currentUser!.isLoggedIn) {
      _loadInitialNotifications(currentUser!);
    }
  }

  void _updateNotificationsForUser(UserModel user) {
    if (!user.isLoggedIn) {
      updateState(NotificationModel.empty());
      return;
    }

    transformState((state) => state.copyWith(
      userId: user.id,
      userName: user.name,
    ));
  }

  Future<void> _loadInitialNotifications(UserModel user) async {
    final notifications = await _repository.getForUser(user.id);
    transformState((state) => state.copyWith(items: notifications));
  }
}
```

## Using callOnInit Parameter

When `callOnInit: true`, the callback fires immediately with the current state:

```dart
@override
void init() {
  // Callback fires immediately, then on every subsequent change
  UserService.userState.notifier.listenVM((userData) {
    currentUser = userData;
    syncWithUser(userData);
  }, callOnInit: true);

  // No need to manually handle initial state - callback already executed
}
```

## Best Practices

### 1. Always Store Current State in Instance Variables

Store the state from other services for access throughout your ViewModel:

```dart
class DashboardViewModel extends ViewModel<DashboardModel> {
  // Instance variables for cross-service state
  UserModel? currentUser;
  SettingsModel? currentSettings;

  @override
  void init() {
    currentUser = UserService.userState.notifier.listenVM((user) {
      currentUser = user;  // Always update the instance variable
      _updateDashboard();
    });

    currentSettings = SettingsService.settings.notifier.listenVM((settings) {
      currentSettings = settings;
      _updateDashboard();
    });
  }
}
```

### 2. Use Explicit Service References

Always reference specific service instances directly:

```dart
// CORRECT: Explicit and traceable
UserService.userState.notifier.listenVM((user) { ... });

// INCORRECT: This is not how ReactiveNotifier works
// getIt<UserViewModel>().listen((user) { ... });
```

### 3. Guard Against Null States

Handle null states gracefully in your update methods:

```dart
void _updateDashboard() {
  if (currentUser == null) return;
  if (currentSettings == null) return;

  transformState((state) => state.copyWith(
    userName: currentUser!.name,
    theme: currentSettings!.theme,
  ));
}
```

### 4. Use hasInitializedListenerExecution for Safety

Prevent duplicate execution during initialization:

```dart
Future<void> _handleUserChange(UserModel user) async {
  if (!hasInitializedListenerExecution) return;
  await loadDataForUser(user);
}
```

## Memory Considerations

### Automatic Tracking

Each listener is assigned a unique key and tracked internally:

```dart
// Internal tracking (from source code)
final Map<String, VoidCallback> _listeners = {};
final Map<String, int> _listeningTo = {};
```

Key format: `'vm_${hashCode}_${DateTime.now().microsecondsSinceEpoch}'`

### Automatic Cleanup

All listeners registered via `listenVM()` are automatically cleaned up when `dispose()` is called:

```dart
@override
void dispose() {
  // Automatic cleanup sequence:
  // 1. removeListeners() - external listeners from setupListeners()
  // 2. stopListeningVM() - all listenVM() connections
  // 3. Clear tracking maps
  // 4. Notify ReactiveNotifier for cleanup
  super.dispose();
}
```

### Multiple Listeners Support

Unlike `listen()` on NotifierImpl (which replaces previous listeners), `listenVM()` supports multiple concurrent listeners on the same ViewModel:

```dart
@override
void init() {
  // Multiple listeners are tracked independently
  UserService.userState.notifier.listenVM((user) { handleUser(user); });
  SettingsService.settings.notifier.listenVM((settings) { handleSettings(settings); });
  CartService.cart.notifier.listenVM((cart) { handleCart(cart); });
}
```

### Debug Monitoring

Monitor active listeners using the `activeListenerCount` getter:

```dart
void debugListenerStatus() {
  final count = UserService.userState.notifier.activeListenerCount;
  log('User ViewModel has $count active listeners');
}
```

## Source Reference

**File**: `lib/src/viewmodel/viewmodel_impl.dart`

**Lines**: 575-609

```dart
T listenVM(void Function(T data) value, {bool callOnInit = false}) {
  // Create unique key for this listener
  final listenerKey =
      'vm_${hashCode}_${DateTime.now().microsecondsSinceEpoch}';

  // Create callback
  void callback() => value(_data);

  // Store listener
  _listeners[listenerKey] = callback;

  // Track relationship (this ViewModel is listening to current ViewModel)
  _listeningTo[listenerKey] = hashCode;

  // Call on init if requested
  if (callOnInit) {
    callback();
  }

  // Register with ChangeNotifier
  addListener(callback);

  return _data;
}
```

## Related Methods

- [stopListeningVM()](stop-listening-vm.md) - Remove all listeners
- [stopSpecificListener()](stop-specific-listener.md) - Remove a specific listener by key
