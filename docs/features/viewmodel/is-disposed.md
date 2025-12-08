# isDisposed Getter

## Signature

```dart
bool get isDisposed
```

## Type

`bool` - Returns `true` if the ViewModel has been disposed, `false` otherwise.

## Description

The `isDisposed` getter provides a way to check whether the ViewModel has been disposed. This is useful for:

- Preventing operations on disposed ViewModels
- Conditional logic based on ViewModel lifecycle state
- Debugging and logging lifecycle events
- Safe cleanup operations in external code

### Source Implementation

```dart
bool _disposed = false;

bool get isDisposed => _disposed;
```

The internal `_disposed` flag is set to `true` during the `dispose()` method and can be reset to `false` during reinitialization.

## Usage Example

```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.empty());

  @override
  void init() {
    updateSilently(UserModel.guest());
  }

  Future<void> fetchUserData() async {
    final response = await api.getUser();

    // Check before updating after async operation
    if (!isDisposed) {
      updateState(UserModel.fromJson(response));
    }
  }
}

// External usage
void performCleanup() {
  final viewModel = UserService.userState.notifier;

  if (!viewModel.isDisposed) {
    viewModel.cleanState();
  }
}
```

## When to Use

### Essential Scenarios

1. **After async operations** - Check before updating state:
   ```dart
   Future<void> loadData() async {
     final data = await repository.fetch();
     if (!isDisposed) {
       updateState(data);
     }
   }
   ```

2. **In timers and delayed callbacks**:
   ```dart
   void startPolling() {
     Timer.periodic(Duration(seconds: 30), (timer) {
       if (isDisposed) {
         timer.cancel();
         return;
       }
       refreshData();
     });
   }
   ```

3. **Stream subscriptions**:
   ```dart
   void listenToStream() {
     stream.listen((event) {
       if (!isDisposed) {
         processEvent(event);
       }
     });
   }
   ```

4. **External cleanup logic**:
   ```dart
   void externalCleanup(ViewModel viewModel) {
     if (!viewModel.isDisposed) {
       // Safe to perform operations
     }
   }
   ```

### Not Typically Needed

- Inside synchronous ViewModel methods (state is checked automatically)
- In builders (ReactiveNotifier handles this)
- During normal `init()` execution

## Best Practices

1. **Always check after await** - Async gaps can lead to disposed state
2. **Cancel timers** - Use `isDisposed` to cancel periodic operations
3. **Guard stream handlers** - Check before processing stream events
4. **Trust auto-reinitialization** - Other getters like `data` handle this automatically
5. **Use for external code** - Most useful when accessing ViewModel from outside

## Lifecycle Context

```
Constructor -> init() -> [active state] -> dispose() -> [disposed state]
                              ^                              |
                              |______ reinitialization ______|
```

The `isDisposed` flag tracks this lifecycle and is used internally by `_checkDisposed()` to trigger automatic reinitialization when needed.

## Related

- [dispose()](/docs/features/viewmodel/methods/dispose.md) - Dispose lifecycle method
- [cleanState()](/docs/features/viewmodel/methods/clean-state.md) - Clean state without disposing
- [data](/docs/features/viewmodel/data.md) - Data getter with auto-reinitialization
