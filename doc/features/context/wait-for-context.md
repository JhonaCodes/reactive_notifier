# waitForContext Parameter

## Location

Constructor parameter of `AsyncViewModelImpl<T>`.

## Signature

```dart
AsyncViewModelImpl(
  AsyncState<T> initialState, {
  bool loadOnInit = true,
  bool waitForContext = false,  // <-- This parameter
})
```

## Type

`bool` - Default: `false`

## Description

The `waitForContext` parameter controls whether an AsyncViewModelImpl should delay its initialization until a BuildContext becomes available. When set to `true`, the ViewModel stays in `AsyncState.initial()` state until context is registered (either via builder mounting or `ReactiveNotifier.initContext()`).

### Source Implementation

```dart
// From lib/src/viewmodel/async_viewmodel_impl.dart (lines 49-68)
AsyncViewModelImpl(this._state,
    {this.loadOnInit = true, this.waitForContext = false})
    : super() {
  if (loadOnInit) {
    if (waitForContext && !hasContext) {
      // Wait for context - stay in initial state
      hasInitializedListenerExecution = false;
    } else {
      // Initialize immediately
      _initializeAsync();
      hasInitializedListenerExecution = true;
    }
  }
}
```

## Behavior Matrix

| `waitForContext` | `hasContext` on creation | Behavior |
|------------------|--------------------------|----------|
| `false` (default) | Any | Initializes immediately |
| `true` | `true` | Initializes immediately |
| `true` | `false` | Stays in `AsyncState.initial()` until context available |

## Usage Example

### Basic Usage

```dart
class ThemeAwareDataViewModel extends AsyncViewModelImpl<ThemeBasedData> {
  ThemeAwareDataViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,
    waitForContext: true,  // Wait for context before init()
  );

  @override
  Future<ThemeBasedData> init() async {
    // This only executes after BuildContext becomes available
    final theme = Theme.of(requireContext('theme-based data loading'));
    final isDark = theme.brightness == Brightness.dark;

    return await repository.loadData(darkMode: isDark);
  }
}
```

### With MediaQuery Access

```dart
class ResponsiveDataViewModel extends AsyncViewModelImpl<ResponsiveData> {
  ResponsiveDataViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,
    waitForContext: true,
  );

  @override
  Future<ResponsiveData> init() async {
    final mediaQuery = MediaQuery.of(requireContext('responsive setup'));
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;

    return await api.fetchData(
      layout: isTablet ? 'tablet' : 'phone',
      columns: isTablet ? 3 : 2,
    );
  }
}
```

### Riverpod Migration with Context

```dart
class MigrationViewModel extends AsyncViewModelImpl<MigratedData> {
  MigrationViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,
    waitForContext: true,  // Need context for Riverpod access
  );

  @override
  Future<MigratedData> init() async {
    final container = ProviderScope.containerOf(
      requireGlobalContext('Riverpod migration')
    );
    final riverpodData = container.read(dataProvider);

    // Migrate data to ReactiveNotifier
    return MigratedData.fromRiverpod(riverpodData);
  }
}
```

## When Context Becomes Available

Context becomes available in these scenarios, triggering initialization for waiting ViewModels:

### 1. Global Context Initialization

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This triggers initialization for all waiting ViewModels
    ReactiveNotifier.initContext(context);

    return MaterialApp(home: HomePage());
  }
}
```

### 2. Builder Mounting

```dart
// When this builder mounts, context becomes available for the ViewModel
ReactiveAsyncBuilder<ThemeAwareVM, ThemeData>(
  notifier: ThemeService.themeState.notifier,
  onData: (data, viewModel, keep) => ThemeWidget(data: data),
  onLoading: () => CircularProgressIndicator(),
  onError: (error, stack) => ErrorWidget(error: error),
)
```

### 3. Manual Reinitialization

```dart
// Rarely needed - usually automatic
viewModel.reinitializeWithContext();
```

## Lifecycle with waitForContext

```
Constructor called
      │
      ▼
waitForContext == true && !hasContext?
      │
      ├─── Yes ──► Stay in AsyncState.initial()
      │                    │
      │                    ▼
      │           Wait for context...
      │                    │
      │                    ├─── initContext() called
      │                    │           │
      │                    │           ▼
      │                    └─── reinitializeWithContext()
      │                                │
      │                                ▼
      │                           init() called
      │                                │
      │                                ▼
      │                           AsyncState.loading()
      │                                │
      │                                ▼
      │                           AsyncState.success(data)
      │
      └─── No ───► init() called immediately
                          │
                          ▼
                   AsyncState.loading()
                          │
                          ▼
                   AsyncState.success(data)
```

## Best Practices

### 1. Use When Context is Required in init()

```dart
// CORRECT - Use waitForContext when you need context in init()
class ContextDependentVM extends AsyncViewModelImpl<Data> {
  ContextDependentVM() : super(
    AsyncState.initial(),
    waitForContext: true,  // Required because init() uses context
  );

  @override
  Future<Data> init() async {
    final theme = Theme.of(requireContext('initialization'));
    return await loadDataForTheme(theme);
  }
}
```

### 2. Don't Use When Context Not Needed

```dart
// CORRECT - Don't use waitForContext if not needed
class SimpleVM extends AsyncViewModelImpl<List<Item>> {
  SimpleVM() : super(AsyncState.initial());  // No waitForContext

  @override
  Future<List<Item>> init() async {
    // No context needed - fetch directly
    return await repository.fetchItems();
  }
}
```

### 3. Combine with Global Context for Reliability

```dart
// Most reliable pattern: global init + waitForContext
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ReactiveNotifier.initContext(context);  // Global init
    return MaterialApp(home: HomePage());
  }
}

class MyViewModel extends AsyncViewModelImpl<Data> {
  MyViewModel() : super(
    AsyncState.initial(),
    waitForContext: true,  // Extra safety
  );

  @override
  Future<Data> init() async {
    // Always has context because of global init
    final theme = Theme.of(requireContext('init'));
    return await loadData(theme);
  }
}
```

### 4. Handle Loading State in UI

```dart
ReactiveAsyncBuilder<ThemeAwareVM, ThemeData>(
  notifier: ThemeService.state.notifier,
  onInitial: () => Text('Waiting for context...'),  // Show while waiting
  onLoading: () => CircularProgressIndicator(),
  onData: (data, vm, keep) => DataWidget(data: data),
  onError: (error, stack) => ErrorWidget(error: error),
)
```

## Common Patterns

### Deferred Context-Aware Loading

```dart
class DeferredContextVM extends AsyncViewModelImpl<ComplexData> {
  DeferredContextVM() : super(
    AsyncState.initial(),
    loadOnInit: false,      // Don't load immediately
    waitForContext: true,   // Wait for context when loaded
  );

  @override
  Future<ComplexData> init() async {
    final theme = Theme.of(requireContext('deferred load'));
    return await complexLoader.load(theme: theme);
  }

  // Manual trigger when ready
  Future<void> loadWhenReady() async {
    await loadNotifier();
  }
}
```

### Optional Context Usage

```dart
class FlexibleVM extends AsyncViewModelImpl<FlexibleData> {
  FlexibleVM() : super(AsyncState.initial());  // No waitForContext

  @override
  Future<FlexibleData> init() async {
    // Works with or without context
    if (hasContext) {
      final theme = Theme.of(context!);
      return await loadData(darkMode: theme.brightness == Brightness.dark);
    } else {
      return await loadData(darkMode: false);  // Default
    }
  }
}
```

## Comparison: waitForContext vs Manual Checking

### Using waitForContext

```dart
class WithWaitForContext extends AsyncViewModelImpl<Data> {
  WithWaitForContext() : super(
    AsyncState.initial(),
    waitForContext: true,
  );

  @override
  Future<Data> init() async {
    // Context guaranteed to be available
    final theme = Theme.of(requireContext('init'));
    return await loadData(theme);
  }
}
```

### Manual Context Checking

```dart
class WithManualCheck extends AsyncViewModelImpl<Data> {
  WithManualCheck() : super(AsyncState.initial());

  @override
  Future<Data> init() async {
    if (hasContext) {
      final theme = Theme.of(context!);
      return await loadData(theme);
    } else {
      // Fallback required
      return await loadDataWithDefaults();
    }
  }
}
```

| Approach | Pros | Cons |
|----------|------|------|
| `waitForContext: true` | Context guaranteed, cleaner code | Delays initialization |
| Manual checking | Immediate init, works without context | Requires fallback logic |

## Related

- [init-context](init-context.md) - Global context initialization
- [context](context.md) - Context getter
- [requireContext()](require-context.md) - Required context with errors
- [AsyncViewModelImpl Constructor](../async-viewmodel/constructor.md) - Full constructor documentation
