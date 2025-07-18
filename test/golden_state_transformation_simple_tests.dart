import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'config/alchemist_config.dart';

/// Mock widget que simula una pantalla amplia para golden tests
class MockScreenLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final Color? backgroundColor;

  const MockScreenLayout({
    super.key,
    required this.title,
    required this.body,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: backgroundColor ?? Colors.grey[50],
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: body,
        ),
      ),
    );
  }
}

/// Simple Golden Tests for State Transformation and Update Methods
///
/// This test suite provides visual regression testing for different state
/// update methods and their effects on UI rendering:
///
/// 1. updateState() vs updateSilently() visual differences
/// 2. transformState() vs transformStateSilently() behaviors
/// 3. Simple state transformations with immediate values
///
/// These tests ensure that state transformation methods work correctly
/// and that the UI responds appropriately to different update patterns.

void main() {
  group('State Transformation Simple Golden Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    // Use service mixins instead of direct instances

    group('updateState vs updateSilently Visual Comparison', () {
      goldenTest(
        'updateState should show immediate UI updates',
        fileName: 'simple_update_state_immediate',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:
              ReactiveNotifierAlchemistConfig.mobileConstraints,
          children: [
            GoldenTestScenario(
              name: 'Immediate Update',
              child: MockScreenLayout(
                title: 'updateState() Demo',
                backgroundColor: Colors.blue[50],
                body: ReactiveBuilder<int>(
                  notifier: _CounterTestService.counterState,
                  build: (value, notifier, keep) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Counter with updateState()',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Current Value',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$value',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () =>
                              _CounterTestService.incrementCounter(value),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Increment (updateState)',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: const Text(
                            'This button uses updateState() which immediately triggers UI rebuilds and notifies all listeners.',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'updateSilently should show internal state differences',
        fileName: 'simple_update_silently_internal',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:
              ReactiveNotifierAlchemistConfig.mobileConstraints,
          children: [
            GoldenTestScenario(
              name: 'Silent Update',
              child: MockScreenLayout(
                title: 'updateSilently() Demo',
                backgroundColor: Colors.orange[50],
                body: ReactiveBuilder<int>(
                  notifier: _CounterTestService.counterState,
                  build: (value, notifier, keep) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Counter with updateSilently()',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Displayed Value',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$value',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Internal Value',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${notifier.notifier}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _CounterTestService
                                    .counterState
                                    .updateSilently(_CounterTestService
                                            .counterState.notifier +
                                        1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Silent +1',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _CounterTestService
                                    .counterState
                                    .updateState(_CounterTestService
                                        .counterState.notifier),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Force Update',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: const Text(
                            'updateSilently() modifies internal state without triggering UI updates. Use "Force Update" to refresh the display.',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });

    group('transformState vs transformStateSilently Visual Comparison', () {
      goldenTest(
        'transformState should apply transformations and notify',
        fileName: 'simple_transform_state_notify',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:
              ReactiveNotifierAlchemistConfig.mobileConstraints,
          children: [
            GoldenTestScenario(
              name: 'Transform with Notify',
              child: MockScreenLayout(
                title: 'transformState() Demo',
                backgroundColor: Colors.green[50],
                body: ReactiveBuilder<String>(
                  notifier: _StringTestService.stringState,
                  build: (value, notifier, keep) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'String with transformState()',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Current Text',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Text(
                                  '"$value"',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Length:',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black54),
                                    ),
                                    Text(
                                      '${value.length}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _StringTestService.stringState
                                    .transformState((current) => '$current!'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Add !',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _StringTestService.transformToUpper(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'UPPER',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _StringTestService.resetString(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: const Text(
                            'transformState() applies transformations to the current state and immediately notifies all listeners.',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'transformStateSilently should modify without UI updates',
        fileName: 'simple_transform_silently_background',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:
              ReactiveNotifierAlchemistConfig.mobileConstraints,
          children: [
            GoldenTestScenario(
              name: 'Silent Transform',
              child: MockScreenLayout(
                title: 'transformStateSilently() Demo',
                backgroundColor: Colors.purple[50],
                body: ReactiveBuilder<String>(
                  notifier: _StringTestService.stringState,
                  build: (value, notifier, keep) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'String with transformStateSilently()',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Displayed Text',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.purple[200]!),
                                ),
                                child: Text(
                                  '"$value"',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Internal Text',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '"${notifier.notifier}"',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _StringTestService.transformSilently(
                                        (current) => '$current*'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Silent *',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _StringTestService.transformSilently(
                                        (current) => current.toUpperCase()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Silent UP',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _StringTestService.showChanges(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Show Changes',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: const Text(
                            'transformStateSilently() modifies internal state without triggering UI updates. Use "Show Changes" to display modifications.',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  });
}

// Test services for state transformation testing
mixin _CounterTestService {
  static final ReactiveNotifier<int> counterState =
      ReactiveNotifier<int>(() => 0);

  static void incrementCounter(int currentValue) {
    counterState.updateState(currentValue + 1);
  }
}

mixin _StringTestService {
  static final ReactiveNotifier<String> stringState =
      ReactiveNotifier<String>(() => 'Initial');

  static void transformToUpper() {
    stringState.transformState((current) => current.toUpperCase());
  }

  static void transformSilently(String Function(String) transform) {
    stringState.transformStateSilently(transform);
  }

  static void resetString() {
    stringState.updateState('Initial');
  }

  static void showChanges() {
    stringState.updateState(stringState.notifier);
  }
}
