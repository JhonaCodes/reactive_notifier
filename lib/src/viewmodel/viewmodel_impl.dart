import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/src/helper/helper_notifier.dart';

/// Se usa en las clases Viewmodel donde debe estar toda la logica de mi negocio
abstract class ViewModel<T> extends ChangeNotifier with HelperNotifier {
  // Internal state
  late T _data;
  bool _initialized = false;
  bool _disposed = false;

  // Lifecycle tracking for debugging
  final String _instanceId = UniqueKey().toString();
  DateTime? _initTime;
  int _updateCount = 0;

  ViewModel() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }

    _safeInitialization();

    /// Yes and only if it is changed to true when the entire initialization process is finished.
    hasInitializedListenerExecution = true;

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

  /// [hasInitializedListenerExecution]
  /// When registering the listener from an external function, you must first validate if all the loadData has already been initialized,
  /// to avoid duplication when initializing our listener, because when we create a listener it executes the internal code.
  /// We don't use [loadOnInit], because we need a way to be sure that the entire cycle of our viewmodel has already been executed.
  ///
  /// Create fetch function
  /// ```dart
  /// Future<void> _myFunctionWithFetchForListener() async{
  ///     if (hasInitializedListenerExecution) {
  ///       _reloadDataForListener();
  ///     }
  ///   }
  /// ```
  ///
  /// Register listener
  /// ```dart
  ///   @override
  ///   Future<void> setupListeners()async{
  ///     MyNotifierService.instance.notifier.addListener(_myFunctionWithFetchForListener);
  ///   }
  /// ```
  ///
  bool hasInitializedListenerExecution = false;

  /// [removeListeners]
  /// We remove the listeners registered in [setupListeners] to avoid memory problems.
  ///
  @mustCallSuper
  Future<void> removeListeners(
      {List<String> currentListeners = const []}) async {
    if (currentListeners.isNotEmpty) {
      assert(() {
        logRemove<T>(listeners: currentListeners);
        return true;
      }());
    }
  }

  /// [setupListeners]
  /// We register our listeners coming from the notifiers.
  ///
  @mustCallSuper
  Future<void> setupListeners(
      {List<String> currentListeners = const []}) async {
    if (currentListeners.isNotEmpty) {
      assert(() {
        logSetup<T>(listeners: currentListeners);
        return true;
      }());
    }
  }

  /// Abstract method that returns an empty/clean state of type T
  /// Must be implemented by subclasses
  T _createEmptyState();

  /// Public getter for the data
  T get data {
    _checkDisposed();
    assertDataInitialized();
    return _data;
  }


  void assertDataInitialized() {
    assert(() {
      if (!_initialized) {
        throw StateError("ViewModel<${T.toString()}> was used before _data was initialized.");
      }
      return true;
    }());
  }

  /// This method must be implemented as fully synchronous.
  /// Do not use `async` or return a `Future<void>`.
  ///
  /// The base `ViewModel` does not handle asynchronous processes.
  /// Using `async` here can lead to uncontrolled rebuilds or race conditions,
  /// since asynchronous initialization is not managed by the ViewModel's lifecycle.
  ///
  /// If you need to perform asynchronous operations during initialization,
  /// use `AsyncViewModelImpl` instead of `ViewModel`.
  ///
  void init();

  /// Safe initialization that handles errors
  void _safeInitialization() {
    // We make sure it is always false before any full initialization.
    hasInitializedListenerExecution = false;

    if (_initialized || _disposed) return;

    try {
      init();

      // Ensure _data was assigned in init()
      assert(() {
        try {
          final _ = _data;
          return true;
        } catch (_) {
          throw StateError('''
⚠️ ViewModel<${T.toString()}> initialization error
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The init() method did not assign an initial state to the internal _data variable.
It is mandatory to call updateSilently(...) or assign _data before finishing init().

This ensures the ViewModel has a valid state and prevents subsequent errors.

Check the init() implementation at: ${_getCreationLocation()}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
        }
      }());

      _initialized = true;
      _initTime = DateTime.now();

      unawaited(setupListeners());
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
    removeListeners();
    stopListeningVM();

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
  /// @return [Future] that completes immediately, allowing
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

  /// Cleans the state to allow garbage collection without calling dispose
  void cleanState() {
    _checkDisposed();

    unawaited(removeListeners());

    final emptyState = _createEmptyState();

    // Update to the empty state
    updateState(emptyState);

    assert(() {
      log('''
🧹 ViewModel<${T.toString()}> state cleaned
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: $_instanceId
New empty state hash: ${_data.hashCode}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  Future<void> reload() async {
    try {
      if (_initialized) {
        await removeListeners();
      }

      init();
      await setupListeners();
    } catch (error, stackTrace) {
      log(error.toString());
      log(stackTrace.toString());
      try {
        await setupListeners();
      } catch (listenerError) {
        log('Error on restart listeners: $listenerError');
      }
    }
  }

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
  T listenVM(void Function(T data) value) {
    log("Listen notifier is active");

    if (_currentListener != null) {
      removeListener(_currentListener!);
    }

    _currentListener = () => value(_data);
    addListener(_currentListener!);

    return _data;
  }

  /// Stops listening for changes in the ViewModel.
  ///
  /// If a listener is currently registered, it will be removed and
  /// [_currentListener] will be set to null to free up resources.
  void stopListeningVM() {
    if (_currentListener != null) {
      removeListener(_currentListener!);
      _currentListener = null;
    }
  }
}
