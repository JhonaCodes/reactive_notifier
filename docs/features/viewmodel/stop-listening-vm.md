# stopListeningVM() - Stop All ViewModel Listeners

## Method Signature

```dart
void stopListeningVM()
```

## Purpose

`stopListeningVM()` removes all listeners that were registered via `listenVM()` on the ViewModel. It clears both the callback registrations from ChangeNotifier and the internal tracking maps used for listener management.

This method is called automatically during `dispose()`, but can be called manually when you need to disconnect a ViewModel from all its listener relationships without fully disposing it.

## Parameters

None.

## Return Type

**`void`** - This method does not return a value.

## Usage Example: Cross-Service Communication Cleanup

```dart
// Service definitions
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

mixin CartService {
  static final ReactiveNotifier<CartViewModel> cartState =
    ReactiveNotifier<CartViewModel>(() => CartViewModel());
}

mixin NotificationService {
  static final ReactiveNotifier<NotificationViewModel> notifications =
    ReactiveNotifier<NotificationViewModel>(() => NotificationViewModel());
}

// ViewModel that listens to multiple services
class DashboardViewModel extends ViewModel<DashboardModel> {
  DashboardViewModel() : super(DashboardModel.initial());

  UserModel? currentUser;
  CartModel? currentCart;
  NotificationModel? currentNotifications;

  @override
  void init() {
    // Set up multiple listeners
    currentUser = UserService.userState.notifier.listenVM((user) {
      currentUser = user;
      _updateDashboard();
    });

    currentCart = CartService.cartState.notifier.listenVM((cart) {
      currentCart = cart;
      _updateDashboard();
    });

    currentNotifications = NotificationService.notifications.notifier.listenVM((notif) {
      currentNotifications = notif;
      _updateDashboard();
    });
  }

  void _updateDashboard() {
    if (currentUser == null) return;

    transformState((state) => state.copyWith(
      userName: currentUser!.name,
      cartItemCount: currentCart?.items.length ?? 0,
      notificationCount: currentNotifications?.unreadCount ?? 0,
    ));
  }

  /// Disconnect from all services without disposing
  void disconnectFromServices() {
    stopListeningVM();

    // Clear instance variables
    currentUser = null;
    currentCart = null;
    currentNotifications = null;
  }

  /// Reconnect to all services
  void reconnectToServices() {
    // Re-establish listeners
    currentUser = UserService.userState.notifier.listenVM((user) {
      currentUser = user;
      _updateDashboard();
    });

    currentCart = CartService.cartState.notifier.listenVM((cart) {
      currentCart = cart;
      _updateDashboard();
    });

    currentNotifications = NotificationService.notifications.notifier.listenVM((notif) {
      currentNotifications = notif;
      _updateDashboard();
    });

    _updateDashboard();
  }
}
```

## Complete Usage Example: Logout Flow

A common use case is disconnecting from services during logout while preserving the ViewModel instance:

```dart
mixin AuthService {
  static final ReactiveNotifier<AuthViewModel> auth =
    ReactiveNotifier<AuthViewModel>(() => AuthViewModel());
}

class AuthViewModel extends ViewModel<AuthState> {
  AuthViewModel() : super(AuthState.unauthenticated());

  @override
  void init() {
    final storedToken = SecureStorage.getToken();
    if (storedToken != null) {
      updateSilently(AuthState.authenticated(storedToken));
    }
  }

  Future<void> logout() async {
    // 1. Stop listening to other services
    stopListeningVM();

    // 2. Clear sensitive data
    await SecureStorage.clearAll();

    // 3. Update state to unauthenticated
    updateState(AuthState.unauthenticated());

    // 4. Optionally notify other services to clear their state
    UserService.userState.notifier.cleanState();
    CartService.cartState.notifier.cleanState();
  }
}

class ProfileViewModel extends ViewModel<ProfileModel> {
  ProfileViewModel() : super(ProfileModel.empty());

  AuthState? authState;

  @override
  void init() {
    authState = AuthService.auth.notifier.listenVM((auth) {
      authState = auth;

      if (!auth.isAuthenticated) {
        // User logged out - stop listening to profile-related services
        stopListeningVM();
        updateState(ProfileModel.empty());
      } else {
        // User logged in - set up profile listeners
        _setupProfileListeners();
      }
    }, callOnInit: true);
  }

  void _setupProfileListeners() {
    // Set up additional profile-related listeners
    UserService.userState.notifier.listenVM((user) {
      transformState((state) => state.copyWith(
        displayName: user.displayName,
        email: user.email,
      ));
    });
  }
}
```

## Best Practices

### 1. Let dispose() Handle Automatic Cleanup

In most cases, you do not need to call `stopListeningVM()` manually because it is called automatically during disposal:

```dart
@override
void dispose() {
  // Automatic cleanup sequence in ViewModel:
  // 1. removeListeners() - external listeners from setupListeners()
  // 2. stopListeningVM() - all listenVM() connections  <-- Called here
  // 3. Notify ReactiveNotifier for cleanup
  // 4. Mark as disposed
  // 5. super.dispose() - ChangeNotifier cleanup
  super.dispose();
}
```

### 2. Use for Temporary Disconnection

Use `stopListeningVM()` when you need to temporarily disconnect without disposing:

```dart
class DataSyncViewModel extends ViewModel<SyncState> {
  void pauseSync() {
    // Stop receiving updates while paused
    stopListeningVM();
    updateState(SyncState.paused());
  }

  void resumeSync() {
    // Re-establish listeners
    _setupListeners();
    updateState(SyncState.active());
  }
}
```

### 3. Clear Instance Variables After Stopping

Always clear your instance variables when stopping listeners to avoid stale references:

```dart
void disconnectFromServices() {
  stopListeningVM();

  // Clear all stored state
  currentUser = null;
  currentCart = null;
  currentSettings = null;
}
```

### 4. Consider stopSpecificListener() for Granular Control

If you only need to stop one specific listener, use `stopSpecificListener()` instead:

```dart
// Only stop the user listener, keep others active
stopSpecificListener(userListenerKey);
```

## Memory Considerations

### What Gets Cleaned Up

When `stopListeningVM()` is called:

1. **ChangeNotifier Listeners Removed**: All callbacks are removed from the underlying ChangeNotifier
2. **Internal Tracking Cleared**: Both `_listeners` and `_listeningTo` maps are cleared
3. **References Released**: Callback closures are released, allowing garbage collection

### Before vs After

```dart
// Before stopListeningVM()
log('Active listeners: ${activeListenerCount}');  // e.g., 3
log('Listening to: ${_listeningTo.length}');      // e.g., 3

stopListeningVM();

// After stopListeningVM()
log('Active listeners: ${activeListenerCount}');  // 0
log('Listening to: ${_listeningTo.length}');      // 0
```

### No Memory Leaks

Calling `stopListeningVM()` ensures no memory leaks from circular references between ViewModels:

```dart
// ViewModel A listens to ViewModel B
// ViewModel B listens to ViewModel A
// Without proper cleanup, this creates a reference cycle

// stopListeningVM() breaks this cycle by removing all listener references
```

## Source Reference

**File**: `lib/src/viewmodel/viewmodel_impl.dart`

**Lines**: 615-637

```dart
void stopListeningVM() {
  final listenerCount = _listeners.length;

  assert(() {
    log('''
    ViewModel<${T.toString()}> stopping listeners
    Removing listeners: $listenerCount
    Listening relationships: ${_listeningTo.length}
    ''', level: 5);
    return true;
  }());

  // Remove all listeners from ChangeNotifier
  for (final callback in _listeners.values) {
    removeListener(callback);
  }

  // Clear tracking maps
  _listeners.clear();
  _listeningTo.clear();
}
```

## Called Automatically By

`stopListeningVM()` is called automatically in the following scenarios:

1. **dispose()** - During ViewModel disposal (line 384 in source)
2. **cleanCurrentNotifier()** - When ReactiveNotifier cleans up its instance

## Related Methods

- [listenVM()](listen-vm.md) - Register a listener for reactive communication
- [stopSpecificListener()](stop-specific-listener.md) - Remove a specific listener by key
