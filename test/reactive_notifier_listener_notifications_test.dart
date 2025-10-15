import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier listener notification system
///
/// This test suite covers the core listener notification functionality of ReactiveNotifier:
/// - Basic listener registration and notification
/// - Multiple listener management and coordination
/// - Listener removal and cleanup
/// - Notification order and consistency
/// - Edge cases in listener management
///
/// These tests verify that the listener system works correctly for the
/// fundamental reactive pattern where state changes trigger callbacks
/// to registered listeners, enabling reactive UI updates and business logic.
void main() {
  group('ReactiveNotifier Listener Notifications', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Basic Listener Notification Tests', () {
      test('should notify single listener when state updates', () {
        // Setup: Create ReactiveNotifier and register listener
        final notify = ReactiveNotifier<int>(() => 0);
        int? notifiedValue;
        var callCount = 0;

        notify.addListener(() {
          callCount++;
          notifiedValue = notify.notifier;
        });

        // Act: Update state
        notify.updateState(5);

        // Assert: Listener should be called with correct value
        expect(notifiedValue, equals(5),
            reason: 'Listener should receive the updated value');
        expect(callCount, equals(1),
            reason: 'Listener should be called exactly once');
      });

      test('should notify listener immediately when state changes', () {
        // Setup: Create ReactiveNotifier with string value
        final notify = ReactiveNotifier<String>(() => 'initial');
        String? receivedValue;
        DateTime? notificationTime;

        notify.addListener(() {
          receivedValue = notify.notifier;
          notificationTime = DateTime.now();
        });

        // Act: Update state and record update time
        final updateTime = DateTime.now();
        notify.updateState('updated');

        // Assert: Notification should happen immediately
        expect(receivedValue, equals('updated'),
            reason: 'Listener should receive updated value immediately');
        expect(notificationTime, isNotNull,
            reason: 'Notification should have occurred');
        expect(notificationTime!.difference(updateTime).inMilliseconds,
            lessThan(10),
            reason: 'Notification should happen within milliseconds of update');
      });

      test('should notify listener for different data types', () {
        // Test notifications for various data types

        // Test int notifications
        final intNotifier = ReactiveNotifier<int>(() => 0);
        int? receivedInt;
        intNotifier.addListener(() => receivedInt = intNotifier.notifier);
        intNotifier.updateState(42);
        expect(receivedInt, 42, reason: 'Int listener should work');

        // Test bool notifications
        final boolNotifier = ReactiveNotifier<bool>(() => false);
        bool? receivedBool;
        boolNotifier.addListener(() => receivedBool = boolNotifier.notifier);
        boolNotifier.updateState(true);
        expect(receivedBool, true, reason: 'Bool listener should work');

        // Test List notifications
        final listNotifier = ReactiveNotifier<List<String>>(() => []);
        List<String>? receivedList;
        listNotifier.addListener(() => receivedList = listNotifier.notifier);
        listNotifier.updateState(['a', 'b', 'c']);
        expect(receivedList, ['a', 'b', 'c'],
            reason: 'List listener should work');

        // Test Map notifications
        final mapNotifier = ReactiveNotifier<Map<String, int>>(() => {});
        Map<String, int>? receivedMap;
        mapNotifier.addListener(() => receivedMap = mapNotifier.notifier);
        mapNotifier.updateState({'key': 123});
        expect(receivedMap, {'key': 123}, reason: 'Map listener should work');
      });

      test('should handle null values in nullable type notifications', () {
        // Setup: Create nullable ReactiveNotifier
        final notify = ReactiveNotifier<String?>(() => 'initial');
        String? receivedValue;
        var callCount = 0;

        notify.addListener(() {
          callCount++;
          receivedValue = notify.notifier;
        });

        // Act: Update to null
        notify.updateState(null);

        // Assert: Should notify with null value
        expect(receivedValue, isNull,
            reason: 'Listener should receive null value');
        expect(callCount, equals(1),
            reason: 'Listener should be called once for null update');

        // Act: Update from null to value
        notify.updateState('restored');

        // Assert: Should notify with restored value
        expect(receivedValue, equals('restored'),
            reason: 'Listener should receive restored value');
        expect(callCount, equals(2),
            reason: 'Listener should be called again for restored value');
      });
    });

    group('Multiple Listener Management Tests', () {
      test('should notify all registered listeners when state updates', () {
        // Setup: Create ReactiveNotifier and register multiple listeners
        final notify = ReactiveNotifier<int>(() => 0);
        int? listener1Value;
        int? listener2Value;
        int? listener3Value;
        var listener1Calls = 0;
        var listener2Calls = 0;
        var listener3Calls = 0;

        notify.addListener(() {
          listener1Calls++;
          listener1Value = notify.notifier;
        });
        notify.addListener(() {
          listener2Calls++;
          listener2Value = notify.notifier;
        });
        notify.addListener(() {
          listener3Calls++;
          listener3Value = notify.notifier;
        });

        // Act: Update state
        notify.updateState(10);

        // Assert: All listeners should be notified
        expect(listener1Value, equals(10),
            reason: 'First listener should receive value');
        expect(listener2Value, equals(10),
            reason: 'Second listener should receive value');
        expect(listener3Value, equals(10),
            reason: 'Third listener should receive value');
        expect(listener1Calls, equals(1),
            reason: 'First listener should be called once');
        expect(listener2Calls, equals(1),
            reason: 'Second listener should be called once');
        expect(listener3Calls, equals(1),
            reason: 'Third listener should be called once');
      });

      test('should notify listeners in the order they were added', () {
        // Setup: Create ReactiveNotifier and track listener execution order
        final notify = ReactiveNotifier<String>(() => 'initial');
        final executionOrder = <String>[];

        notify.addListener(() => executionOrder.add('listener1'));
        notify.addListener(() => executionOrder.add('listener2'));
        notify.addListener(() => executionOrder.add('listener3'));

        // Act: Update state
        notify.updateState('test');

        // Assert: Listeners should execute in registration order
        expect(executionOrder, equals(['listener1', 'listener2', 'listener3']),
            reason:
                'Listeners should execute in the order they were registered');
      });

      test(
          'should handle listeners that access the notifier value during callback',
          () {
        // Setup: Create ReactiveNotifier with listeners that read current value
        final notify = ReactiveNotifier<int>(() => 5);
        final receivedValues = <int>[];
        var totalSum = 0;

        // Add listeners that perform different operations with the current value
        notify.addListener(() {
          final currentValue = notify.notifier;
          receivedValues.add(currentValue);
        });

        notify.addListener(() {
          final currentValue = notify.notifier;
          totalSum += currentValue;
        });

        notify.addListener(() {
          final currentValue = notify.notifier;
          // Verify value is consistent across all listeners in same update
          expect(currentValue, equals(notify.notifier),
              reason: 'Value should be consistent within same update cycle');
        });

        // Act: Update state multiple times
        notify.updateState(10);
        notify.updateState(20);
        notify.updateState(30);

        // Assert: All listeners should have consistent access to values
        expect(receivedValues, equals([10, 20, 30]),
            reason: 'Values should be recorded correctly by first listener');
        expect(totalSum, equals(60),
            reason:
                'Sum should be calculated correctly by second listener (10+20+30)');
      });

      test('should handle large number of listeners efficiently', () {
        // Setup: Create ReactiveNotifier and add many listeners
        final notify = ReactiveNotifier<int>(() => 0);
        const listenerCount = 1000;
        var totalCallbacks = 0;
        final results = <int>[];

        // Add many listeners
        for (int i = 0; i < listenerCount; i++) {
          notify.addListener(() {
            totalCallbacks++;
            if (i % 100 == 0) {
              // Sample every 100th listener
              results.add(notify.notifier);
            }
          });
        }

        // Act: Update state
        final startTime = DateTime.now();
        notify.updateState(42);
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: All listeners should be called efficiently
        expect(totalCallbacks, equals(listenerCount),
            reason: 'All $listenerCount listeners should be called');
        expect(results.length, equals(10),
            reason: 'Sample listeners should have recorded values');
        expect(results.every((value) => value == 42), isTrue,
            reason: 'All sampled values should be correct');
        expect(duration.inMilliseconds, lessThan(100),
            reason: 'Large number of listeners should be notified quickly');
      });
    });

    group('Listener Removal and Cleanup Tests', () {
      test('should not notify removed listeners', () {
        // Setup: Create ReactiveNotifier and add listener
        final notify = ReactiveNotifier<int>(() => 0);
        int? listenerValue;
        var callCount = 0;

        void listener() {
          callCount++;
          listenerValue = notify.notifier;
        }

        notify.addListener(listener);

        // Act: Update state to verify listener works
        notify.updateState(5);
        expect(listenerValue, equals(5),
            reason: 'Listener should work initially');
        expect(callCount, equals(1),
            reason: 'Listener should be called initially');

        // Act: Remove listener and update state again
        notify.removeListener(listener);
        notify.updateState(10);

        // Assert: Removed listener should not be called
        expect(listenerValue, equals(5),
            reason: 'Listener value should not update after removal');
        expect(callCount, equals(1),
            reason: 'Listener should not be called after removal');
      });

      test('should handle removal of non-existent listeners gracefully', () {
        // Setup: Create ReactiveNotifier
        final notify = ReactiveNotifier<String>(() => 'test');

        void nonExistentListener() {}

        // Act: Try to remove listener that was never added
        expect(
            () => notify.removeListener(nonExistentListener), returnsNormally,
            reason: 'Removing non-existent listener should not throw');

        // Verify notifier still works normally
        String? receivedValue;
        notify.addListener(() => receivedValue = notify.notifier);
        notify.updateState('works');
        expect(receivedValue, equals('works'),
            reason:
                'Notifier should work normally after attempted removal of non-existent listener');
      });

      test('should handle removal of listeners during notification', () {
        // Setup: Create ReactiveNotifier with listeners that remove themselves
        final notify = ReactiveNotifier<int>(() => 0);
        var listener1Calls = 0;
        var listener2Calls = 0;
        var listener3Calls = 0;

        late VoidCallback listener1;
        late VoidCallback listener2;
        late VoidCallback listener3;

        listener1 = () {
          listener1Calls++;
          // Remove self during notification
          notify.removeListener(listener1);
        };

        listener2 = () {
          listener2Calls++;
          // This listener remains
        };

        listener3 = () {
          listener3Calls++;
          // Remove another listener during notification
          notify.removeListener(listener2);
        };

        notify.addListener(listener1);
        notify.addListener(listener2);
        notify.addListener(listener3);

        // Act: Update state (should trigger self-removal)
        notify.updateState(5);

        // Assert: Self-removing listeners should work correctly
        expect(listener1Calls, equals(1),
            reason: 'Self-removing listener should be called once');
        expect(listener2Calls, equals(1),
            reason:
                'Listener removed by other should still be called in same cycle');
        expect(listener3Calls, equals(1),
            reason: 'Listener that removes others should be called');

        // Act: Update state again
        notify.updateState(10);

        // Assert: Removed listeners should not be called again
        expect(listener1Calls, equals(1),
            reason: 'Self-removed listener should not be called again');
        expect(listener2Calls, equals(1),
            reason: 'Externally removed listener should not be called again');
        expect(listener3Calls, equals(2),
            reason: 'Remaining listener should continue to be called');
      });

      test('should properly clean up all listeners with multiple removals', () {
        // Setup: Create ReactiveNotifier with multiple listeners
        final notify = ReactiveNotifier<double>(() => 0.0);
        final listeners = <VoidCallback>[];
        var totalCalls = 0;

        // Create and add multiple listeners
        for (int i = 0; i < 10; i++) {
          int listener() => totalCalls++;
          listeners.add(listener);
          notify.addListener(listener);
        }

        // Act: Update to verify all listeners work
        notify.updateState(1.0);
        expect(totalCalls, equals(10),
            reason: 'All listeners should be called initially');

        // Act: Remove listeners one by one
        for (int i = 0; i < 5; i++) {
          notify.removeListener(listeners[i]);
        }

        totalCalls = 0; // Reset counter
        notify.updateState(2.0);
        expect(totalCalls, equals(5),
            reason: 'Only remaining 5 listeners should be called');

        // Act: Remove remaining listeners
        for (int i = 5; i < 10; i++) {
          notify.removeListener(listeners[i]);
        }

        totalCalls = 0; // Reset counter
        notify.updateState(3.0);
        expect(totalCalls, equals(0),
            reason: 'No listeners should be called after all are removed');
      });
    });

    group('Notification Edge Cases and Error Handling', () {
      test(
          'should handle listeners that throw exceptions by continuing normal operation',
          () {
        // Setup: Create ReactiveNotifier with mix of normal and throwing listeners
        final notify = ReactiveNotifier<int>(() => 0);
        var normalListener1Calls = 0;
        var normalListener2Calls = 0;
        var throwingListenerCalls = 0;

        notify.addListener(() {
          normalListener1Calls++;
        });

        notify.addListener(() {
          throwingListenerCalls++;
          throw Exception('Test exception from listener');
        });

        notify.addListener(() {
          normalListener2Calls++;
        });

        // Act: Update state (should complete normally despite listener exception)
        // Flutter's ChangeNotifier catches exceptions internally and logs them
        // Suppress error output during this test for cleaner test logs
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          // Suppress the expected exception from being logged
          if (!details.exception
              .toString()
              .contains('Test exception from listener')) {
            originalOnError?.call(details);
          }
        };

        try {
          notify.updateState(5);
        } finally {
          FlutterError.onError = originalOnError;
        }

        // Assert: All listeners should be called despite the exception
        expect(normalListener1Calls, equals(1),
            reason: 'First normal listener should be called');
        expect(throwingListenerCalls, equals(1),
            reason: 'Throwing listener should have been called');
        expect(normalListener2Calls, equals(1),
            reason:
                'Second listener should be called despite exception from previous listener');

        // Assert: State should still be updated correctly
        expect(notify.notifier, equals(5),
            reason:
                'State should be updated correctly despite listener exception');
      });

      test('should handle rapid successive state updates correctly', () {
        // Setup: Create ReactiveNotifier with listener that tracks all updates
        final notify = ReactiveNotifier<int>(() => 0);
        final receivedValues = <int>[];
        var callCount = 0;

        notify.addListener(() {
          callCount++;
          receivedValues.add(notify.notifier);
        });

        // Act: Perform rapid successive updates
        for (int i = 1; i <= 100; i++) {
          notify.updateState(i);
        }

        // Assert: All updates should be captured
        expect(callCount, equals(100),
            reason: 'Listener should be called for each update');
        expect(receivedValues.length, equals(100),
            reason: 'All values should be captured');
        expect(receivedValues.last, equals(100),
            reason: 'Final value should be correct');
        expect(receivedValues.first, equals(1),
            reason: 'First value should be correct');
      });

      test('should maintain correct state during nested notifications', () {
        // Setup: Create ReactiveNotifiers that update each other
        final notifierA = ReactiveNotifier<int>(() => 0);
        final notifierB = ReactiveNotifier<int>(() => 0);
        var aCallCount = 0;
        var bCallCount = 0;

        // Setup: A updates B, but B doesn't update A (to avoid infinite loop)
        notifierA.addListener(() {
          aCallCount++;
          if (aCallCount == 1) {
            // Only update B once to prevent loops
            notifierB.updateState(notifierA.notifier * 2);
          }
        });

        notifierB.addListener(() {
          bCallCount++;
        });

        // Act: Update A, which should trigger update to B
        notifierA.updateState(5);

        // Assert: Nested notifications should work correctly
        expect(aCallCount, equals(1),
            reason: 'NotifierA listener should be called once');
        expect(bCallCount, equals(1),
            reason:
                'NotifierB listener should be called once due to nested update');
        expect(notifierA.notifier, equals(5),
            reason: 'NotifierA should have correct value');
        expect(notifierB.notifier, equals(10),
            reason: 'NotifierB should have value updated by A (5 * 2 = 10)');
      });
    });
  });
}
