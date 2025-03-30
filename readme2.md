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
- ⚡ High performance with minimal rebuilds
- 🐛 Powerful debugging tools
- 📊 Detailed error reporting
- 🧹 Full lifecycle control with state cleaning
- 🔍 Comprehensive state tracking
- 📊 Granular state update control

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  reactive_notifier: ^2.7.0
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

/// Create a mixin to encapsulate your ViewModel
mixin CounterService {
  static final ReactiveNotifierViewModel<CounterViewModel, CounterState> viewModel =
  ReactiveNotifierViewModel(() => CounterViewModel());
}

/// Define your ViewModel
class CounterViewModel extends ViewModel<CounterState> {
  CounterViewModel() : super(CounterState(count: 0, message: 'Initial'));

  @override
  void init() {
    // Initialization logic runs only once when created
    print('Counter initialized');
  }

  @override
  CounterState _createEmptyState() {
    // Required for cleanState() functionality
    return CounterState(count: 0, message: '');
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
        return keep(
          Switch(
            value: isDark,
            onChanged: (_) => ThemeService.toggleTheme(),
          ),
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

### transformState and transformStateSilently

For complex state that needs to be updated based on current values:

```dart
mixin CartService {
  static final ReactiveNotifier<CartModel> cart =
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

## Performance Optimization with keep

The `keep` function is a powerful way to prevent unnecessary rebuilds:

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
        keep(
          const ExpensiveWidget(),
        ),
        keep(
          ElevatedButton(
            onPressed: CounterService.increment,
            child: const Text('Increment'),
          ),
        ),
      ],
    );
  },
)
```

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

1. It uses the actual service mixin - no need to create mock versions
2. It tests the real components with controlled data
3. It's simple and doesn't require complex mocking frameworks
4. It maintains the singleton pattern even during testing

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





## Examples

Check out our [example app](https://github.com/jhonacodes/reactive_notifier/tree/main/example) for more comprehensive examples and use cases.

## Contributing

We love contributions! Please read our [Contributing Guide](CONTRIBUTING.md) first.

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