import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/viewmodel/viewmodel_impl.dart';
import 'package:reactive_notifier/src/viewmodel/async_viewmodel_impl.dart';

/// Provides typed access to dependency changes in [onDependenciesStateChanged].
///
/// During **setup** (before `init()`), calling [on] registers the dependency,
/// takes an initial snapshot, and invokes the callback with `(current, current)`.
///
/// During **reaction** (after a dependency fires), calling [on] only invokes the
/// callback if that specific dependency changed, providing `(previous, current)`.
///
/// Example:
/// ```dart
/// @override
/// void onDependenciesStateChanged(DependencyState change) {
///   change.on<UserModel>(UserService.userState, (previous, current) {
///     if (previous.id != current.id) {
///       // User changed — react
///     }
///   });
/// }
/// ```
class DependencyState {
  final bool _isSetup;
  final Set<ReactiveNotifier> _changed;
  final Map<ReactiveNotifier, dynamic> _snapshots;

  /// Internal constructor — not intended for direct use by library consumers.
  /// Used by ViewModel and AsyncViewModelImpl to create setup/reaction states.
  @protected
  DependencyState.create({
    required bool isSetup,
    required Set<ReactiveNotifier> changed,
    required Map<ReactiveNotifier, dynamic> snapshots,
  }) : _isSetup = isSetup,
       _changed = changed,
       _snapshots = snapshots;

  /// Registers a dependency (during setup) or reacts to its change (during reaction).
  ///
  /// [notifier] is the ReactiveNotifier holding the dependency state.
  /// [callback] receives `(previous, current)` values of type [T].
  ///
  /// During setup: registers the dependency, snapshots its current value,
  /// and calls `callback(current, current)`.
  ///
  /// During reaction: only calls callback if [notifier] is in the changed set,
  /// providing the previous snapshot and the new current value.
  void on<T>(
    ReactiveNotifier notifier,
    void Function(T previous, T current) callback,
  ) {
    if (_isSetup) {
      // Setup phase: register dependency, snapshot, execute callback
      final current = _extractValue<T>(notifier);
      _snapshots[notifier] = current;
      callback(current, current);
    } else {
      // Reaction phase: only execute if this notifier changed
      if (_changed.contains(notifier)) {
        final previous = _snapshots[notifier] as T;
        final current = _extractValue<T>(notifier);
        _snapshots[notifier] = current;
        callback(previous, current);
      }
    }
  }

  /// Whether this is the initial setup pass (true) or a reaction pass (false).
  bool get isSetup => _isSetup;

  /// Extracts the typed value from a ReactiveNotifier, handling ViewModel and simple types.
  T _extractValue<T>(ReactiveNotifier notifier) {
    final value = notifier.notifier;
    if (value is ViewModel<T>) return value.data;
    if (value is AsyncViewModelImpl<T>) {
      final data = value.data;
      if (data is T) return data;
    }
    return value as T;
  }
}
