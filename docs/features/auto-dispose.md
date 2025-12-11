# Auto-Dispose: Widget-Aware Lifecycle Management

## Overview

Auto-Dispose is a feature introduced in ReactiveNotifier v2.13.0 that provides automatic memory management based on widget usage. It solves the fundamental challenge of singleton state management: **how to maintain the "create once, reuse always" philosophy while still allowing proper memory cleanup when state is no longer needed**.

### The Problem It Solves

In traditional singleton-based state management, state instances live for the entire application lifecycle. This creates two issues:

1. **Memory Accumulation**: State objects remain in memory even when no widget uses them
2. **Stale State**: Previously used state persists when navigating back to screens

Auto-Dispose addresses both issues by:
- Tracking which widgets are actively using a ReactiveNotifier instance
- Automatically disposing instances when no widgets reference them (after a configurable timeout)
- Recreating fresh instances when widgets need the state again

### How It Works

```
[Widget A mounts] --> addReference("widget_a")     --> referenceCount: 1
[Widget B mounts] --> addReference("widget_b")     --> referenceCount: 2
[Widget B unmounts] --> removeReference("widget_b") --> referenceCount: 1
[Widget A unmounts] --> removeReference("widget_a") --> referenceCount: 0
                                                        |
                                                        v
                                                   [Start Timer]
                                                        |
                                                        v (after timeout)
                                                   [Auto-Dispose]
                                                        |
[Widget C mounts] <-- Fresh instance recreated <-- [Recreation on demand]
```

---

## Enabling Auto-Dispose

### Constructor Parameter

Enable auto-dispose when creating a ReactiveNotifier by setting `autoDispose: true`:

```dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
    ReactiveNotifier<UserViewModel>(
      () => UserViewModel(),
      autoDispose: true, // Enable automatic disposal
    );
}
```

### Source Code Reference

From `/lib/src/notifier/reactive_notifier.dart`:

```dart
factory ReactiveNotifier(T Function() create,
    {List<ReactiveNotifier>? related, Key? key, bool autoDispose = false}) {
  // ...
  final instance = ReactiveNotifier._(create, related, key, autoDispose);
  // ...
}
```

The `autoDispose` parameter is stored as a final field and checked when reference count reaches zero.

---

## Configuring Auto-Dispose Timeout

### enableAutoDispose() Method

Configure the timeout duration using `enableAutoDispose()`:

```dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
    ReactiveNotifier<UserViewModel>(
      () => UserViewModel(),
      autoDispose: true,
    );

  // Configure custom timeout
  static void configureAutoDispose() {
    userState.enableAutoDispose(timeout: const Duration(minutes: 5));
  }
}
```

### Method Signature

```dart
/// Configure auto-dispose timeout for this instance
void enableAutoDispose({Duration? timeout}) {
  if (timeout != null) {
    _autoDisposeTimeout = timeout;
  }
}
```

### Default Timeout

The default auto-dispose timeout is **30 seconds**:

```dart
Duration _autoDisposeTimeout = const Duration(seconds: 30);
```

### Recommended Timeouts by Use Case

| Use Case | Recommended Timeout | Reason |
|----------|---------------------|--------|
| User session state | 5-10 minutes | Allow navigation without losing auth |
| Screen-specific state | 30 seconds (default) | Quick cleanup after leaving screen |
| Cache/temporary data | 1-2 minutes | Balance memory vs reload time |
| Heavy data (images, lists) | 10-30 seconds | Quick memory recovery |

---

## Reference Counting System

The reference counting system tracks active widget usage of each ReactiveNotifier instance.

### referenceCount Getter

Returns the current number of widgets actively using this notifier:

```dart
int get referenceCount => _referenceCount;
```

**Usage:**
```dart
// Check how many widgets are using this state
final count = UserService.userState.referenceCount;
log('Active widgets using user state: $count');
```

### isScheduledForDispose Getter

Returns whether the instance is currently scheduled for automatic disposal:

```dart
bool get isScheduledForDispose => _isScheduledForDispose;
```

**Usage:**
```dart
if (UserService.userState.isScheduledForDispose) {
  log('User state will be disposed soon - consider cancelling if needed');
}
```

### activeReferences Getter

Returns a copy of the set containing all active reference IDs:

```dart
Set<String> get activeReferences => Set.from(_activeReferences);
```

**Usage:**
```dart
// Debug which widgets are currently using this state
final refs = UserService.userState.activeReferences;
for (final ref in refs) {
  log('Active reference: $ref');
}
```

### addReference() Method

Registers a new reference when a widget starts using the notifier:

```dart
void addReference(String referenceId) {
  // Only increment if this is a new reference
  if (_activeReferences.add(referenceId)) {
    _referenceCount++;
  }

  // Cancel auto-dispose if scheduled
  if (_isScheduledForDispose) {
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _isScheduledForDispose = false;
  }
}
```

**Key Behaviors:**
- Duplicate reference IDs are ignored (no double-counting)
- Cancels any pending auto-dispose when a new reference is added
- Automatically called by ReactiveBuilder widgets

**Usage (typically internal):**
```dart
// Called automatically by builders, but can be used manually:
UserService.userState.addReference('my_custom_widget_${hashCode}');
```

### removeReference() Method

Unregisters a reference when a widget stops using the notifier:

```dart
void removeReference(String referenceId) {
  // Only decrement if reference actually existed
  if (_activeReferences.remove(referenceId)) {
    _referenceCount--;
  }

  // Schedule auto-dispose if no more references and auto-dispose is enabled
  if (_referenceCount <= 0 && autoDispose && !_isScheduledForDispose) {
    _scheduleAutoDispose();
  }
}
```

**Key Behaviors:**
- Only decrements if the reference ID was actually registered
- Triggers auto-dispose scheduling when count reaches zero
- Automatically called by ReactiveBuilder widgets on dispose

**Usage (typically internal):**
```dart
// Called automatically by builders, but can be used manually:
UserService.userState.removeReference('my_custom_widget_${hashCode}');
```

---

## How Automatic Disposal Works

### The Disposal Process

When the reference count reaches zero and auto-dispose is enabled:

1. **Timer Starts**: A timer is scheduled for the configured timeout duration
2. **Waiting Period**: The instance waits for new references during this period
3. **Cancellation Check**: If a new reference is added, the timer is cancelled
4. **Final Disposal**: If no references are added, the instance is disposed

```dart
void _scheduleAutoDispose() {
  if (_isScheduledForDispose || _disposed) return;

  _isScheduledForDispose = true;
  _disposeTimer = Timer(_autoDisposeTimeout, () {
    if (_referenceCount <= 0 && autoDispose && !_disposed) {
      // Perform cleanup
      cleanCurrentNotifier(forceCleanup: true);
    }
    _isScheduledForDispose = false;
  });
}
```

### What Happens During Disposal

The `cleanCurrentNotifier(forceCleanup: true)` method:

1. Stops all active listeners
2. Cleans parent-child relationships
3. Disposes the internal ViewModel (if applicable)
4. Removes the instance from the global registry
5. Makes the slot available for recreation

### Recreation on Demand

When a widget needs a disposed notifier, ReactiveNotifier automatically creates a fresh instance:

```dart
// After disposal, the next access creates a new instance
ReactiveBuilder<UserViewModel>(
  notifier: UserService.userState, // Fresh instance created automatically
  build: (user, notifier, keep) => Text(user.name),
)
```

---

## Manual Reinitialization

### reinitializeInstance() Static Method

Force recreation of an instance with fresh state:

```dart
static T reinitializeInstance<T>(Key key, T Function() creator) {
  if (!_instances.containsKey(key)) {
    throw StateError('Cannot reinitialize - instance not found');
  }

  final instance = _instances[key] as ReactiveNotifier<T>;

  // Cancel any pending auto-dispose
  instance._disposeTimer?.cancel();
  instance._disposeTimer = null;
  instance._isScheduledForDispose = false;

  // Reset dispose flag
  instance._disposed = false;

  // Create fresh state
  final newState = creator();

  // Dispose old ViewModel if applicable
  // ...

  // Replace with new state
  instance.replaceNotifier(newState);

  // Notify listeners of the fresh state
  instance.notifyListeners();

  return newState;
}
```

**Usage:**
```dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> userState =
    ReactiveNotifier<UserViewModel>(() => UserViewModel());

  static void logout() {
    // Reinitialize with fresh state after logout
    ReactiveNotifier.reinitializeInstance<UserViewModel>(
      userState.keyNotifier,
      () => UserViewModel(), // Fresh ViewModel
    );
  }
}
```

### isInstanceActive() Static Method

Check if an instance is active (not disposed):

```dart
static bool isInstanceActive<T>(Key key) {
  if (!_instances.containsKey(key)) {
    return false;
  }

  final instance = _instances[key] as ReactiveNotifier<T>?;
  return instance != null && !instance._disposed;
}
```

**Usage:**
```dart
mixin UserService {
  static bool get isUserActive =>
    ReactiveNotifier.isInstanceActive<UserViewModel>(userState.keyNotifier);

  static void ensureUserInitialized() {
    if (!isUserActive) {
      // Handle re-initialization
    }
  }
}
```

---

## Debug Information

### Debug Logging

In debug mode, auto-dispose provides detailed logging:

**Reference Added:**
```
+++ Reference added to ReactiveNotifier<UserViewModel>
----------------------------------------------------
Reference: widget_12345
Total references: 1
Auto-dispose enabled: true
----------------------------------------------------
```

**Reference Removed:**
```
--- Reference removed from ReactiveNotifier<UserViewModel>
----------------------------------------------------
Reference: widget_12345
Remaining references: 0
Auto-dispose enabled: true
----------------------------------------------------
```

**Auto-Dispose Scheduled:**
```
Timer: Auto-dispose scheduled for ReactiveNotifier<UserViewModel>
----------------------------------------------------
Timeout: 30s
Current references: 0
Will dispose if no references are added
----------------------------------------------------
```

**Auto-Dispose Cancelled:**
```
Refresh: Auto-dispose cancelled for ReactiveNotifier<UserViewModel>
----------------------------------------------------
Reference added: widget_67890
Active references: 1
Reason: New widget started using this notifier
----------------------------------------------------
```

**Auto-Dispose Executed:**
```
Trash: Auto-disposing ReactiveNotifier<UserViewModel>
----------------------------------------------------
Key: [#12345]
Timeout: 30s
Final reference count: 0
----------------------------------------------------
```

### Monitoring in Development

```dart
class MemoryDebugHelper {
  static void logNotifierStatus<T>(ReactiveNotifier<T> notifier) {
    assert(() {
      log('''
Memory Status for ReactiveNotifier<$T>
========================================
Reference count: ${notifier.referenceCount}
Scheduled for dispose: ${notifier.isScheduledForDispose}
Active references: ${notifier.activeReferences}
Auto-dispose enabled: ${notifier.autoDispose}
========================================
''');
      return true;
    }());
  }
}

// Usage
MemoryDebugHelper.logNotifierStatus(UserService.userState);
```

---

## Complete Usage Examples

### Example 1: Basic Auto-Dispose Setup

```dart
// Service definition
mixin ProductService {
  static final ReactiveNotifier<ProductViewModel> products =
    ReactiveNotifier<ProductViewModel>(
      () => ProductViewModel(),
      autoDispose: true,
    );
}

// ViewModel
class ProductViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductViewModel() : super(AsyncState.initial());

  @override
  Future<List<Product>> init() async {
    return await ProductRepository.fetchProducts();
  }
}

// Widget usage
class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<ProductViewModel, List<Product>>(
      notifier: ProductService.products.notifier,
      onData: (products, vm, keep) => ListView.builder(
        itemCount: products.length,
        itemBuilder: (_, i) => ProductTile(product: products[i]),
      ),
      onLoading: () => const CircularProgressIndicator(),
      onError: (error, stack) => Text('Error: $error'),
    );
  }
}

// When user navigates away from ProductListScreen:
// 1. Reference count drops to 0
// 2. After 30 seconds (default), ProductViewModel is disposed
// 3. When user returns, fresh ProductViewModel is created and data is fetched again
```

### Example 2: Custom Timeout for User Session

```dart
mixin AuthService {
  static final ReactiveNotifier<AuthViewModel> auth =
    ReactiveNotifier<AuthViewModel>(
      () => AuthViewModel(),
      autoDispose: true,
    );

  static void initialize() {
    // Keep auth state for 10 minutes after last widget usage
    auth.enableAutoDispose(timeout: const Duration(minutes: 10));
  }
}

// Call during app startup
void main() {
  AuthService.initialize();
  runApp(MyApp());
}
```

### Example 3: Manual Logout with Reinitialize

```dart
mixin UserService {
  static final ReactiveNotifier<UserViewModel> currentUser =
    ReactiveNotifier<UserViewModel>(
      () => UserViewModel(),
      autoDispose: true,
    );

  static Future<void> logout() async {
    // Clear server session
    await AuthRepository.logout();

    // Reinitialize with fresh state
    ReactiveNotifier.reinitializeInstance<UserViewModel>(
      currentUser.keyNotifier,
      () => UserViewModel(), // Fresh, logged-out state
    );
  }

  static bool get isLoggedIn =>
    ReactiveNotifier.isInstanceActive<UserViewModel>(currentUser.keyNotifier) &&
    currentUser.notifier.data.isAuthenticated;
}
```

### Example 4: Multiple Screens Sharing State

```dart
mixin CartService {
  static final ReactiveNotifier<CartViewModel> cart =
    ReactiveNotifier<CartViewModel>(
      () => CartViewModel(),
      autoDispose: true,
    );
}

// Screen 1: Product list with "Add to Cart" buttons
class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<CartViewModel>(
      notifier: CartService.cart,
      build: (cart, notifier, keep) => Column(
        children: [
          Text('Cart items: ${cart.itemCount}'),
          // ... product list
        ],
      ),
    );
  }
}

// Screen 2: Cart detail
class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<CartViewModel>(
      notifier: CartService.cart,
      build: (cart, notifier, keep) => ListView.builder(
        itemCount: cart.items.length,
        itemBuilder: (_, i) => CartItemTile(item: cart.items[i]),
      ),
    );
  }
}

// Both screens share the same CartViewModel
// Reference count = 2 when both are visible
// Reference count = 1 when one is visible
// Reference count = 0 only when neither is visible (e.g., order completed)
```

### Example 5: Debugging Reference Leaks

```dart
mixin DataService {
  static final ReactiveNotifier<DataViewModel> data =
    ReactiveNotifier<DataViewModel>(
      () => DataViewModel(),
      autoDispose: true,
    );

  static void debugReferences() {
    final refs = data.activeReferences;
    final count = data.referenceCount;
    final scheduled = data.isScheduledForDispose;

    assert(() {
      log('''
DataService Reference Debug
============================
Reference count: $count
Scheduled for dispose: $scheduled
Active references:
${refs.map((r) => '  - $r').join('\n')}
============================
''');
      return true;
    }());
  }
}

// Use in development to track reference leaks
@override
void dispose() {
  DataService.debugReferences(); // Check before widget disposes
  super.dispose();
}
```

---

## Best Practices

### 1. Enable Auto-Dispose for Screen-Specific State

```dart
// Good: Auto-dispose for screen-specific state
mixin OrderHistoryService {
  static final ReactiveNotifier<OrderHistoryViewModel> orders =
    ReactiveNotifier<OrderHistoryViewModel>(
      () => OrderHistoryViewModel(),
      autoDispose: true, // Clean up when leaving order history
    );
}
```

### 2. Use Longer Timeouts for Shared State

```dart
// Good: Longer timeout for frequently accessed state
mixin AppConfigService {
  static final ReactiveNotifier<AppConfigViewModel> config =
    ReactiveNotifier<AppConfigViewModel>(
      () => AppConfigViewModel(),
      autoDispose: true,
    );

  static void initialize() {
    config.enableAutoDispose(timeout: const Duration(minutes: 15));
  }
}
```

### 3. Disable Auto-Dispose for Critical State

```dart
// Good: No auto-dispose for critical app-wide state
mixin AuthService {
  static final ReactiveNotifier<AuthViewModel> auth =
    ReactiveNotifier<AuthViewModel>(
      () => AuthViewModel(),
      autoDispose: false, // Never auto-dispose auth state
    );
}
```

### 4. Use reinitializeInstance for Explicit Reset

```dart
// Good: Explicit reset when needed
class LogoutHandler {
  static Future<void> performLogout() async {
    await AuthApi.logout();

    // Explicitly reinitialize user-related state
    ReactiveNotifier.reinitializeInstance<UserViewModel>(
      UserService.user.keyNotifier,
      () => UserViewModel(),
    );

    ReactiveNotifier.reinitializeInstance<CartViewModel>(
      CartService.cart.keyNotifier,
      () => CartViewModel(),
    );
  }
}
```

### 5. Monitor References in Development

```dart
// Good: Add development-only monitoring
class DebugOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(8),
        child: Text(
          'User refs: ${UserService.userState.referenceCount}\n'
          'Cart refs: ${CartService.cart.referenceCount}',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
```

---

## When to Use vs When Not to Use

### Use Auto-Dispose When:

| Scenario | Reason |
|----------|--------|
| Screen-specific data | Clean up when user leaves screen |
| Temporary lists/search results | Recover memory after viewing |
| Form state | Reset when form is closed |
| Detail view state | Fresh data when returning |
| Cache with short lifetime | Automatic cache invalidation |

### Do NOT Use Auto-Dispose When:

| Scenario | Reason |
|----------|--------|
| Authentication state | Must persist across app |
| User preferences | Should survive navigation |
| App configuration | Loaded once, used everywhere |
| Background sync state | Must continue without UI |
| Critical business state | Loss could cause issues |

### Decision Tree

```
Should I use autoDispose?
         |
         v
Is the state critical for app operation?
    |           |
   YES          NO
    |           |
    v           v
autoDispose: false    Is the state used across many screens?
                           |           |
                          YES          NO
                           |           |
                           v           v
                      Consider longer timeout    autoDispose: true
                      (5-10 minutes)             (default 30 seconds)
```

---

## Migration Guide

### From Manual Cleanup

**Before (manual cleanup):**
```dart
mixin DataService {
  static final ReactiveNotifier<DataViewModel> data =
    ReactiveNotifier<DataViewModel>(() => DataViewModel());

  // Manual cleanup scattered across code
  static void cleanupData() {
    ReactiveNotifier.cleanupByType<DataViewModel>();
  }
}

// In widget
@override
void dispose() {
  DataService.cleanupData(); // Easy to forget!
  super.dispose();
}
```

**After (auto-dispose):**
```dart
mixin DataService {
  static final ReactiveNotifier<DataViewModel> data =
    ReactiveNotifier<DataViewModel>(
      () => DataViewModel(),
      autoDispose: true, // Automatic cleanup!
    );
}

// In widget - no manual cleanup needed
@override
void dispose() {
  super.dispose(); // That's it!
}
```

### Gradual Migration

1. **Start with non-critical state**: Enable auto-dispose for screen-specific state first
2. **Monitor in development**: Use debug logging to verify expected behavior
3. **Adjust timeouts**: Fine-tune based on user navigation patterns
4. **Expand gradually**: Enable for more state types as confidence grows

---

## Summary

Auto-Dispose provides:

- **Automatic Memory Management**: No manual cleanup required
- **Reference Tracking**: Know exactly which widgets use your state
- **Configurable Timeouts**: Balance memory vs user experience
- **Manual Override**: Use `reinitializeInstance` when explicit control needed
- **Full Debug Support**: Comprehensive logging for development
- **Zero Breaking Changes**: Opt-in feature, existing code unchanged

The feature maintains ReactiveNotifier's "create once, reuse always" philosophy while adding intelligent lifecycle management that responds to actual widget usage.
