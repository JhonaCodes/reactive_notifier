# AsyncViewModelImpl Constructor

## Method Signature

```dart
AsyncViewModelImpl(
  AsyncState<T> initialState, {
  bool loadOnInit = true,
  bool waitForContext = false,
})
```

## Purpose

The constructor initializes an `AsyncViewModelImpl` with an initial async state and configures the automatic initialization behavior. It provides control over when and how the ViewModel loads its data.

## Parameters

### initialState (required)

**Type:** `AsyncState<T>`

The initial state of the ViewModel. Should typically be `AsyncState.initial()`.

### loadOnInit

**Type:** `bool`
**Default:** `true`

Controls whether `init()` is called automatically when the ViewModel is created.

- **`true` (default):** The `init()` method is called immediately after construction, triggering data loading automatically.
- **`false`:** The ViewModel stays in its initial state until `reload()` or `loadNotifier()` is called manually.

### waitForContext

**Type:** `bool`
**Default:** `false`

Controls whether the ViewModel waits for BuildContext availability before initializing.

- **`false` (default):** Initialization proceeds immediately regardless of context availability.
- **`true`:** The ViewModel stays in `AsyncState.initial()` until a BuildContext becomes available through a builder widget or `ReactiveNotifier.initContext()`.

## Return Type

Returns an instance of the `AsyncViewModelImpl<T>` subclass.

## Usage Example

### Basic Auto-Initialization (Default)

```dart
class UserListViewModel extends AsyncViewModelImpl<List<User>> {
  UserListViewModel() : super(AsyncState.initial());
  // loadOnInit: true (default) - init() called automatically

  @override
  Future<List<User>> init() async {
    return await userRepository.fetchAllUsers();
  }
}

// Usage: ViewModel loads data immediately upon creation
mixin UserService {
  static final ReactiveNotifier<UserListViewModel> users =
      ReactiveNotifier<UserListViewModel>(() => UserListViewModel());
}
```

### Manual Initialization

```dart
class SearchResultsViewModel extends AsyncViewModelImpl<List<SearchResult>> {
  SearchResultsViewModel() : super(
    AsyncState.initial(),
    loadOnInit: false, // Do not auto-initialize
  );

  String? _searchQuery;

  @override
  Future<List<SearchResult>> init() async {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return [];
    }
    return await searchRepository.search(_searchQuery!);
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await reload(); // Manually trigger initialization
  }
}

// Usage: ViewModel stays in initial state until search() is called
final viewModel = SearchResultsViewModel();
// Later, when user enters a search query:
await viewModel.search('flutter');
```

### Context-Dependent Initialization

```dart
class ThemeAwareViewModel extends AsyncViewModelImpl<ThemeSettings> {
  ThemeAwareViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,
    waitForContext: true, // Wait for BuildContext
  );

  @override
  Future<ThemeSettings> init() async {
    // This only executes after context becomes available
    final ctx = requireContext('theme initialization');
    final theme = Theme.of(ctx);
    final mediaQuery = MediaQuery.of(ctx);

    return ThemeSettings(
      isDarkMode: theme.brightness == Brightness.dark,
      primaryColor: theme.primaryColor,
      screenWidth: mediaQuery.size.width,
      isTablet: mediaQuery.size.width > 600,
    );
  }
}
```

### Combining loadOnInit and waitForContext

```dart
class LocalizedDataViewModel extends AsyncViewModelImpl<LocalizedContent> {
  LocalizedDataViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,       // Auto-initialize when possible
    waitForContext: true,   // But wait for context first
  );

  @override
  Future<LocalizedContent> init() async {
    final ctx = requireContext('localization');
    final locale = Localizations.localeOf(ctx);

    return await contentRepository.fetchContent(locale.languageCode);
  }
}
```

## Best Practices

### 1. Always Start with AsyncState.initial()

```dart
// RECOMMENDED
class GoodViewModel extends AsyncViewModelImpl<Data> {
  GoodViewModel() : super(AsyncState.initial());
}

// AVOID - May cause unexpected behavior
class BadViewModel extends AsyncViewModelImpl<Data> {
  BadViewModel() : super(AsyncState.loading());
}
```

### 2. Use loadOnInit: false for User-Triggered Operations

```dart
// Search, filtering, or operations that depend on user input
class FilterViewModel extends AsyncViewModelImpl<List<Item>> {
  FilterViewModel() : super(AsyncState.initial(), loadOnInit: false);

  FilterCriteria? _criteria;

  Future<void> applyFilter(FilterCriteria criteria) async {
    _criteria = criteria;
    await reload();
  }

  @override
  Future<List<Item>> init() async {
    if (_criteria == null) return [];
    return await repository.fetchWithFilter(_criteria!);
  }
}
```

### 3. Use waitForContext for Theme/MediaQuery Dependencies

```dart
class ResponsiveViewModel extends AsyncViewModelImpl<ResponsiveConfig> {
  ResponsiveViewModel() : super(
    AsyncState.initial(),
    waitForContext: true,
  );

  @override
  Future<ResponsiveConfig> init() async {
    final ctx = requireContext('responsive config');
    final size = MediaQuery.sizeOf(ctx);

    return ResponsiveConfig(
      columns: size.width > 1200 ? 4 : size.width > 800 ? 3 : 2,
      spacing: size.width > 600 ? 16.0 : 8.0,
    );
  }
}
```

### 4. Consider Global Context Initialization

Instead of using `waitForContext: true` on every ViewModel, initialize context globally:

```dart
// In main.dart or MyApp widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ReactiveNotifier.initContext(context); // Global context
    return MaterialApp(...);
  }
}

// Now all ViewModels have immediate context access
class AnyViewModel extends AsyncViewModelImpl<Data> {
  AnyViewModel() : super(AsyncState.initial());
  // No need for waitForContext: true

  @override
  Future<Data> init() async {
    // Context is available immediately via global initialization
    if (hasContext) {
      final theme = Theme.of(context!);
      // Use theme
    }
    return await loadData();
  }
}
```

### 5. Document Why loadOnInit is Disabled

```dart
class OrderHistoryViewModel extends AsyncViewModelImpl<List<Order>> {
  /// [loadOnInit: false] because this ViewModel requires
  /// a valid user session before loading orders.
  /// Call [loadForUser] after authentication completes.
  OrderHistoryViewModel() : super(AsyncState.initial(), loadOnInit: false);

  String? _userId;

  Future<void> loadForUser(String userId) async {
    _userId = userId;
    await reload();
  }

  @override
  Future<List<Order>> init() async {
    if (_userId == null) {
      throw StateError('User ID required before loading orders');
    }
    return await orderRepository.getOrdersForUser(_userId!);
  }
}
```
