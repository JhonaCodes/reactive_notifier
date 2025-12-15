# isEmptyData() Helper Method

## Signature

```dart
bool isEmptyData(dynamic value)
```

## Type

Returns `bool` - `true` if the provided value is considered "empty", `false` otherwise.

## Description

The `isEmptyData()` method is a utility helper provided by the `HelperNotifier` mixin. It performs comprehensive emptiness checks across various Dart types, making it easy to validate whether data is meaningfully populated.

### Source Implementation

```dart
mixin HelperNotifier {
  bool isEmptyData(dynamic value) {
    // If null
    if (value == null) {
      log("Your current result is null");
      return true;
    }

    // If String
    if (value is String) {
      return value.trim().isEmpty;
    }

    // If Iterable (List, Set, etc.)
    if (value is Iterable) {
      return value.isEmpty;
    }

    // If Map
    if (value is Map) {
      return value.isEmpty;
    }

    // For typed lists
    if (value is Uint8List || value is Int32List || value is Float64List) {
      return value.isEmpty;
    }

    // For objects with isEmpty or length property
    try {
      return value.isEmpty == true;
    } catch (_) {
      try {
        return value.length == 0;
      } catch (_) {
        return false;
      }
    }
  }
}
```

## Usage Example

```dart
class ProductViewModel extends ViewModel<ProductModel> {
  ProductViewModel() : super(ProductModel.empty());

  @override
  void init() {
    updateSilently(ProductModel.empty());
  }

  bool get hasProducts => !isEmptyData(data.products);
  bool get hasDescription => !isEmptyData(data.description);
  bool get hasCategories => !isEmptyData(data.categories);

  void validateProduct() {
    if (isEmptyData(data.name)) {
      throw ValidationError('Product name is required');
    }

    if (isEmptyData(data.price)) {
      throw ValidationError('Product price is required');
    }
  }
}

// Usage in ViewModel methods
class OrderViewModel extends ViewModel<OrderModel> {
  void processOrder() {
    if (isEmptyData(data.items)) {
      showError('Cannot process empty order');
      return;
    }

    if (isEmptyData(data.shippingAddress)) {
      showError('Shipping address required');
      return;
    }

    submitOrder();
  }
}
```

## Supported Types

| Type | Empty Condition |
|------|-----------------|
| `null` | Always empty |
| `String` | `trim().isEmpty` |
| `List` | `isEmpty` |
| `Set` | `isEmpty` |
| `Map` | `isEmpty` |
| `Iterable` | `isEmpty` |
| `Uint8List` | `isEmpty` |
| `Int32List` | `isEmpty` |
| `Float64List` | `isEmpty` |
| Objects with `isEmpty` | `isEmpty == true` |
| Objects with `length` | `length == 0` |
| Other types | `false` (not empty) |

## When to Use

### Form Validation

```dart
void validateForm() {
  final errors = <String>[];

  if (isEmptyData(data.email)) {
    errors.add('Email is required');
  }

  if (isEmptyData(data.password)) {
    errors.add('Password is required');
  }

  if (errors.isNotEmpty) {
    updateState(data.copyWith(errors: errors));
  }
}
```

### Conditional UI Logic

```dart
bool get shouldShowEmptyState => isEmptyData(data.items);
bool get canSubmit => !isEmptyData(data.requiredFields);
```

### Data Processing

```dart
void processApiResponse(Map<String, dynamic>? response) {
  if (isEmptyData(response)) {
    updateState(DataModel.empty());
    return;
  }

  updateState(DataModel.fromJson(response!));
}
```

### Guard Clauses

```dart
Future<void> saveData() async {
  if (isEmptyData(data.changes)) {
    return; // Nothing to save
  }

  await repository.save(data.changes);
}
```

## Best Practices

1. **Use for validation** - Simplify null and empty checks:
   ```dart
   // Instead of
   if (value == null || value.isEmpty)

   // Use
   if (isEmptyData(value))
   ```

2. **Use for strings with whitespace** - Automatically handles trimming:
   ```dart
   isEmptyData('   '); // true - whitespace-only strings are empty
   ```

3. **Use for collections** - Works with any Iterable:
   ```dart
   isEmptyData([]); // true
   isEmptyData({}); // true
   isEmptyData(<String>{}); // true (empty Set)
   ```

4. **Check before operations** - Prevent errors on empty data:
   ```dart
   void processItems() {
     if (isEmptyData(data.items)) {
       return;
     }

     for (final item in data.items) {
       // Safe to iterate
     }
   }
   ```

5. **Combine with computed properties**:
   ```dart
   bool get hasData => !isEmptyData(data.content);
   bool get isReady => hasData && !isEmptyData(data.metadata);
   ```

## Note on Logging

When the value is `null`, the method logs a message:
```dart
if (value == null) {
  log("Your current result is null");
  return true;
}
```

This helps with debugging during development.

## Related

- [data](/doc/features/viewmodel/data.md) - Access current state
- [cleanState()](/doc/features/viewmodel/methods/clean-state.md) - Reset to empty state
