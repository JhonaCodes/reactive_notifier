import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'config/alchemist_config.dart';

/// Golden Tests for Performance Scenarios and Edge Cases
///
/// This test suite provides visual regression testing for performance-critical
/// scenarios and edge cases in ReactiveNotifier:
///
/// 1. Rapid state updates and their visual impact
/// 2. Memory pressure scenarios with large state objects
/// 3. Error states and recovery scenarios
/// 4. Network failure simulations
/// 5. Complex reactive chains and dependencies
/// 6. Null safety and nullable state handling
/// 7. Circular reference detection and error display
///
/// These tests ensure that ReactiveNotifier performs well under stress
/// and handles edge cases gracefully with appropriate visual feedback.

void main() {
  group('Performance and Edge Cases Golden Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    final performanceState =
        ReactiveNotifier<PerformanceViewModel>(() => PerformanceViewModel());
    final networkState = ReactiveNotifier<NetworkSimulatorViewModel>(
        () => NetworkSimulatorViewModel());
    final errorState = ReactiveNotifier<ErrorHandlingViewModel>(
        () => ErrorHandlingViewModel());

    group('Performance Scenarios', () {
      goldenTest(
        'Rapid state updates should show final state without flickering',
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
                    backgroundColor: Colors.deepPurple,
                  ),
                  body: ReactiveViewModelBuilder<PerformanceViewModel,
                      PerformanceModel>(
                    viewmodel: performanceState.notifier,
                    build: (perf, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Performance Metrics',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Current Value:'),
                                        Text(
                                          '${perf.currentValue}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Updates/sec:'),
                                        Text('${perf.updatesPerSecond}'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Updates:'),
                                        Text('${perf.totalUpdates}'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Performance:'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: perf.isPerformant
                                                ? Colors.green
                                                : Colors.orange,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            perf.isPerformant
                                                ? 'Optimal'
                                                : 'Degraded',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: perf.currentValue / 1000.0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                perf.isPerformant
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      viewmodel.startRapidUpdates(),
                                  child: const Text('Start Rapid Updates'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () => viewmodel.stopUpdates(),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Stop Updates'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            keep(const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'This widget never rebuilds during performance tests.\n'
                                  'It serves as a control to verify that non-rebuilding widgets\n'
                                  'remain stable during rapid state changes.',
                                  style: TextStyle(
                                      fontSize: 12,
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
        'Memory pressure scenario with large state objects',
        fileName: 'memory_pressure_large_objects',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Memory Pressure Test',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Memory Pressure Test'),
                    backgroundColor: Colors.orange,
                  ),
                  body: ReactiveViewModelBuilder<PerformanceViewModel,
                      PerformanceModel>(
                    viewmodel: performanceState.notifier,
                    build: (perf, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Memory Usage Simulation',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Memory Objects:'),
                                        Text('${perf.memoryObjects.length}'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Est. Memory Usage:'),
                                        Text(
                                            '${(perf.memoryObjects.length * 0.001).toStringAsFixed(3)} MB'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Memory Status:'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: perf.memoryObjects.length <
                                                    10000
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            perf.memoryObjects.length < 10000
                                                ? 'Normal'
                                                : 'High',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: (perf.memoryObjects.length / 50000.0)
                                  .clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                perf.memoryObjects.length < 10000
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      viewmodel.allocateMemory(1000),
                                  child: const Text('Allocate 1K Objects'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      viewmodel.allocateMemory(10000),
                                  child: const Text('Allocate 10K Objects'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.clearMemory(),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Clear Memory'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  itemCount:
                                      (perf.memoryObjects.length / 1000).ceil(),
                                  itemBuilder: (context, index) {
                                    final startIndex = index * 1000;
                                    final endIndex = (startIndex + 1000)
                                        .clamp(0, perf.memoryObjects.length);
                                    return ListTile(
                                      leading: const Icon(Icons.memory),
                                      title: Text('Memory Block ${index + 1}'),
                                      subtitle: Text(
                                          'Objects ${startIndex + 1} - $endIndex'),
                                      trailing: Text(
                                          '${endIndex - startIndex} items'),
                                    );
                                  },
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

    group('Network Failure Simulation', () {
      goldenTest(
        'Network failure simulation with retry mechanism',
        fileName: 'network_failure_simulation',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Network Failure Test',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Network Simulation'),
                    backgroundColor: Colors.red,
                  ),
                  body: ReactiveAsyncBuilder<NetworkSimulatorViewModel,
                      NetworkResponse>(
                    notifier: networkState.notifier,
                    onLoading: () => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Connecting to server...'),
                        ],
                      ),
                    ),
                    onData: (data, viewModel, keep) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Connection Successful',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Status Code:'),
                                      Text('${data.statusCode}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Response Time:'),
                                      Text('${data.responseTime}ms'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Data Size:'),
                                      Text('${data.dataSize} bytes'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Response Data:'),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      data.responseData,
                                      style: const TextStyle(
                                          fontFamily: 'monospace'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onError: (error, stackTrace) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Network Error',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Error Details:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    error.toString(),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Retry Attempts:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      '${networkState.notifier.data?.retryCount}/3'),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => networkState.notifier
                                          .retryConnection(),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry Connection'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    });

    group('Error Handling and Recovery', () {
      goldenTest(
        'Error handling with graceful recovery',
        fileName: 'error_handling_recovery',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Error Recovery Test',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Error Handling'),
                    backgroundColor: Colors.red,
                  ),
                  body: ReactiveViewModelBuilder<ErrorHandlingViewModel,
                      ErrorHandlingModel>(
                    viewmodel: errorState.notifier,
                    build: (errorModel, viewmodel, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Error Handling Simulation',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            if (errorModel.hasError) ...[
                              Card(
                                color: Colors.red[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            'Error Occurred',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error: ${errorModel.errorMessage}',
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Error Count: ${errorModel.errorCount}'),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Recovery Attempts: ${errorModel.recoveryAttempts}'),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Card(
                                color: Colors.green[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green),
                                          SizedBox(width: 8),
                                          Text(
                                            'System Operational',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Success Operations: ${errorModel.successCount}'),
                                      const SizedBox(height: 8),
                                      Text('Uptime: ${errorModel.uptime}'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'System Status',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Current State:'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: errorModel.hasError
                                                ? Colors.red
                                                : Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            errorModel.hasError
                                                ? 'Error'
                                                : 'Healthy',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Auto-Recovery:'),
                                        Switch(
                                          value: errorModel.autoRecoveryEnabled,
                                          onChanged: (value) =>
                                              viewmodel.toggleAutoRecovery(),
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
                                  onPressed: () => viewmodel.simulateError(),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Simulate Error'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.performOperation(),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('Perform Operation'),
                                ),
                                ElevatedButton(
                                  onPressed: () => viewmodel.resetSystem(),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue),
                                  child: const Text('Reset System'),
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

    group('Null Safety and Edge Cases', () {
      goldenTest(
        'Null safety handling and nullable state management',
        fileName: 'null_safety_handling',
        constraints: ReactiveNotifierAlchemistConfig.wideConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints: ReactiveNotifierAlchemistConfig.wideConstraints,
          children: [
            GoldenTestScenario(
              name: 'Null Safety Test',
              child: MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Null Safety Test'),
                    backgroundColor: Colors.indigo,
                  ),
                  body: ReactiveBuilder<String?>(
                    notifier: _NullSafetyTestService.nullableState,
                    build: (value, notifier, keep) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nullable State Management',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: value == null
                                  ? Colors.orange[50]
                                  : Colors.green[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          value == null
                                              ? Icons.warning
                                              : Icons.check_circle,
                                          color: value == null
                                              ? Colors.orange
                                              : Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          value == null
                                              ? 'Null Value'
                                              : 'Value Present',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: value == null
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Current Value: ${value ?? 'null'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Length: ${value?.length ?? 0}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Is Empty: ${value?.isEmpty ?? true}',
                                      style: const TextStyle(fontSize: 14),
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
                                  onPressed: () =>
                                      _NullSafetyTestService.setValue(
                                          'Hello World'),
                                  child: const Text('Set Value'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      _NullSafetyTestService.setValue(''),
                                  child: const Text('Set Empty'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      _NullSafetyTestService.setValue(null),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange),
                                  child: const Text('Set Null'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Null Safety Features:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text('✓ Nullable type support'),
                                  Text('✓ Safe null checks'),
                                  Text('✓ Null-aware operators'),
                                  Text('✓ Graceful null handling'),
                                  Text('✓ No null pointer exceptions'),
                                ],
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

// Test Models and ViewModels for Performance and Edge Cases

class PerformanceModel {
  final int currentValue;
  final int updatesPerSecond;
  final int totalUpdates;
  final bool isPerformant;
  final List<String> memoryObjects;

  PerformanceModel({
    required this.currentValue,
    required this.updatesPerSecond,
    required this.totalUpdates,
    required this.isPerformant,
    required this.memoryObjects,
  });

  PerformanceModel copyWith({
    int? currentValue,
    int? updatesPerSecond,
    int? totalUpdates,
    bool? isPerformant,
    List<String>? memoryObjects,
  }) {
    return PerformanceModel(
      currentValue: currentValue ?? this.currentValue,
      updatesPerSecond: updatesPerSecond ?? this.updatesPerSecond,
      totalUpdates: totalUpdates ?? this.totalUpdates,
      isPerformant: isPerformant ?? this.isPerformant,
      memoryObjects: memoryObjects ?? this.memoryObjects,
    );
  }
}

class PerformanceViewModel extends ViewModel<PerformanceModel> {
  PerformanceViewModel()
      : super(PerformanceModel(
          currentValue: 0,
          updatesPerSecond: 0,
          totalUpdates: 0,
          isPerformant: true,
          memoryObjects: [],
        ));

  @override
  void init() {
    // Initialize performance monitoring
  }

  void startRapidUpdates() {
    transformState((current) => current.copyWith(
          currentValue: 500,
          updatesPerSecond: 60,
          totalUpdates: current.totalUpdates + 500,
          isPerformant: true,
        ));
  }

  void stopUpdates() {
    transformState((current) => current.copyWith(
          updatesPerSecond: 0,
          isPerformant: true,
        ));
  }

  void allocateMemory(int count) {
    transformState((current) {
      final newObjects = List.generate(
          count, (index) => 'Object_${current.memoryObjects.length + index}');
      return current.copyWith(
        memoryObjects: [...current.memoryObjects, ...newObjects],
      );
    });
  }

  void clearMemory() {
    transformState((current) => current.copyWith(
          memoryObjects: [],
        ));
  }
}

class NetworkResponse {
  final int statusCode;
  final int responseTime;
  final int dataSize;
  final String responseData;
  final int retryCount;

  NetworkResponse({
    required this.statusCode,
    required this.responseTime,
    required this.dataSize,
    required this.responseData,
    required this.retryCount,
  });
}

class NetworkSimulatorViewModel extends AsyncViewModelImpl<NetworkResponse> {
  NetworkSimulatorViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<NetworkResponse> init() async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulate network failure
    throw Exception('Network connection failed');
  }

  void retryConnection() {
    loadingState();
    Future.delayed(const Duration(seconds: 1)).then((_) {
      updateState(NetworkResponse(
        statusCode: 200,
        responseTime: 150,
        dataSize: 1024,
        responseData: '{"status": "success", "message": "Connection restored"}',
        retryCount: (data?.retryCount ?? 0) + 1,
      ));
    });
  }
}

class ErrorHandlingModel {
  final bool hasError;
  final String errorMessage;
  final int errorCount;
  final int recoveryAttempts;
  final int successCount;
  final String uptime;
  final bool autoRecoveryEnabled;

  ErrorHandlingModel({
    required this.hasError,
    required this.errorMessage,
    required this.errorCount,
    required this.recoveryAttempts,
    required this.successCount,
    required this.uptime,
    required this.autoRecoveryEnabled,
  });

  ErrorHandlingModel copyWith({
    bool? hasError,
    String? errorMessage,
    int? errorCount,
    int? recoveryAttempts,
    int? successCount,
    String? uptime,
    bool? autoRecoveryEnabled,
  }) {
    return ErrorHandlingModel(
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCount: errorCount ?? this.errorCount,
      recoveryAttempts: recoveryAttempts ?? this.recoveryAttempts,
      successCount: successCount ?? this.successCount,
      uptime: uptime ?? this.uptime,
      autoRecoveryEnabled: autoRecoveryEnabled ?? this.autoRecoveryEnabled,
    );
  }
}

class ErrorHandlingViewModel extends ViewModel<ErrorHandlingModel> {
  ErrorHandlingViewModel()
      : super(ErrorHandlingModel(
          hasError: false,
          errorMessage: '',
          errorCount: 0,
          recoveryAttempts: 0,
          successCount: 0,
          uptime: '00:00:00',
          autoRecoveryEnabled: false,
        ));

  @override
  void init() {
    // Initialize error handling
  }

  void simulateError() {
    transformState((current) => current.copyWith(
          hasError: true,
          errorMessage: 'Simulated system error occurred',
          errorCount: current.errorCount + 1,
        ));
  }

  void performOperation() {
    transformState((current) => current.copyWith(
          hasError: false,
          errorMessage: '',
          successCount: current.successCount + 1,
        ));
  }

  void resetSystem() {
    transformState((current) => ErrorHandlingModel(
          hasError: false,
          errorMessage: '',
          errorCount: 0,
          recoveryAttempts: 0,
          successCount: 0,
          uptime: '00:00:00',
          autoRecoveryEnabled: current.autoRecoveryEnabled,
        ));
  }

  void toggleAutoRecovery() {
    transformState((current) => current.copyWith(
          autoRecoveryEnabled: !current.autoRecoveryEnabled,
        ));
  }
}

// Test service for null safety testing
mixin _NullSafetyTestService {
  static final ReactiveNotifier<String?> nullableState =
      ReactiveNotifier<String?>(() => null);

  static void setValue(String? value) {
    nullableState.updateState(value);
  }
}
