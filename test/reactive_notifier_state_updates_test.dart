import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier state update methods
///
/// This test suite covers all state update methods available in ReactiveNotifier:
/// - updateState() - Updates state and notifies listeners
/// - updateSilently() - Updates state WITHOUT notifying listeners
/// - transformState() - Transforms state using function and notifies listeners
/// - transformStateSilently() - Transforms state using function WITHOUT notifying listeners
///
/// Each method is tested with different data types, edge cases, and scenarios
/// to ensure proper behavior and prevent regressions.
void main() {
  group('ReactiveNotifier State Updates', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('updateSilently() Method Tests', () {
      test('should update int value without notifying listeners', () {
        // Setup: Create ReactiveNotifier with int value and add listener
        final notifier = ReactiveNotifier<int>(() => 0);
        var listenerCallCount = 0;
        final receivedValues = <int>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Update state silently
        notifier.updateSilently(42);

        // Assert: Value should change but listeners should NOT be called
        expect(notifier.notifier, equals(42),
            reason: 'Value should be updated to new value');
        expect(listenerCallCount, equals(0),
            reason: 'Listeners should NOT be called when updating silently');
        expect(receivedValues, isEmpty,
            reason: 'No values should be received by listeners');
      });

      test('should update String value without notifying listeners', () {
        // Setup: Create ReactiveNotifier with String value
        final notifier = ReactiveNotifier<String>(() => 'initial');
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Update string value silently
        notifier.updateSilently('updated silently');

        // Assert: String should be updated without notification
        expect(notifier.notifier, equals('updated silently'));
        expect(listenerCallCount, equals(0));
      });

      test('should update List value without notifying listeners', () {
        // Setup: Create ReactiveNotifier with List value
        final notifier = ReactiveNotifier<List<int>>(() => [1, 2, 3]);
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Update list silently
        final newList = [4, 5, 6, 7];
        notifier.updateSilently(newList);

        // Assert: List should be updated without notification
        expect(notifier.notifier, equals([4, 5, 6, 7]));
        expect(listenerCallCount, equals(0));
        expect(identical(notifier.notifier, newList), isTrue,
            reason: 'Should maintain object reference');
      });

      test('should update Map value without notifying listeners', () {
        // Setup: Create ReactiveNotifier with Map value
        final notifier =
            ReactiveNotifier<Map<String, dynamic>>(() => {'key': 'value'});
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Update map silently
        final newMap = {'newKey': 'newValue', 'count': 42};
        notifier.updateSilently(newMap);

        // Assert: Map should be updated without notification
        expect(notifier.notifier, equals({'newKey': 'newValue', 'count': 42}));
        expect(listenerCallCount, equals(0));
      });

      test('should update nullable value without notifying listeners', () {
        // Setup: Create ReactiveNotifier with nullable value
        final notifier = ReactiveNotifier<String?>(() => 'initial');
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Update to null silently
        notifier.updateSilently(null);

        // Assert: Should update to null without notification
        expect(notifier.notifier, isNull);
        expect(listenerCallCount, equals(0));

        // Act: Update from null to value silently
        notifier.updateSilently('back to value');

        // Assert: Should update from null without notification
        expect(notifier.notifier, equals('back to value'));
        expect(listenerCallCount, equals(0));
      });

      test('should update complex custom object without notifying listeners',
          () {
        // Setup: Create ReactiveNotifier with custom object
        final notifier =
            ReactiveNotifier<TestModel>(() => TestModel(id: 1, name: 'test'));
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Update custom object silently
        final newModel = TestModel(id: 2, name: 'updated');
        notifier.updateSilently(newModel);

        // Assert: Custom object should be updated without notification
        expect(notifier.notifier.id, equals(2));
        expect(notifier.notifier.name, equals('updated'));
        expect(listenerCallCount, equals(0));
      });

      test(
          'should allow multiple silent updates without accumulating notifications',
          () {
        // Setup: Create ReactiveNotifier and add listener
        final notifier = ReactiveNotifier<int>(() => 0);
        var listenerCallCount = 0;
        final receivedValues = <int>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Multiple silent updates
        notifier.updateSilently(1);
        notifier.updateSilently(2);
        notifier.updateSilently(3);
        notifier.updateSilently(4);
        notifier.updateSilently(5);

        // Assert: No listeners should be called despite multiple updates
        expect(notifier.notifier, equals(5));
        expect(listenerCallCount, equals(0));
        expect(receivedValues, isEmpty);
      });

      test('should work correctly when mixed with regular updates', () {
        // Setup: Create ReactiveNotifier and add listener
        final notifier = ReactiveNotifier<int>(() => 0);
        var listenerCallCount = 0;
        final receivedValues = <int>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Mix silent and regular updates
        notifier.updateSilently(10); // Silent - no notification
        notifier.updateState(20); // Regular - should notify
        notifier.updateSilently(30); // Silent - no notification
        notifier.updateState(40); // Regular - should notify

        // Assert: Only regular updates should trigger notifications
        expect(notifier.notifier, equals(40));
        expect(listenerCallCount, equals(2),
            reason: 'Only regular updates should notify listeners');
        expect(receivedValues, equals([20, 40]),
            reason:
                'Listeners should only receive values from regular updates');
      });
    });

    group('transformState() Method Tests', () {
      test('should transform int value using function and notify listeners',
          () {
        // Setup: Create ReactiveNotifier with int value and add listener
        final notifier = ReactiveNotifier<int>(() => 10);
        var listenerCallCount = 0;
        final receivedValues = <int>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Transform state using function (multiply by 2)
        notifier.transformState((currentValue) => currentValue * 2);

        // Assert: Value should be transformed and listeners should be notified
        expect(notifier.notifier, equals(20),
            reason: 'Value should be transformed by the function');
        expect(listenerCallCount, equals(1),
            reason: 'Listeners should be called when transforming state');
        expect(receivedValues, equals([20]),
            reason: 'Listeners should receive the transformed value');
      });

      test('should transform String value using function and notify listeners',
          () {
        // Setup: Create ReactiveNotifier with String value
        final notifier = ReactiveNotifier<String>(() => 'hello');
        var listenerCallCount = 0;
        final receivedValues = <String>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Transform string using function (uppercase)
        notifier.transformState((currentValue) => currentValue.toUpperCase());

        // Assert: String should be transformed and listeners notified
        expect(notifier.notifier, equals('HELLO'));
        expect(listenerCallCount, equals(1));
        expect(receivedValues, equals(['HELLO']));
      });

      test('should transform List value using function and notify listeners',
          () {
        // Setup: Create ReactiveNotifier with List value
        final notifier = ReactiveNotifier<List<int>>(() => [1, 2, 3]);
        var listenerCallCount = 0;
        final receivedValues = <List<int>>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(
              List.from(notifier.notifier)); // Copy to avoid reference issues
        });

        // Act: Transform list using function (add new element)
        notifier.transformState((currentList) => [...currentList, 4]);

        // Assert: List should be transformed and listeners notified
        expect(notifier.notifier, equals([1, 2, 3, 4]));
        expect(listenerCallCount, equals(1));
        expect(
            receivedValues,
            equals([
              [1, 2, 3, 4]
            ]));
      });

      test('should transform Map value using function and notify listeners',
          () {
        // Setup: Create ReactiveNotifier with Map value
        final notifier =
            ReactiveNotifier<Map<String, int>>(() => {'a': 1, 'b': 2});
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform map using function (add new key-value)
        notifier.transformState((currentMap) => {...currentMap, 'c': 3});

        // Assert: Map should be transformed and listeners notified
        expect(notifier.notifier, equals({'a': 1, 'b': 2, 'c': 3}));
        expect(listenerCallCount, equals(1));
      });

      test('should handle complex transformations with custom objects', () {
        // Setup: Create ReactiveNotifier with custom object
        final notifier = ReactiveNotifier<TestModel>(
            () => TestModel(id: 1, name: 'original'));
        var listenerCallCount = 0;
        final receivedModels = <TestModel>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedModels.add(notifier.notifier);
        });

        // Act: Transform custom object using function
        notifier.transformState((currentModel) => TestModel(
            id: currentModel.id + 100,
            name: '${currentModel.name}_transformed'));

        // Assert: Custom object should be transformed and listeners notified
        expect(notifier.notifier.id, equals(101));
        expect(notifier.notifier.name, equals('original_transformed'));
        expect(listenerCallCount, equals(1));
        expect(receivedModels.length, equals(1));
        expect(receivedModels.first.id, equals(101));
      });

      test('should handle nullable transformations', () {
        // Setup: Create ReactiveNotifier with nullable value
        final notifier = ReactiveNotifier<String?>(() => 'initial');
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform to null
        notifier.transformState((currentValue) => null);

        // Assert: Should transform to null and notify
        expect(notifier.notifier, isNull);
        expect(listenerCallCount, equals(1));

        // Act: Transform from null back to value
        notifier.transformState((currentValue) => 'restored');

        // Assert: Should transform from null and notify again
        expect(notifier.notifier, equals('restored'));
        expect(listenerCallCount, equals(2));
      });

      test('should allow chained transformations', () {
        // Setup: Create ReactiveNotifier with int value
        final notifier = ReactiveNotifier<int>(() => 5);
        var listenerCallCount = 0;
        final receivedValues = <int>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Chain multiple transformations
        notifier.transformState((value) => value * 2); // 5 -> 10
        notifier.transformState((value) => value + 5); // 10 -> 15
        notifier.transformState((value) => value ~/ 3); // 15 -> 5

        // Assert: All transformations should be applied and notify
        expect(notifier.notifier, equals(5));
        expect(listenerCallCount, equals(3),
            reason: 'Each transformation should notify listeners');
        expect(receivedValues, equals([10, 15, 5]),
            reason: 'Each intermediate value should be received');
      });

      test('should maintain function purity - original state not modified', () {
        // Setup: Create ReactiveNotifier with mutable object
        final originalList = [1, 2, 3];
        final notifier = ReactiveNotifier<List<int>>(() => originalList);

        // Act: Transform state (should not modify original)
        notifier.transformState((currentList) {
          return [...currentList, 4]; // Create new list, don't modify current
        });

        // Assert: Original reference should not be modified
        expect(originalList, equals([1, 2, 3]),
            reason: 'Original list should not be modified by transformation');
        expect(notifier.notifier, equals([1, 2, 3, 4]),
            reason: 'New state should have transformed value');
        expect(identical(notifier.notifier, originalList), isFalse,
            reason: 'New state should be different object reference');
      });
    });

    group('transformStateSilently() Method Tests', () {
      test(
          'should transform int value using function without notifying listeners',
          () {
        // Setup: Create ReactiveNotifier with int value and add listener
        final notifier = ReactiveNotifier<int>(() => 5);
        var listenerCallCount = 0;
        final receivedValues = <int>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Transform state silently (square the value)
        notifier.transformStateSilently(
            (currentValue) => currentValue * currentValue);

        // Assert: Value should be transformed but listeners should NOT be called
        expect(notifier.notifier, equals(25),
            reason: 'Value should be transformed by the function');
        expect(listenerCallCount, equals(0),
            reason:
                'Listeners should NOT be called when transforming silently');
        expect(receivedValues, isEmpty,
            reason: 'No values should be received by listeners');
      });

      test(
          'should transform String value using function without notifying listeners',
          () {
        // Setup: Create ReactiveNotifier with String value
        final notifier = ReactiveNotifier<String>(() => 'world');
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform string silently (add prefix)
        notifier
            .transformStateSilently((currentValue) => 'hello $currentValue');

        // Assert: String should be transformed without notification
        expect(notifier.notifier, equals('hello world'));
        expect(listenerCallCount, equals(0));
      });

      test(
          'should transform List value using function without notifying listeners',
          () {
        // Setup: Create ReactiveNotifier with List value
        final notifier = ReactiveNotifier<List<int>>(() => [1, 2]);
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform list silently (double all values)
        notifier.transformStateSilently(
            (currentList) => currentList.map((item) => item * 2).toList());

        // Assert: List should be transformed without notification
        expect(notifier.notifier, equals([2, 4]));
        expect(listenerCallCount, equals(0));
      });

      test(
          'should transform Map value using function without notifying listeners',
          () {
        // Setup: Create ReactiveNotifier with Map value
        final notifier =
            ReactiveNotifier<Map<String, int>>(() => {'x': 1, 'y': 2});
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform map silently (increment all values)
        notifier.transformStateSilently((currentMap) =>
            currentMap.map((key, value) => MapEntry(key, value + 10)));

        // Assert: Map should be transformed without notification
        expect(notifier.notifier, equals({'x': 11, 'y': 12}));
        expect(listenerCallCount, equals(0));
      });

      test(
          'should handle complex transformations with custom objects without notification',
          () {
        // Setup: Create ReactiveNotifier with custom object
        final notifier =
            ReactiveNotifier<TestModel>(() => TestModel(id: 100, name: 'test'));
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform custom object silently
        notifier.transformStateSilently((currentModel) => TestModel(
            id: currentModel.id * 2, name: '${currentModel.name}_silent'));

        // Assert: Custom object should be transformed without notification
        expect(notifier.notifier.id, equals(200));
        expect(notifier.notifier.name, equals('test_silent'));
        expect(listenerCallCount, equals(0));
      });

      test('should handle nullable transformations without notification', () {
        // Setup: Create ReactiveNotifier with nullable value
        final notifier = ReactiveNotifier<int?>(() => 42);
        var listenerCallCount = 0;

        notifier.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform to null silently
        notifier.transformStateSilently((currentValue) => null);

        // Assert: Should transform to null without notification
        expect(notifier.notifier, isNull);
        expect(listenerCallCount, equals(0));

        // Act: Transform from null back to value silently
        notifier.transformStateSilently((currentValue) => 99);

        // Assert: Should transform from null without notification
        expect(notifier.notifier, equals(99));
        expect(listenerCallCount, equals(0));
      });

      test(
          'should allow multiple silent transformations without accumulating notifications',
          () {
        // Setup: Create ReactiveNotifier with int value
        final notifier = ReactiveNotifier<int>(() => 1);
        var listenerCallCount = 0;
        final receivedValues = <int>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Multiple silent transformations
        notifier.transformStateSilently((value) => value + 1); // 1 -> 2
        notifier.transformStateSilently((value) => value * 3); // 2 -> 6
        notifier.transformStateSilently((value) => value - 2); // 6 -> 4
        notifier.transformStateSilently((value) => value * 5); // 4 -> 20

        // Assert: Final value should be correct but no notifications
        expect(notifier.notifier, equals(20));
        expect(listenerCallCount, equals(0));
        expect(receivedValues, isEmpty);
      });

      test('should work correctly when mixed with regular transformations', () {
        // Setup: Create ReactiveNotifier with int value
        final notifier = ReactiveNotifier<int>(() => 10);
        var listenerCallCount = 0;
        final receivedValues = <int>[];

        notifier.addListener(() {
          listenerCallCount++;
          receivedValues.add(notifier.notifier);
        });

        // Act: Mix silent and regular transformations
        notifier
            .transformStateSilently((value) => value * 2); // 10 -> 20 (silent)
        notifier.transformState((value) => value + 5); // 20 -> 25 (notify)
        notifier
            .transformStateSilently((value) => value * 2); // 25 -> 50 (silent)
        notifier.transformState((value) => value - 10); // 50 -> 40 (notify)

        // Assert: Only regular transformations should trigger notifications
        expect(notifier.notifier, equals(40));
        expect(listenerCallCount, equals(2),
            reason: 'Only regular transformations should notify listeners');
        expect(receivedValues, equals([25, 40]),
            reason:
                'Listeners should only receive values from regular transformations');
      });

      test(
          'should maintain function purity - original state not modified in silent transformation',
          () {
        // Setup: Create ReactiveNotifier with mutable object
        final originalList = [10, 20, 30];
        final notifier = ReactiveNotifier<List<int>>(() => originalList);

        // Act: Transform state silently (should not modify original)
        notifier.transformStateSilently((currentList) {
          return currentList
              .map((item) => item ~/ 2)
              .toList(); // Use integer division
        });

        // Assert: Original reference should not be modified
        expect(originalList, equals([10, 20, 30]),
            reason:
                'Original list should not be modified by silent transformation');
        expect(notifier.notifier, equals([5, 10, 15]),
            reason: 'New state should have transformed value');
        expect(identical(notifier.notifier, originalList), isFalse,
            reason: 'New state should be different object reference');
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
