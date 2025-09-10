import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

void main() {
  runApp(const DevToolsExtensionDemo());
}

class DevToolsExtensionDemo extends StatelessWidget {
  const DevToolsExtensionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReactiveNotifier DevTools Extension Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DemoScreen(),
    );
  }
}

// Demo models
class CounterModel {
  final int value;
  final String label;

  CounterModel({required this.value, required this.label});

  CounterModel copyWith({int? value, String? label}) {
    return CounterModel(
      value: value ?? this.value,
      label: label ?? this.label,
    );
  }

  @override
  String toString() => 'CounterModel(value: $value, label: "$label")';
}

class UserModel {
  final String name;
  final int age;
  final bool isActive;

  UserModel({required this.name, required this.age, required this.isActive});

  UserModel copyWith({String? name, int? age, bool? isActive}) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'UserModel(name: "$name", age: $age, active: $isActive)';
}

// ViewModels
class CounterViewModel extends ViewModel<CounterModel> {
  CounterViewModel() : super(CounterModel(value: 0, label: 'Demo Counter'));

  @override
  void init() {
    // Synchronous initialization if needed
  }

  void increment() =>
      transformState((current) => current.copyWith(value: current.value + 1));
  void decrement() =>
      transformState((current) => current.copyWith(value: current.value - 1));
  void reset() => updateState(CounterModel(value: 0, label: data.label));
}

class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel(name: 'Guest', age: 25, isActive: false));

  @override
  void init() {
    // Synchronous initialization if needed
  }

  void updateName(String name) =>
      transformState((current) => current.copyWith(name: name));
  void updateAge(int age) =>
      transformState((current) => current.copyWith(age: age));
  void toggleActive() => transformState(
      (current) => current.copyWith(isActive: !current.isActive));
}

// Services
mixin CounterService {
  static final ReactiveNotifier<CounterViewModel> instance =
      ReactiveNotifier<CounterViewModel>(() => CounterViewModel());
}

mixin UserService {
  static final ReactiveNotifier<UserViewModel> instance =
      ReactiveNotifier<UserViewModel>(() => UserViewModel());

  // Simple notifier example
  static final ReactiveNotifier<String> status =
      ReactiveNotifier<String>(() => 'Ready');
}

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReactiveNotifier DevTools Extension Demo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.extension, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DevTools Extension Active!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Open Flutter DevTools → ReactiveNotifier tab to inspect state',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Counter Section
            const SectionHeader(
                title: 'Counter ViewModel', icon: Icons.add_circle),
            const SizedBox(height: 8),
            ReactiveViewModelBuilder<CounterViewModel, CounterModel>(
              viewmodel: CounterService.instance.notifier,
              build: (counter, viewModel, keep) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          counter.label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${counter.value}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: viewModel.decrement,
                              icon: const Icon(Icons.remove),
                              label: const Text('Decrement'),
                            ),
                            ElevatedButton.icon(
                              onPressed: viewModel.increment,
                              icon: const Icon(Icons.add),
                              label: const Text('Increment'),
                            ),
                            ElevatedButton.icon(
                              onPressed: viewModel.reset,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // User Section
            const SectionHeader(title: 'User ViewModel', icon: Icons.person),
            const SizedBox(height: 8),
            ReactiveViewModelBuilder<UserViewModel, UserModel>(
              viewmodel: UserService.instance.notifier,
              build: (user, viewModel, keep) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: ${user.name}',
                            style: const TextStyle(fontSize: 16)),
                        Text('Age: ${user.age}',
                            style: const TextStyle(fontSize: 16)),
                        Text('Status: ${user.isActive ? 'Active' : 'Inactive'}',
                            style: TextStyle(
                                fontSize: 16,
                                color:
                                    user.isActive ? Colors.green : Colors.red)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton(
                              onPressed: () => viewModel.updateName(
                                  'User ${DateTime.now().millisecond}'),
                              child: const Text('Random Name'),
                            ),
                            ElevatedButton(
                              onPressed: () => viewModel.updateAge(
                                  (20 + (DateTime.now().millisecond % 40))),
                              child: const Text('Random Age'),
                            ),
                            ElevatedButton(
                              onPressed: viewModel.toggleActive,
                              child: const Text('Toggle Status'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Simple Notifier Section
            const SectionHeader(title: 'Simple Notifier', icon: Icons.circle),
            const SizedBox(height: 8),
            ReactiveBuilder<String>(
              notifier: UserService.status,
              build: (status, notifier, keep) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Status: $status',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  UserService.status.updateState('Loading...'),
                              child: const Text('Loading'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  UserService.status.updateState('Success!'),
                              child: const Text('Success'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  UserService.status.updateState('Error'),
                              child: const Text('Error'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        const Text('How to use DevTools Extension:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Run this app in debug mode'),
                    const Text(
                        '2. Open Flutter DevTools in your browser or IDE'),
                    const Text('3. Look for the "ReactiveNotifier" tab'),
                    const Text(
                        '4. Interact with the widgets above to see real-time state changes'),
                    const Text(
                        '5. Monitor ViewModels and simple notifiers independently'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
