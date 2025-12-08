# loadNotifier() Method

## Method Signature

### ViewModel<T>
```dart
Future<void> loadNotifier() async;
```

### AsyncViewModelImpl<T>
```dart
Future<void> loadNotifier() async;
```

## Purpose

The `loadNotifier()` method ensures the ViewModel's availability by confirming initialization has occurred. It provides an explicit way to guarantee a ViewModel is ready for use, particularly useful during app startup or when accessing ViewModels outside their normal lifecycle.

**Key Behavior:**
- **Idempotent**: Safe to call multiple times without side effects
- **No-op if initialized**: Returns immediately if ViewModel is already ready
- **Triggers initialization**: Calls `init()` and `setupListeners()` if data is not loaded

## Parameters

None.

## Return Type

`Future<void>` - Completes immediately, allowing sequential async operations.

## When It's Called

### Manual Invocation Only

`loadNotifier()` is designed for manual invocation in specific scenarios:

1. **App startup pre-loading**: Ensure critical ViewModels are ready before UI renders
2. **Uncertain initialization state**: When code path doesn't guarantee ViewModel initialization
3. **Lazy initialization**: When `loadOnInit: false` was used and you need data
4. **Data availability guarantee**: Before operations that require ViewModel data

### Not Called Automatically

Unlike `init()`, `loadNotifier()` is never called automatically by the framework. It's an opt-in method for explicit initialization control.

## Source Code Reference

### ViewModel<T> Implementation

From `viewmodel_impl.dart` (lines 499-512):

```dart
Future<void> loadNotifier() async {
  assert(() {
    log('''
loadNotifier() called for ViewModel<${T.toString()}>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Already initialized: $_initialized
Is disposed: $_disposed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
    return true;
  }());
  return Future.value();
}
```

### AsyncViewModelImpl<T> Implementation

From `async_viewmodel_impl.dart` (lines 504-518):

```dart
Future<void> loadNotifier() async {
  assert(() {
    log('''
loadNotifier() called for ViewModel<${T.toString()}>
''', level: 10);
    return true;
  }());

  if (_state.data == null || loadOnInit) {
    await init();
    await setupListeners();
    return;
  }
  return Future.value();
}
```

## Behavior Comparison

| Scenario | ViewModel<T> | AsyncViewModelImpl<T> |
|----------|--------------|----------------------|
| Already initialized | Returns immediately | Returns immediately |
| Not initialized | Returns immediately (init() was called in constructor) | Calls init() and setupListeners() |
| Data is null | Returns immediately | Calls init() and setupListeners() |
| loadOnInit was true | Returns immediately | May call init() again if data is null |

## Usage Examples

### App Startup Pre-loading

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load critical ViewModels before app starts
  await Future.wait([
    AuthService.authState.notifier.loadNotifier(),
    ConfigService.appConfig.notifier.loadNotifier(),
    UserService.currentUser.notifier.loadNotifier(),
  ]);

  runApp(MyApp());
}
```

### Lazy Initialization Pattern

```dart
mixin HeavyDataService {
  static final ReactiveNotifier<HeavyDataViewModel> heavyData =
    ReactiveNotifier<HeavyDataViewModel>(() => HeavyDataViewModel());
}

class HeavyDataViewModel extends AsyncViewModelImpl<LargeDataset> {
  // Don't load automatically - data is expensive to fetch
  HeavyDataViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<LargeDataset> init() async {
    return await repository.fetchLargeDataset();
  }
}

// Only load when user navigates to data-heavy screen
class DataHeavyScreen extends StatefulWidget {
  @override
  State<DataHeavyScreen> createState() => _DataHeavyScreenState();
}

class _DataHeavyScreenState extends State<DataHeavyScreen> {
  @override
  void initState() {
    super.initState();
    // Explicitly load the heavy data
    HeavyDataService.heavyData.notifier.loadNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<HeavyDataViewModel, LargeDataset>(
      notifier: HeavyDataService.heavyData.notifier,
      onData: (data, vm, keep) => DataVisualization(data),
      onLoading: () => LoadingScreen(),
      onError: (e, s) => ErrorScreen(e),
    );
  }
}
```

### Ensuring Data Before Operation

```dart
class CheckoutViewModel extends AsyncViewModelImpl<CheckoutState> {
  Future<void> processPayment() async {
    // Ensure cart data is loaded before processing
    await CartService.cart.notifier.loadNotifier();
    await UserService.currentUser.notifier.loadNotifier();

    final cart = CartService.cart.notifier.data;
    final user = UserService.currentUser.notifier.data;

    if (cart == null || user == null) {
      errorState(Exception('Required data not available'));
      return;
    }

    // Process payment with guaranteed data
    await _processPaymentWithData(cart, user);
  }
}
```

### Splash Screen Loading

```dart
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load all essential ViewModels
      await Future.wait([
        AppConfigService.config.notifier.loadNotifier(),
        ThemeService.theme.notifier.loadNotifier(),
        LocaleService.locale.notifier.loadNotifier(),
      ]);

      // Navigate to home after loading
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
```

### Sequential Initialization with Dependencies

```dart
Future<void> initializeServices() async {
  // Step 1: Load authentication first
  await AuthService.auth.notifier.loadNotifier();

  // Step 2: Load user data (depends on auth)
  if (AuthService.auth.notifier.data?.isAuthenticated ?? false) {
    await UserService.user.notifier.loadNotifier();
  }

  // Step 3: Load user-specific data (depends on user)
  if (UserService.user.notifier.data != null) {
    await Future.wait([
      PreferencesService.prefs.notifier.loadNotifier(),
      NotificationService.notifications.notifier.loadNotifier(),
    ]);
  }
}
```

### With Error Handling

```dart
Future<bool> safeLoadNotifier<T>(ReactiveNotifier<AsyncViewModelImpl<T>> service) async {
  try {
    await service.notifier.loadNotifier();
    return true;
  } catch (e) {
    log('Failed to load ${T.toString()}: $e');
    return false;
  }
}

// Usage
Future<void> initApp() async {
  final results = await Future.wait([
    safeLoadNotifier(AuthService.auth),
    safeLoadNotifier(ConfigService.config),
  ]);

  final allLoaded = results.every((success) => success);
  if (!allLoaded) {
    // Handle partial initialization
    showPartialLoadWarning();
  }
}
```

## Best Practices

### 1. Use for Pre-loading Critical Data

```dart
// Good: Pre-load essential data at startup
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CriticalService.data.notifier.loadNotifier();
  runApp(MyApp());
}
```

### 2. Combine with Future.wait for Parallel Loading

```dart
// Efficient: Load multiple ViewModels in parallel
await Future.wait([
  ServiceA.data.notifier.loadNotifier(),
  ServiceB.data.notifier.loadNotifier(),
  ServiceC.data.notifier.loadNotifier(),
]);
```

### 3. Use with Lazy ViewModels

```dart
// When loadOnInit: false is used, loadNotifier() triggers loading
class LazyViewModel extends AsyncViewModelImpl<Data> {
  LazyViewModel() : super(AsyncState.initial(), loadOnInit: false);
  // ...
}

// Later, when data is needed:
await LazyService.lazy.notifier.loadNotifier();
```

### 4. Don't Overuse

```dart
// UNNECESSARY - ViewModel is already initialized by constructor
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Don't call loadNotifier() in build - init() already ran
    MyService.data.notifier.loadNotifier(); // Unnecessary!

    return ReactiveBuilder(...);
  }
}

// CORRECT - Only call when you need explicit guarantee
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // Only if using loadOnInit: false
    if (needsExplicitLoad) {
      LazyService.data.notifier.loadNotifier();
    }
  }
}
```

## Common Mistakes to Avoid

### 1. Calling in build() Method

```dart
// WRONG - Called on every rebuild
@override
Widget build(BuildContext context) {
  MyService.data.notifier.loadNotifier(); // Don't do this!
  return Container();
}

// CORRECT - Call in initState or before build
@override
void initState() {
  super.initState();
  MyService.data.notifier.loadNotifier();
}
```

### 2. Not Awaiting When Order Matters

```dart
// WRONG - Data might not be ready
void process() {
  DataService.data.notifier.loadNotifier(); // Not awaited!
  useData(DataService.data.notifier.data); // May be null!
}

// CORRECT - Await before using data
Future<void> process() async {
  await DataService.data.notifier.loadNotifier();
  useData(DataService.data.notifier.data); // Data is ready
}
```

### 3. Using Instead of reload()

```dart
// WRONG - loadNotifier() won't refresh already loaded data
Future<void> refreshData() async {
  await service.notifier.loadNotifier(); // No-op if already loaded!
}

// CORRECT - Use reload() for refreshing
Future<void> refreshData() async {
  await service.notifier.reload(); // Actually refreshes data
}
```

### 4. Ignoring Exceptions

```dart
// WRONG - Silently fails
void initializeApp() {
  DataService.data.notifier.loadNotifier(); // May throw!
}

// CORRECT - Handle potential errors
Future<void> initializeApp() async {
  try {
    await DataService.data.notifier.loadNotifier();
  } catch (e) {
    handleInitializationError(e);
  }
}
```

### 5. Redundant Calls for Auto-Init ViewModels

```dart
// UNNECESSARY - ViewModel with loadOnInit: true already initializes
class AutoViewModel extends AsyncViewModelImpl<Data> {
  AutoViewModel() : super(AsyncState.initial(), loadOnInit: true);
}

// loadNotifier() is redundant here if data is already loaded
await AutoService.auto.notifier.loadNotifier(); // Usually no-op
```

## Lifecycle Position

`loadNotifier()` can be called at any time but is typically used early:

```
[App Startup]
      |
      v
loadNotifier() <-- Common usage point
      |
      v
Constructor -> init() -> setupListeners() -> onResume()
      |
      v
[Active State]
      |
      v
  dispose()
```

## Comparison with Other Methods

| Method | Purpose | When to Use |
|--------|---------|-------------|
| `loadNotifier()` | Ensure initialization | App startup, lazy loading |
| `reload()` | Refresh data | Pull-to-refresh, manual refresh |
| `init()` | Initialize state | Automatically by constructor |

## Related Methods

- `init()` - The actual initialization logic called by loadNotifier()
- `setupListeners()` - Called after init() when loadNotifier() triggers initialization
- `reload()` - Use this instead when you need to refresh already-loaded data
- `hasInitializedListenerExecution` - Flag to check if initialization is complete
