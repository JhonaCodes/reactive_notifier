# call() Syntax — Shorthand Data Access

Dart's `call()` method enables concise data access on `ReactiveNotifier` and `ReactiveNotifierViewModel`.

## Overview

Instead of writing verbose accessor chains, use the call syntax to get data directly:

```dart
// Before
final userName = UserService.userState.notifier.data.name;

// After
final userName = UserService.userState().name;
```

## API

### ReactiveNotifier\<T\>

```dart
dynamic call()
```

Returns the unwrapped data value:

| Notifier Type | Returns |
|---------------|---------|
| `ReactiveNotifier<int>` | `int` |
| `ReactiveNotifier<String>` | `String` |
| `ReactiveNotifier<ViewModel<T>>` | `T` (ViewModel's `.data`) |
| `ReactiveNotifier<AsyncViewModelImpl<T>>` | `T?` (async data, may be null) |

### ReactiveNotifierViewModel\<VM, T\>

```dart
T call()
```

Returns `T` directly (the ViewModel's `.data`). Fully typed — no `dynamic`.

## Three Levels of Access

```dart
mixin UserService {
  static final userState = ReactiveNotifierViewModel<UserViewModel, UserModel>(
    () => UserViewModel(),
  );
}

// Level 1: Full accessor chain
final user = UserService.userState.notifier.data;

// Level 2: State shorthand
final user = UserService.userState.state;

// Level 3: Call syntax (shortest)
final user = UserService.userState();
```

## Usage in ViewModels

```dart
class DashboardViewModel extends ViewModel<DashboardModel> {
  @override
  void onDependenciesStateChanged(DependencyState change) {
    change.on<UserModel>(UserService.userState, (previous, current) {
      // Use call() for quick access to other services
      final cart = CartService.cartState();
      final settings = SettingsService.settings();

      updateState(data.copyWith(
        userName: current.name,
        cartCount: cart.items.length,
        theme: settings.theme,
      ));
    });
  }

  @override
  void init() {
    final user = UserService.userState();
    updateSilently(DashboardModel(userName: user.name));
  }
}
```

## Important: Snapshot, Not Reactive

`call()` returns a **snapshot** of the current value. It is not reactive — the returned value won't update automatically.

```dart
final user = UserService.userState(); // snapshot at this moment
// user won't change if UserService.userState updates later
```

For reactivity, use:
- **Builders** (`ReactiveBuilder`, `ReactiveViewModelBuilder`) for UI
- **`listenVM()`** for cross-ViewModel communication
- **`onDependenciesStateChanged`** for declarative dependency tracking
