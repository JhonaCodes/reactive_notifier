import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Tests for AsyncViewModelImpl transform methods
///
/// This comprehensive test suite covers the transform methods that are specific
/// to AsyncViewModelImpl:
/// - transformDataState() - transforms data within success state with notifications
/// - transformDataStateSilently() - transforms data within success state without notifications
/// - transformStateSilently() - transforms entire AsyncState without notifications
///
/// These tests ensure that the transform methods work correctly with different
/// state types and data transformations.

class TestAsyncViewModel extends AsyncViewModelImpl<List<String>> {
  TestAsyncViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<List<String>> init() async {
    return ['initial'];
  }

  // Expose transform methods for testing
  void testTransformDataState(
      List<String>? Function(List<String>? data) transformer) {
    transformDataState(transformer);
  }

  void testTransformDataStateSilently(
      List<String>? Function(List<String>? data) transformer) {
    transformDataStateSilently(transformer);
  }

  void testTransformStateSilently(
      AsyncState<List<String>> Function(AsyncState<List<String>> state)
          transformer) {
    transformStateSilently(transformer);
  }

  void testLoadingState() {
    loadingState();
  }
}

class TestIntAsyncViewModel extends AsyncViewModelImpl<int> {
  TestIntAsyncViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<int> init() async {
    return 0;
  }

  void testTransformDataState(int? Function(int? data) transformer) {
    transformDataState(transformer);
  }

  void testTransformDataStateSilently(int? Function(int? data) transformer) {
    transformDataStateSilently(transformer);
  }

  void testTransformStateSilently(
      AsyncState<int> Function(AsyncState<int> state) transformer) {
    transformStateSilently(transformer);
  }
}

class TestNullableAsyncViewModel extends AsyncViewModelImpl<String?> {
  TestNullableAsyncViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<String?> init() async {
    return null;
  }

  void testTransformDataState(String? Function(String? data) transformer) {
    transformDataState(transformer);
  }

  void testTransformDataStateSilently(
      String? Function(String? data) transformer) {
    transformDataStateSilently(transformer);
  }

  void testTransformStateSilently(
      AsyncState<String?> Function(AsyncState<String?> state) transformer) {
    transformStateSilently(transformer);
  }
}

void main() {
  group('AsyncViewModelImpl Transform Methods Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('transformDataState Tests', () {
      test('should transform data within success state and notify listeners',
          () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        // Set up listener
        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple', 'banana']);
        listenerCalled = false; // Reset flag

        // Transform data
        viewModel.testTransformDataState((data) {
          return [...?data, 'cherry'];
        });

        // Verify transformation
        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['apple', 'banana', 'cherry']));
        expect(listenerCalled, isTrue);
      });

      test('should handle null data gracefully', () {
        final viewModel = TestNullableAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set success state with null data
        viewModel.updateState(null);
        listenerCalled = false;

        // Transform null data
        viewModel.testTransformDataState((data) {
          return data ?? 'default';
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals('default'));
        expect(listenerCalled, isTrue);
      });

      test('should ignore transformation when transformer returns null', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple']);
        listenerCalled = false;

        // Transform that returns null
        viewModel.testTransformDataState((data) {
          return null; // This should be ignored
        });

        // Verify state unchanged
        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['apple']));
        expect(listenerCalled, isFalse);
      });

      test('should work with different data types', () {
        final intViewModel = TestIntAsyncViewModel();
        bool listenerCalled = false;

        intViewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        intViewModel.updateState(5);
        listenerCalled = false;

        // Transform integer data
        intViewModel.testTransformDataState((data) {
          return (data ?? 0) + 10;
        });

        expect(intViewModel.hasData, isTrue);
        expect(intViewModel.data, equals(15));
        expect(listenerCalled, isTrue);
      });

      test('should handle complex transformations', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple', 'banana', 'cherry']);
        listenerCalled = false;

        // Complex transformation - filter and map
        viewModel.testTransformDataState((data) {
          return data
              ?.where((item) => item.length > 5)
              .map((item) => item.toUpperCase())
              .toList();
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['BANANA', 'CHERRY']));
        expect(listenerCalled, isTrue);
      });

      test('should work when called from non-success state', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set error state
        viewModel.errorState('Test error');
        listenerCalled = false;

        // Try to transform data (should handle null data)
        viewModel.testTransformDataState((data) {
          return data ?? ['default'];
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['default']));
        expect(listenerCalled, isTrue);
      });
    });

    group('transformDataStateSilently Tests', () {
      test(
          'should transform data within success state without notifying listeners',
          () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        // Set up listener
        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple', 'banana']);
        listenerCalled = false; // Reset flag

        // Transform data silently
        viewModel.testTransformDataStateSilently((data) {
          return [...?data, 'cherry'];
        });

        // Verify transformation
        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['apple', 'banana', 'cherry']));
        expect(listenerCalled, isFalse); // Should not have been called
      });

      test('should handle null data gracefully', () {
        final viewModel = TestNullableAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set success state with null data
        viewModel.updateState(null);
        listenerCalled = false;

        // Transform null data silently
        viewModel.testTransformDataStateSilently((data) {
          return data ?? 'default';
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals('default'));
        expect(listenerCalled, isFalse);
      });

      test('should ignore transformation when transformer returns null', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple']);
        listenerCalled = false;

        // Transform that returns null
        viewModel.testTransformDataStateSilently((data) {
          return null; // This should be ignored
        });

        // Verify state unchanged
        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['apple']));
        expect(listenerCalled, isFalse);
      });

      test('should work with multiple silent transformations', () {
        final intViewModel = TestIntAsyncViewModel();
        bool listenerCalled = false;

        intViewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        intViewModel.updateState(0);
        listenerCalled = false;

        // Multiple silent transformations
        intViewModel.testTransformDataStateSilently((data) => (data ?? 0) + 5);
        intViewModel.testTransformDataStateSilently((data) => (data ?? 0) * 2);
        intViewModel.testTransformDataStateSilently((data) => (data ?? 0) + 1);

        expect(intViewModel.hasData, isTrue);
        expect(intViewModel.data, equals(11)); // (0 + 5) * 2 + 1
        expect(listenerCalled, isFalse);
      });

      test('should handle complex transformations silently', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple', 'banana', 'cherry', 'date']);
        listenerCalled = false;

        // Complex transformation - sort and take first 2
        viewModel.testTransformDataStateSilently((data) {
          final sorted = [...?data]..sort();
          return sorted.take(2).toList();
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['apple', 'banana']));
        expect(listenerCalled, isFalse);
      });
    });

    group('transformStateSilently Tests', () {
      test('should transform entire AsyncState without notifying listeners',
          () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        // Set up listener
        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple', 'banana']);
        listenerCalled = false; // Reset flag

        // Transform entire state silently
        viewModel.testTransformStateSilently((state) {
          if (state.isSuccess && state.data != null) {
            return AsyncState.success([...state.data!, 'cherry']);
          }
          return state;
        });

        // Verify transformation
        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['apple', 'banana', 'cherry']));
        expect(listenerCalled, isFalse); // Should not have been called
      });

      test('should allow state transitions between different AsyncState types',
          () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple']);
        listenerCalled = false;

        // Transform success to error based on condition
        viewModel.testTransformStateSilently((state) {
          if (state.isSuccess && state.data != null && state.data!.length < 2) {
            return AsyncState.error('Not enough items');
          }
          return state;
        });

        expect(viewModel.error != null, isTrue);
        expect(viewModel.error, equals('Not enough items'));
        expect(listenerCalled, isFalse);
      });

      test('should handle loading state transformations', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set loading state
        viewModel.testLoadingState();
        listenerCalled = false;

        // Transform loading to error
        viewModel.testTransformStateSilently((state) {
          if (state.isLoading) {
            return AsyncState.error('Loading timeout');
          }
          return state;
        });

        expect(viewModel.error != null, isTrue);
        expect(viewModel.error, equals('Loading timeout'));
        expect(listenerCalled, isFalse);
      });

      test('should handle error state transformations', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set error state
        viewModel.errorState('Network error');
        listenerCalled = false;

        // Transform error to success with fallback data
        viewModel.testTransformStateSilently((state) {
          if (state.isError) {
            return AsyncState.success(['fallback']);
          }
          return state;
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['fallback']));
        expect(listenerCalled, isFalse);
      });

      test('should handle complex state logic', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple', 'banana']);
        listenerCalled = false;

        // Complex state transformation logic
        viewModel.testTransformStateSilently((state) {
          if (state.isSuccess && state.data != null) {
            final data = state.data!;
            if (data.length >= 2) {
              // If we have 2 or more items, add a bonus item
              return AsyncState.success([...data, 'bonus']);
            } else if (data.length == 1) {
              // If we have 1 item, transition to loading
              return AsyncState.loading();
            } else {
              // If empty, transition to error
              return AsyncState.error('No items found');
            }
          }
          return state;
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['apple', 'banana', 'bonus']));
        expect(listenerCalled, isFalse);
      });

      test('should maintain state when transformation returns same state', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set initial success state
        viewModel.updateState(['apple']);
        listenerCalled = false;

        // Transform that returns same state
        viewModel.testTransformStateSilently((state) {
          return state; // No change
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['apple']));
        expect(listenerCalled, isFalse);
      });

      test('should work with nullable data types', () {
        final viewModel = TestNullableAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Set success state with null data
        viewModel.updateState(null);
        listenerCalled = false;

        // Transform null data
        viewModel.testTransformStateSilently((state) {
          if (state.isSuccess && state.data == null) {
            return AsyncState.success('converted from null');
          }
          return state;
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals('converted from null'));
        expect(listenerCalled, isFalse);
      });

      test('should handle initial state transformations', () {
        final viewModel = TestAsyncViewModel();
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Transform initial state
        viewModel.testTransformStateSilently((state) {
          if (state.isInitial) {
            return AsyncState.success(['initialized']);
          }
          return state;
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['initialized']));
        expect(listenerCalled, isFalse);
      });
    });

    group('Integration Tests - Transform Methods Working Together', () {
      test('should combine silent and non-silent transformations correctly',
          () {
        final viewModel = TestAsyncViewModel();
        int listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Set initial success state
        viewModel.updateState(['start']);
        listenerCallCount = 0;

        // Silent transformation
        viewModel.testTransformDataStateSilently((data) {
          return [...?data, 'silent1'];
        });

        expect(viewModel.data, equals(['start', 'silent1']));
        expect(listenerCallCount, equals(0));

        // Another silent transformation
        viewModel.testTransformDataStateSilently((data) {
          return [...?data, 'silent2'];
        });

        expect(viewModel.data, equals(['start', 'silent1', 'silent2']));
        expect(listenerCallCount, equals(0));

        // Non-silent transformation
        viewModel.testTransformDataState((data) {
          return [...?data, 'notified'];
        });

        expect(viewModel.data,
            equals(['start', 'silent1', 'silent2', 'notified']));
        expect(listenerCallCount, equals(1));
      });

      test(
          'should handle transformStateSilently followed by transformDataState',
          () {
        final viewModel = TestAsyncViewModel();
        int listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Set initial error state
        viewModel.errorState('Initial error');
        listenerCallCount = 0;

        // Transform error to success silently
        viewModel.testTransformStateSilently((state) {
          if (state.isError) {
            return AsyncState.success(['recovered']);
          }
          return state;
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['recovered']));
        expect(listenerCallCount, equals(0));

        // Transform data with notification
        viewModel.testTransformDataState((data) {
          return [...?data, 'enhanced'];
        });

        expect(viewModel.data, equals(['recovered', 'enhanced']));
        expect(listenerCallCount, equals(1));
      });

      test('should handle edge cases with multiple transformation types', () {
        final viewModel = TestAsyncViewModel();
        int listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Start with loading state
        viewModel.testLoadingState();
        listenerCallCount = 0;

        // Transform loading to success silently
        viewModel.testTransformStateSilently((state) {
          if (state.isLoading) {
            return AsyncState.success(['loaded']);
          }
          return state;
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['loaded']));
        expect(listenerCallCount, equals(0));

        // Transform data silently
        viewModel.testTransformDataStateSilently((data) {
          return [...?data, 'processed'];
        });

        expect(viewModel.data, equals(['loaded', 'processed']));
        expect(listenerCallCount, equals(0));

        // Transform state to error based on data silently
        viewModel.testTransformStateSilently((state) {
          if (state.isSuccess &&
              state.data != null &&
              state.data!.length >= 2) {
            return AsyncState.error('Too many items');
          }
          return state;
        });

        expect(viewModel.error != null, isTrue);
        expect(viewModel.error, equals('Too many items'));
        expect(listenerCallCount, equals(0));

        // Transform error back to success with notification
        viewModel.testTransformStateSilently((state) {
          if (state.isError) {
            return AsyncState.success(['reset']);
          }
          return state;
        });

        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals(['reset']));
        expect(listenerCallCount, equals(0));

        // Finally, transform data with notification
        viewModel.testTransformDataState((data) {
          return [...?data, 'final'];
        });

        expect(viewModel.data, equals(['reset', 'final']));
        expect(listenerCallCount, equals(1));
      });
    });
  });
}
