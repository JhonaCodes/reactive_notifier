# onResume() Method

## Method Signature

### ViewModel<T>
```dart
@protected
FutureOr<void> onResume(T data) async;
```

### AsyncViewModelImpl<T>
```dart
@protected
FutureOr<void> onResume(T? data) async;
```

## Purpose

The `onResume()` method is a post-initialization hook that executes after the ViewModel's primary initialization logic has completed successfully. It provides an opportunity to perform tasks that depend on the initial state being fully established.

**Key Use Cases:**
- Setting up secondary listeners
- Logging initialization completion
- Triggering follow-up actions
- Starting background tasks that depend on initial setup
- Performing operations that require the full initialization chain to be complete

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | `T` (ViewModel) or `T?` (AsyncViewModelImpl) | The current state/data after initialization |

## Return Type

`FutureOr<void>` - Can be synchronous or asynchronous.

## When It's Called

### Automatic Invocation

`onResume()` is called automatically at the end of the initialization chain:

**ViewModel<T>:**
- Called at the end of `reload()` after `setupListeners()` completes

**AsyncViewModelImpl<T>:**
- Called at the end of `reload()` after `setupListeners()` completes
- Only called if `init()` succeeds (not called on error)

### Call Sequence

```
Constructor
    |
    v
_safeInitialization() / _initializeAsync()
    |
    v
init()
    |
    v
setupListeners()
    |
    v
onResume(data) <-- Called here
```

## Source Code Reference

### ViewModel<T> Implementation

From `viewmodel_impl.dart` (lines 716-719):

```dart
@protected
FutureOr<void> onResume(T data) async {
  log("Application was initialized and onResume was executed");
}
```

### AsyncViewModelImpl<T> Implementation

From `async_viewmodel_impl.dart` (lines 419-422):

```dart
@protected
FutureOr<void> onResume(T? data) async {
  log("Application was initialized and onResume was executed");
}
```

### Called from reload()

From `viewmodel_impl.dart` (lines 537-555):

```dart
Future<void> reload() async {
  try {
    if (_initialized) {
      await removeListeners();
    }
    init();
    await setupListeners();
    await onResume(_data); // <-- Called here
  } catch (error, stackTrace) {
    // ...
  }
}
```

From `async_viewmodel_impl.dart` (lines 132-157):

```dart
Future<void> reload() async {
  // ...
  try {
    // ...
    final result = await init();
    updateState(result);
    await setupListeners();
    await onResume(_state.data); // <-- Called here
  } catch (error, stackTrace) {
    // ...
  }
}
```

## Usage Examples

### Basic Post-Initialization Logging

```dart
class UserViewModel extends ViewModel<UserModel> {
  @override
  void init() {
    updateSilently(UserModel.guest());
  }

  @override
  FutureOr<void> onResume(UserModel data) {
    log('UserViewModel initialized with user: ${data.name}');
    analytics.trackEvent('user_vm_ready', {'user_id': data.id});
  }
}
```

### Setting Up Secondary Listeners

```dart
class DashboardViewModel extends AsyncViewModelImpl<DashboardData> {
  StreamSubscription? _realtimeSubscription;

  @override
  Future<DashboardData> init() async {
    return await dashboardService.fetchInitialData();
  }

  @override
  FutureOr<void> onResume(DashboardData? data) async {
    // Set up realtime updates after initial data is loaded
    _realtimeSubscription = dashboardService
        .realtimeUpdates()
        .listen(_handleRealtimeUpdate);

    log('Dashboard ready with ${data?.items.length ?? 0} items');
  }

  void _handleRealtimeUpdate(DashboardUpdate update) {
    transformDataState((current) {
      return current?.applyUpdate(update);
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
```

### Starting Background Tasks

```dart
class SyncViewModel extends AsyncViewModelImpl<SyncState> {
  Timer? _syncTimer;

  @override
  Future<SyncState> init() async {
    final lastSync = await storage.getLastSyncTime();
    return SyncState(lastSyncTime: lastSync, isSyncing: false);
  }

  @override
  FutureOr<void> onResume(SyncState? data) {
    // Start periodic sync after initialization
    _syncTimer = Timer.periodic(
      Duration(minutes: 15),
      (_) => _performSync(),
    );

    // Check if we need immediate sync
    if (data?.needsImmediateSync ?? false) {
      _performSync();
    }
  }

  Future<void> _performSync() async {
    transformDataState((current) => current?.copyWith(isSyncing: true));
    try {
      await syncService.sync();
      transformDataState((current) => current?.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
    } catch (e) {
      transformDataState((current) => current?.copyWith(isSyncing: false));
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
```

### Triggering Follow-up Actions

```dart
class AuthViewModel extends AsyncViewModelImpl<AuthState> {
  @override
  Future<AuthState> init() async {
    final token = await secureStorage.getToken();
    if (token != null) {
      return AuthState.authenticated(token: token);
    }
    return AuthState.unauthenticated();
  }

  @override
  FutureOr<void> onResume(AuthState? data) async {
    if (data?.isAuthenticated ?? false) {
      // Trigger loading of user-dependent data
      await Future.wait([
        UserService.profile.notifier.loadNotifier(),
        SettingsService.userSettings.notifier.loadNotifier(),
        NotificationService.notifications.notifier.loadNotifier(),
      ]);
    }
  }
}
```

### Context-Aware Operations

```dart
class ThemeAwareViewModel extends AsyncViewModelImpl<AppTheme> {
  ThemeAwareViewModel() : super(
    AsyncState.initial(),
    waitForContext: true,
  );

  @override
  Future<AppTheme> init() async {
    final theme = Theme.of(requireContext('theme init'));
    return AppTheme.fromMaterialTheme(theme);
  }

  @override
  FutureOr<void> onResume(AppTheme? data) {
    if (hasContext && data != null) {
      // Safe to use context here - it's guaranteed available
      final mediaQuery = MediaQuery.of(requireContext('media query'));
      log('Theme ready: ${data.isDark ? "dark" : "light"} mode');
      log('Screen size: ${mediaQuery.size}');
    }
  }
}
```

### Conditional Initialization

```dart
class FeatureViewModel extends AsyncViewModelImpl<FeatureState> {
  @override
  Future<FeatureState> init() async {
    final config = await configService.getFeatureConfig();
    return FeatureState(config: config, isEnabled: config.enabled);
  }

  @override
  FutureOr<void> onResume(FeatureState? data) async {
    if (data?.isEnabled ?? false) {
      // Only set up feature-specific resources if enabled
      await _initializeFeatureResources();
      _startFeatureTracking();
    } else {
      log('Feature disabled - skipping resource initialization');
    }
  }

  Future<void> _initializeFeatureResources() async {
    // Initialize feature-specific resources
  }

  void _startFeatureTracking() {
    // Start analytics tracking for feature
  }
}
```

### Error Handling in onResume

```dart
class ResilientViewModel extends AsyncViewModelImpl<DataModel> {
  @override
  Future<DataModel> init() async {
    return await repository.fetchData();
  }

  @override
  FutureOr<void> onResume(DataModel? data) async {
    try {
      // Attempt secondary initialization
      await _setupSecondaryFeatures(data);
    } catch (e) {
      // Log but don't fail - primary init succeeded
      log('Warning: Secondary features failed to initialize: $e');
      analytics.trackError('secondary_init_failed', e);
    }
  }

  Future<void> _setupSecondaryFeatures(DataModel? data) async {
    // May fail without affecting primary functionality
  }
}
```

## Best Practices

### 1. Keep onResume() Lightweight

```dart
// GOOD - Lightweight operations
@override
FutureOr<void> onResume(Data? data) {
  log('Ready');
  analytics.track('vm_ready');
}

// AVOID - Heavy operations that block UI
@override
FutureOr<void> onResume(Data? data) async {
  await heavyOperation(); // May delay UI responsiveness
  await anotherHeavyOperation();
}
```

### 2. Handle Null Data Gracefully

```dart
@override
FutureOr<void> onResume(Data? data) {
  // AsyncViewModelImpl receives nullable data
  if (data == null) {
    log('onResume called with null data - skipping setup');
    return;
  }

  // Proceed with data-dependent operations
  _setupWithData(data);
}
```

### 3. Use for Non-Critical Operations

```dart
@override
FutureOr<void> onResume(UserData? data) {
  // Non-critical: analytics, logging, prefetching
  analytics.identifyUser(data?.id);
  prefetchService.prefetchRelatedData(data?.preferences);

  // DON'T put critical logic here - use init() instead
}
```

### 4. Check Disposed State for Async Operations

```dart
@override
FutureOr<void> onResume(Data? data) async {
  await someAsyncOperation();

  // Check disposal before continuing
  if (isDisposed) return;

  // Safe to continue
  _setupListenersAfterAsync();
}
```

### 5. Pair with dispose() for Cleanup

```dart
class SubscriptionViewModel extends AsyncViewModelImpl<SubData> {
  StreamSubscription? _subscription;

  @override
  FutureOr<void> onResume(SubData? data) {
    // Set up subscription in onResume
    _subscription = dataStream.listen(_handleData);
  }

  @override
  void dispose() {
    // Clean up in dispose
    _subscription?.cancel();
    super.dispose();
  }
}
```

## Common Mistakes to Avoid

### 1. Critical Logic in onResume

```dart
// WRONG - Critical data loading should be in init()
@override
FutureOr<void> onResume(Data? data) async {
  final criticalData = await loadCriticalData();
  updateState(criticalData); // This should be in init()
}

// CORRECT - Use init() for critical loading
@override
Future<Data> init() async {
  return await loadCriticalData();
}

@override
FutureOr<void> onResume(Data? data) {
  // Only non-critical follow-up tasks
  prefetchAdditionalData();
}
```

### 2. Not Handling Errors

```dart
// WRONG - Unhandled errors can crash the app
@override
FutureOr<void> onResume(Data? data) async {
  await riskyOperation(); // May throw!
}

// CORRECT - Handle errors gracefully
@override
FutureOr<void> onResume(Data? data) async {
  try {
    await riskyOperation();
  } catch (e) {
    log('Non-critical operation failed: $e');
  }
}
```

### 3. Blocking UI with Sync Operations

```dart
// WRONG - Heavy sync operation blocks UI
@override
FutureOr<void> onResume(Data? data) {
  final result = heavySyncComputation(data!); // Blocks main thread
}

// CORRECT - Use compute for heavy operations
@override
FutureOr<void> onResume(Data? data) async {
  if (data != null) {
    final result = await compute(heavyComputation, data);
  }
}
```

### 4. Assuming Context Availability

```dart
// WRONG - Context may not be available
@override
FutureOr<void> onResume(Data? data) {
  final theme = Theme.of(context!); // May crash!
}

// CORRECT - Check context availability
@override
FutureOr<void> onResume(Data? data) {
  if (hasContext) {
    final theme = Theme.of(requireContext('theme'));
  }
}
```

### 5. Not Checking for Null in AsyncViewModelImpl

```dart
// WRONG - Assumes data is non-null
@override
FutureOr<void> onResume(UserData? data) {
  final userName = data.name; // Nullable dereference!
}

// CORRECT - Handle nullable data
@override
FutureOr<void> onResume(UserData? data) {
  if (data != null) {
    final userName = data.name;
  }
}
```

## Lifecycle Position

`onResume()` is the final step in the initialization chain:

```
Constructor -> init() -> setupListeners() -> onResume()
                                                ^
                                                |
                                          You are here
                                                |
                                                v
                                         [Active State]
                                                |
                                                v
                                            dispose()
```

## When onResume() is NOT Called

- When `init()` throws an error (AsyncViewModelImpl transitions to error state)
- When ViewModel is disposed before initialization completes
- When `loadOnInit: false` and `loadNotifier()` is never called

## Related Methods

- `init()` - Primary initialization, runs before onResume()
- `setupListeners()` - Listener registration, runs after init() and before onResume()
- `reload()` - Calls the full chain including onResume()
- `dispose()` - Cleanup counterpart to initialization
