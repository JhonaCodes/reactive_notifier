import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/helper/helper_notifier.dart';

/// Base ViewModel implementation for handling asynchronous operations with state management.
///
/// Provides a standardized way to handle loading, success, and error states for async data.
///
/// ## Constructor Parameters:
/// - [loadOnInit]: If true (default), automatically calls init() when the ViewModel is created
/// - [waitForContext]: If true (default false), waits for BuildContext to be available before
///   calling init() when loadOnInit is true. The ViewModel stays in initial state until context is ready.
///
/// ## waitForContext Usage:
/// When waitForContext is true:
/// - The ViewModel stays in AsyncState.initial() until BuildContext becomes available
/// - Once context is available, init() is called automatically
/// - Useful for ViewModels that need MediaQuery, Theme, or other context-dependent data
///
/// Example:
/// ```dart
/// class MyViewModel extends AsyncViewModelImpl<MyData> {
///   MyViewModel() : super(AsyncState.initial(), waitForContext: true);
///
///   @override
///   Future<MyData> init() async {
///     // This will only run after BuildContext is available
///     final theme = Theme.of(requireContext('theme access'));
///     return await loadDataBasedOnTheme(theme);
///   }
/// }
/// ```
abstract class AsyncViewModelImpl<T> extends ChangeNotifier
    with HelperNotifier, ViewModelContextService {
  AsyncState<T> _state;
  late bool loadOnInit;
  bool waitForContext = false;
  bool _disposed = false;
  bool _initialized = false;
  bool _initializedWithoutContext = false;

  /// Public getter to check if AsyncViewModel is disposed
  /// Used by ReactiveNotifier to avoid circular dispose calls
  bool get isDisposed => _disposed;

  AsyncViewModelImpl(this._state,
      {this.loadOnInit = true, this.waitForContext = false})
      : super() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }

    if (loadOnInit) {
      if (waitForContext && !hasContext) {
        // Wait for context - stay in initial state
        hasInitializedListenerExecution = false;
      } else {
        // ALWAYS initialize like in main branch - context is optional feature
        _initializeAsync();

        /// Yes and only if it is changed to true when the entire initialization process is finished.
        hasInitializedListenerExecution = true;
      }
    }
  }

  /// Internal initialization method that properly handles async initialization
  Future<void> _initializeAsync() async {
    if (_initialized || _disposed) return;

    /// We make sure it is always false before any full initialization.
    hasInitializedListenerExecution = false;

    try {
      // Setup dependencies BEFORE reload/init so they're available
      await _setupDependencies();

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

      // Mark if we initialized without context for potential reinitialize later
      if (!hasContext) {
        _initializedWithoutContext = true;
      }
    } catch (error, stackTrace) {
      if (!_disposed) {
        errorState(error, stackTrace);
      }
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
        assert(() {
          if (!ReactiveNotifier.debugLogging) return true;
          log('Error on restart listeners: $listenerError');
          return true;
        }());
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
  /// The [transformer] function receives the current ```AsyncState<T>``` and should
  /// return a new ```AsyncState<T>```. This allows for complex state transitions,
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
    final previous = _state;
    _state = transformer(_state);
    notifyListeners();

    // Execute async state change hook
    onAsyncStateChanged(previous, _state);
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
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('⚠️ transformDataState<${T.toString()}> returned null - transformation ignored');
        return true;
      }());
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
    final previous = _state;
    final transformData = transformer(_state.data);

    if (transformData != null) {
      _state = AsyncState.success(transformData);

      // Execute async state change hook (even for silent updates)
      onAsyncStateChanged(previous, _state);
    } else {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('⚠️ transformDataStateSilently<${T.toString()}> returned null - transformation ignored');
        return true;
      }());
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
  /// The [transformer] function receives the current ```AsyncState<T>``` and should
  /// return a new ```AsyncState<T>```.
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
  ///```
  ///
  void transformStateSilently(
      AsyncState<T> Function(AsyncState<T> state) transformer) {
    final previous = _state;
    _state = transformer(_state);

    // Execute async state change hook (even for silent updates)
    onAsyncStateChanged(previous, _state);
  }

  /// Abstract method that returns an empty/clean AsyncState of type T
  /// Can be overridden by subclasses for custom empty state behavior
  ///
  /// Default implementation returns AsyncState.initial()
  AsyncState<T> _createEmptyState() {
    return AsyncState<T>.initial();
  }

  /// Hook that executes automatically after every async state change
  ///
  /// This method is called immediately after the async state is updated via
  /// updateState(), errorState(), loadingState(), transformState(), etc.
  ///
  /// Override this method to:
  /// - Add logging for async state transitions
  /// - Perform automatic actions based on state changes
  /// - Track loading/error patterns
  /// - Update UI indicators or analytics
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onAsyncStateChanged(AsyncState<UserModel> previous, AsyncState<UserModel> next) {
  ///   // Log state transitions
  ///   if (previous.isLoading && next.isSuccess) {
  ///     log('User loaded successfully: ${next.data?.name}');
  ///   }
  ///
  ///   // Handle errors automatically
  ///   if (next.isError) {
  ///     showErrorDialog(next.error.toString());
  ///   }
  ///
  ///   // Analytics tracking
  ///   if (previous.isInitial && next.isLoading) {
  ///     analytics.track('UserLoad_Started');
  ///   }
  /// }
  /// ```
  @protected
  void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next) {
    // Base implementation does nothing
    // Override in subclasses to react to async state changes
  }

  // ─── Dependency tracking for onDependenciesStateChanged ───

  /// Stores the last known snapshot for each dependency.
  final Map<ReactiveNotifier, dynamic> _dependencySnapshots = {};

  /// Stores the listener callback for each dependency (for cleanup).
  final Map<ReactiveNotifier, VoidCallback> _dependencyListeners = {};

  /// Tracks which dependencies have changed since last batch.
  final Set<ReactiveNotifier> _pendingDependencyChanges = {};

  /// Whether a microtask is already scheduled to process the batch.
  bool _dependencyBatchScheduled = false;

  /// Lifecycle hook called when any registered dependency's state changes.
  ///
  /// Override this method to declare dependencies and react to their changes.
  /// Uses [DependencyState.on] to register typed callbacks per dependency.
  ///
  /// **Setup phase** (before `init()`): Registers dependencies, takes snapshots,
  /// and calls each callback with `(current, current)`.
  ///
  /// **Reaction phase** (after dependencies fire): Only calls callbacks for
  /// dependencies that actually changed, with `(previous, current)`.
  /// Multiple dependency changes are batched into a single `notifyListeners()`.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onDependenciesStateChanged(DependencyState change) {
  ///   change.on<UserModel>(UserService.userState, (previous, current) {
  ///     if (previous.id != current.id) {
  ///       reload(); // Re-fetch data for new user
  ///     }
  ///   });
  /// }
  /// ```
  @protected
  void onDependenciesStateChanged(DependencyState change) {
    // Base implementation does nothing.
    // Override in subclasses to declare and react to dependencies.
  }

  /// Sets up dependencies declared in [onDependenciesStateChanged].
  /// Called before [init()] during async initialization.
  Future<void> _setupDependencies() async {
    final state = DependencyState.create(
      isSetup: true,
      changed: {},
      snapshots: _dependencySnapshots,
    );

    // Call hook to register dependencies via change.on<T>()
    onDependenciesStateChanged(state);

    // If no dependencies were registered, nothing else to do
    if (_dependencySnapshots.isEmpty) return;

    // Guarantee initialization of async dependencies
    for (final notifier in _dependencySnapshots.keys.toList()) {
      final value = notifier.notifier;
      if (value is AsyncViewModelImpl && value.data == null) {
        await value.loadNotifier();
        // Re-snapshot with initialized value
        // Re-snapshot: extract value directly
        final val = notifier.notifier;
        if (val is ViewModel) {
          _dependencySnapshots[notifier] = val.data;
        } else if (val is AsyncViewModelImpl) {
          _dependencySnapshots[notifier] = val.data;
        } else {
          _dependencySnapshots[notifier] = val;
        }
      }
    }

    // Subscribe to each registered dependency with batching
    for (final notifier in _dependencySnapshots.keys.toList()) {
      _subscribeToDependency(notifier);
    }
  }

  /// Subscribes to a dependency's changes with microtask batching.
  void _subscribeToDependency(ReactiveNotifier notifier) {
    void listener() {
      _pendingDependencyChanges.add(notifier);
      if (!_dependencyBatchScheduled) {
        _dependencyBatchScheduled = true;
        scheduleMicrotask(_processDependencyBatch);
      }
    }

    _dependencyListeners[notifier] = listener;
    notifier.addListener(listener);
  }

  /// Processes batched dependency changes in a single microtask.
  void _processDependencyBatch() {
    _dependencyBatchScheduled = false;
    if (_disposed || _pendingDependencyChanges.isEmpty) return;

    final state = DependencyState.create(
      isSetup: false,
      changed: Set.from(_pendingDependencyChanges),
      snapshots: _dependencySnapshots,
    );
    _pendingDependencyChanges.clear();

    onDependenciesStateChanged(state);
    notifyListeners(); // Single rebuild for all batched changes
  }

  /// Removes all dependency listeners and clears tracking state.
  void _cleanupDependencies() {
    for (final entry in _dependencyListeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _dependencyListeners.clear();
    _dependencySnapshots.clear();
    _pendingDependencyChanges.clear();
    _dependencyBatchScheduled = false;
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

  }

  /// Update data directly
  void updateState(T data) {
    final previous = _state;
    _state = AsyncState.success(data);
    notifyListeners();

    // Execute async state change hook
    onAsyncStateChanged(previous, _state);
  }

  @protected
  @visibleForTesting
  void loadingState() {
    final previous = _state;
    _state = AsyncState.loading();
    notifyListeners();

    // Execute async state change hook
    onAsyncStateChanged(previous, _state);
  }

  /// Set error state

  void errorState(Object error, [StackTrace? stackTrace]) {
    final previous = _state;
    _state = AsyncState.error(error, stackTrace);
    notifyListeners();

    // Execute async state change hook
    onAsyncStateChanged(previous, _state);
  }

  void cleanState() {
    final previous = _state;
    _state = _createEmptyState();
    unawaited(removeListeners());
    unawaited(_reloadAfterClean());
    notifyListeners();

    // Execute async state change hook
    onAsyncStateChanged(previous, _state);
  }

  Future<void> _reloadAfterClean() async {
    try {
      await init();
      await setupListeners();
    } catch (error, stackTrace) {
      errorState(error, stackTrace);
    }
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
      if (!ReactiveNotifier.debugLogging) return true;
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

  /// Atomic counter for unique listener keys (avoids microsecond collisions)
  static int _listenerCounter = 0;

  /// Holds the currently active listener callbacks.
  /// Maps listener keys to their callback functions for better tracking.
  final Map<String, VoidCallback> _listeners = {};

  /// Starts listening for changes in the ViewModel's asynchronous state.
  ///
  /// This method:
  /// - Creates a unique listener for this specific callback
  /// - Tracks the relationship between listener and listened-to ViewModel
  /// - Returns the current AsyncState allowing the caller to sync with the initial state.
  ///
  /// The [value] callback receives the current ```AsyncState<T>``` whenever the state updates.
  ///
  /// Returns a [Future] that completes with the current state.
  Future<AsyncState<T>> listenVM(void Function(AsyncState<T> data) value,
      {bool callOnInit = false}) async {
    // Create unique key for this listener
    final listenerKey = 'async_vm_${hashCode}_${++_listenerCounter}';

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
🔗 AsyncViewModelImpl<${T.toString()}> adding listener
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Listener key: $listenerKey
Current listeners: ${_listeners.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());

    // Create callback
    void callback() => value(_state);

    // Store listener
    _listeners[listenerKey] = callback;

    // Call on init if requested
    if (callOnInit) {
      callback();
    }

    // Register with ChangeNotifier
    addListener(callback);

    return _state;
  }

  /// Stops listening for changes in the AsyncViewModel.
  ///
  /// Removes all active listeners and clears tracking information.
  /// This helps prevent memory leaks from circular references.
  void stopListeningVM() {
    final listenerCount = _listeners.length;

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
🔌 AsyncViewModelImpl<${T.toString()}> stopping listeners
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Removing listeners: $listenerCount
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());

    // Remove all listeners from ChangeNotifier
    for (final callback in _listeners.values) {
      removeListener(callback);
    }

    // Clear tracking map
    _listeners.clear();
  }

  /// Stops a specific listener by key
  /// Useful for more granular listener management
  void stopSpecificListener(String listenerKey) {
    final callback = _listeners[listenerKey];
    if (callback != null) {
      removeListener(callback);
      _listeners.remove(listenerKey);

      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
🔌 AsyncViewModelImpl<${T.toString()}> stopped specific listener
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Listener key: $listenerKey
Remaining listeners: ${_listeners.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
        return true;
      }());
    }
  }

  /// Get current listener count for debugging
  int get activeListenerCount => _listeners.length;

  @override
  void dispose() {
    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
🗑️ Starting AsyncViewModelImpl<${T.toString()}> disposal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current state: ${_state.runtimeType}
LoadOnInit was: $loadOnInit
HasInitialized: $hasInitializedListenerExecution
Active listeners: ${_listeners.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    // 1. Cleanup dependency listeners from onDependenciesStateChanged
    _cleanupDependencies();

    // 2. Stop internal listenVM() connections to other ViewModels/AsyncViewModels
    stopListeningVM();

    // 3. Remove all external listeners registered via setupListeners()
    removeListeners();

    // 4. Clear async state to help GC
    _state = AsyncState.initial();

    // 5. Reset initialization flags
    hasInitializedListenerExecution = false;
    loadOnInit = true;
    _initialized = false;
    _initializedWithoutContext = false;

    // 6. Mark as disposed
    _disposed = true;

    // 7. Notify ReactiveNotifier to remove this AsyncViewModel from global registry
    _notifyReactiveNotifierDisposal();

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
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

    // 8. Call ChangeNotifier dispose to remove all Flutter listeners
    super.dispose();
  }

  /// Notifies any containing ReactiveNotifier that this AsyncViewModel is being disposed
  /// This allows ReactiveNotifier to clean itself from the global registry
  void _notifyReactiveNotifierDisposal() {
    // Find any ReactiveNotifier that contains this AsyncViewModel instance
    // and request cleanup from global registry (O(1) lookup)
    try {
      final instance = ReactiveNotifier.findByNotifier(this);
      if (instance != null) {
        instance.cleanCurrentNotifier(forceCleanup: true);
      }
    } catch (e) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
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
    // Check if we need to initialize due to waitForContext or previous context-less initialization
    bool shouldReinitialize =
        (_initializedWithoutContext && hasContext && !_disposed) ||
            (waitForContext && !_initialized && hasContext && !_disposed);

    if (shouldReinitialize) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
🔄 AsyncViewModelImpl<${T.toString()}> re-initializing with context
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Context now available: ✓
Wait for context: $waitForContext
Previously initialized without context: $_initializedWithoutContext
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
