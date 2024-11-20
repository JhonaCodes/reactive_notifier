import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/handler/async_state.dart';

/// Base ViewModel implementation for handling asynchronous operations with state management.
///
/// Provides a standardized way to handle loading, success, and error states for async data.
abstract class AsyncViewModelImpl<T> extends ChangeNotifier {
  AsyncState<T> _state = AsyncState.initial();
  AsyncState<T> get state => _state;
  Object? get error => _state.error;
  StackTrace? get stackTrace => _state.stackTrace;

  AsyncViewModelImpl({bool loadOnInit = true}) {
    if (loadOnInit) {
      reload();
    }
  }

  @protected
  Future<void> reload() async {
    if (_state.isLoading) return;

    _setState(AsyncState.loading());
    try {
      final result = await loadData();
      _setState(AsyncState.success(result));
    } catch (error, stackTrace) {
      setError(error, stackTrace);
    }
  }

  /// Override this method to provide the async data loading logic
  @protected
  Future<T> loadData();

  @protected
  void updateData(T data) {
    _setState(AsyncState.success(data));
  }

  @protected
  void setError(Object error, [StackTrace? stackTrace]) {
    _setState(AsyncState.error(error, stackTrace));
  }

  void _setState(AsyncState<T> newState) {
    _state = newState;
    notifyListeners();
  }
}
