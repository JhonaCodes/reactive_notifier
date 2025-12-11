# removeListeners() Method

## Method Signature

### ViewModel<T>
```dart
@mustCallSuper
Future<void> removeListeners({List<String> currentListeners = const []}) async;
```

### AsyncViewModelImpl<T>
```dart
@mustCallSuper
Future<void> removeListeners({List<String> currentListeners = const []}) async;
```

## Purpose

The `removeListeners()` method is the designated hook for unregistering external listeners that were set up in `setupListeners()`. It ensures proper cleanup of listener connections to prevent memory leaks and avoid callbacks to disposed ViewModels.

**Key Responsibilities:**
- Remove listeners from external notifiers
- Clean up inter-ViewModel communication channels
- Prevent memory leaks from dangling listener references
- Provide debug logging for removed listeners

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `currentListeners` | `List<String>` | `const []` | List of listener names for debug logging |

## Return Type

`Future<void>`

## When It's Called

### Automatic Invocation

`removeListeners()` is called automatically in several scenarios:

**ViewModel<T>:**
- Called by `dispose()` during ViewModel cleanup
- Called by `reload()` before re-initialization (if already initialized)
- Called by `cleanState()` during state reset

**AsyncViewModelImpl<T>:**
- Called by `dispose()` during ViewModel cleanup
- Called by `reload()` before re-initialization (if not first load)
- Called by `cleanState()` during state reset

### Call Sequences

**During dispose():**
```
dispose()
    |
    v
removeListeners() <-- Called here
    |
    v
stopListeningVM()
    |
    v
super.dispose()
```

**During reload():**
```
reload()
    |
    v
removeListeners() <-- Called here (if initialized)
    |
    v
init()
    |
    v
setupListeners()
```

## Source Code Reference

### ViewModel<T> Implementation

From `viewmodel_impl.dart` (lines 90-99):

```dart
@mustCallSuper
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  if (currentListeners.isNotEmpty) {
    assert(() {
      logRemove<T>(listeners: currentListeners);
      return true;
    }());
  }
}
```

### AsyncViewModelImpl<T> Implementation

From `async_viewmodel_impl.dart` (lines 159-171):

```dart
@mustCallSuper
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  if (currentListeners.isNotEmpty) {
    assert(() {
      logRemove<T>(listeners: currentListeners);
      return true;
    }());
  }
}
```

### Called from dispose() (ViewModel)

From `viewmodel_impl.dart` (lines 363-412):

```dart
@override
void dispose() {
  if (_disposed) return;

  // 1. Remove all external listeners registered via setupListeners()
  removeListeners(); // <-- Called here

  // 2. Stop internal listenVM() connections to other ViewModels
  stopListeningVM();

  // ...
}
```

### Called from reload() (AsyncViewModelImpl)

From `async_viewmodel_impl.dart` (lines 132-157):

```dart
Future<void> reload() async {
  if (_state.isLoading) return;
  try {
    if (!loadOnInit) {
      await removeListeners(); // <-- Called here before re-init
    }
    loadOnInit = false;
    loadingState();
    final result = await init();
    // ...
  }
}
```

## Usage Examples

### Basic Listener Removal

```dart
class OrdersViewModel extends AsyncViewModelImpl<List<Order>> {
  Future<void> _onUserChanged() async {
    if (hasInitializedListenerExecution) {
      await reload();
    }
  }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    UserService.currentUser.notifier.addListener(_onUserChanged);
    await super.setupListeners(currentListeners: ['_onUserChanged']);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    // Remove the exact same listener that was added
    UserService.currentUser.notifier.removeListener(_onUserChanged);
    await super.removeListeners(currentListeners: ['_onUserChanged']);
  }
}
```

### Multiple Listener Removal

```dart
class DashboardViewModel extends AsyncViewModelImpl<DashboardState> {
  Future<void> _onUserUpdated() async { /* ... */ }
  Future<void> _onOrdersUpdated() async { /* ... */ }
  Future<void> _onSettingsUpdated() async { /* ... */ }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    UserService.user.notifier.addListener(_onUserUpdated);
    OrderService.orders.notifier.addListener(_onOrdersUpdated);
    SettingsService.settings.notifier.addListener(_onSettingsUpdated);

    await super.setupListeners(currentListeners: [
      '_onUserUpdated',
      '_onOrdersUpdated',
      '_onSettingsUpdated',
    ]);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    // Remove ALL listeners in the same order or reverse order
    UserService.user.notifier.removeListener(_onUserUpdated);
    OrderService.orders.notifier.removeListener(_onOrdersUpdated);
    SettingsService.settings.notifier.removeListener(_onSettingsUpdated);

    await super.removeListeners(currentListeners: [
      '_onUserUpdated',
      '_onOrdersUpdated',
      '_onSettingsUpdated',
    ]);
  }
}
```

### Stream Subscription Cleanup

```dart
class RealtimeViewModel extends AsyncViewModelImpl<RealtimeData> {
  StreamSubscription? _dataSubscription;
  StreamSubscription? _statusSubscription;

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    _dataSubscription = realtimeService.dataStream.listen(_handleData);
    _statusSubscription = realtimeService.statusStream.listen(_handleStatus);

    await super.setupListeners(currentListeners: [
      '_dataSubscription',
      '_statusSubscription',
    ]);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    // Cancel subscriptions and null references
    await _dataSubscription?.cancel();
    _dataSubscription = null;

    await _statusSubscription?.cancel();
    _statusSubscription = null;

    await super.removeListeners(currentListeners: [
      '_dataSubscription',
      '_statusSubscription',
    ]);
  }
}
```

### Conditional Listener Removal

```dart
class FeatureViewModel extends AsyncViewModelImpl<FeatureState> {
  bool _configListenerRegistered = false;

  Future<void> _onConfigChanged() async { /* ... */ }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    final listeners = <String>[];

    if (FeatureFlags.isEnabled('config_sync')) {
      ConfigService.config.notifier.addListener(_onConfigChanged);
      _configListenerRegistered = true;
      listeners.add('_onConfigChanged');
    }

    await super.setupListeners(currentListeners: listeners);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    final listeners = <String>[];

    // Only remove if it was registered
    if (_configListenerRegistered) {
      ConfigService.config.notifier.removeListener(_onConfigChanged);
      _configListenerRegistered = false;
      listeners.add('_onConfigChanged');
    }

    await super.removeListeners(currentListeners: listeners);
  }
}
```

### Safe Removal with Null Checks

```dart
class SafeViewModel extends AsyncViewModelImpl<SafeData> {
  VoidCallback? _listenerA;
  VoidCallback? _listenerB;

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    _listenerA = () => _handleA();
    _listenerB = () => _handleB();

    ServiceA.notifier.addListener(_listenerA!);
    ServiceB.notifier.addListener(_listenerB!);

    await super.setupListeners(currentListeners: ['_listenerA', '_listenerB']);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    // Safe removal with null checks
    if (_listenerA != null) {
      ServiceA.notifier.removeListener(_listenerA!);
      _listenerA = null;
    }

    if (_listenerB != null) {
      ServiceB.notifier.removeListener(_listenerB!);
      _listenerB = null;
    }

    await super.removeListeners(currentListeners: ['_listenerA', '_listenerB']);
  }
}
```

### Timer and Periodic Task Cleanup

```dart
class PollingViewModel extends AsyncViewModelImpl<PollingData> {
  Timer? _pollingTimer;
  Timer? _healthCheckTimer;

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (_) => _poll());
    _healthCheckTimer = Timer.periodic(Duration(minutes: 5), (_) => _healthCheck());

    await super.setupListeners(currentListeners: ['_pollingTimer', '_healthCheckTimer']);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    await super.removeListeners(currentListeners: ['_pollingTimer', '_healthCheckTimer']);
  }
}
```

## Best Practices

### 1. Mirror setupListeners() Exactly

```dart
// setupListeners and removeListeners should be mirrors of each other
@override
Future<void> setupListeners({List<String> currentListeners = const []}) async {
  ServiceA.notifier.addListener(_listenerA);
  ServiceB.notifier.addListener(_listenerB);
  await super.setupListeners(currentListeners: ['_listenerA', '_listenerB']);
}

@override
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  ServiceA.notifier.removeListener(_listenerA); // Same as setupListeners
  ServiceB.notifier.removeListener(_listenerB); // Same as setupListeners
  await super.removeListeners(currentListeners: ['_listenerA', '_listenerB']);
}
```

### 2. Always Call super.removeListeners()

```dart
@override
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  // Your cleanup code
  SomeService.notifier.removeListener(_myListener);

  // Always call super
  await super.removeListeners(currentListeners: ['_myListener']);
}
```

### 3. Null Out References After Removal

```dart
@override
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  await _subscription?.cancel();
  _subscription = null; // Help garbage collection

  _timer?.cancel();
  _timer = null; // Prevent accidental reuse

  await super.removeListeners(currentListeners: [...]);
}
```

### 4. Handle Potential Removal Errors

```dart
@override
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  try {
    ExternalService.notifier.removeListener(_listener);
  } catch (e) {
    // Log but don't throw - cleanup should be resilient
    log('Warning: Failed to remove listener: $e');
  }

  await super.removeListeners(currentListeners: ['_listener']);
}
```

### 5. Use Tracking Flags for Conditional Listeners

```dart
bool _isListenerRegistered = false;

@override
Future<void> setupListeners(...) async {
  if (shouldRegister) {
    Service.notifier.addListener(_listener);
    _isListenerRegistered = true;
  }
}

@override
Future<void> removeListeners(...) async {
  if (_isListenerRegistered) {
    Service.notifier.removeListener(_listener);
    _isListenerRegistered = false;
  }
}
```

## Common Mistakes to Avoid

### 1. Forgetting to Implement removeListeners()

```dart
// WRONG - Memory leak!
class LeakyViewModel extends AsyncViewModelImpl<Data> {
  @override
  Future<void> setupListeners(...) async {
    ExternalService.notifier.addListener(_listener);
  }
  // Missing removeListeners() override!
}

// CORRECT
class CleanViewModel extends AsyncViewModelImpl<Data> {
  @override
  Future<void> setupListeners(...) async {
    ExternalService.notifier.addListener(_listener);
    await super.setupListeners(currentListeners: ['_listener']);
  }

  @override
  Future<void> removeListeners(...) async {
    ExternalService.notifier.removeListener(_listener);
    await super.removeListeners(currentListeners: ['_listener']);
  }
}
```

### 2. Removing Wrong Listener Reference

```dart
// WRONG - Different function references
void _listener() => doSomething();

@override
Future<void> setupListeners(...) async {
  ExternalService.notifier.addListener(() => doSomething()); // Anonymous
}

@override
Future<void> removeListeners(...) async {
  ExternalService.notifier.removeListener(_listener); // Different reference!
}

// CORRECT - Use the same reference
@override
Future<void> setupListeners(...) async {
  ExternalService.notifier.addListener(_listener);
}

@override
Future<void> removeListeners(...) async {
  ExternalService.notifier.removeListener(_listener); // Same reference
}
```

### 3. Not Handling Async Cleanup

```dart
// WRONG - Fire and forget
@override
Future<void> removeListeners(...) async {
  _subscription?.cancel(); // Not awaited!
}

// CORRECT - Await async cleanup
@override
Future<void> removeListeners(...) async {
  await _subscription?.cancel(); // Properly awaited
  _subscription = null;
}
```

### 4. Missing super Call

```dart
// WRONG - Breaks debug logging
@override
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  ExternalService.notifier.removeListener(_listener);
  // Missing super.removeListeners() call!
}

// CORRECT
@override
Future<void> removeListeners({List<String> currentListeners = const []}) async {
  ExternalService.notifier.removeListener(_listener);
  await super.removeListeners(currentListeners: ['_listener']);
}
```

### 5. Throwing Exceptions During Cleanup

```dart
// WRONG - Throws during cleanup
@override
Future<void> removeListeners(...) async {
  if (_listener == null) {
    throw StateError('Listener was not set!'); // Don't throw!
  }
  ExternalService.notifier.removeListener(_listener!);
}

// CORRECT - Be defensive during cleanup
@override
Future<void> removeListeners(...) async {
  if (_listener != null) {
    try {
      ExternalService.notifier.removeListener(_listener!);
    } catch (e) {
      log('Cleanup warning: $e');
    }
    _listener = null;
  }
  await super.removeListeners(currentListeners: ['_listener']);
}
```

### 6. Mismatched Listener Counts

```dart
// WRONG - setupListeners adds 3, removeListeners removes 2
@override
Future<void> setupListeners(...) async {
  Service.notifier.addListener(_a);
  Service.notifier.addListener(_b);
  Service.notifier.addListener(_c);
}

@override
Future<void> removeListeners(...) async {
  Service.notifier.removeListener(_a);
  Service.notifier.removeListener(_b);
  // Missing removal of _c!
}
```

## Lifecycle Position

`removeListeners()` is called at cleanup time, before full disposal:

```
Constructor -> init() -> setupListeners() -> onResume()
                                               |
                                               v
                                        [Active State]
                                               |
                    +--------------------------+
                    |                          |
                    v                          v
              reload()                    dispose()
                    |                          |
                    v                          v
            removeListeners()          removeListeners()
                    |                          |
                    v                          v
                init()                  super.dispose()
```

## Difference from stopListeningVM()

| Aspect | removeListeners() | stopListeningVM() |
|--------|-------------------|-------------------|
| **Purpose** | Remove external listeners | Remove listenVM() connections |
| **Scope** | Listeners added via addListener() | Internal ViewModel-to-ViewModel listening |
| **Management** | Manual in setupListeners()/removeListeners() | Automatic via listenVM() |
| **Called by** | dispose(), reload(), cleanState() | dispose() only |

## Related Methods

- `setupListeners()` - Counterpart for registration, must match
- `dispose()` - Calls removeListeners() during cleanup
- `reload()` - Calls removeListeners() before re-initialization
- `cleanState()` - Calls removeListeners() during state reset
- `stopListeningVM()` - Separate cleanup for listenVM() connections
