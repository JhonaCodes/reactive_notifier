# setupListeners() Method

## Method Signature

### ViewModel<T>
```dart
@mustCallSuper
Future<void> setupListeners({List<String> currentListeners = const []}) async;
```

### AsyncViewModelImpl<T>
```dart
@mustCallSuper
Future<void> setupListeners({List<String> currentListeners = const []}) async;
```

## Purpose

The `setupListeners()` method is the designated hook for registering external listeners from other notifiers and services. It provides a centralized location for all listener registration, making it easier to manage dependencies and ensure proper cleanup through its counterpart `removeListeners()`.

**Key Responsibilities:**
- Register listeners to external notifiers
- Set up inter-ViewModel communication
- Establish reactive data flow between services
- Provide debug logging for registered listeners

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `currentListeners` | `List<String>` | `const []` | List of listener names for debug logging |

## Return Type

`Future<void>`

## When It's Called

### Automatic Invocation

`setupListeners()` is called automatically during initialization:

**ViewModel<T>:**
- Called by `_safeInitialization()` after `init()` completes
- Called by `reload()` after `init()` completes

**AsyncViewModelImpl<T>:**
- Called by `reload()` after `init()` and `updateState()` complete

### Call Sequence

```
Constructor
    |
    v
init()
    |
    v
setupListeners() <-- Called here
    |
    v
onResume()
```

## Source Code Reference

### ViewModel<T> Implementation

From `viewmodel_impl.dart` (lines 101-113):

```dart
@mustCallSuper
Future<void> setupListeners({List<String> currentListeners = const []}) async {
  if (currentListeners.isNotEmpty) {
    assert(() {
      logSetup<T>(listeners: currentListeners);
      return true;
    }());
  }
}
```

### AsyncViewModelImpl<T> Implementation

From `async_viewmodel_impl.dart` (lines 177-185):

```dart
@mustCallSuper
Future<void> setupListeners({List<String> currentListeners = const []}) async {
  if (currentListeners.isNotEmpty) {
    assert(() {
      logSetup<T>(listeners: currentListeners);
      return true;
    }());
  }
}
```

### Called from _safeInitialization() (ViewModel)

From `viewmodel_impl.dart` (line 215):

```dart
void _safeInitialization() {
  // ...
  init();
  // ...
  unawaited(setupListeners());
}
```

### Called from reload() (AsyncViewModelImpl)

From `async_viewmodel_impl.dart` (lines 132-157):

```dart
Future<void> reload() async {
  // ...
  final result = await init();
  updateState(result);
  await setupListeners(); // <-- Called here
  await onResume(_state.data);
}
```

## Usage Examples

### Basic External Listener Registration

```dart
class OrdersViewModel extends AsyncViewModelImpl<List<Order>> {
  // Store listener as class property for proper cleanup
  Future<void> _onUserChanged() async {
    if (hasInitializedListenerExecution) {
      await _reloadOrdersForCurrentUser();
    }
  }

  @override
  Future<List<Order>> init() async {
    final userId = UserService.currentUser.notifier.data?.id;
    if (userId != null) {
      return await orderRepository.fetchOrders(userId);
    }
    return [];
  }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    // Register listener to user changes
    UserService.currentUser.notifier.addListener(_onUserChanged);

    // Call super with listener names for debug logging
    await super.setupListeners(currentListeners: ['_onUserChanged']);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    // Remove the registered listener
    UserService.currentUser.notifier.removeListener(_onUserChanged);
    await super.removeListeners(currentListeners: ['_onUserChanged']);
  }

  Future<void> _reloadOrdersForCurrentUser() async {
    await reload();
  }
}
```

### Multiple External Listeners

```dart
class DashboardViewModel extends AsyncViewModelImpl<DashboardState> {
  Future<void> _onUserUpdated() async {
    if (hasInitializedListenerExecution) {
      await _refreshUserSection();
    }
  }

  Future<void> _onOrdersUpdated() async {
    if (hasInitializedListenerExecution) {
      await _refreshOrdersSection();
    }
  }

  Future<void> _onNotificationsUpdated() async {
    if (hasInitializedListenerExecution) {
      await _refreshNotificationsSection();
    }
  }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    // Register multiple listeners
    UserService.currentUser.notifier.addListener(_onUserUpdated);
    OrderService.orders.notifier.addListener(_onOrdersUpdated);
    NotificationService.notifications.notifier.addListener(_onNotificationsUpdated);

    await super.setupListeners(currentListeners: [
      '_onUserUpdated',
      '_onOrdersUpdated',
      '_onNotificationsUpdated',
    ]);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    UserService.currentUser.notifier.removeListener(_onUserUpdated);
    OrderService.orders.notifier.removeListener(_onOrdersUpdated);
    NotificationService.notifications.notifier.removeListener(_onNotificationsUpdated);

    await super.removeListeners(currentListeners: [
      '_onUserUpdated',
      '_onOrdersUpdated',
      '_onNotificationsUpdated',
    ]);
  }
}
```

### Using hasInitializedListenerExecution Guard

```dart
class SalesViewModel extends AsyncViewModelImpl<SalesData> {
  Future<void> _onCartChanged() async {
    // IMPORTANT: Guard against premature listener execution
    // This prevents duplicate data loading during initialization
    if (hasInitializedListenerExecution) {
      await _processSaleFromCart();
    }
  }

  @override
  Future<SalesData> init() async {
    return await salesRepository.fetchCurrentSales();
  }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    CartService.cart.notifier.addListener(_onCartChanged);
    await super.setupListeners(currentListeners: ['_onCartChanged']);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    CartService.cart.notifier.removeListener(_onCartChanged);
    await super.removeListeners(currentListeners: ['_onCartChanged']);
  }
}
```

### Combining with listenVM() (Alternative Pattern)

```dart
class NotificationViewModel extends ViewModel<NotificationState> {
  UserModel? currentUser;

  @override
  void init() {
    updateSilently(NotificationState.empty());

    // Using listenVM for reactive communication (automatic tracking)
    UserService.currentUser.notifier.listenVM((userData) {
      currentUser = userData;
      _updateNotificationsForUser(userData);
    });
  }

  // setupListeners() is for EXTERNAL addListener() calls
  // listenVM() handles its own listener management automatically
  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    // Only needed for addListener() registrations
    await super.setupListeners(currentListeners: currentListeners);
  }
}
```

### Conditional Listener Registration

```dart
class FeatureViewModel extends AsyncViewModelImpl<FeatureState> {
  Future<void> _onConfigChanged() async {
    if (hasInitializedListenerExecution) {
      await reload();
    }
  }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    final listeners = <String>[];

    // Only register if feature is enabled
    if (FeatureFlags.isEnabled('advanced_sync')) {
      ConfigService.config.notifier.addListener(_onConfigChanged);
      listeners.add('_onConfigChanged');
    }

    await super.setupListeners(currentListeners: listeners);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    final listeners = <String>[];

    if (FeatureFlags.isEnabled('advanced_sync')) {
      ConfigService.config.notifier.removeListener(_onConfigChanged);
      listeners.add('_onConfigChanged');
    }

    await super.removeListeners(currentListeners: listeners);
  }
}
```

### Stream Subscription in setupListeners

```dart
class RealtimeViewModel extends AsyncViewModelImpl<RealtimeData> {
  StreamSubscription? _realtimeSubscription;

  @override
  Future<RealtimeData> init() async {
    return await apiService.fetchInitialData();
  }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    // Cancel existing subscription first
    await _realtimeSubscription?.cancel();

    // Set up new stream subscription
    _realtimeSubscription = realtimeService
        .dataStream()
        .listen(_handleRealtimeUpdate);

    await super.setupListeners(currentListeners: ['_realtimeSubscription']);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;

    await super.removeListeners(currentListeners: ['_realtimeSubscription']);
  }

  void _handleRealtimeUpdate(RealtimeUpdate update) {
    transformDataState((current) => current?.applyUpdate(update));
  }
}
```

## Best Practices

### 1. Always Pair with removeListeners()

```dart
@override
Future<void> setupListeners({List<String> currentListeners = const []}) async {
  ExternalService.notifier.addListener(_listener);
  await super.setupListeners(currentListeners: ['_listener']);
}

@override
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  ExternalService.notifier.removeListener(_listener); // MUST match setupListeners
  await super.removeListeners(currentListeners: ['_listener']);
}
```

### 2. Use hasInitializedListenerExecution Guard

```dart
Future<void> _myListener() async {
  // Prevent execution during initial load
  if (hasInitializedListenerExecution) {
    await _handleUpdate();
  }
}
```

### 3. Store Listeners as Class Properties

```dart
// GOOD - Can be properly removed
class GoodViewModel extends ViewModel<State> {
  Future<void> _onDataChanged() async { /* ... */ }

  @override
  Future<void> setupListeners(...) async {
    DataService.notifier.addListener(_onDataChanged);
  }

  @override
  Future<void> removeListeners(...) async {
    DataService.notifier.removeListener(_onDataChanged);
  }
}

// BAD - Anonymous function cannot be removed
class BadViewModel extends ViewModel<State> {
  @override
  Future<void> setupListeners(...) async {
    DataService.notifier.addListener(() async {
      // Cannot remove this listener!
    });
  }
}
```

### 4. Call super with Listener Names

```dart
@override
Future<void> setupListeners({List<String> currentListeners = const []}) async {
  // Add your listeners
  SomeService.notifier.addListener(_myListener);

  // Pass listener names to super for debug logging
  await super.setupListeners(currentListeners: ['_myListener']);
}
```

### 5. Handle Async Listeners Properly

```dart
Future<void> _asyncListener() async {
  if (!hasInitializedListenerExecution) return;
  if (isDisposed) return; // Check disposal state

  try {
    await _processUpdate();
  } catch (e) {
    log('Listener error: $e');
  }
}
```

## Common Mistakes to Avoid

### 1. Not Removing Listeners

```dart
// WRONG - Memory leak!
@override
Future<void> setupListeners(...) async {
  ExternalService.notifier.addListener(_listener);
}
// Missing removeListeners() override!

// CORRECT
@override
Future<void> removeListeners(...) async {
  ExternalService.notifier.removeListener(_listener);
  await super.removeListeners(currentListeners: ['_listener']);
}
```

### 2. Using Anonymous Functions

```dart
// WRONG - Cannot remove anonymous functions
@override
Future<void> setupListeners(...) async {
  ExternalService.notifier.addListener(() {
    doSomething(); // Cannot be removed!
  });
}

// CORRECT - Use named method
void _handleChange() {
  doSomething();
}

@override
Future<void> setupListeners(...) async {
  ExternalService.notifier.addListener(_handleChange);
}
```

### 3. Missing hasInitializedListenerExecution Guard

```dart
// WRONG - May cause duplicate loading during init
Future<void> _onExternalChange() async {
  await reload(); // Called during setupListeners too!
}

// CORRECT - Guard against premature execution
Future<void> _onExternalChange() async {
  if (hasInitializedListenerExecution) {
    await reload();
  }
}
```

### 4. Forgetting to Call super

```dart
// WRONG - Breaks debug logging
@override
Future<void> setupListeners(...) async {
  ExternalService.notifier.addListener(_listener);
  // Missing super.setupListeners() call!
}

// CORRECT
@override
Future<void> setupListeners({List<String> currentListeners = const []}) async {
  ExternalService.notifier.addListener(_listener);
  await super.setupListeners(currentListeners: ['_listener']);
}
```

### 5. Mismatched Registration/Removal

```dart
// WRONG - Different methods registered vs removed
@override
Future<void> setupListeners(...) async {
  ExternalService.notifier.addListener(_listenerA);
}

@override
Future<void> removeListeners(...) async {
  ExternalService.notifier.removeListener(_listenerB); // Wrong listener!
}

// CORRECT - Match exactly
@override
Future<void> setupListeners(...) async {
  ExternalService.notifier.addListener(_listenerA);
}

@override
Future<void> removeListeners(...) async {
  ExternalService.notifier.removeListener(_listenerA); // Same listener
}
```

## Lifecycle Position

`setupListeners()` is called after `init()` but before `onResume()`:

```
Constructor -> init() -> setupListeners() -> onResume()
                              ^
                              |
                        You are here
```

## listenVM() vs setupListeners()

| Feature | listenVM() | setupListeners() |
|---------|------------|------------------|
| **Purpose** | Cross-ViewModel reactive communication | External listener registration |
| **Cleanup** | Automatic via stopListeningVM() | Manual via removeListeners() |
| **Location** | Used in init() | Override as method |
| **Tracking** | Automatic with internal maps | Manual with currentListeners param |
| **Use Case** | Listen to other ViewModels | Listen to external notifiers/services |

## Related Methods

- `removeListeners()` - Counterpart for cleanup, must match registrations
- `init()` - Runs before setupListeners()
- `onResume()` - Runs after setupListeners()
- `reload()` - Calls setupListeners() as part of refresh cycle
- `listenVM()` - Alternative for cross-ViewModel communication with automatic cleanup
- `hasInitializedListenerExecution` - Guard flag for listener callbacks
