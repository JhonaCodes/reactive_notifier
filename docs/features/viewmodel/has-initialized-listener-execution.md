# hasInitializedListenerExecution Flag

## Signature

```dart
bool hasInitializedListenerExecution = false;
```

## Type

`bool` - A mutable flag that indicates whether the ViewModel's full initialization cycle has completed.

## Description

The `hasInitializedListenerExecution` flag is set to `true` only after the entire ViewModel initialization process has finished, including `init()` and initial state setup. This flag is essential for preventing duplicate data fetches when external listeners are registered.

### Source Implementation

```dart
ViewModel(this._data) {
  // ... initialization code ...

  _safeInitialization();

  // Set to true ONLY after full initialization
  hasInitializedListenerExecution = true;

  // ...
}

void _safeInitialization() {
  // Reset to false before any initialization
  hasInitializedListenerExecution = false;

  if (_initialized || _disposed) return;

  // ... init() and setup ...
}
```

## Usage Example

```dart
class OrderViewModel extends AsyncViewModelImpl<List<Order>> {
  OrderViewModel() : super(AsyncState.initial(), loadOnInit: true);

  @override
  Future<List<Order>> init() async {
    return await repository.getOrders();
  }

  // Listener function that reacts to external changes
  Future<void> _onUserChanged() async {
    // Only reload if initialization is complete
    if (hasInitializedListenerExecution) {
      await reload();
    }
  }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    UserService.userState.notifier.addListener(_onUserChanged);
    await super.setupListeners(currentListeners: ['_onUserChanged']);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    UserService.userState.notifier.removeListener(_onUserChanged);
    await super.removeListeners(currentListeners: ['_onUserChanged']);
  }
}
```

## When to Use

### Primary Use Case

**Preventing duplicate initialization in listeners**:

When you register a listener via `addListener()`, Flutter immediately calls that listener. Without this guard, you would fetch data twice:
1. Once during `init()`
2. Once when the listener is first registered

```dart
// WITHOUT guard - causes duplicate fetch
Future<void> _onExternalChange() async {
  await reloadData(); // Called during setupListeners AND init!
}

// WITH guard - proper behavior
Future<void> _onExternalChange() async {
  if (hasInitializedListenerExecution) {
    await reloadData(); // Only called for actual changes
  }
}
```

### Common Scenarios

1. **External service listeners**:
   ```dart
   void _onAuthChanged() {
     if (hasInitializedListenerExecution) {
       refreshForCurrentUser();
     }
   }
   ```

2. **Cross-ViewModel communication**:
   ```dart
   void _onCartUpdated() {
     if (hasInitializedListenerExecution) {
       recalculateTotals();
     }
   }
   ```

3. **Stream-based updates**:
   ```dart
   void _onStreamEvent(Event event) {
     if (hasInitializedListenerExecution) {
       processEvent(event);
     }
   }
   ```

## Best Practices

1. **Always use in `setupListeners` callbacks** - Guard all listener functions that perform data operations

2. **Do not use with `listenVM`** - The `listenVM` method has its own `callOnInit` parameter for this purpose:
   ```dart
   // listenVM handles this internally
   OtherService.state.notifier.listenVM(
     (data) => handleChange(data),
     callOnInit: false, // Don't call on registration
   );
   ```

3. **Check before async operations** - Prevents unnecessary network calls:
   ```dart
   Future<void> _externalListener() async {
     if (hasInitializedListenerExecution) {
       // Safe to make API calls
       await fetchUpdatedData();
     }
   }
   ```

4. **Never set manually** - This flag is managed by the ViewModel lifecycle

## Timeline

```
Constructor starts
    |
    v
hasInitializedListenerExecution = false (in _safeInitialization)
    |
    v
init() executes
    |
    v
setupListeners() called (listeners registered, may fire)
    |
    v
hasInitializedListenerExecution = true (safe for listener operations)
    |
    v
[Normal operation - listeners react to real changes]
```

## Related

- [setupListeners()](/docs/features/viewmodel/methods/setup-listeners.md) - Register external listeners
- [removeListeners()](/docs/features/viewmodel/methods/remove-listeners.md) - Cleanup listeners
- [listenVM()](/docs/features/viewmodel/methods/listen-vm.md) - Built-in listener with init control
