# Builder Widgets

ReactiveNotifier provides a set of builder widgets that enable reactive UI updates when state changes. Each builder is designed for specific use cases and provides the `keep()` function for performance optimization.

## Table of Contents

- [ReactiveBuilder](#reactivebuilder)
- [ReactiveViewModelBuilder](#reactiveviewmodelbuilder)
- [ReactiveAsyncBuilder](#reactiveasyncbuilder)
- [ReactiveStreamBuilder](#reactivestreambuilder)
- [ReactiveFutureBuilder](#reactivefuturebuilder)
- [The keep() Function](#the-keep-function)

---

## ReactiveBuilder

`ReactiveBuilder<T>` is the simplest builder widget for handling reactive state from a `ReactiveNotifier<T>`. Use it for simple state values like primitives, settings, flags, or direct model state.

### Purpose and When to Use

- **Simple state values**: integers, booleans, strings, enums
- **Settings or configuration state**
- **State that does not require complex business logic**
- **Direct model state without ViewModel wrapper**

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `notifier` | `NotifierImpl<T>` | Yes | The reactive notifier to listen to |
| `build` | `Widget Function(T, NotifierImpl<T>, Widget Function(Widget))` | No* | The builder function (recommended) |
| `builder` | `Widget Function(T, Widget Function(Widget))` | No* | **Deprecated** - use `build` instead |

*At least one of `build` or `builder` must be provided.

### Build Callback Signature

```dart
Widget Function(
  T state,                           // Current state value
  NotifierImpl<T> notifier,          // The notifier with update methods
  Widget Function(Widget child) keep // Widget preservation function
)
```

**Parameters explained:**
- `state`: The current reactive value of type `T`
- `notifier`: The internal `NotifierImpl<T>` containing state update methods and logic
- `keep`: A wrapper function used to prevent unnecessary widget rebuilds

### Deprecated Parameter

The `builder` parameter is deprecated and will be removed in version 3.0.0. Use `build` instead, which provides access to the `notifier` parameter for direct state manipulation.

```dart
// OLD (deprecated)
builder: (value, keep) => Text('$value')

// NEW (recommended)
build: (value, notifier, keep) => Text('$value')
```

### Usage Example

```dart
// Service definition using mixin pattern
mixin CounterService {
  static final ReactiveNotifier<int> count =
    ReactiveNotifier<int>(() => 0);
}

// Widget usage
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<int>(
      notifier: CounterService.count,
      build: (count, notifier, keep) {
        return Column(
          children: [
            Text('Count: $count'),
            keep(const ExpensiveWidget()), // Never rebuilds
            ElevatedButton(
              onPressed: () => notifier.updateState(count + 1),
              child: const Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}
```

### With Complex State

```dart
mixin UserService {
  static final ReactiveNotifier<UserModel> user =
    ReactiveNotifier<UserModel>(() => UserModel.guest());
}

class UserProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<UserModel>(
      notifier: UserService.user,
      build: (user, notifier, keep) {
        return Card(
          child: Column(
            children: [
              Text('Welcome, ${user.name}'),
              Text('Email: ${user.email}'),
              keep(const StaticHeader()), // Preserved across rebuilds
            ],
          ),
        );
      },
    );
  }
}
```

---

## ReactiveViewModelBuilder

`ReactiveViewModelBuilder<VM, T>` is designed for handling ViewModel states with complex business logic. It works specifically with `ViewModel<T>` implementations.

### Purpose and When to Use

- **Complex state objects** with business logic
- **State requiring validation or transformation**
- **ViewModels with methods for data manipulation**
- **When you need direct access to ViewModel methods**

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `viewmodel` | `ViewModel<T>` | Yes | The ViewModel instance to observe |
| `build` | `Widget Function(T, VM, Widget Function(Widget))` | No* | The builder function (recommended) |
| `builder` | `Widget Function(T, Widget Function(Widget))` | No* | **Deprecated** - use `build` instead |

*At least one of `build` or `builder` must be provided.

### Build Callback Signature

```dart
Widget Function(
  T state,                           // Current state value from ViewModel.data
  VM viewmodel,                      // The ViewModel instance with business logic
  Widget Function(Widget child) keep // Widget preservation function
)
```

**Parameters explained:**
- `state`: The current value of the reactive state (`ViewModel.data`)
- `viewmodel`: The `ViewModel` instance containing business logic, validation, and update methods
- `keep`: A helper function to prevent unnecessary widget rebuilds

### Deprecated Parameter

The `builder` parameter is deprecated and will be removed in version 3.0.0. Use `build` instead, which provides access to the `viewmodel` parameter.

```dart
// OLD (deprecated)
builder: (state, keep) => Text(state.name)

// NEW (recommended)
build: (state, viewmodel, keep) => Text(state.name)
```

### Usage Example

```dart
// ViewModel definition
class CartViewModel extends ViewModel<CartModel> {
  CartViewModel() : super(CartModel.empty());

  @override
  void init() {
    // Synchronous initialization
  }

  void addItem(Product product) {
    transformState((cart) => cart.copyWith(
      items: [...cart.items, product],
      total: cart.total + product.price,
    ));
  }

  void removeItem(String productId) {
    transformState((cart) => cart.copyWith(
      items: cart.items.where((p) => p.id != productId).toList(),
    ));
  }

  bool get isEmpty => data.items.isEmpty;
}

// Service definition
mixin CartService {
  static final ReactiveNotifier<CartViewModel> cart =
    ReactiveNotifier<CartViewModel>(() => CartViewModel());
}

// Widget usage
class CartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveViewModelBuilder<CartViewModel, CartModel>(
      viewmodel: CartService.cart.notifier,
      build: (cart, viewModel, keep) {
        return Column(
          children: [
            Text('Total: \$${cart.total.toStringAsFixed(2)}'),
            Text('Items: ${cart.items.length}'),
            keep(const CartHeader()), // Never rebuilds
            Expanded(
              child: ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return ListTile(
                    title: Text(item.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => viewModel.removeItem(item.id),
                    ),
                  );
                },
              ),
            ),
            if (!viewModel.isEmpty)
              ElevatedButton(
                onPressed: () => _checkout(context, cart),
                child: const Text('Checkout'),
              ),
          ],
        );
      },
    );
  }
}
```

### Automatic Context Registration

`ReactiveViewModelBuilder` automatically:
1. Registers the `BuildContext` for the ViewModel before initialization
2. Calls `reinitializeWithContext()` for ViewModels created without context
3. Manages reference counting for widget-aware lifecycle
4. Unregisters context when the widget disposes

---

## ReactiveAsyncBuilder

`ReactiveAsyncBuilder<VM, T>` handles asynchronous state with built-in support for loading, success, and error states. It works with `AsyncViewModelImpl<T>`.

### Purpose and When to Use

- **API calls and network requests**
- **Database operations**
- **File I/O operations**
- **Any asynchronous data loading**
- **States that transition through loading/success/error**

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `notifier` | `AsyncViewModelImpl<T>` | Yes | The async ViewModel to observe |
| `onData` | `Widget Function(T, VM, Widget Function(Widget))` | No* | Builder for success state (recommended) |
| `onSuccess` | `Widget Function(T)` | No* | **Deprecated** - use `onData` instead |
| `onLoading` | `Widget Function()` | No | Builder for loading state |
| `onError` | `Widget Function(Object?, StackTrace?)` | No | Builder for error state |
| `onInitial` | `Widget Function()` | No | Builder for initial state |

*At least one of `onData` or `onSuccess` should be provided for meaningful UI.

### onData Callback Signature

```dart
Widget Function(
  T data,                            // The loaded data
  VM viewModel,                      // The AsyncViewModelImpl instance
  Widget Function(Widget child) keep // Widget preservation function
)
```

**Parameters explained:**
- `data`: The successfully loaded data of type `T`
- `viewModel`: The `AsyncViewModelImpl` instance for reload/refresh operations
- `keep`: A helper function to prevent unnecessary widget rebuilds

### Deprecated Parameter

The `onSuccess` parameter is deprecated and will be removed in version 3.0.0. Use `onData` instead, which provides access to the `viewModel` and `keep` parameters.

```dart
// OLD (deprecated)
onSuccess: (data) => Text(data.title)

// NEW (recommended)
onData: (data, viewModel, keep) => Text(data.title)
```

### Default Behaviors

| State | Default Widget |
|-------|----------------|
| `onInitial` | `SizedBox.shrink()` |
| `onLoading` | `Center(child: CircularProgressIndicator.adaptive())` |
| `onError` | `Center(child: Text('Error: $error'))` |
| `onData` / `onSuccess` | `SizedBox.shrink()` |

### Usage Example

```dart
// AsyncViewModel definition
class ProductListViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductListViewModel() : super(AsyncState.initial(), loadOnInit: true);

  @override
  Future<List<Product>> init() async {
    return await ProductRepository.fetchAll();
  }

  Future<void> refreshProducts() async {
    await reload();
  }

  Future<void> searchProducts(String query) async {
    loadingState();
    try {
      final results = await ProductRepository.search(query);
      updateState(results);
    } catch (e, stack) {
      errorState(e.toString());
    }
  }
}

// Service definition
mixin ProductService {
  static final ReactiveNotifier<ProductListViewModel> products =
    ReactiveNotifier<ProductListViewModel>(() => ProductListViewModel());
}

// Widget usage
class ProductListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<ProductListViewModel, List<Product>>(
      notifier: ProductService.products.notifier,
      onInitial: () => const Center(
        child: Text('Tap to load products'),
      ),
      onLoading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...'),
          ],
        ),
      ),
      onError: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () => ProductService.products.notifier.reload(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      onData: (products, viewModel, keep) {
        return RefreshIndicator(
          onRefresh: viewModel.refreshProducts,
          child: Column(
            children: [
              keep(const ProductListHeader()), // Never rebuilds
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### waitForContext Pattern

For AsyncViewModels that need BuildContext during initialization:

```dart
class ThemeAwareViewModel extends AsyncViewModelImpl<ThemeConfig> {
  ThemeAwareViewModel() : super(
    AsyncState.initial(),
    loadOnInit: true,
    waitForContext: true, // Wait for context before init()
  );

  @override
  Future<ThemeConfig> init() async {
    // Context is guaranteed to be available
    final theme = Theme.of(requireContext('theme initialization'));
    return await loadThemeConfig(theme.brightness);
  }
}
```

---

## ReactiveStreamBuilder

`ReactiveStreamBuilder<VM, T>` handles reactive streams with automatic subscription management and state transitions.

### Purpose and When to Use

- **Real-time data streams** (WebSockets, Firebase, etc.)
- **Continuous data updates**
- **Event-based data sources**
- **Any `Stream<T>` data source**

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `notifier` | `ReactiveNotifier<Stream<T>>` | Yes | The reactive notifier wrapping a stream |
| `onData` | `Widget Function(T, VM, Widget Function(Widget))` | Yes | Builder for data events |
| `onLoading` | `Widget Function()` | No | Builder for loading state |
| `onError` | `Widget Function(Object)` | No | Builder for error events |
| `onEmpty` | `Widget Function()` | No | Builder for initial/empty state |
| `onDone` | `Widget Function()` | No | Builder for stream completion |

### onData Callback Signature

```dart
Widget Function(
  T data,                            // Latest value from stream
  VM viewmodel,                      // The ReactiveNotifier wrapping the stream
  Widget Function(Widget child) keep // Widget preservation function
)
```

**Parameters explained:**
- `data`: The latest value emitted by the stream
- `viewmodel`: The reactive state that wraps the stream
- `keep`: Function to prevent unnecessary widget rebuilds

### Stream States

| State | Trigger | Default Widget |
|-------|---------|----------------|
| `initial` | Before subscription | `onEmpty` or `SizedBox.shrink()` |
| `loading` | During subscription setup | `onLoading` or `CircularProgressIndicator` |
| `data` | Stream emits data | `onData` (required) |
| `error` | Stream emits error | `onError` or `Text('Error: $error')` |
| `done` | Stream closes | `onDone` or `SizedBox.shrink()` |

### Usage Example

```dart
// Service definition
mixin ChatService {
  static final ReactiveNotifier<Stream<List<Message>>> messages =
    ReactiveNotifier<Stream<List<Message>>>(() => _createMessageStream());

  static Stream<List<Message>> _createMessageStream() {
    return FirebaseFirestore.instance
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .toList());
  }
}

// Widget usage
class ChatWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveStreamBuilder<ReactiveNotifier<Stream<List<Message>>>, List<Message>>(
      notifier: ChatService.messages,
      onEmpty: () => const Center(
        child: Text('No messages yet'),
      ),
      onLoading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      onError: (error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red),
            Text('Connection error: $error'),
          ],
        ),
      ),
      onDone: () => const Center(
        child: Text('Chat ended'),
      ),
      onData: (messages, notifier, keep) {
        return Column(
          children: [
            keep(const ChatHeader()), // Never rebuilds
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(message: messages[index]);
                },
              ),
            ),
            keep(const MessageInput()), // Never rebuilds
          ],
        );
      },
    );
  }
}
```

### Automatic Stream Management

`ReactiveStreamBuilder` automatically:
1. Subscribes to the stream on `initState`
2. Handles stream state transitions (loading, data, error, done)
3. Resubscribes when the stream changes via the notifier
4. Cancels subscription on dispose
5. Handles auto-dispose if configured on the notifier

---

## ReactiveFutureBuilder

`ReactiveFutureBuilder<T>` combines Future handling with reactive state management to avoid UI flickering and enable state sharing.

### Purpose and When to Use

- **One-time async operations** with reactive updates
- **Navigation with preloaded data** (avoid flickering)
- **Sharing Future results** with other widgets via `ReactiveNotifier`
- **Simple async loading** without full AsyncViewModel

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `future` | `Future<T>` | Yes | The Future to execute |
| `onData` | `Widget Function(T, Widget Function(Widget))` | No* | Builder for success (recommended) |
| `onSuccess` | `Widget Function(T)` | No* | **Deprecated** - use `onData` |
| `onLoading` | `Widget Function()` | No | Builder for loading state |
| `onError` | `Widget Function(Object?, StackTrace?)` | No | Builder for error state |
| `onInitial` | `Widget Function()` | No | Builder for initial state |
| `defaultData` | `T?` | No | Immediate data to show (prevents flickering) |
| `createStateNotifier` | `ReactiveNotifier<T>?` | No | Notifier to update with results |
| `notifyChangesFromNewState` | `bool` | No | Whether to notify on state updates (default: false) |

### onData Callback Signature

```dart
Widget Function(
  T data,                            // The resolved data
  Widget Function(Widget child) keep // Widget preservation function
)
```

### Usage Example

```dart
// Service definition
mixin OrderService {
  static final ReactiveNotifier<OrderItem?> currentOrderItem =
    ReactiveNotifier<OrderItem?>(() => null);

  static final orderRepository = OrderRepository();

  static Future<OrderItem?> loadById(String orderId) {
    return orderRepository.fetchOrder(orderId);
  }

  static OrderItem? getByPid(String orderId) {
    // Return cached order if available
    return _orderCache[orderId];
  }
}

// Widget usage - with default data to prevent flickering
class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ReactiveFutureBuilder<OrderItem?>(
      future: OrderService.loadById(orderId),
      // Show cached data immediately while loading fresh data
      defaultData: OrderService.getByPid(orderId),
      // Update this notifier with the result
      createStateNotifier: OrderService.currentOrderItem,
      notifyChangesFromNewState: true, // Notify other listeners
      onInitial: () => const Center(
        child: Text('Preparing order details...'),
      ),
      onLoading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      onError: (error, stackTrace) => Center(
        child: Text('Failed to load order: $error'),
      ),
      onData: (order, keep) {
        if (order == null) {
          return const Center(child: Text('Order not found'));
        }
        return Column(
          children: [
            keep(const OrderHeader()),
            Expanded(
              child: OrderDetailView(order: order),
            ),
          ],
        );
      },
    );
  }
}
```

### Key Features

1. **Flicker Prevention**: Use `defaultData` to show cached/previous data immediately
2. **State Sharing**: Use `createStateNotifier` to share results with other widgets
3. **Silent Updates**: Set `notifyChangesFromNewState: false` to update without triggering rebuilds
4. **Cleanup**: Automatically cleans up the `createStateNotifier` on dispose

---

## The keep() Function

The `keep()` function is a performance optimization tool provided by all builder widgets. It prevents unnecessary widget rebuilds by maintaining widget identity across state changes.

### What It Does

When state changes trigger a rebuild, widgets wrapped with `keep()`:
1. Are **not reconstructed** - the same widget instance is reused
2. Do **not go through their build method** again
3. Maintain their **internal state** (if StatefulWidget)

### How It Works

Under the hood, `keep()` uses a `HashMap` to cache widgets by their key. When you wrap a widget:

```dart
keep(ExpensiveWidget())
```

The builder:
1. Generates a key based on the widget's key or hash code
2. Checks if a cached version exists
3. Returns the cached version if it exists, or caches the new widget

### When to Use keep()

**Use `keep()` for:**

- **Expensive widgets** that are computationally heavy to build
- **Static content** that never changes based on state
- **Nested reactive builders** that manage their own state
- **Complex layouts** that don't depend on the parent state
- **Images or media** that should not flicker on rebuild

**Do NOT use `keep()` for:**

- Widgets that **depend on the current state**
- Widgets that need to **reflect state changes**
- Simple, cheap widgets (overhead may exceed benefit)

### Usage Examples

#### Basic Usage

```dart
ReactiveBuilder<int>(
  notifier: CounterService.count,
  build: (count, notifier, keep) {
    return Column(
      children: [
        Text('Count: $count'),          // Rebuilds - depends on count
        keep(const ExpensiveChart()),   // Never rebuilds
        keep(const StaticFooter()),     // Never rebuilds
      ],
    );
  },
)
```

#### With Nested Builders

```dart
ReactiveBuilder<UserModel>(
  notifier: UserService.user,
  build: (user, notifier, keep) {
    return Column(
      children: [
        Text('Hello, ${user.name}'),    // Rebuilds with user changes
        // This nested builder manages its own state
        keep(
          ReactiveBuilder<CartModel>(
            notifier: CartService.cart,
            build: (cart, cartNotifier, cartKeep) {
              return Text('Cart items: ${cart.items.length}');
            },
          ),
        ),
      ],
    );
  },
)
```

#### With Keys for Dynamic Content

```dart
ReactiveBuilder<List<Product>>(
  notifier: ProductService.products,
  build: (products, notifier, keep) {
    return Column(
      children: [
        keep(const PageHeader()),
        ...products.map((product) =>
          keep(ProductCard(key: ValueKey(product.id), product: product))
        ),
      ],
    );
  },
)
```

### Important Notes

1. **Key Importance**: Widgets with the same key are considered identical. Use explicit `Key` for lists.
2. **Cache Clearing**: The cache is cleared when the builder widget disposes.
3. **Memory**: Cached widgets stay in memory until the builder disposes.
4. **Safety**: If a kept widget's key changes, it will rebuild (logged as warning).

### Performance Comparison

```dart
// WITHOUT keep() - ExpensiveWidget rebuilds every time count changes
ReactiveBuilder<int>(
  notifier: CounterService.count,
  build: (count, notifier, keep) {
    return Column(
      children: [
        Text('$count'),
        ExpensiveWidget(), // Rebuilds on every state change
      ],
    );
  },
)

// WITH keep() - ExpensiveWidget builds only once
ReactiveBuilder<int>(
  notifier: CounterService.count,
  build: (count, notifier, keep) {
    return Column(
      children: [
        Text('$count'),
        keep(ExpensiveWidget()), // Builds only once, cached thereafter
      ],
    );
  },
)
```

---

## Summary

| Builder | State Type | Primary Use Case | Key Callback |
|---------|------------|------------------|--------------|
| `ReactiveBuilder<T>` | Simple values | Primitives, settings | `build(state, notifier, keep)` |
| `ReactiveViewModelBuilder<VM, T>` | ViewModel | Business logic | `build(state, viewmodel, keep)` |
| `ReactiveAsyncBuilder<VM, T>` | Async states | API/database | `onData(data, viewModel, keep)` |
| `ReactiveStreamBuilder<VM, T>` | Streams | Real-time data | `onData(data, viewmodel, keep)` |
| `ReactiveFutureBuilder<T>` | Future | One-time async | `onData(data, keep)` |

All builders support the `keep()` function for performance optimization and automatic context registration for ViewModels.
