# updateSilently()

Updates the ViewModel state without notifying listeners.

## Method Signature

```dart
void updateSilently(T newState)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `newState` | `T` | The new state value to replace the current state |

## Purpose

`updateSilently()` updates the internal state without triggering UI rebuilds. This is essential for background operations, batch updates, or initialization scenarios where you need to set state without immediate visual feedback.

## When to Use

Use `updateSilently()` when:

- Setting initial state in `init()` method
- Performing background data synchronization
- Batching multiple updates before a single notification
- Caching data that does not require immediate display
- Pre-loading data before user navigation

Use alternatives when:

- **`updateState()`**: User should see the change immediately
- **`transformState()`**: Need to modify based on current state with notification
- **`transformStateSilently()`**: Need to modify based on current state silently

## Triggers onStateChanged?

**Yes** - The `onStateChanged(previous, next)` hook is still called, allowing internal reactions to state changes even without UI notification.

## Usage Example

```dart
class CacheViewModel extends ViewModel<CacheModel> {
  CacheViewModel() : super(CacheModel.empty());

  @override
  void init() {
    // Silent initialization - no UI exists yet
    final cached = loadFromLocalStorage();
    updateSilently(cached);
  }

  // Background sync without UI interruption
  Future<void> syncInBackground() async {
    final serverData = await api.fetchLatestData();
    updateSilently(CacheModel(
      data: serverData,
      lastSync: DateTime.now(),
    ));
  }

  // Batch updates - single notification at end
  void batchUpdateItems(List<Item> items) {
    for (final item in items) {
      // Silent updates for each item
      updateSilently(data.copyWith(
        items: [...data.items, item],
      ));
    }
    // Single notification after all updates
    notifyListeners();
  }

  // Pre-load data before showing screen
  Future<void> preloadUserData(String userId) async {
    final userData = await repository.getUser(userId);
    updateSilently(data.copyWith(user: userData));
    // UI will show this when it mounts
  }
}
```

## Best Practices

1. **Use in init()** - Silent updates are ideal for initialization since no UI is listening yet:

```dart
@override
void init() {
  final initialData = loadInitialData();
  updateSilently(initialData); // No listeners yet
}
```

2. **Combine with explicit notifyListeners()** - For batch operations:

```dart
void processBatch(List<Item> items) {
  for (final item in items) {
    updateSilently(data.copyWith(items: [...data.items, item]));
  }
  notifyListeners(); // Single rebuild at the end
}
```

3. **Background synchronization** - Keep UI responsive during heavy operations:

```dart
Future<void> heavyBackgroundTask() async {
  // Process without blocking UI
  for (int i = 0; i < 1000; i++) {
    final result = await processItem(i);
    updateSilently(data.copyWith(processed: [...data.processed, result]));
  }
  // Notify only when complete
  updateState(data); // This triggers the rebuild
}
```

4. **Cache warming** - Load data before user needs it:

```dart
void warmCache() {
  final cachedData = prefs.getStoredData();
  if (cachedData != null) {
    updateSilently(cachedData);
  }
}
```

## Internal Behavior

When `updateSilently()` is called:

1. Checks if ViewModel is disposed (reinitializes if needed)
2. Stores the previous state
3. Assigns the new state
4. Executes `onStateChanged(previous, newState)` hook
5. Does NOT call `notifyListeners()`
6. Does NOT increment the update counter

## Important Notes

- The `onStateChanged` hook still fires, allowing internal logic to react
- Use this for performance optimization when UI updates are not needed
- Remember to call `updateState()` or `notifyListeners()` when UI should reflect changes

## Related Methods

- [`updateState()`](./update-state.md) - Update with notification
- [`transformState()`](./transform-state.md) - Transform with notification
- [`transformStateSilently()`](./transform-state-silently.md) - Transform without notification
- [`cleanState()`](./clean-state.md) - Reset to empty state
