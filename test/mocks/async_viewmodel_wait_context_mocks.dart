import 'dart:async';

import 'package:reactive_notifier/src/viewmodel/async_viewmodel_impl.dart';
import 'package:reactive_notifier/src/handler/async_state.dart';

/// Test AsyncViewModel implementation for testing waitForContext functionality
class TestWaitForContextViewModel extends AsyncViewModelImpl<String> {
  final String initialData;
  final bool shouldThrowError;
  int initCallCount = 0;
  int setupListenersCallCount = 0;
  int removeListenersCallCount = 0;
  int onResumeCallCount = 0;
  String? lastOnResumeData;

  TestWaitForContextViewModel({
    required this.initialData,
    bool loadOnInit = true,
    bool waitForContext = false,
    this.shouldThrowError = false,
  }) : super(AsyncState.initial(),
            loadOnInit: loadOnInit, waitForContext: waitForContext);

  @override
  Future<String> init() async {
    initCallCount++;

    if (shouldThrowError) {
      throw Exception('Test error during initialization');
    }

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
}
