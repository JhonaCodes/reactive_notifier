import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/handler/async_state.dart';
import 'package:reactive_notifier/src/implements/notifier_impl.dart';

/// Base ViewModel implementation for handling asynchronous operations with state management.
///
/// Provides a standardized way to handle loading, success, and error states for async data.
import 'package:flutter/foundation.dart';

/// Base ViewModel implementation for handling asynchronous operations with state management.
abstract class AsyncViewModelImpl<T> extends NotifierImpl<AsyncState<T>> {
  AsyncViewModelImpl({
    bool loadOnInit = true,
    T? initialData,
  }) : super(initialData != null ? AsyncState.success(initialData) : AsyncState.initial()) {
    if (loadOnInit) {
      _initializeAsync();
    }
  }

  /// Internal initialization method that properly handles async initialization
  Future<void> _initializeAsync() async {
    try {
      await reload();
    } catch (error, stackTrace) {
      setError(error, stackTrace);
    }
  }

  /// Public method to reload data
  @protected
  Future<void> reload() async {
    if (value.isLoading) return;

    updateState(AsyncState.loading());
    try {
      final result = await loadData();
      updateState(AsyncState.success(result));
    } catch (error, stackTrace) {
      setError(error, stackTrace);
    }
  }

  /// Override this method to provide the async data loading logic
  @protected
  Future<T> loadData();

  /// Update data directly
  @protected
  void updateData(T data) {
    updateState(AsyncState.success(data));
  }

  /// Set error state
  @protected
  void setError(Object error, [StackTrace? stackTrace]) {
    updateState(AsyncState.error(error, stackTrace));
  }

  /// Check if any operation is in progress
  bool get isLoading => value.isLoading;

  /// Get current error if any
  Object? get error => value.error;

  /// Get current stack trace if there's an error
  StackTrace? get stackTrace => value.stackTrace;

  /// Check if the state contains valid data
  bool get hasData => value.isSuccess;

  /// Get the current data (may be null if not in success state)
  T? get data => value.isSuccess ? value.data : null;
}
