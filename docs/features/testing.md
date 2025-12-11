# Testing ReactiveNotifier Applications

This comprehensive guide covers testing patterns, utilities, and best practices for ReactiveNotifier applications. From unit testing ViewModels to widget testing with builders, this documentation provides everything you need to write reliable, maintainable tests.

---

## Table of Contents

1. [Overview](#overview)
2. [Setup and Teardown](#setup-and-teardown)
3. [Setting Test State](#setting-test-state)
4. [Testing ViewModels](#testing-viewmodels)
5. [Testing AsyncViewModels](#testing-asyncviewmodels)
6. [Context in Tests](#context-in-tests)
7. [Widget Testing with Builders](#widget-testing-with-builders)
8. [Complete Test Examples](#complete-test-examples)
9. [Best Practices](#best-practices)
10. [Common Testing Patterns](#common-testing-patterns)

---

## Overview

ReactiveNotifier provides testing utilities designed around its singleton-based "create once, reuse always" philosophy. The testing approach emphasizes:

- **Clean State**: Each test starts with a fresh state using `ReactiveNotifier.cleanup()`
- **Direct State Manipulation**: Use `updateSilently()` to set test data without triggering notifications
- **Context Registration**: `registerContextForTesting()` for ViewModels requiring BuildContext
- **Minimal Mocking**: Test actual services and ViewModels rather than complex mocks

### Testing Utilities at a Glance

| Utility | Purpose | Location |
|---------|---------|----------|
| `ReactiveNotifier.cleanup()` | Clear all singleton instances | `reactive_notifier.dart` |
| `registerContextForTesting()` | Register BuildContext for tests | `viewmodel_context_notifier.dart` |
| `updateSilently()` | Set state without notifications | All state holders |
| `@visibleForTesting parents` | Access parent relationships | `reactive_notifier.dart` |
| `loadingState()` | Set loading state (protected) | `async_viewmodel_impl.dart` |

---

## Setup and Teardown

### ReactiveNotifier.cleanup()

The `cleanup()` method is the cornerstone of testing. It clears all singleton instances, disposes ViewModels, and resets the global registries.

**Source Implementation** (`lib/src/notifier/reactive_notifier.dart`):

```dart
static void cleanup() {
  // 1. Dispose all ViewModels and AsyncViewModels properly
  for (final instance in _instances.values.toList()) {
    if (instance is ReactiveNotifier) {
      final vm = instance.notifier;
      if (vm is ViewModel && !vm.isDisposed) {
        vm.dispose();
      } else if (vm is AsyncViewModelImpl && !vm.isDisposed) {
        vm.dispose();
      }
    }
  }

  // 2. Clear all global registries
  _instances.clear();
  _updatingNotifiers.clear();
  _instanceRegistry.clear();

  // 3. Clear context registries
  ReactiveContextEnhanced.cleanup();
  ViewModelContextNotifier.cleanup();
}
```

### Standard Test Setup Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

void main() {
  group('MyFeature Tests', () {
    // Recommended: Use tearDown to ensure cleanup happens even if tests fail
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    // Alternative: Use setUp for pre-test cleanup
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    test('my test case', () {
      // Test implementation
    });
  });
}
```

### Service Reset Pattern

For services with lazily initialized instances, create a `createNew()` method:

```dart
mixin UserService {
  static ReactiveNotifier<UserViewModel>? _instance;

  static ReactiveNotifier<UserViewModel> get instance {
    _instance ??= ReactiveNotifier<UserViewModel>(UserViewModel.new);
    return _instance!;
  }

  // Essential for testing - creates completely fresh instance
  static ReactiveNotifier<UserViewModel> createNew() {
    _instance = ReactiveNotifier<UserViewModel>(UserViewModel.new);
    return _instance!;
  }
}

// In tests
setUp(() {
  ReactiveNotifier.cleanup();
  UserService.createNew();  // Fresh instance for each test
});
```

---

## Setting Test State

### Using updateSilently()

The `updateSilently()` method updates state without triggering listener notifications. This is essential for setting up test data without causing unintended side effects.

```dart
test('should process data correctly', () {
  // Arrange: Set up test state silently
  final viewModel = MyViewModel();
  viewModel.updateSilently(TestData(
    id: 'test-123',
    name: 'Test Item',
    status: 'active',
  ));

  // Act: Perform the operation being tested
  viewModel.processData();

  // Assert: Verify the result
  expect(viewModel.data.processedStatus, equals('ACTIVE'));
});
```

### Direct State Manipulation for ReactiveNotifier

```dart
test('should calculate total correctly', () {
  // Setup: Create and populate state
  final cartState = ReactiveNotifier<CartModel>(() => CartModel.empty());

  // Set test data silently
  cartState.updateSilently(CartModel(
    items: [
      CartItem(price: 10.0, quantity: 2),
      CartItem(price: 25.0, quantity: 1),
    ],
  ));

  // Assert
  expect(cartState.notifier.total, equals(45.0));
});
```

### Using transformStateSilently()

For complex state transformations without notifications:

```dart
test('should filter items correctly', () {
  final viewModel = ItemListViewModel();

  // Set up initial state
  viewModel.updateSilently(ItemList(items: testItems));

  // Transform state silently for test setup
  viewModel.transformStateSilently((state) => state.copyWith(
    filter: FilterType.active,
  ));

  // Now test the filtering logic
  expect(viewModel.data.visibleItems.length, equals(5));
});
```

---

## Testing ViewModels

### Testing the init() Method

The `init()` method is called once during ViewModel creation. Test it by verifying the initial state after construction.

```dart
class CounterViewModel extends ViewModel<CounterState> {
  int initCallCount = 0;

  CounterViewModel() : super(CounterState.initial());

  @override
  void init() {
    initCallCount++;
    updateSilently(CounterState(count: 0, initialized: true));
  }
}

test('should call init() once during construction', () {
  final viewModel = CounterViewModel();

  expect(viewModel.initCallCount, equals(1));
  expect(viewModel.data.initialized, isTrue);
  expect(viewModel.data.count, equals(0));
});
```

### Testing State Updates

```dart
test('should update state and notify listeners', () {
  // Arrange
  final viewModel = CounterViewModel();
  var notificationCount = 0;

  viewModel.addListener(() {
    notificationCount++;
  });

  // Act
  viewModel.updateState(CounterState(count: 5, initialized: true));

  // Assert
  expect(viewModel.data.count, equals(5));
  expect(notificationCount, equals(1));
});

test('should update state silently without notifying', () {
  // Arrange
  final viewModel = CounterViewModel();
  var notificationCount = 0;

  viewModel.addListener(() {
    notificationCount++;
  });

  // Act
  viewModel.updateSilently(CounterState(count: 10, initialized: true));

  // Assert
  expect(viewModel.data.count, equals(10));
  expect(notificationCount, equals(0));  // No notification
});
```

### Testing State Transformations

```dart
test('should transform state correctly', () {
  // Arrange
  final viewModel = CounterViewModel();
  viewModel.updateSilently(CounterState(count: 5, initialized: true));

  // Act
  viewModel.transformState((state) => state.copyWith(
    count: state.count * 2,
  ));

  // Assert
  expect(viewModel.data.count, equals(10));
});

test('should transform state silently', () {
  // Arrange
  final viewModel = CounterViewModel();
  var notificationCount = 0;
  viewModel.addListener(() => notificationCount++);
  viewModel.updateSilently(CounterState(count: 3, initialized: true));

  // Act
  viewModel.transformStateSilently((state) => state.copyWith(
    count: state.count + 7,
  ));

  // Assert
  expect(viewModel.data.count, equals(10));
  expect(notificationCount, equals(0));  // No notification
});
```

### Testing Cross-ViewModel Communication with listenVM

```dart
class SourceViewModel extends ViewModel<String> {
  SourceViewModel() : super('initial');

  @override
  void init() {}
}

class DependentViewModel extends ViewModel<String> {
  String? receivedValue;
  int updateCount = 0;

  DependentViewModel() : super('dependent_initial');

  @override
  void init() {}

  void listenToSource(SourceViewModel source) {
    source.listenVM((value) {
      updateCount++;
      receivedValue = value;
      updateState('reacting_to_$value');
    }, callOnInit: true);
  }
}

test('should receive updates via listenVM', () {
  // Arrange
  final source = SourceViewModel();
  final dependent = DependentViewModel();

  // Act: Setup reactive communication
  dependent.listenToSource(source);

  // Assert: Should receive initial value
  expect(dependent.receivedValue, equals('initial'));
  expect(dependent.updateCount, equals(1));

  // Act: Update source
  source.updateState('updated');

  // Assert: Should receive update
  expect(dependent.receivedValue, equals('updated'));
  expect(dependent.updateCount, equals(2));
  expect(dependent.data, equals('reacting_to_updated'));
});
```

### Testing Listener Lifecycle

```dart
class TestableViewModel extends ViewModel<String> {
  int setupListenersCount = 0;
  int removeListenersCount = 0;

  TestableViewModel() : super('initial');

  @override
  void init() {}

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    setupListenersCount++;
    await super.setupListeners(currentListeners: currentListeners);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    removeListenersCount++;
    await super.removeListeners(currentListeners: currentListeners);
  }
}

test('should call setupListeners during initialization', () {
  final viewModel = TestableViewModel();

  expect(viewModel.setupListenersCount, equals(1));
});

test('should call removeListeners during dispose', () {
  final viewModel = TestableViewModel();

  viewModel.dispose();

  expect(viewModel.removeListenersCount, equals(1));
  expect(viewModel.isDisposed, isTrue);
});
```

---

## Testing AsyncViewModels

### Testing Async init()

```dart
class DataViewModel extends AsyncViewModelImpl<List<String>> {
  int initCallCount = 0;
  final List<String> testData;

  DataViewModel({required this.testData, bool loadOnInit = true})
      : super(AsyncState.initial(), loadOnInit: loadOnInit);

  @override
  Future<List<String>> init() async {
    initCallCount++;
    // Simulate async operation
    await Future.delayed(Duration(milliseconds: 10));
    return testData;
  }
}

test('should initialize with loadOnInit: true', () async {
  // Arrange & Act
  final viewModel = DataViewModel(testData: ['item1', 'item2']);

  // Wait for async initialization
  await Future.delayed(Duration(milliseconds: 50));

  // Assert
  expect(viewModel.initCallCount, equals(1));
  expect(viewModel.hasData, isTrue);
  expect(viewModel.data, equals(['item1', 'item2']));
});

test('should not initialize with loadOnInit: false', () async {
  // Arrange & Act
  final viewModel = DataViewModel(
    testData: ['item1', 'item2'],
    loadOnInit: false,
  );

  // Wait to ensure nothing happens
  await Future.delayed(Duration(milliseconds: 50));

  // Assert
  expect(viewModel.initCallCount, equals(0));
  expect(viewModel.isInitial, isTrue);
  expect(viewModel.hasData, isFalse);
});
```

### Testing Loading States

```dart
test('should transition through loading state', () async {
  // Arrange
  final viewModel = DataViewModel(
    testData: ['data'],
    loadOnInit: false,
  );
  final states = <String>[];

  viewModel.addListener(() {
    if (viewModel.isLoading) states.add('loading');
    if (viewModel.hasData) states.add('success');
    if (viewModel.isError) states.add('error');
  });

  // Act
  await viewModel.reload();

  // Assert
  expect(states, contains('loading'));
  expect(states, contains('success'));
});

test('should set loading state explicitly', () {
  // Arrange
  final viewModel = DataViewModel(
    testData: ['data'],
    loadOnInit: false,
  );

  // Act - using testLoadingState() helper for protected method
  viewModel.loadingState();  // Note: This is @protected/@visibleForTesting

  // Assert
  expect(viewModel.isLoading, isTrue);
  expect(viewModel.hasData, isFalse);
});
```

### Testing Error States

```dart
class FailingViewModel extends AsyncViewModelImpl<String> {
  bool shouldFail = true;

  FailingViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<String> init() async {
    if (shouldFail) {
      throw Exception('Initialization failed');
    }
    return 'success';
  }
}

test('should handle init() errors gracefully', () async {
  // Arrange
  final viewModel = FailingViewModel();

  // Act
  await viewModel.reload();

  // Assert
  expect(viewModel.isError, isTrue);
  expect(viewModel.error, isA<Exception>());
  expect(viewModel.error.toString(), contains('Initialization failed'));
});

test('should recover from error state', () async {
  // Arrange
  final viewModel = FailingViewModel();
  await viewModel.reload();  // Will fail
  expect(viewModel.isError, isTrue);

  // Act: Fix the condition and reload
  viewModel.shouldFail = false;
  await viewModel.reload();

  // Assert
  expect(viewModel.isError, isFalse);
  expect(viewModel.hasData, isTrue);
  expect(viewModel.data, equals('success'));
});
```

### Testing Data Transformations in AsyncViewModel

```dart
test('should transform data with transformDataState', () async {
  // Arrange
  final viewModel = DataViewModel(
    testData: [1, 2, 3],
    loadOnInit: false,
  );
  viewModel.updateState([1, 2, 3]);

  // Act
  viewModel.transformDataState((data) => [...?data, 4, 5]);

  // Assert
  expect(viewModel.data, equals([1, 2, 3, 4, 5]));
});

test('should transform data silently', () async {
  // Arrange
  final viewModel = DataViewModel(testData: [10, 20], loadOnInit: false);
  viewModel.updateState([10, 20]);
  var notificationCount = 0;
  viewModel.addListener(() => notificationCount++);

  // Act
  viewModel.transformDataStateSilently((data) =>
    data?.map((e) => e * 2).toList() ?? []
  );

  // Assert
  expect(viewModel.data, equals([20, 40]));
  expect(notificationCount, equals(0));  // No notification
});
```

---

## Context in Tests

### Using registerContextForTesting()

For ViewModels that require BuildContext access, use `registerContextForTesting()` from `ViewModelContextNotifier`:

**Source** (`lib/src/context/viewmodel_context_notifier.dart`):

```dart
/// Register context for specific ViewModel - used for testing
static void registerContextForTesting(
    BuildContext context, String builderType, Object? viewModel) {
  _registerContext(context, builderType, viewModel);
}
```

### Widget Test with Context

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

class ThemeAwareViewModel extends ViewModel<String> {
  ThemeAwareViewModel() : super('initial');

  @override
  void init() {
    if (hasContext) {
      final theme = Theme.of(requireContext('theme access'));
      updateSilently(theme.brightness == Brightness.dark ? 'dark' : 'light');
    } else {
      updateSilently('no_context');
    }
  }
}

testWidgets('ViewModel receives context via builder', (tester) async {
  // Arrange
  ReactiveNotifier.cleanup();
  final notifier = ReactiveNotifier<ThemeAwareViewModel>(
    () => ThemeAwareViewModel(),
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: ReactiveViewModelBuilder<ThemeAwareViewModel, String>(
        viewmodel: notifier.notifier,
        build: (state, viewModel, keep) => Text('Theme: $state'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Assert
  expect(notifier.notifier.hasContext, isTrue);
});
```

### Manual Context Registration for Unit Tests

For unit tests that need context without widget tree:

```dart
testWidgets('ViewModel with manual context registration', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          // Register context manually for testing
          ViewModelContextNotifier.registerContextForTesting(
            context,
            'TestBuilder',
            myViewModel,
          );
          return const SizedBox();
        },
      ),
    ),
  );

  await tester.pump();

  // ViewModel now has context
  expect(myViewModel.hasContext, isTrue);
});
```

### Testing Context Lifecycle

```dart
testWidgets('Context becomes null when builder disposes', (tester) async {
  // Arrange
  ReactiveNotifier.cleanup();
  final notifier = ReactiveNotifier<MyViewModel>(() => MyViewModel());

  // Build widget with builder
  await tester.pumpWidget(
    MaterialApp(
      home: ReactiveViewModelBuilder<MyViewModel, String>(
        viewmodel: notifier.notifier,
        build: (state, vm, keep) => Text(state),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Verify context available
  expect(notifier.notifier.hasContext, isTrue);

  // Remove widget (dispose builder)
  await tester.pumpWidget(
    const MaterialApp(home: Text('No Builder')),
  );
  await tester.pumpAndSettle();

  // Context should be null
  expect(notifier.notifier.hasContext, isFalse);
  expect(notifier.notifier.context, isNull);
});
```

---

## Widget Testing with Builders

### Testing ReactiveBuilder

```dart
testWidgets('ReactiveBuilder rebuilds on state change', (tester) async {
  // Arrange
  ReactiveNotifier.cleanup();
  final counterState = ReactiveNotifier<int>(() => 0);

  await tester.pumpWidget(
    MaterialApp(
      home: ReactiveBuilder<int>(
        notifier: counterState,
        build: (count, notifier, keep) => Text('Count: $count'),
      ),
    ),
  );

  // Assert initial state
  expect(find.text('Count: 0'), findsOneWidget);

  // Act: Update state
  counterState.updateState(5);
  await tester.pump();

  // Assert updated state
  expect(find.text('Count: 5'), findsOneWidget);
});
```

### Testing ReactiveViewModelBuilder

```dart
class CounterVM extends ViewModel<int> {
  CounterVM() : super(0);

  @override
  void init() {
    updateSilently(0);
  }

  void increment() => updateState(data + 1);
}

testWidgets('ReactiveViewModelBuilder provides viewmodel access', (tester) async {
  // Arrange
  ReactiveNotifier.cleanup();
  final vm = CounterVM();

  await tester.pumpWidget(
    MaterialApp(
      home: ReactiveViewModelBuilder<CounterVM, int>(
        viewmodel: vm,
        build: (count, viewModel, keep) => Column(
          children: [
            Text('Count: $count'),
            ElevatedButton(
              onPressed: viewModel.increment,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    ),
  );

  // Assert initial state
  expect(find.text('Count: 0'), findsOneWidget);

  // Act: Tap increment button
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Assert incremented
  expect(find.text('Count: 1'), findsOneWidget);
});
```

### Testing ReactiveAsyncBuilder

```dart
class ItemsVM extends AsyncViewModelImpl<List<String>> {
  ItemsVM() : super(AsyncState.initial());

  @override
  Future<List<String>> init() async {
    await Future.delayed(Duration(milliseconds: 10));
    return ['Item 1', 'Item 2', 'Item 3'];
  }
}

testWidgets('ReactiveAsyncBuilder handles all states', (tester) async {
  // Arrange
  ReactiveNotifier.cleanup();
  final notifier = ReactiveNotifier<ItemsVM>(() => ItemsVM());

  await tester.pumpWidget(
    MaterialApp(
      home: ReactiveAsyncBuilder<ItemsVM, List<String>>(
        notifier: notifier.notifier,
        onLoading: () => const Text('Loading...'),
        onError: (error, stack) => Text('Error: $error'),
        onData: (items, viewModel, keep) => Column(
          children: items.map((item) => Text(item)).toList(),
        ),
      ),
    ),
  );

  // Initially loading
  expect(find.text('Loading...'), findsOneWidget);

  // Wait for async initialization
  await tester.pumpAndSettle();

  // Assert data loaded
  expect(find.text('Item 1'), findsOneWidget);
  expect(find.text('Item 2'), findsOneWidget);
  expect(find.text('Item 3'), findsOneWidget);
});
```

### Testing the keep() Function

The `keep()` function prevents child widgets from rebuilding when the parent state changes:

```dart
testWidgets('keep() prevents unnecessary rebuilds', (tester) async {
  // Arrange
  ReactiveNotifier.cleanup();
  final state = ReactiveNotifier<int>(() => 0);
  int expensiveWidgetBuildCount = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: ReactiveBuilder<int>(
        notifier: state,
        build: (count, notifier, keep) => Column(
          children: [
            Text('Count: $count'),  // Rebuilds
            keep(
              Builder(builder: (context) {
                expensiveWidgetBuildCount++;
                return const Text('Expensive Widget');
              }),
            ),
          ],
        ),
      ),
    ),
  );

  final initialBuildCount = expensiveWidgetBuildCount;

  // Act: Update state multiple times
  state.updateState(1);
  await tester.pump();
  state.updateState(2);
  await tester.pump();
  state.updateState(3);
  await tester.pump();

  // Assert: Expensive widget never rebuilt
  expect(expensiveWidgetBuildCount, equals(initialBuildCount));
  expect(find.text('Count: 3'), findsOneWidget);
  expect(find.text('Expensive Widget'), findsOneWidget);
});
```

---

## Complete Test Examples

### Complete ViewModel Test Suite

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

// Model
class UserModel {
  final String id;
  final String name;
  final bool isActive;

  UserModel({required this.id, required this.name, this.isActive = false});

  UserModel copyWith({String? id, String? name, bool? isActive}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ViewModel
class UserViewModel extends ViewModel<UserModel> {
  int initCallCount = 0;

  UserViewModel() : super(UserModel(id: '', name: ''));

  @override
  void init() {
    initCallCount++;
    updateSilently(UserModel(id: 'user-1', name: 'Initial User'));
  }

  void activate() {
    transformState((user) => user.copyWith(isActive: true));
  }

  void updateName(String name) {
    transformState((user) => user.copyWith(name: name));
  }
}

// Service
mixin UserService {
  static ReactiveNotifier<UserViewModel>? _instance;

  static ReactiveNotifier<UserViewModel> get instance {
    _instance ??= ReactiveNotifier<UserViewModel>(UserViewModel.new);
    return _instance!;
  }

  static ReactiveNotifier<UserViewModel> createNew() {
    _instance = ReactiveNotifier<UserViewModel>(UserViewModel.new);
    return _instance!;
  }
}

void main() {
  group('UserViewModel Tests', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Initialization', () {
      test('should call init() once on construction', () {
        final vm = UserViewModel();

        expect(vm.initCallCount, equals(1));
        expect(vm.data.id, equals('user-1'));
        expect(vm.data.name, equals('Initial User'));
      });

      test('should start inactive', () {
        final vm = UserViewModel();

        expect(vm.data.isActive, isFalse);
      });
    });

    group('State Updates', () {
      test('should activate user', () {
        final vm = UserViewModel();

        vm.activate();

        expect(vm.data.isActive, isTrue);
      });

      test('should update name', () {
        final vm = UserViewModel();

        vm.updateName('New Name');

        expect(vm.data.name, equals('New Name'));
      });

      test('should notify listeners on state change', () {
        final vm = UserViewModel();
        var notificationCount = 0;

        vm.addListener(() => notificationCount++);
        vm.activate();

        expect(notificationCount, equals(1));
      });
    });

    group('Service Integration', () {
      setUp(() {
        ReactiveNotifier.cleanup();
        UserService.createNew();
      });

      test('should access ViewModel through service', () {
        final vm = UserService.instance.notifier;

        expect(vm.data.id, equals('user-1'));
      });

      test('should persist state across multiple accesses', () {
        final vm1 = UserService.instance.notifier;
        vm1.updateName('Modified Name');

        final vm2 = UserService.instance.notifier;

        expect(vm2.data.name, equals('Modified Name'));
        expect(identical(vm1, vm2), isTrue);
      });
    });
  });
}
```

### Complete AsyncViewModel Test Suite

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

// Model
class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});
}

// AsyncViewModel
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  final List<Product> mockData;
  final bool shouldFail;
  int initCallCount = 0;
  int setupListenersCount = 0;
  int removeListenersCount = 0;

  ProductsViewModel({
    required this.mockData,
    this.shouldFail = false,
    bool loadOnInit = true,
  }) : super(AsyncState.initial(), loadOnInit: loadOnInit);

  @override
  Future<List<Product>> init() async {
    initCallCount++;
    await Future.delayed(Duration(milliseconds: 10));

    if (shouldFail) {
      throw Exception('Failed to load products');
    }

    return mockData;
  }

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    setupListenersCount++;
    await super.setupListeners(currentListeners: currentListeners);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    removeListenersCount++;
    await super.removeListeners(currentListeners: currentListeners);
  }

  void addProduct(Product product) {
    if (hasData) {
      transformDataState((products) => [...?products, product]);
    }
  }
}

void main() {
  group('ProductsViewModel Tests', () {
    final testProducts = [
      Product(id: '1', name: 'Product 1', price: 10.0),
      Product(id: '2', name: 'Product 2', price: 20.0),
    ];

    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Initialization', () {
      test('should load data when loadOnInit is true', () async {
        final vm = ProductsViewModel(mockData: testProducts);

        await Future.delayed(Duration(milliseconds: 50));

        expect(vm.initCallCount, equals(1));
        expect(vm.hasData, isTrue);
        expect(vm.data!.length, equals(2));
      });

      test('should not load data when loadOnInit is false', () async {
        final vm = ProductsViewModel(
          mockData: testProducts,
          loadOnInit: false,
        );

        await Future.delayed(Duration(milliseconds: 50));

        expect(vm.initCallCount, equals(0));
        expect(vm.isInitial, isTrue);
      });

      test('should call setupListeners after init', () async {
        final vm = ProductsViewModel(mockData: testProducts);

        await Future.delayed(Duration(milliseconds: 50));

        expect(vm.setupListenersCount, equals(1));
      });
    });

    group('State Transitions', () {
      test('should transition through loading to success', () async {
        final vm = ProductsViewModel(
          mockData: testProducts,
          loadOnInit: false,
        );
        final states = <String>[];

        vm.addListener(() {
          if (vm.isLoading) states.add('loading');
          if (vm.hasData) states.add('success');
        });

        await vm.reload();

        expect(states, contains('loading'));
        expect(states.last, equals('success'));
      });

      test('should handle errors gracefully', () async {
        final vm = ProductsViewModel(
          mockData: testProducts,
          shouldFail: true,
          loadOnInit: false,
        );

        await vm.reload();

        expect(vm.isError, isTrue);
        expect(vm.error.toString(), contains('Failed to load products'));
      });
    });

    group('Data Transformations', () {
      test('should add product with transformDataState', () async {
        final vm = ProductsViewModel(mockData: testProducts);
        await Future.delayed(Duration(milliseconds: 50));

        final newProduct = Product(id: '3', name: 'Product 3', price: 30.0);
        vm.addProduct(newProduct);

        expect(vm.data!.length, equals(3));
        expect(vm.data!.last.id, equals('3'));
      });
    });

    group('Lifecycle', () {
      test('should call removeListeners on dispose', () async {
        final vm = ProductsViewModel(mockData: testProducts);
        await Future.delayed(Duration(milliseconds: 50));

        vm.dispose();

        expect(vm.removeListenersCount, equals(1));
        expect(vm.isDisposed, isTrue);
      });
    });
  });
}
```

### Complete Widget Test Suite

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

class TodoItem {
  final String id;
  final String title;
  final bool completed;

  TodoItem({required this.id, required this.title, this.completed = false});

  TodoItem copyWith({String? id, String? title, bool? completed}) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

class TodoViewModel extends ViewModel<List<TodoItem>> {
  TodoViewModel() : super([]);

  @override
  void init() {
    updateSilently([
      TodoItem(id: '1', title: 'Learn ReactiveNotifier'),
      TodoItem(id: '2', title: 'Write tests'),
    ]);
  }

  void toggleComplete(String id) {
    transformState((todos) => todos.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(completed: !todo.completed);
      }
      return todo;
    }).toList());
  }

  void addTodo(String title) {
    transformState((todos) => [
      ...todos,
      TodoItem(id: DateTime.now().toString(), title: title),
    ]);
  }
}

void main() {
  group('Todo Widget Tests', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    testWidgets('should display todo list', (tester) async {
      final vm = TodoViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactiveViewModelBuilder<TodoViewModel, List<TodoItem>>(
              viewmodel: vm,
              build: (todos, viewModel, keep) => ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(todos[index].title),
                  leading: Checkbox(
                    value: todos[index].completed,
                    onChanged: (_) => viewModel.toggleComplete(todos[index].id),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Learn ReactiveNotifier'), findsOneWidget);
      expect(find.text('Write tests'), findsOneWidget);
    });

    testWidgets('should toggle todo completion', (tester) async {
      final vm = TodoViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactiveViewModelBuilder<TodoViewModel, List<TodoItem>>(
              viewmodel: vm,
              build: (todos, viewModel, keep) => ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) => ListTile(
                  key: ValueKey(todos[index].id),
                  title: Text(todos[index].title),
                  leading: Checkbox(
                    value: todos[index].completed,
                    onChanged: (_) => viewModel.toggleComplete(todos[index].id),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Find and tap the first checkbox
      final checkbox = find.byType(Checkbox).first;
      await tester.tap(checkbox);
      await tester.pump();

      // Verify state changed
      expect(vm.data[0].completed, isTrue);
    });

    testWidgets('should add new todo', (tester) async {
      final vm = TodoViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactiveViewModelBuilder<TodoViewModel, List<TodoItem>>(
              viewmodel: vm,
              build: (todos, viewModel, keep) => Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(todos[index].title),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => viewModel.addTodo('New Task'),
                    child: const Text('Add Todo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Initially 2 items
      expect(find.byType(ListTile), findsNWidgets(2));

      // Add new todo
      await tester.tap(find.text('Add Todo'));
      await tester.pump();

      // Now 3 items
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('New Task'), findsOneWidget);
    });
  });
}
```

---

## Best Practices

### 1. Always Clean Up Between Tests

```dart
// Preferred: tearDown ensures cleanup even if test fails
tearDown(() {
  ReactiveNotifier.cleanup();
});

// Alternative: setUp for pre-test cleanup
setUp(() {
  ReactiveNotifier.cleanup();
  MyService.createNew();
});
```

### 2. Use updateSilently() for Test Setup

```dart
test('should process correctly', () {
  final vm = MyViewModel();

  // GOOD: Silent setup
  vm.updateSilently(TestData(value: 100));

  // BAD: Triggers notifications during setup
  // vm.updateState(TestData(value: 100));

  // Now test
  vm.process();
  expect(vm.data.processed, isTrue);
});
```

### 3. Test Real Services, Not Mocks

```dart
// GOOD: Test actual service behavior
test('should persist user data', () {
  UserService.createNew();
  final vm = UserService.instance.notifier;

  vm.updateName('Test User');

  expect(UserService.instance.notifier.data.name, equals('Test User'));
});

// AVOID: Complex mocking when unnecessary
```

### 4. Wait for Async Operations Properly

```dart
testWidgets('should load data', (tester) async {
  await tester.pumpWidget(MyWidget());

  // GOOD: Use pumpAndSettle for async operations
  await tester.pumpAndSettle();

  // GOOD: Use specific delays when needed
  await Future.delayed(Duration(milliseconds: 50));
  await tester.pump();

  expect(find.text('Data Loaded'), findsOneWidget);
});
```

### 5. Test State Transitions, Not Implementation

```dart
// GOOD: Test observable behavior
test('should be authenticated after login', () async {
  final vm = AuthViewModel();

  await vm.login('user', 'pass');

  expect(vm.data.isAuthenticated, isTrue);
});

// AVOID: Testing private implementation details
```

### 6. Use Helper Methods in Test ViewModels

```dart
class TestableAsyncVM extends AsyncViewModelImpl<String> {
  // Track calls for verification
  int initCallCount = 0;
  int setupListenersCount = 0;

  // Expose protected methods for testing
  void testLoadingState() => loadingState();

  // Helper to check state
  bool isInSuccessState() => match(
    initial: () => false,
    loading: () => false,
    success: (_) => true,
    empty: () => false,
    error: (_, __) => false,
  );
}
```

### 7. Verify Context Requirements Explicitly

```dart
testWidgets('ViewModel requires context for theme', (tester) async {
  // Test that context-dependent ViewModel works
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: ReactiveViewModelBuilder<ThemeVM, ThemeState>(
        viewmodel: vm,
        build: (state, vm, keep) => Text(state.themeName),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(vm.hasContext, isTrue);
  expect(vm.data.themeName, equals('dark'));
});

test('ViewModel throws clear error without context', () {
  final vm = ThemeVM();

  expect(
    () => vm.requireContext('theme access'),
    throwsA(isA<StateError>().having(
      (e) => e.message,
      'message',
      contains('BuildContext Required'),
    )),
  );
});
```

---

## Common Testing Patterns

### Pattern 1: Testing Related States

```dart
test('should notify parent when child state changes', () {
  // Arrange
  ReactiveNotifier.cleanup();

  final childState = ReactiveNotifier<int>(() => 0);
  final parentState = ReactiveNotifier<String>(
    () => 'parent',
    related: [childState],
  );

  var parentNotifications = 0;
  parentState.addListener(() => parentNotifications++);

  // Act
  childState.updateState(5);

  // Assert
  expect(parentNotifications, greaterThan(0));

  // Verify parent relationship (using @visibleForTesting getter)
  expect(childState.parents.contains(parentState), isTrue);
});
```

### Pattern 2: Testing Listener Cleanup

```dart
test('should remove listeners on dispose', () {
  final source = SourceViewModel();
  final dependent = DependentViewModel();

  dependent.listenToSource(source);
  expect(source.hasListeners, isTrue);

  dependent.dispose();

  // Verify cleanup
  expect(dependent.isDisposed, isTrue);
});
```

### Pattern 3: Testing Error Recovery

```dart
test('should recover from error state on retry', () async {
  final vm = FailableViewModel(shouldFail: true);

  // First attempt fails
  await vm.reload();
  expect(vm.isError, isTrue);

  // Fix condition
  vm.shouldFail = false;

  // Retry succeeds
  await vm.reload();
  expect(vm.hasData, isTrue);
  expect(vm.isError, isFalse);
});
```

### Pattern 4: Testing State Hooks

```dart
class HookedViewModel extends ViewModel<int> {
  List<String> stateChanges = [];

  HookedViewModel() : super(0);

  @override
  void init() {}

  @override
  void onStateChanged(int previous, int next) {
    stateChanges.add('$previous -> $next');
  }
}

test('should track state changes via hook', () {
  final vm = HookedViewModel();

  vm.updateState(1);
  vm.updateState(2);
  vm.updateState(3);

  expect(vm.stateChanges, equals(['0 -> 1', '1 -> 2', '2 -> 3']));
});
```

### Pattern 5: Testing Auto-Dispose

```dart
test('should track reference count', () {
  final state = ReactiveNotifier<int>(() => 0, autoDispose: true);

  expect(state.referenceCount, equals(0));

  state.addReference('widget_1');
  expect(state.referenceCount, equals(1));

  state.addReference('widget_2');
  expect(state.referenceCount, equals(2));

  state.removeReference('widget_1');
  expect(state.referenceCount, equals(1));
});
```

### Pattern 6: Testing with postFrameCallback

For ViewModels that use `postFrameCallback` for safe InheritedWidget access:

```dart
testWidgets('should access MediaQuery after frame', (tester) async {
  final vm = ResponsiveViewModel();

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: ReactiveViewModelBuilder<ResponsiveViewModel, ResponsiveState>(
          viewmodel: vm,
          build: (state, vm, keep) => Text('Width: ${state.screenWidth}'),
        ),
      ),
    ),
  );

  // Wait for initial build
  await tester.pumpAndSettle();

  // Important: pump again for postFrameCallback
  await tester.pump();

  expect(vm.data.screenWidth, equals(800.0));
});
```

---

## Summary

Testing ReactiveNotifier applications follows these core principles:

1. **Use `ReactiveNotifier.cleanup()` in tearDown** to ensure clean state between tests
2. **Use `updateSilently()` for test setup** to avoid unintended notifications
3. **Test real services and ViewModels** rather than complex mocks
4. **Use `registerContextForTesting()`** when ViewModels need BuildContext
5. **Wait properly for async operations** with `pumpAndSettle()` and `Future.delayed()`
6. **Test observable behavior** rather than implementation details
7. **Create testable ViewModels** with call counters and helper methods

The singleton-based architecture of ReactiveNotifier makes testing straightforward - you're testing the actual code that runs in production, not mocked substitutes.
