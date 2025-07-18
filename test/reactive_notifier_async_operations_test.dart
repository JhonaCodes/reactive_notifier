import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier asynchronous operations
/// 
/// This test suite covers asynchronous operation capabilities of ReactiveNotifier:
/// - Async state updates and timing management
/// - Concurrent async operations and coordination
/// - Multi-threading support with isolates
/// - Async operation sequencing and dependencies
/// - Performance optimization for frequent async updates
/// 
/// These tests verify that ReactiveNotifier can handle asynchronous patterns
/// required for real-world applications including API calls, background processing,
/// and multi-threaded operations while maintaining state consistency.
void main() {
  group('ReactiveNotifier Async Operations', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Basic Async State Updates', () {
      test('should handle async state updates correctly', () async {
        // Setup: Create ReactiveNotifier with async state update function
        final asyncState = ReactiveNotifier<String>(() => 'initial');
        String? finalValue;
        var listenerCallCount = 0;

        asyncState.addListener(() {
          listenerCallCount++;
          finalValue = asyncState.notifier;
        });

        // Helper function for async state update
        Future<void> updateStateAsync() async {
          await Future.delayed(const Duration(milliseconds: 100));
          asyncState.updateState('updated');
        }

        // Act: Start async operation and verify initial state
        final updateFuture = updateStateAsync();
        expect(asyncState.notifier, 'initial',
            reason: 'State should remain initial while async operation is pending');
        expect(listenerCallCount, 0,
            reason: 'Listener should not be called before async operation completes');

        // Act: Wait for async operation to complete
        await updateFuture;

        // Assert: State should be updated after async operation
        expect(asyncState.notifier, 'updated',
            reason: 'State should be updated after async operation completes');
        expect(listenerCallCount, 1,
            reason: 'Listener should be called once after async update');
        expect(finalValue, 'updated',
            reason: 'Listener should receive updated value');
      });

      test('should handle multiple sequential async updates', () async {
        // Setup: Create ReactiveNotifier for sequential async updates
        final sequentialState = ReactiveNotifier<int>(() => 0);
        final updateHistory = <int>[];

        sequentialState.addListener(() {
          updateHistory.add(sequentialState.notifier);
        });

        // Helper function for async increment
        Future<void> incrementAsync(int increment, int delay) async {
          await Future.delayed(Duration(milliseconds: delay));
          sequentialState.updateState(sequentialState.notifier + increment);
        }

        // Act: Perform sequential async updates
        await incrementAsync(1, 50);   // 0 + 1 = 1
        await incrementAsync(2, 30);   // 1 + 2 = 3
        await incrementAsync(3, 20);   // 3 + 3 = 6

        // Assert: All updates should be applied in sequence
        expect(sequentialState.notifier, 6,
            reason: 'Final state should reflect all sequential updates');
        expect(updateHistory, [1, 3, 6],
            reason: 'Update history should show correct sequence');
      });

      test('should handle async updates with different data types', () async {
        // Setup: Create multiple ReactiveNotifiers with different types
        final stringState = ReactiveNotifier<String>(() => 'start');
        final listState = ReactiveNotifier<List<int>>(() => []);
        final mapState = ReactiveNotifier<Map<String, bool>>(() => {});

        final allUpdatesCompleted = <String>[];

        // Setup async update functions
        Future<void> updateStringAsync() async {
          await Future.delayed(const Duration(milliseconds: 50));
          stringState.updateState('async_string');
          allUpdatesCompleted.add('string');
        }

        Future<void> updateListAsync() async {
          await Future.delayed(const Duration(milliseconds: 75));
          listState.updateState([1, 2, 3, 4, 5]);
          allUpdatesCompleted.add('list');
        }

        Future<void> updateMapAsync() async {
          await Future.delayed(const Duration(milliseconds: 25));
          mapState.updateState({'async': true, 'completed': true});
          allUpdatesCompleted.add('map');
        }

        // Act: Execute all async updates simultaneously
        await Future.wait([
          updateStringAsync(),
          updateListAsync(),
          updateMapAsync(),
        ]);

        // Assert: All async updates should complete successfully
        expect(stringState.notifier, 'async_string',
            reason: 'String state should be updated asynchronously');
        expect(listState.notifier, [1, 2, 3, 4, 5],
            reason: 'List state should be updated asynchronously');
        expect(mapState.notifier, {'async': true, 'completed': true},
            reason: 'Map state should be updated asynchronously');
        expect(allUpdatesCompleted.length, 3,
            reason: 'All async updates should complete');
        expect(allUpdatesCompleted, contains('string'),
            reason: 'String update should complete');
        expect(allUpdatesCompleted, contains('list'),
            reason: 'List update should complete');
        expect(allUpdatesCompleted, contains('map'),
            reason: 'Map update should complete');
      });
    });

    group('Concurrent Async Operations', () {
      test('should manage concurrent async updates correctly', () async {
        // Setup: Create ReactiveNotifier for concurrent operations
        final concurrentState = ReactiveNotifier<int>(() => 0);
        var totalListenerCalls = 0;

        concurrentState.addListener(() {
          totalListenerCalls++;
        });

        // Helper function for async increment
        Future<void> incrementAsync() async {
          await Future.delayed(const Duration(milliseconds: 50));
          concurrentState.updateState(concurrentState.notifier + 1);
        }

        // Act: Start multiple concurrent async operations
        await Future.wait([
          incrementAsync(),
          incrementAsync(),
          incrementAsync()
        ]);

        // Assert: All concurrent operations should complete
        expect(concurrentState.notifier, 3,
            reason: 'All concurrent increments should be applied');
        expect(totalListenerCalls, 3,
            reason: 'Listener should be called for each concurrent update');
      });

      test('should handle race conditions in concurrent updates safely', () async {
        // Setup: Create ReactiveNotifier for race condition testing
        final raceState = ReactiveNotifier<List<String>>(() => []);
        final finalResults = <String>[];

        raceState.addListener(() {
          // Capture the final state after each update
          finalResults.addAll(raceState.notifier);
        });

        // Helper function for concurrent list updates
        Future<void> addItemAsync(String item, int delay) async {
          await Future.delayed(Duration(milliseconds: delay));
          final currentList = List<String>.from(raceState.notifier);
          currentList.add(item);
          raceState.updateState(currentList);
        }

        // Act: Perform concurrent updates with different delays
        await Future.wait([
          addItemAsync('fast', 10),     // Should complete first
          addItemAsync('medium', 50),   // Should complete second
          addItemAsync('slow', 100),    // Should complete last
        ]);

        // Assert: All updates should be applied despite race conditions
        expect(raceState.notifier.length, 3,
            reason: 'All concurrent updates should be applied');
        expect(raceState.notifier, containsAll(['fast', 'medium', 'slow']),
            reason: 'All items should be added to the list');
      });

      test('should coordinate multiple dependent async operations', () async {
        // Setup: Create dependent ReactiveNotifiers
        final sourceState = ReactiveNotifier<int>(() => 1);
        final derivedState = ReactiveNotifier<int>(() => 1);
        final finalState = ReactiveNotifier<String>(() => 'initial');

        final operationOrder = <String>[];

        // Setup dependencies with async processing
        sourceState.addListener(() async {
          operationOrder.add('source_updated');
          await Future.delayed(const Duration(milliseconds: 30));
          derivedState.updateState(sourceState.notifier * 2);
        });

        derivedState.addListener(() async {
          operationOrder.add('derived_updated');
          await Future.delayed(const Duration(milliseconds: 20));
          finalState.updateState('result_${derivedState.notifier}');
        });

        // Act: Trigger the async dependency chain
        sourceState.updateState(5);

        // Wait for all async operations to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert: Dependent async operations should complete in order
        expect(sourceState.notifier, 5,
            reason: 'Source state should be updated');
        expect(derivedState.notifier, 10,
            reason: 'Derived state should be updated based on source');
        expect(finalState.notifier, 'result_10',
            reason: 'Final state should reflect the complete chain');
        expect(operationOrder, ['source_updated', 'derived_updated'],
            reason: 'Operations should complete in dependency order');
      });
    });

    group('Multi-threading and Isolate Support', () {
      test('should handle updates from different isolates', () async {
        // Setup: Create ReactiveNotifier for isolate communication
        final isolateState = ReactiveNotifier<int>(() => 0);
        var listenerCallCount = 0;

        isolateState.addListener(() {
          listenerCallCount++;
        });

        // Create a receive port to receive data from the isolate
        final receivePort = ReceivePort();

        // Act: Start an isolate to perform computation
        await Isolate.spawn((SendPort sendPort) {
          // Here we are in the new isolate
          const updatedState = 42;
          sendPort.send(updatedState); // Send the updated state to main isolate
        }, receivePort.sendPort);

        // Listen to the receive port to get the updated state
        final updatedState = await receivePort.first;

        // Update the state in the main isolate
        isolateState.updateState(updatedState as int);

        // Assert: State should be updated from isolate computation
        expect(isolateState.notifier, 42,
            reason: 'State should be updated with value from isolate');
        expect(listenerCallCount, 1,
            reason: 'Listener should be called after isolate update');
      });

      test('should handle multiple isolate operations concurrently', () async {
        // Setup: Create ReactiveNotifier for multiple isolate operations
        final multiIsolateState = ReactiveNotifier<List<int>>(() => []);

        // Create receive ports for multiple isolates
        final receivePorts = List.generate(3, (_) => ReceivePort());
        final results = <int>[];

        // Act: Start multiple isolates for parallel computation
        for (int i = 0; i < receivePorts.length; i++) {
          await Isolate.spawn((Map<String, dynamic> params) {
            final SendPort sendPort = params['sendPort'] as SendPort;
            final int multiplier = params['multiplier'] as int;
            
            // Simulate computation in isolate
            final result = multiplier * multiplier;
            sendPort.send(result);
          }, {
            'sendPort': receivePorts[i].sendPort,
            'multiplier': i + 2, // 2, 3, 4
          });
        }

        // Collect results from all isolates
        for (final receivePort in receivePorts) {
          final result = await receivePort.first;
          results.add(result as int);
        }

        // Update state with all isolate results
        multiIsolateState.updateState(results);

        // Assert: All isolate computations should be collected
        expect(multiIsolateState.notifier, [4, 9, 16],
            reason: 'State should contain results from all isolates (2²=4, 3²=9, 4²=16)');
        expect(results.length, 3,
            reason: 'Should receive results from all 3 isolates');
      });
    });

    group('Performance Optimization for Async Operations', () {
      test('should optimize frequent async updates efficiently', () async {
        // Setup: Create ReactiveNotifier for performance testing
        final optimizedState = ReactiveNotifier<int>(() => 0);
        var updateCount = 0;
        final startTime = DateTime.now();

        optimizedState.addListener(() => updateCount++);

        // Act: Perform many rapid async updates
        final futures = <Future<void>>[];
        for (var i = 1; i <= 50; i++) {
          futures.add(Future.delayed(
            Duration(milliseconds: i % 10), // Vary delays
            () => optimizedState.updateState(i),
          ));
        }

        await Future.wait(futures);
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should handle frequent updates efficiently
        expect(updateCount, 50,
            reason: 'All async updates should be processed');
        expect(optimizedState.notifier, greaterThan(0),
            reason: 'Final state should be updated');
        expect(duration.inMilliseconds, lessThan(1000),
            reason: 'Frequent async updates should complete within reasonable time');
      });

      test('should maintain consistency during high-frequency async operations', () async {
        // Setup: Create system for high-frequency operations
        final highFrequencyState = ReactiveNotifier<Map<String, int>>(() => {
          'counter': 0,
          'sum': 0,
        });

        var consistencyChecks = 0;
        var inconsistentStates = 0;

        highFrequencyState.addListener(() {
          consistencyChecks++;
          final state = highFrequencyState.notifier;
          final counter = state['counter']!;
          final sum = state['sum']!;
          
          // Check if sum matches expected value (sum of 1 to counter)
          final expectedSum = counter * (counter + 1) ~/ 2;
          if (sum != expectedSum) {
            inconsistentStates++;
          }
        });

        // Act: Perform high-frequency updates with computation
        final futures = <Future<void>>[];
        for (int i = 1; i <= 20; i++) {
          futures.add(Future.delayed(
            Duration(milliseconds: i * 2),
            () {
              final currentState = Map<String, int>.from(highFrequencyState.notifier);
              currentState['counter'] = i;
              currentState['sum'] = i * (i + 1) ~/ 2; // Sum of 1 to i
              highFrequencyState.updateState(currentState);
            },
          ));
        }

        await Future.wait(futures);

        // Assert: High-frequency operations should maintain consistency
        expect(consistencyChecks, greaterThan(0),
            reason: 'Consistency checks should be performed');
        expect(inconsistentStates, 0,
            reason: 'No inconsistent states should be detected');
        expect(highFrequencyState.notifier['counter'], 20,
            reason: 'Final counter should be correct');
        expect(highFrequencyState.notifier['sum'], 210,
            reason: 'Final sum should be correct (sum of 1 to 20 = 210)');
      });

      test('should handle async operations with cleanup correctly', () async {
        // Setup: Create ReactiveNotifier with cleanup simulation
        final cleanupState = ReactiveNotifier<String>(() => 'initial');
        final operationResults = <String>[];
        var cleanupCalled = false;

        // Simulate async operation with cleanup
        Future<void> performAsyncOperationWithCleanup() async {
          try {
            await Future.delayed(const Duration(milliseconds: 50));
            cleanupState.updateState('processing');
            operationResults.add('processed');
            
            await Future.delayed(const Duration(milliseconds: 30));
            cleanupState.updateState('completed');
            operationResults.add('completed');
          } finally {
            // Simulate cleanup
            cleanupCalled = true;
            operationResults.add('cleanup');
          }
        }

        // Act: Perform async operation with cleanup
        await performAsyncOperationWithCleanup();

        // Assert: Operation and cleanup should complete correctly
        expect(cleanupState.notifier, 'completed',
            reason: 'Async operation should complete successfully');
        expect(cleanupCalled, true,
            reason: 'Cleanup should be called');
        expect(operationResults, ['processed', 'completed', 'cleanup'],
            reason: 'Operation should complete with proper cleanup sequence');
      });
    });
  });
}