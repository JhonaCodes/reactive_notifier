import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/handler/async_state.dart';

class ReactiveAsyncBuilder<T> extends StatelessWidget {
  final AsyncViewModelImpl<T> viewModel;
  final Widget Function(T data) buildSuccess;
  final Widget Function()? buildLoading;
  final Widget Function(Object? error, StackTrace? stackTrace)? buildError;
  final Widget Function()? buildInitial;

  const ReactiveAsyncBuilder({
    super.key,
    required this.viewModel,
    required this.buildSuccess,
    this.buildLoading,
    this.buildError,
    this.buildInitial,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return viewModel.when(
          initial: () => buildInitial?.call() ?? const SizedBox.shrink(),
          loading: () =>
              buildLoading?.call() ??
              const Center(child: CircularProgressIndicator.adaptive()),
          success: (data) => buildSuccess(data),
          error: (error, stackTrace) => buildError != null ? buildError!(error, stackTrace) : Center(child: Text('Error: $error')),
        );
      },
    );
  }
}


/// Base ViewModel implementation for handling asynchronous operations with state management.
///
/// Provides a standardized way to handle loading, success, and error states for async data.

/// Base ViewModel implementation for handling asynchronous operations with state management.
abstract class AsyncViewModelImpl<T> extends ChangeNotifier {

  late AsyncState _state;
  late bool loadOnInit;

  AsyncViewModelImpl(this._state,{ this.loadOnInit = true }) :super() {

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
  @protected
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

  /// Override this method to provide the async data loading logic
  @protected
  Future<T> loadData();

  /// Update data directly

  @protected
  void updateState(T data) {
    _state = AsyncState.success(data);
    notifyListeners();
  }

  @protected
  void loadingState(){
    _state = AsyncState.loading();
    notifyListeners();
  }

  /// Set error state

  @protected
  void errorState(Object error, [StackTrace? stackTrace]) {
    _state = AsyncState.error(error, stackTrace);
    notifyListeners();
  }

  @protected
  void cleanState(){
    _state = AsyncState.initial();
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

  @protected
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Object? err, StackTrace? stackTrace) error,
  }){
    return _state.when(
      initial: initial,
      loading: loading,
      success: (infoData) => success(infoData),
      error: error,
    );
  }

}