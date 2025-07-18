import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'config/alchemist_config.dart';

/// Comprehensive Golden Tests for ReactiveNotifier Visual Regression Testing
///
/// This test suite provides visual regression testing for ReactiveNotifier components,
/// verifying that state updates and rebuilds render correctly across different scenarios:
///
/// 1. ReactiveBuilder state updates and partial rebuilds
/// 2. ReactiveViewModelBuilder with complex state objects
/// 3. ReactiveAsyncBuilder with loading, success, and error states
/// 4. Cross-component communication and reactive chains
/// 5. Performance scenarios with rapid updates
/// 6. Error handling and edge cases
///
/// Each test captures golden images that serve as visual baselines for detecting
/// unintended UI changes during refactoring or feature development.

void main() {
  group('ReactiveNotifier Comprehensive Golden Tests', () {
    setUp(() {
      // Clean up state before each test
      ReactiveNotifier.cleanup();
    });

    // Test models for complex state scenarios
    final counterState = ReactiveNotifier<int>(() => 0);
    final userState = ReactiveNotifier<UserViewModel>(() => UserViewModel());
    final asyncDataState =
        ReactiveNotifier<DataAsyncViewModel>(() => DataAsyncViewModel());

    group('ReactiveBuilder State Updates', () {
      goldenTest(
        'ReactiveBuilder should show initial state correctly',
        fileName: 'reactive_builder_initial_state',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          columns: 1,
          children: [
            GoldenTestScenario(
              name: 'Initial Counter State',
              child: MaterialApp(
                home: Scaffold(
                  body: ReactiveBuilder<int>(
                    notifier: counterState,
                    build: (value, notifier, keep) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Counter Value: $value',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          keep(const Text(
                            'This widget never rebuilds',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          )),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    counterState.updateState(value - 1),
                                child: const Text('-'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    counterState.updateState(value + 1),
                                child: const Text('+'),
                              ),
                            ],
                          ),
                        ],
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
        'ReactiveBuilder should show state after multiple updates',
        fileName: 'reactive_builder_updated_state',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Updated Counter State',
              child: MaterialApp(
                home: Scaffold(
                  body: ReactiveBuilder<int>(
                    notifier: counterState,
                    build: (value, notifier, keep) {
                      // Simulate multiple updates to show final state
                      if (value == 0) {
                        // Chain multiple updates to test final render
                        Future.microtask(() {
                          counterState.updateState(5);
                          counterState.updateState(10);
                          counterState.updateState(15);
                        });
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Counter Value: $value',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: value > 10 ? Colors.green : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: value / 20.0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              value > 10 ? Colors.green : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          keep(const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'This card never rebuilds\nregardless of state changes',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          )),
                        ],
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
        'ReactiveBuilder should handle silent updates correctly',
        fileName: 'reactive_builder_silent_updates',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Silent Update Behavior',
              child: MaterialApp(
                home: Scaffold(
                  body: ReactiveBuilder<int>(
                    notifier: counterState,
                    build: (value, notifier, keep) {
                      // Simulate silent update that shouldn't trigger rebuild
                      if (value == 0) {
                        Future.microtask(() {
                          counterState.updateSilently(100); // Silent update
                          counterState.updateState(25); // Normal update
                        });
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Displayed Value: $value',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Actual Internal Value: ${counterState.notifier}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Silent updates change internal state\nbut don\'t trigger rebuilds',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
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

    group('ReactiveViewModelBuilder Complex State', () {
      goldenTest(
        'ReactiveViewModelBuilder should render complex user state',
        fileName: 'reactive_viewmodel_user_state',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'User Profile State',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('User Profile'),
                    backgroundColor: Colors.blue,
                  ),
                  body: ReactiveViewModelBuilder<UserViewModel, UserModel>(
                    viewmodel: userState.notifier,
                    build: (user, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 24, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        user.email,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Profile Statistics',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Login Count:'),
                                        Text('${user.loginCount}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Status:'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: user.isActive
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            keep(const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'This section never rebuilds\neven when user state changes',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            )),
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
        'ReactiveViewModelBuilder should show updated user state',
        fileName: 'reactive_viewmodel_updated_user',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Updated User Profile',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('User Profile'),
                    backgroundColor: Colors.blue,
                  ),
                  body: ReactiveViewModelBuilder<UserViewModel, UserModel>(
                    viewmodel: userState.notifier,
                    build: (user, viewmodel, keep) {
                      // Simulate user state update
                      if (user.name == 'John Doe') {
                        Future.microtask(() {
                          viewmodel.updateUserProfile(
                            name: 'Jane Smith',
                            email: 'jane.smith@example.com',
                            isActive: true,
                            loginCount: 15,
                          );
                        });
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor:
                                      user.isActive ? Colors.green : Colors.red,
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 24, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        user.email,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Profile Statistics',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Login Count:'),
                                        Text('${user.loginCount}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Status:'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: user.isActive
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

    group('ReactiveAsyncBuilder State Management', () {
      goldenTest(
        'ReactiveAsyncBuilder should show loading state',
        fileName: 'reactive_async_loading_state',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Loading State',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Data Loading'),
                    backgroundColor: Colors.purple,
                  ),
                  body: ReactiveAsyncBuilder<DataAsyncViewModel, List<String>>(
                    notifier: asyncDataState.notifier,
                    onLoading: () => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading data...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    onData: (data, viewModel, keep) => ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const Icon(Icons.data_usage),
                        title: Text(data[index]),
                        subtitle: Text('Item ${index + 1}'),
                      ),
                    ),
                    onError: (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $error',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'ReactiveAsyncBuilder should show success state with data',
        fileName: 'reactive_async_success_state',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Success State with Data',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Data Loaded'),
                    backgroundColor: Colors.green,
                  ),
                  body: ReactiveAsyncBuilder<DataAsyncViewModel, List<String>>(
                    notifier: asyncDataState.notifier,
                    onLoading: () =>
                        const Center(child: CircularProgressIndicator()),
                    onData: (data, viewModel, keep) {
                      // Simulate loading success data
                      if (data.isEmpty) {
                        Future.microtask(() {
                          viewModel.loadSuccessData([
                            'Item 1: User Data',
                            'Item 2: Settings',
                            'Item 3: Preferences',
                            'Item 4: History',
                            'Item 5: Cache',
                          ]);
                        });
                      }

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.green[50],
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Data loaded successfully (${data.length} items)',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: data.length,
                              itemBuilder: (context, index) => Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(data[index]),
                                  subtitle: Text(
                                      'Loaded at ${DateTime.now().toString().substring(11, 19)}'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    onError: (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Error: $error'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'ReactiveAsyncBuilder should show error state',
        fileName: 'reactive_async_error_state',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Error State',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Data Error'),
                    backgroundColor: Colors.red,
                  ),
                  body: ReactiveAsyncBuilder<DataAsyncViewModel, List<String>>(
                    notifier: asyncDataState.notifier,
                    onLoading: () =>
                        const Center(child: CircularProgressIndicator()),
                    onData: (data, viewModel, keep) => ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(data[index]),
                      ),
                    ),
                    onError: (error, stackTrace) {
                      // Simulate error state
                      if (error.toString().isEmpty) {
                        Future.microtask(() {
                          asyncDataState.notifier
                              .simulateError('Network connection failed');
                        });
                      }

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'Oops! Something went wrong',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error: $error',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    asyncDataState.notifier.reload(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
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

    group('Cross-Component Communication', () {
      goldenTest(
        'Cross-component reactive updates should render correctly',
        fileName: 'cross_component_communication',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Reactive Communication',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Reactive Components'),
                    backgroundColor: Colors.indigo,
                  ),
                  body: Column(
                    children: [
                      // Counter component
                      Expanded(
                        child: ReactiveBuilder<int>(
                          notifier: counterState,
                          build: (value, notifier, keep) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.blue[50],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Counter Component',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Count: $value',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      counterState.updateState(value + 1);
                                      // Update user's login count when counter changes
                                      userState.notifier.incrementLoginCount();
                                    },
                                    child: const Text('Increment'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // User component that reacts to counter changes
                      Expanded(
                        child:
                            ReactiveViewModelBuilder<UserViewModel, UserModel>(
                          viewmodel: userState.notifier,
                          build: (user, viewmodel, keep) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.green[50],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'User Component',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'User: ${user.name}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Login Count: ${user.loginCount}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: user.isActive
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.isActive
                                          ? 'Active User'
                                          : 'Inactive User',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    group('Performance and Edge Cases', () {
      goldenTest(
        'Performance scenario with rapid updates should render final state',
        fileName: 'performance_rapid_updates',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Rapid Updates Performance',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Performance Test'),
                    backgroundColor: Colors.orange,
                  ),
                  body: ReactiveBuilder<int>(
                    notifier: counterState,
                    build: (value, notifier, keep) {
                      // Simulate rapid updates
                      if (value == 0) {
                        Future.microtask(() {
                          for (int i = 1; i <= 50; i++) {
                            counterState.updateState(i);
                          }
                        });
                      }

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Performance Test',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Final Value: $value',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: value / 50.0,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.orange),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Progress: ${(value / 50.0 * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            keep(const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'This widget survives rapid updates\nand never rebuilds',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            )),
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

// Test Models and ViewModels

class UserModel {
  final String name;
  final String email;
  final bool isActive;
  final int loginCount;

  UserModel({
    required this.name,
    required this.email,
    required this.isActive,
    required this.loginCount,
  });

  UserModel copyWith({
    String? name,
    String? email,
    bool? isActive,
    int? loginCount,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      loginCount: loginCount ?? this.loginCount,
    );
  }
}

class UserViewModel extends ViewModel<UserModel> {
  UserViewModel()
      : super(UserModel(
          name: 'John Doe',
          email: 'john.doe@example.com',
          isActive: false,
          loginCount: 0,
        ));

  @override
  void init() {
    // Initialize user data
  }

  void updateUserProfile({
    required String name,
    required String email,
    required bool isActive,
    required int loginCount,
  }) {
    updateState(UserModel(
      name: name,
      email: email,
      isActive: isActive,
      loginCount: loginCount,
    ));
  }

  void incrementLoginCount() {
    transformState((current) => current.copyWith(
          loginCount: current.loginCount + 1,
          isActive: true,
        ));
  }
}

class DataAsyncViewModel extends AsyncViewModelImpl<List<String>> {
  DataAsyncViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<List<String>> init() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Initial Item 1', 'Initial Item 2', 'Initial Item 3'];
  }

  void loadSuccessData(List<String> data) {
    updateState(data);
  }

  void simulateError(String message) {
    errorState(message);
  }
}
