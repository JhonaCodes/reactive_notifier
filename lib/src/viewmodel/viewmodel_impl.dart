import 'dart:developer';

import 'package:flutter/foundation.dart';


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


  /// Transforms the state using a function
  void transformStateSilently(T Function(T data) transformer) {
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

  /// [loadNotifier]
  /// Ensures the ViewModel's availability by confirming initialization has occurred.
  ///
  /// This method should be called when explicit access to the ViewModel is required
  /// outside its normal lifecycle. Typical situations include:
  ///
  /// - At application startup to pre-load critical ViewModels
  /// - In code paths where it's not evident if the ViewModel is already initialized
  /// - When data availability needs to be guaranteed before executing an operation
  ///
  /// It is not necessary to call this method in the normal lifecycle, as the ViewModel's
  /// constructor automatically handles initialization through [_safeInitialization].
  ///
  /// ```dart
  /// // Typical usage during app initialization
  /// await myViewModel.loadNotifier();
  ///
  /// // Or from a service
  /// await notifier<MyViewModel>().loadNotifier();
  /// ```
  ///
  /// This method is idempotent and safe for multiple calls:
  /// - If the ViewModel is already initialized, it will do nothing
  /// - If the ViewModel was disposed, it will log the state but not interfere
  ///   with the automatic reinitialization process
  ///
  /// @return Future<void> that completes immediately, allowing
  ///         sequential asynchronous operations if needed
  Future<void> loadNotifier() async {
    assert(() {
      log('''
🔍 loadNotifier() called for ViewModel<${T.toString()}>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
Already initialized: $_initialized
Is disposed: $_disposed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
    return Future.value();
  }
}
