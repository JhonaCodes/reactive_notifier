import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

void main() {
  group('ReactiveNotifier Comprehensive Tests', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Basic Functionality', () {
      test('001 - should create instance with factory function', () {
        // Test: Verify ReactiveNotifier creates single instance using factory function, 
        // initializes with correct value, and maintains singleton behavior
        
        // Act: Create ReactiveNotifier with factory function
        final notifier1 = ReactiveNotifier<int>(() => 42);
        final notifier2 = ReactiveNotifier<int>(() => 42);
        
        // Assert: Should create separate instances (not singleton behavior)
        expect(notifier1.notifier, equals(42), 
            reason: 'First instance should return factory value');
        expect(notifier2.notifier, equals(42), 
            reason: 'Second instance should return factory value');
        expect(identical(notifier1, notifier2), isFalse, 
            reason: 'Different instances should be created without keys');
        expect(ReactiveNotifier.instanceCount, equals(2), 
            reason: 'Should track both instances');
        
        // Test singleton behavior with keys
        final key = UniqueKey();
        final singletonNotifier1 = ReactiveNotifier<int>(() => 99, key: key);
        
        // This should throw an error since key already exists
        expect(() => ReactiveNotifier<int>(() => 100, key: key), 
            throwsA(isA<StateError>()),
            reason: 'Should throw StateError when creating with existing key');
            
        // Verify factory function was called and value is correct
        expect(singletonNotifier1.notifier, equals(99), 
            reason: 'Singleton should use factory value from first creation');
      });
      
      test('002 - should return initial value from notifier getter', () {
        // Test: .notifier getter returns the exact initial value provided by factory function
        
        // Test with various types
        final intNotifier = ReactiveNotifier<int>(() => 123);
        final stringNotifier = ReactiveNotifier<String>(() => 'hello world');
        final listNotifier = ReactiveNotifier<List<int>>(() => [1, 2, 3]);
        final mapNotifier = ReactiveNotifier<Map<String, int>>(() => {'key': 456});
        final nullableNotifier = ReactiveNotifier<String?>(() => null);
        
        // Assert: Exact value returned without modifications
        expect(intNotifier.notifier, equals(123));
        expect(stringNotifier.notifier, equals('hello world'));
        expect(listNotifier.notifier, equals([1, 2, 3]));
        expect(mapNotifier.notifier, equals({'key': 456}));
        expect(nullableNotifier.notifier, isNull);
        
        // Test identity for complex objects
        final originalList = [1, 2, 3];
        final listNotifierIdentity = ReactiveNotifier<List<int>>(() => originalList);
        expect(identical(listNotifierIdentity.notifier, originalList), isTrue,
            reason: 'Should return exact same object reference');
      });
      
      test('003 - should notify listeners on state change', () {
        // Test: Verify listeners are called when updateState() changes value, 
        // with correct value passed to callback
        
        final notifier = ReactiveNotifier<int>(() => 0);
        final receivedValues = <int>[];
        var callCount = 0;
        
        // Add listener
        notifier.addListener(() {
          callCount++;
          receivedValues.add(notifier.notifier);
        });
        
        // Act: Update state multiple times
        notifier.updateState(10);
        notifier.updateState(20);
        notifier.updateState(30);
        
        // Assert: All updates triggered listeners with correct values
        expect(callCount, equals(3), reason: 'Listener should be called for each update');
        expect(receivedValues, equals([10, 20, 30]), 
            reason: 'Listener should receive correct values in order');
        expect(notifier.notifier, equals(30), 
            reason: 'Final state should be last updated value');
        
        // Test multiple listeners
        final secondReceivedValues = <int>[];
        notifier.addListener(() {
          secondReceivedValues.add(notifier.notifier);
        });
        
        notifier.updateState(40);
        
        expect(receivedValues, equals([10, 20, 30, 40]));
        expect(secondReceivedValues, equals([40]));
      });
      
      test('004 - should not notify on same value update', () {
        // Test: updateState() with identical value does not trigger listener notifications
        
        final notifier = ReactiveNotifier<int>(() => 42);
        var callCount = 0;
        final receivedValues = <int>[];
        
        notifier.addListener(() {
          callCount++;
          receivedValues.add(notifier.notifier);
        });
        
        // Act: Update with same value multiple times
        notifier.updateState(42);  // Same as initial
        notifier.updateState(42);  // Same again
        notifier.updateState(42);  // Same again
        
        // Assert: No notifications should be triggered
        expect(callCount, equals(0), 
            reason: 'Listener should not be called for identical values');
        expect(receivedValues, isEmpty, 
            reason: 'No values should be received for identical updates');
        expect(notifier.notifier, equals(42), 
            reason: 'Value should remain unchanged');
        
        // Test that different value still triggers notification
        notifier.updateState(43);
        expect(callCount, equals(1), 
            reason: 'Listener should be called when value actually changes');
        expect(receivedValues, equals([43]));
        
        // Test with complex objects (Lists with same content but different instances are different)
        final originalList = [1, 2, 3];
        final listNotifier = ReactiveNotifier<List<int>>(() => originalList);
        var listCallCount = 0;
        
        listNotifier.addListener(() {
          listCallCount++;
        });
        
        // Same content but different instance should trigger notification
        listNotifier.updateState([1, 2, 3]);  // Same content, different instance
        expect(listCallCount, equals(1), 
            reason: 'Should notify for lists with same content but different instance');
        
        // Same instance should not trigger notification
        listNotifier.updateState(listNotifier.notifier);  // Exact same instance
        expect(listCallCount, equals(1), 
            reason: 'Should not notify for same list instance');
        
        listNotifier.updateState([1, 2, 4]);  // Different content
        expect(listCallCount, equals(2), 
            reason: 'Should notify for lists with different content');
      });
    });
  });
}