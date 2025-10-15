import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Test to verify that AsyncViewModelImpl doesn't double-initialize
/// when navigating back to a screen that already had context
class DoubleInitializationTestViewModel extends AsyncViewModelImpl<String> {
  DoubleInitializationTestViewModel()
      : super(AsyncState.initial(), loadOnInit: true);

  int initCallCount = 0;

  @override
  Future<String> init() async {
    initCallCount++;
    return 'Initialized $initCallCount times';
  }
}

mixin DoubleInitTestService {
  static ReactiveNotifier<DoubleInitializationTestViewModel>? _instance;

  static ReactiveNotifier<DoubleInitializationTestViewModel> get instance {
    _instance ??= ReactiveNotifier<DoubleInitializationTestViewModel>(
        () => DoubleInitializationTestViewModel());
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }
}

void main() {
  group('AsyncViewModelImpl Double Initialization Prevention Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      DoubleInitTestService.reset();
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
      DoubleInitTestService.reset();
    });

    test(
        'should not double-initialize when reinitializeWithContext is called multiple times',
        () async {
      // Create the ViewModel instance
      final viewModel = DoubleInitTestService.instance.notifier;

      // Wait for initial initialization to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify initial state after first initialization
      expect(viewModel.initCallCount, equals(1),
          reason: 'Should initialize only once initially');
      expect(viewModel.hasData, isTrue,
          reason: 'Should have data after initialization');
      expect(viewModel.data, equals('Initialized 1 times'),
          reason: 'Should contain correct initial data');

      // Simulate what happens when user navigates back to a screen
      // This would previously cause double initialization
      viewModel.reinitializeWithContext();

      // Wait a bit to ensure no async operations occur
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify that init was not called again
      expect(viewModel.initCallCount, equals(1),
          reason: 'Should NOT initialize again when context already available');
      expect(viewModel.data, equals('Initialized 1 times'),
          reason: 'Data should remain the same');
    });

    test(
        'should maintain initialization state correctly through multiple reinitializeWithContext calls',
        () async {
      final viewModel = DoubleInitTestService.instance.notifier;

      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Check initial state
      expect(viewModel.initCallCount, equals(1),
          reason: 'Should initialize once initially');
      expect(viewModel.hasInitializedListenerExecution, isTrue,
          reason: 'hasInitializedListenerExecution should be true');

      // Call reinitializeWithContext multiple times (simulating multiple screen navigations)
      viewModel.reinitializeWithContext();
      viewModel.reinitializeWithContext();
      viewModel.reinitializeWithContext();

      // Wait to ensure no additional async operations occur
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify that init was not called additional times
      expect(viewModel.initCallCount, equals(1),
          reason:
              'Should not reinitialize when already initialized with context');
      expect(viewModel.data, equals('Initialized 1 times'),
          reason: 'Data should remain unchanged');
    });
  });
}
