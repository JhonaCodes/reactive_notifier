# reload() Method

## Method Signature

### ViewModel<T>
```dart
Future<void> reload() async;
```

### AsyncViewModelImpl<T>
```dart
Future<void> reload() async;
```

## Purpose

The `reload()` method provides a way to refresh the ViewModel's state by re-executing the initialization sequence. It is the primary mechanism for refreshing data after the initial load, handling the complete cycle of teardown and re-initialization.

**Key Differences:**
- In `ViewModel<T>`: Calls `init()` synchronously, then `setupListeners()` and `onResume()`
- In `AsyncViewModelImpl<T>`: Manages loading states, calls async `init()`, handles errors automatically

## Parameters

None.

## Return Type

`Future<void>`

## When It's Called

### Automatic Invocation

**AsyncViewModelImpl<T>:**
- Called by `_initializeAsync()` during construction when `loadOnInit: true`
- Called by `loadNotifier()` when data needs to be loaded

**ViewModel<T>:**
- Not called automatically during normal initialization
- The synchronous `init()` is called directly instead

### Manual Invocation

`reload()` is designed for manual invocation when you need to:
- Refresh data from an API
- Reset state after user actions
- Recover from errors
- Pull-to-refresh functionality

## Source Code Reference

### ViewModel<T> Reload Implementation

From `viewmodel_impl.dart` (lines 537-555):

```dart
Future<void> reload() async {
  try {
    if (_initialized) {
      await removeListeners();
    }

    init();
    await setupListeners();
    await onResume(_data);
  } catch (error, stackTrace) {
    log(error.toString());
    log(stackTrace.toString());
    try {
      await setupListeners();
    } catch (listenerError) {
      log('Error on restart listeners: $listenerError');
    }
  }
}
```

### AsyncViewModelImpl<T> Reload Implementation

From `async_viewmodel_impl.dart` (lines 132-157):

```dart
Future<void> reload() async {
  if (_state.isLoading) return; // Prevent concurrent reloads
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
    try {
      await setupListeners();
    } catch (listenerError) {
      log('Error on restart listeners: $listenerError');
    }
  }
}
```

## Reload Sequence

### ViewModel<T>

```
reload() called
    |
    v
[1] removeListeners() - Clean existing listeners (if initialized)
    |
    v
[2] init() - Re-run synchronous initialization
    |
    v
[3] setupListeners() - Re-register listeners
    |
    v
[4] onResume(data) - Post-initialization hook
```

### AsyncViewModelImpl<T>

```
reload() called
    |
    v
[Check] Is loading? -> Return early if true
    |
    v
[1] removeListeners() - Clean existing listeners
    |
    v
[2] loadingState() - Set state to loading (notifies UI)
    |
    v
[3] init() - Re-run async initialization
    |
    v
[4] updateState(result) - Set success state with data
    |
    v
[5] setupListeners() - Re-register listeners
    |
    v
[6] onResume(data) - Post-initialization hook
    |
    v
[Error?] -> errorState() + attempt setupListeners()
```

## Usage Examples

### Basic Reload (AsyncViewModelImpl)

```dart
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  final ProductRepository _repository;

  ProductsViewModel(this._repository) : super(AsyncState.initial());

  @override
  Future<List<Product>> init() async {
    return await _repository.fetchProducts();
  }
}

// Usage in widget
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<ProductsViewModel, List<Product>>(
      notifier: ProductService.products.notifier,
      onData: (products, viewModel, keep) {
        return RefreshIndicator(
          onRefresh: () => viewModel.reload(), // Pull to refresh
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, index) => ProductTile(products[index]),
          ),
        );
      },
      onLoading: () => CircularProgressIndicator(),
      onError: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### Reload with Filters

```dart
class FilterableProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  String _currentCategory = 'all';

  @override
  Future<List<Product>> init() async {
    return await repository.fetchProducts(category: _currentCategory);
  }

  Future<void> filterByCategory(String category) async {
    _currentCategory = category;
    await reload(); // Reload with new filter
  }
}
```

### Reload After User Action

```dart
class CartViewModel extends AsyncViewModelImpl<CartModel> {
  @override
  Future<CartModel> init() async {
    return await cartService.fetchCart();
  }

  Future<void> addItem(Product product) async {
    await cartService.addToCart(product);
    await reload(); // Refresh cart after adding item
  }

  Future<void> removeItem(String productId) async {
    await cartService.removeFromCart(productId);
    await reload(); // Refresh cart after removal
  }
}
```

### Conditional Reload

```dart
class DataViewModel extends AsyncViewModelImpl<DataModel> {
  DateTime? _lastFetch;
  final Duration _cacheTimeout = Duration(minutes: 5);

  @override
  Future<DataModel> init() async {
    _lastFetch = DateTime.now();
    return await repository.fetchData();
  }

  Future<void> reloadIfStale() async {
    if (_lastFetch == null) {
      await reload();
      return;
    }

    final elapsed = DateTime.now().difference(_lastFetch!);
    if (elapsed > _cacheTimeout) {
      await reload();
    }
  }
}
```

### Error Recovery with Reload

```dart
class ResilienceViewModel extends AsyncViewModelImpl<ApiData> {
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  Future<ApiData> init() async {
    try {
      final data = await apiClient.fetchData();
      _retryCount = 0; // Reset on success
      return data;
    } catch (e) {
      _retryCount++;
      rethrow;
    }
  }

  Future<void> retryWithBackoff() async {
    if (_retryCount >= _maxRetries) {
      throw Exception('Max retries exceeded');
    }

    // Exponential backoff
    await Future.delayed(Duration(seconds: pow(2, _retryCount).toInt()));
    await reload();
  }
}

// Usage
onError: (error, stack) => Column(
  children: [
    Text('Error: $error'),
    ElevatedButton(
      onPressed: () => viewModel.retryWithBackoff(),
      child: Text('Retry'),
    ),
  ],
),
```

### ViewModel Reload (Synchronous)

```dart
class SettingsViewModel extends ViewModel<SettingsModel> {
  SettingsViewModel() : super(SettingsModel.defaults());

  @override
  void init() {
    final stored = localStorage.getSettings();
    updateSilently(stored ?? SettingsModel.defaults());
  }

  Future<void> refreshFromServer() async {
    // Fetch new settings
    final serverSettings = await settingsApi.fetch();
    localStorage.saveSettings(serverSettings);

    // Reload to pick up new values
    await reload();
  }
}
```

## Best Practices

### 1. Prevent Concurrent Reloads

AsyncViewModelImpl already guards against this:

```dart
Future<void> reload() async {
  if (_state.isLoading) return; // Built-in guard
  // ...
}
```

For ViewModel, implement your own guard:

```dart
class SafeViewModel extends ViewModel<MyState> {
  bool _isReloading = false;

  Future<void> safeReload() async {
    if (_isReloading) return;
    _isReloading = true;
    try {
      await reload();
    } finally {
      _isReloading = false;
    }
  }
}
```

### 2. Provide User Feedback During Reload

```dart
ReactiveAsyncBuilder<DataVM, Data>(
  notifier: Service.data.notifier,
  onData: (data, vm, keep) => DataView(data),
  onLoading: () => Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        Text('Refreshing data...'),
      ],
    ),
  ),
)
```

### 3. Handle Partial Updates

```dart
Future<void> partialReload() async {
  // Keep existing data visible during reload
  final existingData = data;
  try {
    await reload();
  } catch (e) {
    // Restore previous data on error
    if (existingData != null) {
      updateState(existingData);
    }
  }
}
```

### 4. Use reload() Instead of Re-creating ViewModel

```dart
// WRONG - Creates new ViewModel instance
void refreshData() {
  final newVM = MyViewModel(); // Don't do this!
}

// CORRECT - Use existing instance
void refreshData() {
  MyService.data.notifier.reload();
}
```

### 5. Debounce Rapid Reload Calls

```dart
Timer? _debounceTimer;

void debouncedReload() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    reload();
  });
}
```

## Common Mistakes to Avoid

### 1. Calling reload() in init()

```dart
// WRONG - Creates infinite loop
@override
Future<Data> init() async {
  final data = await fetchData();
  await reload(); // Never do this!
  return data;
}

// CORRECT - Let reload() call init()
@override
Future<Data> init() async {
  return await fetchData();
}
```

### 2. Not Handling Loading State in UI

```dart
// WRONG - UI doesn't show loading during reload
ReactiveBuilder<List<Item>>(
  notifier: service.items,
  build: (items, notifier, keep) => ListView(...),
  // No loading handling!
)

// CORRECT - Handle loading state
ReactiveAsyncBuilder<ItemsVM, List<Item>>(
  notifier: service.items.notifier,
  onData: (items, vm, keep) => ListView(...),
  onLoading: () => LoadingIndicator(),
  onError: (e, s) => ErrorView(e),
)
```

### 3. Ignoring Error Recovery

```dart
// WRONG - No error handling
onPressed: () => viewModel.reload(), // What if it fails?

// CORRECT - Handle errors gracefully
onPressed: () async {
  try {
    await viewModel.reload();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to refresh: $e')),
    );
  }
},
```

### 4. Not Awaiting reload()

```dart
// WRONG - Fire and forget without tracking
void refresh() {
  viewModel.reload(); // Not awaited
  showSuccessMessage(); // May show before reload completes!
}

// CORRECT - Await the reload
Future<void> refresh() async {
  await viewModel.reload();
  showSuccessMessage();
}
```

### 5. Reload Without Cleanup

```dart
// ViewModel.reload() handles this automatically, but be aware:
// 1. removeListeners() is called first
// 2. Then init() runs
// 3. Then setupListeners() re-registers

// Don't manually call init() without the full sequence
void wrongApproach() {
  init(); // Missing listener cleanup and re-registration!
}
```

## Lifecycle Position

The `reload()` method can be called at any point during the active state:

```
Constructor -> init() -> setupListeners() -> onResume()
                                               |
                                               v
                                        [Active State] <--+
                                               |          |
                                          reload() -------+
                                               |
                                               v
                                          dispose()
```

## Related Methods

- `init()` - Called by reload() to re-initialize state
- `setupListeners()` - Called by reload() after init()
- `removeListeners()` - Called by reload() before init()
- `onResume()` - Called by reload() after setupListeners()
- `loadNotifier()` - Alternative entry point that may call reload()
