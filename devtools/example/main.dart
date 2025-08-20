import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

void main() {
  runApp(const DevToolsExampleApp());
}

class DevToolsExampleApp extends StatelessWidget {
  const DevToolsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReactiveNotifier DevTools Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

// Example models
class CounterModel {
  final int value;
  final String label;
  final DateTime lastUpdated;

  CounterModel({
    required this.value,
    required this.label,
    required this.lastUpdated,
  });

  CounterModel copyWith({
    int? value,
    String? label,
    DateTime? lastUpdated,
  }) {
    return CounterModel(
      value: value ?? this.value,
      label: label ?? this.label,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() => 'CounterModel(value: $value, label: $label, lastUpdated: $lastUpdated)';
}

class UserModel {
  final String name;
  final String email;
  final bool isActive;
  final int points;

  UserModel({
    required this.name,
    required this.email,
    required this.isActive,
    required this.points,
  });

  UserModel copyWith({
    String? name,
    String? email,
    bool? isActive,
    int? points,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      points: points ?? this.points,
    );
  }

  @override
  String toString() => 'UserModel(name: $name, email: $email, isActive: $isActive, points: $points)';
}

// ViewModels
class CounterViewModel extends ViewModel<CounterModel> {
  CounterViewModel() : super(CounterModel(
    value: 0,
    label: 'Demo Counter',
    lastUpdated: DateTime.now(),
  ));

  @override
  void init() {
    // Initialize counter ViewModel
  }

  void increment() {
    transformState((current) => current.copyWith(
      value: current.value + 1,
      lastUpdated: DateTime.now(),
    ));
  }

  void decrement() {
    transformState((current) => current.copyWith(
      value: current.value - 1,
      lastUpdated: DateTime.now(),
    ));
  }

  void reset() {
    updateState(CounterModel(
      value: 0,
      label: data.label,
      lastUpdated: DateTime.now(),
    ));
  }

  void updateLabel(String newLabel) {
    transformStateSilently((current) => current.copyWith(
      label: newLabel,
      lastUpdated: DateTime.now(),
    ));
  }
}

class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel(
    name: 'John Doe',
    email: 'john@example.com',
    isActive: true,
    points: 100,
  ));

  @override
  void init() {
    // Initialize user ViewModel
  }

  void toggleActive() {
    transformState((current) => current.copyWith(
      isActive: !current.isActive,
    ));
  }

  void addPoints(int points) {
    transformState((current) => current.copyWith(
      points: current.points + points,
    ));
  }

  void updateProfile(String name, String email) {
    updateState(data.copyWith(
      name: name,
      email: email,
    ));
  }
}

class DataViewModel extends AsyncViewModelImpl<List<String>> {
  DataViewModel() : super(AsyncState.initial(), loadOnInit: true);

  @override
  Future<List<String>> init() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    return ['Item 1', 'Item 2', 'Item 3'];
  }

  Future<void> addItem(String item) async {
    loadingState();
    await Future.delayed(const Duration(milliseconds: 500));
    
    final currentData = data ?? [];
    updateState([...currentData, item]);
  }

  Future<void> removeItem(int index) async {
    final currentData = data ?? [];
    if (index >= 0 && index < currentData.length) {
      final newData = List<String>.from(currentData);
      newData.removeAt(index);
      updateState(newData);
    }
  }

  Future<void> refreshData() async {
    await reload();
  }
}

// Services
mixin CounterService {
  static final ReactiveNotifier<CounterViewModel> instance = 
    ReactiveNotifier<CounterViewModel>(() => CounterViewModel());
}

mixin UserService {
  static final ReactiveNotifier<UserViewModel> instance = 
    ReactiveNotifier<UserViewModel>(() => UserViewModel());
}

mixin DataService {
  static final ReactiveNotifier<DataViewModel> instance = 
    ReactiveNotifier<DataViewModel>(() => DataViewModel());
}

// UI Components
class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReactiveNotifier DevTools Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              // Create some memory pressure for testing
              for (int i = 0; i < 10; i++) {
                ReactiveNotifier<String>(() => 'Temporary $i');
              }
            },
            icon: const Icon(Icons.memory),
            tooltip: 'Create temporary instances',
          ),
          IconButton(
            onPressed: ReactiveNotifier.cleanup,
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Cleanup all instances',
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ReactiveNotifier DevTools Extension Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This demo app showcases the ReactiveNotifier DevTools extension. '
              'Open Flutter DevTools and navigate to the "ReactiveNotifier" tab to see the extension in action.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            CounterSection(),
            SizedBox(height: 24),
            UserSection(),
            SizedBox(height: 24),
            DataSection(),
            SizedBox(height: 24),
            DebugActionsSection(),
          ],
        ),
      ),
    );
  }
}

class CounterSection extends StatelessWidget {
  const CounterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Counter Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ReactiveViewModelBuilder<CounterViewModel, CounterModel>(
              viewmodel: CounterService.instance.notifier,
              build: (counter, viewModel, keep) {
                return Column(
                  children: [
                    Text(
                      '${counter.label}: ${counter.value}',
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(
                      'Last updated: ${counter.lastUpdated.toIso8601String().substring(11, 19)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: viewModel.decrement,
                          child: const Text('Decrement'),
                        ),
                        ElevatedButton(
                          onPressed: viewModel.increment,
                          child: const Text('Increment'),
                        ),
                        ElevatedButton(
                          onPressed: viewModel.reset,
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Counter Label',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: viewModel.updateLabel,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UserSection extends StatelessWidget {
  const UserSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ReactiveViewModelBuilder<UserViewModel, UserModel>(
              viewmodel: UserService.instance.notifier,
              build: (user, viewModel, keep) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${user.name}'),
                    Text('Email: ${user.email}'),
                    Text('Status: ${user.isActive ? "Active" : "Inactive"}'),
                    Text('Points: ${user.points}'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: viewModel.toggleActive,
                          child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                        ),
                        ElevatedButton(
                          onPressed: () => viewModel.addPoints(10),
                          child: const Text('+10 Points'),
                        ),
                        ElevatedButton(
                          onPressed: () => viewModel.addPoints(-5),
                          child: const Text('-5 Points'),
                        ),
                        ElevatedButton(
                          onPressed: () => viewModel.updateProfile(
                            'Jane Smith',
                            'jane@example.com',
                          ),
                          child: const Text('Change Profile'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Async Data Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ReactiveAsyncBuilder<DataViewModel, List<String>>(
              notifier: DataService.instance.notifier,
              onData: (data, viewModel, keep) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items: ${data.length}'),
                    const SizedBox(height: 8),
                    ...data.asMap().entries.map((entry) {
                      return ListTile(
                        dense: true,
                        title: Text(entry.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => viewModel.removeItem(entry.key),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'New Item',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                viewModel.addItem(value.trim());
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: viewModel.refreshData,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                );
              },
              onLoading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              onError: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class DebugActionsSection extends StatelessWidget {
  const DebugActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Use these actions to test the DevTools extension:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Create rapid state changes
                    final counter = CounterService.instance.notifier;
                    for (int i = 0; i < 10; i++) {
                      Future.delayed(Duration(milliseconds: i * 100), () {
                        counter.increment();
                      });
                    }
                  },
                  child: const Text('Rapid Updates'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Create temporary instances
                    for (int i = 0; i < 5; i++) {
                      ReactiveNotifier<int>(() => i);
                    }
                  },
                  child: const Text('Create Temp Instances'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Silent updates
                    CounterService.instance.notifier.updateLabel('Silent Update ${DateTime.now().millisecondsSinceEpoch}');
                  },
                  child: const Text('Silent Update'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Memory stress test
                    final data = List.generate(1000, (i) => 'Large data $i' * 100);
                    final notifier = ReactiveNotifier<List<String>>(() => data);
                    notifier.updateState(data);
                  },
                  child: const Text('Memory Stress'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Show debug info
                    final instanceCount = ReactiveNotifier.instanceCount;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Active instances: $instanceCount')),
                    );
                  },
                  child: const Text('Show Debug Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}