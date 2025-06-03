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

  void transformStateSilently(T Function(T data) data) {
    _notifier = data(_notifier);
  }

  @protected
  @override
  String toString() => '${describeIdentity(this)}($_notifier)';

  @override
  bool get hasListeners => super.hasListeners;

  VoidCallback? _currentListener;

  Future<void> listen(void Function(T data) data) async {
    log("Listen notifier is active");
    if (_currentListener != null) {
      removeListener(_currentListener!);
    }
    _currentListener = () => data(_notifier);
    addListener(_currentListener!);
  }

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
