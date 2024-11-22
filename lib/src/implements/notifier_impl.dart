import 'package:flutter/foundation.dart';

@protected
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

// abstract class ValueListenable<T> extends Listenable {
//   /// Abstract const constructor. This constructor enables subclasses to provide
//   /// const constructors so that they can be used in const expressions.
//   const ValueListenable();
//
//   /// The current value of the object. When the value changes, the callbacks
//   /// registered with [addListener] will be invoked.
//   T get state;
// }
