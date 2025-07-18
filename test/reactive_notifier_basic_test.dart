import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier basic functionality
///
/// This test suite covers the core basic functionality of ReactiveNotifier:
/// - Initialization with default values
/// - Instance creation and separation
/// - Basic state updates with updateState()
/// - Single value management
///
/// These tests verify that ReactiveNotifier can be created, initialized properly,
/// and handle basic state changes as expected.
void main() {
  group('ReactiveNotifier Basic Functionality', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Initialization Tests', () {
      test('should initialize with default value from factory function', () {
        // Setup: Create ReactiveNotifier with factory function returning 0
        final state = ReactiveNotifier<int>(() => 0);

        // Assert: Should initialize with the factory function result
        expect(state.notifier, 0,
            reason:
                'ReactiveNotifier should initialize with factory function result');
        expect(ReactiveNotifier.instanceCount, 1,
            reason: 'Instance count should reflect the created notifier');
      });

      test('should create separate instances for each ReactiveNotifier call',
          () {
        // Setup: Create multiple ReactiveNotifier instances with different values
        final state1 = ReactiveNotifier<int>(() => 0);
        final state2 = ReactiveNotifier<int>(() => 1);

        // Assert: Each instance should maintain its own value
        expect(state1.notifier, 0,
            reason: 'First instance should have its own initial value');
        expect(state2.notifier, 1,
            reason: 'Second instance should have its own initial value');
        expect(ReactiveNotifier.instanceCount, 2,
            reason: 'Instance count should track all created notifiers');
      });

      test('should support different data types during initialization', () {
        // Setup: Create ReactiveNotifiers with various data types
        final intState = ReactiveNotifier<int>(() => 42);
        final stringState = ReactiveNotifier<String>(() => 'hello');
        final boolState = ReactiveNotifier<bool>(() => true);
        final listState = ReactiveNotifier<List<int>>(() => [1, 2, 3]);

        // Assert: Each type should be properly initialized
        expect(intState.notifier, 42,
            reason: 'Int notifier should initialize correctly');
        expect(stringState.notifier, 'hello',
            reason: 'String notifier should initialize correctly');
        expect(boolState.notifier, true,
            reason: 'Bool notifier should initialize correctly');
        expect(listState.notifier, [1, 2, 3],
            reason: 'List notifier should initialize correctly');
        expect(ReactiveNotifier.instanceCount, 4,
            reason: 'All different type instances should be counted');
      });

      test('should handle nullable types during initialization', () {
        // Setup: Create ReactiveNotifiers with nullable types
        final nullableIntState = ReactiveNotifier<int?>(() => null);
        final nullableStringState = ReactiveNotifier<String?>(() => 'initial');

        // Assert: Nullable types should be supported
        expect(nullableIntState.notifier, isNull,
            reason: 'Nullable int should support null initialization');
        expect(nullableStringState.notifier, 'initial',
            reason: 'Nullable string should support non-null initialization');
      });
    });

    group('Basic State Update Tests', () {
      test('should update value with updateState() and reflect new value', () {
        // Setup: Create ReactiveNotifier with initial value
        final state = ReactiveNotifier<int>(() => 0);
        expect(state.notifier, 0, reason: 'Initial state should be 0');

        // Act: Update state to new value
        state.updateState(10);

        // Assert: State should reflect the new value
        expect(state.notifier, 10,
            reason: 'State should be updated to new value after updateState()');
      });

      test('should handle multiple consecutive state updates', () {
        // Setup: Create ReactiveNotifier
        final state = ReactiveNotifier<String>(() => 'initial');

        // Act: Perform multiple updates
        state.updateState('first');
        expect(state.notifier, 'first', reason: 'Should update to first value');

        state.updateState('second');
        expect(state.notifier, 'second',
            reason: 'Should update to second value');

        state.updateState('final');
        expect(state.notifier, 'final', reason: 'Should update to final value');

        // Assert: Final state should be the last updated value
        expect(state.notifier, 'final',
            reason: 'Final state should reflect the last updateState() call');
      });

      test('should handle updateState() with same value', () {
        // Setup: Create ReactiveNotifier
        final state = ReactiveNotifier<int>(() => 5);

        // Act: Update with same value multiple times
        state.updateState(5);
        state.updateState(5);
        state.updateState(5);

        // Assert: State should remain consistent
        expect(state.notifier, 5,
            reason:
                'State should remain consistent when updated with same value');
      });

      test('should update complex objects correctly', () {
        // Setup: Create ReactiveNotifier with complex object
        final state = ReactiveNotifier<Map<String, dynamic>>(
            () => {'count': 0, 'name': 'test'});

        // Act: Update with new complex object
        state.updateState({'count': 1, 'name': 'updated', 'active': true});

        // Assert: Complex object should be updated completely
        expect(state.notifier['count'], 1, reason: 'Count should be updated');
        expect(state.notifier['name'], 'updated',
            reason: 'Name should be updated');
        expect(state.notifier['active'], true,
            reason: 'New property should be added');
        expect(state.notifier.length, 3,
            reason: 'Map should have all properties');
      });

      test('should update List values correctly', () {
        // Setup: Create ReactiveNotifier with List
        final state = ReactiveNotifier<List<String>>(() => ['a', 'b']);

        // Act: Update with new List
        state.updateState(['x', 'y', 'z']);

        // Assert: List should be completely replaced
        expect(state.notifier, ['x', 'y', 'z'],
            reason: 'List should be completely replaced with new values');
        expect(state.notifier.length, 3, reason: 'List should have new length');
      });

      test('should handle null updates for nullable types', () {
        // Setup: Create ReactiveNotifier with nullable type
        final state = ReactiveNotifier<String?>(() => 'initial');

        // Act: Update to null
        state.updateState(null);

        // Assert: Should accept null value
        expect(state.notifier, isNull,
            reason: 'Nullable type should accept null updates');

        // Act: Update back to non-null
        state.updateState('restored');

        // Assert: Should accept non-null value again
        expect(state.notifier, 'restored',
            reason: 'Should accept non-null value after null');
      });
    });

    group('State Value Access Tests', () {
      test(
          'should provide consistent access to current value via notifier getter',
          () {
        // Setup: Create ReactiveNotifier
        final state = ReactiveNotifier<double>(() => 3.14);

        // Act & Assert: Multiple accesses should return same value
        expect(state.notifier, 3.14,
            reason: 'First access should return initial value');
        expect(state.notifier, 3.14,
            reason: 'Second access should return same value');
        expect(state.notifier, 3.14,
            reason: 'Third access should return same value');

        // Act: Update and verify consistent access
        state.updateState(2.71);
        expect(state.notifier, 2.71,
            reason: 'Access after update should return new value');
        expect(state.notifier, 2.71,
            reason: 'Subsequent access should remain consistent');
      });

      test('should maintain value integrity across multiple reads', () {
        // Setup: Create ReactiveNotifier with complex data
        final testData = {
          'users': ['Alice', 'Bob'],
          'count': 2
        };
        final state = ReactiveNotifier<Map<String, dynamic>>(() => testData);

        // Act & Assert: Multiple reads should maintain data integrity
        final read1 = state.notifier;
        final read2 = state.notifier;
        final read3 = state.notifier;

        expect(read1, equals(read2),
            reason: 'Multiple reads should return equal data');
        expect(read2, equals(read3),
            reason: 'Subsequent reads should remain equal');
        expect(read1['users'], ['Alice', 'Bob'],
            reason: 'Nested data should be preserved');
        expect(read1['count'], 2,
            reason: 'All properties should be maintained');
      });
    });
  });
}
