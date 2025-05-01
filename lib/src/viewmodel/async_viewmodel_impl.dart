import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/helper/helper_notifier.dart';

/// Base ViewModel implementation for handling asynchronous operations with state management.
///
/// Provides a standardized way to handle loading, success, and error states for async data.

/// Base ViewModel implementation for handling asynchronous operations with state management.
abstract class AsyncViewModelImpl<T> extends ChangeNotifier
    with HelperNotifier {
  late AsyncState<T> _state;
  late bool loadOnInit;

  AsyncViewModelImpl(this._state, {this.loadOnInit = true}) : super() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }

    if (loadOnInit) {
      _initializeAsync();

      /// Yes and only if it is changed to true when the entire initialization process is finished.
      hasInitializedListenerExecution = true;
    }
  }

  /// Internal initialization method that properly handles async initialization
  Future<void> _initializeAsync() async {
    /// We make sure it is always false before any full initialization.
    hasInitializedListenerExecution = false;

    try {
      await reload();
    } catch (error, stackTrace) {
      errorState(error, stackTrace);
    }
  }

  /// [hasInitializedListenerExecution]
  /// When registering the listener from an external function, you must first validate if all the loadData has already been initialized,
  /// to avoid duplication when initializing our listener, because when we create a listener it executes the internal code.
  /// We don't use [loadOnInit], because we need a way to be sure that the entire cycle of our viewmodel has already been executed.
  ///
  /// Create fetch function
  ///  Future<void> _myFunctionWithFetchForListener() async{
  ///     if (hasInitializedListenerExecution) {
  ///       _reloadDataForListener();
  ///     }
  ///   }
  ///
  /// Register listener
  ///   @override
  ///   Future<void> setupListeners()async{
  ///     MyNotifierService.instance.notifier.addListener(_myFunctionWithFetchForListener);
  ///   }
  ///
  bool hasInitializedListenerExecution = false;

  /// Public method to reload data
  Future<void> reload() async {
    if (_state.isLoading) return;
    try {
      /// If it is the first initialization we do not have listeners to remove.
      if (!loadOnInit) {
        await removeListeners();
      }

      loadOnInit = false;

      loadingState();
      final result = await loadData();
      updateState(result);

      await setupListeners();
    } catch (error, stackTrace) {
      errorState(error, stackTrace);
      try {
        await setupListeners();
      } catch (listenerError) {
        log('Error on restart listeners: $listenerError');
      }
    }
  }

  /// [removeListeners]
  /// We remove the listeners registered in [setupListeners] to avoid memory problems.
  ///
  @mustCallSuper
  Future<void> removeListeners(
      {List<String> currentListeners = const []}) async {
    if (currentListeners.isNotEmpty) {
      assert(() {
        logRemove<T>(listeners: currentListeners);
        return true;
      }());
    }
  }

  /// [setupListeners]
  /// We register our listeners coming from the notifiers.
  ///
  @mustCallSuper
  Future<void> setupListeners(
      {List<String> currentListeners = const []}) async {
    if (currentListeners.isNotEmpty) {
      assert(() {
        logSetup<T>(listeners: currentListeners);
        return true;
      }());
    }
  }

  void updateSilently(T newState) {
    _state = AsyncState.success(newState);
  }

  void transformState(AsyncState<T> Function(AsyncState<T> data) data) {
    _state = data(_state);
    notifyListeners();
  }

  void transformStateSilently(AsyncState<T> Function(AsyncState<T> data) data) {
    _state = data(_state);
  }

  /// Override this method to provide the async data loading logic
  @protected
  FutureOr<T> loadData();

  /// Update data directly

  void updateState(T data) {
    _state = AsyncState.success(data);
    notifyListeners();
  }

  @protected
  void loadingState() {
    _state = AsyncState.loading();
    notifyListeners();
  }

  /// Set error state

  void errorState(Object error, [StackTrace? stackTrace]) {
    final errorToThrow = error;
    _state = AsyncState.error(error, stackTrace);
    notifyListeners();

    throw errorToThrow;
  }

  void cleanState() {
    _state = AsyncState.initial();
    unawaited(removeListeners());
    loadData();
    unawaited(setupListeners());
    notifyListeners();
  }

  /// [loadNotifier]
  /// Ensures the ViewModel's availability by confirming initialization has occurred.
  ///
  /// This method should be called when explicit access to the ViewModel is required
  /// outside its normal lifecycle. Typical situations include:
  ///
  /// - At application startup to pre-load critical ViewModels
  /// - In code paths where it's not evident if the ViewModel is already initialized
  /// - When data availability needs to be guaranteed before executing an operation
  ///
  /// It is not necessary to call this method in the normal lifecycle, as the ViewModel's
  /// constructor automatically handles initialization through [_safeInitialization].
  ///
  /// ```dart
  /// // Typical usage during app initialization
  /// await myViewModel.loadNotifier();
  ///
  /// // Or from a service
  /// await notifier<MyViewModel>().loadNotifier();
  /// ```
  ///
  /// This method is idempotent and safe for multiple calls:
  /// - If the ViewModel is already initialized, it will do nothing
  /// - If the ViewModel was disposed, it will log the state but not interfere
  ///   with the automatic reinitialization process
  ///
  /// @return [Future] that completes immediately, allowing
  ///         sequential asynchronous operations if needed
  Future<void> loadNotifier() async {
    assert(() {
      log('''
🔍 loadNotifier() called for ViewModel<${T.toString()}>
''', level: 10);
      return true;
    }());

    if (_state.data == null || loadOnInit) {
      await loadData();
      await setupListeners();
      return;
    }
    return Future.value();
  }

  /// Check if any operation is in progress
  bool get isLoading => _state.isLoading;

  /// Get current error if any
  Object? get error => _state.error;

  /// Get current stack trace if there's an error
  StackTrace? get stackTrace => _state.stackTrace;

  /// Check if the state contains valid data
  bool get hasData => _state.isSuccess;

  /// Get the current data (may be null if not in success state)
  T get data {
    if (_state.error != null) {
      throw _state.error!;
    }

    if (_state.data == null) {
      final error = _state.error ?? "Not found data";
      _state = AsyncState.error(error, _state.stackTrace);
      throw error;
    }

    return _state.data!;
  }

  R match<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function() empty,
    required R Function(Object? err, StackTrace? stackTrace) error,
  }) {
    return _state.match(
      initial: initial,
      loading: loading,
      success: (infoData) => success(infoData),
      empty: empty,
      error: error,
    );
  }

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Object? err, StackTrace? stackTrace) error,
  }) {
    return _state.when(
      initial: initial,
      loading: loading,
      success: (infoData) => success(infoData),
      error: error,
    );
  }
}
