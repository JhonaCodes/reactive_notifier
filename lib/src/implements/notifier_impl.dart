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

  void transformState(T Function(T data) data) {
    _notifier = data(_notifier);
    notifyListeners();
  }

  @protected
  @override
  String toString() => '${describeIdentity(this)}($_notifier)';

  @override
  bool get hasListeners => super.hasListeners;
}

/// [StateNotifierImpl]
/// Contains the data that is modified by `NotifierImpl`, it takes the data type declared in the viewmodel -
/// to use as a data type and returns the data from that viewmodel.
/// [ViewModelImpl] and [ViewModelStateImpl]
@protected
@Deprecated(
    "StateNotifierImpl will be replaced by ViewModel in version 2.7.0. It is recommended to migrate.")
abstract class StateNotifierImpl<T> extends ChangeNotifier {
  T _data;
  StateNotifierImpl(this._data) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  T get data => _data;

  /// [updateState]
  /// Updates the state and notifies listeners if the value has changed.

  void updateState(T newState) {
    if (_data.hashCode == newState.hashCode) {
      return;
    }

    _data = newState;
    notifyListeners();
  }

  void transformState(T Function(T data) data) {
    final dataNotifier = data(_data);
    if (dataNotifier.hashCode == _data.hashCode) {
      return;
    }
    _data = data(_data);
    notifyListeners();
  }

  /// [updateSilently]
  /// Updates the value silently without notifying listeners.
  @protected
  void updateSilently(T newState) {
    _data = newState;
  }

  @protected
  @override
  String toString() => '${describeIdentity(this)}($data)';
}
