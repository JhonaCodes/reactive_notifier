import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/helper/helper_notifier.dart';
import 'package:reactive_notifier/src/context/viewmodel_context_notifier.dart';

/// Base ViewModel implementation for handling asynchronous operations with state management.
///
/// Provides a standardized way to handle loading, success, and error states for async data.

/// Base ViewModel implementation for handling asynchronous operations with state management.
abstract class AsyncViewModelImpl<T> extends ChangeNotifier
    with HelperNotifier, ViewModelContextService {
  AsyncState<T> _state;
  late bool loadOnInit;
  bool _disposed = false;
  bool _initialized = false;
  bool _initializedWithoutContext = false;

  /// Public getter to check if AsyncViewModel is disposed
  /// Used by ReactiveNotifier to avoid circular dispose calls
  bool get isDisposed => _disposed;

  AsyncViewModelImpl(this._state, {this.loadOnInit = false}) : super() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }

    if (loadOnInit) {
      // Only initialize if context is available OR if init() doesn't require context
      if (hasContext) {
        _initializeAsync();
        /// Yes and only if it is changed to true when the entire initialization process is finished.
        hasInitializedListenerExecution = true;
      } else {
        // Mark that we were initialized without context for later reinitialize
        _initializedWithoutContext = true;
        /// Set to false until we get context and can properly initialize
        hasInitializedListenerExecution = false;
        
        // Still try to initialize for backward compatibility with tests
        // and cases where init() doesn't require context
        _initializeAsync();
      }
    }
  }

  /// Internal initialization method that properly handles async initialization
  Future<void> _initializeAsync() async {
    if (_initialized || _disposed) return;

    /// We make sure it is always false before any full initialization.
    hasInitializedListenerExecution = false;

    try {
      // Track if we're initializing without context
      if (!hasContext) {
        _initializedWithoutContext = true;
      }

      await reload();

      // Assert _state is properly initialized
      assert(() {
        try {
          final _ = _state;
          return true;
        } catch (_) {
          throw StateError(
              '⚠️ AsyncViewModelImpl<${T.toString()}> did not properly initialize state in init()');
        }
      }());

      _initialized = true;
      /// Yes and only if it is changed to true when the entire initialization process is finished.
      hasInitializedListenerExecution = true;
    } catch (error, stackTrace) {
      errorState(error, stackTrace);
    }
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

  /// Public method to reload data
  Future<void> reload() async {
    if (_state.isLoading) return;
    try {
      /// If it is the first initialization we do not have listeners to remove.
      if (!loadOnInit) {
        await removeListeners();
      }

      loadOnInit = false;

      loadingState();
      final result = await init();
      updateState(result);

      await setupListeners();

      await onResume(_state.data);
    } catch (error, stackTrace) {
      errorState(error, stackTrace);
      try {
        await setupListeners();
      } catch (listenerError) {
        log('Error on restart listeners: $listenerError');
      }
    }
  }

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

  /// Updates the internal state to a new success state with [newState]
  /// without notifying any listeners.
  ///
  /// This is useful for making internal or test state changes that should not trigger
  /// a UI rebuild or other side effects that listeners might perform.
  /// For example, this might be used during initialization or when applying
  /// changes that will be bundled with a subsequent notification.
  ///
  /// Example:
  ///```dart
  ///     // Inside a ViewModel method, perhaps during setup:
  ///     var initialData = await _repository.fetchInitialData();
  ///     updateSilently(initialData);
  ///     // ... other setup ...
  ///     // A later call to notifyListeners() or a state-updating method that
  ///     // notifies will make this state visible to the UI.
  ///```
  /// - Parameter newState: The new data to set as the successful state.
  ///
  void updateSilently(T newState) {
    _state = AsyncState.success(newState);
  }

  /// Transforms the current entire [AsyncState] using the provided [transformer]
  /// function and notifies listeners.
  ///
  /// The [transformer] function receives the current [AsyncState<T>] and should
  /// return a new [AsyncState<T>]. This allows for complex state transitions,
  /// such as changing from a loading state to an error state, or modifying
  /// data within a success state while preserving the state type.
  ///
  /// After the transformation, listeners are notified of the change.
  ///
  /// Example:
  ///```dart
  ///    // Change state to error if data is null, otherwise keep success
  ///    transformState((currentState) {
  ///       if (currentState.isSuccess && currentState.data == null) {
  ///         return AsyncState.error('Data became null unexpectedly');
  ///       }
  ///       return currentState; // Or modify currentState.data if needed
  ///     });
  ///
  ///     // Transition from a loading state to a success state
  ///     if (_state.isLoading) {
  ///       transformState((_) => AsyncState.success(fetchedData));
  ///     }
  ///
  /// - Parameter transformer: A function that takes the current [AsyncState<T>]
  ///   and returns a new [AsyncState<T>].
  ///```
  ///
  void transformState(AsyncState<T> Function(AsyncState<T> state) transformer) {
    final newState = transformer(_state).data;
    if (newState != null) {
      updateState(newState);
    }
  }

  /// Transforms the data within the current success state using the
  /// provided [transformer] function and notifies listeners.
  ///
  /// If the current state is not a success state, or if the current data is `null`
  /// and the [transformer] cannot handle `null`, the behavior might lead to
  /// unexpected states or errors depending on the [transformer]'s implementation.
  /// It's generally expected that this method is called when `_state.data` is valid
  /// or the [transformer] can gracefully handle `null`.
  ///
  /// The [transformer] function receives the current data `T?` (which might be null
  /// if the state was `AsyncState.success(null)` or if `T` is nullable)
  /// and should return the new data `T`. The state will then be updated to
  /// `AsyncState.success` with this new data.
  ///
  /// After the transformation, listeners are notified.
  ///
  /// Example:
  ///```dart
  ///     // Assuming T is List<String> and _state is AsyncState.success(["apple"])
  ///     // Add an item to the list
  ///     transformDataState((currentData) {
  ///       return [...?currentData, "banana"];
  ///     });
  ///     // _state is now AsyncState.success(["apple", "banana"]) and listeners are notified.
  ///
  ///     // If T is int and _state is AsyncState.success(5)
  ///     transformDataState((currentData) => (currentData ?? 0) + 1);
  ///     // _state is now AsyncState.success(6)
  ///```
  /// - Parameter transformer: A function that takes the current data `T?` from
  ///   a success state and returns the new data `T`.
  void transformDataState(T? Function(T? data) transformer) {
    final transformData = transformer(_state.data);

    if (transformData != null) {
      updateState(transformData);
    } else {
      log('⚠️ transformDataState<${T.toString()}> returned null - transformation ignored');
    }
  }

  /// Transforms the data within the current success state using the
  /// provided [transformer] function, **without notifying listeners**.
  ///
  /// This is the "silent" version of [transformDataState]. It's useful for
  /// making internal changes to the data of a success state that should not
  /// immediately trigger a UI rebuild or other listener-driven side effects.
  ///
  /// Similar to [transformDataState], care should be taken if the current data
  /// is `null` based on the [transformer]'s ability to handle it. The state
  /// will be updated to `AsyncState.success` with the new data.
  ///
  /// Example:
  ///```dart
  ///     // Increment a counter silently
  ///     // Assuming T is int and _state is AsyncState.success(5)
  ///     transformDataStateSilently((currentData) => (currentData ?? 0) + 1);
  ///     // _state is now AsyncState.success(6), but listeners are not notified yet.
  ///```
  /// - Parameter transformer: A function that takes the current data `T?` from
  ///   a success state and returns the new data `T`.
  void transformDataStateSilently(T? Function(T? data) transformer) {
    final transformData = transformer(_state.data);

    if (transformData != null) {
      _state = AsyncState.success(transformData);
    } else {
      log('⚠️ transformDataStateSilently<${T.toString()}> returned null - transformation ignored');
    }
  }

  /// Transforms the current entire [AsyncState] using the provided [transformer]
  /// function, **without notifying listeners**.
  ///
  /// This is the "silent" version of [transformState]. It's useful for
  /// making complex internal state transitions (e.g., from loading to error,
  /// or modifying data within a success state) that should not immediately
  /// trigger a UI rebuild or other listener-driven side effects.
  ///
  /// The [transformer] function receives the current [AsyncState<T>] and should
  /// return a new [AsyncState<T>].
  ///
  /// Example:
  ///```dart
  ///     // Silently change state to error if data is null during an internal check
  ///     transformStateSilently((currentState) {
  ///       if (currentState.isSuccess && currentState.data == null) {
  ///         return AsyncState.error('Internal check: Data became null');
  ///       }
  ///       return currentState;
  ///     });
  ///
  /// - Parameter transformer: A function that takes the current [AsyncState<T>]
  ///   and returns a new [AsyncState<T>].
  ///   ```
  ///
  void transformStateSilently(
      AsyncState<T> Function(AsyncState<T> state) transformer) {
    _state = transformer(_state);
  }

  /// Override this method to provide the async data loading logic
  @protected
  Future<T> init();

  /// Called after the ViewModel's primary initialization logic (e.g., in `init(), setupListeners, etc`)
  /// has completed successfully.
  ///
  /// Override this method in subclasses to perform any tasks that should
  /// execute immediately after the ViewModel is considered fully initialized
  /// and its initial state/data is available.
  ///
  /// This can be useful for setting up secondary listeners, logging completion,
  /// triggering follow-up actions, or starting background tasks that depend
  /// on the initial setup.
  ///
  /// The base implementation simply logs a message.
  ///
  /// Example:
  ///
  @protected
  FutureOr<void> onResume(T? data) async {
    log("Application was initialized and onResume was executed");
  }

  /// Update data directly
  void updateState(T data) {
    _state = AsyncState.success(data);
    notifyListeners();
  }

  @protected
  void loadingState() {
    _state = AsyncState.loading();
    notifyListeners();
  }

  /// Set error state

  void errorState(Object error, [StackTrace? stackTrace]) {
    _state = AsyncState.error(error, stackTrace);
    notifyListeners();
  }

  void cleanState() {
    _state = AsyncState.initial();
    unawaited(removeListeners());
    init();
    unawaited(setupListeners());
    notifyListeners();
  }

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
''', level: 10);
      return true;
    }());

    if (_state.data == null || loadOnInit) {
      await init();
      await setupListeners();
      return;
    }
    return Future.value();
  }

  /// Check if any operation is in progress
  bool get isLoading => _state.isLoading;

  /// Get current error if any
  Object? get error => _state.error;

  /// Get current stack trace if there's an error
  StackTrace? get stackTrace => _state.stackTrace;

  /// Check if the state contains valid data
  bool get hasData => _state.isSuccess;

  /// Get the current data (may be null if not in success state)
  T? get data {
    if (_state.error != null) {
      throw _state.error!;
    }

    return _state.data;
  }

  R match<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function() empty,
    required R Function(Object? err, StackTrace? stackTrace) error,
  }) {
    return _state.match(
      initial: initial,
      loading: loading,
      success: (infoData) => success(infoData),
      empty: empty,
      error: error,
    );
  }

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Object? err, StackTrace? stackTrace) error,
  }) {
    return _state.when(
      initial: initial,
      loading: loading,
      success: (infoData) => success(infoData),
      error: error,
    );
  }

  /// Holds the currently active listener callback.
  /// Ensures only one listener is attached at any given time.
  VoidCallback? _currentListener;

  /// Starts listening for changes in the ViewModel's asynchronous state.
  ///
  /// This method:
  /// - Cancels any previously registered listener to prevent duplication.
  /// - Registers a new listener that invokes the given [value] callback whenever [_state] changes.
  ///
  /// The [value] callback receives the current [AsyncState<T>] whenever the state updates.
  ///
  /// Returns a [Future] that completes once the listener is registered.
  Future<AsyncState<T>> listenVM(void Function(AsyncState<T> data) value,
      {bool callOnInit = false}) async {
    log("Listen notifier is active");

    if (_currentListener != null) {
      removeListener(_currentListener!);
    }

    _currentListener = () => value(_state);

    if (callOnInit) {
      _currentListener?.call();
    }

    addListener(_currentListener!);

    return _state;
  }

  /// Stops listening for changes in the ViewModel.
  ///
  /// If a listener is currently registered, it is removed and
  /// [_currentListener] is set to null to avoid memory leaks.
  void stopListeningVM() {
    if (_currentListener != null) {
      removeListener(_currentListener!);
      _currentListener = null;
    }
  }

  @override
  void dispose() {
    assert(() {
      log('''
🗑️ Starting AsyncViewModelImpl<${T.toString()}> disposal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current state: ${_state.runtimeType}
LoadOnInit was: $loadOnInit
HasInitialized: $hasInitializedListenerExecution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    // 1. Stop internal listenVM() connections to other ViewModels/AsyncViewModels
    stopListeningVM();

    // 2. Remove all external listeners registered via setupListeners()
    removeListeners();

    // 3. Clear async state to help GC
    _state = AsyncState.initial();

    // 4. Reset initialization flags
    hasInitializedListenerExecution = false;
    loadOnInit = true;
    _initialized = false;
    _initializedWithoutContext = false;

    // 5. Mark as disposed
    _disposed = true;

    // 6. Notify ReactiveNotifier to remove this AsyncViewModel from global registry
    _notifyReactiveNotifierDisposal();

    assert(() {
      log('''
✅ AsyncViewModelImpl<${T.toString()}> completely disposed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
State reset to: AsyncState.initial()
Listeners: Removed
ReactiveNotifier cleanup: Requested
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    // 6. Call ChangeNotifier dispose to remove all Flutter listeners
    super.dispose();
  }

  /// Notifies any containing ReactiveNotifier that this AsyncViewModel is being disposed
  /// This allows ReactiveNotifier to clean itself from the global registry
  void _notifyReactiveNotifierDisposal() {
    // Find any ReactiveNotifier that contains this AsyncViewModel instance
    // and request cleanup from global registry
    try {
      final instances = ReactiveNotifier.getInstances;
      for (final instance in instances) {
        if (instance.notifier == this) {
          // Found the ReactiveNotifier containing this AsyncViewModel
          // Use cleanCurrentNotifier with forceCleanup since AsyncViewModel is disposing
          instance.cleanCurrentNotifier(forceCleanup: true);
          break;
        }
      }
    } catch (e) {
      assert(() {
        log('''
⚠️ Warning: Could not notify ReactiveNotifier of AsyncViewModel disposal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AsyncViewModel: ${T.toString()}
Current state: ${_state.runtimeType}
Error: $e

This may result in the ReactiveNotifier remaining in global registry.
Consider calling ReactiveNotifier.cleanup() manually when appropriate.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
        return true;
      }());
    }
  }

  /// Called when context becomes available for the first time
  /// Used to reinitialize ViewModels that were created without context
  void reinitializeWithContext() {
    if (_initializedWithoutContext && hasContext && !_disposed) {
      assert(() {
        log('''
🔄 AsyncViewModelImpl<${T.toString()}> re-initializing with context
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Context now available: ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());
      
      // Reset flags and perform full initialization
      _initializedWithoutContext = false;
      _initialized = false;
      
      // Now perform async initialization with context
      _initializeAsync();
    }
  }
}
