# activeListenerCount Getter

## Signature

```dart
int get activeListenerCount
```

## Type

`int` - Returns the number of currently active listeners registered via `listenVM()`.

## Description

The `activeListenerCount` getter provides the count of listeners that have been registered through the `listenVM()` method. This is useful for debugging, monitoring, and ensuring proper cleanup of listener connections between ViewModels.

### Source Implementation

```dart
/// Holds the currently active listener callbacks.
final Map<String, VoidCallback> _listeners = {};

/// Get current listener count for debugging
int get activeListenerCount => _listeners.length;
```

Note: This count specifically tracks listeners added via `listenVM()`, not all Flutter `ChangeNotifier` listeners.

## Usage Example

```dart
class DashboardViewModel extends ViewModel<DashboardModel> {
  DashboardViewModel() : super(DashboardModel.empty());

  @override
  void init() {
    // Set up reactive listeners to other ViewModels
    UserService.userState.notifier.listenVM((user) {
      updateUserSection(user);
    });

    CartService.cartState.notifier.listenVM((cart) {
      updateCartSummary(cart);
    });

    OrderService.orderState.notifier.listenVM((orders) {
      updateOrderHistory(orders);
    });

    // Debug: verify listeners are registered
    assert(() {
      print('DashboardViewModel listeners: $activeListenerCount'); // Output: 3
      return true;
    }());
  }
}

// Debugging in development
void debugViewModelState() {
  final vm = DashboardService.dashboard.notifier;
  print('Active listeners: ${vm.activeListenerCount}');
}
```

## When to Use

### Debugging Scenarios

1. **Verify listener setup**:
   ```dart
   @override
   void init() {
     // ... setup listeners ...

     assert(() {
       if (activeListenerCount != expectedCount) {
         print('Warning: Expected $expectedCount listeners, got $activeListenerCount');
       }
       return true;
     }());
   }
   ```

2. **Memory leak detection**:
   ```dart
   void checkForLeaks() {
     // If count keeps growing, listeners aren't being cleaned up
     print('Listener count: ${viewModel.activeListenerCount}');
   }
   ```

3. **Logging lifecycle events**:
   ```dart
   @override
   void dispose() {
     print('Disposing with $activeListenerCount active listeners');
     super.dispose();
   }
   ```

### Monitoring Scenarios

1. **Development tools integration**:
   ```dart
   Map<String, dynamic> getDebugInfo() {
     return {
       'type': runtimeType.toString(),
       'activeListeners': activeListenerCount,
       'isDisposed': isDisposed,
     };
   }
   ```

2. **Health checks**:
   ```dart
   bool isHealthy() {
     // A ViewModel with too many listeners might indicate a problem
     return activeListenerCount < maxExpectedListeners;
   }
   ```

## Best Practices

1. **Use for debugging only** - This is primarily a development/debugging tool

2. **Don't rely on for logic** - Avoid using this count for business logic decisions

3. **Check during dispose** - Verify listeners are cleaned up:
   ```dart
   @override
   void dispose() {
     assert(() {
       if (activeListenerCount > 0) {
         print('Warning: $activeListenerCount listeners still active at dispose');
       }
       return true;
     }());
     super.dispose();
   }
   ```

4. **Compare with expected count** - Useful for catching missing listeners:
   ```dart
   void validateSetup() {
     assert(activeListenerCount == 3,
       'Expected 3 listeners but found $activeListenerCount');
   }
   ```

## What It Tracks

| Tracked | Not Tracked |
|---------|-------------|
| `listenVM()` callbacks | Direct `addListener()` calls |
| Internal ViewModel listeners | `setupListeners()` external listeners |
| Cross-ViewModel communication | Widget-level listeners |

## Related

- [listenVM()](/doc/features/viewmodel/methods/listen-vm.md) - Register reactive listeners
- [stopListeningVM()](/doc/features/viewmodel/methods/stop-listening-vm.md) - Remove all listeners
- [stopSpecificListener()](/doc/features/viewmodel/methods/stop-specific-listener.md) - Remove specific listener
