# Builder Components Guide

## Current API (v2.10.5)

All builders use the `build` parameter with three arguments: `(value, notifier/viewmodel, keep)`

## ReactiveBuilder<T>

**Purpose**: Display simple state values
**Use case**: ReactiveNotifier<T> instances

```dart
ReactiveBuilder<int>(
  notifier: CounterService.count,
  build: (value, notifier, keep) {
    return Column(
      children: [
        Text('Count: $value'),
        keep(ExpensiveWidget()), // Won't rebuild
        ElevatedButton(
          onPressed: () => notifier.updateState(value + 1),
          child: Text('Increment'),
        ),
      ],
    );
  },
)
```

### Parameters:
- `notifier`: ReactiveNotifier<T> instance
- `build`: (T value, ReactiveNotifier<T> notifier, Widget Function(Widget) keep) => Widget

## ReactiveViewModelBuilder<VM, T>

**Purpose**: Display complex ViewModel state
**Use case**: ViewModel<T> instances

```dart
ReactiveViewModelBuilder<UserViewModel, UserState>(
  viewmodel: UserService.userState.notifier,
  build: (userState, userViewModel, keep) {
    return Column(
      children: [
        Text('Welcome ${userState.name}'),
        if (userState.isLoggedIn) 
          keep(ProfileWidget()), // Performance optimization
        ElevatedButton(
          onPressed: () => userViewModel.logout(),
          child: Text('Logout'),
        ),
      ],
    );
  },
)
```

### Parameters:
- `viewmodel`: ViewModel<T> instance
- `build`: (T state, VM viewmodel, Widget Function(Widget) keep) => Widget

## ReactiveAsyncBuilder<VM, T>

**Purpose**: Handle async states with loading/error handling
**Use case**: AsyncViewModelImpl<T> instances

```dart
ReactiveAsyncBuilder<ProductsViewModel, List<Product>>(
  notifier: ProductsService.productsState.notifier,
  onData: (products, viewModel, keep) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => ProductTile(products[index]),
    );
  },
  onLoading: () => Center(child: CircularProgressIndicator()),
  onError: (error, stackTrace) => ErrorWidget(error: error),
  onEmpty: () => Center(child: Text('No products available')),
)
```

### Parameters:
- `notifier`: AsyncViewModelImpl<T> instance
- `onData`: (T data, VM viewmodel, Widget Function(Widget) keep) => Widget
- `onLoading`: () => Widget (optional)
- `onError`: (Object error, StackTrace? stackTrace) => Widget (optional)
- `onEmpty`: () => Widget (optional)

## ReactiveStreamBuilder<VM, T>

**Purpose**: Handle Stream data with states
**Use case**: ReactiveNotifier<Stream<T>> instances

```dart
ReactiveStreamBuilder<ReactiveNotifier<Stream<String>>, String>(
  notifier: StreamService.dataStream,
  onData: (data, notifier, keep) {
    return Text('Latest: $data');
  },
  onLoading: () => CircularProgressIndicator(),
  onError: (error) => Text('Stream Error: $error'),
  onEmpty: () => Text('Waiting for data...'),
  onDone: () => Text('Stream completed'),
)
```

### Parameters:
- `notifier`: ReactiveNotifier<Stream<T>> instance
- `onData`: (T data, VM state, Widget Function(Widget) keep) => Widget
- `onLoading`: () => Widget (optional)
- `onError`: (Object error) => Widget (optional)
- `onEmpty`: () => Widget (optional)
- `onDone`: () => Widget (optional)

## Performance Optimization with keep()

The `keep()` function prevents unnecessary rebuilds of expensive widgets:

```dart
ReactiveBuilder<UserModel>(
  notifier: UserService.userState,
  build: (user, notifier, keep) {
    return Column(
      children: [
        Text('Hello ${user.name}'), // Rebuilds when user changes
        keep(ExpensiveChart()), // Never rebuilds
        keep(AnotherReactiveBuilder(
          notifier: OtherService.data,
          build: (data, notifier, keep) => Text('$data'),
        )), // Only rebuilds for its own state
      ],
    );
  },
)
```

### When to use keep():
- Expensive widgets (charts, complex layouts)
- Nested reactive builders
- Static content that doesn't depend on current state
- Third-party widgets with heavy initialization

## Common Patterns

### Conditional Rendering
```dart
ReactiveBuilder<AppState>(
  notifier: AppService.state,
  build: (state, notifier, keep) {
    if (state.isLoading) {
      return keep(LoadingSpinner());
    }
    
    return state.user.isLoggedIn 
      ? keep(DashboardPage())
      : keep(LoginPage());
  },
)
```

### Multiple State Dependencies
```dart
ReactiveBuilder<CombinedState>(
  notifier: AppService.combinedState, // Uses related states
  build: (combined, notifier, keep) {
    return Column(
      children: [
        Text('User: ${combined.user.name}'),
        Text('Cart: ${combined.cart.itemCount} items'),
        Text('Total: \$${combined.cart.total}'),
      ],
    );
  },
)
```

### Error Boundaries
```dart
ReactiveAsyncBuilder<DataViewModel, List<Item>>(
  notifier: DataService.items.notifier,
  onData: (items, viewModel, keep) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => ItemTile(items[index]),
    );
  },
  onLoading: () => SkeletonLoader(),
  onError: (error, stack) {
    return ErrorCard(
      message: 'Failed to load items',
      onRetry: () => viewModel.reload(),
    );
  },
)
```

## Anti-Patterns

### ❌ Old API Usage
```dart
// DON'T USE - Old API
ReactiveBuilder<int>(
  notifier: CounterService.count,
  builder: (value, keep) => Text('$value'), // Missing notifier parameter
)
```

### ❌ Business Logic in Builders
```dart
// DON'T DO - Logic belongs in ViewModel
ReactiveBuilder<UserModel>(
  notifier: UserService.user,
  build: (user, notifier, keep) {
    // Complex validation here - WRONG
    final isValid = validateEmail(user.email) && 
                   checkPermissions(user.role) &&
                   verifySubscription(user.subscription);
    
    return isValid ? Dashboard() : ErrorPage();
  },
)
```

### ❌ Not Using keep() for Performance
```dart
// DON'T DO - Expensive widget rebuilds unnecessarily
ReactiveBuilder<CounterModel>(
  notifier: CounterService.state,
  build: (counter, notifier, keep) {
    return Column(
      children: [
        Text('Count: ${counter.value}'),
        ComplexChart(data: heavyCalculation()), // Rebuilds every time
      ],
    );
  },
)

// DO THIS - Use keep() for expensive widgets
ReactiveBuilder<CounterModel>(
  notifier: CounterService.state,
  build: (counter, notifier, keep) {
    return Column(
      children: [
        Text('Count: ${counter.value}'),
        keep(ComplexChart(data: heavyCalculation())), // Cached
      ],
    );
  },
)
```