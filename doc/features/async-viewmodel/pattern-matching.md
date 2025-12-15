# Pattern Matching: match() and when()

`AsyncViewModelImpl` provides two pattern matching methods for exhaustively handling all possible async states. These methods delegate to the underlying `AsyncState<T>` pattern matching implementation.

## match()

### Method Signature

```dart
R match<R>({
  required R Function() initial,
  required R Function() loading,
  required R Function(T data) success,
  required R Function() empty,
  required R Function(Object? err, StackTrace? stackTrace) error,
})
```

### Purpose

Exhaustive pattern matching for all five async states. Every state must be handled, making this the safest and most complete way to respond to async state changes.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `initial` | `R Function()` | Called when state is `AsyncState.initial()` |
| `loading` | `R Function()` | Called when state is `AsyncState.loading()` |
| `success` | `R Function(T data)` | Called when state is `AsyncState.success(data)` - receives the data |
| `empty` | `R Function()` | Called when state is `AsyncState.empty()` |
| `error` | `R Function(Object? err, StackTrace? stackTrace)` | Called when state is `AsyncState.error()` - receives error and stack trace |

### Return Type

`R` - The generic return type allows returning any type (Widget, String, bool, etc.)

### Usage Example

```dart
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<ProductViewModel, List<Product>>(
      notifier: ProductService.products.notifier,
      onData: (products, viewModel, keep) {
        // Using match inside the builder for additional logic
        return viewModel.match(
          initial: () => InitialView(
            onStart: () => viewModel.reload(),
          ),
          loading: () => LoadingShimmer(itemCount: 6),
          success: (data) => ProductGrid(products: data),
          empty: () => EmptyStateView(
            icon: Icons.inventory_2_outlined,
            title: 'No Products',
            message: 'Add your first product to get started',
            action: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/add-product'),
              child: Text('Add Product'),
            ),
          ),
          error: (err, stack) => ErrorView(
            error: err,
            onRetry: () => viewModel.reload(),
          ),
        );
      },
    );
  }
}
```

### Building Widgets with match()

```dart
class OrderStatusWidget extends StatelessWidget {
  final OrderViewModel viewModel;

  const OrderStatusWidget({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return viewModel.match(
      initial: () => StatusChip(
        label: 'Not Started',
        color: Colors.grey,
      ),
      loading: () => StatusChip(
        label: 'Processing...',
        color: Colors.blue,
        showSpinner: true,
      ),
      success: (order) => StatusChip(
        label: order.status.displayName,
        color: order.status.color,
      ),
      empty: () => StatusChip(
        label: 'No Order',
        color: Colors.grey,
      ),
      error: (err, _) => StatusChip(
        label: 'Error',
        color: Colors.red,
        tooltip: err.toString(),
      ),
    );
  }
}
```

### Returning Non-Widget Values

```dart
class AnalyticsViewModel extends AsyncViewModelImpl<AnalyticsData> {
  String get statusMessage {
    return match(
      initial: () => 'Analytics not loaded',
      loading: () => 'Loading analytics...',
      success: (data) => 'Showing ${data.entries.length} entries',
      empty: () => 'No analytics data available',
      error: (err, _) => 'Failed to load: ${err.toString()}',
    );
  }

  bool get canExport {
    return match(
      initial: () => false,
      loading: () => false,
      success: (data) => data.entries.isNotEmpty,
      empty: () => false,
      error: (_, __) => false,
    );
  }

  Color get indicatorColor {
    return match(
      initial: () => Colors.grey,
      loading: () => Colors.blue,
      success: (_) => Colors.green,
      empty: () => Colors.orange,
      error: (_, __) => Colors.red,
    );
  }
}
```

---

## when()

### Method Signature

```dart
R when<R>({
  required R Function() initial,
  required R Function() loading,
  required R Function(T data) success,
  required R Function(Object? err, StackTrace? stackTrace) error,
})
```

### Purpose

Simplified pattern matching where the `empty` state is handled by the `error` callback. Use this when you don't need to distinguish between empty and error states, or when treating empty as an error condition is appropriate.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `initial` | `R Function()` | Called when state is `AsyncState.initial()` |
| `loading` | `R Function()` | Called when state is `AsyncState.loading()` |
| `success` | `R Function(T data)` | Called when state is `AsyncState.success(data)` |
| `error` | `R Function(Object? err, StackTrace? stackTrace)` | Called when state is `AsyncState.error()` OR `AsyncState.empty()` |

### Return Type

`R` - The generic return type allows returning any type

### Behavior

The `when()` method uses a `default` case in its switch statement, meaning:
- `AsyncStatus.initial` -> calls `initial()`
- `AsyncStatus.loading` -> calls `loading()`
- `AsyncStatus.success` -> calls `success(data)`
- `AsyncStatus.error` -> calls `error(err, stackTrace)`
- `AsyncStatus.empty` -> falls through to `error(null, null)`

### Usage Example

```dart
class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = UserService.profile.notifier;

    return viewModel.when(
      initial: () => SplashScreen(),
      loading: () => ProfileSkeleton(),
      success: (user) => ProfileView(user: user),
      error: (err, stack) => ErrorView(
        // Handles both actual errors and empty state
        message: err?.toString() ?? 'No profile found',
        onRetry: () => viewModel.reload(),
      ),
    );
  }
}
```

### Simple Loading States

```dart
class DataPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DataService.items.notifier.when(
      initial: () => Text('Tap to load'),
      loading: () => CircularProgressIndicator(),
      success: (items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (ctx, i) => ListTile(title: Text(items[i].name)),
      ),
      error: (err, _) => Column(
        children: [
          Text('Error: ${err ?? "No data"}'),
          ElevatedButton(
            onPressed: () => DataService.items.notifier.reload(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

---

## Comparison: match() vs when()

| Feature | match() | when() |
|---------|---------|--------|
| **States Handled** | 5 (initial, loading, success, empty, error) | 4 (initial, loading, success, error) |
| **Empty State** | Explicit handler | Falls through to error |
| **Use Case** | When empty needs distinct UI | When empty = error condition |
| **Type Safety** | Fully exhaustive | Slightly simpler |

### When to Use match()

```dart
// Use match() when empty state needs special handling
viewModel.match(
  initial: () => WelcomeScreen(),
  loading: () => LoadingView(),
  success: (items) => ItemList(items: items),
  empty: () => EmptyState(
    // Special empty state UI
    message: 'No items yet',
    action: AddFirstItemButton(),
  ),
  error: (err, _) => ErrorState(error: err),
);
```

### When to Use when()

```dart
// Use when() when empty should be treated like an error
viewModel.when(
  initial: () => Text('Not started'),
  loading: () => CircularProgressIndicator(),
  success: (user) => UserCard(user: user),
  error: (err, _) => Text(err?.toString() ?? 'User not found'),
);
```

---

## Complete Example

```dart
class ShoppingCartViewModel extends AsyncViewModelImpl<Cart> {
  ShoppingCartViewModel() : super(AsyncState.initial());

  @override
  Future<Cart> init() async {
    return await cartRepository.getCart();
  }

  // Using match() for comprehensive state handling
  Widget buildCartSummary() {
    return match(
      initial: () => CartSummaryPlaceholder(),
      loading: () => CartSummaryLoading(),
      success: (cart) => CartSummaryCard(
        itemCount: cart.items.length,
        total: cart.total,
        onCheckout: () => _startCheckout(),
      ),
      empty: () => EmptyCartCard(
        onBrowse: () => navigateToCatalog(),
      ),
      error: (err, stack) => CartErrorCard(
        message: _getErrorMessage(err),
        onRetry: reload,
      ),
    );
  }

  // Using when() for simple status text
  String get statusText {
    return when(
      initial: () => 'Your cart',
      loading: () => 'Loading cart...',
      success: (cart) => '${cart.items.length} items in cart',
      error: (err, _) => 'Unable to load cart',
    );
  }

  // Using match() for action button state
  Widget buildCheckoutButton() {
    return match(
      initial: () => OutlinedButton(
        onPressed: reload,
        child: Text('Load Cart'),
      ),
      loading: () => OutlinedButton(
        onPressed: null,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      success: (cart) => ElevatedButton(
        onPressed: cart.items.isNotEmpty ? _startCheckout : null,
        child: Text('Checkout (\$${cart.total.toStringAsFixed(2)})'),
      ),
      empty: () => OutlinedButton(
        onPressed: () => navigateToCatalog(),
        child: Text('Start Shopping'),
      ),
      error: (_, __) => OutlinedButton(
        onPressed: reload,
        child: Text('Retry'),
      ),
    );
  }

  // Using when() for boolean checks
  bool get isCheckoutEnabled {
    return when(
      initial: () => false,
      loading: () => false,
      success: (cart) => cart.items.isNotEmpty && cart.total > 0,
      error: (_, __) => false,
    );
  }

  String _getErrorMessage(Object? error) {
    if (error is NetworkException) {
      return 'Check your internet connection';
    }
    if (error is AuthException) {
      return 'Please sign in to view your cart';
    }
    return 'Something went wrong';
  }
}
```

## Best Practices

### 1. Prefer match() for UI Building

```dart
// RECOMMENDED - Explicit handling of all states
Widget build(context) {
  return viewModel.match(
    initial: () => InitialView(),
    loading: () => LoadingView(),
    success: (data) => SuccessView(data),
    empty: () => EmptyView(),
    error: (err, stack) => ErrorView(err),
  );
}
```

### 2. Use when() for Simple Cases

```dart
// GOOD - Simple status where empty = error
String get statusLabel => viewModel.when(
  initial: () => 'Ready',
  loading: () => 'Working...',
  success: (_) => 'Done',
  error: (_, __) => 'Failed',
);
```

### 3. Extract Complex Handlers

```dart
// GOOD - Keep match/when calls clean
Widget build(context) {
  return viewModel.match(
    initial: _buildInitial,
    loading: _buildLoading,
    success: _buildSuccess,
    empty: _buildEmpty,
    error: _buildError,
  );
}

Widget _buildSuccess(Data data) {
  // Complex success UI
  return Column(
    children: [
      Header(title: data.title),
      DataGrid(items: data.items),
      Footer(stats: data.stats),
    ],
  );
}
```

### 4. Use Return Type for Validation

```dart
// match() ensures all states are handled
bool canProceed = viewModel.match<bool>(
  initial: () => false,
  loading: () => false,
  success: (data) => data.isValid,
  empty: () => false,
  error: (_, __) => false,
);
```

### 5. Consider Builder Widgets for Complex UI

```dart
// For complex UIs, combine with ReactiveAsyncBuilder
ReactiveAsyncBuilder<MyViewModel, MyData>(
  notifier: service.notifier,
  onData: (data, vm, keep) => DataView(data),
  onLoading: () => LoadingView(),
  onError: (err, stack) => ErrorView(err),
  onEmpty: () => EmptyView(), // If supported
);

// Use match/when for internal ViewModel logic
class MyViewModel extends AsyncViewModelImpl<MyData> {
  String get summary => match(
    initial: () => 'Not loaded',
    loading: () => 'Loading...',
    success: (d) => '${d.count} items',
    empty: () => 'Empty',
    error: (e, _) => 'Error: $e',
  );
}
```

## Related Documentation

- [`AsyncState`](../state-types.md) - The underlying state class
- [`ReactiveAsyncBuilder`](../builders.md#reactiveasyncbuilder) - Widget builder for async states
- [`onAsyncStateChanged`](./on-async-state-changed.md) - Hook for state change reactions
