# init() Method

## Method Signature

### ViewModel<T>
```dart
void init();
```

### AsyncViewModelImpl<T>
```dart
@protected
Future<T> init();
```

## Purpose

The `init()` method is the primary initialization hook for ViewModels. It is called once when the ViewModel is created and is responsible for setting up the initial state and any necessary configuration.

**Key Differences:**
- In `ViewModel<T>`: Must be **synchronous** (no `async` keyword)
- In `AsyncViewModelImpl<T>`: Must be **asynchronous** and return `Future<T>`

## Parameters

None.

## Return Type

- **ViewModel<T>**: `void`
- **AsyncViewModelImpl<T>**: `Future<T>` - The loaded data that will be set as the success state

## When It's Called

### Automatic Invocation

The `init()` method is called automatically during ViewModel construction:

**ViewModel<T>:**
- Called synchronously in the constructor via `_safeInitialization()`
- Executes immediately when the ViewModel instance is created
- Called before `hasInitializedListenerExecution` is set to `true`

**AsyncViewModelImpl<T>:**
- Called during `reload()` which is triggered by `_initializeAsync()`
- Controlled by constructor parameters:
  - `loadOnInit: true` (default) - Calls `init()` immediately
  - `loadOnInit: false` - Skips automatic initialization
  - `waitForContext: true` - Delays `init()` until BuildContext is available

### Source Code Reference

From `viewmodel_impl.dart` (lines 178-231):
```dart
void _safeInitialization() {
  hasInitializedListenerExecution = false;
  if (_initialized || _disposed) return;

  try {
    if (!hasContext) {
      _initializedWithoutContext = true;
    }
    init();
    _initialized = true;
    _initTime = DateTime.now();
    unawaited(setupListeners());
  } catch (e, stack) {
    // Error handling...
    rethrow;
  }
}
```

From `async_viewmodel_impl.dart` (lines 132-157):
```dart
Future<void> reload() async {
  if (_state.isLoading) return;
  try {
    if (!loadOnInit) {
      await removeListeners();
    }
    loadOnInit = false;
    loadingState();
    final result = await init();
    updateState(result);
    await setupListeners();
    await onResume(_state.data);
  } catch (error, stackTrace) {
    errorState(error, stackTrace);
    // ...
  }
}
```

## Usage Examples

### Basic ViewModel (Synchronous)

```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());

  @override
  void init() {
    // Synchronous initialization only
    updateSilently(UserModel(
      id: 'guest',
      name: 'Guest User',
      isLoggedIn: false,
    ));

    // Set up reactive listeners to other ViewModels
    AuthService.authState.notifier.listenVM((authData) {
      if (authData.isAuthenticated) {
        _loadAuthenticatedUser(authData.userId);
      }
    });
  }

  void _loadAuthenticatedUser(String userId) {
    // Handle async operations in separate methods
    // This keeps init() synchronous
  }
}
```

### AsyncViewModelImpl (Asynchronous)

```dart
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  final ProductRepository _repository;

  ProductsViewModel(this._repository)
    : super(AsyncState.initial(), loadOnInit: true);

  @override
  Future<List<Product>> init() async {
    // Async operations are allowed here
    final products = await _repository.fetchProducts();
    return products;
  }
}
```

### With waitForContext (Context-Aware Initialization)

```dart
class ThemeAwareViewModel extends AsyncViewModelImpl<AppTheme> {
  ThemeAwareViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,
    waitForContext: true, // Wait for BuildContext
  );

  @override
  Future<AppTheme> init() async {
    // Context is guaranteed to be available here
    final theme = Theme.of(requireContext('theme initialization'));
    final brightness = theme.brightness;

    return AppTheme(
      isDarkMode: brightness == Brightness.dark,
      primaryColor: theme.primaryColor,
    );
  }
}
```

### Deferred Initialization (loadOnInit: false)

```dart
class LazyViewModel extends AsyncViewModelImpl<ExpensiveData> {
  LazyViewModel() : super(
    AsyncState.initial(),
    loadOnInit: false, // Don't initialize automatically
  );

  @override
  Future<ExpensiveData> init() async {
    return await expensiveDataLoader.load();
  }

  // Call manually when needed
  Future<void> initializeWhenNeeded() async {
    await loadNotifier();
  }
}
```

### Cross-ViewModel Communication in init()

```dart
class OrdersViewModel extends ViewModel<OrdersState> {
  OrdersViewModel() : super(OrdersState.empty());

  UserModel? currentUser;

  @override
  void init() {
    // Listen to user changes reactively
    UserService.userState.notifier.listenVM((userData) {
      currentUser = userData;
      _refreshOrdersForUser(userData.id);
    });

    // Initialize with current user if available
    final user = UserService.userState.notifier.data;
    if (user.isLoggedIn) {
      updateSilently(OrdersState.loading());
      _refreshOrdersForUser(user.id);
    }
  }

  void _refreshOrdersForUser(String userId) {
    // Handle async logic outside init()
  }
}
```

## Best Practices

### 1. Keep ViewModel.init() Synchronous

```dart
// CORRECT
@override
void init() {
  updateSilently(MyState.initial());
  _setupListeners();
}

// INCORRECT - Don't use async in ViewModel
@override
Future<void> init() async { // This signature is wrong!
  final data = await fetchData(); // Don't do this
  updateSilently(data);
}
```

### 2. Use updateSilently() for Initial State

```dart
@override
void init() {
  // Use updateSilently to avoid unnecessary notifications during init
  updateSilently(MyState.initial());
}
```

### 3. Handle Errors in AsyncViewModelImpl

```dart
@override
Future<List<Item>> init() async {
  try {
    return await repository.fetchItems();
  } catch (e) {
    // Errors are automatically caught and set as errorState
    // by the reload() method, but you can add custom handling
    logError('Failed to load items', e);
    rethrow; // Let reload() handle the error state
  }
}
```

### 4. Avoid Heavy Computations

```dart
// AVOID - Heavy computation blocks the UI
@override
void init() {
  final result = heavyComputation(); // Blocks main thread
  updateSilently(result);
}

// BETTER - Defer heavy work
@override
void init() {
  updateSilently(MyState.initial());
  // Schedule heavy work after init completes
  Future.microtask(() => _performHeavyWork());
}
```

### 5. Set Up Reactive Listeners

```dart
@override
void init() {
  // Use listenVM for cross-ViewModel communication
  DependencyService.state.notifier.listenVM((data) {
    _handleDependencyChange(data);
  });

  updateSilently(MyState.initial());
}
```

## Common Mistakes to Avoid

### 1. Making ViewModel.init() Async

```dart
// WRONG - ViewModel.init() must be synchronous
class BadViewModel extends ViewModel<MyState> {
  @override
  Future<void> init() async { // Incorrect signature!
    final data = await loadData();
    updateSilently(data);
  }
}

// CORRECT - Use AsyncViewModelImpl for async initialization
class GoodViewModel extends AsyncViewModelImpl<MyState> {
  @override
  Future<MyState> init() async {
    return await loadData();
  }
}
```

### 2. Forgetting to Set Initial State

```dart
// WRONG - No initial state set
@override
void init() {
  // init() completes without setting state
  // This will trigger an assertion error in debug mode
}

// CORRECT - Always set initial state
@override
void init() {
  updateSilently(MyState.empty());
}
```

### 3. Using Context Without Checking Availability

```dart
// WRONG - Context might not be available
@override
void init() {
  final theme = Theme.of(context!); // May crash!
}

// CORRECT - Check context availability
@override
void init() {
  if (hasContext) {
    final theme = Theme.of(requireContext('theme'));
  } else {
    // Fallback logic
  }
}

// BETTER - Use waitForContext for AsyncViewModelImpl
class BetterVM extends AsyncViewModelImpl<Data> {
  BetterVM() : super(AsyncState.initial(), waitForContext: true);

  @override
  Future<Data> init() async {
    // Context is guaranteed here
    final theme = Theme.of(requireContext('theme'));
    return Data.fromTheme(theme);
  }
}
```

### 4. Calling notifyListeners() in init()

```dart
// WRONG - Causes unnecessary rebuilds during initialization
@override
void init() {
  _data = MyState.initial();
  notifyListeners(); // Premature notification
}

// CORRECT - Use updateSilently()
@override
void init() {
  updateSilently(MyState.initial());
}
```

### 5. Not Handling Reinitialize Scenario

```dart
// Be aware that init() may be called again after reinitializeWithContext()
@override
void init() {
  // Check if already initialized to avoid duplicate setup
  if (_isAlreadySetup) return;

  _performOneTimeSetup();
  _isAlreadySetup = true;

  updateSilently(MyState.initial());
}
```

## Lifecycle Position

The `init()` method is the first step in the ViewModel lifecycle:

```
Constructor -> _safeInitialization() -> init() -> setupListeners() -> onResume()
                                          ^
                                          |
                                    You are here
```

## Related Methods

- `setupListeners()` - Called automatically after `init()` completes
- `onResume()` - Called after the entire initialization chain completes
- `reload()` - Calls `init()` again to refresh state (AsyncViewModelImpl)
- `reinitializeWithContext()` - May trigger `init()` when context becomes available
