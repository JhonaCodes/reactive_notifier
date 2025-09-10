import 'dart:async';

import 'package:reactive_notifier/src/viewmodel/async_viewmodel_impl.dart';
import 'package:reactive_notifier/src/handler/async_state.dart';

/// Test AsyncViewModel implementation for testing
class TestAsyncViewModel extends AsyncViewModelImpl<String> {
  final String initialData;
  int initCallCount = 0;
  int setupListenersCallCount = 0;
  int removeListenersCallCount = 0;
  int onResumeCallCount = 0;
  String? lastOnResumeData;

  TestAsyncViewModel({required this.initialData, bool loadOnInit = true})
      : super(AsyncState.initial(), loadOnInit: loadOnInit);

  @override
  Future<String> init() async {
    initCallCount++;
    return initialData;
  }

  @override
  Future<void> setupListeners(
      {List<String> currentListeners = const []}) async {
    setupListenersCallCount++;
    await super.setupListeners(currentListeners: currentListeners);
  }

  @override
  Future<void> removeListeners(
      {List<String> currentListeners = const []}) async {
    removeListenersCallCount++;
    await super.removeListeners(currentListeners: currentListeners);
  }

  @override
  Future<void> onResume(String? data) async {
    onResumeCallCount++;
    lastOnResumeData = data;
    await super.onResume(data);
  }

  // Test helpers to inspect state
  bool isInitial() => match<bool>(
        initial: () => true,
        loading: () => false,
        success: (_) => false,
        empty: () => false,
        error: (_, __) => false,
      );

  bool isSuccess() => match<bool>(
        initial: () => false,
        loading: () => false,
        success: (_) => true,
        empty: () => false,
        error: (_, __) => false,
      );

  bool isEmpty() => match<bool>(
        initial: () => false,
        loading: () => false,
        success: (_) => false,
        empty: () => true,
        error: (_, __) => false,
      );

  bool isError() => match<bool>(
        initial: () => false,
        loading: () => false,
        success: (_) => false,
        empty: () => false,
        error: (_, __) => true,
      );

  // Helper to set state for testing (using existing public methods)
  void testSetEmptyState() {
    transformStateSilently((_) => AsyncState.empty());
  }

  // Expose protected methods for testing
  void testLoadingState() {
    loadingState();
  }

  // Helper to check if has listeners
  bool get testHasListeners => hasListeners;
}

/// Slow AsyncViewModel for testing concurrent operations
class SlowAsyncViewModel extends AsyncViewModelImpl<String> {
  final int delay;
  int initCallCount = 0;
  Timer? _delayTimer;

  SlowAsyncViewModel({this.delay = 50, bool loadOnInit = true})
      : super(AsyncState.initial(), loadOnInit: loadOnInit);

  @override
  Future<String> init() async {
    initCallCount++;
    // Use immediate completion to avoid pending timers in tests
    if (delay <= 0) {
      return 'slow_data';
    }

    final completer = Completer<String>();
    _delayTimer = Timer(Duration(milliseconds: delay), () {
      if (!isDisposed && !completer.isCompleted) {
        completer.complete('slow_data');
      }
    });

    return completer.future;
  }

  // Expose protected methods for testing
  void testLoadingState() {
    loadingState();
  }

  // Helper to check if has listeners
  bool get testHasListeners => hasListeners;

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }
}

/// AsyncViewModel that throws error during init
class ErrorAsyncViewModel extends AsyncViewModelImpl<String> {
  int setupListenersCallCount = 0;

  ErrorAsyncViewModel() : super(AsyncState.initial(), loadOnInit: true);

  @override
  Future<String> init() async {
    throw Exception('Init failed');
  }

  @override
  Future<void> setupListeners(
      {List<String> currentListeners = const []}) async {
    setupListenersCallCount++;
    await super.setupListeners(currentListeners: currentListeners);
  }

  // Test helper
  bool isError() => match<bool>(
        initial: () => false,
        loading: () => false,
        success: (_) => false,
        empty: () => false,
        error: (_, __) => true,
      );

  // Expose protected methods for testing
  void testLoadingState() {
    loadingState();
  }

  // Helper to check if has listeners
  bool get testHasListeners => hasListeners;
}

/// AsyncViewModel with conditional failure for testing error handling
class ConditionalErrorAsyncViewModel extends AsyncViewModelImpl<String> {
  bool shouldFail;

  ConditionalErrorAsyncViewModel(
      {this.shouldFail = false, bool loadOnInit = true})
      : super(AsyncState.initial(), loadOnInit: loadOnInit);

  @override
  Future<String> init() async {
    if (shouldFail) {
      throw Exception('Conditional failure');
    }
    return 'success_data';
  }

  // Test helpers
  bool isSuccess() => match<bool>(
        initial: () => false,
        loading: () => false,
        success: (_) => true,
        empty: () => false,
        error: (_, __) => false,
      );

  bool isError() => match<bool>(
        initial: () => false,
        loading: () => false,
        success: (_) => false,
        empty: () => false,
        error: (_, __) => true,
      );

  // Expose protected methods for testing
  void testLoadingState() {
    loadingState();
  }

  // Helper to check if has listeners
  bool get testHasListeners => hasListeners;
}

/// AsyncViewModel for testing List data transformations
class ListAsyncViewModel extends AsyncViewModelImpl<List<int>> {
  final List<int> initialData;

  ListAsyncViewModel({required this.initialData, bool loadOnInit = true})
      : super(AsyncState.initial(), loadOnInit: loadOnInit);

  @override
  Future<List<int>> init() async {
    return initialData;
  }

  // Test helper
  bool isSuccess() => match<bool>(
        initial: () => false,
        loading: () => false,
        success: (_) => true,
        empty: () => false,
        error: (_, __) => false,
      );

  // Expose protected methods for testing
  void testLoadingState() {
    loadingState();
  }

  // Helper to check if has listeners
  bool get testHasListeners => hasListeners;
}

/// Dependent AsyncViewModel for testing cross-communication
class DependentAsyncViewModel extends AsyncViewModelImpl<String> {
  AsyncState<String>? receivedSourceState;
  int sourceUpdateCount = 0;

  DependentAsyncViewModel({bool loadOnInit = true})
      : super(AsyncState.initial(), loadOnInit: loadOnInit);

  @override
  Future<String> init() async {
    return 'dependent_initial';
  }

  /// Setup reactive communication with source AsyncViewModel
  Future<AsyncState<String>> listenToSource(
      TestAsyncViewModel sourceViewModel) {
    return sourceViewModel.listenVM((sourceState) {
      sourceUpdateCount++;
      receivedSourceState = sourceState;
      // React to source changes by updating our own state
      if (sourceState.isSuccess) {
        updateState('dependent_reacting_to_${sourceState.data}');
      }
    }, callOnInit: true); // Call immediately to get current state
  }

  /// Stop listening to source AsyncViewModel
  void stopListeningToSource() {
    stopListeningVM();
  }

  // Expose protected methods for testing
  void testLoadingState() {
    loadingState();
  }

  // Helper to check if has listeners
  bool get testHasListeners => hasListeners;
}
