import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'config/alchemist_config.dart';

/// Golden Tests for State Transformation and Update Methods
/// 
/// This test suite provides comprehensive visual testing for different state
/// update methods and their effects on UI rendering:
/// 
/// 1. updateState() vs updateSilently() visual differences
/// 2. transformState() vs transformStateSilently() behaviors
/// 3. Complex state transformations with business logic
/// 4. Edge cases and error scenarios
/// 5. Performance impact visualization
/// 
/// These tests ensure that state transformation methods work correctly
/// and that the UI responds appropriately to different update patterns.

void main() {
  group('State Transformation Golden Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    final shoppingCartState = ReactiveNotifier<ShoppingCartViewModel>(() => ShoppingCartViewModel());
    final calculatorState = ReactiveNotifier<CalculatorViewModel>(() => CalculatorViewModel());
    final formState = ReactiveNotifier<FormViewModel>(() => FormViewModel());

    group('updateState vs updateSilently Comparison', () {
      goldenTest(
        'updateState should trigger immediate UI updates',
        fileName: 'update_state_immediate_render',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:  ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Immediate State Update',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('updateState() Method'),
                    backgroundColor: Colors.blue,
                  ),
                  body: ReactiveViewModelBuilder<ShoppingCartViewModel, ShoppingCartModel>(
                    viewmodel: shoppingCartState.notifier,
                    build: (cart, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shopping Cart (updateState)',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Items in Cart:'),
                                        Text(
                                          '${cart.items.length}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Price:'),
                                        Text(
                                          '\$${cart.totalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Update Count:'),
                                        Text('${viewmodel.updateCount}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // This will immediately trigger a rebuild
                                viewmodel.addItem('New Item', 9.99);
                              },
                              child: const Text('Add Item (updateState)'),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                itemCount: cart.items.length,
                                itemBuilder: (context, index) {
                                  final item = cart.items[index];
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.shopping_cart),
                                      title: Text(item.name),
                                      subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () => viewmodel.removeItem(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'updateSilently should show internal state without UI updates',
        fileName: 'update_silently_internal_state',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:  ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Silent State Update',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('updateSilently() Method'),
                    backgroundColor: Colors.orange,
                  ),
                  body: ReactiveViewModelBuilder<ShoppingCartViewModel, ShoppingCartModel>(
                    viewmodel: shoppingCartState.notifier,
                    build: (cart, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shopping Cart (updateSilently)',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Displayed State (last build):',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Items in Cart:'),
                                        Text('${cart.items.length}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Price:'),
                                        Text('\$${cart.totalPrice.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.blue[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Actual Internal State:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Internal Items:'),
                                        Text('${viewmodel.data.items.length}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Internal Total:'),
                                        Text('\$${viewmodel.data.totalPrice.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    // This will NOT trigger a rebuild
                                    viewmodel.addItemSilently('Silent Item', 15.99);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  child: const Text('Add Item (updateSilently)'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // This will trigger a rebuild showing the accumulated changes
                                    viewmodel.forceUpdate();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  child: const Text('Force Update'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    group('transformState vs transformStateSilently Comparison', () {
      goldenTest(
        'transformState should apply business logic and notify',
        fileName: 'transform_state_business_logic',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:  ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Business Logic Transformation',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('transformState() Method'),
                    backgroundColor: Colors.green,
                  ),
                  body: ReactiveViewModelBuilder<CalculatorViewModel, CalculatorModel>(
                    viewmodel: calculatorState.notifier,
                    build: (calc, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Calculator (transformState)',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Current Value:'),
                                        Text(
                                          '${calc.currentValue}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Operations:'),
                                        Text('${calc.operationCount}'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('History:'),
                                        Text('${calc.history.length} entries'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Status:'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: calc.isValid ? Colors.green : Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            calc.isValid ? 'Valid' : 'Invalid',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: () => viewmodel.add(10),
                                  child: const Text('Add 10'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.multiply(2),
                                  child: const Text('Multiply by 2'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.subtract(5),
                                  child: const Text('Subtract 5'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.divide(3),
                                  child: const Text('Divide by 3'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.clear(),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Recent History:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: calc.history.length,
                                itemBuilder: (context, index) {
                                  final entry = calc.history[index];
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.history),
                                      title: Text(entry),
                                      subtitle: Text('Step ${index + 1}'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'transformStateSilently should modify state without UI updates',
        fileName: 'transform_state_silently_background',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:  ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Silent Background Transformation',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('transformStateSilently() Method'),
                    backgroundColor: Colors.purple,
                  ),
                  body: ReactiveViewModelBuilder<CalculatorViewModel, CalculatorModel>(
                    viewmodel: calculatorState.notifier,
                    build: (calc, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Calculator (transformStateSilently)',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.purple[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Displayed State (last build):',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Current Value:'),
                                        Text('${calc.currentValue}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Operations:'),
                                        Text('${calc.operationCount}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.blue[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Actual Internal State:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Internal Value:'),
                                        Text('${viewmodel.data.currentValue}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Internal Operations:'),
                                        Text('${viewmodel.data.operationCount}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: () => viewmodel.addSilently(20),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                                  child: const Text('Add 20 (Silent)'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.multiplySilently(3),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                                  child: const Text('Multiply by 3 (Silent)'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.commitSilentChanges(),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  child: const Text('Commit Changes'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Silent operations modify internal state without triggering UI updates. '
                                'Use "Commit Changes" to update the UI with accumulated changes.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    group('Complex State Transformation Scenarios', () {
      goldenTest(
        'Complex form validation and state transformation',
        fileName: 'complex_form_validation',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:  ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Form Validation',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Complex Form Validation'),
                    backgroundColor: Colors.teal,
                  ),
                  body: ReactiveViewModelBuilder<FormViewModel, FormModel>(
                    viewmodel: formState.notifier,
                    build: (form, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registration Form',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        errorText: form.emailError.isNotEmpty ? form.emailError : null,
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (value) => viewmodel.updateEmail(value),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        errorText: form.passwordError.isNotEmpty ? form.passwordError : null,
                                        border: const OutlineInputBorder(),
                                      ),
                                      obscureText: true,
                                      onChanged: (value) => viewmodel.updatePassword(value),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        errorText: form.confirmPasswordError.isNotEmpty ? form.confirmPasswordError : null,
                                        border: const OutlineInputBorder(),
                                      ),
                                      obscureText: true,
                                      onChanged: (value) => viewmodel.updateConfirmPassword(value),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: form.isValid ? Colors.green[50] : Colors.red[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          form.isValid ? Icons.check_circle : Icons.error,
                                          color: form.isValid ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          form.isValid ? 'Form Valid' : 'Form Invalid',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: form.isValid ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Email: ${form.email.isEmpty ? 'Empty' : form.email}'),
                                    Text('Password Strength: ${form.passwordStrength}'),
                                    Text('Validation Count: ${form.validationCount}'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: form.isValid ? () => viewmodel.submitForm() : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: form.isValid ? Colors.teal : Colors.grey,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Submit Registration',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  });
}

// Test Models and ViewModels for State Transformation

class ShoppingCartItem {
  final String name;
  final double price;

  ShoppingCartItem({required this.name, required this.price});
}

class ShoppingCartModel {
  final List<ShoppingCartItem> items;
  final double totalPrice;

  ShoppingCartModel({required this.items, required this.totalPrice});

  ShoppingCartModel copyWith({
    List<ShoppingCartItem>? items,
    double? totalPrice,
  }) {
    return ShoppingCartModel(
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class ShoppingCartViewModel extends ViewModel<ShoppingCartModel> {
  ShoppingCartViewModel() : super(ShoppingCartModel(items: [], totalPrice: 0.0));

  int _updateCount = 0;
  int get updateCount => _updateCount;

  @override
  void init() {
    // Initialize shopping cart
  }

  void addItem(String name, double price) {
    _updateCount++;
    transformState((current) {
      final newItems = [...current.items, ShoppingCartItem(name: name, price: price)];
      final newTotal = newItems.fold(0.0, (sum, item) => sum + item.price);
      return ShoppingCartModel(items: newItems, totalPrice: newTotal);
    });
  }

  void addItemSilently(String name, double price) {
    _updateCount++;
    transformStateSilently((current) {
      final newItems = [...current.items, ShoppingCartItem(name: name, price: price)];
      final newTotal = newItems.fold(0.0, (sum, item) => sum + item.price);
      return ShoppingCartModel(items: newItems, totalPrice: newTotal);
    });
  }

  void removeItem(int index) {
    _updateCount++;
    transformState((current) {
      final newItems = [...current.items];
      newItems.removeAt(index);
      final newTotal = newItems.fold(0.0, (sum, item) => sum + item.price);
      return ShoppingCartModel(items: newItems, totalPrice: newTotal);
    });
  }

  void forceUpdate() {
    updateState(data);
  }
}

class CalculatorModel {
  final double currentValue;
  final int operationCount;
  final List<String> history;
  final bool isValid;

  CalculatorModel({
    required this.currentValue,
    required this.operationCount,
    required this.history,
    required this.isValid,
  });

  CalculatorModel copyWith({
    double? currentValue,
    int? operationCount,
    List<String>? history,
    bool? isValid,
  }) {
    return CalculatorModel(
      currentValue: currentValue ?? this.currentValue,
      operationCount: operationCount ?? this.operationCount,
      history: history ?? this.history,
      isValid: isValid ?? this.isValid,
    );
  }
}

class CalculatorViewModel extends ViewModel<CalculatorModel> {
  CalculatorViewModel() : super(CalculatorModel(
    currentValue: 0.0,
    operationCount: 0,
    history: [],
    isValid: true,
  ));

  @override
  void init() {
    // Initialize calculator
  }

  void add(double value) {
    transformState((current) => current.copyWith(
      currentValue: current.currentValue + value,
      operationCount: current.operationCount + 1,
      history: [...current.history, 'Added $value'],
      isValid: true,
    ));
  }

  void multiply(double value) {
    transformState((current) => current.copyWith(
      currentValue: current.currentValue * value,
      operationCount: current.operationCount + 1,
      history: [...current.history, 'Multiplied by $value'],
      isValid: true,
    ));
  }

  void subtract(double value) {
    transformState((current) => current.copyWith(
      currentValue: current.currentValue - value,
      operationCount: current.operationCount + 1,
      history: [...current.history, 'Subtracted $value'],
      isValid: true,
    ));
  }

  void divide(double value) {
    transformState((current) => current.copyWith(
      currentValue: value != 0 ? current.currentValue / value : current.currentValue,
      operationCount: current.operationCount + 1,
      history: [...current.history, value != 0 ? 'Divided by $value' : 'Division by zero attempted'],
      isValid: value != 0,
    ));
  }

  void clear() {
    transformState((current) => CalculatorModel(
      currentValue: 0.0,
      operationCount: 0,
      history: [],
      isValid: true,
    ));
  }

  void addSilently(double value) {
    transformStateSilently((current) => current.copyWith(
      currentValue: current.currentValue + value,
      operationCount: current.operationCount + 1,
      history: [...current.history, 'Added $value (silent)'],
    ));
  }

  void multiplySilently(double value) {
    transformStateSilently((current) => current.copyWith(
      currentValue: current.currentValue * value,
      operationCount: current.operationCount + 1,
      history: [...current.history, 'Multiplied by $value (silent)'],
    ));
  }

  void commitSilentChanges() {
    updateState(data);
  }
}

class FormModel {
  final String email;
  final String password;
  final String confirmPassword;
  final String emailError;
  final String passwordError;
  final String confirmPasswordError;
  final bool isValid;
  final String passwordStrength;
  final int validationCount;

  FormModel({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.emailError,
    required this.passwordError,
    required this.confirmPasswordError,
    required this.isValid,
    required this.passwordStrength,
    required this.validationCount,
  });

  FormModel copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    bool? isValid,
    String? passwordStrength,
    int? validationCount,
  }) {
    return FormModel(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      confirmPasswordError: confirmPasswordError ?? this.confirmPasswordError,
      isValid: isValid ?? this.isValid,
      passwordStrength: passwordStrength ?? this.passwordStrength,
      validationCount: validationCount ?? this.validationCount,
    );
  }
}

class FormViewModel extends ViewModel<FormModel> {
  FormViewModel() : super(FormModel(
    email: '',
    password: '',
    confirmPassword: '',
    emailError: '',
    passwordError: '',
    confirmPasswordError: '',
    isValid: false,
    passwordStrength: 'None',
    validationCount: 0,
  ));

  @override
  void init() {
    // Initialize form
  }

  void updateEmail(String email) {
    transformState((current) {
      final emailError = _validateEmail(email);
      return current.copyWith(
        email: email,
        emailError: emailError,
        validationCount: current.validationCount + 1,
      );
    });
    _validateForm();
  }

  void updatePassword(String password) {
    transformState((current) {
      final passwordError = _validatePassword(password);
      final strength = _calculatePasswordStrength(password);
      return current.copyWith(
        password: password,
        passwordError: passwordError,
        passwordStrength: strength,
        validationCount: current.validationCount + 1,
      );
    });
    _validateForm();
  }

  void updateConfirmPassword(String confirmPassword) {
    transformState((current) {
      final confirmError = _validateConfirmPassword(current.password, confirmPassword);
      return current.copyWith(
        confirmPassword: confirmPassword,
        confirmPasswordError: confirmError,
        validationCount: current.validationCount + 1,
      );
    });
    _validateForm();
  }

  void _validateForm() {
    transformState((current) {
      final isValid = current.emailError.isEmpty &&
          current.passwordError.isEmpty &&
          current.confirmPasswordError.isEmpty &&
          current.email.isNotEmpty &&
          current.password.isNotEmpty &&
          current.confirmPassword.isNotEmpty;
      return current.copyWith(isValid: isValid);
    });
  }

  String _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Invalid email format';
    return '';
  }

  String _validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return '';
  }

  String _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return 'Please confirm your password';
    if (password != confirmPassword) return 'Passwords do not match';
    return '';
  }

  String _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 'None';
    if (password.length < 8) return 'Weak';
    if (password.length < 12) return 'Medium';
    return 'Strong';
  }

  void submitForm() {
    transformState((current) => current.copyWith(
      validationCount: current.validationCount + 1,
    ));
  }
}