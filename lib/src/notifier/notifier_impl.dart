import 'dart:developer';

import 'package:flutter/foundation.dart';

/// [NotifierImpl]
/// Contains all the elements of the viewmodel, such as the main functions and attributes, which are used to modify data.
/// [ReactiveBuilder] and [ReactiveNotifier]
///
@protected
abstract class NotifierImpl<T> extends ChangeNotifier {
  T _notifier;
  NotifierImpl(this._notifier) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  T get notifier => _notifier;

  /// [updateState]
  /// Updates the state and notifies listeners if the value has changed.
  ///
  @protected
  void updateState(T newState) {
    if (_notifier == newState) {
      return;
    }

    _notifier = newState;
    notifyListeners();
  }

  /// [updateSilently]
  /// Updates the value silently without notifying listeners.
  ///
  @protected
  void updateSilently(T newState) {
    _notifier = newState;
  }

  @protected
  void transformState(T Function(T data) data) {
    _notifier = data(_notifier);
    notifyListeners();
  }

  void transformStateSilently(T Function(T data) transform) {
    _notifier = transform(_notifier);
  }

  @protected
  @override
  String toString() => '${describeIdentity(this)}($_notifier)';

  @override
  bool get hasListeners => super.hasListeners;

  /// Holds the currently active listener callback.
  /// Ensures that only one listener is attached at any given time.
  VoidCallback? _currentListener;

  /// Starts listening for changes in the ViewModel.
  ///
  /// This method:
  /// - Removes any previously registered listener.
  /// - Registers a new listener that invokes the provided [value] callback with the current [_data].
  /// - Immediately returns the current value of [_data], allowing the caller to sync with the initial state.
  ///
  /// [value] is the callback function that receives the updated data whenever a change occurs.
  ///
  /// Returns the current value of [_data].
  T listen(void Function(T data) value) {
    log("Listen notifier is active");

    if (_currentListener != null) {
      removeListener(_currentListener!);
    }

    _currentListener = () => value(_notifier);
    addListener(_currentListener!);

    return _notifier;
  }

  /// Stops listening for changes in the ViewModel.
  ///
  /// If a listener is currently registered, it will be removed and
  /// [_currentListener] will be set to null to free up resources.
  void stopListening() {
    if (_currentListener != null) {
      removeListener(_currentListener!);
      _currentListener = null;
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
