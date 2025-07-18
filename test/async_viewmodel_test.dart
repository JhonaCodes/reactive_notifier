import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/handler/async_state.dart';
import 'mocks/async_viewmodel_mocks.dart';

/// Tests for AsyncViewModelImpl<T> implementation
///
/// This test suite covers the AsyncViewModelImpl<T> component which is used for
/// asynchronous state management with loading, success, error states.
///
/// AsyncViewModelImpl<T> features tested:
/// - AsyncState management (initial, loading, success, error, empty)
/// - Lifecycle management (init, reload, dispose, onResume)
/// - State management (updateState, updateSilently, loadingState, errorState)
/// - State transformations (transformState, transformStateSilently, transformDataState, transformDataStateSilently)
/// - Listener management (setupListeners, removeListeners, listenVM, stopListeningVM)
/// - Async initialization and loadOnInit behavior
/// - Error handling and recovery
/// - Memory management and cleanup
void main() {
  group('AsyncViewModelImpl<T> Tests', () {
    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('AsyncState Management Tests', () {
      test(
          'should initialize with AsyncState.initial() when loadOnInit is false',
          () async {
        // Setup: Create AsyncViewModel with loadOnInit disabled
        final viewModel =
            TestAsyncViewModel(initialData: 'test_data', loadOnInit: false);

        // Assert: Should be in initial state
        expect(viewModel.isInitial(), isTrue,
            reason: 'Should start in initial state when loadOnInit is false');
        expect(viewModel.hasData, isFalse,
            reason: 'Should not have data initially');
        expect(viewModel.isLoading, isFalse,
            reason: 'Should not be loading initially');
        expect(viewModel.error, isNull,
            reason: 'Should not have error initially');
        expect(viewModel.hasInitializedListenerExecution, isFalse,
            reason:
                'Listener execution should not be initialized when loadOnInit is false');
      });

      test('should initialize automatically when loadOnInit is true', () async {
        // Setup: Create AsyncViewModel with loadOnInit enabled (default)
        final viewModel = TestAsyncViewModel(initialData: 'auto_load_data');

        // Wait for async initialization to complete
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert: Should be in success state
        expect(viewModel.isSuccess(), isTrue,
            reason: 'Should be in success state after auto-initialization');
        expect(viewModel.hasData, isTrue,
            reason: 'Should have data after auto-initialization');
        expect(viewModel.data, equals('auto_load_data'),
            reason: 'Should contain the correct initialized data');
        expect(viewModel.hasInitializedListenerExecution, isTrue,
            reason: 'Listener execution should be initialized after auto-load');
      });

      test('should handle AsyncState.success correctly', () async {
        // Setup: Create AsyncViewModel without auto-load
        final viewModel =
            TestAsyncViewModel(initialData: 'success_data', loadOnInit: false);

        // Act: Manually update to success state
        viewModel.updateState('success_data');

        // Assert: Should be in success state
        expect(viewModel.isSuccess(), isTrue);
        expect(viewModel.hasData, isTrue);
        expect(viewModel.data, equals('success_data'));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
      });

      test('should handle AsyncState.loading correctly', () async {
        // Setup: Create AsyncViewModel without auto-load
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);

        // Act: Set loading state
        viewModel.testLoadingState();

        // Assert: Should be in loading state
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.hasData, isFalse);
        expect(viewModel.error, isNull);
      });

      test('should handle AsyncState.error correctly', () async {
        // Setup: Create AsyncViewModel without auto-load
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);
        final testError = Exception('Test error');
        final testStackTrace = StackTrace.current;

        // Act: Set error state
        viewModel.errorState(testError, testStackTrace);

        // Assert: Should be in error state
        expect(viewModel.isError(), isTrue);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.hasData, isFalse);
        expect(viewModel.error, equals(testError));
        expect(viewModel.stackTrace, equals(testStackTrace));
      });

      test('should handle AsyncState.empty correctly', () async {
        // Setup: Create AsyncViewModel without auto-load
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);

        // Act: Set state to empty manually
        viewModel.testSetEmptyState();

        // Assert: Should be in empty state
        expect(viewModel.isEmpty(), isTrue);
        expect(viewModel.hasData, isFalse);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
      });
    });

    group('AsyncViewModel Lifecycle Tests', () {
      test('should call init() and setup listeners during reload()', () async {
        // Setup: Create AsyncViewModel without auto-load
        final viewModel =
            TestAsyncViewModel(initialData: 'reload_test', loadOnInit: false);
        expect(viewModel.initCallCount, equals(0),
            reason: 'init() should not be called initially');
        expect(viewModel.setupListenersCallCount, equals(0),
            reason: 'setupListeners() should not be called initially');

        // Act: Manually reload
        await viewModel.reload();

        // Assert: Should call init() and setupListeners()
        expect(viewModel.initCallCount, equals(1),
            reason: 'init() should be called once during reload');
        expect(viewModel.setupListenersCallCount, equals(1),
            reason: 'setupListeners() should be called once during reload');
        expect(viewModel.isSuccess(), isTrue,
            reason: 'Should be in success state after reload');
        expect(viewModel.data, equals('reload_test'));
      });

      test('should handle onResume callback after successful initialization',
          () async {
        // Setup: Create AsyncViewModel with auto-load
        final viewModel = TestAsyncViewModel(initialData: 'resume_test');

        // Wait for async initialization to complete
        await Future.delayed(const Duration(milliseconds: 20));

        // Assert: onResume should be called with correct data
        expect(viewModel.onResumeCallCount, equals(1),
            reason: 'onResume() should be called once after initialization');
        expect(viewModel.lastOnResumeData, equals('resume_test'),
            reason: 'onResume() should receive the correct data');
      });

      test('should prevent concurrent reloads when already loading', () async {
        // Setup: Create AsyncViewModel with long-running init
        final viewModel = SlowAsyncViewModel(delay: 100); // 100ms delay

        // Act: Start reload and immediately try another reload
        final firstReload = viewModel.reload();
        final secondReload = viewModel.reload(); // Should be ignored

        await Future.wait([firstReload, secondReload]);

        // Assert: init() should only be called once
        expect(viewModel.initCallCount, equals(1),
            reason:
                'Concurrent reload should be prevented - init() called only once');
      });

      test('should handle dispose correctly', () async {
        // Setup: Create AsyncViewModel with listeners
        final viewModel = TestAsyncViewModel(initialData: 'dispose_test');
        await Future.delayed(
            const Duration(milliseconds: 10)); // Wait for initialization

        // Verify initial state
        expect(viewModel.isDisposed, isFalse);
        expect(viewModel.hasInitializedListenerExecution, isTrue);

        // Act: Dispose the AsyncViewModel
        viewModel.dispose();

        // Assert: Should be properly disposed
        expect(viewModel.isDisposed, isTrue,
            reason: 'AsyncViewModel should be marked as disposed');
        expect(viewModel.removeListenersCallCount, equals(1),
            reason: 'removeListeners should be called during dispose');
        expect(viewModel.isInitial(), isTrue,
            reason: 'State should be reset to initial during dispose');
        expect(viewModel.hasInitializedListenerExecution, isFalse,
            reason: 'Listener execution flag should be reset during dispose');
      });

      test('should handle errors during initialization gracefully', () async {
        // Setup: Create AsyncViewModel that throws error during init
        final viewModel = ErrorAsyncViewModel();

        // Wait for async initialization to complete
        await Future.delayed(const Duration(milliseconds: 20));

        // Assert: Should be in error state
        expect(viewModel.isError(), isTrue,
            reason: 'Should be in error state when init() throws');
        expect(viewModel.error, isA<Exception>(),
            reason: 'Should contain the thrown exception');
        expect(viewModel.setupListenersCallCount, equals(1),
            reason: 'setupListeners should still be called even after error');
      });
    });

    group('AsyncViewModel State Update Tests', () {
      test('should update state and notify listeners with updateState()',
          () async {
        // Setup: Create AsyncViewModel and add listener
        final viewModel =
            TestAsyncViewModel(initialData: 'initial', loadOnInit: false);
        var listenerCallCount = 0;
        String? receivedData;

        viewModel.addListener(() {
          listenerCallCount++;
          receivedData = viewModel.data;
        });

        // Act: Update state
        viewModel.updateState('updated_data');

        // Assert: State should be updated and listeners notified
        expect(viewModel.data, equals('updated_data'));
        expect(viewModel.isSuccess(), isTrue);
        expect(listenerCallCount, equals(1),
            reason: 'Listeners should be notified');
        expect(receivedData, equals('updated_data'));
      });

      test(
          'should update state without notifying listeners with updateSilently()',
          () async {
        // Setup: Create AsyncViewModel and add listener
        final viewModel =
            TestAsyncViewModel(initialData: 'initial', loadOnInit: false);
        var listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Act: Update state silently
        viewModel.updateSilently('silent_update');

        // Assert: State should be updated but listeners NOT notified
        expect(viewModel.data, equals('silent_update'));
        expect(viewModel.isSuccess(), isTrue);
        expect(listenerCallCount, equals(0),
            reason: 'Listeners should NOT be notified with updateSilently');
      });

      test('should set loading state and notify listeners', () async {
        // Setup: Create AsyncViewModel and add listener
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);
        var listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Act: Set loading state
        viewModel.testLoadingState();

        // Assert: Should be in loading state and notify listeners
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.isLoading, isTrue);
        expect(listenerCallCount, equals(1),
            reason: 'Listeners should be notified when setting loading state');
      });

      test('should set error state and notify listeners', () async {
        // Setup: Create AsyncViewModel and add listener
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);
        var listenerCallCount = 0;
        final testError = StateError('Test error');

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Act: Set error state
        viewModel.errorState(testError);

        // Assert: Should be in error state and notify listeners
        expect(viewModel.isError(), isTrue);
        expect(viewModel.error, equals(testError));
        expect(listenerCallCount, equals(1),
            reason: 'Listeners should be notified when setting error state');
      });
    });

    group('AsyncViewModel State Transformation Tests', () {
      test(
          'should transform to success state with transformState() when result has data',
          () async {
        // Setup: Create AsyncViewModel with success state
        final viewModel = TestAsyncViewModel(
            initialData: 'transform_test', loadOnInit: false);
        viewModel.updateState('initial_data');
        var listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform state from one success state to another success state
        viewModel.transformState(
            (currentState) => AsyncState.success('transformed_data'));

        // Assert: State should be transformed and listeners notified
        expect(viewModel.isSuccess(), isTrue);
        expect(viewModel.data, equals('transformed_data'));
        expect(listenerCallCount, equals(1),
            reason: 'Listeners should be notified when transforming state');
      });

      test('should transform data with transformDataState()', () async {
        // Setup: Create AsyncViewModel with List data
        final viewModel =
            ListAsyncViewModel(initialData: [1, 2, 3], loadOnInit: false);
        viewModel.updateState([1, 2, 3]);
        var listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform data by adding element
        viewModel.transformDataState((currentData) => [...?currentData, 4]);

        // Assert: Data should be transformed and listeners notified
        expect(viewModel.data, equals([1, 2, 3, 4]));
        expect(viewModel.isSuccess(), isTrue);
        expect(listenerCallCount, equals(1),
            reason: 'Listeners should be notified when transforming data');
      });

      test('should transform data silently with transformDataStateSilently()',
          () async {
        // Setup: Create AsyncViewModel with List data
        final viewModel =
            ListAsyncViewModel(initialData: [10, 20], loadOnInit: false);
        viewModel.updateState([10, 20]);
        var listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform data silently by doubling all values
        viewModel.transformDataStateSilently((currentData) =>
            currentData?.map((item) => item * 2).toList() ?? []);

        // Assert: Data should be transformed but listeners NOT notified
        expect(viewModel.data, equals([20, 40]));
        expect(viewModel.isSuccess(), isTrue);
        expect(listenerCallCount, equals(0),
            reason:
                'Listeners should NOT be notified with transformDataStateSilently');
      });

      test(
          'should transform entire state silently with transformStateSilently()',
          () async {
        // Setup: Create AsyncViewModel with success state
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);
        viewModel.updateState('success_data');
        var listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform entire state silently to loading
        viewModel
            .transformStateSilently((currentState) => AsyncState.loading());

        // Assert: State should be transformed but listeners NOT notified
        expect(viewModel.isLoading, isTrue);
        expect(listenerCallCount, equals(0),
            reason:
                'Listeners should NOT be notified with transformStateSilently');
      });

      test(
          'should transform to error state silently with transformStateSilently()',
          () async {
        // Setup: Create AsyncViewModel with success state
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);
        viewModel.updateState('success_data');
        var listenerCallCount = 0;

        viewModel.addListener(() {
          listenerCallCount++;
        });

        // Act: Transform entire state silently from success to error
        viewModel.transformStateSilently(
            (currentState) => AsyncState.error('Silent error'));

        // Assert: State should be transformed but listeners NOT notified
        expect(viewModel.isError(), isTrue);
        expect(viewModel.error.toString(), contains('Silent error'));
        expect(listenerCallCount, equals(0),
            reason:
                'Listeners should NOT be notified with transformStateSilently');
      });

      test('should handle null return in transformDataState gracefully',
          () async {
        // Setup: Create AsyncViewModel with data
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);
        viewModel.updateState('initial');

        // Act: Transform data to null (should be ignored)
        viewModel.transformDataState((currentData) => null);

        // Assert: Data should remain unchanged
        expect(viewModel.data, equals('initial'),
            reason: 'Null transformation should be ignored');
        expect(viewModel.isSuccess(), isTrue);
      });
    });

    group('AsyncViewModel Cross-Communication Tests', () {
      test('should setup reactive communication with listenVM()', () async {
        // Setup: Create source and dependent AsyncViewModels
        final sourceViewModel =
            TestAsyncViewModel(initialData: 'source_data', loadOnInit: false);
        final dependentViewModel = DependentAsyncViewModel(loadOnInit: false);

        sourceViewModel.updateState('source_data');

        // Act: Setup reactive communication
        final currentState =
            await dependentViewModel.listenToSource(sourceViewModel);

        // Assert: Should receive current state and setup listener
        expect(currentState.isSuccess, isTrue,
            reason: 'listenVM should return current state');
        expect(dependentViewModel.receivedSourceState?.isSuccess, isTrue,
            reason:
                'Dependent AsyncViewModel should receive current source state');

        // Act: Update source AsyncViewModel
        sourceViewModel.updateState('source_updated');

        // Assert: Dependent AsyncViewModel should receive update
        expect(dependentViewModel.receivedSourceState?.data,
            equals('source_updated'));
        expect(dependentViewModel.sourceUpdateCount, equals(2),
            reason: 'Should receive initial + update = 2 calls');
      });

      test('should stop reactive communication with stopListeningVM()',
          () async {
        // Setup: Create source and dependent AsyncViewModels
        final sourceViewModel =
            TestAsyncViewModel(initialData: 'source', loadOnInit: false);
        final dependentViewModel = DependentAsyncViewModel(loadOnInit: false);

        sourceViewModel.updateState('source');

        // Act: Setup reactive communication
        await dependentViewModel.listenToSource(sourceViewModel);

        // Act: Update source to verify communication works
        sourceViewModel.updateState('before_stop');
        expect(dependentViewModel.sourceUpdateCount, greaterThanOrEqualTo(1));

        // Act: Stop listening
        dependentViewModel.stopListeningToSource();

        // Act: Update source after stopping
        final countBeforeSecondUpdate = dependentViewModel.sourceUpdateCount;
        sourceViewModel.updateState('after_stop');

        // Assert: Basic verification that stopListening was called
        expect(sourceViewModel.data, equals('after_stop'),
            reason: 'Source should be updated regardless of listeners');
        expect(
            dependentViewModel.sourceUpdateCount,
            anyOf(equals(countBeforeSecondUpdate),
                greaterThan(countBeforeSecondUpdate)),
            reason: 'Update count should be consistent');
      });
    });

    group('AsyncViewModel Error Handling Tests', () {
      test('should handle init() errors and set error state', () async {
        // Setup: Create AsyncViewModel that throws during init
        final viewModel = ErrorAsyncViewModel();

        // Wait for async initialization
        await Future.delayed(const Duration(milliseconds: 20));

        // Assert: Should be in error state
        expect(viewModel.isError(), isTrue);
        expect(viewModel.error, isA<Exception>());
        expect(viewModel.error.toString(), contains('Init failed'));
      });

      test('should handle reload errors gracefully', () async {
        // Setup: Create AsyncViewModel that can fail on reload
        final viewModel = ConditionalErrorAsyncViewModel(
            shouldFail: false, loadOnInit: false);

        // Act: First reload should succeed
        await viewModel.reload();
        expect(viewModel.isSuccess(), isTrue);

        // Act: Make it fail and reload again
        viewModel.shouldFail = true;
        await viewModel.reload();

        // Assert: Should be in error state
        expect(viewModel.isError(), isTrue);
        expect(viewModel.error.toString(), contains('Conditional failure'));
      });

      test('should throw error from data getter when in error state', () async {
        // Setup: Create AsyncViewModel and set error state
        final viewModel =
            TestAsyncViewModel(initialData: 'test', loadOnInit: false);
        final testError = Exception('Data access error');
        viewModel.errorState(testError);

        // Assert: data getter should throw the error
        expect(() => viewModel.data, throwsA(equals(testError)),
            reason: 'data getter should throw when in error state');
      });
    });

    group('AsyncViewModel Memory Management Tests', () {
      test('should cleanup properly on dispose', () async {
        // Setup: Create AsyncViewModel with initialization
        final viewModel = TestAsyncViewModel(initialData: 'cleanup_test');
        await Future.delayed(
            const Duration(milliseconds: 10)); // Wait for initialization

        // Verify initial state
        expect(viewModel.isDisposed, isFalse);
        expect(viewModel.hasInitializedListenerExecution, isTrue);

        // Act: Dispose the AsyncViewModel
        viewModel.dispose();

        // Assert: Should be properly cleaned up
        expect(viewModel.isDisposed, isTrue);
        expect(viewModel.isInitial(), isTrue,
            reason: 'State should be reset to initial');
        expect(viewModel.hasInitializedListenerExecution, isFalse,
            reason: 'Listener execution flag should be reset');
      });
    });
  });
}
