import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier listener management methods
///
/// This test suite covers all listener-related methods available in ReactiveNotifier:
/// - listen() - Sets up a listener with callback that receives the current value
/// - addListener() - Standard ChangeNotifier listener management (already covered in existing tests)
/// - removeListener() - Standard ChangeNotifier listener removal (already covered in existing tests)
/// - stopListening() - Stops the current listen() callback
///
/// The listen() method is critical for reactive communication patterns and
/// cross-component communication, especially for ViewModel interactions.
void main() {
  group('ReactiveNotifier Listeners', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('listen() Method Tests', () {
      test('should setup listener and immediately return current value', () {
        // Setup: Create ReactiveNotifier with initial value
        final notifier = ReactiveNotifier<int>(() => 42);
        var callbackValue = 0;
        var callbackCallCount = 0;

        // Act: Setup listener using listen() method
        final returnedValue = notifier.listen((value) {
          callbackCallCount++;
          callbackValue = value;
        });

        // Assert: Should return current value immediately
        expect(returnedValue, equals(42),
            reason: 'listen() should return current value immediately');
        expect(callbackCallCount, equals(0),
            reason: 'Callback should not be called on setup by default');
        expect(callbackValue, equals(0),
            reason: 'Callback value should remain unchanged on setup');
      });

      test('should call listener callback when state changes', () {
        // Setup: Create ReactiveNotifier and setup listener
        final notifier = ReactiveNotifier<String>(() => 'initial');
        var callbackValue = '';
        var callbackCallCount = 0;
        final receivedValues = <String>[];

        notifier.listen((value) {
          callbackCallCount++;
          callbackValue = value;
          receivedValues.add(value);
        });

        // Act: Update state multiple times
        notifier.updateState('first');
        notifier.updateState('second');
        notifier.updateState('third');

        // Assert: Callback should be called for each update
        expect(callbackCallCount, equals(3),
            reason: 'Callback should be called for each state update');
        expect(callbackValue, equals('third'),
            reason: 'Callback should receive the latest value');
        expect(receivedValues, equals(['first', 'second', 'third']),
            reason: 'Callback should receive all values in order');
      });

      test('should handle List values correctly in listener callback', () {
        // Setup: Create ReactiveNotifier with List value
        final notifier = ReactiveNotifier<List<int>>(() => [1, 2, 3]);
        var callbackCallCount = 0;
        List<int>? receivedList;

        final returnedValue = notifier.listen((value) {
          callbackCallCount++;
          receivedList = List.from(value); // Copy to avoid reference issues
        });

        // Assert: Initial value should be returned correctly
        expect(returnedValue, equals([1, 2, 3]));

        // Act: Update with new list
        notifier.updateState([4, 5, 6, 7]);

        // Assert: Callback should receive new list
        expect(callbackCallCount, equals(1));
        expect(receivedList, equals([4, 5, 6, 7]));
      });

      test('should handle Map values correctly in listener callback', () {
        // Setup: Create ReactiveNotifier with Map value
        final notifier =
            ReactiveNotifier<Map<String, dynamic>>(() => {'key': 'value'});
        var callbackCallCount = 0;
        Map<String, dynamic>? receivedMap;

        notifier.listen((value) {
          callbackCallCount++;
          receivedMap = Map.from(value);
        });

        // Act: Update with new map
        notifier.updateState({'newKey': 'newValue', 'count': 123});

        // Assert: Callback should receive new map
        expect(callbackCallCount, equals(1));
        expect(receivedMap, equals({'newKey': 'newValue', 'count': 123}));
      });

      test('should handle custom object values correctly in listener callback',
          () {
        // Setup: Create ReactiveNotifier with custom object
        final notifier = ReactiveNotifier<TestModel>(
            () => TestModel(id: 1, name: 'initial'));
        var callbackCallCount = 0;
        TestModel? receivedModel;

        final returnedValue = notifier.listen((value) {
          callbackCallCount++;
          receivedModel = value;
        });

        // Assert: Initial value should be returned correctly
        expect(returnedValue.id, equals(1));
        expect(returnedValue.name, equals('initial'));

        // Act: Update with new custom object
        final newModel = TestModel(id: 2, name: 'updated');
        notifier.updateState(newModel);

        // Assert: Callback should receive new custom object
        expect(callbackCallCount, equals(1));
        expect(receivedModel?.id, equals(2));
        expect(receivedModel?.name, equals('updated'));
        expect(identical(receivedModel, newModel), isTrue,
            reason: 'Should maintain object reference');
      });

      test('should handle nullable values correctly in listener callback', () {
        // Setup: Create ReactiveNotifier with nullable value
        final notifier = ReactiveNotifier<String?>(() => 'initial');
        var callbackCallCount = 0;
        String? receivedValue;

        notifier.listen((value) {
          callbackCallCount++;
          receivedValue = value;
        });

        // Act: Update to null
        notifier.updateState(null);

        // Assert: Callback should receive null
        expect(callbackCallCount, equals(1));
        expect(receivedValue, isNull);

        // Act: Update back to non-null
        notifier.updateState('restored');

        // Assert: Callback should receive restored value
        expect(callbackCallCount, equals(2));
        expect(receivedValue, equals('restored'));
      });

      test(
          'should replace previous listener when listen() is called multiple times',
          () {
        // Setup: Create ReactiveNotifier
        final notifier = ReactiveNotifier<int>(() => 0);
        var firstCallbackCount = 0;
        var secondCallbackCount = 0;
        var firstCallbackValue = 0;
        var secondCallbackValue = 0;

        // Act: Setup first listener
        notifier.listen((value) {
          firstCallbackCount++;
          firstCallbackValue = value;
        });

        // Act: Setup second listener (should replace first)
        notifier.listen((value) {
          secondCallbackCount++;
          secondCallbackValue = value;
        });

        // Act: Update state
        notifier.updateState(100);

        // Assert: Only second listener should be called
        expect(firstCallbackCount, equals(0),
            reason: 'First listener should be replaced and not called');
        expect(secondCallbackCount, equals(1),
            reason: 'Second listener should be called');
        expect(firstCallbackValue, equals(0),
            reason: 'First listener should not receive updates');
        expect(secondCallbackValue, equals(100),
            reason: 'Second listener should receive updates');
      });

      test('should work correctly with silent updates', () {
        // Setup: Create ReactiveNotifier and setup listener
        final notifier = ReactiveNotifier<int>(() => 10);
        var callbackCallCount = 0;
        final receivedValues = <int>[];

        notifier.listen((value) {
          callbackCallCount++;
          receivedValues.add(value);
        });

        // Act: Mix regular and silent updates
        notifier.updateState(20); // Should trigger callback
        notifier.updateSilently(30); // Should NOT trigger callback
        notifier.updateState(40); // Should trigger callback
        notifier.updateSilently(50); // Should NOT trigger callback

        // Assert: Only regular updates should trigger callback
        expect(callbackCallCount, equals(2),
            reason: 'Only regular updates should trigger listen() callback');
        expect(receivedValues, equals([20, 40]),
            reason: 'Callback should only receive values from regular updates');
        expect(notifier.notifier, equals(50),
            reason: 'Final state should include silent updates');
      });

      test('should work correctly with transform methods', () {
        // Setup: Create ReactiveNotifier and setup listener
        final notifier = ReactiveNotifier<int>(() => 5);
        var callbackCallCount = 0;
        final receivedValues = <int>[];

        notifier.listen((value) {
          callbackCallCount++;
          receivedValues.add(value);
        });

        // Act: Mix transform methods
        notifier.transformState((v) => v * 2); // 5 -> 10 (should trigger)
        notifier.transformStateSilently(
            (v) => v + 5); // 10 -> 15 (should NOT trigger)
        notifier.transformState((v) => v * 3); // 15 -> 45 (should trigger)

        // Assert: Only non-silent transforms should trigger callback
        expect(callbackCallCount, equals(2));
        expect(receivedValues, equals([10, 45]));
        expect(notifier.notifier, equals(45));
      });
    });

    group('stopListening() Method Tests', () {
      test('should stop listen() callback from receiving updates', () {
        // Setup: Create ReactiveNotifier and setup listener
        final notifier = ReactiveNotifier<int>(() => 0);
        var callbackCallCount = 0;
        var lastReceivedValue = 0;

        notifier.listen((value) {
          callbackCallCount++;
          lastReceivedValue = value;
        });

        // Act: Update state to verify listener is working
        notifier.updateState(100);
        expect(callbackCallCount, equals(1));
        expect(lastReceivedValue, equals(100));

        // Act: Stop listening
        notifier.stopListening();

        // Act: Update state after stopping
        notifier.updateState(200);
        notifier.updateState(300);

        // Assert: Callback should not be called after stopListening()
        expect(callbackCallCount, equals(1),
            reason: 'Callback should not be called after stopListening()');
        expect(lastReceivedValue, equals(100),
            reason: 'Last received value should remain unchanged');
        expect(notifier.notifier, equals(300),
            reason: 'State should still update normally');
      });

      test('should handle multiple stopListening() calls safely', () {
        // Setup: Create ReactiveNotifier and setup listener
        final notifier = ReactiveNotifier<String>(() => 'initial');
        var callbackCallCount = 0;

        notifier.listen((value) {
          callbackCallCount++;
        });

        // Act: Call stopListening() multiple times
        notifier.stopListening();
        notifier.stopListening(); // Should not cause error
        notifier.stopListening(); // Should not cause error

        // Act: Update state
        notifier.updateState('after stop');

        // Assert: Should not cause errors and callback should not be called
        expect(callbackCallCount, equals(0));
        expect(notifier.notifier, equals('after stop'));
      });

      test('should allow setting up new listener after stopListening()', () {
        // Setup: Create ReactiveNotifier and setup first listener
        final notifier = ReactiveNotifier<int>(() => 1);
        var firstCallbackCount = 0;
        var secondCallbackCount = 0;

        notifier.listen((value) {
          firstCallbackCount++;
        });

        // Act: Stop first listener
        notifier.stopListening();

        // Act: Setup new listener
        notifier.listen((value) {
          secondCallbackCount++;
        });

        // Act: Update state
        notifier.updateState(100);

        // Assert: Only new listener should be called
        expect(firstCallbackCount, equals(0),
            reason: 'First listener should be stopped');
        expect(secondCallbackCount, equals(1),
            reason: 'New listener should work normally');
      });
    });

    group('listen() Integration Tests', () {
      test('should work correctly with cross-notifier communication', () {
        // Setup: Create two ReactiveNotifiers for cross-communication
        final sourceNotifier = ReactiveNotifier<int>(() => 10);
        final dependentNotifier = ReactiveNotifier<String>(() => 'initial');

        var listenerCallCount = 0;
        final receivedTransformations = <String>[];

        // Act: Setup cross-notifier communication using listen()
        sourceNotifier.listen((value) {
          // Transform source value and update dependent notifier
          final transformedValue = 'transformed_$value';
          dependentNotifier.updateState(transformedValue);
        });

        // Setup listener on dependent notifier to track changes
        dependentNotifier.listen((value) {
          listenerCallCount++;
          receivedTransformations.add(value);
        });

        // Act: Update source notifier
        sourceNotifier.updateState(20);
        sourceNotifier.updateState(30);

        // Assert: Dependent notifier should be updated through cross-communication
        expect(listenerCallCount, equals(2));
        expect(receivedTransformations,
            equals(['transformed_20', 'transformed_30']));
        expect(dependentNotifier.notifier, equals('transformed_30'));
      });

      test('should handle complex reactive chains correctly', () {
        // Setup: Create a chain of reactive notifiers A -> B -> C
        final notifierA = ReactiveNotifier<int>(() => 1);
        final notifierB = ReactiveNotifier<int>(() => 0);
        final notifierC = ReactiveNotifier<String>(() => 'initial');

        var finalResults = <String>[];

        // Act: Setup reactive chain A -> B -> C
        notifierA.listen((valueA) {
          notifierB.updateState(valueA * 10); // A * 10 -> B
        });

        notifierB.listen((valueB) {
          notifierC.updateState('result_$valueB'); // 'result_' + B -> C
        });

        notifierC.listen((valueC) {
          finalResults.add(valueC);
        });

        // Act: Update the source notifier
        notifierA.updateState(2); // Should cause: A=2 -> B=20 -> C='result_20'
        notifierA.updateState(5); // Should cause: A=5 -> B=50 -> C='result_50'

        // Assert: Chain should propagate correctly
        expect(finalResults, equals(['result_20', 'result_50']));
        expect(notifierA.notifier, equals(5));
        expect(notifierB.notifier, equals(50));
        expect(notifierC.notifier, equals('result_50'));
      });
    });
  });
}

/// Test model class for testing custom objects
class TestModel {
  final int id;
  final String name;

  TestModel({required this.id, required this.name});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'TestModel(id: $id, name: $name)';
}
