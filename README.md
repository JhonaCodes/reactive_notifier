# ReactiveNotifier

A flexible, elegant, and secure tool for state management in Flutter. Designed with fine-grained state control in mind, it easily integrates with architectural patterns like MVVM, guarantees full independence from BuildContext, and is suitable for projects of any scale.

![reactive_notifier](https://github.com/user-attachments/assets/ca97c7e6-a254-4b19-b58d-fd07206ff6ee)

[![Dart SDK Version](https://img.shields.io/badge/Dart-SDK%20%3E%3D%202.17.0-0175C2?logo=dart)](https://dart.dev)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/reactive_notifier.svg)](https://pub.dev/packages/reactive_notifier)
[![likes](https://img.shields.io/pub/likes/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)
[![downloads](https://img.shields.io/badge/dynamic/json?url=https://pub.dev/api/packages/reactive_notifier/score&label=downloads&query=$.downloadCount30Days&color=blue)](https://pub.dev/packages/reactive_notifier)
[![popularity](https://img.shields.io/pub/popularity/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)


[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/jhonacodes/reactive_notifier/workflows/ci/badge.svg)](https://github.com/jhonacodes/reactive_notifier/actions)

> **Note**: Are you migrating from `reactive_notify`? The API remains unchanged - just update your dependency to `reactive_notifier`.

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

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  reactive_notifier: ^2.6.1
```

## Quick Start

### Usage with ReactiveNotifier

Learn how to implement ReactiveNotifier across different use cases - from basic data types (`String`, `bool`) to complex classes (`ViewModels`). These examples showcase global state management patterns that maintain accessibility across your application.

#### With Classes, Viewmodel, etc.

```dart

/// It is recommended to use mixin to save your notifiers, from a static variable.
///
mixin ConnectionService{
  static final ReactiveNotifier<ConnectionManager> instance = ReactiveNotifier<ConnectionManager>(() => ConnectionManager());
}


ReactiveBuilder<ConnectionManager>(

  notifier: ConnectionService.instance,

  builder: ( service, keep) {

    /// Notifier is used to access your model's data.
    final state = service.notifier;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: state.color.withValues(alpha: 255 * 0.2),
              child: Icon(
                state.icon,
                color: state.color,
                size: 35,
              ),
            ),

            Text(
              state.message,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            if (state.isError || state == ConnectionState.disconnected)
              keep(
                ElevatedButton.icon(

                  /// If you don't use notifier, access the functions of your Viewmodel that contains your model.
                  onPressed: () => service.manualReconnect(),

                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ),
            if (state.isSyncing) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  },
);
```

#### With simple values.

```dart

mixin ConnectionService{
  static final ReactiveNotifier<String> instance = ReactiveNotifier<String>(() => "N/A");
}

// Declare a simple state
ReactiveBuilder<ConnectionManager>(
  notifier: ConnectionService.instance,
  builder: ( state, keep) => Text(state),
);


/// Modify from other widget.
class OtherWidget extends StatelessWidget {
  const OtherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(onPressed: (){
          ConnectionService.instance.updateState("New value");
        }, child: Text('Edit String'))
      ],
    );
  }
}


/// Modify from any class, etc.
class OtherViewModel{

  void otherFunction(){
    ///Come code.....

    ConnectionService.instance.updateState("Value from other viewmodel");
  }
}

/// This example above applies to any Reactive Notifier, no matter how complex, it can be used from anywhere without the need for a reference or handler.
```

Both simple and complex values can be modified from anywhere in the application without modifying the structure of your widget.
You also don't need to instantiate variables in your widget build, you just call the mixin directly where you want to use it, this helps with less coupling, being able to replace all functions from the mixin and not fight with extensive migrations.

---

## **`ViewModelStateImpl` without Repository**

For simpler cases where direct state management is needed without a repository layer, you can use `ViewModelStateImpl`. This approach manages state directly within the ViewModel:

```dart
class CartViewModel extends ViewModelStateImpl<CartModel> {
  CartViewModel() : super(CartModel());

  // Add product directly to state
  void addProduct(String item, double price) {
    final currentItems = notifier.items;
    final newItems = [...currentItems, item];
    final newTotal = notifier.total + price;
    
    // Or using transformState
    transformState((state) => state.copyWith(items: newItems, total: newTotal));
    
    // Or dreate new instance and replace.
    updaeState(newCarInstance);
  }

  // Other business logic methods...
}
```
This implementation is suitable for:
- When you don't require repository at ViewModel level
- When implementing different architectural patterns (MVP, DAO, Clean Architecture)
- Any complexity level of state management
- Freedom to implement data persistence and business logic as needed
- Flexibility to structure your code without being tied to specific architectural constraints

# **Using the Library Repository with `ViewModelImpl`**

In this example, we are going to use the library's built-in repository to get and update the shopping cart data in the `ViewModelImpl`.

## **1. Defining the Repository using the library**

First, instead of creating a repository manually, we are going to use a repository provided by the library to interact with the data. Let's say you have a repository to handle cart-related data.

```dart
import 'package:reactive_notifier/reactive_notifier.dart';

class CartRepository extends RepositoryImpl<CartModel> {
	// We simulate the loading of a shopping cart
  Future<CartModel> fetchData() async {
    await Future.delayed(Duration(seconds: 2));
    return CartModel(
      items: ['Product A', 'Product B'],
      total: 39.98,
    );
  }

  /// More functions .....

}
```

---

## **2. `ViewModelImpl` with the Repository**

Now we are going to use the repository in the `ViewModelImpl` to interact with the cart model. The `ViewModelImpl` will leverage the repository to get data and make updates.

```dart
class CartViewModel extends ViewModelImpl<CartModel> {
  final CartRepository repository;

  CartViewModel(this.repository) : super(CartModel());

  // Function to load the cart from the repository
  Future<void> loadShoppingCart() async {
    try {
    	// We get the cart from the repository
      final shoppingCart = await repository.fetchData();
      updateState(carrito); // We update the status with the cart loaded
    } catch (e) {
    // Error handling
      print("Error: $e");
    }
  }

  // Function to add a product to the cart
  Future<void> addProduct(String item, double price) async {
    try {

      await repository.addProduct(value, item, price);

      // We update the status after adding the product
      updateState(notifier.copyWith(items: value.items, total: value.total));

      // Or
      transformState((state) => state.copyWith(items: value.items, total: value.total));

      // Or
      updateState(yourModelWithData);

    } catch (e) {

    // Error handling
      print("Error $e");


    }
  }
}
```

## **3. Repository Instance and `ViewModelImpl`**

Here we create the repository instance and the `ViewModelImpl`:

```dart
final cartViewModelNotifier = ReactiveNotifier<CartViewModel>((){
	final cartRepository = CartRepository();
	return CartViewModel(cartRepository);
});
```

---

## **4. Cart Status Widget**

Finally, we are going to display the cart status in the UI using `ReactiveBuilder`, which will automatically update when the status changes.

```dart
ReactiveViewModelBuilder<CartModel>(
  notifier: cartViewModelNotifier.notifier,
  builder: ( carModel, keep) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (carModel.isEmpty)
          keep(Text("Loading cart...")),
        if (carModel.isNotEmpty) ...[
          keep(Text("Products in cart:")),
          ...carModel.map((item) => Text(item)).toList(),
          keep(const SizedBox(height: 20)),
          Text("Total: \$${viewModel.total.toStringAsFixed(2)}"),
          keep(const SizedBox(height: 20)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              keep(
                ElevatedButton(
                  onPressed: () {
                    // Add a new product
                    cartViewModelNotifier.notifier.agregarProducto("Producto C", 29.99);
                  },
                  child: Text("Agregar Producto C"),
                ),
              ),
              keep(const SizedBox(width: 10)),
              keep(
                ElevatedButton(
                  onPressed: () {
                    // Empty cart
                    cartViewModelNotifier.notifier.myCleaningCarFunction();

                  },
                  child: Text("Vaciar Carrito"),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  },
)

```

# ⚡️ **Essential: `ReactiveNotifier` Core Concepts**

## **Documentation for `related` in `ReactiveNotifier`**

The `related` attribute in `ReactiveNotifier` allows you to efficiently manage interdependent states. They can be used in different ways depending on the structure and complexity of the state you need to handle.

### **Using `related` in ReactiveNotifier**

**Establishing Relationships Between Notifiers**

- `ReactiveNotifier` can manage any type of data (simple or complex). Through the `related` property, you can establish connections between different notifiers, where changes in any related notifier will trigger updates in the `ReactiveBuilder` that's watching them.

**Example Scenario: Managing Connected States**

- A primary notifier might handle a complex `UserInfo` class, while other notifiers manage related states like `Settings` or `Preferences`. Using `related`, any changes in these interconnected states will trigger the appropriate UI updates through `ReactiveBuilder`.

---

### **Direct Relationship between Simple Notifiers**

In this approach, you have several simple `ReactiveNotifier`s, and you use them together to notify state changes when any of these notifiers changes. The `ReactiveNotifier`s are related to each other using the `related` attribute, and you see a combined `ReactiveBuilder`.

#### **Example**

```dart
final timeHoursNotifier = ReactiveNotifier<int>(() => 0);
final routeNotifier = ReactiveNotifier<String>(() => '');
final statusNotifier = ReactiveNotifier<bool>(() => false);

// A combined ReactiveNotifier that watches for changes in all three notifiers
final combinedNotifier = ReactiveNotifier(
  () {},
  related: [timeHoursNotifier, routeNotifier, statusNotifier],
);

```

- **Explanation**:
  Here, `combinedNotifier` is a `ReactiveNotifier` that updates when any of the three notifiers (`timeHoursNotifier`, `routeNotifier`, `statusNotifier`) changes. This is useful when you have several simple states and you want them all to be connected to trigger an update in the UI together.

```dart
ReactiveBuilder(
  notifier: combinedNotifier,
  builder: (state, keep) {
    return Column(
      children: [
        Text("Hours: ${timeHoursNotifier.value}"),
        Text("Route: ${routeNotifier.value}"),
        Text("State: ${statusNotifier.value ? 'Active' : 'Inactive'}"),
      ],
    );
  },
);
```

- **Explanation**:
  `ReactiveBuilder` watches the `combinedNotifier`. Since the related notifiers are configured, any changes to `timeHoursNotifier`, `routeNotifier`, or `statusNotifier` will automatically update the UI.

---

### ** Relationship between a Main `ReactiveNotifier` and Other Complementary Notifiers**

In this approach, you have a main `ReactiveNotifier` that handles a more complex class, such as a `UserInfo` object, and other complementary `ReactiveNotifier`s are related through `related`. These complementary notifiers do not need to be declared inside the main object class, but are integrated with it through the `related` attribute.

#### **Example: `UserInfo` with `Settings`**

Imagine that we have a `UserInfo` class that represents a user's information, and a `Settings` class that contains complementary settings. The notifiers for these states are related to each other so that any change in `Settings` or `UserInfo` triggers a global update.

```dart
class UserInfo {
  final String name;
  final int age;

  UserInfo({required this.name, required this.age});

  // Constructor for default values
  UserInfo.empty() : name = '', age = 0;

  // Method to clone with new values
  UserInfo copyWith({String? name, int? age}) {
    return UserInfo(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}

// Complementary notifiers for configurations
final settingsNotifier = ReactiveNotifier<String>(() => 'Dark Mode');
final notificationsEnabledNotifier = ReactiveNotifier<bool>(() => true);

// Combined ReactiveNotifier that watches all related notifiers
final userStateNotifier = ReactiveNotifier<UserInfo>(
  () => UserInfo.empty(),
  related: [settingsNotifier, notificationsEnabledNotifier],
);
```

- **Explanation**:
  In this example, `userStateNotifier` is the main `ReactiveNotifier` that handles the state of `UserInfo`. `settingsNotifier` and `notificationsEnabledNotifier` are companion notifiers that handle user settings such as dark mode and enabling notifications. While they are not declared within `UserInfo`, they are related to it via `related`.

```dart
ReactiveBuilder<UserInfo>(
  notifier: userStateNotifier,
  builder: ( userInfo, keep) {
    return Column(
      children: [
        Text("User: ${userInfo.name}, Age: ${userInfo.age}"),
        Text("Configuration: ${settingsNotifier.notifier}"),
        Text("Notifications: ${notificationsEnabledNotifier.notifier ? 'Active' : 'Inactive'}"),
      ],
    );
  },
);
```

- **Explanation**:
  `ReactiveBuilder` watches `userStateNotifier.value` (the user state). It also watches the related notifiers (settings and notifications). This means that any change to any of these notifiers will trigger an update in the UI.

#### **Usage with `ReactiveBuilder.notifier`**

```dart
ReactiveBuilder(
  notifier: userStateNotifier,
  builder: (userInfo, keep) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            userStateNotifier.updateState(userInfo.copyWith(name: "Nuevo Nombre"));
          },
          child: Text("Actualizar Nombre"),
        ),
      ],
    );
  },
);
```

---

### **Advantages of Using `related` in `ReactiveNotifier`**

1. **Flexibility**:
   You can relate simple and complex notifiers without the need to involve additional classes. This is useful for handling states that depend on multiple values without overcomplicating the structure.

2. **Optimization**:
   When related notifiers change, the UI is automatically updated without the need to manually manage dependencies. This streamlines the workflow and improves the performance of the application.

3. **Scalability**:
   As your application grows, you can easily add more notifiers and relate them without modifying the existing logic, simply by extending the list of `related`.

4. **Simplicity**:
   You can easily handle complex states using `related`, keeping everything decoupled and clean without the need to wrap everything in a single ViewModel.

## **Accessing Related States within a `ReactiveBuilder`**

When you have multiple related `ReactiveNotifier`s, you can access the states in a number of ways within a `ReactiveBuilder`. Here I will explain the different ways to do this:

1. **Directly accessing the related `ReactiveNotifier`s.**
2. **Using the `from<T>()` method to access the related states within a `ReactiveNotifier`.**
3. **Using `keyNotifier` to access a specific `ReactiveNotifier`.**

### **General Example: Relating Notifiers and Accessing their States**

First, we will define the individual notifiers and then create a relationship between them using the `related` attribute within a parent `ReactiveNotifier`.

#### **Defining Notifiers and Relationships**

```dart

final userState = ReactiveNotifier<UserState>(() => UserState());
final cartState = ReactiveNotifier<CartState>(() => CartState());
final settingsState = ReactiveNotifier<SettingsState>(() => SettingsState());

final appState = ReactiveNotifier<AppState>(
  () => AppState(),
  related: [userState, cartState, settingsState],
);
```

- **`userState`, `cartState` and `settingsState`** are individual states, and **`appState`** is the main `ReactiveNotifier` that is related to them. This means that when any of the related states change, `appState` will be automatically updated.

### **1. Accessing Related States Directly**

In a `ReactiveBuilder`, you can directly access related notifiers without using additional methods like `from<T>()` or `keyNotifier`. You simply use the notifiers directly inside the `builder`.

#### **Usage in Direct `ReactiveBuilder`**

```dart
class AppDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<AppState>(
      notifier: appState,
      builder: (state, keep) {

        final user = userState.notifier.data;
        final cart = cartState.notifier.data;
        final settings = settingsState.notifier.data;

        return Column(
          children: [
            Text('Welcome ${user.name}'),
            Text('Cart Items: ${cart.items.length}'),
            Text('Settings: ${settings.theme}'),
            if (user.isLoggedIn) keep(const UserProfile())
          ],
        );
      },
    );
  }
}
```

- **Explanation**:
- Here, we directly access the values of `userState`, `cartState`, and `settingsState` using `.notifier.data`.
- **Pros**: It's a quick and straightforward way to access the values if you don't need to perform any extra logic on them.
- **Cons**: If you need to access a specific value of a related `ReactiveNotifier` and it's not directly in the `builder`, you might need something more organized, like using `keyNotifier` or the `from<T>()` method.

---

### **2. Using the `from<T>()` Method**

The `from<T>()` method is used to access a related state within a `ReactiveNotifier`. This method allows you to access a specific state more explicitly, especially if you need to get the value of a related state without directly accessing the `ReactiveNotifier`.

#### **Usage with `from<T>()`**

```dart
class AppDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<AppState>(
      notifier: appState,
      builder: (state, keep) {

        final user = appState.from<UserState>();
        final cart = appState.from<CartState>();
        final settings = appState.from<SettingsState>();

        return Column(
          children: [
            Text('Welcome ${user.name}'),
            Text('Cart Items: ${cart.items.length}'),
            Text('Settings: ${settings.theme}'),
            if (user.isLoggedIn) keep(const UserProfile())
          ],
        );
      },
    );
  }
}
```

- **Explanation**:
- We use `appState.from<UserState>()` to access the related user state. Similarly, we use `cartState.keyNotifier` to access `CartState` using its `keyNotifier`.
- **Pros**: `from<T>()` is useful when you have multiple related states and want to extract a value from a specific one more explicitly.
- **Cons**: Although it is more organized, it can add complexity if you only need to access one or two states in a simple way.

### **3. Using `keyNotifier` to Access Specific Notifiers**

The `keyNotifier` is useful when you want to access a related state that has a unique key within the `related` relationship. This is especially useful when you have multiple notifiers of the same type (for example, multiple `cartState's`) and you need to distinguish between them.

#### **Using `keyNotifier`**

```dart
class AppDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<AppState>(
      notifier: appState,
      builder: (state, keep) {

        final user = appState.from<UserState>(userState.keyNotifier);  /// Or appState.from(userState.keyNotifier)
        final cart = appState.from<CartState>(cartState.keyNotifier);  /// ....
        final settings = appState.from<SettingsState>(settingsState.keyNotifier); /// ....

        return Column(
          children: [
            Text('Welcome ${user.name}'),
            Text('Cart Items: ${cart.items.length}'),
            Text('Settings: ${settings.theme}'),
            if (user.isLoggedIn) keep(const UserProfile())
          ],
        );
      },
    );
  }
}
```

- **Explanation**:
- `appState.from<CartState>(cartState.keyNotifier)` accesses the cart state using its `keyNotifier`.
- **Pros**: Using `keyNotifier` is useful when you have states of similar types or when you want to specify which instance of a `ReactiveNotifier` to use within a relationship.
- **Cons**: If you only have one `ReactiveNotifier` of each type, this may be unnecessary, but in more complex scenarios with multiple notifiers of the same type, it's a great way to distinguish them.

---

### What to Avoid

```dart
// ❌ NEVER: Nested related states
final cartState = ReactiveNotifier<CartState>(
  () => CartState(),
  related: [userState] // ❌ Don't do this
);

// ❌ NEVER: Chain of related states
final orderState = ReactiveNotifier<OrderState>(
  () => OrderState(),
  related: [cartState] // ❌ Avoid relation chains
);

// ✅ CORRECT: Flat structure with single parent
final appState = ReactiveNotifier<AppState>(
  () => AppState(),
  related: [userState, cartState, orderState]
);
```

## Async & Stream Support

### Async Operations

```dart
class ProductViewModel extends AsyncViewModelImpl<List<Product>> {
  @override
  Future<List<Product>> fetchData() async {
    return await repository.getProducts();
  }
}

class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveAsyncBuilder<List<Product>>(
      notifier: productViewModel,
      onSuccess: (products) => ProductGrid(products),
      onLoading: () => const LoadingSpinner(),
      onError: (error, stack) => ErrorWidget(error),
      onInitial: () => const InitialView(),
    );
  }
}
```

### Stream Handling

```dart
final messagesStream = ReactiveNotifier<Stream<Message>>(
  () => messageRepository.getMessageStream()
);

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveStreamBuilder<Message>(
      notifier: messagesStream,
      onData: (message) => MessageBubble(message),
      onLoading: () => const LoadingIndicator(),
      onError: (error) => ErrorMessage(error),
      onEmpty: () => const NoMessages(),
      onDone: () => const StreamComplete(),
    );
  }
}
```

## Debugging System

ReactiveNotifier includes a comprehensive debugging system with detailed error messages:

### Creation Tracking

```
📦 Creating ReactiveNotifier<UserState>
🔗 With related types: CartState, OrderState
```

### Invalid Structure Detection

```
⚠️ Invalid Reference Structure Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Notifier: CartState
Key: cart_key
Problem: Attempting to create a notifier with an existing key
Solution: Ensure unique keys for each notifier
Location: package:my_app/cart/cart_state.dart:42
```

### Performance Monitoring

```
⚠️ Notification Overflow Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Notifier: CartState
50 notifications in 500ms
❌ Problem: Excessive updates detected
✅ Solution: Review update logic and consider debouncing
```

And more...

## Best Practices

### State Declaration

- Declare ReactiveNotifier instances globally or as static mixin members
- Never create instances inside widgets
- Use mixins for better organization of related states

### Performance Optimization

- Use `keep` for static content
- Maintain flat state hierarchy
- Use keyNotifier for specific state access
- Avoid unnecessary rebuilds

### Architecture Guidelines

- Follow MVVM pattern
- Utilize Repository/Service patterns
- Let ViewModels initialize automatically
- Keep state updates context-independent

### Related States

- Maintain flat relationships
- Avoid circular dependencies
- Use type-safe access
- Keep state updates predictable

## Coming Soon: Real-Time State Inspector 🔍

We're developing a powerful visual debugging interface that will revolutionize how you debug and monitor ReactiveNotifier states:

### Features in Development

- 📊 Real-time state visualization
- 🔄 Live update tracking
- 📈 Performance metrics
- 🕸️ Interactive dependency graph
- ⏱️ Update timeline
- 🔍 Deep state inspection
- 📱 DevTools integration

This tool will help you:

- Understand state flow in real-time
- Identify performance bottlenecks
- Debug complex state relationships
- Monitor rebuild patterns
- Optimize your application
- Develop more efficiently

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
