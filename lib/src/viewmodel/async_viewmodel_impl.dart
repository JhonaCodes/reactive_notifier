import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/helper/helper_notifier.dart';

/// Base ViewModel implementation for handling asynchronous operations with state management.
///
/// Provides a standardized way to handle loading, success, and error states for async data.

/// Base ViewModel implementation for handling asynchronous operations with state management.
abstract class AsyncViewModelImpl<T> extends ChangeNotifier with HelperNotifier{
  late AsyncState<T> _state;
  late bool loadOnInit;

  AsyncViewModelImpl(this._state, {this.loadOnInit = true}) : super() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }

    if (loadOnInit) {
      _initializeAsync();
    }
  }

  /// Internal initialization method that properly handles async initialization
  Future<void> _initializeAsync() async {
    try {
      await reload();
    } catch (error, stackTrace) {
      errorState(error, stackTrace);
    }
  }

  /// Public method to reload data
  Future<void> reload() async {
    loadOnInit = false;
    if (_state.isLoading) return;

    loadingState();
    try {
      final result = await loadData();
      updateState(result);
    } catch (error, stackTrace) {
      errorState(error, stackTrace);
    }
  }

  void updateSilently(T newState) {
    if(isEmpty(newState)){
      _state = AsyncState.empty();
      return;
    }
    _state = AsyncState.success(newState);
  }

  void transformState(AsyncState<T> Function(AsyncState<T> data) data) {
    final dataNotifier = data(_state);
    if (dataNotifier.hashCode == _state.hashCode) {
      return;
    }

    if(isEmpty(data(_state))){
      _state = AsyncState.empty();
      notifyListeners();
      return;
    }
    _state = data(_state);
    notifyListeners();
  }

  void transformStateSilently(AsyncState<T> Function(AsyncState<T> data) data) {
    final dataNotifier = data(_state);
    if (dataNotifier.hashCode == _state.hashCode) {
      return;
    }

    if(isEmpty(data(_state))){
      _state = AsyncState.empty();
      return;
    }
    _state = data(_state);
  }

  /// Override this method to provide the async data loading logic
  @protected
  FutureOr<T> loadData();

  /// Update data directly

  void updateState(T data) {
    if(isEmpty(data)){
      _state = AsyncState.empty();
      notifyListeners();
      return;
    }
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
    _state = AsyncState.error(error, stackTrace);
    notifyListeners();
  }

  @protected
  void cleanState() {
    _state = AsyncState.initial();
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
  T? get data => _state.isSuccess ? _state.data : null;

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function() empty,
    required R Function(Object? err, StackTrace? stackTrace) error,
  }) {
    return _state.when(
      initial: initial,
      loading: loading,
      success: (infoData) => success(infoData),
      empty: empty,
      error: error,
    );
  }
}
