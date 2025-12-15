# transformDataStateSilently()

## Method Signature

```dart
void transformDataStateSilently(T? Function(T? data) transformer)
```

## Purpose

Transforms only the data within the current success state using a transformer function **without notifying listeners**. This is the silent version of `transformDataState()`, useful for batching multiple updates, background operations, or internal state changes that should not trigger immediate UI rebuilds.

**Important:** Even though listeners are not notified, the `onAsyncStateChanged` hook is still called. This allows for logging and side effects while preventing UI updates.

## Parameters

### transformer (required)

**Type:** `T? Function(T? data)`

A function that receives the current data (which may be `null`) and returns the transformed data. If the transformer returns `null`, the transformation is ignored and a warning is logged.

## Return Type

`void`

## Behavior

1. Stores the previous state for the hook
2. Extracts the current `data` from the async state
3. Passes the data to the transformer function
4. If the transformer returns a non-null value:
   - Updates the state to `AsyncState.success(transformedData)`
   - Does **NOT** call `notifyListeners()` (UI is not rebuilt)
   - Triggers `onAsyncStateChanged` hook
5. If the transformer returns `null`:
   - Logs a warning message
   - State remains unchanged

## Usage Example

### Batching Multiple Updates

```dart
class CartViewModel extends AsyncViewModelImpl<Cart> {
  void applyBulkDiscounts(List<Discount> discounts) {
    // Apply each discount silently
    for (final discount in discounts) {
      transformDataStateSilently((cart) {
        return cart?.copyWith(
          items: cart.items.map((item) {
            if (discount.appliesTo(item)) {
              return item.copyWith(
                price: item.price * (1 - discount.percentage),
              );
            }
            return item;
          }).toList(),
        );
      });
    }

    // Single notification after all updates
    if (hasData) {
      notifyListeners();
    }
  }
}
```

### Background Data Processing

```dart
class DataProcessorViewModel extends AsyncViewModelImpl<ProcessedData> {
  Future<void> processInBackground() async {
    if (!hasData) return;

    // Process data silently in chunks
    final chunks = data!.items.chunked(100);

    for (final chunk in chunks) {
      final processedChunk = await _processChunk(chunk);

      // Update silently - no UI flicker during processing
      transformDataStateSilently((data) {
        return data?.copyWith(
          processedItems: [...data.processedItems, ...processedChunk],
          progress: data.progress + (chunk.length / data.items.length),
        );
      });
    }

    // Notify once processing is complete
    notifyListeners();
  }
}
```

### Internal State Normalization

```dart
class UserListViewModel extends AsyncViewModelImpl<List<User>> {
  void normalizeData() {
    // Silent normalization - UI doesn't need to update
    transformDataStateSilently((users) {
      return users?.map((user) {
        return user.copyWith(
          name: user.name.trim(),
          email: user.email.toLowerCase(),
        );
      }).toList();
    });
  }

  // Called before any operation that requires normalized data
  void prepareForExport() {
    normalizeData();
    // Continue with export logic...
  }
}
```

### Optimistic Updates with Delayed Notification

```dart
class MessageViewModel extends AsyncViewModelImpl<List<Message>> {
  Future<void> sendMessage(String content) async {
    final tempMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );

    // Add message silently
    transformDataStateSilently((messages) {
      return [...?messages, tempMessage];
    });

    // Show sending indicator without full rebuild
    notifyListeners();

    try {
      final sentMessage = await messageRepository.send(content);

      // Update silently with real message
      transformDataStateSilently((messages) {
        return messages?.map((m) {
          return m.id == tempMessage.id ? sentMessage : m;
        }).toList();
      });

      // Single notification for success
      notifyListeners();
    } catch (e) {
      // Remove temp message silently
      transformDataStateSilently((messages) {
        return messages?.where((m) => m.id != tempMessage.id).toList();
      });

      notifyListeners();
      rethrow;
    }
  }
}
```

### Caching/Pagination Without UI Updates

```dart
class PaginatedListViewModel extends AsyncViewModelImpl<PaginatedData<Item>> {
  final Map<int, List<Item>> _pageCache = {};

  void cacheCurrentPage() {
    if (!hasData) return;

    final currentPage = data!.currentPage;
    _pageCache[currentPage] = List.from(data!.items);
  }

  Future<void> loadPage(int page) async {
    // Check cache first
    if (_pageCache.containsKey(page)) {
      // Silent update from cache
      transformDataStateSilently((data) {
        return data?.copyWith(
          items: _pageCache[page]!,
          currentPage: page,
        );
      });
      notifyListeners();
      return;
    }

    // Load from API
    loadingState();
    try {
      final pageData = await repository.fetchPage(page);
      _pageCache[page] = pageData.items;
      updateState(pageData);
    } catch (e, stack) {
      errorState(e, stack);
    }
  }
}
```

### Silent Counter Updates

```dart
class StatsViewModel extends AsyncViewModelImpl<Statistics> {
  void incrementViewCount() {
    // Silent increment - user doesn't need to see every update
    transformDataStateSilently((stats) {
      return stats?.copyWith(viewCount: stats.viewCount + 1);
    });
  }

  void batchIncrementViews(int count) {
    for (int i = 0; i < count; i++) {
      incrementViewCount();
    }
    // Notify once at the end
    notifyListeners();
  }
}
```

## Complete Example

```dart
class InventoryViewModel extends AsyncViewModelImpl<Inventory> {
  final InventoryRepository _repository;

  InventoryViewModel({InventoryRepository? repository})
      : _repository = repository ?? InventoryRepository(),
        super(AsyncState.initial());

  @override
  Future<Inventory> init() async {
    return await _repository.fetchInventory();
  }

  @override
  void onAsyncStateChanged(AsyncState<Inventory> previous, AsyncState<Inventory> next) {
    // This is still called even for silent updates
    // Useful for logging/analytics
    if (previous.isSuccess && next.isSuccess) {
      final prevCount = previous.data?.totalItems ?? 0;
      final nextCount = next.data?.totalItems ?? 0;
      if (prevCount != nextCount) {
        analytics.track('InventoryChanged', {
          'previous': prevCount,
          'current': nextCount,
        });
      }
    }
  }

  // Bulk restock operation
  Future<void> restockItems(Map<String, int> restockQuantities) async {
    if (!hasData) return;

    // Track changes for rollback
    final originalInventory = data!;
    int processedCount = 0;

    try {
      for (final entry in restockQuantities.entries) {
        final itemId = entry.key;
        final quantity = entry.value;

        // Silent local update
        transformDataStateSilently((inventory) {
          return inventory?.copyWith(
            items: inventory.items.map((item) {
              if (item.id == itemId) {
                return item.copyWith(quantity: item.quantity + quantity);
              }
              return item;
            }).toList(),
          );
        });

        processedCount++;

        // Sync with backend
        await _repository.restockItem(itemId, quantity);
      }

      // All successful - notify UI
      notifyListeners();
    } catch (e) {
      // Rollback to original
      updateState(originalInventory);
      rethrow;
    }
  }

  // Low stock check (background operation)
  void checkLowStock() {
    transformDataStateSilently((inventory) {
      return inventory?.copyWith(
        items: inventory.items.map((item) {
          return item.copyWith(
            isLowStock: item.quantity < item.minimumStock,
          );
        }).toList(),
        lastChecked: DateTime.now(),
      );
    });
    // No notification - this is just internal state maintenance
  }

  // Prepare data for export (normalize without UI update)
  Inventory? prepareForExport() {
    transformDataStateSilently((inventory) {
      return inventory?.copyWith(
        items: inventory.items
            .where((item) => item.quantity > 0)
            .map((item) => item.copyWith(
                  name: item.name.trim(),
                  sku: item.sku.toUpperCase(),
                ))
            .toList(),
      );
    });
    return data;
  }
}
```

## Best Practices

### 1. Always Notify After Batch Operations

```dart
// GOOD - Notify once after all silent updates
void processBatch(List<Item> items) {
  for (final item in items) {
    transformDataStateSilently((data) => /* transform */);
  }
  notifyListeners(); // Single notification
}

// AVOID - Forgetting to notify
void processBatch(List<Item> items) {
  for (final item in items) {
    transformDataStateSilently((data) => /* transform */);
  }
  // Missing notifyListeners() - UI never updates!
}
```

### 2. Use for Background Processing Only

```dart
// GOOD - Background operation
void normalizeInBackground() {
  transformDataStateSilently((data) => normalize(data));
  // Later triggered by user action or timer
}

// AVOID - User-triggered action should notify
void onUserTap() {
  transformDataStateSilently((data) => /* update */);
  // User expects immediate feedback!
}
```

### 3. Track State for Potential Rollback

```dart
void riskyOperation() {
  final backup = data;

  try {
    transformDataStateSilently((data) => riskyTransform(data));
    // ... more operations
    notifyListeners();
  } catch (e) {
    if (backup != null) {
      updateState(backup); // Rollback with notification
    }
    rethrow;
  }
}
```

### 4. Document Silent Updates

```dart
/// Updates stock counts silently for batch processing.
/// Caller is responsible for calling notifyListeners()
/// after all updates are complete.
void updateStockSilently(String itemId, int newQuantity) {
  transformDataStateSilently((inventory) {
    return inventory?.updateStock(itemId, newQuantity);
  });
}
```

### 5. Use onAsyncStateChanged for Logging

```dart
@override
void onAsyncStateChanged(AsyncState<Data> previous, AsyncState<Data> next) {
  // This hook fires even for silent updates
  // Perfect for analytics/logging without affecting UI
  logger.debug('State changed: ${previous.status} -> ${next.status}');
}
```

## Related Methods

- [`transformDataState()`](./transform-data-state.md) - Same transformation with listener notification
- [`transformStateSilently()`](../async-viewmodel.md#transformstatesilently) - Silent transformation of entire `AsyncState`
- [`updateSilently()`](../async-viewmodel.md#updatesilently) - Silent complete data replacement
