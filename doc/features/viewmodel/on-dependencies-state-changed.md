# onDependenciesStateChanged

Lifecycle hook for declaring and reacting to external state dependencies with automatic batching.

## Overview

`onDependenciesStateChanged` allows a ViewModel to declare which external `ReactiveNotifier` instances it depends on and react to their changes. It runs in two phases:

1. **Setup phase** (before `init()`): Registers dependencies, takes initial snapshots, and calls each callback with `(current, current)`.
2. **Reaction phase** (after a dependency fires): Only calls callbacks for dependencies that actually changed, providing `(previous, current)`. Multiple changes are batched into a single `notifyListeners()`.

## API

```dart
@protected
void onDependenciesStateChanged(DependencyState change)
```

### DependencyState.on\<T\>()

```dart
void on<T>(ReactiveNotifier notifier, void Function(T previous, T current) callback)
```

- During **setup**: Registers the dependency, snapshots its value, calls `callback(current, current)`.
- During **reaction**: Only calls callback if this specific notifier changed. Provides `(previous, current)`.

### DependencyState.isSetup

```dart
bool get isSetup
```

Returns `true` during the setup phase, `false` during reaction.

## Type Extraction

`on<T>()` automatically extracts the correct typed value:

| Notifier Type | Extracted Value |
|---------------|----------------|
| `ReactiveNotifier<int>` | `int` directly |
| `ReactiveNotifier<ViewModel<T>>` | `T` via `.data` |
| `ReactiveNotifier<AsyncViewModelImpl<T>>` | `T?` via `.data` |

## Usage with ViewModel

```dart
class NotificationViewModel extends ViewModel<NotificationModel> {
  NotificationViewModel() : super(NotificationModel.empty());

  @override
  void onDependenciesStateChanged(DependencyState change) {
    change.on<UserModel>(UserService.userState, (previous, current) {
      if (previous.id != current.id) {
        // User changed — reload notifications for new user
        _loadNotificationsForUser(current.id);
      }
    });

    change.on<SettingsModel>(SettingsService.settings, (previous, current) {
      if (previous.notificationsEnabled != current.notificationsEnabled) {
        updateState(data.copyWith(enabled: current.notificationsEnabled));
      }
    });
  }

  @override
  void init() {
    // Dependencies are already available here
    final user = UserService.userState();
    updateSilently(NotificationModel(userId: user.id));
  }
}
```

## Usage with AsyncViewModelImpl

```dart
class OrdersViewModel extends AsyncViewModelImpl<List<Order>> {
  OrdersViewModel() : super(AsyncState.initial());

  @override
  void onDependenciesStateChanged(DependencyState change) {
    change.on<UserModel>(UserService.userState, (previous, current) {
      if (!change.isSetup && previous.id != current.id) {
        reload(); // Re-fetch orders for new user
      }
    });
  }

  @override
  Future<List<Order>> init() async {
    final userId = UserService.userState().id;
    return await OrderRepository.getOrders(userId);
  }
}
```

## Lifecycle

```
Constructor
    |
    v
_setupDependencies()  <-- calls onDependenciesStateChanged(setup)
    |                      Registers deps, takes snapshots, calls callbacks with (current, current)
    v
init()                <-- dependencies guaranteed available
    |
    v
setupListeners()
    |
    v
onResume()
    |
    v
[Running — dependency changes trigger reaction phase]
    |
    v
dispose()             <-- all dependency listeners cleaned up
```

## Batching

When multiple dependencies change synchronously, their reactions are batched into a single microtask:

```dart
// Both change synchronously
UserService.userState.updateState(newUser);
SettingsService.settings.updateState(newSettings);

// Result: ONE notifyListeners() call, not two
// Both reaction callbacks execute, then a single rebuild
```

This prevents unnecessary intermediate rebuilds.

## Comparison with listenVM

| Feature | onDependenciesStateChanged | listenVM |
|---------|---------------------------|----------|
| **Phase** | Runs before `init()` | Called manually in `init()` |
| **Batching** | Automatic microtask batching | No batching |
| **Previous value** | Typed `(previous, current)` | Only current value |
| **Cleanup** | Automatic on dispose | Manual or via stopListeningVM |
| **Use case** | Declarative dependency tracking | Imperative reactive communication |

### When to use which

- **onDependenciesStateChanged**: When you need typed previous/current values, automatic batching, or want dependencies set up before `init()`.
- **listenVM**: When you need imperative control, or want to set up listeners dynamically during runtime.
