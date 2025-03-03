import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/tracker/state_tracker.dart';

import '../implements/notifier_impl.dart';
import '../implements/repository_impl.dart';

/// [ViewModelImpl]
/// Base ViewModel implementation with repository integration for domain logic and data handling.
/// Use this when you need to interact with repositories and manage business logic.
/// For simple state management without repository, use [ViewModelStateImpl] instead.
///
@Deprecated("Use ViewModel")
abstract class ViewModelImpl<T> extends StateNotifierImpl<T> {
  final String? _id;
  final String? _location;

  // ignore_for_file: unused_field
  final RepositoryImpl _repository;

  ViewModelImpl(this._repository, super._data, [this._id, this._location]) {
    _initialization();

    if (!kReleaseMode && (_id != null && _location != null)) {
      StateTracker.setLocation(_id, _location);
    }
  }

  void init();

  bool _initialized = false;

  void _initialization() {
    if (!_initialized) {
      log('ViewModelImpl.init');

      init();
      _initialized = true;
    }
  }

  void addDependencyTracker(String notifyId, String dependentId) {
    if (!kReleaseMode) {
      StateTracker.addDependency(notifyId, dependentId);
    }
  }

  void currentTracker() {
    if (!kReleaseMode && _id != null) {
      StateTracker.trackStateChange(_id);
    }
  }

  @override
  void dispose() {
    _initialized = false;
    super.dispose();
  }
}

/// [ViewModelStateImpl]
/// Base ViewModel implementation for simple state management without repository dependencies.
/// Use this when you only need to handle UI state without domain logic or data layer interactions.
/// For cases requiring repository access, use [ViewModelImpl] instead.
///
@Deprecated("Use ViewModel")
abstract class ViewModelStateImpl<T> extends StateNotifierImpl<T> {
  final String? _id;
  final String? _location;

  ViewModelStateImpl(super._data, [this._id, this._location]) {
    _initialization();

    if (!kReleaseMode && (_id != null && _location != null)) {
      StateTracker.setLocation(_id, _location);
    }
  }

  void init();

  bool _initialized = false;

  void _initialization() {
    if (!_initialized) {
      log('ViewModelStateImpl.init');

      init();
      _initialized = true;
    }
  }

  void addDependencyTracker(String notifyId, String dependentId) {
    if (!kReleaseMode) {
      StateTracker.addDependency(notifyId, dependentId);
    }
  }

  void currentTracker() {
    if (!kReleaseMode && _id != null) {
      StateTracker.trackStateChange(_id);
    }
  }

  @override
  void dispose() {
    _initialized = false;
    super.dispose();
  }
}

/// Se usa en las clases Viewmodel donde debe estar toda la logica de mi negocio
abstract class ViewModel<T> extends ChangeNotifier {
  // Internal state
  T _data;
  bool _initialized = false;
  bool _disposed = false;

  // Lifecycle tracking for debugging
  final String _instanceId = UniqueKey().toString();
  DateTime? _initTime;
  int _updateCount = 0;

  ViewModel(this._data) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }

    _safeInitialization();

    assert(() {
      log('''
🔧 ViewModel<${T.toString()}> created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Location: ${_getCreationLocation()}
Initial state hash: ${_data.hashCode}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  /// Public getter for the data
  T get data {
    _checkDisposed();
    return _data;
  }

  /// Abstract init method to be implemented by subclasses
  void init();

  /// Safe initialization that handles errors
  void _safeInitialization() {
    if (_initialized || _disposed) return;

    try {
      init();
      _initialized = true;
      _initTime = DateTime.now();
    } catch (e, stack) {
      assert(() {
        log('''
⚠️ Error during ViewModel<${T.toString()}> initialization
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Error: $e
Stack trace: 
$stack
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 100);
        return true;
      }());
      rethrow;
    }
  }

  /// Reinitialize the ViewModel if it was disposed
  void _reinitializeIfNeeded() {
    if (_disposed) {
      assert(() {
        log('''
🔄 Reinitializing disposed ViewModel<${T.toString()}>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Was disposed for: ${DateTime.now().difference(_disposeTime!).inMilliseconds}ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
        return true;
      }());

      _disposed = false;
      _updateCount = 0;
      _safeInitialization();
    }
  }

  /// Throws if the ViewModel is disposed
  void _checkDisposed() {
    if (_disposed) {
      _reinitializeIfNeeded();
    }
  }

  /// Updates the state and notifies listeners if the value has changed
  void updateState(T newState) {
    _checkDisposed();

    // Skip if state hasn't changed
    if (_data.hashCode == newState.hashCode) {
      assert(() {
        log('''
ℹ️ ViewModel<${T.toString()}> update skipped - state unchanged
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Hash: ${_data.hashCode}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
        return true;
      }());
      return;
    }

    _data = newState;
    _updateCount++;
    notifyListeners();

    assert(() {
      log('''
📝 ViewModel<${T.toString()}> updated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Update #: $_updateCount
New state hash: ${_data.hashCode}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  /// Transforms the state using a function
  void transformState(T Function(T data) transformer) {
    _checkDisposed();

    final newState = transformer(_data);

    // Skip if state hasn't changed
    if (_data.hashCode == newState.hashCode) {
      assert(() {
        log('''
ℹ️ ViewModel<${T.toString()}> transform skipped - state unchanged
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Hash: ${_data.hashCode}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
        return true;
      }());
      return;
    }

    _data = newState;
    _updateCount++;
    notifyListeners();

    assert(() {
      log('''
🔄 ViewModel<${T.toString()}> transformed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Update #: $_updateCount
New state hash: ${_data.hashCode}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  /// Updates the state without notifying listeners
  void updateSilently(T newState) {
    _checkDisposed();
    _data = newState;

    assert(() {
      log('''
🤫 ViewModel<${T.toString()}> updated silently
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
New state hash: ${_data.hashCode}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());
  }

  // Tracks when the ViewModel was disposed
  DateTime? _disposeTime;

  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _disposeTime = DateTime.now();

    assert(() {
      final lifespan = _initTime != null
          ? _disposeTime!.difference(_initTime!).inMilliseconds
          : 'unknown';

      log('''
🗑️ ViewModel<${T.toString()}> disposed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Updates: $_updateCount
Lifespan: ${lifespan}ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    super.dispose();
  }

  /// Gets the creation location for debugging
  String _getCreationLocation() {
    try {
      final stackTrace = StackTrace.current.toString().split('\n');
      final viewModelLine = stackTrace.firstWhere(
        (line) =>
            !line.contains('_getCreationLocation') &&
            !line.contains('ViewModel'),
        orElse: () => 'Unknown location',
      );
      return viewModelLine.trim();
    } catch (e) {
      return 'Error getting location: $e';
    }
  }

  @override
  String toString() {
    return 'ViewModel<$T>(id: $_instanceId, initialized: $_initialized, disposed: $_disposed, updates: $_updateCount)';
  }

  @override
  bool get hasListeners => super.hasListeners;
}
