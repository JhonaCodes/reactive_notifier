# AsyncViewModelImpl Properties

This document covers the async-specific properties unique to `AsyncViewModelImpl` that provide convenient access to the current `AsyncState<T>` information.

## isLoading

### Signature

```dart
bool get isLoading
```

### Purpose

Returns `true` if the current async state is in the loading phase. Use this to display loading indicators or disable user interactions during data fetching.

### Return Type

`bool`

### Usage Example

```dart
class ProductViewModel extends AsyncViewModelImpl<List<Product>> {
  ProductViewModel() : super(AsyncState.initial());

  @override
  Future<List<Product>> init() async {
    return await productRepository.fetchAll();
  }

  Future<void> refreshProducts() async {
    if (isLoading) {
      // Prevent duplicate requests
      return;
    }
    await reload();
  }
}

// In widget
if (viewModel.isLoading) {
  return CircularProgressIndicator();
}
```

---

## hasData

### Signature

```dart
bool get hasData
```

### Purpose

Returns `true` if the current state is a success state containing valid data. This indicates that `data` can be safely accessed.

### Return Type

`bool`

### Usage Example

```dart
class UserViewModel extends AsyncViewModelImpl<User> {
  Future<void> updateEmail(String newEmail) async {
    if (!hasData) {
      // Cannot update - no user data loaded
      return;
    }

    final currentUser = data!;
    final updatedUser = currentUser.copyWith(email: newEmail);
    updateState(updatedUser);
  }
}

// Safe data access pattern
if (viewModel.hasData) {
  final user = viewModel.data!;
  displayUserProfile(user);
} else {
  displayPlaceholder();
}
```

---

## error

### Signature

```dart
Object? get error
```

### Purpose

Returns the error object if the current state is an error state, otherwise returns `null`. Use this to display error messages or determine the type of error that occurred.

### Return Type

`Object?` - The error object or `null` if not in error state.

### Usage Example

```dart
class DataViewModel extends AsyncViewModelImpl<Data> {
  void handleErrorDisplay() {
    if (error != null) {
      if (error is NetworkException) {
        showNetworkError();
      } else if (error is AuthenticationException) {
        navigateToLogin();
      } else {
        showGenericError(error.toString());
      }
    }
  }
}

// In widget
if (viewModel.error != null) {
  return ErrorWidget(
    message: viewModel.error.toString(),
    onRetry: () => viewModel.reload(),
  );
}
```

---

## stackTrace

### Signature

```dart
StackTrace? get stackTrace
```

### Purpose

Returns the stack trace associated with the current error, if available. Useful for debugging and error logging.

### Return Type

`StackTrace?` - The stack trace or `null` if not in error state or no stack trace was provided.

### Usage Example

```dart
class ReportingViewModel extends AsyncViewModelImpl<Report> {
  @override
  void onAsyncStateChanged(AsyncState<Report> previous, AsyncState<Report> next) {
    if (next.isError && error != null) {
      // Log error with stack trace for debugging
      crashlytics.recordError(
        error!,
        stackTrace ?? StackTrace.current,
        reason: 'Report loading failed',
      );
    }
  }
}

// Debug error with full context
if (viewModel.error != null) {
  debugPrint('Error: ${viewModel.error}');
  if (viewModel.stackTrace != null) {
    debugPrint('Stack trace:\n${viewModel.stackTrace}');
  }
}
```

---

## data

### Signature

```dart
T? get data
```

### Purpose

Returns the current data if the state is success. **Important:** This getter throws the stored error if the current state is an error state.

### Return Type

`T?` - The data or `null` if not in success state.

### Behavior

- Returns the data value when state is `AsyncState.success(data)`
- Returns `null` when state is `initial`, `loading`, or `empty`
- **Throws** the stored error when state is `AsyncState.error`

### Usage Example

```dart
class ItemListViewModel extends AsyncViewModelImpl<List<Item>> {
  // Safe access - check hasData first
  void processItems() {
    if (hasData) {
      final items = data!;
      for (final item in items) {
        processItem(item);
      }
    }
  }

  // Alternative - handle potential null
  int get itemCount => data?.length ?? 0;

  // CAUTION: This can throw if in error state
  void riskyAccess() {
    try {
      final items = data; // Throws if error state
      if (items != null) {
        // Process items
      }
    } catch (e) {
      // Handle the error
    }
  }
}

// Recommended: Use pattern matching instead of direct data access
Widget build(BuildContext context) {
  return viewModel.match(
    initial: () => Text('Not started'),
    loading: () => CircularProgressIndicator(),
    success: (items) => ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) => ItemTile(items[i]),
    ),
    empty: () => Text('No items'),
    error: (err, stack) => ErrorDisplay(err),
  );
}
```

---

## isDisposed

### Signature

```dart
bool get isDisposed
```

### Purpose

Returns `true` if the ViewModel has been disposed. Use this to prevent operations on a disposed ViewModel, particularly in async callbacks.

### Return Type

`bool`

### Usage Example

```dart
class TimerViewModel extends AsyncViewModelImpl<TimerState> {
  Timer? _timer;

  @override
  Future<TimerState> init() async {
    _startTimer();
    return TimerState(seconds: 0);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      // Guard against disposed ViewModel
      if (isDisposed) {
        _timer?.cancel();
        return;
      }

      transformDataState((state) {
        return state?.copyWith(seconds: state.seconds + 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// In async callbacks
Future<void> fetchData() async {
  final result = await api.fetchData();

  // Check before updating state
  if (!isDisposed) {
    updateState(result);
  }
}
```

---

## Complete Example

```dart
class OrderDetailsViewModel extends AsyncViewModelImpl<Order> {
  final String orderId;
  final OrderRepository _repository;

  OrderDetailsViewModel({
    required this.orderId,
    OrderRepository? repository,
  })  : _repository = repository ?? OrderRepository(),
        super(AsyncState.initial());

  @override
  Future<Order> init() async {
    return await _repository.getOrder(orderId);
  }

  // Using all async properties together
  Widget buildStatusWidget() {
    if (isDisposed) {
      return SizedBox.shrink();
    }

    if (isLoading) {
      return LoadingIndicator(message: 'Loading order...');
    }

    if (error != null) {
      return ErrorDisplay(
        error: error!,
        stackTrace: stackTrace,
        onRetry: reload,
      );
    }

    if (hasData) {
      return OrderDisplay(order: data!);
    }

    return Text('No order data');
  }

  Future<void> cancelOrder() async {
    if (!hasData) {
      throw StateError('Cannot cancel: no order loaded');
    }

    if (isLoading) {
      throw StateError('Cannot cancel: operation in progress');
    }

    final order = data!;
    if (order.status == OrderStatus.shipped) {
      errorState(
        BusinessException('Cannot cancel shipped orders'),
        StackTrace.current,
      );
      return;
    }

    loadingState();
    try {
      final cancelledOrder = await _repository.cancelOrder(orderId);
      updateState(cancelledOrder);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}
```

## Best Practices

### 1. Always Guard Async Operations with isDisposed

```dart
Future<void> delayedOperation() async {
  await Future.delayed(Duration(seconds: 2));

  if (isDisposed) return; // Guard after await

  updateState(newData);
}
```

### 2. Prefer hasData Over Null Checks

```dart
// RECOMMENDED
if (hasData) {
  final value = data!;
}

// AVOID - data throws on error state
if (data != null) {
  // May throw if error state
}
```

### 3. Use Properties for UI Logic, Pattern Matching for Widgets

```dart
// Properties for quick checks
bool get canSubmit => hasData && !isLoading;

// Pattern matching for comprehensive widget building
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

### 4. Log Errors with Stack Traces

```dart
@override
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
  if (next.isError && error != null) {
    logger.error(
      'ViewModel error',
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }
}
```
