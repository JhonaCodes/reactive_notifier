# dispose() Method

## Method Signature

### ViewModel<T>
```dart
@override
void dispose();
```

### AsyncViewModelImpl<T>
```dart
@override
void dispose();
```

## Purpose

The `dispose()` method handles the complete cleanup of a ViewModel, ensuring all resources are properly released, listeners are removed, and memory leaks are prevented. It orchestrates a multi-step cleanup process that safely tears down the ViewModel's connections and state.

## Parameters

None.

## Return Type

`void`

## When It's Called

### Automatic Invocation

The `dispose()` method is called automatically when:

1. **ReactiveNotifier cleanup** - When `ReactiveNotifier.cleanup()` is called globally
2. **Auto-dispose timeout** - When `autoDispose: true` is configured and the reference count reaches zero
3. **Manual disposal** - When explicitly called in code

### Manual Invocation

You should **rarely** need to call `dispose()` manually. ReactiveNotifier manages ViewModel lifecycle automatically. However, manual disposal may be needed for:

- Testing scenarios
- Force cleanup in specific edge cases
- Custom lifecycle management

## Source Code Reference

### ViewModel<T> Dispose Implementation

From `viewmodel_impl.dart` (lines 363-412):

```dart
@override
void dispose() {
  if (_disposed) return;

  // 1. Remove all external listeners registered via setupListeners()
  removeListeners();

  // 2. Stop internal listenVM() connections to other ViewModels
  stopListeningVM();

  // 3. Notify ReactiveNotifier to remove this ViewModel from global registry
  _notifyReactiveNotifierDisposal();

  // 4. Mark as disposed and record timing
  _disposed = true;
  _disposeTime = DateTime.now();

  // 5. Call ChangeNotifier dispose to remove all Flutter listeners
  super.dispose();
}
```

### AsyncViewModelImpl<T> Dispose Implementation

From `async_viewmodel_impl.dart` (lines 680-730):

```dart
@override
void dispose() {
  // 1. Stop internal listenVM() connections to other ViewModels/AsyncViewModels
  stopListeningVM();

  // 2. Remove all external listeners registered via setupListeners()
  removeListeners();

  // 3. Clear async state to help GC
  _state = AsyncState.initial();

  // 4. Reset initialization flags
  hasInitializedListenerExecution = false;
  loadOnInit = true;
  _initialized = false;
  _initializedWithoutContext = false;

  // 5. Mark as disposed
  _disposed = true;

  // 6. Notify ReactiveNotifier to remove this AsyncViewModel from global registry
  _notifyReactiveNotifierDisposal();

  // 7. Call ChangeNotifier dispose to remove all Flutter listeners
  super.dispose();
}
```

## Disposal Sequence

The `dispose()` method follows a specific order to ensure safe cleanup:

```
dispose() called
    |
    v
[1] removeListeners() - Remove external listeners from other notifiers
    |
    v
[2] stopListeningVM() - Stop listening to other ViewModels
    |
    v
[3] Clear state (AsyncViewModelImpl only)
    |
    v
[4] Reset flags
    |
    v
[5] _notifyReactiveNotifierDisposal() - Clean from global registry
    |
    v
[6] Mark as disposed (_disposed = true)
    |
    v
[7] super.dispose() - ChangeNotifier cleanup
```

## Usage Examples

### Testing with Manual Dispose

```dart
void main() {
  group('UserViewModel Tests', () {
    late UserViewModel viewModel;

    setUp(() {
      ReactiveNotifier.cleanup(); // Clear all state
      viewModel = UserViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('should update user name', () {
      viewModel.updateUserName('John');
      expect(viewModel.data.name, equals('John'));
    });
  });
}
```

### Checking Disposal State

```dart
class MyViewModel extends ViewModel<MyState> {
  MyViewModel() : super(MyState.initial());

  @override
  void init() {
    updateSilently(MyState.initial());
  }

  void safeOperation() {
    // Check if disposed before operations
    if (isDisposed) {
      return; // Don't perform operation on disposed ViewModel
    }

    // Perform operation safely
    updateState(data.copyWith(updated: true));
  }
}
```

### Custom Cleanup in Dispose Override

```dart
class ResourceViewModel extends ViewModel<ResourceState> {
  StreamSubscription? _subscription;
  Timer? _refreshTimer;

  ResourceViewModel() : super(ResourceState.initial());

  @override
  void init() {
    _subscription = someStream.listen(_handleStreamData);
    _refreshTimer = Timer.periodic(
      Duration(minutes: 5),
      (_) => _refresh(),
    );
    updateSilently(ResourceState.initial());
  }

  @override
  void dispose() {
    // Clean up custom resources BEFORE calling super.dispose()
    _subscription?.cancel();
    _subscription = null;

    _refreshTimer?.cancel();
    _refreshTimer = null;

    // Always call super.dispose() last
    super.dispose();
  }
}
```

### Handling Async Cleanup

```dart
class AsyncResourceViewModel extends AsyncViewModelImpl<ResourceData> {
  WebSocketChannel? _channel;

  AsyncResourceViewModel() : super(AsyncState.initial());

  @override
  Future<ResourceData> init() async {
    _channel = WebSocketChannel.connect(Uri.parse('wss://example.com'));
    return await _fetchInitialData();
  }

  @override
  void dispose() {
    // Close async resources synchronously
    _channel?.sink.close();
    _channel = null;

    super.dispose();
  }
}
```

## Best Practices

### 1. Always Call super.dispose()

```dart
@override
void dispose() {
  // Your cleanup code here
  _myResource?.cleanup();

  // ALWAYS call super.dispose() at the end
  super.dispose();
}
```

### 2. Cancel Subscriptions and Timers

```dart
@override
void dispose() {
  // Cancel all subscriptions
  for (final subscription in _subscriptions) {
    subscription.cancel();
  }
  _subscriptions.clear();

  // Cancel all timers
  _refreshTimer?.cancel();
  _debounceTimer?.cancel();

  super.dispose();
}
```

### 3. Null Out References

```dart
@override
void dispose() {
  _controller?.dispose();
  _controller = null; // Help GC

  _stream?.close();
  _stream = null;

  super.dispose();
}
```

### 4. Check Disposed State in Long-Running Operations

```dart
Future<void> _longRunningOperation() async {
  for (int i = 0; i < items.length; i++) {
    // Check disposal during long operations
    if (isDisposed) return;

    await processItem(items[i]);
  }

  if (!isDisposed) {
    updateState(ProcessingState.completed());
  }
}
```

### 5. Use isDisposed Getter

```dart
void safeUpdate(MyState newState) {
  if (!isDisposed) {
    updateState(newState);
  }
}
```

## Common Mistakes to Avoid

### 1. Not Calling super.dispose()

```dart
// WRONG - Memory leak! ChangeNotifier listeners not cleaned
@override
void dispose() {
  _myCleanup();
  // Missing super.dispose()!
}

// CORRECT
@override
void dispose() {
  _myCleanup();
  super.dispose(); // Always call this
}
```

### 2. Calling dispose() Multiple Times

```dart
// WRONG - May cause issues
viewModel.dispose();
viewModel.dispose(); // Second call

// The implementation protects against this:
// if (_disposed) return;
// But you should avoid it in your code
```

### 3. Using ViewModel After Dispose

```dart
// WRONG - ViewModel is disposed
viewModel.dispose();
viewModel.updateState(newState); // Error or unexpected behavior

// CORRECT - Check before use
if (!viewModel.isDisposed) {
  viewModel.updateState(newState);
}
```

### 4. Forgetting to Clean Custom Resources

```dart
// WRONG - Timer continues running after dispose
class LeakyViewModel extends ViewModel<State> {
  Timer? _timer;

  void init() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _tick());
  }

  // No override of dispose() - timer keeps running!
}

// CORRECT - Clean up custom resources
class CleanViewModel extends ViewModel<State> {
  Timer? _timer;

  void init() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
```

### 5. Disposing in Wrong Order

```dart
// WRONG - Calling super.dispose() first
@override
void dispose() {
  super.dispose(); // Now ChangeNotifier is disposed
  _cleanup(); // May fail if it depends on notifier state
}

// CORRECT - Clean up first, then super.dispose()
@override
void dispose() {
  _cleanup(); // Your cleanup first
  super.dispose(); // ChangeNotifier cleanup last
}
```

### 6. Blocking dispose() with Async Operations

```dart
// WRONG - dispose() is synchronous, don't await
@override
void dispose() {
  await _asyncCleanup(); // Compilation error: dispose is not async
  super.dispose();
}

// CORRECT - Fire and forget if needed, or use sync cleanup
@override
void dispose() {
  // Fire and forget
  unawaited(_asyncCleanup());

  // Or better: use synchronous cleanup
  _channel?.sink.close(); // Synchronous

  super.dispose();
}
```

## Lifecycle Position

The `dispose()` method is the final step in the ViewModel lifecycle:

```
Constructor -> init() -> setupListeners() -> onResume()
                                               |
                                               v
                                        [Active State]
                                               |
                                               v
                                          dispose()
                                               ^
                                               |
                                         You are here
```

## Automatic Reinitialization

ReactiveNotifier supports automatic reinitialization of disposed ViewModels. If a disposed ViewModel is accessed again, the `_checkDisposed()` method triggers `_reinitializeIfNeeded()`:

```dart
void _checkDisposed() {
  if (_disposed) {
    _reinitializeIfNeeded();
  }
}
```

This means that even after disposal, accessing the ViewModel through its ReactiveNotifier will automatically create a fresh instance.

## Related Methods

- `removeListeners()` - Called during dispose to clean up external listeners
- `stopListeningVM()` - Called during dispose to stop listening to other ViewModels
- `cleanState()` - Alternative to dispose that cleans state without full disposal
- `isDisposed` - Getter to check if ViewModel is disposed
