# transformState()

Transforms the current state using a function and notifies listeners.

## Method Signature

```dart
void transformState(T Function(T data) transformer)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `transformer` | `T Function(T data)` | A function that receives the current state and returns the new state |

## Purpose

`transformState()` provides a functional approach to state updates. Instead of replacing state directly, you provide a transformation function that receives the current state and returns a new state. This pattern ensures you always work with the latest state value and promotes immutable update patterns.

## When to Use

Use `transformState()` when:

- Updating state based on current values (incrementing, toggling, appending)
- Using `copyWith` patterns for partial updates
- Ensuring atomic updates that depend on current state
- Writing more declarative, functional code

Use alternatives when:

- **`updateState()`**: Replacing state entirely without needing current value
- **`updateSilently()`**: Setting state without UI notification
- **`transformStateSilently()`**: Transforming state without UI notification

## Triggers onStateChanged?

**Yes** - The `onStateChanged(previous, next)` hook is called after the transformation and notification.

## Usage Example

```dart
class CartViewModel extends ViewModel<CartModel> {
  CartViewModel() : super(CartModel.empty());

  @override
  void init() {
    updateSilently(CartModel.empty());
  }

  // Add item using current state
  void addItem(Product product) {
    transformState((cart) => cart.copyWith(
      items: [...cart.items, CartItem(product: product, quantity: 1)],
      updatedAt: DateTime.now(),
    ));
  }

  // Increment quantity based on current value
  void incrementQuantity(String productId) {
    transformState((cart) {
      final items = cart.items.map((item) {
        if (item.product.id == productId) {
          return item.copyWith(quantity: item.quantity + 1);
        }
        return item;
      }).toList();
      return cart.copyWith(items: items);
    });
  }

  // Toggle selection state
  void toggleItemSelection(String productId) {
    transformState((cart) {
      final items = cart.items.map((item) {
        if (item.product.id == productId) {
          return item.copyWith(isSelected: !item.isSelected);
        }
        return item;
      }).toList();
      return cart.copyWith(items: items);
    });
  }

  // Apply discount based on current total
  void applyPercentageDiscount(double percentage) {
    transformState((cart) => cart.copyWith(
      discount: cart.subtotal * (percentage / 100),
    ));
  }

  // Remove item from list
  void removeItem(String productId) {
    transformState((cart) => cart.copyWith(
      items: cart.items.where((item) => item.product.id != productId).toList(),
    ));
  }
}
```

## Best Practices

1. **Keep transformers pure** - The transformer function should not have side effects:

```dart
// Good - pure transformation
transformState((state) => state.copyWith(count: state.count + 1));

// Avoid - side effects in transformer
transformState((state) {
  saveToDatabase(state); // Side effect - avoid
  return state.copyWith(count: state.count + 1);
});
```

2. **Use copyWith for partial updates** - Preserve unmodified fields:

```dart
transformState((user) => user.copyWith(
  name: newName,
  // email, id, etc. preserved automatically
));
```

3. **Handle null safety within transformers**:

```dart
transformState((state) {
  if (state.items == null) return state;
  return state.copyWith(
    items: state.items!.where((i) => i.isValid).toList(),
  );
});
```

4. **Chain logical operations**:

```dart
void processOrder() {
  transformState((order) => order
    .copyWith(status: OrderStatus.processing)
    .copyWith(processedAt: DateTime.now())
    .copyWith(processedBy: currentUser.id));
}
```

5. **Prefer transformState over manual get-then-set**:

```dart
// Avoid - state might change between get and set
void incrementBad() {
  final current = data.count;
  updateState(data.copyWith(count: current + 1));
}

// Prefer - atomic operation
void incrementGood() {
  transformState((state) => state.copyWith(count: state.count + 1));
}
```

## Internal Behavior

When `transformState()` is called:

1. Checks if ViewModel is disposed (reinitializes if needed)
2. Stores the previous state
3. Executes the transformer function with current state
4. Assigns the returned value as new state
5. Increments the update counter
6. Calls `notifyListeners()` to trigger UI rebuilds
7. Executes `onStateChanged(previous, newState)` hook

## Common Patterns

### Counter Operations

```dart
void increment() => transformState((s) => s.copyWith(count: s.count + 1));
void decrement() => transformState((s) => s.copyWith(count: s.count - 1));
void reset() => transformState((s) => s.copyWith(count: 0));
```

### List Operations

```dart
void addItem(Item item) => transformState((s) => s.copyWith(items: [...s.items, item]));
void removeAt(int index) => transformState((s) => s.copyWith(items: [...s.items]..removeAt(index)));
void clearItems() => transformState((s) => s.copyWith(items: []));
```

### Toggle Operations

```dart
void toggleDarkMode() => transformState((s) => s.copyWith(isDark: !s.isDark));
void toggleExpanded() => transformState((s) => s.copyWith(isExpanded: !s.isExpanded));
```

## Related Methods

- [`updateState()`](./update-state.md) - Update with notification
- [`updateSilently()`](./update-silently.md) - Update without notification
- [`transformStateSilently()`](./transform-state-silently.md) - Transform without notification
- [`cleanState()`](./clean-state.md) - Reset to empty state
