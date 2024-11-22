# ReactiveNotifier

A flexible, elegant, and secure tool for state management in Flutter. Designed to easily integrate with architectural patterns like MVVM, it guarantees full independence from BuildContext and is suitable for projects of any scale.

![reactive_notifier](https://github.com/user-attachments/assets/ca97c7e6-a254-4b19-b58d-fd07206ff6ee)

[![Dart SDK Version](https://img.shields.io/badge/Dart-SDK%20%3E%3D%202.17.0-0175C2?logo=dart)](https://dart.dev)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/reactive_notifier.svg)](https://pub.dev/packages/reactive_notifier)
[![likes](https://img.shields.io/pub/likes/reactive_notifier?logo=dart)](https://pub.dev/packages/reactive_notifier/score)
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
- ⚡  High performance with minimal rebuilds
- 🐛 Powerful debugging tools
- 📊 Detailed error reporting

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  reactive_notifier: ^2.3.0
```

## Quick Start

### **Basic Usage with ReactiveNotifier and `ReactiveBuilder.notifier`**

#### **Example: Handling a Simple State**

This example demonstrates how to manage a basic state that stores a `String`. It shows how to declare the state, create a widget to display it, and update its value:

```dart
import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

// Declare a simple state
final messageState = ReactiveNotifier<String>(() => "Hello, world!");

class SimpleExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ReactiveNotifier Example")),
      body: Center(
        child: ReactiveBuilder.notifier(
          notifier: messageState,
          builder: (context, value, keep) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value, // Display the current state
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                keep(
                  ElevatedButton(
                    onPressed: () => messageState.updateState("New message!"),
                    child: Text("Update Message"),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```
---

### **Example Description**

1. **State Declaration:**
    - `ReactiveNotifier<String>` is used to manage a state of type `String`.
    - You can use other primitive types such as `int`, `double`, `bool`, `enum`, etc.

2. **ReactiveBuilder.notifier:**
    - Observes the state and automatically updates the UI when its value changes.
    - Accepts three parameters in the `builder` method:
        - `context`: The widget's context.
        - `value`: The current value of the state.
        - `keep`: Prevents uncontrolled widget rebuilds.

3. **State Update:**
    - The `updateState` method is used to change the state value.
    - Whenever the state is updated, the UI dependent on it automatically rebuilds.

## **1. Model Class Definition**

We'll create a `MyClass` model with some properties such as `String` and `int`.

```dart
class MyClass {
  final String name;
  final int value;

  MyClass({required this.name, required this.value});

  // Method to create an empty instance
  MyClass.empty() : name = '', value = 0;

  // Method to clone and update values
  MyClass copyWith({String? name, int? value}) {
    return MyClass(
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}
```


## **2. Create and Update State with `ReactiveNotifier`**

Now, we'll use `ReactiveNotifier` to manage the state of `MyClass`. We'll start with an empty state and later update it using the `updateState` method.

```dart
final myReactive = ReactiveNotifier<MyClass>(() => MyClass.empty());
```

Here, `myReactive` is a `ReactiveNotifier` managing the state of `MyClass`.

---

## **3. Display and Update State with `ReactiveBuilder.notifier`**

We'll use `ReactiveBuilder.notifier` to display the current state of `MyClass` and update it when needed.

```dart
import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Direct ReactiveNotifier")),
        body: Center(
          child: ReactiveBuilder.notifier(
            notifier: myReactive,
            builder: (context, state, keep) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Name: ${state.name}"),
                  Text("Value: ${state.value}"),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Update the state with new values
                      myReactive.updateState(state.copyWith(name: "New Name", value: 42));
                    },
                    child: Text("Update State"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

### **Advantages of This Approach**

- **Simplicity**: This example is straightforward and easy to understand, making it ideal for handling simple states without requiring a `ViewModel` or repository.
- **Reactivity**: With `ReactiveNotifier` and `ReactiveBuilder.notifier`, the UI automatically updates whenever the state changes.
- **Immutability**: `MyClass` follows the immutability pattern, simplifying state management and preventing unexpected side effects.


## **Shopping Cart with `ViewModelStateImpl`**

### **1. Defining the Model**

The `CartModel` class represents the shopping cart's state. It contains the data and includes a `copyWith` method for creating a new instance with updated values.

```dart
class CartModel {
  final List<String> items;
  final double total;

  CartModel({this.items = const [], this.total = 0.0});

  // Method to clone the model with updated values
  CartModel copyWith({List<String>? items, double? total}) {
    return CartModel(
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }
}
```

### **2. ViewModel for Managing Cart Logic**

The `ViewModel` contains the logic for modifying the cart's state. Instead of using `state.copyWith`, use `value.copyWith` to access the current state and update it.

```dart
class CartViewModel extends ViewModelStateImpl<CartModel> {
  CartViewModel() : super(CartModel());

  // Function to add a product to the cart and update the total
  void addProduct(String item, double price) {
    final updatedItems = List<String>.from(value.items)..add(item);
    final updatedTotal = value.total + price;
    updateState(value.copyWith(items: updatedItems, total: updatedTotal));
  }

  // Function to empty the cart
  void clearCart() {
    updateState(CartModel());
  }
}
```

---

### **3. Creating the ViewModel Instance**

Create the `ViewModel` instance that will manage the cart's state.

```dart
final cartViewModel = ReactiveNotifier<CartViewModel>(() => CartViewModel());
```

---

### **4. Widget to Display Cart State**

Finally, create a widget that observes the cart's state and updates the UI whenever necessary.

```dart
import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shopping Cart")),
      body: Center(
        child: ReactiveBuilder<CartViewModel>(
          valueListenable: cartViewModel.value,
          builder: (context, viewModel, keep) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Products in Cart:"),
                ...viewModel.items.map((item) => Text(item)).toList(),
                SizedBox(height: 20),
                Text("Total: \$${viewModel.total.toStringAsFixed(2)}"),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    keep(
                      ElevatedButton(
                        onPressed: () {
                          // Add a new product
                          cartViewModel.value.addProduct("Product A", 19.99);
                        },
                        child: Text("Add Product A"),
                      ),
                    ),
                    SizedBox(width: 10),
                    keep(
                      ElevatedButton(
                        onPressed: () {
                          // Clear the cart
                          cartViewModel.value.clearCart();
                        },
                        child: Text("Clear Cart"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

### **Explanation**

1. **Model (`CartModel`)**:
    - `CartModel` is a class that holds the shopping cart data (`items` and `total`).
    - The `copyWith` method allows creating a new instance of the model with modified values while maintaining immutability.

2. **ViewModel (`CartViewModel`)**:
    - `CartViewModel` extends `ViewModelStateImpl<CartModel>` and handles business logic.
    - Instead of `state.copyWith`, `value.copyWith` is used to access and update the current state.
    - The methods `addProduct` and `clearCart` update the state using `updateState`.

3. **UI with `ReactiveBuilder`**:
    - `ReactiveBuilder` observes the `ViewModel` state and rebuilds the UI when the state changes.
    - The `keep` function is used to prevent unnecessary button rebuilds, improving performance.

---

### **Using the Library Repository with `ViewModelImpl`**

In this example, we are going to use the library's built-in repository to get and update the shopping cart data in the `ViewModelImpl`.

---

## **1. Defining the Repository using the library**

First, instead of creating a repository manually, we are going to use a repository provided by the library to interact with the data. Let's say you have a repository to handle cart-related data.

```dart
import 'package:reactive_notifier/reactive_notifier.dart';

class CartRepository extends RepositoryImpl<CartModel> {
	// We simulate the loading of a shopping cart
  
  Future<CartModel> fetchData() async {
    await Future.delayed(Duration(seconds: 2));
    return CartModel(
      items: ['Producto A', 'Producto B'],
      total: 39.98,
    );
  }

  // Method to add a product to the cart
  Future<void> agregarProducto(CartModel carrito, String item, double price) async {
    await Future.delayed(Duration(seconds: 1));
    carrito.items.add(item);
    carrito.total += price;
  }
}
```

---

## **2. Cart Model (`CartModel`)**

The model remains the same:

```dart
class CartModel {
  final List<String> items;
  final double total;

  CartModel({this.items = const [], this.total = 0.0});

  // Method to clone the model with new values
  CartModel copyWith({List<String>? items, double? total}) {
    return CartModel(
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }
}
```

---

## **3. `ViewModelImpl` with the Repository**

Now we are going to use the repository in the `ViewModelImpl` to interact with the cart model. The `ViewModelImpl` will leverage the repository to get data and make updates.

```dart
class CartViewModel extends ViewModelImpl<CartModel> {
  final CartRepository repository;

  CartViewModel(this.repository) : super(CartModel());

  // Function to load the cart from the repository
  Future<void> cargarCarrito() async {
    try {
    	// We get the cart from the repository
      final carrito = await repository.fetchData();
      setState(carrito); // We update the status with the cart loaded
    } catch (e) {
    // Error handling
      print("Error al cargar el carrito: $e");
    }
  }

  // Function to add a product to the cart
  Future<void> agregarProducto(String item, double price) async {
    try {
      await repository.agregarProducto(value, item, price);
      // We update the status after adding the product
      updateState(value.copyWith(items: value.items, total: value.total));
    } catch (e) {
    // Error handling
      print("Error al agregar el producto: $e");
    }
  }
}
```


## **4. Repository Instance and `ViewModelImpl`**

Here we create the repository instance and the `ViewModelImpl`:

```dart
final cartViewModel = ReactiveNotifier<CartViewModel>((){
	final cartRepository = CartRepository();
	return CartViewModel(cartRepository);
});
```

---

## **5. Cart Status Widget**

Finally, we are going to display the cart status in the UI using `ReactiveBuilder`, which will automatically update when the status changes.

```dart
class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carrito de Compras")),
      body: Center(
        child: ReactiveBuilder<CartViewModel>(
          valueListenable: cartViewModel.value,
          builder: (context, viewModel, keep) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (viewModel.items.isEmpty)
                  keep(Text("Loading cart...")),
                if (viewModel.items.isNotEmpty) ...[
                  keep(Text("Products in cart:")),
                  ...viewModel.items.map((item) => Text(item)).toList(),
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
                            cartViewModel.value.agregarProducto("Producto C", 29.99);
                          },
                          child: Text("Agregar Producto C"),
                        ),
                      ),
                      keep(const SizedBox(width: 10)),
                      keep(
                        ElevatedButton(
                          onPressed: () {
                          // Empty cart
                            cartViewModel.value.setState(CartModel());
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
        ),
      ),
    );
  }
}


```


### **Explanation of the Example**

1. **Repository (`CartRepository`)**:
- The repository extends `RepositoryImpl<CartModel>`, allowing you to interact with the cart data model.
- The `fetchData` function simulates fetching the cart data, and `addProduct` simulates adding products to the cart.

2. **Model (`CartModel`)**:
- `CartModel` contains the cart data (items and total).
- The `copyWith` method is used to create a new instance with modified values, maintaining immutability.

3. **`ViewModelImpl` (`CartViewModel`)**:
- `CartViewModel` extends `ViewModelImpl<CartModel>`, allowing you to handle the cart business logic.
- The `loadCart` and `addProduct` methods interact with the repository and update the state of the cart.

4. **UI with `ReactiveBuilder`**:
- `ReactiveBuilder` observes the state of the `ViewModel` and updates the UI automatically when the state changes.
- `keep` is used to avoid unnecessary button rebuilds.


### **Advantages of Using `ViewModelImpl` with Repository**

- **Decoupling**: Data access logic is separated in the repository, while the `ViewModel` handles business logic and UI interaction.
- **Scalability**: You can easily change the repository implementation, for example to use a real API or a local database, without modifying the `ViewModel`.
- **Error Handling**: The `ViewModel` handles errors centrally and updates the state in case of failures.

---

## **Documentation for `related` in `ReactiveNotifier`**

The `related` attribute in `ReactiveNotifier` allows you to efficiently manage interdependent states. They can be used in different ways depending on the structure and complexity of the state you need to handle.

### **Types of `related` Usage**

1. **Direct Relationship between Simple Notifiers**
- This is the case where you have multiple independent `ReactiveNotifier`s (of simple type like `int`, `String`, `bool`, etc.) and you want any change in one of these notifiers to trigger an update in a `ReactiveBuilder` that is watched by a combined `ReactiveNotifier`.

2. **Relationship between a Main `ReactiveNotifier` and Other Complementary Notifiers**
- In this approach, a main `ReactiveNotifier` handles a complex class (e.g. `UserInfo`), and other notifiers complement this state, such as `Settings`. The companion states are managed separately, but are related to the main state via `related`. Changes to any of the related notifiers cause the `ReactiveBuilder` to be updated.

---

### **1. Direct Relationship between Simple Notifiers**

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

#### **Using with `ReactiveBuilder`**

```dart
ReactiveBuilder.notifier(
  notifier: combinedNotifier,
  builder: (context, _, keep) {
    return Column(
      children: [
        Text("Horas: ${timeHoursNotifier.value}"),
        Text("Ruta: ${routeNotifier.value}"),
        Text("Estado: ${statusNotifier.value ? 'Activo' : 'Inactivo'}"),
      ],
    );
  },
);
```

- **Explanation**:
  `ReactiveBuilder` watches the `combinedNotifier`. Since the related notifiers are configured, any changes to `timeHoursNotifier`, `routeNotifier`, or `statusNotifier` will automatically update the UI.

---

### **2. Relationship between a Main `ReactiveNotifier` and Other Complementary Notifiers**

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

final userInfoNotifier = ReactiveNotifier<UserInfo>(() => UserInfo.empty());

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

#### **Using with `ReactiveBuilder`**

```dart
ReactiveBuilder<UserInfo>(
  valueListenable: userStateNotifier.value,
  builder: (context, userInfo, keep) {
    return Column(
      children: [
        Text("Usuario: ${userInfo.name}, Edad: ${userInfo.age}"),
        Text("Configuración: ${settingsNotifier.value}"),
        Text("Notificaciones: ${notificationsEnabledNotifier.value ? 'Habilitadas' : 'Deshabilitadas'}"),
      ],
    );
  },
);
```

- **Explanation**:
  `ReactiveBuilder` watches `userStateNotifier.value` (the user state). It also watches the related notifiers (settings and notifications). This means that any change to any of these notifiers will trigger an update in the UI.

#### **Usage with `ReactiveBuilder.notifier`**

```dart
ReactiveBuilder.notifier(
  notifier: userStateNotifier,
  builder: (context, userInfo, keep) {
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

- **Explanation**:
  We use `ReactiveBuilder.notifier` to directly observe and update the `userStateNotifier`. When the user's name or any other value changes, it is automatically updated in the UI.

---

### **Advantages of Using `related` in `ReactiveNotifier`**

1. **Flexibility**:
   You can relate simple and complex notifiers without the need to involve additional classes. This is useful for handling states that depend on multiple values ​​without overcomplicating the structure.

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
      valueListenable: appState,
      builder: (context, state, keep) {
        
        final user = userState.value;
        final cart = cartState.value;
        final settings = settingsState.value;

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
- Here, we directly access the values ​​of `userState`, `cartState`, and `settingsState` using `.value`.
- **Pros**: It's a quick and straightforward way to access the values ​​if you don't need to perform any extra logic on them.
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
      valueListenable: appState,
      builder: (context, state, keep) {
        
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

The `keyNotifier` is useful when you want to access a related state that has a unique key within the `related` relationship. This is especially useful when you have multiple notifiers of the same type (for example, multiple `cartState`s) and you need to distinguish between them.

#### **Using `keyNotifier`**

```dart
class AppDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<AppState>(
      valueListenable: appState,
      builder: (context, state, keep) {
       
        final user = appState.from<UserState>(userState.keyNotifier);
        final cart = appState.from<CartState>(cartState.keyNotifier);
        final settings = appState.from<SettingsState>(settingsState.keyNotifier);

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

### **Summary of Ways to Access Related States**

1. **Direct Access to `ReactiveNotifier`**:
- **Simplest way**: `userState.value or final user = userState.value;`
- **Ideal for simple, straightforward states**.

2. **Using `from<T>()`**:
- **Explicit access to a related state**: `final user = appState.from<UserState>();`
- **Ideal for handling more complex relationships between notifiers and extracting values ​​from a specific state**.

3. **Using `keyNotifier`**:
- **Access to a related state with a unique identifier**: `final cart = appState.from<CartState>(cartState.keyNotifier);`
- **Ideal for handling notifiers of the same type and differentiating between them**.


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
      viewModel: productViewModel,
      buildSuccess: (products) => ProductGrid(products),
      buildLoading: () => const LoadingSpinner(),
      buildError: (error, stack) => ErrorWidget(error),
      buildInitial: () => const InitialView(),
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
      streamNotifier: messagesStream,
      buildData: (message) => MessageBubble(message),
      buildLoading: () => const LoadingIndicator(),
      buildError: (error) => ErrorMessage(error),
      buildEmpty: () => const NoMessages(),
      buildDone: () => const StreamComplete(),
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
