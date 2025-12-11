# loadingState()

## Method Signature

```dart
@protected
@visibleForTesting
void loadingState()
```

## Purpose

Sets the current async state to `AsyncState.loading()` and notifies all listeners. This method signals that an asynchronous operation is in progress, typically used to show loading indicators in the UI.

## Parameters

None.

## Return Type

`void`

## Annotations

- `@protected` - Intended for use within the ViewModel or subclasses, not from external code
- `@visibleForTesting` - Exposed for testing purposes

## Behavior

1. Stores the previous state for the hook
2. Sets the internal state to `AsyncState.loading()`
3. Calls `notifyListeners()` to trigger UI updates
4. Triggers `onAsyncStateChanged(previous, newState)` hook

## Usage Example

### Basic Loading State

```dart
class ProductViewModel extends AsyncViewModelImpl<Product> {
  ProductViewModel() : super(AsyncState.initial());

  @override
  Future<Product> init() async {
    return await productRepository.fetchProduct(productId);
  }

  Future<void> refreshProduct() async {
    loadingState(); // Show loading indicator

    try {
      final product = await productRepository.fetchProduct(productId);
      updateState(product);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}
```

### Before Async Operations

```dart
class UserProfileViewModel extends AsyncViewModelImpl<UserProfile> {
  Future<void> updateProfile(ProfileUpdateRequest request) async {
    loadingState(); // Indicate operation in progress

    try {
      final updatedProfile = await userRepository.updateProfile(request);
      updateState(updatedProfile);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    loadingState(); // Show upload progress

    try {
      final avatarUrl = await storageService.uploadImage(imageFile);
      final updated = data!.copyWith(avatarUrl: avatarUrl);
      updateState(updated);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}
```

### Preventing Duplicate Operations

```dart
class SearchViewModel extends AsyncViewModelImpl<List<SearchResult>> {
  Future<void> search(String query) async {
    // Prevent duplicate searches
    if (isLoading) {
      return;
    }

    loadingState();

    try {
      final results = await searchService.search(query);
      updateState(results);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}
```

### Multi-Step Operations

```dart
class CheckoutViewModel extends AsyncViewModelImpl<CheckoutResult> {
  Future<void> processCheckout(Cart cart) async {
    loadingState(); // Step 1: Start loading

    try {
      // Validate cart
      await cartService.validate(cart);

      // Process payment
      final paymentResult = await paymentService.process(cart.total);

      // Create order
      final order = await orderService.create(cart, paymentResult);

      updateState(CheckoutResult.success(order));
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}
```

## Complete Example

```dart
class DataSyncViewModel extends AsyncViewModelImpl<SyncStatus> {
  final DataRepository _repository;
  final SyncService _syncService;

  DataSyncViewModel({
    DataRepository? repository,
    SyncService? syncService,
  })  : _repository = repository ?? DataRepository(),
        _syncService = syncService ?? SyncService(),
        super(AsyncState.initial());

  @override
  Future<SyncStatus> init() async {
    return await _repository.getLastSyncStatus();
  }

  @override
  void onAsyncStateChanged(
    AsyncState<SyncStatus> previous,
    AsyncState<SyncStatus> next,
  ) {
    // Track loading state transitions
    if (previous.isSuccess && next.isLoading) {
      analytics.track('SyncStarted');
    }
    if (previous.isLoading && next.isSuccess) {
      analytics.track('SyncCompleted', {
        'duration': DateTime.now().difference(
          previous.data?.lastSyncTime ?? DateTime.now()
        ).inSeconds,
      });
    }
  }

  Future<void> startSync() async {
    // Guard against concurrent syncs
    if (isLoading) {
      log('Sync already in progress');
      return;
    }

    loadingState();

    try {
      // Perform sync operation
      final result = await _syncService.performFullSync();

      // Update local status
      final status = SyncStatus(
        lastSyncTime: DateTime.now(),
        itemsSynced: result.itemCount,
        success: true,
      );

      await _repository.saveSyncStatus(status);
      updateState(status);
    } catch (e, stack) {
      final errorStatus = SyncStatus(
        lastSyncTime: data?.lastSyncTime,
        itemsSynced: 0,
        success: false,
        errorMessage: e.toString(),
      );

      // Save error status but show error state
      await _repository.saveSyncStatus(errorStatus);
      errorState(e, stack);
    }
  }

  Future<void> syncItem(String itemId) async {
    loadingState();

    try {
      await _syncService.syncSingleItem(itemId);

      // Refresh status
      final status = await _repository.getLastSyncStatus();
      updateState(status);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}
```

## UI Integration

```dart
class SyncButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<DataSyncViewModel, SyncStatus>(
      notifier: SyncService.syncState.notifier,
      onData: (status, viewModel, keep) {
        return ElevatedButton(
          onPressed: () => viewModel.startSync(),
          child: Text('Sync Now'),
        );
      },
      onLoading: () {
        // loadingState() triggers this
        return ElevatedButton(
          onPressed: null, // Disabled during loading
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Syncing...'),
            ],
          ),
        );
      },
      onError: (error, stack) {
        return ElevatedButton(
          onPressed: () => SyncService.syncState.notifier.startSync(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Retry Sync'),
        );
      },
    );
  }
}
```

## Best Practices

### 1. Call Before Any Async Operation

```dart
// GOOD - Loading state before async work
Future<void> fetchData() async {
  loadingState();
  try {
    final data = await repository.fetch();
    updateState(data);
  } catch (e, stack) {
    errorState(e, stack);
  }
}

// AVOID - Missing loading state
Future<void> fetchData() async {
  try {
    final data = await repository.fetch(); // No loading indicator shown!
    updateState(data);
  } catch (e, stack) {
    errorState(e, stack);
  }
}
```

### 2. Guard Against Duplicate Calls

```dart
Future<void> refresh() async {
  if (isLoading) return; // Prevent duplicate operations

  loadingState();
  // ... rest of operation
}
```

### 3. Always Follow with Success or Error

```dart
Future<void> operation() async {
  loadingState();

  try {
    // ... async work
    updateState(result); // Success path
  } catch (e, stack) {
    errorState(e, stack); // Error path
  }
  // Never leave in loading state indefinitely
}
```

### 4. Use for User-Visible Operations

```dart
// GOOD - User expects feedback
Future<void> submitForm() async {
  loadingState(); // User sees loading
  // ...
}

// For background operations, consider silent updates
Future<void> backgroundSync() async {
  // No loadingState() - happens in background
  final data = await fetchBackground();
  updateSilently(data);
}
```

### 5. Leverage onAsyncStateChanged for Analytics

```dart
@override
void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
  if (next.isLoading) {
    analytics.track('OperationStarted');
    _operationStartTime = DateTime.now();
  }
  if (previous.isLoading && next.isSuccess) {
    final duration = DateTime.now().difference(_operationStartTime!);
    analytics.track('OperationCompleted', {'durationMs': duration.inMilliseconds});
  }
}
```

## Notes

- The method is marked `@protected` because it is typically called internally within the ViewModel, not from external code
- The `@visibleForTesting` annotation allows direct testing of loading state transitions
- The `reload()` method internally calls `loadingState()` before invoking `init()`
- Calling `loadingState()` when already in loading state will still notify listeners

## Related Methods

- [`errorState()`](./error-state.md) - Set error state with notification
- [`updateState()`](../async-viewmodel.md#updatestate) - Set success state with notification
- [`reload()`](../async-viewmodel.md#reload) - Full reload cycle (includes loadingState)
