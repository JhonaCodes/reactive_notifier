import 'package:flutter/foundation.dart';

/// value return.
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

  void transformState(T Function(T data) data) {
    _notifier = data(_notifier);
    notifyListeners();
  }

  @protected
  @override
  String toString() => '${describeIdentity(this)}($_notifier)';

  @immutable
  @override
  bool get hasListeners => super.hasListeners;
}

@protected
abstract class StateNotifierImpl<T> extends ChangeNotifier {
  T _notifier;
  StateNotifierImpl(this._notifier) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @protected
  T get notifier => _notifier;

  /// [updateState]
  /// Updates the state and notifies listeners if the value has changed.

  void updateState(T newState) {
    if (_notifier.hashCode == newState.hashCode) {
      return;
    }

    _notifier = newState;
    notifyListeners();
  }

  void transformState(T Function(T data) data) {
    final dataNotifier = data(_notifier);
    if (dataNotifier.hashCode == _notifier.hashCode) {
      return;
    }
    _notifier = data(_notifier);
    notifyListeners();
  }

  /// [updateSilently]
  /// Updates the value silently without notifying listeners.
  @protected
  void updateSilently(T newState) {
    _notifier = newState;
  }

  @protected
  @override
  String toString() => '${describeIdentity(this)}($notifier)';

  @protected
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }

  @protected
  @override
  void removeListener(VoidCallback listener) => super.removeListener(listener);

  @protected
  @override
  void dispose() => super.dispose();

  @immutable
  @protected
  @override
  void notifyListeners() => super.notifyListeners();

  @immutable
  @protected
  @override
  bool get hasListeners => super.hasListeners;
}
