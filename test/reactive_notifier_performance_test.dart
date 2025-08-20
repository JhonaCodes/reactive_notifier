import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier performance and memory management
///
/// This test suite covers performance-critical aspects of ReactiveNotifier:
/// - Large-scale instance creation and management
/// - Efficient cleanup operations for memory management
/// - Memory leak prevention with listener management
/// - Performance benchmarks for creation and cleanup operations
/// - Stress testing with high-volume operations
///
/// These tests ensure that ReactiveNotifier can handle demanding scenarios
/// without performance degradation or memory leaks, making it suitable
/// for production applications with complex state management needs.
void main() {
  group('ReactiveNotifier Performance and Memory', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Large-Scale Instance Creation Tests', () {
      test('should handle large number of instances efficiently', () {
        // Setup: Determine iterations based on environment (CI vs local)
        final iterations = Platform.environment['CI'] == 'true' ? 3000 : 10000;

        // Act: Measure time to create many instances
        final startTime = DateTime.now();
        for (int i = 0; i < iterations; i++) {
          ReactiveNotifier<int>(() => i);
        }
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should create all instances and complete in reasonable time
        expect(ReactiveNotifier.instanceCount, iterations,
            reason: 'All instances should be tracked correctly');
        expect(duration.inMilliseconds, lessThan(1000),
            reason: 'Instance creation should complete within 1 second');
      });

      test(
          'should handle creation of instances with different types efficiently',
          () {
        // Setup: Create various types in bulk
        const iterations = 1000;

        final startTime = DateTime.now();

        // Create instances of different types
        for (int i = 0; i < iterations; i++) {
          ReactiveNotifier<int>(() => i);
          ReactiveNotifier<String>(() => 'item_$i');
          ReactiveNotifier<bool>(() => i % 2 == 0);
          ReactiveNotifier<double>(() => i * 1.5);
        }

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should handle mixed types efficiently
        expect(ReactiveNotifier.instanceCount, iterations * 4,
            reason: 'All instances of different types should be tracked');
        expect(duration.inMilliseconds, lessThan(2000),
            reason: 'Mixed type creation should complete in reasonable time');

        // Verify type-specific counts
        expect(ReactiveNotifier.instanceCountByType<int>(), iterations,
            reason: 'Int instances should be tracked correctly');
        expect(ReactiveNotifier.instanceCountByType<String>(), iterations,
            reason: 'String instances should be tracked correctly');
        expect(ReactiveNotifier.instanceCountByType<bool>(), iterations,
            reason: 'Bool instances should be tracked correctly');
        expect(ReactiveNotifier.instanceCountByType<double>(), iterations,
            reason: 'Double instances should be tracked correctly');
      });

      test('should handle creation of complex object instances efficiently',
          () {
        // Setup: Create instances with complex objects
        const iterations = 1000;

        final startTime = DateTime.now();

        for (int i = 0; i < iterations; i++) {
          // Create instances with complex data structures
          ReactiveNotifier<List<int>>(
              () => List.generate(10, (index) => index + i));
          ReactiveNotifier<Map<String, dynamic>>(() => {
                'id': i,
                'name': 'item_$i',
                'active': i % 2 == 0,
                'metadata': {'created': DateTime.now().millisecondsSinceEpoch}
              });
        }

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should handle complex objects efficiently
        expect(ReactiveNotifier.instanceCount, iterations * 2,
            reason: 'Complex object instances should be tracked');
        expect(duration.inMilliseconds, lessThan(1500),
            reason:
                'Complex object creation should complete in reasonable time');
      });
    });

    group('Cleanup Performance Tests', () {
      test('should efficiently clean up large number of instances', () {
        // Setup: Create many instances (scale down on CI to avoid flakiness)
        final iterations = Platform.environment['CI'] == 'true' ? 3000 : 10000;
        for (int i = 0; i < iterations; i++) {
          ReactiveNotifier<int>(() => i);
        }

        expect(ReactiveNotifier.instanceCount, iterations,
            reason: 'All instances should be created before cleanup test');

        // Act: Measure cleanup time
        final startTime = DateTime.now();
        ReactiveNotifier.cleanup();
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should clean up efficiently
        expect(ReactiveNotifier.instanceCount, 0,
            reason: 'All instances should be cleaned up');
        // Keep performance expectation reasonable across machines
        expect(duration.inMilliseconds, lessThan(500),
            reason: 'Cleanup should complete quickly');
      });

      test('should efficiently clean up mixed type instances', () {
        // Setup: Create instances of various types
        const iterations = 2000;

        for (int i = 0; i < iterations; i++) {
          ReactiveNotifier<int>(() => i);
          ReactiveNotifier<String>(() => 'test_$i');
          ReactiveNotifier<List<double>>(
              () => [i.toDouble(), (i + 1).toDouble()]);
          ReactiveNotifier<Map<String, int>>(() => {'value': i});
        }

        expect(ReactiveNotifier.instanceCount, iterations * 4,
            reason: 'All mixed type instances should be created');

        // Act: Measure cleanup time for mixed types
        final startTime = DateTime.now();
        ReactiveNotifier.cleanup();
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should clean up mixed types efficiently
        expect(ReactiveNotifier.instanceCount, 0,
            reason: 'All mixed type instances should be cleaned up');
        // Allow more headroom to avoid flakes in CI or constrained envs
        expect(duration.inMilliseconds, lessThan(600),
            reason: 'Mixed type cleanup should complete quickly');

        // Verify all type counts are reset
        expect(ReactiveNotifier.instanceCountByType<int>(), 0);
        expect(ReactiveNotifier.instanceCountByType<String>(), 0);
        expect(ReactiveNotifier.instanceCountByType<List<double>>(), 0);
        expect(ReactiveNotifier.instanceCountByType<Map<String, int>>(), 0);
      });

      test('should handle repeated cleanup operations efficiently', () {
        // Test multiple create-cleanup cycles
        const cycles = 5;
        const instancesPerCycle = 1000;
        final durations = <int>[];

        for (int cycle = 0; cycle < cycles; cycle++) {
          // Create instances
          for (int i = 0; i < instancesPerCycle; i++) {
            ReactiveNotifier<int>(() => i + cycle * instancesPerCycle);
          }

          expect(ReactiveNotifier.instanceCount, instancesPerCycle,
              reason: 'Instances should be created for cycle $cycle');

          // Measure cleanup time
          final startTime = DateTime.now();
          ReactiveNotifier.cleanup();
          final endTime = DateTime.now();
          final duration = endTime.difference(startTime).inMilliseconds;

          durations.add(duration);

          expect(ReactiveNotifier.instanceCount, 0,
              reason: 'Cleanup should work for cycle $cycle');
        }

        // Assert: All cleanup operations should be consistently fast
        final maxDuration = durations.reduce((a, b) => a > b ? a : b);
        final avgDuration =
            durations.reduce((a, b) => a + b) / durations.length;

        expect(maxDuration, lessThan(400),
            reason: 'Maximum cleanup time should be reasonable');
        expect(avgDuration, lessThan(200),
            reason: 'Average cleanup time should be very fast');
      });
    });

    group('Memory Management and Leak Prevention Tests', () {
      test('should not leak memory when adding and removing listeners', () {
        // Setup: Create notifier and many listeners
        final notifier = ReactiveNotifier<int>(() => 0);
        const listenerCount = 1000;
        final listeners = List.generate(listenerCount, (_) => () {});

        // Act: Add all listeners
        final addStartTime = DateTime.now();
        for (final listener in listeners) {
          notifier.addListener(listener);
        }
        final addEndTime = DateTime.now();
        final addDuration = addEndTime.difference(addStartTime);

        // Act: Remove all listeners
        final removeStartTime = DateTime.now();
        for (final listener in listeners) {
          notifier.removeListener(listener);
        }
        final removeEndTime = DateTime.now();
        final removeDuration = removeEndTime.difference(removeStartTime);

        // Assert: Operations should complete efficiently
        expect(addDuration.inMilliseconds, lessThan(200),
            reason: 'Adding $listenerCount listeners should be fast');
        expect(removeDuration.inMilliseconds, lessThan(200),
            reason: 'Removing $listenerCount listeners should be fast');

        // Verify notifier still works after listener operations
        var listenerCalled = false;
        notifier.addListener(() => listenerCalled = true);
        notifier.updateState(42);
        expect(listenerCalled, isTrue,
            reason:
                'Notifier should still work after mass listener operations');
      });

      test('should handle rapid listener addition and removal cycles', () {
        // Setup: Test rapid listener lifecycle management
        final notifier = ReactiveNotifier<String>(() => 'initial');
        const cycles = 100;
        const listenersPerCycle = 50;

        final overallStartTime = DateTime.now();

        for (int cycle = 0; cycle < cycles; cycle++) {
          // Add listeners
          final listeners = List.generate(
              listenersPerCycle, (index) => () => 'listener_${cycle}_$index');

          for (final listener in listeners) {
            notifier.addListener(listener);
          }

          // Update state to trigger listeners
          notifier.updateState('cycle_$cycle');

          // Remove listeners
          for (final listener in listeners) {
            notifier.removeListener(listener);
          }
        }

        final overallEndTime = DateTime.now();
        final totalDuration = overallEndTime.difference(overallStartTime);

        // Assert: Should handle rapid cycles efficiently
        expect(totalDuration.inMilliseconds, lessThan(1000),
            reason: 'Rapid listener cycles should complete within 1 second');

        // Verify final state
        expect(notifier.notifier, 'cycle_${cycles - 1}',
            reason: 'Final state should be from last cycle');
      });

      test('should efficiently manage memory during state updates', () {
        // Setup: Test memory efficiency during rapid state updates
        final notifier = ReactiveNotifier<List<int>>(() => []);
        var callbackCount = 0;

        notifier.addListener(() {
          callbackCount++;
        });

        // Act: Perform many state updates with growing data
        final startTime = DateTime.now();
        for (int i = 0; i < 1000; i++) {
          final newList = List.generate(i + 1, (index) => index);
          notifier.updateState(newList);
        }
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should handle growing state efficiently
        expect(duration.inMilliseconds, lessThan(500),
            reason: 'Rapid state updates should be efficient');
        expect(callbackCount, 1000,
            reason: 'All updates should trigger callbacks');
        expect(notifier.notifier.length, 1000,
            reason: 'Final state should have correct size');
      });
    });

    group('Stress Testing and Scalability', () {
      test('should handle concurrent instance creation stress test', () {
        // Setup: Simulate concurrent instance creation
        const iterations = 5000;
        final instances = <ReactiveNotifier<int>>[];

        // Act: Create instances rapidly
        final startTime = DateTime.now();
        for (int i = 0; i < iterations; i++) {
          final instance = ReactiveNotifier<int>(() => i);
          instances.add(instance);

          // Perform some operations on each instance
          if (i % 100 == 0) {
            instance.updateState(i * 2);
          }
        }
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should handle stress efficiently
        expect(instances.length, iterations,
            reason: 'All instances should be created');
        expect(ReactiveNotifier.instanceCount, iterations,
            reason: 'All instances should be tracked');
        expect(duration.inMilliseconds, lessThan(1500),
            reason: 'Stress test should complete in reasonable time');

        // Verify some instances were updated correctly
        expect(instances[0].notifier, 0,
            reason: 'First instance should have correct value');
        expect(instances[100].notifier, 200,
            reason: 'Updated instance should have correct value');
      });

      test('should maintain performance with heavy listener activity', () {
        // Setup: Create notifier with many listeners performing different operations
        final notifier = ReactiveNotifier<int>(() => 0);
        const listenerCount = 500;
        var totalCallbacks = 0;
        final results = <String>[];

        // Add diverse listeners
        for (int i = 0; i < listenerCount; i++) {
          notifier.addListener(() {
            totalCallbacks++;
            final value = notifier.notifier;
            if (i % 5 == 0) {
              results.add('listener_$i: $value');
            }
          });
        }

        // Act: Perform updates and measure performance
        final startTime = DateTime.now();
        for (int update = 1; update <= 100; update++) {
          notifier.updateState(update);
        }
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should handle heavy listener activity efficiently
        expect(totalCallbacks, listenerCount * 100,
            reason: 'All listeners should be called for all updates');
        expect(duration.inMilliseconds, lessThan(1000),
            reason:
                'Heavy listener activity should complete in reasonable time');
        expect(results.length, 100 * (listenerCount / 5).ceil(),
            reason: 'Expected number of results should be generated');
      });

      test('should scale efficiently with increasing complexity', () {
        // Setup: Test scaling with increasing complexity
        final complexities = [100, 500, 1000, 2000];
        final durations = <int>[];

        for (final complexity in complexities) {
          ReactiveNotifier.cleanup(); // Start fresh for each complexity level

          final startTime = DateTime.now();

          // Create instances with increasing complexity
          for (int i = 0; i < complexity; i++) {
            final notifier = ReactiveNotifier<Map<String, dynamic>>(() => {
                  'id': i,
                  'data': List.generate(i % 10 + 1, (index) => index),
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                });

            // Add some listeners
            notifier.addListener(() {
              // Simulate some processing
              final data = notifier.notifier;
              data['processed'] = true;
            });

            // Update the state
            notifier.updateState({
              'id': i,
              'data': List.generate(i % 10 + 1, (index) => index * 2),
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'updated': true,
            });
          }

          final endTime = DateTime.now();
          final duration = endTime.difference(startTime).inMilliseconds;
          durations.add(duration);

          expect(ReactiveNotifier.instanceCount, complexity,
              reason:
                  'Complexity level $complexity should create correct number of instances');
        }

        // Assert: Performance should scale reasonably
        for (int i = 0; i < durations.length; i++) {
          final complexity = complexities[i];
          final duration = durations[i];

          // Performance should be roughly linear or better
          final expectedMaxDuration =
              (complexity / 100) * 200; // 200ms per 100 instances
          expect(duration, lessThan(expectedMaxDuration),
              reason:
                  'Complexity $complexity should complete within expected time ($expectedMaxDuration ms), actual: $duration ms');
        }
      });
    });
  });
}
