import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

// Test models
class TestModel {
  final int value;
  const TestModel(this.value);
  @override
  bool operator ==(Object other) => other is TestModel && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'TestModel($value)';
}

class TestViewModel extends ViewModel<TestModel> {
  TestViewModel() : super(const TestModel(0));
  
  @override
  void init() {
    // Simple initialization
  }
  
  void increment() {
    updateState(TestModel(data.value + 1));
  }
}

void main() {
  group('Widget-Aware Lifecycle Management', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });
    
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    test('should track reference count correctly', () {
      // Create a ReactiveNotifier with auto-dispose
      final notifier = ReactiveNotifier<TestViewModel>(
        () => TestViewModel(),
        autoDispose: true,
      );

      // Initially no references
      expect(notifier.referenceCount, equals(0));

      // Add a reference (simulating widget mounting)
      notifier.addReference('test_widget_1');
      expect(notifier.referenceCount, equals(1));

      // Add another reference
      notifier.addReference('test_widget_2');  
      expect(notifier.referenceCount, equals(2));

      // Remove a reference (simulating widget disposal)
      notifier.removeReference('test_widget_1');
      expect(notifier.referenceCount, equals(1));

      // Remove final reference
      notifier.removeReference('test_widget_2');
      expect(notifier.referenceCount, equals(0));
      expect(notifier.isScheduledForDispose, isTrue);
    });

    test('should not schedule dispose if auto-dispose is disabled', () {
      // Create a ReactiveNotifier without auto-dispose
      final notifier = ReactiveNotifier<TestViewModel>(
        () => TestViewModel(),
        autoDispose: false,
      );

      notifier.addReference('test_widget');
      notifier.removeReference('test_widget');
      
      expect(notifier.referenceCount, equals(0));
      expect(notifier.isScheduledForDispose, isFalse);
    });

    test('should cancel scheduled dispose when new reference is added', () {
      final notifier = ReactiveNotifier<TestViewModel>(
        () => TestViewModel(),
        autoDispose: true,
      );

      // Add and remove reference to schedule dispose
      notifier.addReference('test_widget');
      notifier.removeReference('test_widget');
      expect(notifier.isScheduledForDispose, isTrue);

      // Add new reference should cancel dispose
      notifier.addReference('new_widget');
      expect(notifier.isScheduledForDispose, isFalse);
      expect(notifier.referenceCount, equals(1));
    });

    test('reinitializeInstance should create fresh state', () {
      final key = UniqueKey();
      final notifier = ReactiveNotifier<TestViewModel>(
        () => TestViewModel(),
        key: key,
      );

      // Modify the state
      notifier.notifier.increment();
      expect(notifier.notifier.data.value, equals(1));

      // Reinitialize with fresh state
      final freshViewModel = ReactiveNotifier.reinitializeInstance<TestViewModel>(
        key,
        () => TestViewModel(),
      );

      // Should have fresh state
      expect(freshViewModel.data.value, equals(0));
      expect(notifier.notifier.data.value, equals(0));
    });

    test('isInstanceActive should return correct status', () {
      final key = UniqueKey();
      
      // No instance exists
      expect(ReactiveNotifier.isInstanceActive<TestViewModel>(key), isFalse);
      
      // Create instance
      final notifier = ReactiveNotifier<TestViewModel>(
        () => TestViewModel(),
        key: key,
      );
      
      expect(ReactiveNotifier.isInstanceActive<TestViewModel>(key), isTrue);
      
      // Dispose instance
      notifier.dispose();
      expect(ReactiveNotifier.isInstanceActive<TestViewModel>(key), isFalse);
    });

    test('enableAutoDispose should configure timeout', () {
      final notifier = ReactiveNotifier<TestViewModel>(
        () => TestViewModel(),
        autoDispose: true,
      );

      // Configure custom timeout
      notifier.enableAutoDispose(timeout: const Duration(minutes: 10));
      
      // Add and remove reference to trigger timer
      notifier.addReference('test_widget');
      notifier.removeReference('test_widget');
      
      expect(notifier.isScheduledForDispose, isTrue);
      // Timer should be set but not expired yet
      expect(notifier.referenceCount, equals(0));
    });

    test('should handle multiple reference additions and removals', () {
      final notifier = ReactiveNotifier<TestViewModel>(
        () => TestViewModel(),
        autoDispose: true,
      );

      // Add same reference multiple times (should only count once)
      notifier.addReference('same_widget');
      notifier.addReference('same_widget');
      expect(notifier.referenceCount, equals(1));

      // Add different references
      notifier.addReference('widget_1');
      notifier.addReference('widget_2'); 
      expect(notifier.referenceCount, equals(3));

      // Remove non-existent reference (should be safe)
      notifier.removeReference('non_existent');
      expect(notifier.referenceCount, equals(3));

      // Remove actual references
      notifier.removeReference('same_widget');
      notifier.removeReference('widget_1');
      expect(notifier.referenceCount, equals(1));
      expect(notifier.isScheduledForDispose, isFalse);

      // Remove final reference
      notifier.removeReference('widget_2');
      expect(notifier.referenceCount, equals(0));
      expect(notifier.isScheduledForDispose, isTrue);
    });

    test('activeReferences should return current references', () {
      final notifier = ReactiveNotifier<TestViewModel>(
        () => TestViewModel(),
        autoDispose: true,
      );

      expect(notifier.activeReferences.isEmpty, isTrue);

      notifier.addReference('widget_1');
      notifier.addReference('widget_2');
      
      final refs = notifier.activeReferences;
      expect(refs.length, equals(2));
      expect(refs.contains('widget_1'), isTrue);
      expect(refs.contains('widget_2'), isTrue);

      notifier.removeReference('widget_1');
      expect(notifier.activeReferences.length, equals(1));
      expect(notifier.activeReferences.contains('widget_2'), isTrue);
    });
  });
}