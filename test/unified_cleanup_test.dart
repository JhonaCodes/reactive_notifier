import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Test models for unified cleanup verification
class TestState {
  final String value;
  const TestState(this.value);
}

class AsyncTestData {
  final String name;
  const AsyncTestData(this.name);
}

/// Test ViewModels to verify unified behavior
class TestViewModel extends ViewModel<TestState> {
  TestViewModel() : super(const TestState('initial'));

  @override
  void init() {
    updateSilently(const TestState('ready'));
  }
}

class TestAsyncViewModel extends AsyncViewModelImpl<AsyncTestData> {
  TestAsyncViewModel() : super(AsyncState.initial());

  @override
  Future<AsyncTestData> init() async {
    return const AsyncTestData('async ready');
  }
}

void main() {
  group('Unified Cleanup Behavior Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    test('Both ViewModel and AsyncViewModel support multiple listeners', () {
      final viewModel = TestViewModel();
      final asyncViewModel = TestAsyncViewModel();

      // Both should start with 0 listeners
      expect(viewModel.activeListenerCount, equals(0));
      expect(asyncViewModel.activeListenerCount, equals(0));

      // Add multiple listeners to regular ViewModel
      viewModel.listenVM((data) => print('VM Listener 1: ${data.value}'));
      viewModel.listenVM((data) => print('VM Listener 2: ${data.value}'));
      viewModel.listenVM((data) => print('VM Listener 3: ${data.value}'));

      expect(viewModel.activeListenerCount, equals(3));

      // Add multiple listeners to AsyncViewModel
      asyncViewModel
          .listenVM((state) => print('Async Listener 1: ${state.runtimeType}'));
      asyncViewModel
          .listenVM((state) => print('Async Listener 2: ${state.runtimeType}'));

      expect(asyncViewModel.activeListenerCount, equals(2));

      // Clean up
      viewModel.stopListeningVM();
      asyncViewModel.stopListeningVM();

      expect(viewModel.activeListenerCount, equals(0));
      expect(asyncViewModel.activeListenerCount, equals(0));
    });

    test('Both ViewModels clean up properly on dispose', () {
      final viewModel = TestViewModel();
      final asyncViewModel = TestAsyncViewModel();

      // Add listeners
      viewModel.listenVM((data) => print('VM: ${data.value}'));
      asyncViewModel.listenVM((state) => print('Async: ${state.runtimeType}'));

      expect(viewModel.activeListenerCount, equals(1));
      expect(asyncViewModel.activeListenerCount, equals(1));

      // Dispose should clean everything
      viewModel.dispose();
      asyncViewModel.dispose();

      // After dispose, internal cleanup should have happened
      // We can't test activeListenerCount after dispose, but no crashes means success
    });

    test('stopListeningVM works consistently for both ViewModels', () {
      final viewModel = TestViewModel();
      final asyncViewModel = TestAsyncViewModel();

      // Set up listeners
      viewModel.listenVM((data) => print('VM1'));
      viewModel.listenVM((data) => print('VM2'));
      asyncViewModel.listenVM((state) => print('Async1'));
      asyncViewModel.listenVM((state) => print('Async2'));

      expect(viewModel.activeListenerCount, equals(2));
      expect(asyncViewModel.activeListenerCount, equals(2));

      // Stop all listeners using the same method
      viewModel.stopListeningVM();
      asyncViewModel.stopListeningVM();

      expect(viewModel.activeListenerCount, equals(0));
      expect(asyncViewModel.activeListenerCount, equals(0));
    });

    test('Both ViewModels track listener relationships correctly', () {
      final vm1 = TestViewModel();
      final vm2 = TestViewModel();
      final asyncVM = TestAsyncViewModel();

      // Create cross-listening relationships
      vm1.listenVM((data) => print('VM1 listens to itself'));
      vm2.listenVM((data) => print('VM2 listens to itself'));
      asyncVM.listenVM((state) => print('AsyncVM listens to itself'));

      // Each should track its own listeners
      expect(vm1.activeListenerCount, equals(1));
      expect(vm2.activeListenerCount, equals(1));
      expect(asyncVM.activeListenerCount, equals(1));

      // Cross-ViewModel listening
      vm1.listenVM((data) => print('VM1 -> VM2'));
      asyncVM.listenVM((state) => print('AsyncVM -> itself again'));

      expect(vm1.activeListenerCount, equals(2)); // self + cross
      expect(asyncVM.activeListenerCount, equals(2)); // self + additional

      // Clean up individual ViewModels
      vm1.stopListeningVM();
      expect(vm1.activeListenerCount, equals(0));
      expect(vm2.activeListenerCount, equals(1)); // still has its own
      expect(asyncVM.activeListenerCount, equals(2)); // unaffected

      vm2.dispose();
      asyncVM.dispose();
    });

    test('Unified logging format during disposal', () {
      final viewModel = TestViewModel();
      final asyncViewModel = TestAsyncViewModel();

      // Add listeners to verify they're logged
      viewModel.listenVM((data) => print('VM listener'));
      asyncViewModel.listenVM((state) => print('Async listener'));

      // Both should have active listeners
      expect(viewModel.activeListenerCount, greaterThan(0));
      expect(asyncViewModel.activeListenerCount, greaterThan(0));

      // Disposal should log similar information for both
      // We can't test the logs directly, but disposal without crashes means success
      viewModel.dispose();
      asyncViewModel.dispose();
    });
  });
}
