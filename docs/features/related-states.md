# Related States

The Related States system in ReactiveNotifier enables parent-child relationships between state instances, providing automatic notification propagation and convenient type-based access to dependent states.

## Table of Contents

1. [Overview](#overview)
2. [Defining Related States](#defining-related-states)
3. [Parent-Child Relationships](#parent-child-relationships)
4. [Automatic Notification Propagation](#automatic-notification-propagation)
5. [The from\<R\>() Method](#the-fromr-method)
6. [Multiple Related States](#multiple-related-states)
7. [Circular Reference Detection](#circular-reference-detection)
8. [Complete Usage Examples](#complete-usage-examples)
9. [Best Practices](#best-practices)
10. [Common Patterns](#common-patterns)

---

## Overview

Related States is a powerful feature that allows you to create a hierarchy of state dependencies. When a child state updates, its parent states are automatically notified, enabling reactive cascading updates throughout your application.

### Key Benefits

- **Automatic Propagation**: Parent states are notified when any child state changes
- **Type-Safe Access**: Access related states by type using the `from<R>()` method
- **Key-Based Access**: Access related states by their unique key when multiple states share the same type
- **Circular Reference Prevention**: Built-in validation prevents circular dependencies
- **Memory Efficient**: No state duplication; states are referenced, not copied

### When to Use Related States

Use Related States when you need:

- A combined/aggregate state that depends on multiple independent states
- Automatic UI updates when any dependent state changes
- Type-safe access to child states from a parent state
- A dashboard or summary view that reflects multiple data sources

---

## Defining Related States

To define related states, use the `related` parameter in the `ReactiveNotifier` constructor:

```dart
// Define independent child states
final userState = ReactiveNotifier<UserState>(() => UserState.guest());
final cartState = ReactiveNotifier<CartState>(() => CartState.empty());
final settingsState = ReactiveNotifier<SettingsState>(() => SettingsState.defaults());

// Define parent state with related children
final shopState = ReactiveNotifier<ShopState>(
  () => ShopState.initial(),
  related: [userState, cartState, settingsState], // Child states
);
```

### Factory Constructor Signature

```dart
factory ReactiveNotifier(
  T Function() create, {
  List<ReactiveNotifier>? related,  // Optional list of related states
  Key? key,                          // Optional unique key
  bool autoDispose = false,          // Auto-dispose when no widgets use it
})
```

---

## Parent-Child Relationships

When you specify the `related` parameter, ReactiveNotifier establishes a parent-child relationship:

1. The new state becomes the **parent**
2. States in the `related` list become **children**
3. Each child registers the parent in its internal `_parents` set

### Internal Mechanism

```dart
// From ReactiveNotifier source code (simplified)
ReactiveNotifier._(/* ... */) : super(create()) {
  if (related != null) {
    _validateCircularReferences(this);  // Prevent cycles
    related?.forEach((child) {
      child._parents.add(this);  // Register parent in child
    });
  }
}
```

### Relationship Diagram

```
                    +------------------+
                    |    ShopState     |  (Parent)
                    |   (combined)     |
                    +--------+---------+
                             |
         +-------------------+-------------------+
         |                   |                   |
+--------v---------+ +-------v--------+ +--------v---------+
|    UserState     | |   CartState    | |  SettingsState   |
|   (child)        | |   (child)      | |    (child)       |
+------------------+ +----------------+ +------------------+
```

---

## Automatic Notification Propagation

When a child state updates, all its parent states are automatically notified. This propagation works for all state update methods:

### Propagation Flow

```dart
// When cartState updates...
cartState.updateState(CartState(items: 5));

// 1. cartState listeners are notified
// 2. All parents in cartState._parents are notified (shopState)
// 3. shopState listeners rebuild their UI
```

### Source Code Implementation

All update methods (`updateState`, `updateSilently`, `transformState`, `transformStateSilently`) follow the same pattern:

```dart
@override
void updateState(T newState) {
  if (notifier != newState) {
    if (_updatingNotifiers.contains(this)) return;  // Prevent circular updates

    _updatingNotifiers.add(this);
    try {
      super.updateState(newState);  // Update and notify own listeners

      // Notify all parent states
      if (_parents.isNotEmpty) {
        for (var parent in _parents) {
          parent.notifyListeners();
        }
      }
    } finally {
      _updatingNotifiers.remove(this);
    }
  }
}
```

### Silent Updates and Parents

Even `updateSilently()` notifies parent states:

```dart
// Silent update on child
cartState.updateSilently(CartState(items: 10));
// cartState listeners are NOT notified
// But shopState (parent) IS notified!
```

This design ensures parent states always reflect the latest child state data, even for background updates.

---

## The from\<R\>() Method

The `from<R>()` method provides type-safe access to related states from a parent state.

### Basic Usage

```dart
// Access related state by type
final user = shopState.from<UserState>();
final cart = shopState.from<CartState>();

// Use the related state values
print('User: ${user.name}');
print('Cart items: ${cart.items}');
```

### Method Signature

```dart
R from<R>([Key? key])
```

- **R**: The type of the state value to retrieve
- **key**: Optional key for disambiguation when multiple states have the same type

### Key-Based Access

When you have multiple related states of the same type, use key-based access:

```dart
// Multiple String states
final primaryTitle = ReactiveNotifier<String>(() => 'Primary');
final secondaryTitle = ReactiveNotifier<String>(() => 'Secondary');

final combined = ReactiveNotifier<String>(
  () => 'Combined',
  related: [primaryTitle, secondaryTitle],
);

// Access by key to disambiguate
final primary = combined.from<String>(primaryTitle.keyNotifier);
final secondary = combined.from<String>(secondaryTitle.keyNotifier);
```

### Error Handling

`from<R>()` throws descriptive `StateError` messages when:

1. **No related states exist**:
```
No Related States Found
Parent type: ShopState
Requested type: UserState
```

2. **Requested type not found**:
```
Related State Not Found
Looking for: UserState
Parent type: ShopState
Available types: CartState, SettingsState
```

---

## Multiple Related States

You can define multiple related states to create complex state hierarchies.

### Accessing All Related States

```dart
mixin OrderService {
  // Child states
  static final userState = ReactiveNotifier<UserState>(() => UserState.guest());
  static final cartState = ReactiveNotifier<CartState>(() => CartState.empty());
  static final totalState = ReactiveNotifier<TotalState>(() => TotalState(0.0));
  static final discountState = ReactiveNotifier<DiscountState>(() => DiscountState(0.0));

  // Parent state combining all children
  static final orderState = ReactiveNotifier<OrderState>(
    () => OrderState.pending(),
    related: [userState, cartState, totalState, discountState],
  );

  // Access all related states
  static void processOrder() {
    final user = orderState.from<UserState>();
    final cart = orderState.from<CartState>();
    final total = orderState.from<TotalState>();
    final discount = orderState.from<DiscountState>();

    // Process order with all state data
    final finalTotal = total.amount - (total.amount * discount.percentage / 100);
    print('Processing order for ${user.name} with ${cart.items} items, total: \$${finalTotal}');
  }
}
```

### Batch Updates with Multiple States

When multiple child states update, the parent receives a notification for each:

```dart
// Setup notification tracking
var parentNotifications = 0;
orderState.addListener(() => parentNotifications++);

// Update multiple children
cartState.updateState(CartState(items: 3));   // parentNotifications = 1
totalState.updateState(TotalState(150.0));     // parentNotifications = 2
discountState.updateState(DiscountState(10)); // parentNotifications = 3

print('Parent notified $parentNotifications times'); // Output: 3
```

---

## Circular Reference Detection

ReactiveNotifier includes comprehensive circular reference detection to prevent infinite loops and memory issues.

### Types of Detected Cycles

1. **Direct Self-Reference**: A state referencing itself
2. **Indirect Circular Reference**: A -> B -> A
3. **Complex Chain Cycles**: A -> B -> C -> D -> A
4. **Diamond Dependencies**: When a state tries to reference two states that share a common ancestor

### Validation Process

```dart
void _validateCircularReferences(ReactiveNotifier root) {
  final pathKeys = <Key>{};
  final ancestorKeys = <Key>{};

  // Collect all ancestors
  if (root.related != null) {
    for (final related in root.related!) {
      _collectAncestors(related, ancestorKeys);
    }
  }

  // Validate no node references an ancestor
  pathKeys.add(root.keyNotifier);
  _validateNodeReferences(root, pathKeys, ancestorKeys);
}
```

### Error Messages

When a circular reference is detected, you receive detailed error information:

```
Circular Reference Detected!

Location:
   Package: my_app
   File: services/shop_service.dart
   Line: 42

Dependency Cycle:
   String(Key<'A'>) -> String(Key<'B'>) -> String(Key<'C'>) -> String(Key<'A'>)

Current Notifier:
   Type: String
   Value: A
   Key: Key<'A'>

Problematic Child Notifier:
   Type: String
   Value: C
   Key: Key<'C'>

Problem:
   A circular dependency was detected in your state relationships.
   This creates an infinite loop in the following chain.

Solution:
   1. Review the state dependencies at the location shown above
   2. Ensure your states form a directed acyclic graph (DAG)
   3. Consider these alternatives:
      - Use a parent state to manage related states
      - Implement unidirectional data flow
      - Split the circular dependency into separate state trees
```

### Valid vs Invalid Structures

```dart
// VALID: Linear chain (no cycles)
final stateA = ReactiveNotifier<String>(() => 'A');
final stateB = ReactiveNotifier<String>(() => 'B', related: [stateA]); // OK

// INVALID: Diamond dependency
final stateA = ReactiveNotifier<String>(() => 'A');
final stateB1 = ReactiveNotifier<String>(() => 'B1', related: [stateA]);
final stateB2 = ReactiveNotifier<String>(() => 'B2', related: [stateA]);
final stateC = ReactiveNotifier<String>(
  () => 'C',
  related: [stateB1, stateB2], // ERROR: Both B1 and B2 reference A
);

// VALID: Independent chains merged at top
final chainA1 = ReactiveNotifier<String>(() => 'A1');
final chainA2 = ReactiveNotifier<String>(() => 'A2');
final combined = ReactiveNotifier<String>(
  () => 'Combined',
  related: [chainA1, chainA2], // OK: No shared ancestors
);
```

---

## Complete Usage Examples

### Example 1: E-Commerce Shop Service

```dart
// State models
class UserState {
  final String id;
  final String name;
  final bool isPremium;

  UserState({required this.id, required this.name, this.isPremium = false});
  UserState.guest() : id = '', name = 'Guest', isPremium = false;
}

class CartState {
  final List<CartItem> items;

  CartState(this.items);
  CartState.empty() : items = [];

  int get itemCount => items.length;
  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
}

class DiscountState {
  final double percentage;
  final String? code;

  DiscountState({this.percentage = 0, this.code});
}

// Service with Related States
mixin ShopService {
  // Independent child states
  static final userState = ReactiveNotifier<UserState>(() => UserState.guest());
  static final cartState = ReactiveNotifier<CartState>(() => CartState.empty());
  static final discountState = ReactiveNotifier<DiscountState>(() => DiscountState());

  // Combined shop state - automatically notified when any child updates
  static final shopState = ReactiveNotifier<String>(
    () => 'Shop Ready',
    related: [userState, cartState, discountState],
  );

  // Calculate total using related states
  static double calculateTotal() {
    final cart = shopState.from<CartState>();
    final discount = shopState.from<DiscountState>();
    final user = shopState.from<UserState>();

    var total = cart.subtotal;

    // Apply discount
    total -= total * (discount.percentage / 100);

    // Premium user bonus discount
    if (user.isPremium) {
      total -= total * 0.05; // Extra 5% for premium
    }

    return total;
  }

  // Login user
  static void login(String id, String name, bool isPremium) {
    userState.updateState(UserState(id: id, name: name, isPremium: isPremium));
    // shopState listeners automatically notified
  }

  // Add to cart
  static void addToCart(CartItem item) {
    final currentCart = cartState.notifier;
    cartState.updateState(CartState([...currentCart.items, item]));
    // shopState listeners automatically notified
  }

  // Apply discount code
  static void applyDiscount(String code, double percentage) {
    discountState.updateState(DiscountState(code: code, percentage: percentage));
    // shopState listeners automatically notified
  }
}

// Widget usage
class ShopSummaryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<String>(
      notifier: ShopService.shopState,
      build: (status, notifier, keep) {
        // Access all related states through parent
        final user = notifier.from<UserState>();
        final cart = notifier.from<CartState>();
        final discount = notifier.from<DiscountState>();

        return Card(
          child: Column(
            children: [
              Text('Welcome, ${user.name}${user.isPremium ? " (Premium)" : ""}'),
              Text('Items in cart: ${cart.itemCount}'),
              Text('Subtotal: \$${cart.subtotal.toStringAsFixed(2)}'),
              if (discount.percentage > 0)
                Text('Discount: ${discount.percentage}% (${discount.code})'),
              Text(
                'Total: \$${ShopService.calculateTotal().toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Example 2: Dashboard with Multiple Data Sources

```dart
// State models
class SalesData {
  final double total;
  final int transactions;
  SalesData({this.total = 0, this.transactions = 0});
}

class InventoryData {
  final int inStock;
  final int lowStock;
  InventoryData({this.inStock = 0, this.lowStock = 0});
}

class CustomerData {
  final int active;
  final int newToday;
  CustomerData({this.active = 0, this.newToday = 0});
}

// Dashboard Service
mixin DashboardService {
  // Independent data sources
  static final salesData = ReactiveNotifier<SalesData>(() => SalesData());
  static final inventoryData = ReactiveNotifier<InventoryData>(() => InventoryData());
  static final customerData = ReactiveNotifier<CustomerData>(() => CustomerData());

  // Dashboard aggregate - updates when any data source changes
  static final dashboardState = ReactiveNotifier<String>(
    () => 'Dashboard',
    related: [salesData, inventoryData, customerData],
  );

  // Refresh all data
  static Future<void> refreshAll() async {
    // Fetch data from APIs
    final sales = await SalesApi.fetchToday();
    final inventory = await InventoryApi.fetchCurrent();
    final customers = await CustomerApi.fetchStats();

    // Update all states - dashboard notified 3 times
    salesData.updateState(sales);
    inventoryData.updateState(inventory);
    customerData.updateState(customers);
  }
}

// Single dashboard widget that rebuilds on any data change
class DashboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<String>(
      notifier: DashboardService.dashboardState,
      build: (_, notifier, keep) {
        final sales = notifier.from<SalesData>();
        final inventory = notifier.from<InventoryData>();
        final customers = notifier.from<CustomerData>();

        return GridView.count(
          crossAxisCount: 3,
          children: [
            DashboardCard(
              title: 'Sales Today',
              value: '\$${sales.total.toStringAsFixed(2)}',
              subtitle: '${sales.transactions} transactions',
            ),
            DashboardCard(
              title: 'Inventory',
              value: '${inventory.inStock}',
              subtitle: '${inventory.lowStock} low stock alerts',
            ),
            DashboardCard(
              title: 'Customers',
              value: '${customers.active}',
              subtitle: '${customers.newToday} new today',
            ),
          ],
        );
      },
    );
  }
}
```

---

## Best Practices

### 1. Use Mixins for Service Organization

Always organize related states within mixins:

```dart
// GOOD: Organized in mixin
mixin OrderService {
  static final userState = ReactiveNotifier<UserState>(() => UserState.guest());
  static final cartState = ReactiveNotifier<CartState>(() => CartState.empty());
  static final orderState = ReactiveNotifier<OrderState>(
    () => OrderState.initial(),
    related: [userState, cartState],
  );
}

// BAD: Global variables
final userState = ReactiveNotifier<UserState>(() => UserState.guest());
final orderState = ReactiveNotifier<OrderState>(
  () => OrderState.initial(),
  related: [userState],
);
```

### 2. Keep Relationship Depth Shallow

Avoid deeply nested relationships:

```dart
// GOOD: Flat structure with one parent
final stateA = ReactiveNotifier<A>(() => A());
final stateB = ReactiveNotifier<B>(() => B());
final stateC = ReactiveNotifier<C>(() => C());
final combined = ReactiveNotifier<Combined>(
  () => Combined(),
  related: [stateA, stateB, stateC],
);

// AVOID: Deep nesting (even though technically allowed)
final level1 = ReactiveNotifier<L1>(() => L1());
final level2 = ReactiveNotifier<L2>(() => L2(), related: [level1]);
final level3 = ReactiveNotifier<L3>(() => L3(), related: [level2]);
// level1 change triggers level2 AND level3
```

### 3. Use Distinct Types for Related States

Prefer distinct types to avoid key-based lookups:

```dart
// GOOD: Distinct types
class UserData { /* ... */ }
class CartData { /* ... */ }
class SettingsData { /* ... */ }

final combined = ReactiveNotifier<Combined>(
  () => Combined(),
  related: [userNotifier, cartNotifier, settingsNotifier],
);

// Access is simple and type-safe
final user = combined.from<UserData>();
final cart = combined.from<CartData>();
```

### 4. Handle Notifications Efficiently

Remember that each child update triggers parent notification:

```dart
// If you need to update multiple children without multiple parent notifications,
// consider updating silently and then forcing a single notification:

cartState.updateSilently(newCart);
totalState.updateSilently(newTotal);
discountState.updateSilently(newDiscount);

// Force single parent update
parentState.notifyListeners();
```

### 5. Access Related States in Builders, Not Externally

Always access related states through builders for reactive updates:

```dart
// GOOD: Inside builder - reactive
ReactiveBuilder<CombinedState>(
  notifier: MyService.combinedState,
  build: (state, notifier, keep) {
    final user = notifier.from<UserState>(); // Reactive access
    return Text(user.name);
  },
)

// AVOID: Outside builder - not reactive
final user = MyService.combinedState.from<UserState>();
// This value won't update automatically
```

---

## Common Patterns

### Shop Service Pattern

The most common use case combining user, cart, and order states:

```dart
mixin ShopService {
  // User state
  static final _userNotifier = ReactiveNotifier<UserViewModel>(
    () => UserViewModel(),
  );
  static ReactiveNotifier<UserViewModel> get user => _userNotifier;

  // Cart state
  static final _cartNotifier = ReactiveNotifier<CartViewModel>(
    () => CartViewModel(),
  );
  static ReactiveNotifier<CartViewModel> get cart => _cartNotifier;

  // Combined shop state with related states
  static final _shopNotifier = ReactiveNotifier<ShopViewModel>(
    () => ShopViewModel(),
    related: [_userNotifier, _cartNotifier],
  );
  static ReactiveNotifier<ShopViewModel> get shop => _shopNotifier;

  // Convenience method to access user from shop
  static UserViewModel get currentUser => _shopNotifier.from<UserViewModel>();

  // Convenience method to access cart from shop
  static CartViewModel get currentCart => _shopNotifier.from<CartViewModel>();
}
```

### Multi-Source Dashboard Pattern

For dashboards aggregating multiple data sources:

```dart
mixin DashboardService {
  static final salesMetrics = ReactiveNotifier<SalesMetrics>(() => SalesMetrics());
  static final userMetrics = ReactiveNotifier<UserMetrics>(() => UserMetrics());
  static final systemMetrics = ReactiveNotifier<SystemMetrics>(() => SystemMetrics());

  // Dashboard notified when ANY metric updates
  static final dashboard = ReactiveNotifier<DashboardState>(
    () => DashboardState.loading(),
    related: [salesMetrics, userMetrics, systemMetrics],
  );
}
```

### Form State Aggregation Pattern

For complex forms with multiple sections:

```dart
mixin FormService {
  static final personalInfo = ReactiveNotifier<PersonalInfoState>(() => PersonalInfoState());
  static final addressInfo = ReactiveNotifier<AddressState>(() => AddressState());
  static final paymentInfo = ReactiveNotifier<PaymentState>(() => PaymentState());

  // Form validity updates when any section changes
  static final formState = ReactiveNotifier<FormState>(
    () => FormState.initial(),
    related: [personalInfo, addressInfo, paymentInfo],
  );

  static bool get isFormValid {
    final personal = formState.from<PersonalInfoState>();
    final address = formState.from<AddressState>();
    final payment = formState.from<PaymentState>();

    return personal.isValid && address.isValid && payment.isValid;
  }
}
```

---

## Summary

Related States is a powerful feature for:

- Creating aggregate/combined states from multiple independent states
- Automatic notification propagation from child to parent
- Type-safe access to dependent states via `from<R>()`
- Preventing memory leaks and infinite loops through circular reference detection

Use this feature when you need a single point of observation for multiple related data sources, such as dashboards, shopping carts, or complex forms.
