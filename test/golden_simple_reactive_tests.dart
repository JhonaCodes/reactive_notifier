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

/// Simple Golden Tests for ReactiveNotifier Visual Validation
///
/// This test suite provides basic visual regression testing for ReactiveNotifier
/// components to verify that state updates and rebuilds render correctly.
///
/// These tests serve as a foundation for more complex golden test scenarios
/// and help ensure that basic ReactiveNotifier functionality works as expected
/// from a visual perspective.

void main() {
  group('Simple ReactiveNotifier Golden Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    goldenTest(
      'ReactiveBuilder should display initial counter state',
      fileName: 'simple_counter_initial',
      constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
      builder: () => GoldenTestGroup(
        scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        children: [
          GoldenTestScenario(
            name: 'Initial State',
            child: MockScreenLayout(
              title: 'Counter Demo',
              backgroundColor: Colors.blue[50],
              body: ReactiveBuilder<int>(
                notifier: ReactiveNotifier<int>(() => 0),
                build: (value, notifier, keep) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Counter with ReactiveBuilder',
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
                              'Current Count',
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: keep(const Text(
                          'This text never rebuilds during state changes. It demonstrates the keep() function for widget preservation.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                          textAlign: TextAlign.center,
                        )),
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
      'ReactiveBuilder should display updated counter state',
      fileName: 'simple_counter_updated',
      constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
      builder: () => GoldenTestGroup(
        scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        children: [
          GoldenTestScenario(
            name: 'Updated State',
            child: MockScreenLayout(
              title: 'Updated Counter',
              backgroundColor: Colors.green[50],
              body: ReactiveBuilder<int>(
                notifier: ReactiveNotifier<int>(() => 42),
                build: (value, notifier, keep) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Counter Updated Demo',
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
                              'Updated Count',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$value',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Updated!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: keep(const Text(
                          'This preserved text demonstrates that the keep() function prevents unnecessary rebuilds during state updates.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                          textAlign: TextAlign.center,
                        )),
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
      'ReactiveBuilder should handle different data types',
      fileName: 'simple_different_types',
      constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
      builder: () => GoldenTestGroup(
        scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        children: [
          GoldenTestScenario(
            name: 'String State',
            child: MockScreenLayout(
              title: 'String Data Demo',
              backgroundColor: Colors.orange[50],
              body: ReactiveBuilder<String>(
                notifier:
                    ReactiveNotifier<String>(() => 'Hello ReactiveNotifier!'),
                build: (value, notifier, keep) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'String Data Type Support',
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
                              'String Message',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange[600],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Length: ${value.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            keep(const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            )),
                            const SizedBox(height: 8),
                            const Text(
                              'String type supported',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
      'ReactiveBuilder should handle boolean state with conditional rendering',
      fileName: 'simple_boolean_conditional',
      constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
      builder: () => GoldenTestGroup(
        scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        children: [
          GoldenTestScenario(
            name: 'Boolean True State',
            child: MockScreenLayout(
              title: 'Boolean State Demo',
              backgroundColor: Colors.purple[50],
              body: ReactiveBuilder<bool>(
                notifier: ReactiveNotifier<bool>(() => true),
                build: (value, notifier, keep) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Boolean Conditional Rendering',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: value ? Colors.green[100] : Colors.red[100],
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
                            Icon(
                              value ? Icons.check_circle : Icons.cancel,
                              color: value ? Colors.green : Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              value ? 'Enabled' : 'Disabled',
                              style: TextStyle(
                                fontSize: 24,
                                color: value ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    value ? Colors.green[600] : Colors.red[600],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                value ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: keep(const Text(
                          'This static content demonstrates conditional rendering with boolean states. The content above changes based on the boolean value.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                          textAlign: TextAlign.center,
                        )),
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
      'ReactiveBuilder should handle null state safely',
      fileName: 'simple_null_safe',
      constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
      builder: () => GoldenTestGroup(
        scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        children: [
          GoldenTestScenario(
            name: 'Null State',
            child: MockScreenLayout(
              title: 'Null Safety Demo',
              backgroundColor: Colors.amber[50],
              body: ReactiveBuilder<String?>(
                notifier: ReactiveNotifier<String?>(() => null),
                build: (value, notifier, keep) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Null Safety Handling',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: value == null
                              ? Colors.orange[100]
                              : Colors.green[100],
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
                            Icon(
                              value == null
                                  ? Icons.warning
                                  : Icons.check_circle,
                              color:
                                  value == null ? Colors.orange : Colors.green,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: value == null
                                        ? Colors.orange[200]!
                                        : Colors.green[200]!),
                              ),
                              child: Text(
                                value ?? 'No value',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: value == null
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: value == null
                                    ? Colors.orange[600]
                                    : Colors.green[600],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                value == null
                                    ? 'Null value detected'
                                    : 'Value present',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            keep(const Icon(
                              Icons.security,
                              color: Colors.blue,
                              size: 32,
                            )),
                            const SizedBox(height: 12),
                            const Text(
                              'Null-safe rendering demonstrates Flutter\'s null safety features working seamlessly with ReactiveNotifier.',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
}
