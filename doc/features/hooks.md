# State Change Hooks

## Overview

State Change Hooks are callback methods that execute automatically after every state change in your ViewModels. Introduced in ReactiveNotifier v2.16.0, hooks provide a clean way to react to state transitions without cluttering your business logic methods.

**Key Benefits:**

- Centralized state change handling
- Automatic execution on all state updates (including silent updates)
- Access to both previous and current state
- Perfect for logging, analytics, side effects, and validation

There are two types of hooks:

1. **`onStateChanged`** - For synchronous `ViewModel<T>`
2. **`onAsyncStateChanged`** - For asynchronous `AsyncViewModelImpl<T>`

## ViewModel.onStateChanged(previous, next)

### Method Signature

```dart
@protected
void onStateChanged(T previous, T next)
```

**Parameters:**

- `previous` - The state value before the update (`T`)
- `next` - The state value after the update (`T`)

### When It Is Called

The `onStateChanged` hook is automatically invoked after every state modification in a `ViewModel<T>`. This includes:

| Method | Notifies Listeners | Triggers Hook |
|--------|-------------------|---------------|
| `updateState(newState)` | Yes | Yes |
| `updateSilently(newState)` | No | Yes |
| `transformState((data) => ...)` | Yes | Yes |
| `transformStateSilently((data) => ...)` | No | Yes |

**Important:** The hook is called after the state has been updated, regardless of whether listeners are notified.

### Basic Usage

```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());

  @override
  void init() {
    // Load initial user data
    updateSilently(UserModel.empty());
  }

  @override
  void onStateChanged(UserModel previous, UserModel next) {
    // This method is called after every state update
    log('User state changed: ${previous.name} -> ${next.name}');
  }

  void updateUserName(String newName) {
    transformState((user) => user.copyWith(name: newName));
    // onStateChanged will be called automatically after this
  }
}
```

### Use Cases

#### 1. Logging State Changes

Track all state modifications for debugging or audit purposes:

```dart
class AuditableViewModel extends ViewModel<DocumentModel> {
  AuditableViewModel() : super(DocumentModel.empty());

  @override
  void onStateChanged(DocumentModel previous, DocumentModel next) {
    // Log every change with timestamp
    log('[${DateTime.now().toIso8601String()}] Document changed');
    log('  Previous: ${previous.toJson()}');
    log('  Next: ${next.toJson()}');

    // Track specific field changes
    if (previous.title != next.title) {
      log('  Title changed: "${previous.title}" -> "${next.title}"');
    }
    if (previous.content != next.content) {
      log('  Content updated (${next.content.length} chars)');
    }
  }

  @override
  void init() {
    updateSilently(DocumentModel.empty());
  }
}
```

#### 2. Analytics Tracking

Send analytics events based on state transitions:

```dart
class CartViewModel extends ViewModel<CartModel> {
  CartViewModel() : super(CartModel.empty());

  @override
  void onStateChanged(CartModel previous, CartModel next) {
    // Track item additions
    if (next.items.length > previous.items.length) {
      final addedItems = next.items.length - previous.items.length;
      Analytics.track('cart_items_added', {
        'count': addedItems,
        'total_items': next.items.length,
        'cart_value': next.totalPrice,
      });
    }

    // Track item removals
    if (next.items.length < previous.items.length) {
      Analytics.track('cart_items_removed', {
        'count': previous.items.length - next.items.length,
      });
    }

    // Track significant cart value changes
    if ((next.totalPrice - previous.totalPrice).abs() > 100) {
      Analytics.track('cart_value_changed', {
        'previous': previous.totalPrice,
        'current': next.totalPrice,
      });
    }
  }

  @override
  void init() {
    updateSilently(CartModel.empty());
  }
}
```

#### 3. Triggering Side Effects

Perform automatic actions based on state changes:

```dart
class FormViewModel extends ViewModel<FormModel> {
  FormViewModel() : super(FormModel.empty());

  @override
  void onStateChanged(FormModel previous, FormModel next) {
    // Auto-save when form becomes valid
    if (!previous.isValid && next.isValid) {
      _autoSaveDraft(next);
    }

    // Clear errors when user starts typing
    if (previous.hasErrors && next.email != previous.email) {
      transformStateSilently((state) => state.copyWith(emailError: null));
    }

    // Enable submit button when all required fields are filled
    if (!previous.canSubmit && next.canSubmit) {
      _notifyFormReady();
    }
  }

  void _autoSaveDraft(FormModel form) async {
    await DraftService.save(form);
    log('Draft auto-saved');
  }

  void _notifyFormReady() {
    // Notify UI or other services that form is ready
    log('Form is ready for submission');
  }

  @override
  void init() {
    updateSilently(FormModel.empty());
  }
}
```

#### 4. Automatic Validation

Validate state changes and react accordingly:

```dart
class ProfileViewModel extends ViewModel<ProfileModel> {
  ProfileViewModel() : super(ProfileModel.empty());

  @override
  void onStateChanged(ProfileModel previous, ProfileModel next) {
    // Validate email format when changed
    if (previous.email != next.email) {
      if (next.email.isNotEmpty && !_isValidEmail(next.email)) {
        log('Warning: Invalid email format detected');
        // Optionally show validation error in UI
      }
    }

    // Validate age constraints
    if (previous.age != next.age) {
      if (next.age < 0 || next.age > 150) {
        log('Warning: Invalid age value: ${next.age}');
      }
    }

    // Check for required fields
    if (next.isComplete && !previous.isComplete) {
      log('Profile is now complete');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void init() {
    updateSilently(ProfileModel.empty());
  }
}
```

#### 5. Cross-Service Notification

Notify other services about important state changes:

```dart
class AuthViewModel extends ViewModel<AuthModel> {
  AuthViewModel() : super(AuthModel.loggedOut());

  @override
  void onStateChanged(AuthModel previous, AuthModel next) {
    // Notify when user logs in
    if (!previous.isLoggedIn && next.isLoggedIn) {
      log('User logged in: ${next.userId}');
      _onUserLoggedIn(next);
    }

    // Notify when user logs out
    if (previous.isLoggedIn && !next.isLoggedIn) {
      log('User logged out');
      _onUserLoggedOut();
    }

    // Track permission changes
    if (previous.permissions != next.permissions) {
      PermissionService.notifyPermissionChange(next.permissions);
    }
  }

  void _onUserLoggedIn(AuthModel auth) {
    // Initialize user-specific services
    NotificationService.initializeForUser(auth.userId);
    PreferencesService.loadUserPreferences(auth.userId);
    AnalyticsService.setUserId(auth.userId);
  }

  void _onUserLoggedOut() {
    // Clean up user-specific data
    NotificationService.clearUserData();
    PreferencesService.clearCache();
    AnalyticsService.clearUserId();
  }

  @override
  void init() {
    updateSilently(AuthModel.loggedOut());
  }
}
```

## AsyncViewModelImpl.onAsyncStateChanged(previous, next)

### Method Signature

```dart
@protected
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next)
```

**Parameters:**

- `previous` - The async state before the update (`AsyncState<T>`)
- `next` - The async state after the update (`AsyncState<T>`)

### When It Is Called

The `onAsyncStateChanged` hook is automatically invoked after every async state modification:

| Method | Notifies Listeners | Triggers Hook |
|--------|-------------------|---------------|
| `updateState(data)` | Yes | Yes |
| `updateSilently(data)` | No | No |
| `loadingState()` | Yes | Yes |
| `errorState(error, stackTrace)` | Yes | Yes |
| `transformState((state) => ...)` | Yes | Yes |
| `transformStateSilently((state) => ...)` | No | Yes |
| `transformDataState((data) => ...)` | Yes | Yes |
| `transformDataStateSilently((data) => ...)` | No | Yes |
| `cleanState()` | Yes | Yes |

**Note:** `updateSilently()` in `AsyncViewModelImpl` does not trigger the hook, unlike in `ViewModel`. This is by design for initialization scenarios.

### AsyncState Properties

The `AsyncState<T>` object provides these helpful properties:

```dart
// State type checks
next.isInitial   // True if in initial state
next.isLoading   // True if loading
next.isSuccess   // True if data loaded successfully
next.isError     // True if an error occurred
next.isEmpty     // True if success but data is null/empty

// Data access
next.data        // The data (T?) - null if not in success state
next.error       // The error object (Object?) - null if no error
next.stackTrace  // Stack trace for errors (StackTrace?)
```

### Basic Usage

```dart
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductsViewModel() : super(AsyncState.initial());

  @override
  Future<List<Product>> init() async {
    return await ProductRepository.fetchAll();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<List<Product>> previous,
    AsyncState<List<Product>> next,
  ) {
    // Log state transitions
    log('Products state: ${previous.runtimeType} -> ${next.runtimeType}');

    if (next.isSuccess) {
      log('Loaded ${next.data?.length ?? 0} products');
    } else if (next.isError) {
      log('Error loading products: ${next.error}');
    }
  }
}
```

### Handling State Transitions

#### Loading Started

```dart
@override
void onAsyncStateChanged(
  AsyncState<List<Order>> previous,
  AsyncState<List<Order>> next,
) {
  // Detect when loading starts
  if (!previous.isLoading && next.isLoading) {
    log('Started loading orders...');
    _showLoadingIndicator();
  }
}
```

#### Loading Completed Successfully

```dart
@override
void onAsyncStateChanged(
  AsyncState<List<Order>> previous,
  AsyncState<List<Order>> next,
) {
  // Detect successful load completion
  if (previous.isLoading && next.isSuccess) {
    log('Orders loaded successfully');
    _hideLoadingIndicator();

    final orderCount = next.data?.length ?? 0;
    if (orderCount == 0) {
      _showEmptyState();
    }
  }
}
```

#### Error Handling

```dart
@override
void onAsyncStateChanged(
  AsyncState<UserProfile> previous,
  AsyncState<UserProfile> next,
) {
  // Detect errors
  if (next.isError) {
    _hideLoadingIndicator();

    final error = next.error;
    if (error is NetworkException) {
      _showNetworkError();
    } else if (error is AuthException) {
      _redirectToLogin();
    } else {
      _showGenericError(error.toString());
    }

    // Log error for debugging
    log('Profile load error: $error');
    log('Stack trace: ${next.stackTrace}');
  }
}
```

### Use Cases

#### 1. Loading Indicator Management

```dart
class DataViewModel extends AsyncViewModelImpl<DashboardData> {
  DataViewModel() : super(AsyncState.initial());

  bool _isLoadingShown = false;

  @override
  Future<DashboardData> init() async {
    return await DashboardRepository.fetchData();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<DashboardData> previous,
    AsyncState<DashboardData> next,
  ) {
    // Show loading indicator when loading starts
    if (next.isLoading && !_isLoadingShown) {
      _isLoadingShown = true;
      LoadingOverlay.show();
    }

    // Hide loading indicator when loading ends (success or error)
    if (!next.isLoading && _isLoadingShown) {
      _isLoadingShown = false;
      LoadingOverlay.hide();
    }
  }
}
```

#### 2. Error Notification System

```dart
class ApiDataViewModel extends AsyncViewModelImpl<ApiResponse> {
  ApiDataViewModel() : super(AsyncState.initial());

  @override
  Future<ApiResponse> init() async {
    return await ApiService.fetchData();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<ApiResponse> previous,
    AsyncState<ApiResponse> next,
  ) {
    if (next.isError) {
      final error = next.error;

      // Categorize and handle different error types
      String userMessage;
      if (error is TimeoutException) {
        userMessage = 'Request timed out. Please try again.';
      } else if (error is SocketException) {
        userMessage = 'No internet connection.';
      } else if (error is HttpException) {
        userMessage = 'Server error. Please try later.';
      } else {
        userMessage = 'Something went wrong.';
      }

      // Show user-friendly error
      ToastService.showError(userMessage);

      // Log detailed error for developers
      ErrorReportingService.report(
        error: error,
        stackTrace: next.stackTrace,
        context: 'ApiDataViewModel.init',
      );
    }
  }
}
```

#### 3. Analytics for Async Operations

```dart
class SearchViewModel extends AsyncViewModelImpl<SearchResults> {
  SearchViewModel() : super(AsyncState.initial(), loadOnInit: false);

  DateTime? _searchStartTime;
  String _currentQuery = '';

  @override
  Future<SearchResults> init() async {
    return await SearchService.search(_currentQuery);
  }

  void search(String query) {
    _currentQuery = query;
    _searchStartTime = DateTime.now();
    reload();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<SearchResults> previous,
    AsyncState<SearchResults> next,
  ) {
    // Track search started
    if (previous.isInitial && next.isLoading) {
      Analytics.track('search_started', {'query': _currentQuery});
    }

    // Track search completed
    if (previous.isLoading && next.isSuccess) {
      final duration = _searchStartTime != null
          ? DateTime.now().difference(_searchStartTime!).inMilliseconds
          : 0;

      Analytics.track('search_completed', {
        'query': _currentQuery,
        'results_count': next.data?.items.length ?? 0,
        'duration_ms': duration,
      });
    }

    // Track search errors
    if (next.isError) {
      Analytics.track('search_error', {
        'query': _currentQuery,
        'error_type': next.error.runtimeType.toString(),
      });
    }
  }
}
```

#### 4. Caching Strategy

```dart
class CachedDataViewModel extends AsyncViewModelImpl<List<Article>> {
  CachedDataViewModel() : super(AsyncState.initial());

  @override
  Future<List<Article>> init() async {
    return await ArticleRepository.fetchLatest();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<List<Article>> previous,
    AsyncState<List<Article>> next,
  ) {
    // Cache successful responses
    if (next.isSuccess && next.data != null) {
      CacheService.store(
        key: 'articles_latest',
        data: next.data!,
        expiry: Duration(minutes: 15),
      );
      log('Articles cached successfully');
    }

    // On error, try to load from cache
    if (next.isError && previous.isLoading) {
      _tryLoadFromCache();
    }
  }

  void _tryLoadFromCache() async {
    final cached = await CacheService.get<List<Article>>('articles_latest');
    if (cached != null) {
      log('Loading articles from cache');
      updateState(cached);
      ToastService.show('Showing cached data');
    }
  }
}
```

#### 5. Retry Logic

```dart
class ResilientViewModel extends AsyncViewModelImpl<ConfigData> {
  ResilientViewModel() : super(AsyncState.initial());

  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  Future<ConfigData> init() async {
    return await ConfigService.fetchConfig();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<ConfigData> previous,
    AsyncState<ConfigData> next,
  ) {
    // Reset retry count on success
    if (next.isSuccess) {
      _retryCount = 0;
    }

    // Auto-retry on specific errors
    if (next.isError && _retryCount < _maxRetries) {
      final error = next.error;

      // Only retry on transient errors
      if (_isRetryableError(error)) {
        _retryCount++;
        log('Retrying... Attempt $_retryCount of $_maxRetries');

        // Exponential backoff
        Future.delayed(
          Duration(seconds: _retryCount * 2),
          () => reload(),
        );
      }
    }

    // Show final error after max retries
    if (next.isError && _retryCount >= _maxRetries) {
      ToastService.showError(
        'Failed to load config after $_maxRetries attempts',
      );
    }
  }

  bool _isRetryableError(Object? error) {
    return error is TimeoutException ||
           error is SocketException ||
           (error is HttpException && error.statusCode >= 500);
  }
}
```

## Integration with State Update Methods

### ViewModel Integration

All state update methods in `ViewModel<T>` trigger `onStateChanged`:

```dart
class DemoViewModel extends ViewModel<int> {
  DemoViewModel() : super(0);

  @override
  void init() {}

  @override
  void onStateChanged(int previous, int next) {
    log('State changed: $previous -> $next');
  }

  void demonstrateAllMethods() {
    // All of these will trigger onStateChanged

    updateState(10);
    // Output: State changed: 0 -> 10

    updateSilently(20);
    // Output: State changed: 10 -> 20
    // (no UI rebuild, but hook still fires)

    transformState((value) => value + 5);
    // Output: State changed: 20 -> 25

    transformStateSilently((value) => value * 2);
    // Output: State changed: 25 -> 50
    // (no UI rebuild, but hook still fires)
  }
}
```

### AsyncViewModelImpl Integration

```dart
class AsyncDemoViewModel extends AsyncViewModelImpl<String> {
  AsyncDemoViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<String> init() async {
    return 'Initialized';
  }

  @override
  void onAsyncStateChanged(
    AsyncState<String> previous,
    AsyncState<String> next,
  ) {
    log('Async state: ${_stateToString(previous)} -> ${_stateToString(next)}');
  }

  String _stateToString(AsyncState<String> state) {
    if (state.isInitial) return 'initial';
    if (state.isLoading) return 'loading';
    if (state.isSuccess) return 'success(${state.data})';
    if (state.isError) return 'error(${state.error})';
    return 'unknown';
  }

  void demonstrateAllMethods() async {
    // These trigger onAsyncStateChanged

    loadingState();
    // Output: Async state: initial -> loading

    updateState('Hello');
    // Output: Async state: loading -> success(Hello)

    errorState(Exception('Test error'));
    // Output: Async state: success(Hello) -> error(Exception: Test error)

    transformStateSilently((state) => AsyncState.success('Transformed'));
    // Output: Async state: error(...) -> success(Transformed)

    transformDataState((data) => '${data ?? ''} World');
    // Output: Async state: success(Transformed) -> success(Transformed World)

    // Note: updateSilently does NOT trigger the hook
    updateSilently('Silent update');
    // No output - hook not called
  }
}
```

## Best Practices

### 1. Keep Hooks Lightweight

Hooks should execute quickly to avoid blocking state updates:

```dart
// GOOD: Quick operations
@override
void onStateChanged(UserModel previous, UserModel next) {
  log('User updated');
  Analytics.track('user_update'); // Fire-and-forget
}

// AVOID: Heavy operations in hooks
@override
void onStateChanged(UserModel previous, UserModel next) {
  // DON'T DO THIS - blocks state updates
  final result = await expensiveOperation(); // Blocking!
  await saveToDatabase(result); // More blocking!
}
```

### 2. Use Async Operations Carefully

If you need async operations, fire-and-forget or use unawaited:

```dart
import 'dart:async';

@override
void onStateChanged(OrderModel previous, OrderModel next) {
  // Fire-and-forget async operations
  unawaited(_syncToServer(next));
  unawaited(_updateLocalCache(next));
}

Future<void> _syncToServer(OrderModel order) async {
  try {
    await OrderService.sync(order);
  } catch (e) {
    log('Sync failed: $e');
  }
}
```

### 3. Avoid State Mutations in Hooks

Be careful not to create infinite loops:

```dart
// DANGEROUS: Can cause infinite loop
@override
void onStateChanged(CounterModel previous, CounterModel next) {
  if (next.count > 100) {
    updateState(next.copyWith(count: 100)); // This triggers onStateChanged again!
  }
}

// SAFE: Use transformStateSilently or guard with conditions
@override
void onStateChanged(CounterModel previous, CounterModel next) {
  // Option 1: Use a flag to prevent re-entry
  if (_isNormalizing) return;

  if (next.count > 100 && previous.count <= 100) {
    _isNormalizing = true;
    transformStateSilently((state) => state.copyWith(count: 100));
    _isNormalizing = false;
  }
}
```

### 4. Compare States Before Acting

Only react to meaningful changes:

```dart
@override
void onStateChanged(SettingsModel previous, SettingsModel next) {
  // Only act on specific changes
  if (previous.theme != next.theme) {
    _applyTheme(next.theme);
  }

  if (previous.language != next.language) {
    _changeLanguage(next.language);
  }

  // Ignore other property changes
}
```

### 5. Use Type-Safe Error Handling

```dart
@override
void onAsyncStateChanged(
  AsyncState<UserData> previous,
  AsyncState<UserData> next,
) {
  if (next.isError) {
    final error = next.error;

    // Type-safe error handling
    switch (error) {
      case NetworkException e:
        _handleNetworkError(e);
        break;
      case AuthException e:
        _handleAuthError(e);
        break;
      case ValidationException e:
        _handleValidationError(e);
        break;
      default:
        _handleUnknownError(error);
    }
  }
}
```

## Common Patterns

### Pattern 1: State Change Logger

Create a reusable logging mixin:

```dart
mixin StateChangeLogger<T> on ViewModel<T> {
  @override
  void onStateChanged(T previous, T next) {
    assert(() {
      log('''
StateChange [${runtimeType}]:
  Previous: $previous
  Next: $next
  Time: ${DateTime.now().toIso8601String()}
''');
      return true;
    }());

    // Call super if extending another class with hooks
    super.onStateChanged(previous, next);
  }
}

// Usage
class LoggedUserViewModel extends ViewModel<UserModel> with StateChangeLogger<UserModel> {
  LoggedUserViewModel() : super(UserModel.empty());

  @override
  void init() {
    updateSilently(UserModel.empty());
  }
}
```

### Pattern 2: Debounced Side Effects

Prevent rapid-fire side effects:

```dart
class SearchViewModel extends ViewModel<SearchQuery> {
  SearchViewModel() : super(SearchQuery.empty());

  Timer? _debounceTimer;

  @override
  void init() {
    updateSilently(SearchQuery.empty());
  }

  @override
  void onStateChanged(SearchQuery previous, SearchQuery next) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search requests
    if (next.query != previous.query) {
      _debounceTimer = Timer(Duration(milliseconds: 300), () {
        _performSearch(next.query);
      });
    }
  }

  void _performSearch(String query) {
    SearchService.search(query);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

### Pattern 3: Conditional Analytics

Track only significant changes:

```dart
class CartAnalyticsViewModel extends ViewModel<CartModel> {
  CartAnalyticsViewModel() : super(CartModel.empty());

  @override
  void init() {
    updateSilently(CartModel.empty());
  }

  @override
  void onStateChanged(CartModel previous, CartModel next) {
    // Track cart value milestones
    final previousMilestone = _getMilestone(previous.totalPrice);
    final nextMilestone = _getMilestone(next.totalPrice);

    if (nextMilestone > previousMilestone) {
      Analytics.track('cart_milestone_reached', {
        'milestone': nextMilestone,
        'cart_value': next.totalPrice,
      });
    }

    // Track checkout readiness
    if (!previous.isReadyForCheckout && next.isReadyForCheckout) {
      Analytics.track('cart_ready_for_checkout', {
        'items_count': next.items.length,
        'total_value': next.totalPrice,
      });
    }
  }

  int _getMilestone(double value) {
    if (value >= 1000) return 1000;
    if (value >= 500) return 500;
    if (value >= 100) return 100;
    if (value >= 50) return 50;
    return 0;
  }
}
```

### Pattern 4: State History Tracking

Track recent state changes for debugging:

```dart
class HistoryTrackingViewModel extends ViewModel<EditorState> {
  HistoryTrackingViewModel() : super(EditorState.empty());

  final List<EditorState> _stateHistory = [];
  static const int _maxHistorySize = 50;

  @override
  void init() {
    updateSilently(EditorState.empty());
  }

  @override
  void onStateChanged(EditorState previous, EditorState next) {
    // Store previous state in history
    _stateHistory.add(previous);

    // Limit history size
    if (_stateHistory.length > _maxHistorySize) {
      _stateHistory.removeAt(0);
    }
  }

  /// Undo to previous state
  void undo() {
    if (_stateHistory.isNotEmpty) {
      final previousState = _stateHistory.removeLast();
      updateState(previousState);
    }
  }

  /// Check if undo is available
  bool get canUndo => _stateHistory.isNotEmpty;
}
```

### Pattern 5: Multi-Service Synchronization

Coordinate state across services:

```dart
class SyncCoordinator extends ViewModel<SyncState> {
  SyncCoordinator() : super(SyncState.idle());

  @override
  void init() {
    updateSilently(SyncState.idle());
  }

  @override
  void onStateChanged(SyncState previous, SyncState next) {
    // Notify all services of sync state changes
    if (previous.status != next.status) {
      _broadcastSyncStatus(next.status);
    }

    // Handle sync completion
    if (previous.status == SyncStatus.syncing &&
        next.status == SyncStatus.completed) {
      _notifySyncComplete();
    }

    // Handle sync errors
    if (next.status == SyncStatus.error) {
      _handleSyncError(next.error);
    }
  }

  void _broadcastSyncStatus(SyncStatus status) {
    // Notify other ViewModels
    EventBus.fire(SyncStatusChanged(status));
  }

  void _notifySyncComplete() {
    // Trigger dependent operations
    CacheService.markAsSynced();
    OfflineService.clearPendingChanges();
  }

  void _handleSyncError(Object? error) {
    ErrorReportingService.report(error);
    RetryScheduler.scheduleRetry(Duration(minutes: 5));
  }
}
```

## Summary

State Change Hooks provide a powerful mechanism for reacting to state changes in ReactiveNotifier ViewModels:

| Feature | `ViewModel<T>` | `AsyncViewModelImpl<T>` |
|---------|---------------|------------------------|
| Hook method | `onStateChanged(T previous, T next)` | `onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next)` |
| Triggered by | All update methods | Most update methods (except `updateSilently`) |
| Access to previous | Yes | Yes |
| Access to current | Yes | Yes |
| Silent updates | Triggers hook | Does not trigger hook |

**Key Takeaways:**

- Hooks centralize state change handling
- They execute after state is updated
- Use them for logging, analytics, side effects, and validation
- Keep hook implementations lightweight
- Be careful to avoid infinite loops when mutating state in hooks
