import 'package:flutter/foundation.dart';

@protected

/// value return.
abstract class NotifierImpl<T> extends ChangeNotifier
    implements ValueListenable<T> {
  T _value;
  NotifierImpl(this._value) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  T get value => _value;

  /// [updateState]
  /// Updates the state and notifies listeners if the value has changed.
  ///
  void updateState(T newState) {
    if (_value == newState) {
      return;
    }

    _value = newState;
    notifyListeners();
  }

  /// [updateSilently]
  /// Updates the value silently without notifying listeners.
  ///
  void updateSilently(T newState) {
    _value = newState;
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

@protected
abstract class StateNotifierImpl<T> extends ChangeNotifier
    implements ValueListenable<T> {
  T _value;
  StateNotifierImpl(this._value) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @protected
  @override
  T get value => _value;

  /// [updateState]
  /// Updates the state and notifies listeners if the value has changed.
  @protected
  void updateState(T newState) {
    if (_value == newState) {
      return;
    }

    _value = newState;
    notifyListeners();
  }

  /// [updateSilently]
  /// Updates the value silently without notifying listeners.
  @protected
  void updateSilently(T newState) {
    _value = newState;
  }

  @protected
  @override
  String toString() => '${describeIdentity(this)}($value)';

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
