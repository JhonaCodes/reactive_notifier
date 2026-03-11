import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'notifier_impl.dart';
import '../context/reactive_context_enhanced.dart';
import '../context/viewmodel_context_notifier.dart';

/// A reactive state management solution that supports:
/// - Singleton instances with key-based identity
/// - Related states management
/// - Circular reference detection
/// - Notification overflow detection
/// - Detailed debug logging
class ReactiveNotifier<T> extends NotifierImpl<T> {
  /// Controls debug logging for all ReactiveNotifier components.
  /// Only affects debug builds (assert blocks). Defaults to true in debug mode.
  /// Set to `false` to suppress all ReactiveNotifier debug logs.
  ///
  /// ```dart
  /// void main() {
  ///   ReactiveNotifier.debugLogging = false; // Silence all debug logs
  ///   runApp(MyApp());
  /// }
  /// ```
  static bool debugLogging = true;

  // Singleton management
  static final HashMap<Key, dynamic> _instances = HashMap.from({});

  // Relations management
  final List<ReactiveNotifier>? related;
  final Set<ReactiveNotifier> _parents = {};
  static final Set<ReactiveNotifier> _updatingNotifiers = {};
  final Key keyNotifier;

  // Notification overflow detection
  static const _notificationThreshold = 50;
  static const _thresholdTimeWindow = Duration(milliseconds: 500);
  DateTime? _firstNotificationTime;
  int _notificationCount = 0;

  // Widget-aware lifecycle management
  final bool autoDispose;
  int _referenceCount = 0;
  Timer? _disposeTimer;
  Duration _autoDisposeTimeout = const Duration(seconds: 30);
  bool _isScheduledForDispose = false;
  bool _disposed = false;

  // Reference tracking for debugging
  final Set<String> _activeReferences = <String>{};
  static final Map<Key, ReactiveNotifier> _instanceRegistry =
      <Key, ReactiveNotifier>{};

  // O(1) reverse lookup: maps notifier value identity -> ReactiveNotifier container
  static final Map<int, ReactiveNotifier> _notifierToInstance = {};


  // Factory function storage for recreate() functionality
  final T Function() _createFunction;

  // Recreation guard to prevent infinite loops during ViewModel initialization
  bool _isRecreating = false;

  ReactiveNotifier._(
      T Function() create, this.related, this.keyNotifier, this.autoDispose)
      : _createFunction = create,
        super(create()) {
    if (related != null) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
🔍 Setting up relations for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''', level: 10);
        return true;
      }());

      _validateCircularReferences(this);
      related?.forEach((child) {
        child._parents.add(this);
        assert(() {
          if (!ReactiveNotifier.debugLogging) return true;
          log('➕ Added parent-child relation: $T -> ${child.notifier.runtimeType}',
              level: 10);
          return true;
        }());
      });
    }
  }

  /// Creates or returns existing instance of ReactiveNotifier
  ///
  /// Parameters:
  /// - [create]: Function that creates the initial state
  /// - [related]: Optional list of related states
  /// - [key]: Optional key for instance identity
  factory ReactiveNotifier(T Function() create,
      {List<ReactiveNotifier>? related, Key? key, bool autoDispose = false}) {
    key ??= UniqueKey();

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
📦 Creating ReactiveNotifier<$T>
${related != null ? '🔗 With related types: ${related.map((r) => r.notifier.runtimeType).join(', ')}' : ''}
''', level: 5);
      return true;
    }());

    if (_instances.containsKey(key)) {
      final trace = StackTrace.current.toString().split('\n')[1];
      throw StateError('''
⚠️ Invalid Reference Structure Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Notifier: $T
Key: $key
Problem: Attempting to create a notifier with an existing key, which could lead to circular dependencies or duplicate instances.
Solution: Ensure that each notifier has a unique key or does not reference itself directly.
Location: $trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
    }

    try {
      final instance = ReactiveNotifier._(create, related, key, autoDispose);
      _instances[key] = instance;
      _instanceRegistry[key] = instance;
      _notifierToInstance[identityHashCode(instance.notifier)] = instance;
    } catch (e) {
      if (e is StateError) {
        rethrow;
      }
      final trace = StackTrace.current.toString().split('\n')[1];
      throw StateError('''
⚠️ ReactiveNotifier Creation Failed!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: $T
Error: $e

🔍 Check:
   - Related states configuration
   - Initial value creation
   - Type consistency
Location: $trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
    }

    return _instances[key] as ReactiveNotifier<T>;
  }

  /// Convenience factory for auto-dispose singletons.
  ///
  /// Prefer this when you want singleton-like state that should be
  /// automatically cleaned up when unused.
  static ReactiveNotifier<T> createAutoDispose<T>(T Function() create,
      {List<ReactiveNotifier>? related, Key? key, Duration? timeout}) {
    final instance = ReactiveNotifier<T>(
      create,
      related: related,
      key: key,
      autoDispose: true,
    );

    if (timeout != null) {
      instance.enableAutoDispose(timeout: timeout);
    }

    return instance;
  }

  @override
  void updateState(T newState) {
    if (notifier != newState) {
      // Prevent circular update
      if (_updatingNotifiers.contains(this)) {
        return;
      }

      // Check for possible notification overflow
      _checkNotificationOverflow();

      log('📝 Updating state for $T: $notifier -> ${newState.runtimeType}',
          level: 10);

      _updatingNotifiers.add(this);

      try {
        // Update value and notify
        super.updateState(newState);

        // Notify parents if they exist
        if (_parents.isNotEmpty) {
          assert(() {
            if (!ReactiveNotifier.debugLogging) return true;
            log('📤 Notifying parent states for $T', level: 10);
            return true;
          }());

          for (var parent in _parents) {
            if (!parent._disposed) {
              parent.notifyListeners();
            }
          }
        }
      } finally {
        _updatingNotifiers.remove(this);
      }
    }
  }

  @override
  void updateSilently(T newState) {
    if (notifier != newState) {
      // Prevent circular update
      if (_updatingNotifiers.contains(this)) {
        return;
      }

      // Check for possible notification overflow
      _checkNotificationOverflow();

      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('📝 Updating state silently for $T: $notifier -> ${newState.runtimeType}',
            level: 10);
        return true;
      }());

      _updatingNotifiers.add(this);

      try {
        // Update value without notifying (truly silent - no parent notifications)
        super.updateSilently(newState);
      } finally {
        _updatingNotifiers.remove(this);
      }
    }
  }

  @override
  void transformStateSilently(T Function(T data) transform) {
    // Prevent circular update
    if (_updatingNotifiers.contains(this)) {
      return;
    }

    // Check for possible notification overflow
    _checkNotificationOverflow();

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('🔄 Transforming state silently for $T', level: 10);
      return true;
    }());

    _updatingNotifiers.add(this);

    try {
      // Transform state without notifying (truly silent - no parent notifications)
      super.transformStateSilently(transform);
    } finally {
      _updatingNotifiers.remove(this);
    }
  }

  @override
  void transformState(T Function(T data) data) {
    // Prevent circular update
    if (_updatingNotifiers.contains(this)) {
      return;
    }

    // Check for possible notification overflow
    _checkNotificationOverflow();

    log('🔄 Transforming state for $T', level: 10);

    _updatingNotifiers.add(this);

    try {
      // Transform state and notify
      super.transformState(data);

      // Notify parents if they exist
      if (_parents.isNotEmpty) {
        assert(() {
          if (!ReactiveNotifier.debugLogging) return true;
          log('📤 Notifying parent states for $T', level: 10);
          return true;
        }());

        for (var parent in _parents) {
          if (!parent._disposed) {
            parent.notifyListeners();
          }
        }
      }
    } finally {
      _updatingNotifiers.remove(this);
    }
  }

  /// Checks for potential notification overflow
  /// Throws assertion error if too many notifications occur in a short time window
  void _checkNotificationOverflow() {
    final now = DateTime.now();

    if (_firstNotificationTime == null) {
      _firstNotificationTime = now;
      _notificationCount = 1;
      return;
    }

    if (now.difference(_firstNotificationTime!) < _thresholdTimeWindow) {
      _notificationCount++;

      if (_notificationCount >= _notificationThreshold) {
        assert(() {
          if (!ReactiveNotifier.debugLogging) return true;
          log('''
⚠️ Notification Overflow Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Notifier: ${describeIdentity(this)}
Type: $T
Current Value: $notifier
Location: ${StackTrace.current}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$_notificationCount notifications in ${_thresholdTimeWindow.inMilliseconds}ms

❌ Problem:
   Excessive notifications may indicate:
   - setState calls in build methods
   - Infinite update loops
   - Uncontrolled rapid updates

✅ Solution:
   - Check for setState in build methods
   - Verify update logic
   - Consider debouncing rapid updates
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 100);
          return true;
        }());
      }
    } else {
      _firstNotificationTime = now;
      _notificationCount = 1;
    }
  }

  // Private methods for formatting and validation
  String _getLocationInfo() {
    try {
      final frames = StackTrace.current.toString().split('\n');

      // We look for the first frame that is not from reactive_notifier.dart
      final relevantFrame = frames.firstWhere(
        (frame) => !frame.contains('reactive_notifier.dart'),
        orElse: () => frames.first,
      );

      // Extract relevant information from the frame
      final pattern = RegExp(r'package:([^/]+)/(.+)\.dart[: ](\d+)(?::(\d+))?');
      final match = pattern.firstMatch(relevantFrame);

      if (match != null) {
        final package = match.group(1);
        final file = match.group(2);
        final line = match.group(3);
        final column = match.group(4);

        return '''
📍 Location:
   Package: $package
   File: $file.dart
   Line: $line${column != null ? ', Column: $column' : ''}''';
      }
      return '📍 Location: $relevantFrame';
    } catch (e) {
      return '📍 Location: Unable to determine';
    }
  }

  String _formatNotifierInfo(ReactiveNotifier notifier) {
    return '''
   Type: ${notifier.notifier.runtimeType}
   Value: ${notifier.notifier}
   Key: ${notifier.keyNotifier}''';
  }

  void _collectAncestors(ReactiveNotifier node, Set<Key> ancestorKeys) {
    if (node.related == null) return;
    for (final related in node.related!) {
      ancestorKeys.add(related.keyNotifier);
      _collectAncestors(related, ancestorKeys);
    }
  }

  void _validateNodeReferences(
    ReactiveNotifier node,
    Set<Key> pathKeys,
    Set<Key> ancestorKeys,
  ) {
    if (node.related == null) return;

    for (final child in node.related!) {
      if (pathKeys.contains(child.keyNotifier)) {
        _throwCircularReferenceError(node, child, pathKeys);
      }

      if (ancestorKeys.contains(child.keyNotifier)) {
        _throwAncestorReferenceError(node, child, pathKeys, ancestorKeys);
      }

      pathKeys.add(child.keyNotifier);
      _validateNodeReferences(child, pathKeys, ancestorKeys);
      pathKeys.remove(child.keyNotifier);
    }
  }

  Never _throwCircularReferenceError(
    ReactiveNotifier node,
    ReactiveNotifier child,
    Set<Key> pathKeys,
  ) {
    final cycle = [...pathKeys, child.keyNotifier]
        .map((key) => '${_instances[key]?.notifier.runtimeType}($key)')
        .join(' -> ');

    throw StateError('''
⚠️ Circular Reference Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${_getLocationInfo()}

🔄 Dependency Cycle:
   $cycle

📦 Current Notifier:
${_formatNotifierInfo(node)}

🔗 Problematic Child Notifier:
${_formatNotifierInfo(child)}

❌ Problem: 
   A circular dependency was detected in your state relationships.
   This creates an infinite loop in the following chain:
   $cycle

✅ Solution:
   1. Review the state dependencies at the location shown above
   2. Ensure your states form a directed acyclic graph (DAG)
   3. Consider these alternatives:
      - Use a parent state to manage related states
      - Implement unidirectional data flow
      - Split the circular dependency into separate state trees

💡 Debug Info:
   Total states in chain: ${pathKeys.length + 1}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
  }

  Never _throwAncestorReferenceError(
    ReactiveNotifier node,
    ReactiveNotifier child,
    Set<Key> pathKeys,
    Set<Key> ancestorKeys,
  ) {
    throw StateError('''
⚠️ Invalid Reference Structure Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${_getLocationInfo()}

📦 Current Notifier:
${_formatNotifierInfo(node)}

🔗 Ancestor Notifier Being Referenced:
${_formatNotifierInfo(child)}

❌ Problem: 
   Attempting to reference an ancestor state, which would create
   a circular dependency in your state management tree.

✅ Solution:
   1. Review the state relationships at the location shown above
   2. Avoid referencing ancestor states
   3. Consider these alternatives:
      - Create a new parent state to manage both states
      - Use a different state management pattern
      - Implement unidirectional data flow

💡 Debug Info:
   Current chain depth: ${pathKeys.length}
   Total ancestors: ${ancestorKeys.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
  }

  void _validateCircularReferences(ReactiveNotifier root) {
    final pathKeys = <Key>{};
    final ancestorKeys = <Key>{};

    // Collect ancestors
    if (root.related != null) {
      for (final related in root.related!) {
        _collectAncestors(related, ancestorKeys);
      }
    }

    // Validate references
    pathKeys.add(root.keyNotifier);
    _validateNodeReferences(root, pathKeys, ancestorKeys);
    pathKeys.remove(root.keyNotifier);
  }

  /// Gets a related state by type
  R from<R>([Key? key]) {
    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('🔍 Getting related state of type $R from $T${key != null ? ' with key: $key' : ''}',
          level: 10);
      return true;
    }());

    if (related == null || related!.isEmpty) {
      throw StateError('''
❌ No Related States Found
━━━━━━━━━━━━━━━━━━━━━
Parent type: $T
Requested type: $R${key != null ? '\nRequested key: $key' : ''}
━━━━━━━━━━━━━━━━━━━━━
''');
    }

    final result = key != null
        ? related!.firstWhere(
            (n) => n.notifier is R && n.keyNotifier == key,
            orElse: () => throw StateError('''
❌ Related State Not Found
━━━━━━━━━━━━━━━━━━━━━
Looking for: $R with key: $key
Parent type: $T
Available types: ${related!.map((r) => '${r.notifier.runtimeType}(${r.keyNotifier})').join(', ')}
━━━━━━━━━━━━━━━━━━━━━
'''),
          )
        : related!.firstWhere(
            (n) => n.notifier is R,
            orElse: () => throw StateError('''
❌ Related State Not Found
━━━━━━━━━━━━━━━━━━━━━
Looking for: $R
Parent type: $T
Available types: ${related!.map((r) => '${r.notifier.runtimeType}(${r.keyNotifier})').join(', ')}
━━━━━━━━━━━━━━━━━━━━━
'''),
          );

    return result.notifier as R;
  }

  /// Widget-aware lifecycle management methods

  /// Increment reference count when a widget starts using this notifier
  void addReference(String referenceId) {
    // Only increment if this is a new reference
    if (_activeReferences.add(referenceId)) {
      _referenceCount++;
    }

    // Cancel auto-dispose if scheduled
    if (_isScheduledForDispose) {
      _disposeTimer?.cancel();
      _disposeTimer = null;
      _isScheduledForDispose = false;

      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
🔄 Auto-dispose cancelled for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reference added: $referenceId
Active references: $_referenceCount
Reason: New widget started using this notifier
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());
    }

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
➕ Reference added to ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reference: $referenceId
Total references: $_referenceCount
Auto-dispose enabled: $autoDispose
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());
  }

  /// Decrement reference count when a widget stops using this notifier
  void removeReference(String referenceId) {
    // Only decrement if reference actually existed
    if (_activeReferences.remove(referenceId)) {
      _referenceCount--;
    }

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
➖ Reference removed from ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reference: $referenceId
Remaining references: $_referenceCount
Auto-dispose enabled: $autoDispose
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());

    // Schedule auto-dispose if no more references and auto-dispose is enabled
    if (_referenceCount <= 0 && autoDispose && !_isScheduledForDispose) {
      _scheduleAutoDispose();
    }
  }

  /// Checks if the internal ViewModel/AsyncViewModel has active listenVM() subscribers.
  /// This bridges the gap between the ReactiveNotifier container (ChangeNotifier #1)
  /// and the ViewModel value (ChangeNotifier #2) for cleanup safety.
  bool _hasInternalViewModelListeners() {
    final value = notifier;
    if (value is ViewModel && value.activeListenerCount > 0) return true;
    if (value is AsyncViewModelImpl && value.activeListenerCount > 0) return true;
    return false;
  }

  /// Schedule automatic disposal after timeout
  void _scheduleAutoDispose() {
    if (_isScheduledForDispose || _disposed) return;

    _isScheduledForDispose = true;
    _disposeTimer = Timer(_autoDisposeTimeout, () {
      if (_referenceCount <= 0 && autoDispose && !_disposed) {
        // Guard: Don't dispose if the internal ViewModel has active listenVM() subscribers
        if (_hasInternalViewModelListeners()) {
          _isScheduledForDispose = false;
          assert(() {
            if (!ReactiveNotifier.debugLogging) return true;
            log('[ReactiveNotifier] Auto-dispose deferred for <$T>: '
                'ViewModel has active listenVM() subscribers.', level: 10);
            return true;
          }());
          return;
        }
        assert(() {
          if (!ReactiveNotifier.debugLogging) return true;
          log('''
🗑️ Auto-disposing ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
Timeout: ${_autoDisposeTimeout.inSeconds}s
Final reference count: $_referenceCount
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
          return true;
        }());

        cleanCurrentNotifier(forceCleanup: true);
      }
      _isScheduledForDispose = false;
    });

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
⏰ Auto-dispose scheduled for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Timeout: ${_autoDisposeTimeout.inSeconds}s
Current references: $_referenceCount
Will dispose if no references are added
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  /// Configure auto-dispose timeout for this instance
  void enableAutoDispose({Duration? timeout}) {
    if (timeout != null) {
      _autoDisposeTimeout = timeout;
    }

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
⚙️ Auto-dispose configured for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Timeout: ${_autoDisposeTimeout.inSeconds}s
Current references: $_referenceCount
Will auto-dispose when references reach 0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  /// Get current reference count (for debugging)
  int get referenceCount => _referenceCount;

  /// Check if instance is scheduled for dispose
  bool get isScheduledForDispose => _isScheduledForDispose;

  /// Get active references (for debugging)
  Set<String> get activeReferences => Set.from(_activeReferences);

  /// Static methods for instance management

  /// Reinitialize a disposed instance with a fresh state
  ///
  /// This method allows you to recreate an instance that was previously disposed,
  /// maintaining the same key and configuration but with a fresh state.
  ///
  /// Use cases:
  /// - After logout to create fresh user state
  /// - Reset application state to initial values
  /// - Recovery from corrupted state
  /// - Testing scenarios where clean state is needed
  ///
  /// Example:
  /// ```dart
  /// mixin UserService {
  ///   static final instance = ReactiveNotifier<UserViewModel>(() => UserViewModel());
  ///
  ///   static void logout() {
  ///     ReactiveNotifier.reinitializeInstance<UserViewModel>(
  ///       instance.keyNotifier,
  ///       () => UserViewModel()
  ///     );
  ///   }
  /// }
  /// ```
  static T reinitializeInstance<T>(Key key, T Function() creator) {
    if (!_instances.containsKey(key)) {
      throw StateError('''
❌ Cannot reinitialize - instance not found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $key
Type: $T
Available instances: ${_instances.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
    }

    final instance = _instances[key] as ReactiveNotifier<T>;

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
🔄 Reinitializing ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $key
Was disposed: ${instance._disposed}
Current references: ${instance._referenceCount}
Creating fresh state...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    // Cancel any pending auto-dispose
    instance._disposeTimer?.cancel();
    instance._disposeTimer = null;
    instance._isScheduledForDispose = false;

    // Reset dispose flag
    instance._disposed = false;

    // Create fresh state
    final newState = creator();

    // Update the internal state
    try {
      if (instance.notifier is ViewModel) {
        // For ViewModels, dispose old one first if not already disposed
        final oldVM = instance.notifier as ViewModel;
        if (!oldVM.isDisposed) {
          oldVM.dispose();
        }
      } else if (instance.notifier is AsyncViewModelImpl) {
        // For AsyncViewModels, dispose old one first if not already disposed
        final oldAsyncVM = instance.notifier as AsyncViewModelImpl;
        if (!oldAsyncVM.isDisposed) {
          oldAsyncVM.dispose();
        }
      }
    } catch (e) {
      // If disposal fails, log but continue with replacement
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
⚠️ Warning during old ViewModel disposal in reinitializeInstance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Error: $e
Continuing with state replacement...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
        return true;
      }());
    }

    // Replace with new state
    instance.replaceNotifier(newState);

    // Notify listeners of the fresh state
    instance.notifyListeners();

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
✅ ReactiveNotifier<$T> successfully reinitialized
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $key
New state hash: ${newState.hashCode}
Active references: ${instance._referenceCount}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    return newState;
  }

  /// Check if an instance with the given key is active (not disposed)
  ///
  /// Returns `true` if the instance exists and is not disposed,
  /// `false` if the instance doesn't exist or is disposed.
  ///
  /// Example:
  /// ```dart
  /// if (ReactiveNotifier.isInstanceActive<UserViewModel>(userKey)) {
  ///   // Instance is active, safe to use
  ///   final user = UserService.instance.notifier;
  /// } else {
  ///   // Instance is disposed or doesn't exist
  ///   UserService.initializeUser();
  /// }
  /// ```
  static bool isInstanceActive<T>(Key key) {
    if (!_instances.containsKey(key)) {
      return false;
    }

    final instance = _instances[key] as ReactiveNotifier<T>?;
    return instance != null && !instance._disposed;
  }

  /// Replace the internal notifier with a new instance
  /// Used by reinitializeInstance to update the internal state
  void replaceNotifier(T newNotifier) {
    // Update reverse lookup map
    _notifierToInstance.remove(identityHashCode(notifier));
    _notifierToInstance[identityHashCode(newNotifier)] = this;

    // This is a protected method that updates the internal state
    // It's used internally by reinitializeInstance
    updateSilently(newNotifier);
  }

  /// Global cleanup flag to prevent concurrent modifications during cleanup
  static bool _isGlobalCleanupInProgress = false;

  /// Garbage collect unused auto-dispose instances.
  ///
  /// Cleans instances that: have no references, no listeners, no parents,
  /// and are marked autoDispose. Returns the number of instances cleaned.
  static int garbageCollectUnused() {
    if (_isGlobalCleanupInProgress) {
      return 0;
    }

    int cleaned = 0;

    // Work on a copy to avoid concurrent modification.
    final instancesList = _instances.values.toList();
    for (final instance in instancesList) {
      if (instance is ReactiveNotifier) {
        if (!instance._disposed &&
            instance.autoDispose &&
            instance.referenceCount <= 0 &&
            !instance.hasListeners &&
            instance._parents.isEmpty &&
            !instance._hasInternalViewModelListeners()) {
          final ok = instance.cleanCurrentNotifier();
          if (ok) cleaned++;
        }
      }
    }

    return cleaned;
  }

  /// Utility methods
  static void cleanup() {
    if (_isGlobalCleanupInProgress) {
      return; // Already cleaning up, avoid recursive calls
    }

    _isGlobalCleanupInProgress = true;
    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
🧹 Starting global ReactiveNotifier cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total instances before cleanup: ${_instances.length}
Updating notifiers: ${_updatingNotifiers.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    // 1. Dispose all ViewModels and AsyncViewModels properly before clearing registry
    int viewModelsDisposed = 0;
    int asyncViewModelsDisposed = 0;
    int simpleNotifiersCleared = 0;

    // Create a copy of the instances to avoid concurrent modification
    final instancesList = _instances.values.toList();
    for (final instance in instancesList) {
      if (instance is ReactiveNotifier) {
        final vm = instance.notifier;
        try {
          // Cancel any pending dispose timers
          instance._disposeTimer?.cancel();
          instance._disposeTimer = null;
          instance._isScheduledForDispose = false;
          instance._disposed = true;

          if (vm is ViewModel && !vm.isDisposed) {
            vm.dispose();
            viewModelsDisposed++;
          } else if (vm is AsyncViewModelImpl && !vm.isDisposed) {
            vm.dispose();
            asyncViewModelsDisposed++;
          } else {
            // Simple notifier (not ViewModel)
            simpleNotifiersCleared++;
          }
        } catch (e) {
          assert(() {
            if (!ReactiveNotifier.debugLogging) return true;
            log('''
⚠️ Error disposing ViewModel during cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ViewModel type: ${vm.runtimeType}
Error: $e
Continuing with cleanup...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
            return true;
          }());
        }
      }
    }

    // 2. Clear all global registries
    _instances.clear();
    _updatingNotifiers.clear();
    _instanceRegistry.clear();
    _notifierToInstance.clear();

    // 3. Clear ReactiveContext registries
    try {
      ReactiveContextEnhanced.cleanup();
      cleanupPreservedWidgets();
    } catch (e) {
      // Ignore cleanup errors - may not be available in all contexts
    }

    // 4. Clear ViewModelContextNotifier
    try {
      ViewModelContextNotifier.cleanup();
    } catch (e) {
      // Ignore cleanup errors
    }

    // Reset cleanup flag
    _isGlobalCleanupInProgress = false;

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
✅ Global ReactiveNotifier cleanup completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ViewModels disposed: $viewModelsDisposed
AsyncViewModels disposed: $asyncViewModelsDisposed  
Simple notifiers cleared: $simpleNotifiersCleared
Total instances processed: ${viewModelsDisposed + asyncViewModelsDisposed + simpleNotifiersCleared}

Global registries cleared:
- _instances: ${_instances.isEmpty ? '✓' : '✗ (${_instances.length} remaining)'}
- _updatingNotifiers: ${_updatingNotifiers.isEmpty ? '✓' : '✗ (${_updatingNotifiers.length} remaining)'}
- _instanceRegistry: ${_instanceRegistry.isEmpty ? '✓' : '✗ (${_instanceRegistry.length} remaining)'}

All memory should now be available for garbage collection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  R? getStateByKey<R>(Key key) {
    if (_instances.containsKey(key)) {
      return (_instances[key]! as ReactiveNotifier<R>).notifier;
    }
    return null;
  }

  static int get instanceCount => _instances.length;

  static int instanceCountByType<S>() {
    return _instances.values.whereType<ReactiveNotifier<S>>().length;
  }

  /// Attempts to remove the current instance from the global registry if it's not being used.
  ///
  /// This method will only clean up the instance if:
  /// - It has no active listeners
  /// - It's not being referenced by other notifiers
  ///
  /// If the instance cannot be cleaned, detailed diagnostic information will be provided
  /// about what's preventing the cleanup.
  ///
  /// Returns `true` if the instance was cleaned, `false` if it's still in use.
  ///
  /// [forceCleanup] - If true, cleanup will be performed regardless of listeners or parent references
  /// This is used when ViewModels call dispose() and need to force registry cleanup
  bool cleanCurrentNotifier({bool forceCleanup = false}) {
    // Skip cleanup if global cleanup is in progress to avoid concurrent modification
    if (_isGlobalCleanupInProgress) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
🔄 Skipping cleanCurrentNotifier during global cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: $T
Reason: Global cleanup is already handling this instance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());
      return true; // Pretend it was cleaned successfully
    }

    // Check if it has listeners (unless force cleanup)
    if (hasListeners && !forceCleanup) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        final trace = StackTrace.current.toString().split('\n')[1];
        log('''
⚠️ Cannot clean ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
Reason: Still has active listeners.
${_getLocationInfo()}

🔍 Recommended actions:
   - Ensure all widgets using this notifier are disposed
   - Verify that there are no listeners added without being removed
   - Use removeListener() for all registered listeners
   - Or call cleanCurrentNotifier(forceCleanup: true) to force cleanup

Location of cleanup request: $trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 100);
        return true;
      }());
      return false;
    }

    // Check if it has parents (notifiers referencing it) (unless force cleanup)
    if (_parents.isNotEmpty && !forceCleanup) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        final parentInfo = _parents.map((parent) => '''
   - ${parent.notifier.runtimeType} (${parent.keyNotifier})
     ${_getParentLocationInfo(parent)}''').join('\n');

        final trace = StackTrace.current.toString().split('\n')[1];
        log('''
⚠️ Cannot clean ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
Reason: Being referenced by other notifiers.

🔗 Active references:
$parentInfo

🔍 Recommended actions:
   - First clean the notifiers that reference this one
   - Or use ReactiveNotifier.cleanup() to clean the entire registry
   - Or call cleanCurrentNotifier(forceCleanup: true) to force cleanup

Location of cleanup request: $trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 100);
        return true;
      }());
      return false;
    }

    // Force cleanup mode: Stop listeners and clean relationships
    if (forceCleanup) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
Force cleanup mode enabled for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
Active listeners: $hasListeners
Parent references: ${_parents.length}
Child relationships: ${related?.length ?? 0}
Cleaning regardless of current state...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());

      // Stop all listeners in force mode
      if (hasListeners) {
        stopListening();
      }

      // Clean parent-child relationships
      if (related != null) {
        for (var child in related!) {
          child._parents.remove(this);
        }
      }
      _parents.clear();
    }

    // If it is safe to clean this instance (check isDisposed to prevent double disposal)
    if (notifier is ViewModel && !(notifier as ViewModel).isDisposed) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
ℹ️ Propagating dispose to ViewModel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: ${notifier.runtimeType}
Key: $keyNotifier
This will release any resources held by the ViewModel (timers, streams, etc.)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());

      (notifier as ViewModel).dispose();
    } else if (notifier is AsyncViewModelImpl && !(notifier as AsyncViewModelImpl).isDisposed) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
ℹ️ Propagating dispose to AsyncViewModelImpl
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: ${notifier.runtimeType}
Key: $keyNotifier
This will release any resources held by the AsyncViewModel (timers, streams, etc.)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());

      (notifier as AsyncViewModelImpl).dispose();
    }

    // It's safe to clean this instance
    _notifierToInstance.remove(identityHashCode(notifier));
    _instances.removeWhere((key, value) {
      if (value == this) {
        return true;
      }
      return false;
    });

    // Clean child references
    if (related != null) {
      for (var child in related!) {
        child._parents.remove(this);
      }
    }

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
✅ ReactiveNotifier<$T> successfully cleaned
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
${_getLocationInfo()}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    return true;
  }

// Helper method to get location information for a parent
  String _getParentLocationInfo(ReactiveNotifier parent) {
    try {
      final framePattern =
          RegExp(r'#\d+\s+([^(]+)\(([^:]+):(\d+)(?::(\d+))?\)');
      final frames = StackTrace.current.toString().split('\n');

      for (final frame in frames) {
        final match = framePattern.firstMatch(frame);
        if (match != null && !frame.contains('reactive_notifier.dart')) {
          final method = match.group(1)?.trim();
          final file = match.group(2);
          final line = match.group(3);
          return 'Location: $file:$line in $method';
        }
      }
      return 'Location: Not determined';
    } catch (e) {
      return 'Location: Error determining location ($e)';
    }
  }

  /// Removes a specific instance from the global registry by its key.
  ///
  /// This method allows for targeted cleanup of a single instance when you know its key.
  ///
  /// Parameters:
  /// - [key]: The unique key of the instance to be removed
  ///
  /// Returns `true` if an instance was found and removed, `false` otherwise.
  static bool cleanupInstance(Key key) {
    // Skip cleanup if global cleanup is in progress
    if (_isGlobalCleanupInProgress) {
      return true; // Pretend it was cleaned successfully
    }

    if (!_instances.containsKey(key)) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        final trace = StackTrace.current.toString().split('\n')[1];
        log('''
⚠️ Cannot clean ReactiveNotifier instance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $key
Reason: No instance found with this key.

🔍 Available keys: ${_instances.keys.take(5).join(', ')}${_instances.length > 5 ? '... (${_instances.length - 5} more)' : ''}

Location of cleanup request: $trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 100);
        return true;
      }());
      return false;
    }

    final instance = _instances[key];

    // Check if instance has listeners
    if (instance is ReactiveNotifier && instance.hasListeners) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        final trace = StackTrace.current.toString().split('\n')[1];
        log('''
⚠️ Warning: Cleaning ReactiveNotifier with active listeners
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $key
Type: ${instance.notifier.runtimeType}
Reason: Instance still has active listeners.

❗ This may cause unexpected behavior if widgets are still listening to this instance.

Location of cleanup request: $trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
        return true;
      }());
    }

    _instances.remove(key);

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
✅ ReactiveNotifier instance successfully cleaned
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $key
Type: ${instance?.notifier.runtimeType}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    return true;
  }

  /// Removes all instances of a specific type from the global registry.
  ///
  /// This method cleans up all ReactiveNotifier instances of the specified type T.
  /// Useful when you want to clear all notifiers of a certain model type.
  ///
  /// Returns the number of instances that were removed.
  static int cleanupByType<T>() {
    // Skip cleanup if global cleanup is in progress
    if (_isGlobalCleanupInProgress) {
      return 0; // No instances cleaned during global cleanup
    }

    final instancesBeforeCleanup = _instances.length;
    final instancesOfType = _instances.entries
        .where((entry) => entry.value is ReactiveNotifier<T>)
        .toList();

    if (instancesOfType.isEmpty) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        final trace = StackTrace.current.toString().split('\n')[1];
        log('''
ℹ️ No ReactiveNotifier instances of type <$T> found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Location of cleanup request: $trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());
      return 0;
    }

    // Check for instances with active listeners
    final instancesWithListeners = instancesOfType
        .where((entry) => (entry.value as ReactiveNotifier).hasListeners)
        .toList();

    if (instancesWithListeners.isNotEmpty) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        final trace = StackTrace.current.toString().split('\n')[1];
        final listenerInfo = instancesWithListeners
            .map((entry) => '   - Key: ${entry.key}')
            .join('\n');

        log('''
⚠️ Warning: Cleaning ReactiveNotifier instances with active listeners
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: $T
Count: ${instancesWithListeners.length}
Instances with active listeners:
$listenerInfo

❗ This may cause unexpected behavior if widgets are still listening to these instances.

Location of cleanup request: $trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
        return true;
      }());
    }

    _instances.removeWhere((_, value) {
      if (value is ReactiveNotifier<T>) {
        _notifierToInstance.remove(identityHashCode(value.notifier));
        return true;
      }
      return false;
    });

    final removedCount = instancesBeforeCleanup - _instances.length;

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
✅ ReactiveNotifier instances of type <$T> successfully cleaned
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Count: $removedCount
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    return removedCount;
  }

  @override
  String toString() => '${describeIdentity(this)}($notifier)';

  /// Gets the parent notifiers for testing purposes
  @visibleForTesting
  Set<ReactiveNotifier> get parents => Set.from(_parents);

  static List<ReactiveNotifier> get getInstances =>
      _instances.values.map((e) => e as ReactiveNotifier).toList();
  static ReactiveNotifier<T> getInstanceByKey<T>(Key key) =>
      _instances[key]! as ReactiveNotifier<T>;

  /// O(1) lookup: find the ReactiveNotifier that contains a given notifier value.
  /// Returns null if no ReactiveNotifier contains this value.
  static ReactiveNotifier? findByNotifier(Object notifierValue) {
    return _notifierToInstance[identityHashCode(notifierValue)];
  }

  /// Recreates the notifier instance with a fresh state using the original factory function.
  ///
  /// This method:
  /// 1. Disposes the current ViewModel/state properly (if applicable)
  /// 2. Creates a new instance using the original factory function
  /// 3. Maintains the same key and related states configuration
  /// 4. Notifies all current listeners with the new state
  ///
  /// The method includes protection against infinite loops during ViewModel
  /// initialization by using a recreation guard flag.
  ///
  /// Use cases:
  /// - After logout to create fresh user state
  /// - Reset application state to initial values
  /// - Testing scenarios where clean state is needed
  /// - Recovery from corrupted or invalid state
  ///
  /// Returns the newly created state instance.
  ///
  /// Example:
  /// ```dart
  /// mixin UserService {
  ///   static final instance = ReactiveNotifier<UserViewModel>(() => UserViewModel());
  ///
  ///   static void logout() {
  ///     instance.recreate(); // Fresh UserViewModel with clean state
  ///   }
  /// }
  /// ```
  ///
  /// Throws [StateError] if:
  /// - Called during an ongoing recreation (prevents infinite loops)
  /// - Called on a disposed ReactiveNotifier
  T recreate() {
    // Guard against infinite loops during recreation
    if (_isRecreating) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
⚠️ Recursive recreate() call detected and blocked
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: $T
Key: $keyNotifier
This usually indicates that init() or a listener is calling recreate(),
which would cause an infinite loop.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 100);
        return true;
      }());
      throw StateError('''
Cannot call recreate() during an ongoing recreation.
This usually indicates that init() or a listener is calling recreate(),
which would cause an infinite loop.
Type: $T
Key: $keyNotifier
''');
    }

    // Check if disposed
    if (_disposed) {
      throw StateError('''
Cannot call recreate() on a disposed ReactiveNotifier.
Type: $T
Key: $keyNotifier
Use reinitializeInstance() to create a fresh instance after disposal.
''');
    }

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
🔄 Starting recreate() for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
Current state hash: ${notifier.hashCode}
Current references: $_referenceCount
Has listeners: $hasListeners
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    // Set recreation guard
    _isRecreating = true;

    try {
      // Step 1: Dispose the old ViewModel/AsyncViewModel properly
      final oldNotifier = notifier;

      // Warn if the old ViewModel has active listenVM() subscribers
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        if (oldNotifier is ViewModel &&
            oldNotifier.activeListenerCount > 0) {
          log('[ReactiveNotifier] WARNING: recreate() on ViewModel<$T> with '
              '${oldNotifier.activeListenerCount} active listenVM() subscribers. '
              'Those subscribers will stop receiving updates from the new instance.',
              level: 100);
        }
        if (oldNotifier is AsyncViewModelImpl &&
            oldNotifier.activeListenerCount > 0) {
          log('[ReactiveNotifier] WARNING: recreate() on AsyncViewModel<$T> with '
              '${oldNotifier.activeListenerCount} active listenVM() subscribers. '
              'Those subscribers will stop receiving updates from the new instance.',
              level: 100);
        }
        return true;
      }());

      _disposeOldNotifier(oldNotifier);

      // Step 2: Create fresh state using the original factory function
      // The factory function will create a new ViewModel instance with fresh init()
      final newState = _createFunction();

      // Step 3: Replace the internal state
      // Use updateSilently first to avoid double notification
      replaceNotifier(newState);

      // Step 4: Reset lifecycle flags
      _disposed = false;
      _disposeTimer?.cancel();
      _disposeTimer = null;
      _isScheduledForDispose = false;

      // Step 5: Notify all listeners of the new state
      notifyListeners();

      // Step 6: Notify related parent states if they exist
      if (_parents.isNotEmpty) {
        assert(() {
          if (!ReactiveNotifier.debugLogging) return true;
          log('📤 Notifying parent states after recreate for $T', level: 10);
          return true;
        }());

        for (var parent in _parents) {
          if (!parent._disposed) {
            parent.notifyListeners();
          }
        }
      }

      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
✅ recreate() completed for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
New state hash: ${newState.hashCode}
Old state disposed: ✓
Listeners notified: ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());

      return newState;
    } catch (e, stackTrace) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
⚠️ Error during recreate() for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
Error: $e
Stack trace:
$stackTrace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 100);
        return true;
      }());
      rethrow;
    } finally {
      // Always clear the recreation guard
      _isRecreating = false;
    }
  }

  /// Internal helper to dispose the old notifier properly
  void _disposeOldNotifier(T oldNotifier) {
    try {
      if (oldNotifier is ViewModel && !oldNotifier.isDisposed) {
        // Remove listeners first to prevent callbacks during disposal
        oldNotifier.stopListeningVM();
        oldNotifier.removeListeners();
        // Dispose ChangeNotifier resources (timers, streams, etc.)
        // _disposed is set first in ViewModel.dispose() so it won't
        // re-enter _notifyReactiveNotifierDisposal since we're already in recreate
        try {
          oldNotifier.dispose();
        } catch (e) {
          assert(() {
            if (!ReactiveNotifier.debugLogging) return true;
            log('''
⚠️ Error disposing old ViewModel during recreate()
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: ${oldNotifier.runtimeType}
Error: $e
This may indicate resources that were not properly cleaned up.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
            return true;
          }());
        }
      } else if (oldNotifier is AsyncViewModelImpl && !oldNotifier.isDisposed) {
        // Remove listeners first to prevent callbacks during disposal
        oldNotifier.stopListeningVM();
        oldNotifier.removeListeners();
        // Dispose ChangeNotifier resources (timers, streams, etc.)
        try {
          oldNotifier.dispose();
        } catch (e) {
          assert(() {
            if (!ReactiveNotifier.debugLogging) return true;
            log('''
⚠️ Error disposing old AsyncViewModel during recreate()
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: ${oldNotifier.runtimeType}
Error: $e
This may indicate resources that were not properly cleaned up.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
            return true;
          }());
        }
      }
    } catch (e) {
      assert(() {
        if (!ReactiveNotifier.debugLogging) return true;
        log('''
⚠️ Warning during old notifier cleanup in recreate()
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: $T
Error: $e
Continuing with recreation...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
        return true;
      }());
    }
  }

  /// Check if recreate() is currently in progress
  ///
  /// This can be useful for ViewModels that need to check whether
  /// they are being created as part of a recreation process.
  bool get isRecreating => _isRecreating;

  @override
  void dispose() {
    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
🗑️ ReactiveNotifier<${T.toString()}> dispose() called directly
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Key: $keyNotifier
Note: This will dispose the ReactiveNotifier but not remove from global registry.
For complete cleanup including registry removal, use cleanCurrentNotifier() or 
let ViewModel handle disposal via _handleViewModelDisposal().
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    // 1. Cancel any pending dispose timer
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _isScheduledForDispose = false;

    // 2. Mark as disposed
    _disposed = true;

    // 3. Stop any active listeners
    if (hasListeners) {
      stopListening();
    }

    // 4. If notifier is a ViewModel/AsyncViewModel, dispose it (but avoid circular calls)
    if (notifier is ViewModel || notifier is AsyncViewModelImpl) {
      // Only dispose if the ViewModel hasn't already called dispose
      // This prevents circular dispose calls between ReactiveNotifier and ViewModel
      try {
        if (notifier is ViewModel && !(notifier as ViewModel).isDisposed) {
          (notifier as ViewModel).dispose();
        } else if (notifier is AsyncViewModelImpl &&
            !(notifier as AsyncViewModelImpl).isDisposed) {
          (notifier as AsyncViewModelImpl).dispose();
        }
      } catch (e) {
        assert(() {
          if (!ReactiveNotifier.debugLogging) return true;
          log('''
⚠️ Warning during ViewModel disposal from ReactiveNotifier
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Error: $e
This may indicate the ViewModel was already disposed or there's a circular reference.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
          return true;
        }());
      }
    }

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
✅ ReactiveNotifier<${T.toString()}> dispose completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Listeners stopped: ✓
ViewModel dispose: Attempted
Note: Instance remains in global registry unless manually cleaned
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    // 5. Call ChangeNotifier dispose
    super.dispose();
  }

  /// Initialize global BuildContext for all ViewModels
  ///
  /// Call this method early in your app (typically in MyApp.build() or main())
  /// to make BuildContext available to all ViewModels from the start.
  ///
  /// This is especially useful when:
  /// - Multiple ViewModels need context access
  /// - You want to avoid using waitForContext: true on individual ViewModels
  /// - You need Theme, MediaQuery, or Localizations available during ViewModel init()
  ///
  /// Usage:
  /// ```dart
  /// class MyApp extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     // Initialize global context for all ViewModels
  ///     ReactiveNotifier.initContext(context);
  ///
  ///     return MaterialApp(...);
  ///   }
  /// }
  /// ```
  ///
  /// After calling this:
  /// - All ViewModels ```ViewModel<T> and AsyncViewModelImpl<T>``` have hasContext = true
  /// - context and requireContext() work immediately in init() methods
  /// - No need to use waitForContext: true for individual ViewModels
  /// - Existing ViewModels with waitForContext: true will reinitialize automatically
  static void initContext(BuildContext context) {
    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
🌍 ReactiveNotifier: Initializing global BuildContext
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Widget: ${context.widget.runtimeType}
Context: ${context.runtimeType}
Current ViewModels: ${_instances.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());

    // Register context globally using the ContextNotifier system
    ViewModelContextNotifier.registerGlobalContext(context);

    // Check for ViewModels that were waiting for context and reinitialize them
    int reinitializedCount = 0;
    for (var instance in _instances.values) {
      if (instance is ReactiveNotifier) {
        final notifier = instance.notifier;

        // Check if the ViewModel has a reinitializeWithContext method (AsyncViewModelImpl)
        if (notifier != null && notifier is ViewModelContextService) {
          try {
            // Try to call reinitializeWithContext if it exists using dynamic call
            final dynamic asyncVM = notifier;
            asyncVM.reinitializeWithContext();
            reinitializedCount++;
          } catch (e) {
            // Silently ignore if method doesn't exist or fails - happens for ViewModel<T> which don't have this method
            assert(() {
              if (!ReactiveNotifier.debugLogging) return true;
              log('Note: Could not reinitialize ViewModel ${notifier.runtimeType}: $e',
                  level: 10);
              return true;
            }());
          }
        }
      }
    }

    assert(() {
      if (!ReactiveNotifier.debugLogging) return true;
      log('''
✅ ReactiveNotifier: Global context initialization completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Context registered: ✓
ViewModels checked: ${_instances.length}
ViewModels reinitialized: $reinitializedCount
Global context now available for all ViewModels
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 5);
      return true;
    }());
  }
}