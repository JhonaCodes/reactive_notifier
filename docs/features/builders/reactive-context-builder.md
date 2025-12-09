# ReactiveContextBuilder

## Overview

`ReactiveContextBuilder` is a specialized widget that forces the InheritedWidget strategy for specified ReactiveNotifiers, providing maximum performance for known reactive dependencies.

## Purpose

While ReactiveNotifier automatically selects the optimal rebuild strategy (InheritedWidget vs markNeedsBuild), `ReactiveContextBuilder` allows you to explicitly force the InheritedWidget strategy for better control and performance in specific scenarios.

## When to Use

| Scenario | Use ReactiveContextBuilder |
|----------|---------------------------|
| Multiple widgets sharing same notifier | Yes |
| Performance-critical sections | Yes |
| Explicit rebuild control needed | Yes |
| Simple single-widget usage | No (use ReactiveBuilder) |
| Dynamic notifier switching | No |

## Signature

```dart
class ReactiveContextBuilder extends StatelessWidget {
  final Widget child;
  final List<ReactiveNotifier> forceInheritedFor;

  const ReactiveContextBuilder({
    super.key,
    required this.child,
    required this.forceInheritedFor,
  });
}
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `child` | `Widget` | Yes | The widget tree that will have access to the reactive context |
| `forceInheritedFor` | `List<ReactiveNotifier>` | Yes | List of notifiers to force InheritedWidget strategy |

## Source Implementation

```dart
// From lib/src/context/reactive_context_enhanced.dart (lines 170-200)
class ReactiveContextBuilder extends StatelessWidget {
  final Widget child;
  final List<ReactiveNotifier> forceInheritedFor;

  const ReactiveContextBuilder({
    super.key,
    required this.child,
    required this.forceInheritedFor,
  });

  @override
  Widget build(BuildContext context) {
    Widget current = child;

    // Create InheritedWidgets for all specified notifiers
    for (final notifier in forceInheritedFor.reversed) {
      current = _createInheritedWidget(notifier, current);
    }

    return current;
  }

  Widget _createInheritedWidget(ReactiveNotifier notifier, Widget child) {
    return ReactiveInheritedContext(
      notifier: notifier,
      contextType: notifier.notifier.runtimeType,
      child: child,
    );
  }
}
```

## Usage Example

### Basic Usage

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveContextBuilder(
      forceInheritedFor: [
        UserService.userState,
        ThemeService.themeState,
        CartService.cartState,
      ],
      child: Scaffold(
        appBar: AppBar(title: Text('My Page')),
        body: Column(
          children: [
            UserInfoWidget(),
            ThemePreviewWidget(),
            CartSummaryWidget(),
          ],
        ),
      ),
    );
  }
}
```

### With Nested Widgets

```dart
class ShoppingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveContextBuilder(
      forceInheritedFor: [
        CartService.cartState,
        ProductService.productsState,
      ],
      child: Column(
        children: [
          // All these widgets efficiently share the same InheritedWidget
          CartHeader(),
          ProductGrid(),
          CartSummary(),
          CheckoutButton(),
        ],
      ),
    );
  }
}
```

### Scoped Context

```dart
class ProductSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Only products context for this section
    return ReactiveContextBuilder(
      forceInheritedFor: [ProductService.productsState],
      child: Column(
        children: [
          ProductFilter(),
          ProductList(),
          ProductPagination(),
        ],
      ),
    );
  }
}
```

## Rebuild Strategy Comparison

### markNeedsBuild Strategy (Default)

```
Widget A uses notifier X
Widget B uses notifier X
Widget C uses notifier X

State change in X:
  -> Widget A.markNeedsBuild()
  -> Widget B.markNeedsBuild()
  -> Widget C.markNeedsBuild()
  -> Each widget rebuilds independently
```

### InheritedWidget Strategy (ReactiveContextBuilder)

```
ReactiveContextBuilder (InheritedWidget for X)
  -> Widget A (depends on X)
  -> Widget B (depends on X)
  -> Widget C (depends on X)

State change in X:
  -> InheritedWidget notifies dependents
  -> Single efficient rebuild pass
  -> Widgets rebuild only if truly dependent
```

## Performance Considerations

### Benefits

1. **Reduced Overhead**: Single InheritedWidget vs multiple listeners
2. **Efficient Dependency Tracking**: Flutter's built-in dependency system
3. **Batched Updates**: Updates batched in single frame
4. **Memory Efficient**: Shared context instance

### When NOT to Use

1. **Single Widget**: Overhead doesn't justify for single consumer
2. **Dynamic Notifiers**: Not suited for frequently changing notifiers
3. **Deep Nesting**: May add unnecessary widget depth
4. **Simple Cases**: ReactiveBuilder is simpler for basic usage

## Best Practices

### 1. Group Related Notifiers

```dart
// GOOD - Related notifiers together
ReactiveContextBuilder(
  forceInheritedFor: [
    ShopService.products,
    ShopService.categories,
    ShopService.filters,
  ],
  child: ShopContent(),
)

// AVOID - Unrelated notifiers
ReactiveContextBuilder(
  forceInheritedFor: [
    ShopService.products,
    AuthService.user,        // Different domain
    SettingsService.theme,   // Different domain
  ],
  child: ShopContent(),
)
```

### 2. Scope Appropriately

```dart
// GOOD - Scoped to relevant section
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: ReactiveContextBuilder(
        forceInheritedFor: [ProductService.products],
        child: ProductList(),  // Only product-related widgets
      ),
    );
  }
}

// AVOID - Too broad scope
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Too broad - affects entire app tree
    return ReactiveContextBuilder(
      forceInheritedFor: [ProductService.products],
      child: MaterialApp(...),
    );
  }
}
```

### 3. Combine with Regular Builders

```dart
class HybridPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Use ReactiveContextBuilder for shared state
        ReactiveContextBuilder(
          forceInheritedFor: [UserService.userState],
          child: Column(
            children: [
              UserHeader(),
              UserStats(),
              UserActions(),
            ],
          ),
        ),

        // Use regular ReactiveBuilder for isolated state
        ReactiveBuilder<int>(
          notifier: CounterService.count,
          build: (count, notifier, keep) => Text('Count: $count'),
        ),
      ],
    );
  }
}
```

## Internal Mechanism

### How It Works

1. **Widget Creation**: Creates nested `ReactiveInheritedContext` widgets
2. **Registration**: Each notifier is registered in the context registry
3. **Dependency Tracking**: Child widgets automatically become dependents
4. **Update Propagation**: State changes notify all dependents efficiently

### Element Tracking

```dart
// Enhanced element tracking prevents cross-rebuilds
static final Map<ReactiveNotifier, Set<Element>> _markNeedsBuildElements = {};

// Only elements for specific notifier rebuild
void _notifyDependents(ReactiveNotifier notifier) {
  final elements = _markNeedsBuildElements[notifier];
  for (final elem in elements ?? {}) {
    if (elem.mounted) {
      elem.markNeedsBuild();
    }
  }
}
```

## Comparison with Other Builders

| Builder | Strategy | Use Case |
|---------|----------|----------|
| `ReactiveBuilder` | Auto (markNeedsBuild) | Single widget, simple state |
| `ReactiveViewModelBuilder` | Auto | ViewModel with business logic |
| `ReactiveAsyncBuilder` | Auto | Async operations |
| `ReactiveContextBuilder` | Forced InheritedWidget | Multiple shared consumers |

## Example: Dashboard with Shared State

```dart
mixin DashboardService {
  static final ReactiveNotifier<UserViewModel> user =
      ReactiveNotifier(() => UserViewModel());
  static final ReactiveNotifier<StatsViewModel> stats =
      ReactiveNotifier(() => StatsViewModel());
  static final ReactiveNotifier<NotificationsViewModel> notifications =
      ReactiveNotifier(() => NotificationsViewModel());
}

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveContextBuilder(
      forceInheritedFor: [
        DashboardService.user,
        DashboardService.stats,
        DashboardService.notifications,
      ],
      child: Scaffold(
        appBar: DashboardAppBar(),       // Uses user, notifications
        body: Column(
          children: [
            UserWelcomeCard(),           // Uses user
            StatsSummary(),              // Uses stats
            NotificationsList(),         // Uses notifications
            QuickActions(),              // Uses user, stats
          ],
        ),
        bottomNavigationBar: DashboardNav(), // Uses notifications count
      ),
    );
  }
}
```

## Related

- [ReactiveBuilder](../builders.md#reactivebuilder) - Standard reactive builder
- [ReactiveViewModelBuilder](../builders.md#reactiveviewmodelbuilder) - ViewModel builder
- [Context Access](../context-access.md) - Context system overview
