import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier advanced state management
///
/// This test suite covers advanced state management capabilities of ReactiveNotifier:
/// - Complex object state handling and updates
/// - Nullable state management and null safety
/// - State transitions and lifecycle tracking
/// - Custom object serialization and deserialization
/// - State history management and undo operations
///
/// These tests verify that ReactiveNotifier can handle sophisticated state patterns
/// required for complex applications including nullable states, custom objects,
/// and state transition tracking essential for advanced business logic.
void main() {
  group('ReactiveNotifier Advanced State Management', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Complex Object State Handling', () {
      test('should handle complex object states with nested properties', () {
        // Setup: Create ReactiveNotifier with complex Map state
        final complexState = ReactiveNotifier<Map<String, dynamic>>(
            () => {'count': 0, 'name': 'Test'});

        // Assert: Initial state should be correct
        expect(complexState.notifier, {'count': 0, 'name': 'Test'},
            reason: 'Initial complex state should be set correctly');

        // Act: Update complex state
        complexState.updateState({'count': 1, 'name': 'Updated'});

        // Assert: Complex state should be updated completely
        expect(complexState.notifier, {'count': 1, 'name': 'Updated'},
            reason: 'Complex state should be updated with new values');
      });

      test('should handle custom object states with properties and methods',
          () {
        // Setup: Create ReactiveNotifier with custom object state
        final customState =
            ReactiveNotifier<CustomObject>(() => CustomObject(1, 'initial'));

        // Assert: Initial custom object should be correct
        expect(customState.notifier.id, 1,
            reason: 'Initial custom object id should be correct');
        expect(customState.notifier.name, 'initial',
            reason: 'Initial custom object name should be correct');

        // Act: Update custom object state
        customState.updateState(CustomObject(2, 'updated'));

        // Assert: Custom object should be updated with new values
        expect(customState.notifier.id, 2,
            reason: 'Custom object id should be updated');
        expect(customState.notifier.name, 'updated',
            reason: 'Custom object name should be updated');
      });

      test('should handle deeply nested object structures', () {
        // Setup: Create ReactiveNotifier with deeply nested object
        final nestedState = ReactiveNotifier<Map<String, dynamic>>(() => {
              'user': {
                'profile': {
                  'personal': {'name': 'John', 'age': 30},
                  'settings': {'theme': 'dark', 'notifications': true}
                },
                'permissions': ['read', 'write']
              },
              'session': {'active': true, 'timestamp': 1234567890}
            });

        // Assert: Initial nested structure should be accessible
        expect(
            nestedState.notifier['user']['profile']['personal']['name'], 'John',
            reason: 'Deeply nested initial values should be accessible');
        expect(nestedState.notifier['session']['active'], true,
            reason: 'Session state should be accessible');

        // Act: Update deeply nested structure
        final updatedState = Map<String, dynamic>.from(nestedState.notifier);
        updatedState['user']['profile']['personal']['age'] = 31;
        updatedState['session']['timestamp'] = 1234567999;
        nestedState.updateState(updatedState);

        // Assert: Nested updates should be reflected
        expect(nestedState.notifier['user']['profile']['personal']['age'], 31,
            reason: 'Deeply nested values should be updatable');
        expect(nestedState.notifier['session']['timestamp'], 1234567999,
            reason: 'Session timestamp should be updated');
      });

      test('should handle list and collection states correctly', () {
        // Setup: Create ReactiveNotifier with collection states
        final listState = ReactiveNotifier<List<Map<String, dynamic>>>(() => [
              {'id': 1, 'name': 'Item 1', 'active': true},
              {'id': 2, 'name': 'Item 2', 'active': false}
            ]);

        // Assert: Initial list should be correct
        expect(listState.notifier.length, 2,
            reason: 'Initial list should have correct length');
        expect(listState.notifier[0]['name'], 'Item 1',
            reason: 'First item should have correct name');

        // Act: Update list by adding new item
        final updatedList = List<Map<String, dynamic>>.from(listState.notifier);
        updatedList.add({'id': 3, 'name': 'Item 3', 'active': true});
        listState.updateState(updatedList);

        // Assert: List should be updated with new item
        expect(listState.notifier.length, 3,
            reason: 'Updated list should have correct length');
        expect(listState.notifier[2]['name'], 'Item 3',
            reason: 'New item should be added correctly');

        // Act: Update existing item in list
        final modifiedList =
            List<Map<String, dynamic>>.from(listState.notifier);
        modifiedList[1]['active'] = true;
        listState.updateState(modifiedList);

        // Assert: Existing item should be updated
        expect(listState.notifier[1]['active'], true,
            reason: 'Existing item should be updatable');
      });
    });

    group('Nullable State Management', () {
      test('should handle null states correctly', () {
        // Setup: Create ReactiveNotifier with nullable type
        final nullableState = ReactiveNotifier<int?>(() => null);

        // Assert: Initial state should be null
        expect(nullableState.notifier, isNull,
            reason: 'Initial nullable state should be null');

        // Act: Update from null to value
        nullableState.updateState(5);

        // Assert: State should be updated to non-null value
        expect(nullableState.notifier, 5,
            reason: 'Nullable state should accept non-null values');

        // Act: Update back to null
        nullableState.updateState(null);

        // Assert: State should accept null again
        expect(nullableState.notifier, isNull,
            reason: 'Nullable state should accept null updates');
      });

      test('should handle nullable complex objects', () {
        // Setup: Create ReactiveNotifier with nullable custom object
        final nullableObjectState = ReactiveNotifier<CustomObject?>(() => null);

        // Assert: Initial nullable object should be null
        expect(nullableObjectState.notifier, isNull,
            reason: 'Initial nullable object should be null');

        // Act: Update with custom object
        nullableObjectState.updateState(CustomObject(42, 'test'));

        // Assert: Nullable object should contain custom object
        expect(nullableObjectState.notifier, isNotNull,
            reason: 'Nullable object should accept custom object');
        expect(nullableObjectState.notifier!.id, 42,
            reason: 'Custom object properties should be accessible');
        expect(nullableObjectState.notifier!.name, 'test',
            reason: 'Custom object name should be correct');

        // Act: Update back to null
        nullableObjectState.updateState(null);

        // Assert: Should accept null again
        expect(nullableObjectState.notifier, isNull,
            reason: 'Nullable object should accept null again');
      });

      test('should notify listeners correctly for null transitions', () {
        // Setup: Create nullable ReactiveNotifier with listener
        final nullableState = ReactiveNotifier<String?>(() => 'initial');
        String? receivedValue;
        var notificationCount = 0;

        nullableState.addListener(() {
          notificationCount++;
          receivedValue = nullableState.notifier;
        });

        // Act: Update to null
        nullableState.updateState(null);

        // Assert: Should notify about null transition
        expect(notificationCount, 1,
            reason: 'Should notify when transitioning to null');
        expect(receivedValue, isNull,
            reason: 'Listener should receive null value');

        // Act: Update from null to value
        nullableState.updateState('restored');

        // Assert: Should notify about restoration from null
        expect(notificationCount, 2,
            reason: 'Should notify when transitioning from null');
        expect(receivedValue, 'restored',
            reason: 'Listener should receive restored value');
      });
    });

    group('State Transitions and Lifecycle', () {
      test('should handle state transitions correctly', () {
        // Setup: Create ReactiveNotifier for state machine
        final stateTransition = ReactiveNotifier<String>(() => 'initial');
        var transitionCount = 0;
        final transitions = <String>[];

        stateTransition.addListener(() {
          transitionCount++;
          transitions.add(stateTransition.notifier);
        });

        // Act: Perform state transitions
        stateTransition.updateState('processing');
        stateTransition.updateState('completed');

        // Assert: All transitions should be tracked
        expect(transitionCount, 2,
            reason: 'Should count all state transitions');
        expect(transitions, ['processing', 'completed'],
            reason: 'Should track state transition sequence');
      });

      test('should handle state machine with validation', () {
        // Setup: Create state machine with validation logic
        final stateMachine = ReactiveNotifier<String>(() => 'idle');
        final stateHistory = <String>[];
        var validTransitions = 0;
        var invalidTransitions = 0;

        // Valid state transitions: idle -> loading -> success/error -> idle
        final validStates = {
          'idle': ['loading'],
          'loading': ['success', 'error'],
          'success': ['idle'],
          'error': ['idle']
        };

        stateMachine.addListener(() {
          stateHistory.add(stateMachine.notifier);
        });

        // Helper function to validate and update state
        void validateAndUpdate(String newState) {
          final currentState = stateMachine.notifier;
          if (validStates[currentState]?.contains(newState) == true) {
            stateMachine.updateState(newState);
            validTransitions++;
          } else {
            invalidTransitions++;
          }
        }

        // Act: Perform valid state transitions
        validateAndUpdate('loading'); // idle -> loading (valid)
        validateAndUpdate('success'); // loading -> success (valid)
        validateAndUpdate('idle'); // success -> idle (valid)
        validateAndUpdate('error'); // idle -> error (invalid)
        validateAndUpdate('loading'); // idle -> loading (valid)
        validateAndUpdate('error'); // loading -> error (valid)

        // Assert: Valid transitions should be executed, invalid ones rejected
        expect(validTransitions, 5,
            reason: 'Valid transitions should be counted');
        expect(invalidTransitions, 1,
            reason: 'Invalid transitions should be rejected');
        expect(stateHistory, ['loading', 'success', 'idle', 'loading', 'error'],
            reason: 'Only valid state transitions should be in history');
        expect(stateMachine.notifier, 'error',
            reason: 'Final state should be from last valid transition');
      });

      test('should track state lifecycle with timestamps', () {
        // Setup: Create state tracker with timestamps
        final lifecycleState = ReactiveNotifier<String>(() => 'created');
        final stateLifecycle = <Map<String, dynamic>>[];

        lifecycleState.addListener(() {
          stateLifecycle.add({
            'state': lifecycleState.notifier,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        });

        // Act: Perform lifecycle transitions with delays
        lifecycleState.updateState('initialized');
        lifecycleState.updateState('active');
        lifecycleState.updateState('suspended');
        lifecycleState.updateState('terminated');

        // Assert: All lifecycle states should be tracked with timestamps
        expect(stateLifecycle.length, 4,
            reason: 'All lifecycle transitions should be tracked');
        expect(stateLifecycle.map((e) => e['state']),
            ['initialized', 'active', 'suspended', 'terminated'],
            reason: 'Lifecycle states should be in correct order');

        // Assert: Timestamps should be in chronological order
        for (int i = 1; i < stateLifecycle.length; i++) {
          expect(stateLifecycle[i]['timestamp'] as int,
              greaterThanOrEqualTo(stateLifecycle[i - 1]['timestamp'] as int),
              reason: 'Timestamps should be in chronological order');
        }
      });
    });

    group('State History and Undo Operations', () {
      test('should maintain comprehensive state history', () {
        // Setup: Create ReactiveNotifier with history tracking
        final historicalState = ReactiveNotifier<int>(() => 0);
        final history = <int>[];

        historicalState
            .addListener(() => history.add(historicalState.notifier));

        // Act: Perform multiple state updates
        historicalState.updateState(1);
        historicalState.updateState(2);
        historicalState.updateState(3);

        // Assert: Complete history should be maintained
        expect(history, [1, 2, 3],
            reason: 'Complete state history should be maintained');
        expect(historicalState.notifier, 3,
            reason: 'Current state should be the latest');
      });

      test('should support undo operations with history navigation', () {
        // Setup: Create undo-capable state manager
        final undoableState = ReactiveNotifier<int>(() => 0);
        final history = <int>[0]; // Include initial state

        undoableState.addListener(() => history.add(undoableState.notifier));

        // Act: Perform operations that can be undone
        undoableState.updateState(1);
        undoableState.updateState(2);

        // Perform undo operation (go back to previous state)
        final previousState = history[history.length - 2];
        undoableState.updateState(previousState);

        // Assert: Undo should restore previous state
        expect(undoableState.notifier, 1,
            reason: 'Undo should restore previous state');
        expect(history, [0, 1, 2, 1],
            reason: 'Undo operation should be recorded in history');
      });

      test('should handle complex undo/redo operations', () {
        // Setup: Create sophisticated undo/redo system
        final editorState = ReactiveNotifier<String>(() => 'initial');
        final undoStack = <String>['initial'];
        final redoStack = <String>[];
        var isUndoRedoOperation = false;

        editorState.addListener(() {
          if (!isUndoRedoOperation) {
            // Only add to undo stack if it's not an undo/redo operation
            undoStack.add(editorState.notifier);
            redoStack.clear(); // Clear redo stack on new operation
          }
        });

        // Helper functions
        void performEdit(String newText) {
          isUndoRedoOperation = false;
          editorState.updateState(newText);
        }

        void undo() {
          if (undoStack.length > 1) {
            isUndoRedoOperation = true;
            final currentState = undoStack.removeLast();
            redoStack.add(currentState);
            editorState.updateState(undoStack.last);
            isUndoRedoOperation = false;
          }
        }

        void redo() {
          if (redoStack.isNotEmpty) {
            isUndoRedoOperation = true;
            final nextState = redoStack.removeLast();
            undoStack.add(nextState);
            editorState.updateState(nextState);
            isUndoRedoOperation = false;
          }
        }

        // Act: Perform editing operations
        performEdit('edit1');
        performEdit('edit2');
        performEdit('edit3');

        // Assert: All edits should be in undo stack
        expect(editorState.notifier, 'edit3',
            reason: 'Current state should be latest edit');
        expect(undoStack, ['initial', 'edit1', 'edit2', 'edit3'],
            reason: 'Undo stack should contain all edits');

        // Act: Perform undo operations
        undo(); // Back to edit2
        undo(); // Back to edit1

        // Assert: Undo should work correctly
        expect(editorState.notifier, 'edit1',
            reason: 'Undo should restore previous state');
        expect(redoStack, ['edit3', 'edit2'],
            reason: 'Redo stack should contain undone operations');

        // Act: Perform redo operation
        redo(); // Forward to edit2

        // Assert: Redo should work correctly
        expect(editorState.notifier, 'edit2',
            reason: 'Redo should restore next state');
        expect(redoStack, ['edit3'], reason: 'Redo stack should be updated');

        // Act: Perform new edit after undo/redo
        performEdit('newEdit');

        // Assert: New edit should clear redo stack
        expect(editorState.notifier, 'newEdit',
            reason: 'New edit should be current state');
        expect(redoStack.isEmpty, true,
            reason: 'New edit should clear redo stack');
        expect(undoStack.last, 'newEdit',
            reason: 'New edit should be added to undo stack');
      });
    });
  });
}

/// Custom test class for advanced state management testing
class CustomObject {
  final int id;
  final String name;

  CustomObject(this.id, this.name);

  @override
  String toString() => 'CustomObject(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomObject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
