# ReactiveNotifier

A flexible, elegant, and secure tool for state management in Flutter. Designed with fine-grained state control in mind, it easily integrates with architectural patterns like MVVM, guarantees full independence from BuildContext, and is suitable for projects of any scale.

![reactive_notifier](https://github.com/user-attachments/assets/ca97c7e6-a254-4b19-b58d-fd07206ff6ee)

[![Dart SDK Version](https://img.shields.io/badge/Dart-SDK%20%3E%3D%203.5.4-0175C2?logo=dart)](https://dart.dev)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/reactive_notifier.svg)](https://pub.dev/packages/reactive_notifier)
[![likes](https://img.shields.io/pub/likes/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)
[![downloads](https://img.shields.io/badge/dynamic/json?url=https://pub.dev/api/packages/reactive_notifier/score&label=downloads&query=$.downloadCount30Days&color=blue)](https://pub.dev/packages/reactive_notifier)
[![popularity](https://img.shields.io/pub/popularity/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/jhonacodes/reactive_notifier/workflows/ci/badge.svg)](https://github.com/jhonacodes/reactive_notifier/actions)

## Features

- 🚀 Simple and intuitive API
- 🏗️ Perfect for MVVM architecture
- 🔄 Independent from BuildContext
- 🎯 Type-safe state management
- 📡 Built-in Async and Stream support
- 🔗 Smart related states system
- 🛠️ Repository/Service layer integration
- ⚡  High performance with minimal rebuilds
- 🐛 Powerful debugging tools
- 📊 Detailed error reporting
- 🧹 Full lifecycle control with state cleaning
- 🔍 Comprehensive state tracking
- 📊 Granular state update control

![performance_test](https://github.com/user-attachments/assets/0dc568d2-7e0a-46e5-8ad6-1fec92b772be)


## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  reactive_notifier: ^2.10.2
```

## Core Concepts

ReactiveNotifier follows a unique "create once, reuse always" approach to state management. Unlike other solutions that recreate state, ReactiveNotifier creates instances on demand and maintains them throughout the app lifecycle. This means:

- States are created only when needed, optimizing memory usage
- States persist across the app and can be accessed anywhere
- Cleanup focuses on resetting state, not destroying instances
- Organization should be done through mixins, not global variables

## Quick Start

### Using ViewModel with ReactiveViewModelBuilder

The ViewModel approach provides a robust foundation for complex state management with lifecycle hooks and powerful state control.

```dart
/// Define your state model
class CounterState {
  final int count;
  final String message;
  
  const CounterState({required this.count, required this.message});
  
  CounterState copyWith({int? count, String? message}) {
    return CounterState(
      count: count ?? this.count,
      message: message ?? this.message
    );
  }
}

/// Define your ViewModel
class CounterViewModel extends ViewModel<CounterState> {
  CounterViewModel() : super(CounterState(count: 0, message: 'Initial'));
  
  @override
  void init() {
    // Initialization logic runs only once when created
    print('Counter initialized');
  }
  
  void increment() {
    transformState((state) => state.copyWith(
      count: state.count + 1,
      message: 'Incremented to ${state.count + 1}'
    ));
  }
  
  void decrement() {
    transformState((state) => state.copyWith(
      count: state.count - 1,
      message: 'Decremented to ${state.count - 1}'
    ));
  }
}


/// Create a mixin to encapsulate your ViewModel
mixin CounterService {
  static final ReactiveNotifierViewModel<CounterViewModel, CounterState> viewModel =
  ReactiveNotifierViewModel(() => CounterViewModel());
}


/// In your UI, use ReactiveViewModelBuilder
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveViewModelBuilder<CounterState>(
      viewmodel: CounterService.viewModel.notifier,
      builder: (state, keep) {
        return Column(
          children: [
            Text('Count: ${state.count}'),
            Text(state.message),
            
            // Prevent rebuilds with keep
            keep(
              Row(
                children: [
                  ElevatedButton(
                    onPressed: CounterService.viewModel.notifier.decrement,
                    child: Text('-'),
                  ),
                  ElevatedButton(
                    onPressed: CounterService.viewModel.notifier.increment,
                    child: Text('+'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
```

### Using Simple ReactiveNotifier

For simpler state management scenarios:

```dart
/// Create a mixin to encapsulate state
mixin ThemeService {
  static final ReactiveNotifier<bool> isDarkMode = 
      ReactiveNotifier<bool>(() => false);
  
  static void toggleTheme() {
    isDarkMode.updateState(!isDarkMode.notifier);
  }
}

/// In your UI
class ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<bool>(
      notifier: ThemeService.isDarkMode,
      builder: (isDark, keep) {
        return Switch(
          value: isDark,
          onChanged: (_) => ThemeService.toggleTheme(),
        );
      },
    );
  }
}
```

## Lifecycle Management

### Initializing Instances with loadNotifier()

ReactiveNotifier creates instances on demand, but sometimes you need to preload data at app startup. Use `loadNotifier()`:

```dart
// In your main or initialization code
mixin StartupService {
  static Future<void> initializeApp() async {
    // Initialize critical states at startup
    await UserService.userState.loadNotifier();
    await ConfigService.configState.loadNotifier();
    
    runApp(MyApp());
  }
}
```

### State Cleaning vs Disposing

ReactiveNotifier promotes cleaning state rather than disposing instances:

```dart
mixin UserService {
  static final userState = ReactiveNotifier<UserModel>(() => UserModel.guest());
  
  // Recommended: Clean state (reset to empty but keep instance)
  static void resetToGuest() {
    userState.cleanCurrentNotifier();
  }
  
  // Alternative: Dispose completely (only if you're certain)
  // Warning: If used elsewhere, this can cause issues
  static void disposeCompletely() {
    ReactiveNotifier.cleanupInstance(userState.keyNotifier);
  }
}

// In a widget's dispose method
@override
void dispose() {
  // If using auto-dispose pattern
  if (widget.cleanOnDispose) {
    UserService.resetToGuest();
  }
  super.dispose();
}
```

# Listener Management in ReactiveNotifier

ReactiveNotifier provides a sophisticated system for managing listeners in ViewModels through the `setupListeners` and `removeListeners` methods. This pattern ensures proper listener lifecycle management to prevent memory leaks and unnecessary updates.

## Implementation Pattern

```dart
class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  // Store listener methods as class properties for reference and cleanup
  Future<void> _categoryListener() async {
    // Always check hasInitializedListenerExecution to prevent premature updates
    if (hasInitializedListenerExecution) {
      // Update logic here when category changes
    }
  }
  
  Future<void> _priceListener() async {
    if (hasInitializedListenerExecution) {
      // Update logic here when price changes
    }
  }
  
  // Define listener names for debugging (recommended practice)
  final List<String> _listenersName = ["_categoryListener", "_priceListener"];
  
  ProductsViewModel(this.repository) 
      : super(AsyncState.initial(), loadOnInit: true);

  @override
  Future<List<Product>> loadData() async {
    return await repository.getProducts();
  }
  
  @override
  Future<void> setupListeners([List<String> currentListeners = const []]) async {
    // Register listeners with their respective services
    CategoryService.instance.notifier.addListener(_categoryListener);
    PriceService.instance.notifier.addListener(_priceListener);
    
    // Call super with your listeners list for logging and lifecycle management
    await super.setupListeners(_listenersName);
  }
  
  @override
  Future<void> removeListeners([List<String> currentListeners = const []]) async {
    // Unregister all listeners
    CategoryService.instance.notifier.removeListener(_categoryListener);
    PriceService.instance.notifier.removeListener(_priceListener);
    
    // Call super with your listeners list for logging and lifecycle cleanup
    await super.removeListeners(_listenersName);
  }
}
```

## Key Concepts

### 1. Listener Method Definition
- Create dedicated methods for each listener
- Store them as class properties (not anonymous functions)
- Use `hasInitializedListenerExecution` guard to prevent premature updates

### 2. Debugging Support
- Define a `_listenersName` list to track active listeners
- Pass this list to the parent methods for standardized logging
- Logs will show formatted information about listener setup and removal

### 3. Lifecycle Integration
Listeners are automatically managed at specific points:
- **Setup**: After initial data loading completes
- **Removal**: During `dispose()`, before `reload()`, and during `cleanState()`
- **Cleanup**: Automatically handled in superclass implementations

### 4. Memory Leak Prevention
The pattern prevents common memory leaks by ensuring:
- Listeners are properly removed when data is reloaded
- Listeners are cleaned up when the ViewModel is disposed
- No duplicate listeners are created when a ViewModel is reused

### 5. Implementation Best Practices
- Always call `super.setupListeners()` and `super.removeListeners()`
- Pass your listeners list to these methods for proper logging
- Use strong references to listener methods (not anonymous functions)
- Implement both methods as a pair to ensure proper cleanup

## Automatic Lifecycle Hooks

The framework automatically calls these methods at the right times:

| Event | setupListeners | removeListeners |
|-------|----------------|-----------------|
| Initial load completion | ✓ | |
| Before reload() | | ✓ |
| During cleanState() | ✓ | ✓ |
| During dispose() | | ✓ |

This structured approach allows ViewModels to react to external state changes without creating memory leaks or causing unnecessary widget rebuilds.

## `listen`

`listen` is used to subscribe to changes in a **simple `ReactiveNotifier<T>`**—a notifier holding a direct value.

```dart
await notifier.listen((data) {
  // React to changes in the simple value held by the ReactiveNotifier
  print('New value: $data');
});
```

### Usage

* Listen to updates on primitive or simple reactive values (e.g., `int`, `bool`, `List<T>`)
* Run side effects based on value changes (UI notifications, triggers)
* Works with reactive notifiers that directly expose the value as `T`

### Notes

* Remember to stop listening with `stopListening()` to avoid memory leaks
* Keep listener logic lightweight and side-effect focused


## `listenVM`

`listenVM` subscribes to **changes inside a ViewModel’s internal state**, reacting to modifications of the state.

```dart
await notifier.listenVM((state) {
  // React to changes in the simple value held by the ReactiveNotifier
  print('New state: $state');
});
```

### Usage

* Listen to the *state object* inside a ViewModel (e.g., `AsyncState<T>`, `CustomState`)
* React to internal state changes such as loading, error, or data updates
* Enables fine-grained reactive responses tied to the ViewModel’s state

### Notes

* Call `stopListeningVM()` to properly clean up listeners
* Use alongside `setupListeners()` and `removeListeners()` to manage lifecycle
* Listener callback receives only the updated state object, not the entire ViewModel




## State Update Methods

ReactiveNotifier provides multiple ways to update state with precise control:

### updateState and updateSilently

```dart
mixin CounterService {
  static final ReactiveNotifier<int> counter = ReactiveNotifier<int>(() => 0);
  
  // Normal update - triggers widget rebuilds
  static void increment() {
    counter.updateState(counter.notifier + 1);
  }
  
  // Silent update - changes state without rebuilding widgets
  // Useful in initState or for background updates
  static void prepareInitialValue() {
    counter.updateSilently(10);
  }
}
```

### transformState, transformStateSilently, transformDataState and transformDataStateSilently

For complex state that needs to be updated based on current values:

```dart
mixin CartService {
  static final ReactiveViewModelNotifier<CartModel> cart = 
      ReactiveNotifier<CartModel>(() => CartModel.empty());
  
  // Update with notification 
  static void addItem(Product product) {
    cart.transformState((state) => state.copyWith(
      items: [...state.items, product],
      total: state.total + product.price
    ));
  }
  
  // Update without notification
  // Useful for background calculations or preparations
  static void prepareCartData(List<Product> products) {
    cart.transformStateSilently((state) => state.copyWith(
      recommendedItems: products,
      // No UI update needed for this background change
    ));
  }


  // in this case `CartViewModel` is `AsyncViewModelImpl`
  static final ReactiveNotifier<CartModel> cart =
  ReactiveNotifier<CartViewModel>(CartViewModel.new);


  // For update `transformState` we need to use `AsyncState`
  // because sometimes we need a AsyncState to update the state
  static void addItem(Product product) {
    cart.transformState((state) => AsyncState.success(state.data.copyWith(
        items: [...state.items, product],
        total: state.total + product.price
    )));
  }
  
  // This is directory for data
  static void prepareCartData(List<Product> products) {
    cart.transformDataState((state) => state.copyWith(
      recommendedItems: products,
    ));
  }
}
```

## Related States System

ReactiveNotifier's related states system allows for managing interdependent states efficiently:

```dart
mixin ShopService {
  // Individual state notifiers
  static final ReactiveNotifier<UserState> userState = 
      ReactiveNotifier<UserState>(() => UserState.guest());
  
  static final ReactiveNotifier<CartState> cartState = 
      ReactiveNotifier<CartState>(() => CartState.empty());
  
  static final ReactiveNotifier<ProductsState> productsState = 
      ReactiveNotifier<ProductsState>(() => ProductsState.initial());
  
  // Combined state that's aware of all related states
  static final ReactiveNotifier<ShopState> shopState = ReactiveNotifier<ShopState>(
    () => ShopState.initial(),
    related: [userState, cartState, productsState],
  );
  
  // Access related states in three ways:
  static void showUserCartSummary() {
    // 1. Direct access
    final user = userState.notifier;
    
    // 2. Using from<T>()
    final cart = shopState.from<CartState>();
    
    // 3. Using keyNotifier
    final products = shopState.from<ProductsState>(productsState.keyNotifier);
    
    print("${user.name}'s cart has ${cart.items.length} items with products from ${products.categories.length} categories");
  }
}
```

## Special Builder Components

### ReactiveBuilder

For simple state values:

```dart
ReactiveBuilder<bool>(
  notifier: SettingsService.isNotificationsEnabled,
  builder: (enabled, keep) {
    return Switch(
      value: enabled,
      onChanged: (value) => SettingsService.toggleNotifications(),
    );
  },
)
```

### ReactiveViewModelBuilder

For ViewModel-based state:

```dart
ReactiveViewModelBuilder<UserProfileData>(
  viewmodel: ProfileService.viewModel.notifier,
  builder: (profile, keep) {
    return Column(
      children: [
        Text(profile.name),
        Text(profile.email),
        keep(ElevatedButton(
          onPressed: ProfileService.viewModel.notifier.logout, 
          child: Text('Logout')
        )),
      ],
    );
  },
)
```

### ReactiveAsyncBuilder

For async operations with loading, error, and success states:

```dart
mixin ProductService {
  static final productsViewModel = ReactiveNotifier<ProductsViewModel>(
          () => ProductsViewModel(repository)
  );
}

class ProductsViewModel extends AsyncViewModelImpl<List<Product>> {
  final ProductRepository repository;

  ProductsViewModel(this.repository)
      : super(AsyncState.initial(), loadOnInit: true);

  @override
  Future<List<Product>> loadData() async {
    return await repository.getProducts();
  }

  // Clean state when widget is disposed (don't dispose the ViewModel)
  void onWidgetDispose() {
    cleanState();
  }
}

// In your UI
ReactiveAsyncBuilder<List<Product>>(
  notifier: ProductService.productsViewModel.notifier,
  onSuccess: (products) => ProductGrid(products),
  onLoading: () => CircularProgressIndicator(),
  onError: (error, stack) => Text('Error: $error'),
  onInitial: () => Text('Ready to load products'),
)
```

### ReactiveStreamBuilder

For handling streams with a reactive approach:

```dart
mixin ChatService {
  static final messageStream = ReactiveNotifier<Stream<Message>>(
    () => firebaseRepository.getMessageStream()
  );
}

// In your UI
ReactiveStreamBuilder<Message>(
  notifier: ChatService.messageStream,
  onData: (message) => MessageBubble(message),
  onLoading: () => LoadingIndicator(),
  onError: (error) => Text('Error: $error'),
  onEmpty: () => Text('No messages yet'),
  onDone: () => Text('Stream closed'),
)
```

### ReactiveFutureBuilder: Improving Flutter's FutureBuilder

Our `ReactiveFutureBuilder` addresses some limitations of Flutter's standard `FutureBuilder`:

#### Key Advantages

- **No Flickering During Navigation**: Unlike regular `FutureBuilder` which resets its state during rebuilds, `ReactiveFutureBuilder` maintains visual continuity by displaying cached data instantly.

- **Seamless State Access**: Connects with a `ReactiveNotifier` to provide global access to the element's state from anywhere in the app.

- **Immediate Data Display**: Uses `defaultData` to show content immediately while fresh data loads in the background.

- **Smart Updates**: Controls whether state changes trigger UI rebuilds with the `notifyChangesFromNewState` parameter.

- **Perfect for Detail Views**: Ideal for master-detail patterns where you need to:
   - View details of an item from a list
   - Edit those details from anywhere in the app
   - See changes reflected immediately in all related UI components

```dart
// Standard FutureBuilder approach (shows loading indicator on every rebuild)
FutureBuilder<Product>(
  future: MyNotifier.instance.getProduct(id),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator(); // Flickers on navigation
    }
    // ...
  }
)

// ReactiveFutureBuilder approach (no flickering)
ReactiveFutureBuilder<Product>(
  future: MyNotifier.instance.getProduct(id),
  defaultData: MyNotifierCurrentData.instance.data, // Shows immediately
  createStateNotifier: ProductService.currentProductDetails, // Connect to global state
  onSuccess: (product) => ReactiveBuilder(
    notifier: ProductService.currentProductDetails,
    // Update UI when product changes when use ProductService.currentProductDetails.updateState
  ),
)
```

#### When to Use

`ReactiveFutureBuilder` is especially valuable when:

1. **Detail screens need immediate data**: Users shouldn't see loading indicators when returning to previously loaded screens.

2. **Elements need their own reactive state**: When you want to update a specific element globally and have all views of that element update automatically.

3. **UI consistency is critical**: Applications where a professional, native feel is important benefit from the flickerless navigation experience.

This simple implementation provides a significant UX improvement with minimal added complexity.

## Performance Optimization with keep

The `keep` function is a powerful way to prevent unnecessary rebuilds, even for complex widgets containing other reactive components:

```dart
ReactiveBuilder<int>(
  notifier: CounterService.counter,
  builder: (count, keep) {
    return Column(
      children: [
        // Rebuilds when count changes
        Text('Count: $count'), 
        
        // These widgets will NOT rebuild when count changes
        keep(
          Image.asset('assets/counter_image.png'),
        ),
        
        // Even another ReactiveBuilder inside keep won't rebuild when the parent rebuilds
        // Only rebuilds when ThemeService.isDarkMode changes
        keep(
          ReactiveBuilder<bool>(
            notifier: ThemeService.isDarkMode,
            builder: (isDark, innerKeep) {
              return Card(
                color: isDark ? Colors.grey[800] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Theme card with count: $count',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const ExpensiveWidget(),

        const ElevatedButton(
          onPressed: CounterService.increment,
          child: const Text('Increment'),
        ),
      ],
    );
  },
)
```

Key points about `keep`:

1. Using `keep` prevents widgets from rebuilding even when their parent rebuilds
2. Nested ReactiveBuilder widgets inside `keep` only rebuild when their own state changes
3. Use `keep` for:
    - Expensive widgets that don't depend on the current state
    - Other ReactiveBuilders that should update independently
    - Widgets with their own state management
    - Widgets that access the current state but don't need to rebuild when it changes

Note that there's no need to use `keep` on `const` widgets as they're already optimized by Flutter.

## Debugging and Monitoring

ReactiveNotifier provides extensive debugging information:

### Creation and Lifecycle Tracking

```
🔧 ViewModel<UserState> created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: instance_123
Location: package:my_app/user/user_viewmodel.dart:25
Initial state hash: 42
```

### State Updates

```
📝 ViewModel<UserState> updated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: instance_123
Update #: 1
New state hash: 84
```

### Circular Reference Detection

```
⚠️ Invalid Reference Structure Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Notifier: CartState
Key: cart_key
Problem: Attempting to create a circular dependency
Solution: Ensure state relationships form a DAG
Location: package:my_app/cart/cart_state.dart:42
```


# ReactiveFutureBuilder<T>

`ReactiveFutureBuilder` combines Flutter’s `FutureBuilder` with reactive state management to avoid UI flickering and keep data synchronized globally.

### Key Features

* Displays `defaultData` immediately to avoid flickering when navigating back
* Updates a `ReactiveNotifier<T>` with Future results for shared state
* Uses a `keep` function to prevent unnecessary widget rebuilds
* Handles all Future states: initial, loading, error, and success

### Example

```dart
ReactiveFutureBuilder<OrderItem?>(
  future: OrderService.instance.notifier.loadById(orderId),
  defaultData: OrderService.instance.notifier.getByPid(orderId),
  createStateNotifier: OrderService.currentOrderItem,
  onData: (order, keep) => keep(OrderDetailView(order: order!)),
  onLoading: () => const CircularProgressIndicator(),
  onError: (error, _) => Text('Error: $error'),
)
```

### Parameters

| Parameter                   | Description                                                                   |
| --------------------------- | ----------------------------------------------------------------------------- |
| `future`                    | The Future that provides data                                                 |
| `defaultData`               | Data to display immediately while waiting for the Future                      |
| `onSuccess` (deprecated)    | Deprecated simple success builder, use `onData` instead                       |
| `onData`                    | Builder function receiving data and a `keep` widget wrapper to avoid rebuilds |
| `onLoading`                 | Widget displayed while loading                                                |
| `onError`                   | Widget displayed on error                                                     |
| `onInitial`                 | Widget shown before the Future starts                                         |
| `createStateNotifier`       | `ReactiveNotifier<T>` updated with the Future’s data                          |
| `notifyChangesFromNewState` | Whether to notify listeners on updates or update silently                     |


## Best Practices

### Organizing with Mixins

Always organize ReactiveNotifier instances using mixins, not global variables:

```dart
// GOOD: Using mixins
mixin AuthService {
  static final ReactiveNotifier<UserState> userState = 
      ReactiveNotifier<UserState>(() => UserState.guest());
  
  static void login(String username, String password) {
    // Implementation
  }
}

// BAD: Don't use global variables
final userState = ReactiveNotifier<UserState>(() => UserState.guest());
```

### Avoid Creating Instances in Widgets

Never create ReactiveNotifier instances inside widgets:

```dart
// GOOD: Access through mixin
class ProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      notifier: UserService.profileState,
      builder: (profile, keep) => Text(profile.name),
    );
  }
}

// BAD: Don't create instances in widgets
class BadProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // DON'T DO THIS - creates a new instance on every build
    final profileState = ReactiveNotifier<Profile>(() => Profile());
    // ...
  }
}
```

### State Cleaning in Widget Lifecycle

Clean state appropriately when widgets are disposed:

```dart
class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Optionally prepare initial state without notifications
    UserService.profileState.updateSilently(Profile.loading());
  }
  
  @override
  void dispose() {
    // Reset state but keep the instance
    UserService.resetProfile();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      notifier: UserService.profileState,
      builder: (profile, keep) {
        // UI implementation
      },
    );
  }
}
```

### Granular State Updates

Use transformState with copyWith for efficient state updates:

```dart
mixin FormService {
  static final formState = ReactiveNotifier<FormState>(() => FormState.empty());
  
  static void updateEmail(String email) {
    formState.transformState((state) => state.copyWith(email: email));
  }
  
  static void updatePassword(String password) {
    formState.transformState((state) => state.copyWith(password: password));
  }
  
  // Use transformStateSilently for non-UI updates
  static void recordLastValidation() {
    formState.transformStateSilently((state) => 
      state.copyWith(lastValidated: DateTime.now()));
  }
}
```

## Testing with ReactiveNotifier

ReactiveNotifier makes testing straightforward by leveraging the original mixin and directly updating its state:

```dart
// Example test for CounterViewModel
void main() {
  group('CounterViewModel Tests', () {
    setUp(() {
      // Setup before each test
      ReactiveNotifier.cleanup(); // Clear previous states
      
      // Use the original mixin but update with mock data - recommended approach
      CounterService.viewModel.notifier.updateSilently(MockCounterState(
        count: 5,
        message: 'Test Initial State'
      ));
    });
    
    testWidgets('should display counter value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CounterWidget(), // Use the actual widget that uses CounterService
        ),
      );
      
      // Verify the widget displays the mocked state
      expect(find.text('Count: 5'), findsOneWidget);
      
      // Update state for the next test assertion
      CounterService.viewModel.notifier.increment();
      await tester.pump();
      
      // Verify widget updated correctly
      expect(find.text('Count: 6'), findsOneWidget);
    });
    
    test('service actions should update state correctly', () {
      // Set initial state for this specific test
      CounterService.viewModel.notifier.updateSilently(MockCounterState(
        count: 0,
        message: 'Fresh Test State'
      ));
      
      // Use the actual service methods
      CounterService.increment();
      
      // Verify state was updated correctly
      expect(CounterService.viewModel.state.count, equals(1));
      expect(CounterService.viewModel.state.message, contains('Incremented'));
    });
  });
}

// Mock model for testing
class MockCounterState extends CounterState {
  MockCounterState({required int count, required String message})
      : super(count: count, message: message);
}
```

This approach has several advantages:

1. It uses the actual service mixin.
2. No override.
3. No container provider or similar.
4. No force specific patter for testing, just natural :).
5. It tests the real components with controlled data.
6. It's simple and doesn't require complex mocking frameworks.
7. It maintains the singleton pattern even during testing.

For specific test scenarios, you can easily reset or prepare different states:

```dart
// Before a specific test case
test('specific scenario', () {
  // Prepare specific test state
  CounterService.viewModel.notifier.updateSilently(MockCounterState(
    count: 100,
    message: 'Specific test scenario'
  ));
  
  // Run test logic...
});
```

Testing with ReactiveNotifier follows its core philosophy: use the same instances but control their state directly.


## Recommended Architecture

ReactiveNotifier is designed to work optimally with modular applications, following a feature-based MVVM architecture. We recommend the following project structure, although you can use the names and architecture that suit your needs. This example aims to give a clearer idea of the power of this library.
```
src/
├── auth/                   # A specific feature
│   ├── ui/
│   │   ├── layouts/
│   │   ├── views/
│   │   ├── widgets/
│   │   └── screens/
│   ├── model/
│   │   ├── user_model.dart
│   │   └── credentials_model.dart
│   ├── viewmodel/
│   │   └── auth_viewmodel.dart
│   ├── repository/         # Only if required
│   │   └── auth_repository.dart
│   ├── routes/             # Only if required
│   │   └── auth_routes.dart
│   └── notifier/
│       └── auth_notifier.dart (mixin)
│
├── dashboard/              # Another specific feature
│   ├── ui/
│   │   ├── layouts/
│   │   ├── views/
│   │   ├── widgets/
│   │   └── screens/
│   ├── model/
│   │   └── dashboard_model.dart
│   ├── viewmodel/
│   │   └── dashboard_viewmodel.dart
│   ├── repository/
│   │   └── dashboard_repository.dart
│   └── notifier/
│       └── dashboard_notifier.dart (mixin)
│
├── profile/                # Another specific feature
│   ├── ui/
│   ├── model/
│   ├── viewmodel/
│   ├── repository/
│   └── notifier/
│
└── core/                   # Shared core components
    ├── api/
    ├── theme/
    └── utils/
```

Each feature follows the complete MVVM pattern with its own internal structure. This modular feature-based architecture allows for independent development and keeps related functionality grouped together.

### Complete Architecture Example

Below is an example of how to implement a complete system with this architecture:

#### 1. Model

```dart
// src/auth/model/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final List<String> roles;
  
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });
  
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? roles,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
    );
  }
  
  factory UserModel.empty() => const UserModel(
    id: '',
    name: '',
    email: '',
    roles: [],
  );
}
```

#### 2. Repository

```dart
// src/auth/repository/auth_repository.dart
import 'package:http/http.dart' as http;
import '../model/user_model.dart';

class AuthRepositoryImpl {
  AuthRepositoryImpl();
  final http.Client _client = http.Client();
  
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('https://api.example.com/login'),
        body: {'email': email, 'password': password},
      );
      
      if (response.statusCode == 200) {
        // Parse response and return model
        return UserModel(
          id: '123',
          name: 'John Doe',
          email: email,
          roles: ['user'],
        );
      } else {
        throw Exception('Authentication failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }
  
  Future<void> logout() async {
    await _client.post(Uri.parse('https://api.example.com/logout'));
  }
}
```

#### 3. ViewModel

```dart
// src/auth/viewmodel/auth_viewmodel.dart
import 'package:reactive_notifier/reactive_notifier.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../../dashboard/notifier/dashboard_notifier.dart';
import '../../profile/notifier/profile_notifier.dart';

class AuthViewModel extends ViewModel<UserModel> {
  final AuthRepositoryImpl repository;

  // Pass repository by reference for better testability
  AuthViewModel(this.repository) : super(UserModel.empty());

  @override
  void init() {
    // Check for saved session
    checkSavedSession();
  }
  

  Future<void> checkSavedSession() async {
    // Logic to check for saved session
  }

  Future<void> login(String email, String password) async {
    try {
      // Show loading state
      transformState((state) => state.copyWith(
        name: 'Loading...',
      ));

      // Use injected repository for login
      final user = await repository.login(email, password);

      // Update state with user
      updateState(user);

      // CROSS-MODULE COMMUNICATION
      // Update other modules after successful login
      DashboardNotifier.dashboardState.updateSilently(DashboardModel.forUser(user));
      ProfileNotifier.profileState.updateSilently(ProfileModel.fromUser(user));

    } catch (e) {
      // Handle error and update state
      transformState((state) => UserModel.empty().copyWith(
          name: 'Error: ${e.toString()}'
      ));
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();

      // Clear state 
      cleanState();

      // CROSS-MODULE COMMUNICATION
      // Clear data from other modules
      DashboardNotifier.dashboardState.cleanCurrentNotifier();
      ProfileNotifier.profileState.cleanCurrentNotifier();

    } catch (e) {
      print('Logout error: $e');
    }
  }
}
```

#### 4. Notifier (Mixin)

```dart
// src/auth/notifier/auth_notifier.dart
import 'package:reactive_notifier/reactive_notifier.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../model/user_model.dart';

mixin AuthNotifier {
  // Main state
  static final authState = ReactiveNotifier<AuthViewModel>(() {
      final repository = AuthRepositoryImpl();
      return AuthViewModel(repository);
    },
  );
  
  // Utility methods for use in UI
  static Future<void> login(String email, String password) async {
    await authState.notifier.login(email, password);
  }
  
  static Future<void> logout() async {
    await authState.notifier.logout();
  }
  
  static bool get isLoggedIn {
    return authState.notifier.data.id.isNotEmpty;
  }
  
  static String get userName {
    return authState.notifier.data.name;
  }
  
  // More utility methods...
}
```

#### 5. UI (Screen)

```dart
// src/auth/ui/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import '../../notifier/auth_notifier.dart';
import '../../model/user_model.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: ReactiveViewModelBuilder<UserModel>(
        viewmodel: AuthNotifier.authState.notifier,
        builder: (user, keep) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (user.name.startsWith('Error'))
                  Text(
                    user.name,
                    style: TextStyle(color: Colors.red),
                  ),
                
                // Clean UI with reusable widgets
                keep(LoginForm(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  onLogin: ()async => await AuthNotifier.login(
                    _emailController.text,
                    _passwordController.text,
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
  
}

// Reusable widget
class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  
  const LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: onLogin,
          child: Text('Login'),
        ),
      ],
    );
  }
}
```

## Cross-Module Communication

ReactiveNotifier facilitates direct communication between modules without complex event systems. All logic can occur within the ViewModel, Notifier, or even the Repository.

### Communication through ViewModel

```dart
// In auth_viewmodel.dart
Future<void> login(String email, String password) async {
  try {
    // ... login code
    
    // After successful login, update other modules
    // Note we're not using 'related', but direct communication
    
    // Update dashboard with user data
    DashboardNotifier.dashboardState.updateState(
      DashboardModel.forUser(user)
    );
    
    // Prepare profile data silently (without rebuilding UI yet)
    ProfileNotifier.profileState.updateSilently(
      ProfileModel.fromUser(user)
    );
    
    // Cart might require additional data.
    CartNotifier.cartState.updateStateFromUserId(user.id);
    
  } catch (e) {
    // Error handling
  }
}
```

### Communication through Notifier (Mixin)

```dart
// In payment_notifier.dart
mixin PaymentNotifier {
  static final paymentState = ReactiveNotifier<PaymentViewModel>(
    () => PaymentViewModel(),
  );
  
  static Future<void> processPayment(String orderId) async {
    try {
      final result = await paymentState.notifier.processPayment(orderId);
      
      if (result.success) {
        // Update other modules after successful payment
        OrderNotifier.orderState.notifier.updateOrderStatus(
          orderId, 
          'PAID'
        );
        
        CartNotifier.cartState.notifier.clearCart();
        
        NotificationNotifier.notificationState.notifier.addNotification(
          NotificationModel(
            title: 'Payment Successful',
            body: 'Your order #$orderId has been paid.',
            type: NotificationType.success,
          ),
        );
      }
    } catch (e) {
      // Error handling
    }
  }
}
```

### Communication from Repository

```dart
// In order_repository.dart
class OrderRepositoryImpl {
  // ... other methods
  
  Future<OrderModel> createOrder(CartModel cart) async {
    try {
      // API call to create order
      final orderResponse = await _client.post(...);
      final newOrder = OrderModel.fromJson(orderResponse);
      
      // Update related modules directly from repository
      CartNotifier.cartState.notifier.setOrderId(newOrder.id);
      
      // We can even trigger navigation if needed
      NavigationNotifier.navigate('order_confirmation', params: {'id': newOrder.id});
      
      return newOrder;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }
}
```

The main advantage of this approach is that it keeps business logic and cross-module communication in the appropriate layers (ViewModel, Repository), leaving the UI clean and focused solely on presentation. No complex event systems, or additional controllers are required.

## Examples

Check out our [example app](https://github.com/jhonacodes/reactive_notifier/tree/main/example) for more comprehensive examples and use cases.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Create a new Pull Request

## Support

- 🌟 Star the repo to show support
- 🐛 Create an [issue](https://github.com/jhonacodes/reactive_notifier/issues) for bugs
- 💡 Submit feature requests through [issues](https://github.com/jhonacodes/reactive_notifier/issues)
- 📝 Contribute to the [documentation](https://github.com/jhonacodes/reactive_notifier/wiki)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by [JhonaCode](https://github.com/jhonacodes)
