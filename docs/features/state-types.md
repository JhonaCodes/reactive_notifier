# State Types: AsyncState<T> and StreamState<T>

ReactiveNotifier provides two specialized state types for handling asynchronous operations: `AsyncState<T>` for Future-based operations and `StreamState<T>` for Stream-based operations. Both provide type-safe, pattern-matching friendly state management.

---

## AsyncState<T>

### Overview

`AsyncState<T>` is a state container designed for managing the lifecycle of asynchronous operations. It encapsulates five distinct states that an async operation can be in: initial, loading, success, empty, and error. This eliminates the need for multiple boolean flags and provides a single source of truth for async operation status.

`AsyncState<T>` is the primary state type used with `AsyncViewModelImpl<T>` and provides:

- **Type Safety**: Generic type parameter ensures data type consistency
- **Exhaustive State Handling**: All possible states are explicitly defined
- **Pattern Matching**: Two methods (`match` and `when`) for handling state transitions
- **Error Information**: Captures both error object and stack trace for debugging

### AsyncStatus Enum

The `AsyncStatus` enum defines all possible states:

```dart
enum AsyncStatus {
  initial,  // Operation has not started
  loading,  // Operation is in progress
  success,  // Operation completed with data
  error,    // Operation failed with an error
  empty     // Operation completed but returned no data
}
```

| Status | Description | Use Case |
|--------|-------------|----------|
| `initial` | Default state before any operation | ViewModel just created, no fetch attempted |
| `loading` | Async operation in progress | API call executing, showing spinner |
| `success` | Operation completed with data | Data loaded successfully |
| `empty` | Operation completed with no data | Query returned zero results |
| `error` | Operation failed | Network error, parsing error, etc. |

### Factory Constructors

#### AsyncState.initial()

Creates a state representing an unstarted operation.

```dart
final state = AsyncState<List<User>>.initial();
// status: AsyncStatus.initial
// data: null
// error: null
// stackTrace: null
```

#### AsyncState.loading()

Creates a state representing an in-progress operation.

```dart
final state = AsyncState<List<User>>.loading();
// status: AsyncStatus.loading
// data: null
// error: null
// stackTrace: null
```

#### AsyncState.success(T data)

Creates a state representing a successful operation with data.

```dart
final users = [User('Alice'), User('Bob')];
final state = AsyncState<List<User>>.success(users);
// status: AsyncStatus.success
// data: [User('Alice'), User('Bob')]
// error: null
// stackTrace: null
```

#### AsyncState.empty()

Creates a state representing a completed operation with no data.

```dart
final state = AsyncState<List<User>>.empty();
// status: AsyncStatus.empty
// data: null
// error: null
// stackTrace: null
```

#### AsyncState.error(Object error, [StackTrace? stackTrace])

Creates a state representing a failed operation.

```dart
try {
  await fetchData();
} catch (e, stackTrace) {
  final state = AsyncState<List<User>>.error(e, stackTrace);
  // status: AsyncStatus.error
  // data: null
  // error: Exception object
  // stackTrace: StackTrace object
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `status` | `AsyncStatus` | Current status of the async operation |
| `data` | `T?` | The data when status is `success`, otherwise `null` |
| `error` | `Object?` | The error object when status is `error`, otherwise `null` |
| `stackTrace` | `StackTrace?` | Stack trace when status is `error`, otherwise `null` |

### Boolean Getters

Convenience getters for checking the current state:

```dart
final state = AsyncState<User>.loading();

state.isInitial  // false - true when status == AsyncStatus.initial
state.isLoading  // true  - true when status == AsyncStatus.loading
state.isSuccess  // false - true when status == AsyncStatus.success
state.isError    // false - true when status == AsyncStatus.error
state.isEmpty    // false - true when status == AsyncStatus.empty
```

**Usage Example:**

```dart
class UserViewModel extends AsyncViewModelImpl<User> {
  void showStatus() {
    if (state.isLoading) {
      print('Loading user data...');
    } else if (state.isSuccess) {
      print('User loaded: ${state.data!.name}');
    } else if (state.isError) {
      print('Error: ${state.error}');
    }
  }
}
```

### Pattern Matching Methods

AsyncState provides two pattern matching methods: `match` and `when`. Understanding the difference is crucial for correct usage.

#### match<R>() - Exhaustive Pattern Matching

The `match` method requires handlers for ALL five states. This is the recommended approach when you need to handle the `empty` state differently from other states.

```dart
R match<R>({
  required R Function() initial,
  required R Function() loading,
  required R Function(T data) success,
  required R Function() empty,
  required R Function(Object? err, StackTrace? stackTrace) error,
})
```

**Example:**

```dart
Widget buildContent(AsyncState<List<Product>> state) {
  return state.match(
    initial: () => const Text('Press button to load'),
    loading: () => const CircularProgressIndicator(),
    success: (products) => ProductList(products: products),
    empty: () => const Text('No products found'),
    error: (err, stack) => ErrorWidget(message: err.toString()),
  );
}
```

#### when<R>() - Simplified Pattern Matching

The `when` method requires handlers for only four states. The `empty` state falls through to the `error` handler. Use this when empty results should be treated as an error condition, or when you do not need to distinguish between empty and error states.

```dart
R when<R>({
  required R Function() initial,
  required R Function() loading,
  required R Function(T data) success,
  required R Function(Object? err, StackTrace? stackTrace) error,
})
```

**Important:** When the status is `empty`, the `error` callback is invoked with `error: null` and `stackTrace: null`.

**Example:**

```dart
Widget buildContent(AsyncState<List<Product>> state) {
  return state.when(
    initial: () => const Text('Press button to load'),
    loading: () => const CircularProgressIndicator(),
    success: (products) => ProductList(products: products),
    error: (err, stack) {
      // This handles both error AND empty states
      if (err == null) {
        return const Text('No products available');
      }
      return ErrorWidget(message: err.toString());
    },
  );
}
```

#### match vs when - Comparison

| Aspect | `match` | `when` |
|--------|---------|--------|
| Handlers required | 5 (all states) | 4 (empty falls to error) |
| Empty state handling | Explicit `empty` callback | Falls through to `error` with null error |
| Use case | Distinct empty state UI needed | Empty treated as error/edge case |
| Type safety | Fully exhaustive | Partially exhaustive |

**When to use `match`:**
- You need different UI for empty vs error states
- Empty results have business significance
- You want fully exhaustive pattern matching

**When to use `when`:**
- Empty results should show an error-like state
- You want simpler code with fewer callbacks
- The distinction between empty and error is not important

### Complete Usage Examples

#### Example 1: Basic AsyncViewModel with AsyncState

```dart
class ProductViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductViewModel() : super(AsyncState.initial(), loadOnInit: true);

  final ProductRepository _repository = ProductRepository();

  @override
  Future<List<Product>> init() async {
    return await _repository.fetchProducts();
  }

  Future<void> refreshProducts() async {
    loadingState(); // Sets state to AsyncState.loading()

    try {
      final products = await _repository.fetchProducts();
      if (products.isEmpty) {
        updateState(AsyncState.empty());
      } else {
        updateState(products); // Automatically wraps in AsyncState.success()
      }
    } catch (e, stack) {
      errorState(e.toString()); // Sets state to AsyncState.error()
    }
  }
}
```

#### Example 2: Using AsyncState in UI with ReactiveAsyncBuilder

```dart
class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<ProductViewModel, List<Product>>(
      notifier: ProductService.products.notifier,
      onData: (products, viewModel, keep) {
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) => ProductTile(products[index]),
        );
      },
      onLoading: () => const Center(child: CircularProgressIndicator()),
      onError: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () => ProductService.products.notifier.reload(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      onEmpty: () => const Center(child: Text('No products available')),
    );
  }
}
```

#### Example 3: Manual State Checking

```dart
class OrderViewModel extends AsyncViewModelImpl<Order> {
  Future<void> submitOrder(OrderRequest request) async {
    // Show loading
    transformState((_) => AsyncState.loading());

    try {
      final order = await _orderRepository.createOrder(request);
      transformState((_) => AsyncState.success(order));

      // Perform post-success actions
      if (state.isSuccess) {
        _analyticsService.trackOrderCreated(state.data!.id);
      }
    } catch (e, stack) {
      transformState((_) => AsyncState.error(e, stack));

      // Log error with full stack trace
      if (state.isError) {
        _logger.error('Order failed', state.error, state.stackTrace);
      }
    }
  }
}
```

#### Example 4: State Transformation with Data

```dart
class CartViewModel extends AsyncViewModelImpl<Cart> {
  void addItem(Product product) {
    if (state.isSuccess && state.data != null) {
      // Transform only the data portion of the state
      transformDataState((cart) {
        return cart.copyWith(
          items: [...cart.items, CartItem(product: product, quantity: 1)],
        );
      });
    }
  }

  void removeItem(String productId) {
    transformDataState((cart) {
      return cart.copyWith(
        items: cart.items.where((item) => item.product.id != productId).toList(),
      );
    });
  }
}
```

---

## StreamState<T>

### Overview

`StreamState<T>` is a sealed class hierarchy designed for managing Stream-based data flows. It represents the complete lifecycle of a stream: initial state, loading, receiving data, errors, and completion.

Unlike `AsyncState<T>` which uses an enum for status, `StreamState<T>` uses Dart's sealed class pattern, providing compile-time exhaustiveness checking through the type system.

Key characteristics:

- **Sealed Class**: Compiler-enforced exhaustive pattern matching
- **Immutable**: All state instances are const constructible
- **Stream Lifecycle**: Includes a `done` state for stream completion
- **Type Safe**: Generic type parameter for data type safety

### Factory Constructors

All constructors are const-enabled for optimal performance:

#### StreamState.initial()

Creates the initial state before stream subscription.

```dart
const state = StreamState<int>.initial();
```

#### StreamState.loading()

Creates a loading state while waiting for first data.

```dart
const state = StreamState<int>.loading();
```

#### StreamState.data(T data)

Creates a state containing stream data.

```dart
final state = StreamState<int>.data(42);
```

#### StreamState.error(Object error)

Creates an error state when the stream emits an error.

```dart
final state = StreamState<int>.error(Exception('Connection lost'));
```

#### StreamState.done()

Creates a completion state when the stream closes.

```dart
const state = StreamState<int>.done();
```

### State Lifecycle

```
initial -> loading -> data* -> done
                   \-> error -> done

* data can emit multiple times
```

### Pattern Matching with when()

`StreamState<T>` provides a single `when` method that requires handlers for all five states. Because `StreamState` is a sealed class, Dart ensures exhaustiveness at compile time.

```dart
R when<R>({
  required R Function() initial,
  required R Function() loading,
  required R Function(T data) data,
  required R Function(Object error) error,
  required R Function() done,
})
```

**Example:**

```dart
Widget buildStreamContent(StreamState<Message> state) {
  return state.when(
    initial: () => const Text('Connecting...'),
    loading: () => const CircularProgressIndicator(),
    data: (message) => MessageBubble(message: message),
    error: (error) => Text('Error: $error'),
    done: () => const Text('Connection closed'),
  );
}
```

### Usage Examples

#### Example 1: Real-time Chat Messages

```dart
class ChatViewModel extends ChangeNotifier {
  StreamState<Message> _messageState = const StreamState.initial();
  StreamSubscription<Message>? _subscription;

  StreamState<Message> get messageState => _messageState;

  void connectToChat(String roomId) {
    _messageState = const StreamState.loading();
    notifyListeners();

    _subscription = _chatService.messageStream(roomId).listen(
      (message) {
        _messageState = StreamState.data(message);
        notifyListeners();
      },
      onError: (error) {
        _messageState = StreamState.error(error);
        notifyListeners();
      },
      onDone: () {
        _messageState = const StreamState.done();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

#### Example 2: Location Tracking

```dart
class LocationViewModel extends ChangeNotifier {
  StreamState<Position> _locationState = const StreamState.initial();

  StreamState<Position> get locationState => _locationState;

  void startTracking() {
    _locationState = const StreamState.loading();
    notifyListeners();

    _locationService.positionStream.listen(
      (position) {
        _locationState = StreamState.data(position);
        notifyListeners();
      },
      onError: (error) {
        _locationState = StreamState.error(error);
        notifyListeners();
      },
    );
  }

  Widget buildLocationUI() {
    return _locationState.when(
      initial: () => ElevatedButton(
        onPressed: startTracking,
        child: const Text('Start Tracking'),
      ),
      loading: () => const Column(
        children: [
          CircularProgressIndicator(),
          Text('Acquiring GPS signal...'),
        ],
      ),
      data: (position) => Text(
        'Lat: ${position.latitude}, Lng: ${position.longitude}',
      ),
      error: (error) => Text('GPS Error: $error'),
      done: () => const Text('Tracking stopped'),
    );
  }
}
```

#### Example 3: WebSocket Connection Status

```dart
class WebSocketViewModel extends ChangeNotifier {
  StreamState<ConnectionStatus> _connectionState = const StreamState.initial();

  StreamState<ConnectionStatus> get connectionState => _connectionState;

  void connect(String url) {
    _connectionState = const StreamState.loading();
    notifyListeners();

    _webSocketService.connect(url).listen(
      (status) {
        _connectionState = StreamState.data(status);
        notifyListeners();
      },
      onError: (e) {
        _connectionState = StreamState.error(e);
        notifyListeners();
      },
      onDone: () {
        _connectionState = const StreamState.done();
        notifyListeners();
      },
    );
  }

  Color getStatusColor() {
    return _connectionState.when(
      initial: () => Colors.grey,
      loading: () => Colors.yellow,
      data: (status) => status.isConnected ? Colors.green : Colors.orange,
      error: (_) => Colors.red,
      done: () => Colors.grey,
    );
  }
}
```

---

## Comparison: AsyncState vs StreamState

| Feature | AsyncState<T> | StreamState<T> |
|---------|---------------|----------------|
| Implementation | Class with enum status | Sealed class hierarchy |
| States | initial, loading, success, empty, error | initial, loading, data, error, done |
| Data emissions | Single (Future) | Multiple (Stream) |
| Empty state | Explicit `empty` status | No separate empty state |
| Done/Complete | No (Future completes implicitly) | Yes, explicit `done` state |
| Pattern methods | `match()` and `when()` | `when()` only |
| Stack trace | Captured in error state | Not captured |
| Const constructible | Partially (factories) | Fully const enabled |

### When to Use Each

**Use AsyncState<T> when:**
- Working with `AsyncViewModelImpl<T>`
- Handling single async operations (API calls, database queries)
- You need to distinguish between "no data" (empty) and "has data" (success)
- You need stack trace information for error debugging

**Use StreamState<T> when:**
- Working with continuous data streams
- Handling real-time updates (WebSocket, Firebase, sensors)
- You need to know when the stream completes (done state)
- Building reactive UIs that respond to stream events

---

## Best Practices

### 1. Always Use Pattern Matching for UI

```dart
// Preferred - exhaustive and type-safe
state.match(
  initial: () => InitialWidget(),
  loading: () => LoadingWidget(),
  success: (data) => DataWidget(data),
  empty: () => EmptyWidget(),
  error: (e, s) => ErrorWidget(e),
)

// Avoid - not exhaustive, easy to miss states
if (state.isLoading) {
  return LoadingWidget();
} else if (state.isSuccess) {
  return DataWidget(state.data!);
}
// What about initial, empty, error?
```

### 2. Use Appropriate State Transitions

```dart
class DataViewModel extends AsyncViewModelImpl<Data> {
  Future<void> fetchData() async {
    loadingState(); // Always show loading before async operation

    try {
      final result = await _repository.fetch();
      if (result.isEmpty) {
        updateState(AsyncState.empty()); // Use empty for no-data scenarios
      } else {
        updateState(result); // Success with data
      }
    } catch (e, stack) {
      errorState(e.toString()); // Capture errors properly
    }
  }
}
```

### 3. Preserve Stack Traces

```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  // Always pass stack trace for debugging
  transformState((_) => AsyncState.error(e, stackTrace));
}
```

### 4. Handle Stream Completion

```dart
_stream.listen(
  (data) => _state = StreamState.data(data),
  onError: (e) => _state = StreamState.error(e),
  onDone: () => _state = const StreamState.done(), // Do not forget completion
);
```
