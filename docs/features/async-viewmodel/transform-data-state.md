# transformDataState()

## Method Signature

```dart
void transformDataState(T? Function(T? data) transformer)
```

## Purpose

Transforms only the data within the current success state using a transformer function and notifies listeners. This method is designed for modifying the existing data without changing the overall async state type. It provides a clean, functional approach to data manipulation.

## Parameters

### transformer (required)

**Type:** `T? Function(T? data)`

A function that receives the current data (which may be `null`) and returns the transformed data. If the transformer returns `null`, the transformation is ignored and a warning is logged.

## Return Type

`void`

## Behavior

1. Extracts the current `data` from the async state
2. Passes the data to the transformer function
3. If the transformer returns a non-null value:
   - Updates the state to `AsyncState.success(transformedData)`
   - Notifies all listeners
   - Triggers `onAsyncStateChanged` hook
4. If the transformer returns `null`:
   - Logs a warning message
   - State remains unchanged
   - No listeners are notified

## Usage Example

### Adding Items to a List

```dart
class TodoListViewModel extends AsyncViewModelImpl<List<Todo>> {
  TodoListViewModel() : super(AsyncState.initial());

  @override
  Future<List<Todo>> init() async {
    return await todoRepository.fetchAll();
  }

  void addTodo(Todo newTodo) {
    transformDataState((currentTodos) {
      return [...?currentTodos, newTodo];
    });
  }

  void addMultipleTodos(List<Todo> todos) {
    transformDataState((currentTodos) {
      return [...?currentTodos, ...todos];
    });
  }
}
```

### Removing Items from a List

```dart
class CartViewModel extends AsyncViewModelImpl<List<CartItem>> {
  void removeItem(String itemId) {
    transformDataState((items) {
      return items?.where((item) => item.id != itemId).toList();
    });
  }

  void clearCart() {
    transformDataState((_) => []);
  }
}
```

### Updating Specific Items

```dart
class UserListViewModel extends AsyncViewModelImpl<List<User>> {
  void toggleUserActive(String userId) {
    transformDataState((users) {
      return users?.map((user) {
        if (user.id == userId) {
          return user.copyWith(isActive: !user.isActive);
        }
        return user;
      }).toList();
    });
  }

  void updateUserName(String userId, String newName) {
    transformDataState((users) {
      return users?.map((user) {
        if (user.id == userId) {
          return user.copyWith(name: newName);
        }
        return user;
      }).toList();
    });
  }
}
```

### Working with Single Objects

```dart
class ProfileViewModel extends AsyncViewModelImpl<UserProfile> {
  void updateEmail(String newEmail) {
    transformDataState((profile) {
      return profile?.copyWith(email: newEmail);
    });
  }

  void incrementLoginCount() {
    transformDataState((profile) {
      if (profile == null) return null;
      return profile.copyWith(loginCount: profile.loginCount + 1);
    });
  }
}
```

### Filtering Data

```dart
class ProductListViewModel extends AsyncViewModelImpl<List<Product>> {
  void filterByCategory(String category) {
    transformDataState((products) {
      return products?.where((p) => p.category == category).toList();
    });
  }

  void filterByPriceRange(double min, double max) {
    transformDataState((products) {
      return products
          ?.where((p) => p.price >= min && p.price <= max)
          .toList();
    });
  }

  void sortByPrice({bool ascending = true}) {
    transformDataState((products) {
      if (products == null) return null;
      final sorted = List<Product>.from(products);
      sorted.sort((a, b) => ascending
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price));
      return sorted;
    });
  }
}
```

### Numeric Transformations

```dart
class CounterViewModel extends AsyncViewModelImpl<int> {
  CounterViewModel() : super(AsyncState.initial());

  @override
  Future<int> init() async {
    return await counterRepository.getCurrentValue();
  }

  void increment() {
    transformDataState((count) => (count ?? 0) + 1);
  }

  void decrement() {
    transformDataState((count) => (count ?? 0) - 1);
  }

  void multiplyBy(int factor) {
    transformDataState((count) => (count ?? 0) * factor);
  }

  void reset() {
    transformDataState((_) => 0);
  }
}
```

## Complete Example

```dart
class OrderManagementViewModel extends AsyncViewModelImpl<List<Order>> {
  final OrderRepository _repository;

  OrderManagementViewModel({OrderRepository? repository})
      : _repository = repository ?? OrderRepository(),
        super(AsyncState.initial());

  @override
  Future<List<Order>> init() async {
    return await _repository.fetchOrders();
  }

  // Add new order (optimistic update with rollback)
  Future<void> createOrder(OrderRequest request) async {
    final tempOrder = Order.fromRequest(request, id: 'temp-${DateTime.now()}');

    // Optimistic add
    transformDataState((orders) => [...?orders, tempOrder]);

    try {
      final createdOrder = await _repository.createOrder(request);

      // Replace temp order with real order
      transformDataState((orders) {
        return orders?.map((o) {
          return o.id == tempOrder.id ? createdOrder : o;
        }).toList();
      });
    } catch (e) {
      // Rollback on failure
      transformDataState((orders) {
        return orders?.where((o) => o.id != tempOrder.id).toList();
      });
      rethrow;
    }
  }

  // Update order status
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    transformDataState((orders) {
      return orders?.map((order) {
        if (order.id == orderId) {
          return order.copyWith(status: newStatus);
        }
        return order;
      }).toList();
    });
  }

  // Batch update
  void markAllAsProcessing(List<String> orderIds) {
    transformDataState((orders) {
      return orders?.map((order) {
        if (orderIds.contains(order.id)) {
          return order.copyWith(status: OrderStatus.processing);
        }
        return order;
      }).toList();
    });
  }

  // Complex transformation
  void applyDiscount(String couponCode, double discountPercent) {
    transformDataState((orders) {
      return orders?.map((order) {
        if (order.status == OrderStatus.pending) {
          final discountAmount = order.total * (discountPercent / 100);
          return order.copyWith(
            discount: discountAmount,
            total: order.total - discountAmount,
            couponCode: couponCode,
          );
        }
        return order;
      }).toList();
    });
  }
}
```

## Best Practices

### 1. Always Handle Null Data

```dart
// GOOD - Handle potential null
transformDataState((items) {
  return [...?items, newItem]; // Spread operator handles null
});

// GOOD - Explicit null check
transformDataState((items) {
  if (items == null) return [newItem];
  return [...items, newItem];
});

// AVOID - May fail on null
transformDataState((items) {
  return [...items!, newItem]; // Throws if null
});
```

### 2. Return New Instances for Collections

```dart
// GOOD - Create new list
transformDataState((items) {
  return items?.where((i) => i.isActive).toList();
});

// AVOID - Modifying in place (may not trigger updates)
transformDataState((items) {
  items?.removeWhere((i) => !i.isActive);
  return items;
});
```

### 3. Use copyWith for Object Updates

```dart
// GOOD - Immutable update
transformDataState((user) {
  return user?.copyWith(name: newName);
});

// AVOID - Direct mutation
transformDataState((user) {
  user?.name = newName; // Direct mutation
  return user;
});
```

### 4. Keep Transformations Pure

```dart
// GOOD - Pure transformation
transformDataState((count) => (count ?? 0) + 1);

// AVOID - Side effects in transformer
transformDataState((count) {
  saveToDatabase(count); // Side effect
  return (count ?? 0) + 1;
});
```

### 5. Use Meaningful Method Names

```dart
// GOOD - Clear intent
void addProduct(Product product) {
  transformDataState((products) => [...?products, product]);
}

void removeProduct(String id) {
  transformDataState((products) =>
      products?.where((p) => p.id != id).toList());
}

// AVOID - Generic names
void updateData(Product product) { ... }
void modifyList(String id) { ... }
```

### 6. Check State Before Transformation (When Needed)

```dart
void addItem(Item item) {
  if (!hasData) {
    // Cannot transform - no data loaded yet
    // Consider using updateState instead or logging warning
    return;
  }
  transformDataState((items) => [...items!, item]);
}
```

## Related Methods

- [`transformDataStateSilently()`](./transform-data-state-silently.md) - Same transformation without notifying listeners
- [`transformState()`](../async-viewmodel.md#transformstate) - Transform the entire `AsyncState` (not just data)
- [`updateState()`](../async-viewmodel.md#updatestate) - Replace data entirely with notification
