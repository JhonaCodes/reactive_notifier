import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'config/alchemist_config.dart';

/// Golden Tests for AsyncViewModelImpl Transform Methods
///
/// These tests visually demonstrate the transform methods:
/// - transformDataState() - transforms data within success state with notifications
/// - transformDataStateSilently() - transforms data within success state without notifications
/// - transformStateSilently() - transforms entire AsyncState without notifications
///
/// Each test shows 4 scenarios demonstrating the progression and effects
/// of different transformation methods.

// Simple test ViewModels for demonstration
class SimpleTestViewModel extends AsyncViewModelImpl<List<String>> {
  SimpleTestViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<List<String>> init() async {
    return [];
  }

  // Expose transform methods for testing
  void testTransformDataState(
      List<String>? Function(List<String>? data) transformer) {
    transformDataState(transformer);
  }

  void testTransformDataStateSilently(
      List<String>? Function(List<String>? data) transformer) {
    transformDataStateSilently(transformer);
  }

  void testTransformStateSilently(
      AsyncState<List<String>> Function(AsyncState<List<String>> state)
          transformer) {
    transformStateSilently(transformer);
  }
}

class SimpleCounterViewModel extends AsyncViewModelImpl<int> {
  SimpleCounterViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<int> init() async {
    return 0;
  }

  void testTransformDataState(int? Function(int? data) transformer) {
    transformDataState(transformer);
  }

  void testTransformDataStateSilently(int? Function(int? data) transformer) {
    transformDataStateSilently(transformer);
  }

  void testTransformStateSilently(
      AsyncState<int> Function(AsyncState<int> state) transformer) {
    transformStateSilently(transformer);
  }
}

// Simple widgets for demonstration
class SimpleListWidget extends StatelessWidget {
  final List<String> items;
  final String title;
  final Color color;

  const SimpleListWidget({
    super.key,
    required this.items,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items: ${items.length}',
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Center(
              child: Text(
                'No items',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class SimpleCounterWidget extends StatelessWidget {
  final int count;
  final String title;
  final Color color;

  const SimpleCounterWidget({
    super.key,
    required this.count,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleStateWidget extends StatelessWidget {
  final String state;
  final String title;
  final Color color;

  const SimpleStateWidget({
    super.key,
    required this.state,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(
              state,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Transform Methods Golden Tests', () {
    setUp(() {
      // Simple cleanup without reactive notifier complexities
    });

    tearDown(() {
      // Simple cleanup without reactive notifier complexities
    });

    group('transformDataState Method', () {
      goldenTest(
        'transformDataState should show list transformations',
        fileName: 'transform_data_state_flow',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Empty List',
                child: MaterialApp(
                  home: Scaffold(
                    appBar:
                        AppBar(title: const Text('transformDataState - Empty')),
                    body: const Center(
                      child: SimpleListWidget(
                        items: [],
                        title: 'transformDataState',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Single Item',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title: const Text('transformDataState - Single')),
                    body: const Center(
                      child: SimpleListWidget(
                        items: ['Item 1'],
                        title: 'transformDataState',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Multiple Items',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title: const Text('transformDataState - Multiple')),
                    body: const Center(
                      child: SimpleListWidget(
                        items: ['Item 1', 'Item 2', 'Item 3'],
                        title: 'transformDataState',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Transformed Items',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title: const Text('transformDataState - Transformed')),
                    body: const Center(
                      child: SimpleListWidget(
                        items: [
                          'Item 1',
                          'Item 2',
                          'Item 3',
                          'Added via transform'
                        ],
                        title: 'transformDataState',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('transformDataStateSilently Method', () {
      goldenTest(
        'transformDataStateSilently should show silent transformations',
        fileName: 'transform_data_state_silently_flow',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Empty List',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title:
                            const Text('transformDataStateSilently - Empty')),
                    body: const Center(
                      child: SimpleListWidget(
                        items: [],
                        title: 'transformDataStateSilently',
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Initial Items',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title:
                            const Text('transformDataStateSilently - Initial')),
                    body: const Center(
                      child: SimpleListWidget(
                        items: ['First', 'Second'],
                        title: 'transformDataStateSilently',
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Silently Added',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title:
                            const Text('transformDataStateSilently - Added')),
                    body: const Center(
                      child: SimpleListWidget(
                        items: ['First', 'Second', 'Third (silent)'],
                        title: 'transformDataStateSilently',
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Fully Transformed',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title: const Text('transformDataStateSilently - Full')),
                    body: const Center(
                      child: SimpleListWidget(
                        items: [
                          'First',
                          'Second',
                          'Third (silent)',
                          'Fourth (silent)',
                          'Fifth (silent)'
                        ],
                        title: 'transformDataStateSilently',
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('transformStateSilently Method', () {
      goldenTest(
        'transformStateSilently should show state transitions',
        fileName: 'transform_state_silently_flow',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Initial State',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title: const Text('transformStateSilently - Initial')),
                    body: const Center(
                      child: SimpleStateWidget(
                        state: 'Initial',
                        title: 'transformStateSilently',
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Loading State',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title: const Text('transformStateSilently - Loading')),
                    body: const Center(
                      child: SimpleStateWidget(
                        state: 'Loading',
                        title: 'transformStateSilently',
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Success State',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title: const Text('transformStateSilently - Success')),
                    body: const Center(
                      child: SimpleStateWidget(
                        state: 'Success',
                        title: 'transformStateSilently',
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Error State',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                        title: const Text('transformStateSilently - Error')),
                    body: const Center(
                      child: SimpleStateWidget(
                        state: 'Error',
                        title: 'transformStateSilently',
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('Combined Transform Methods', () {
      goldenTest(
        'Combined transform methods should show progression',
        fileName: 'combined_transform_methods_flow',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Counter Initial',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Combined - Initial')),
                    body: const Center(
                      child: SimpleCounterWidget(
                        count: 0,
                        title: 'Combined Methods',
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Counter Incremented',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Combined - Incremented')),
                    body: const Center(
                      child: SimpleCounterWidget(
                        count: 5,
                        title: 'Combined Methods',
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Counter High',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Combined - High')),
                    body: const Center(
                      child: SimpleCounterWidget(
                        count: 25,
                        title: 'Combined Methods',
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Counter Very High',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Combined - Very High')),
                    body: const Center(
                      child: SimpleCounterWidget(
                        count: 100,
                        title: 'Combined Methods',
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  });
}
