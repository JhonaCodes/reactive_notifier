import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Tests for ReactiveAsyncBuilder widget
/// 
/// This comprehensive test suite covers the ReactiveAsyncBuilder widget functionality:
/// - Basic builder functionality with different AsyncState types
/// - Listener management and widget lifecycle
/// - State transition handling (initial → loading → success/error)
/// - Keep function for widget preservation across rebuilds
/// - Error handling and edge cases
/// - Integration with AsyncViewModelImpl
/// - Performance and memory management
/// - Widget updates when notifier changes
/// - Deprecated onSuccess callback compatibility
/// - Auto-dispose functionality
/// 
/// These tests ensure that ReactiveAsyncBuilder correctly handles all AsyncState
/// variations and provides proper widget lifecycle management with reactive updates.

void main() {
  group('ReactiveAsyncBuilder Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Basic Builder Functionality', () {
      testWidgets('should render onInitial widget when AsyncState is initial',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel with initial state
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onInitial: () => const Text('Initial State'),
              onLoading: () => const Text('Loading'),
              onData: (data, vm, keep) => Text('Success: $data'),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ));

        // Assert: Should show initial state
        expect(find.text('Initial State'), findsOneWidget);
        expect(find.text('Loading'), findsNothing);
        expect(find.text('Success: test'), findsNothing);
      });

      testWidgets('should render onLoading widget when AsyncState is loading',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel with loading state
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onInitial: () => const Text('Initial State'),
              onLoading: () => const Text('Loading'),
              onData: (data, vm, keep) => Text('Success: $data'),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ));

        // Act: Set loading state
        viewModel.loadingState();
        await tester.pump();

        // Assert: Should show loading state
        expect(find.text('Loading'), findsOneWidget);
        expect(find.text('Initial State'), findsNothing);
        expect(find.text('Success: test'), findsNothing);
      });

      testWidgets('should render onData widget when AsyncState is success',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel with success state
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onInitial: () => const Text('Initial State'),
              onLoading: () => const Text('Loading'),
              onData: (data, vm, keep) => Text('Success: $data'),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ));

        // Act: Set success state
        viewModel.updateState('test data');
        await tester.pump();

        // Assert: Should show success state
        expect(find.text('Success: test data'), findsOneWidget);
        expect(find.text('Initial State'), findsNothing);
        expect(find.text('Loading'), findsNothing);
      });

      testWidgets('should render onError widget when AsyncState is error',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel with error state
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onInitial: () => const Text('Initial State'),
              onLoading: () => const Text('Loading'),
              onData: (data, vm, keep) => Text('Success: $data'),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ));

        // Act: Set error state
        viewModel.errorState('Test error');
        await tester.pump();

        // Assert: Should show error state
        expect(find.text('Error: Test error'), findsOneWidget);
        expect(find.text('Initial State'), findsNothing);
        expect(find.text('Loading'), findsNothing);
      });

      testWidgets('should use default widgets when callbacks are not provided',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel without all callbacks
        final viewModel = TestAsyncViewModel();
        
        // Build widget with minimal callbacks
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) => Text('Success: $data'),
            ),
          ),
        ));

        // Assert: Should render default initial widget (SizedBox.shrink)
        expect(find.byType(SizedBox), findsOneWidget);

        // Act: Set loading state
        viewModel.loadingState();
        await tester.pump();

        // Assert: Should show default loading widget (CircularProgressIndicator)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Act: Set error state
        viewModel.errorState('Test error');
        await tester.pump();

        // Assert: Should show default error widget with error text
        expect(find.text('Error: Test error'), findsOneWidget);
      });

      testWidgets('should pass correct parameters to onData callback',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel and track callback parameters
        final viewModel = TestAsyncViewModel();
        String? receivedData;
        TestAsyncViewModel? receivedViewModel;
        bool keepFunctionCalled = false;

        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) {
                receivedData = data;
                receivedViewModel = vm;
                
                // Test keep function
                final keptWidget = keep(const Text('Kept Widget'));
                expect(keptWidget, isNotNull);
                keepFunctionCalled = true;
                
                return Text('Success: $data');
              },
            ),
          ),
        ));

        // Act: Set success state
        viewModel.updateState('test data');
        await tester.pump();

        // Assert: Callback should receive correct parameters
        expect(receivedData, equals('test data'));
        expect(receivedViewModel, equals(viewModel));
        expect(keepFunctionCalled, isTrue);
        expect(find.text('Success: test data'), findsOneWidget);
      });
    });

    group('State Transition Handling', () {
      testWidgets('should handle state transitions correctly',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onInitial: () => const Text('Initial'),
              onLoading: () => const Text('Loading'),
              onData: (data, vm, keep) => Text('Data: $data'),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ));

        // Assert: Should start with initial state
        expect(find.text('Initial'), findsOneWidget);

        // Act: Transition to loading
        viewModel.loadingState();
        await tester.pump();

        // Assert: Should show loading
        expect(find.text('Loading'), findsOneWidget);
        expect(find.text('Initial'), findsNothing);

        // Act: Transition to success
        viewModel.updateState('success data');
        await tester.pump();

        // Assert: Should show success
        expect(find.text('Data: success data'), findsOneWidget);
        expect(find.text('Loading'), findsNothing);

        // Act: Transition to error
        viewModel.errorState('error message');
        await tester.pump();

        // Assert: Should show error
        expect(find.text('Error: error message'), findsOneWidget);
        expect(find.text('Data: success data'), findsNothing);

        // Act: Transition back to loading
        viewModel.loadingState();
        await tester.pump();

        // Assert: Should show loading again
        expect(find.text('Loading'), findsOneWidget);
        expect(find.text('Error: error message'), findsNothing);
      });

      testWidgets('should handle multiple rapid state changes',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onLoading: () => const Text('Loading'),
              onData: (data, vm, keep) => Text('Data: $data'),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ));

        // Act: Perform rapid state changes
        viewModel.loadingState();
        viewModel.updateState('data1');
        viewModel.errorState('error1');
        viewModel.loadingState();
        viewModel.updateState('data2');
        await tester.pump();

        // Assert: Should show final state
        expect(find.text('Data: data2'), findsOneWidget);
        expect(find.text('Loading'), findsNothing);
        expect(find.text('Error: error1'), findsNothing);
      });
    });

    group('Keep Function and Widget Preservation', () {
      testWidgets('should preserve widgets using keep function',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel and track widget instances
        final viewModel = TestAsyncViewModel();
        Widget? firstKeptWidget;
        Widget? secondKeptWidget;

        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) {
                final keptWidget = keep(const Text('Kept Widget'));
                if (firstKeptWidget == null) {
                  firstKeptWidget = keptWidget;
                } else {
                  secondKeptWidget = keptWidget;
                }
                return Column(
                  children: [
                    Text('Data: $data'),
                    keptWidget,
                  ],
                );
              },
            ),
          ),
        ));

        // Act: Set initial success state
        viewModel.updateState('data1');
        await tester.pump();

        // Assert: Should render with kept widget
        expect(find.text('Data: data1'), findsOneWidget);
        expect(find.text('Kept Widget'), findsOneWidget);

        // Act: Update state again
        viewModel.updateState('data2');
        await tester.pump();

        // Assert: Should preserve the same widget instance
        expect(find.text('Data: data2'), findsOneWidget);
        expect(find.text('Kept Widget'), findsOneWidget);
        expect(firstKeptWidget, isNotNull);
        expect(secondKeptWidget, isNotNull);
        expect(identical(firstKeptWidget, secondKeptWidget), isTrue);
      });

      testWidgets('should handle keep function with different widget keys',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) {
                return Column(
                  children: [
                    Text('Data: $data'),
                    keep(const Text('Widget 1', key: Key('widget1'))),
                    keep(const Text('Widget 2', key: Key('widget2'))),
                  ],
                );
              },
            ),
          ),
        ));

        // Act: Set success state
        viewModel.updateState('test');
        await tester.pump();

        // Assert: Should render both kept widgets
        expect(find.text('Data: test'), findsOneWidget);
        expect(find.text('Widget 1'), findsOneWidget);
        expect(find.text('Widget 2'), findsOneWidget);
      });
    });

    group('Listener Management and Lifecycle', () {
      testWidgets('should add and remove listeners correctly',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel and track listener count
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) => Text('Data: $data'),
            ),
          ),
        ));

        // Assert: Should have listener attached
        expect(viewModel.hasListeners, isTrue);

        // Act: Remove widget
        await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: Text('Empty')),
        ));

        // Assert: Should have removed listener
        expect(viewModel.hasListeners, isFalse);
      });

      testWidgets('should handle notifier changes correctly',
          (WidgetTester tester) async {
        // Setup: Create two AsyncViewModels
        final viewModel1 = TestAsyncViewModel();
        final viewModel2 = TestAsyncViewModel();
        
        // Build widget with first viewModel
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel1,
              onData: (data, vm, keep) => Text('VM1: $data'),
            ),
          ),
        ));

        // Act: Set data on first viewModel
        viewModel1.updateState('data1');
        await tester.pump();

        // Assert: Should show first viewModel data
        expect(find.text('VM1: data1'), findsOneWidget);
        expect(viewModel1.hasListeners, isTrue);
        expect(viewModel2.hasListeners, isFalse);

        // Act: Switch to second viewModel
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel2,
              onData: (data, vm, keep) => Text('VM2: $data'),
            ),
          ),
        ));

        // Act: Set data on second viewModel
        viewModel2.updateState('data2');
        await tester.pump();

        // Assert: Should show second viewModel data and update listeners
        expect(find.text('VM2: data2'), findsOneWidget);
        expect(find.text('VM1: data1'), findsNothing);
        expect(viewModel1.hasListeners, isFalse);
        expect(viewModel2.hasListeners, isTrue);
      });

      testWidgets('should handle widget disposal correctly',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) => Text('Data: $data'),
            ),
          ),
        ));

        // Assert: Should have listener
        expect(viewModel.hasListeners, isTrue);

        // Act: Dispose widget
        await tester.pumpWidget(const SizedBox.shrink());

        // Assert: Should clean up listener
        expect(viewModel.hasListeners, isFalse);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle null data gracefully',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel with nullable data
        final viewModel = NullableAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<NullableAsyncViewModel, String?>(
              notifier: viewModel,
              onData: (data, vm, keep) => Text('Data: ${data ?? 'null'}'),
            ),
          ),
        ));

        // Act: Set null data
        viewModel.updateState(null);
        await tester.pump();

        // Assert: Should handle null data
        expect(find.text('Data: null'), findsOneWidget);
      });

      testWidgets('should handle onData callback throwing exception',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel
        final viewModel = TestAsyncViewModel();
        
        // Build widget with throwing callback
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) {
                throw Exception('Test exception');
              },
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ));

        // Act: Set success state (should trigger exception)
        viewModel.updateState('test');
        await tester.pump();
        
        // Assert: Should handle exception gracefully
        expect(tester.takeException(), isA<Exception>());
      });

      testWidgets('should handle complex error objects',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel with complex error
        final viewModel = TestAsyncViewModel();
        final complexError = CustomError('Complex error message', 404);
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) => Text('Data: $data'),
              onError: (error, stackTrace) {
                if (error is CustomError) {
                  return Text('Custom Error: ${error.message} (${error.code})');
                }
                return Text('Error: $error');
              },
            ),
          ),
        ));

        // Act: Set complex error
        viewModel.errorState(complexError);
        await tester.pump();

        // Assert: Should handle complex error
        expect(find.text('Custom Error: Complex error message (404)'), findsOneWidget);
      });
    });

    group('Deprecated onSuccess Callback', () {
      testWidgets('should work with deprecated onSuccess callback',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel
        final viewModel = TestAsyncViewModel();
        
        // Build widget with deprecated callback
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              // ignore: deprecated_member_use
              onSuccess: (data) => Text('Success: $data'),
            ),
          ),
        ));

        // Act: Set success state
        viewModel.updateState('test data');
        await tester.pump();

        // Assert: Should work with deprecated callback
        expect(find.text('Success: test data'), findsOneWidget);
      });

      testWidgets('should prefer onData over deprecated onSuccess',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel
        final viewModel = TestAsyncViewModel();
        
        // Build widget with both callbacks
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) => Text('New: $data'),
              // ignore: deprecated_member_use
              onSuccess: (data) => Text('Old: $data'),
            ),
          ),
        ));

        // Act: Set success state
        viewModel.updateState('test data');
        await tester.pump();

        // Assert: Should prefer onData over onSuccess
        expect(find.text('New: test data'), findsOneWidget);
        expect(find.text('Old: test data'), findsNothing);
      });
    });

    group('Performance and Memory Management', () {
      testWidgets('should handle frequent state updates efficiently',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel and track rebuild count
        final viewModel = TestAsyncViewModel();
        var buildCount = 0;

        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) {
                buildCount++;
                return Text('Data: $data (Build: $buildCount)');
              },
            ),
          ),
        ));

        // Act: Perform many state updates
        for (int i = 0; i < 100; i++) {
          viewModel.updateState('data$i');
          await tester.pump();
        }

        // Assert: Should handle frequent updates
        expect(find.text('Data: data99 (Build: 100)'), findsOneWidget);
        expect(buildCount, equals(100));
      });

      testWidgets('should clean up resources properly',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel
        final viewModel = TestAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<TestAsyncViewModel, String>(
              notifier: viewModel,
              onData: (data, vm, keep) => Text('Data: $data'),
            ),
          ),
        ));

        // Act: Add some kept widgets
        viewModel.updateState('test');
        await tester.pump();

        // Assert: Should have resources allocated
        expect(viewModel.hasListeners, isTrue);

        // Act: Dispose widget
        await tester.pumpWidget(const SizedBox.shrink());

        // Assert: Should clean up resources
        expect(viewModel.hasListeners, isFalse);
      });
    });

    group('Integration with AsyncViewModelImpl', () {
      testWidgets('should integrate correctly with AsyncViewModelImpl',
          (WidgetTester tester) async {
        // Setup: Create AsyncViewModel with complex behavior
        final viewModel = ComplexAsyncViewModel();
        
        // Build widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ReactiveAsyncBuilder<ComplexAsyncViewModel, ComplexData>(
              notifier: viewModel,
              onLoading: () => const Text('Loading complex data'),
              onData: (data, vm, keep) => Text('Complex: ${data.value} (${data.timestamp})'),
              onError: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ));

        // Act: Load data (this sets loading state immediately)
        viewModel.loadData();
        await tester.pump();

        // Assert: Should show loading
        expect(find.text('Loading complex data'), findsOneWidget);

        // Act: Wait for completion (100ms delay in loadData)
        await tester.pump(const Duration(milliseconds: 150));

        // Assert: Should show loaded data
        expect(find.textContaining('Complex: loaded data'), findsOneWidget);
      });
    });
  });
}

// Test Models and ViewModels for ReactiveAsyncBuilder testing

class TestAsyncViewModel extends AsyncViewModelImpl<String> {
  TestAsyncViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<String> init() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 'initialized';
  }

  void loadData() {
    loadingState();
    Future.delayed(const Duration(milliseconds: 100)).then((_) {
      updateState('loaded data');
    });
  }
}

class NullableAsyncViewModel extends AsyncViewModelImpl<String?> {
  NullableAsyncViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<String?> init() async {
    return null;
  }
}

class ComplexData {
  final String value;
  final DateTime timestamp;

  ComplexData(this.value, this.timestamp);
}

class ComplexAsyncViewModel extends AsyncViewModelImpl<ComplexData> {
  ComplexAsyncViewModel() : super(AsyncState.initial(), loadOnInit: false);

  @override
  Future<ComplexData> init() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ComplexData('initialized', DateTime.now());
  }

  Future<void> loadData() async {
    loadingState();
    await Future.delayed(const Duration(milliseconds: 100));
    updateState(ComplexData('loaded data', DateTime.now()));
  }
}

class CustomError {
  final String message;
  final int code;

  CustomError(this.message, this.code);

  @override
  String toString() => 'CustomError: $message (Code: $code)';
}