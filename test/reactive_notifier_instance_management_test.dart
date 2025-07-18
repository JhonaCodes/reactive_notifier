import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Tests for ReactiveNotifier instance management
/// 
/// This test suite covers the instance management capabilities of ReactiveNotifier:
/// - Creating multiple instances of the same type
/// - Creating instances of different types  
/// - Instance counting and tracking by type
/// - Cleanup functionality for memory management
/// - Global instance registry management
/// 
/// These tests verify that ReactiveNotifier properly manages its internal 
/// instance registry for debugging, monitoring, and memory cleanup purposes.
void main() {
  group('ReactiveNotifier Instance Management', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Instance Creation and Counting Tests', () {
      test('should create multiple instances of the same type and track them correctly', () {
        // Setup: Create multiple ReactiveNotifier instances of the same type
        final state1 = ReactiveNotifier<int>(() => 0);
        final state2 = ReactiveNotifier<int>(() => 1);
        final state3 = ReactiveNotifier<int>(() => 2);

        // Assert: Total instance count should reflect all created instances
        expect(ReactiveNotifier.instanceCount, 3, 
            reason: 'Total instance count should track all created notifiers');
        
        // Assert: Type-specific count should match number of int instances
        expect(ReactiveNotifier.instanceCountByType<int>(), 3, 
            reason: 'Type-specific count should track instances of specific type');
        
        // Assert: Each instance should maintain its own value
        expect(state1.notifier, 0, reason: 'First instance should have its own value');
        expect(state2.notifier, 1, reason: 'Second instance should have its own value');
        expect(state3.notifier, 2, reason: 'Third instance should have its own value');
      });

      test('should create instances of different types and track them separately', () {
        // Setup: Create ReactiveNotifier instances of different types
        final intState = ReactiveNotifier<int>(() => 0);
        final stringState = ReactiveNotifier<String>(() => 'hello');
        final boolState = ReactiveNotifier<bool>(() => true);

        // Assert: Total instance count should include all types
        expect(ReactiveNotifier.instanceCount, 3, 
            reason: 'Total count should include all types of instances');
        
        // Assert: Each type should be counted separately
        expect(ReactiveNotifier.instanceCountByType<int>(), 1, 
            reason: 'Int type should have exactly one instance');
        expect(ReactiveNotifier.instanceCountByType<String>(), 1, 
            reason: 'String type should have exactly one instance');
        expect(ReactiveNotifier.instanceCountByType<bool>(), 1, 
            reason: 'Bool type should have exactly one instance');
        
        // Assert: Each instance should have correct type and value
        expect(intState.notifier, 0, reason: 'Int instance should have correct value');
        expect(stringState.notifier, 'hello', reason: 'String instance should have correct value');
        expect(boolState.notifier, true, reason: 'Bool instance should have correct value');
      });

      test('should handle complex generic types in instance tracking', () {
        // Setup: Create ReactiveNotifier instances with complex generic types
        final listState = ReactiveNotifier<List<String>>(() => ['a', 'b']);
        final mapState = ReactiveNotifier<Map<String, int>>(() => {'count': 1});
        final nestedState = ReactiveNotifier<List<Map<String, dynamic>>>(() => [{'id': 1}]);

        // Assert: Complex types should be tracked correctly
        expect(ReactiveNotifier.instanceCount, 3, 
            reason: 'Complex generic types should be counted');
        expect(ReactiveNotifier.instanceCountByType<List<String>>(), 1, 
            reason: 'List<String> type should be tracked separately');
        expect(ReactiveNotifier.instanceCountByType<Map<String, int>>(), 1, 
            reason: 'Map<String, int> type should be tracked separately');
        expect(ReactiveNotifier.instanceCountByType<List<Map<String, dynamic>>>(), 1, 
            reason: 'Nested generic type should be tracked separately');
      });

      test('should increment instance count with each new creation', () {
        // Assert: Start with zero instances
        expect(ReactiveNotifier.instanceCount, 0, reason: 'Should start with zero instances');

        // Act & Assert: Instance count should increment with each creation
        final state1 = ReactiveNotifier<int>(() => 1);
        expect(ReactiveNotifier.instanceCount, 1, reason: 'Count should be 1 after first creation');

        final state2 = ReactiveNotifier<String>(() => 'test');
        expect(ReactiveNotifier.instanceCount, 2, reason: 'Count should be 2 after second creation');

        final state3 = ReactiveNotifier<bool>(() => false);
        expect(ReactiveNotifier.instanceCount, 3, reason: 'Count should be 3 after third creation');

        // Verify instances are independent
        expect(state1.notifier, 1, reason: 'First instance should maintain its value');
        expect(state2.notifier, 'test', reason: 'Second instance should maintain its value');
        expect(state3.notifier, false, reason: 'Third instance should maintain its value');
      });
    });

    group('Cleanup and Memory Management Tests', () {
      test('should clean up all instances correctly with cleanup()', () {
        // Setup: Create multiple instances
        ReactiveNotifier<int>(() => 0);
        ReactiveNotifier<String>(() => 'hello');
        ReactiveNotifier<bool>(() => true);
        ReactiveNotifier<List<int>>(() => [1, 2, 3]);
        
        // Verify instances are created
        expect(ReactiveNotifier.instanceCount, 4, 
            reason: 'All instances should be tracked before cleanup');

        // Act: Perform cleanup
        ReactiveNotifier.cleanup();

        // Assert: All instances should be removed
        expect(ReactiveNotifier.instanceCount, 0, 
            reason: 'All instances should be removed after cleanup');
        
        // Assert: Type-specific counts should also be reset
        expect(ReactiveNotifier.instanceCountByType<int>(), 0, 
            reason: 'Int type count should be reset after cleanup');
        expect(ReactiveNotifier.instanceCountByType<String>(), 0, 
            reason: 'String type count should be reset after cleanup');
        expect(ReactiveNotifier.instanceCountByType<bool>(), 0, 
            reason: 'Bool type count should be reset after cleanup');
        expect(ReactiveNotifier.instanceCountByType<List<int>>(), 0, 
            reason: 'List type count should be reset after cleanup');
      });

      test('should allow new instance creation after cleanup', () {
        // Setup: Create instances, clean them up
        ReactiveNotifier<int>(() => 1);
        ReactiveNotifier<String>(() => 'test');
        expect(ReactiveNotifier.instanceCount, 2, reason: 'Initial instances should be tracked');
        
        ReactiveNotifier.cleanup();
        expect(ReactiveNotifier.instanceCount, 0, reason: 'Instances should be cleaned up');

        // Act: Create new instances after cleanup
        final newIntState = ReactiveNotifier<int>(() => 42);
        final newStringState = ReactiveNotifier<String>(() => 'new');

        // Assert: New instances should be tracked correctly
        expect(ReactiveNotifier.instanceCount, 2, 
            reason: 'New instances should be tracked after cleanup');
        expect(ReactiveNotifier.instanceCountByType<int>(), 1, 
            reason: 'New int instance should be tracked');
        expect(ReactiveNotifier.instanceCountByType<String>(), 1, 
            reason: 'New string instance should be tracked');
        
        // Assert: New instances should work correctly
        expect(newIntState.notifier, 42, reason: 'New int instance should work correctly');
        expect(newStringState.notifier, 'new', reason: 'New string instance should work correctly');
      });

      test('should handle multiple cleanup calls safely', () {
        // Setup: Create instances
        ReactiveNotifier<int>(() => 1);
        ReactiveNotifier<String>(() => 'test');
        expect(ReactiveNotifier.instanceCount, 2, reason: 'Instances should be created');

        // Act: Call cleanup multiple times
        ReactiveNotifier.cleanup();
        expect(ReactiveNotifier.instanceCount, 0, reason: 'First cleanup should work');
        
        ReactiveNotifier.cleanup();
        expect(ReactiveNotifier.instanceCount, 0, reason: 'Second cleanup should be safe');
        
        ReactiveNotifier.cleanup();
        expect(ReactiveNotifier.instanceCount, 0, reason: 'Third cleanup should be safe');

        // Assert: Should still allow new creation after multiple cleanups
        final newState = ReactiveNotifier<bool>(() => true);
        expect(ReactiveNotifier.instanceCount, 1, 
            reason: 'New instance creation should work after multiple cleanups');
        expect(newState.notifier, true, reason: 'New instance should function correctly');
      });

      test('should maintain accurate counts during mixed operations', () {
        // Act & Assert: Test mixed creation and cleanup operations
        
        // Create some instances
        final state1 = ReactiveNotifier<int>(() => 1);
        final state2 = ReactiveNotifier<String>(() => 'test');
        expect(ReactiveNotifier.instanceCount, 2, reason: 'Two instances should be tracked');

        // Create more instances
        final state3 = ReactiveNotifier<bool>(() => false);
        expect(ReactiveNotifier.instanceCount, 3, reason: 'Three instances should be tracked');

        // Cleanup and verify
        ReactiveNotifier.cleanup();
        expect(ReactiveNotifier.instanceCount, 0, reason: 'All instances should be cleaned');

        // Create new instances
        final newState1 = ReactiveNotifier<double>(() => 3.14);
        final newState2 = ReactiveNotifier<List<int>>(() => [1, 2]);
        expect(ReactiveNotifier.instanceCount, 2, reason: 'New instances should be tracked');

        // Verify functionality is preserved
        expect(newState1.notifier, 3.14, reason: 'New double instance should work');
        expect(newState2.notifier, [1, 2], reason: 'New list instance should work');
      });
    });

    group('Type-Specific Instance Tracking Tests', () {
      test('should track instances by type independently', () {
        // Setup: Create instances of various types in different quantities
        
        // Create 3 int instances
        ReactiveNotifier<int>(() => 1);
        ReactiveNotifier<int>(() => 2);
        ReactiveNotifier<int>(() => 3);
        
        // Create 2 string instances  
        ReactiveNotifier<String>(() => 'a');
        ReactiveNotifier<String>(() => 'b');
        
        // Create 1 bool instance
        ReactiveNotifier<bool>(() => true);

        // Assert: Total count should be sum of all instances
        expect(ReactiveNotifier.instanceCount, 6, 
            reason: 'Total count should be sum of all type instances');
        
        // Assert: Each type should be counted independently
        expect(ReactiveNotifier.instanceCountByType<int>(), 3, 
            reason: 'Int type should have 3 instances');
        expect(ReactiveNotifier.instanceCountByType<String>(), 2, 
            reason: 'String type should have 2 instances');
        expect(ReactiveNotifier.instanceCountByType<bool>(), 1, 
            reason: 'Bool type should have 1 instance');
        
        // Assert: Non-existent types should return 0
        expect(ReactiveNotifier.instanceCountByType<double>(), 0, 
            reason: 'Non-existent type should return 0 count');
        expect(ReactiveNotifier.instanceCountByType<List<int>>(), 0, 
            reason: 'Non-created type should return 0 count');
      });

      test('should handle identical generic types correctly', () {
        // Setup: Create instances with identical complex generic types
        ReactiveNotifier<List<String>>(() => ['a']);
        ReactiveNotifier<List<String>>(() => ['b']);
        ReactiveNotifier<List<String>>(() => ['c']);
        
        ReactiveNotifier<Map<String, int>>(() => {'x': 1});
        ReactiveNotifier<Map<String, int>>(() => {'y': 2});

        // Assert: Identical generic types should be grouped together
        expect(ReactiveNotifier.instanceCountByType<List<String>>(), 3, 
            reason: 'Identical List<String> types should be grouped');
        expect(ReactiveNotifier.instanceCountByType<Map<String, int>>(), 2, 
            reason: 'Identical Map<String, int> types should be grouped');
        
        // Assert: Similar but different types should be separate
        expect(ReactiveNotifier.instanceCountByType<List<int>>(), 0, 
            reason: 'Different generic parameter should be separate type');
        expect(ReactiveNotifier.instanceCountByType<Map<int, String>>(), 0, 
            reason: 'Different generic parameters should be separate type');
      });
    });
  });
}