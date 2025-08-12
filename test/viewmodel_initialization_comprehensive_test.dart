import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Comprehensive tests for ViewModel initialization with context feature
/// 
/// These tests ensure that:
/// 1. ViewModels ALWAYS initialize (like main branch)
/// 2. Context is optional feature that doesn't affect base initialization
/// 3. Reinitialize only happens when context becomes available and was needed
/// 4. No double initialization occurs
/// 5. State consistency is maintained

/// Test Models
class CounterState {
  final int count;
  final String source;
  final bool hasContextData;
  
  const CounterState({
    required this.count,
    required this.source,
    required this.hasContextData,
  });
  
  CounterState copyWith({
    int? count,
    String? source,
    bool? hasContextData,
  }) {
    return CounterState(
      count: count ?? this.count,
      source: source ?? this.source,
      hasContextData: hasContextData ?? this.hasContextData,
    );
  }
  
  static CounterState initial() => const CounterState(
    count: 0,
    source: 'initial',
    hasContextData: false,
  );
  
  static CounterState fromContext(BuildContext context) => CounterState(
    count: 100,
    source: 'context',
    hasContextData: true,
  );
}

class AsyncCounterState {
  final int count;
  final String source;
  final bool hasContextData;
  
  const AsyncCounterState({
    required this.count,
    required this.source,
    required this.hasContextData,
  });
  
  static AsyncCounterState initial() => const AsyncCounterState(
    count: 0,
    source: 'initial',
    hasContextData: false,
  );
  
  static AsyncCounterState fromContext(BuildContext context) => const AsyncCounterState(
    count: 200,
    source: 'async_context',
    hasContextData: true,
  );
}

/// Test ViewModels
class TestViewModel extends ViewModel<CounterState> {
  int initCallCount = 0;
  
  TestViewModel() : super(CounterState.initial());

  @override
  void init() {
    initCallCount++;
    
    if (hasContext) {
      // Use context to initialize with different data
      updateSilently(CounterState.fromContext(context!));
    } else {
      // Initialize without context
      updateSilently(CounterState.initial());
    }
  }

  @override
  CounterState _createEmptyState() => CounterState.initial();
}

class TestAsyncViewModel extends AsyncViewModelImpl<AsyncCounterState> {
  int initCallCount = 0;
  
  TestAsyncViewModel() : super(AsyncState.initial());

  @override
  Future<AsyncCounterState> init() async {
    initCallCount++;
    
    if (hasContext) {
      // Use context to initialize with different data
      final state = AsyncCounterState.fromContext(context!);
      updateSilently(state);
      return state;
    } else {
      // Initialize without context
      final state = AsyncCounterState.initial();
      updateSilently(state);
      return state;
    }
  }
}

/// Test Services
mixin TestViewModelService {
  static ReactiveNotifier<TestViewModel>? _instance;
  
  static ReactiveNotifier<TestViewModel> get instance {
    _instance ??= ReactiveNotifier<TestViewModel>(() => TestViewModel());
    return _instance!;
  }
  
  static ReactiveNotifier<TestViewModel> createNew() {
    _instance = ReactiveNotifier<TestViewModel>(() => TestViewModel());
    return _instance!;
  }
}

mixin TestAsyncViewModelService {
  static ReactiveNotifier<TestAsyncViewModel>? _instance;
  
  static ReactiveNotifier<TestAsyncViewModel> get instance {
    _instance ??= ReactiveNotifier<TestAsyncViewModel>(() => TestAsyncViewModel());
    return _instance!;
  }
  
  static ReactiveNotifier<TestAsyncViewModel> createNew() {
    _instance = ReactiveNotifier<TestAsyncViewModel>(() => TestAsyncViewModel());
    return _instance!;
  }
}

void main() {
  group('ViewModel Initialization - Context Feature Comprehensive Tests', () {
    setUp(() {
      // CRITICAL: Always cleanup before each test
      ReactiveNotifier.cleanup();
      
      // Create fresh instances to avoid cross-test contamination
      TestViewModelService.createNew();
      TestAsyncViewModelService.createNew();
    });

    group('Constructor Behavior - ALWAYS Initialize', () {
      test('ViewModel without context should execute init() and have data available', () {
        // Create ViewModel outside widget tree (no context)
        final vm = TestViewModel();
        
        // Should have executed init() once
        expect(vm.initCallCount, equals(1));
        
        // Should have data available
        expect(vm.data.source, equals('initial'));
        expect(vm.data.hasContextData, isFalse);
        expect(vm.hasInitializedListenerExecution, isTrue);
        
        // Should be marked as initialized without context
        expect(vm.hasContext, isFalse);
      });

      test('AsyncViewModel without context should execute init() and complete initialization', () async {
        // Create AsyncViewModel outside widget tree (no context)
        final vm = TestAsyncViewModel();
        
        // Wait for async initialization to complete successfully
        int attempts = 0;
        while (attempts < 50) {
          await Future.delayed(const Duration(milliseconds: 20));
          // Check if we have successfully completed initialization with data
          if (vm.hasInitializedListenerExecution && vm.data != null) {
            break;
          }
          attempts++;
        }
        
        // Should have executed init() once
        expect(vm.initCallCount, equals(1));
        
        // Should have completed initialization
        expect(vm.hasInitializedListenerExecution, isTrue);
        
        // State should be success state with data
        expect(vm.data, isNotNull);
        expect(vm.data!.source, equals('initial'));
        expect(vm.data!.hasContextData, isFalse);
        
        // Should be marked as initialized without context
        expect(vm.hasContext, isFalse);
        
        // Clean up
        vm.dispose();
      });

      testWidgets('ViewModel with context should execute init() and have data available', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveViewModelBuilder<TestViewModel, CounterState>(
              viewmodel: TestViewModelService.instance.notifier,
              build: (state, viewModel, keep) => Text('Count: ${state.count}'),
            ),
          ),
        );

        await tester.pump();
        
        final vm = TestViewModelService.instance.notifier;
        
        // Should have executed init()
        expect(vm.initCallCount, greaterThanOrEqualTo(1));
        
        // Should have context data
        expect(vm.data.source, equals('context'));
        expect(vm.data.hasContextData, isTrue);
        expect(vm.hasInitializedListenerExecution, isTrue);
        
        // Should have context
        expect(vm.hasContext, isTrue);
      });

      testWidgets('AsyncViewModel with context should execute init() and have state available', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveAsyncBuilder<TestAsyncViewModel, AsyncCounterState>(
              notifier: TestAsyncViewModelService.instance.notifier,
              onData: (state, viewModel, keep) => Text('Count: ${state.count}'),
              onLoading: () => const CircularProgressIndicator(),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        );

        // Wait for initialization with manual pumping
        await tester.pump();
        
        // Wait for async operations with timeout
        int attempts = 0;
        final vm = TestAsyncViewModelService.instance.notifier;
        while (attempts < 20) {
          await tester.pump(const Duration(milliseconds: 50));
          // Check if initialization completed with data
          if (vm.hasInitializedListenerExecution && vm.data != null) {
            break;
          }
          attempts++;
        }
        
        // Should have executed init()
        expect(vm.initCallCount, greaterThanOrEqualTo(1));
        
        // Should have data available
        expect(vm.data, isNotNull);
        
        // Should have context data
        expect(vm.data!.source, equals('async_context'));
        expect(vm.data!.hasContextData, isTrue);
        expect(vm.hasInitializedListenerExecution, isTrue);
        
        // Should have context
        expect(vm.hasContext, isTrue);
      });
    });

    group('Reinitialize with Context', () {
      testWidgets('ViewModel created without context → builder mounts → reinitializes once', (tester) async {
        // Create ViewModel without context first
        final vm = TestViewModel();
        expect(vm.initCallCount, equals(1));
        expect(vm.data.source, equals('initial'));
        expect(vm.hasContext, isFalse);
        
        // Now mount builder to provide context
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveViewModelBuilder<TestViewModel, CounterState>(
              viewmodel: vm,
              build: (state, viewModel, keep) => Text('Count: ${state.count}'),
            ),
          ),
        );

        await tester.pump();
        
        // Should have reinitalized with context
        expect(vm.initCallCount, equals(2)); // Initial + reinitialize
        expect(vm.data.source, equals('context'));
        expect(vm.data.hasContextData, isTrue);
        expect(vm.hasContext, isTrue);
      });

      testWidgets('ViewModel created with context → builder mounts → does NOT reinitialize', (tester) async {
        // Mount builder first to provide context
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveViewModelBuilder<TestViewModel, CounterState>(
              viewmodel: TestViewModelService.instance.notifier,
              build: (state, viewModel, keep) => Text('Count: ${state.count}'),
            ),
          ),
        );

        await tester.pump();
        
        final vm = TestViewModelService.instance.notifier;
        final initialCallCount = vm.initCallCount;
        
        // Rebuild widget
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveViewModelBuilder<TestViewModel, CounterState>(
              viewmodel: vm,
              build: (state, viewModel, keep) => Text('Updated: ${state.count}'),
            ),
          ),
        );

        await tester.pump();
        
        // Should NOT have reinitalized
        expect(vm.initCallCount, equals(initialCallCount));
        expect(vm.data.source, equals('context'));
      });

      testWidgets('AsyncViewModel created without context → builder mounts → reinitializes once', (tester) async {
        // Create AsyncViewModel without context first
        final vm = TestAsyncViewModel();
        
        // Wait for initial async init
        int attempts = 0;
        while (!vm.hasInitializedListenerExecution && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 10));
          attempts++;
        }
        
        expect(vm.initCallCount, equals(1));
        expect(vm.data!.source, equals('initial'));
        expect(vm.hasContext, isFalse);
        
        // Now mount builder to provide context
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveAsyncBuilder<TestAsyncViewModel, AsyncCounterState>(
              notifier: vm,
              onData: (state, viewModel, keep) => Text('Count: ${state.count}'),
              onLoading: () => const CircularProgressIndicator(),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        );

        // Wait for reinitialize
        await tester.pump();
        attempts = 0;
        while (attempts < 20) {
          await tester.pump(const Duration(milliseconds: 50));
          if (vm.data != null && vm.data!.source == 'async_context') {
            break;
          }
          attempts++;
        }
        
        // Should have reinitalized with context
        expect(vm.initCallCount, equals(2)); // Initial + reinitialize
        expect(vm.data!.source, equals('async_context'));
        expect(vm.data!.hasContextData, isTrue);
        expect(vm.hasContext, isTrue);
      });

      testWidgets('AsyncViewModel created with context → builder mounts → does NOT reinitialize', (tester) async {
        // Mount builder first to provide context
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveAsyncBuilder<TestAsyncViewModel, AsyncCounterState>(
              notifier: TestAsyncViewModelService.instance.notifier,
              onData: (state, viewModel, keep) => Text('Count: ${state.count}'),
              onLoading: () => const CircularProgressIndicator(),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        );

        // Wait for initialization
        await tester.pump();
        int attempts = 0;
        while (attempts < 20) {
          await tester.pump(const Duration(milliseconds: 50));
          final vm = TestAsyncViewModelService.instance.notifier;
          if (vm.data != null && vm.hasInitializedListenerExecution) {
            break;
          }
          attempts++;
        }
        
        final vm = TestAsyncViewModelService.instance.notifier;
        final initialCallCount = vm.initCallCount;
        
        // Rebuild widget
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveAsyncBuilder<TestAsyncViewModel, AsyncCounterState>(
              notifier: vm,
              onData: (state, viewModel, keep) => Text('Updated: ${state.count}'),
              onLoading: () => const CircularProgressIndicator(),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        );

        await tester.pump();
        
        // Should NOT have reinitalized
        expect(vm.initCallCount, equals(initialCallCount));
        expect(vm.data!.source, equals('async_context'));
      });
    });

    group('Edge Cases & Concurrency', () {
      testWidgets('Multiple calls to reinitializeWithContext() → only first time executes', (tester) async {
        // Create ViewModel without context
        final vm = TestViewModel();
        expect(vm.initCallCount, equals(1));
        
        // Mount builder to provide context
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveViewModelBuilder<TestViewModel, CounterState>(
              viewmodel: vm,
              build: (state, viewModel, keep) => Text('Count: ${state.count}'),
            ),
          ),
        );

        await tester.pump();
        expect(vm.initCallCount, equals(2)); // Initial + reinitialize
        
        // Call reinitializeWithContext manually multiple times
        vm.reinitializeWithContext();
        vm.reinitializeWithContext();
        vm.reinitializeWithContext();
        
        await tester.pump();
        
        // Should still be only 2 calls (no additional reinitializations)
        expect(vm.initCallCount, equals(2));
      });

      test('reinitializeWithContext() after dispose → does not execute', () {
        // Create ViewModel without context
        final vm = TestViewModel();
        expect(vm.initCallCount, equals(1));
        
        // Dispose it
        vm.dispose();
        expect(vm.isDisposed, isTrue);
        
        // Try to reinitialize (should do nothing)
        vm.reinitializeWithContext();
        
        // Should not have additional init calls
        expect(vm.initCallCount, equals(1));
      });

      testWidgets('Multiple builders concurrently → context handled correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [
                Expanded(
                  child: ReactiveViewModelBuilder<TestViewModel, CounterState>(
                    viewmodel: TestViewModelService.instance.notifier,
                    build: (state, viewModel, keep) => Text('Builder 1: ${state.count}'),
                  ),
                ),
                Expanded(
                  child: ReactiveViewModelBuilder<TestViewModel, CounterState>(
                    viewmodel: TestViewModelService.instance.notifier,
                    build: (state, viewModel, keep) => Text('Builder 2: ${state.count}'),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pump();
        
        final vm = TestViewModelService.instance.notifier;
        
        // Should have context
        expect(vm.hasContext, isTrue);
        expect(vm.data.source, equals('context'));
        
        // Should not have double initialized
        expect(vm.initCallCount, lessThanOrEqualTo(2));
      });

      testWidgets('Builder dismounts → context cleared but ViewModel continues functioning', (tester) async {
        // Mount builder
        await tester.pumpWidget(
          MaterialApp(
            home: ReactiveViewModelBuilder<TestViewModel, CounterState>(
              viewmodel: TestViewModelService.instance.notifier,
              build: (state, viewModel, keep) => Text('Count: ${state.count}'),
            ),
          ),
        );

        await tester.pump();
        
        final vm = TestViewModelService.instance.notifier;
        expect(vm.hasContext, isTrue);
        
        // Remove builder
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('No Builder')),
          ),
        );

        await tester.pump();
        
        // Context should be cleared but ViewModel should still work
        expect(vm.hasContext, isFalse);
        expect(vm.isDisposed, isFalse);
        
        // Should still be able to access data
        expect(vm.data.source, equals('context')); // Retains last state
      });
    });

    group('State Consistency', () {
      test('Flags are consistent throughout lifecycle', () {
        // Create without context
        final vm = TestViewModel();
        
        expect(vm.hasInitializedListenerExecution, isTrue); // Should be true after init
        expect(vm.hasContext, isFalse);
        expect(vm.isDisposed, isFalse);
      });

      test('data/state always accessible after constructor', () {
        // ViewModel
        final vm = TestViewModel();
        expect(() => vm.data, returnsNormally);
        expect(vm.data.source, equals('initial'));
        
        // AsyncViewModel
        final asyncVm = TestAsyncViewModel();
        expect(() => asyncVm.data, returnsNormally); // Should not throw
      });

      test('hasContext reflects actual system state', () {
        final vm = TestViewModel();
        
        // Initially no context
        expect(vm.hasContext, isFalse);
        
        // Context state should be consistent with ViewModelContextNotifier
        expect(vm.context, isNull);
      });

      test('isDisposed works correctly in all scenarios', () {
        final vm = TestViewModel();
        expect(vm.isDisposed, isFalse);
        
        vm.dispose();
        expect(vm.isDisposed, isTrue);
        
        // Should reinitialize when accessing data after dispose
        final dataAfterDispose = vm.data;
        expect(dataAfterDispose, isNotNull);
        expect(vm.isDisposed, isFalse); // Should be reinitalized
      });
    });

    group('Regression Prevention', () {
      test('Behavior identical to main branch when context not used', () {
        // Create ViewModels that don't use context
        final vm = TestViewModel();
        final asyncVm = TestAsyncViewModel();
        
        // Should have same initialization behavior as main
        expect(vm.initCallCount, equals(1));
        expect(vm.hasInitializedListenerExecution, isTrue);
        expect(vm.data, isNotNull);
        
        expect(asyncVm.initCallCount, equals(1));
        expect(asyncVm.hasInitializedListenerExecution, isTrue);
      });

      test('Context feature does not affect base functionality', () {
        // All ViewModels should work exactly like main branch
        final vm = TestViewModel();
        
        // Basic state operations should work
        vm.updateState(vm.data.copyWith(count: 42));
        expect(vm.data.count, equals(42));
        
        // Should be able to dispose normally
        expect(() => vm.dispose(), returnsNormally);
      });

      test('Performance not degraded by context feature', () {
        // Create many ViewModels quickly (performance test)
        final stopwatch = Stopwatch()..start();
        
        final viewModels = List.generate(100, (_) => TestViewModel());
        
        stopwatch.stop();
        
        // Should complete quickly (less than 100ms for 100 ViewModels)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        
        // All should be properly initialized
        for (final vm in viewModels) {
          expect(vm.initCallCount, equals(1));
          expect(vm.data, isNotNull);
        }
        
        // Cleanup
        for (final vm in viewModels) {
          vm.dispose();
        }
      });
    });
  });
}