import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'notifier_impl.dart';
import '../context/reactive_context_enhanced.dart';
import '../context/viewmodel_context_notifier.dart';
import '../debug/reactive_notifier_debug_service.dart';

/// A reactive state management solution that supports:
/// - Singleton instances with key-based identity
/// - Related states management
/// - Circular reference detection
/// - Notification overflow detection
/// - Detailed debug logging
class ReactiveNotifier<T> extends NotifierImpl<T> {
  // Singleton management
  static final HashMap<Key, dynamic> _instances = HashMap.from({});

  // Relations management
  final List<ReactiveNotifier>? related;
  final Set<ReactiveNotifier> _parents = {};
  static final Set<ReactiveNotifier> _updatingNotifiers = {};
  final Key keyNotifier;

  // Factory function for recreation
  // ignore: unused_field
  final T Function() _createFunction;

  // Notification overflow detection
  static const _notificationThreshold = 50;
  static const _thresholdTimeWindow = Duration(milliseconds: 500);
  DateTime? _firstNotificationTime;
  int _notificationCount = 0;

  final bool autoDispose;

  ReactiveNotifier._(
      T Function() create, this.related, this.keyNotifier, this.autoDispose)
      : _createFunction = create,
        super(create()) {
    if (related != null) {
      assert(() {
        log('''
🔍 Setting up relations for ReactiveNotifier<$T>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''', level: 10);
        return true;
      }());

      _validateCircularReferences(this);
      related?.forEach((child) {
        child._parents.add(this);
        assert(() {
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
      
      // Record instance creation for debug service (only in non-test environments)
      if (kDebugMode && !_isTestEnvironment) {
        ReactiveNotifierDebugService.instance.recordInstanceCreation(instance);
      }
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

      // Record state change for debug service
      dynamic oldState = notifier;
      if (kDebugMode) {
        ReactiveNotifierDebugService.instance.recordStateChange(
          instanceId: '${T.toString()}_${keyNotifier.toString()}',
          type: T.toString(),
          oldState: oldState,
          newState: newState,
          source: 'updateState',
          isSilent: false,
        );
      }

      _updatingNotifiers.add(this);

      try {
        // Update value and notify
        super.updateState(newState);

        // Notify parents if they exist
        if (_parents.isNotEmpty) {
          assert(() {
            log('📤 Notifying parent states for $T', level: 10);
            return true;
          }());

          for (var parent in _parents) {
            parent.notifyListeners();
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

      log('📝 Updating state silently for $T: $notifier -> ${newState.runtimeType}',
          level: 10);

      // Record state change for debug service
      dynamic oldState = notifier;
      if (kDebugMode) {
        ReactiveNotifierDebugService.instance.recordStateChange(
          instanceId: '${T.toString()}_${keyNotifier.toString()}',
          type: T.toString(),
          oldState: oldState,
          newState: newState,
          source: 'updateSilently',
          isSilent: true,
        );
      }

      _updatingNotifiers.add(this);

      try {
        // Update value without notifying
        super.updateSilently(newState);

        // Notify parents if they exist
        if (_parents.isNotEmpty) {
          assert(() {
            log('📤 Notifying parent states for $T', level: 10);
            return true;
          }());

          for (var parent in _parents) {
            parent.notifyListeners();
          }
        }
      } finally {
        _updatingNotifiers.remove(this);
      }
    }
  }

  @override
  void transformStateSilently(T Function(T data) data) {
    // Prevent circular update
    if (_updatingNotifiers.contains(this)) {
      return;
    }

    // Check for possible notification overflow
    _checkNotificationOverflow();

    log('🔄 Transforming state silently for $T', level: 10);

    // Record state change for debug service
    dynamic oldState = notifier;
    T newState = data(notifier);
    if (kDebugMode) {
      ReactiveNotifierDebugService.instance.recordStateChange(
        instanceId: '${T.toString()}_${keyNotifier.toString()}',
        type: T.toString(),
        oldState: oldState,
        newState: newState,
        source: 'transformStateSilently',
        isSilent: true,
      );
    }

    _updatingNotifiers.add(this);

    try {
      // Transform state without notifying
      super.transformStateSilently(data);

      // Notify parents if they exist
      if (_parents.isNotEmpty) {
        assert(() {
          log('📤 Notifying parent states for $T', level: 10);
          return true;
        }());

        for (var parent in _parents) {
          parent.notifyListeners();
        }
      }
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

    // Record state change for debug service
    dynamic oldState = notifier;
    T newState = data(notifier);
    if (kDebugMode) {
      ReactiveNotifierDebugService.instance.recordStateChange(
        instanceId: '${T.toString()}_${keyNotifier.toString()}',
        type: T.toString(),
        oldState: oldState,
        newState: newState,
        source: 'transformState',
        isSilent: false,
      );
    }

    _updatingNotifiers.add(this);

    try {
      // Transform state and notify
      super.transformState(data);

      // Notify parents if they exist
      if (_parents.isNotEmpty) {
        assert(() {
          log('📤 Notifying parent states for $T', level: 10);
          return true;
        }());

        for (var parent in _parents) {
          parent.notifyListeners();
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

  /// Global cleanup flag to prevent concurrent modifications during cleanup
  static bool _isGlobalCleanupInProgress = false;

  /// Utility methods
  static void cleanup() {
    if (_isGlobalCleanupInProgress) {
      return; // Already cleaning up, avoid recursive calls
    }
    
    _isGlobalCleanupInProgress = true;
    assert(() {
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

🎯 All memory should now be available for garbage collection
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
        log('''
🔧 Force cleanup mode enabled for ReactiveNotifier<$T>
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

    // Si es seguro limpiar esta instancia
    if (notifier is ViewModel) {
      assert(() {
        log('''
ℹ️ Propagating dispose to StateNotifierImpl
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: ${notifier.runtimeType}
Key: $keyNotifier
This will release any resources held by the ViewModel (timers, streams, etc.)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
        return true;
      }());

      (notifier as ViewModel).dispose();
    }

    // It's safe to clean this instance
    _instances.removeWhere((key, value) => value == this);

    // Clean child references
    if (related != null) {
      for (var child in related!) {
        child._parents.remove(this);
      }
    }

    assert(() {
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

    _instances.removeWhere((_, value) => value is ReactiveNotifier<T>);

    final removedCount = instancesBeforeCleanup - _instances.length;

    assert(() {
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

  // TODO: Implement recreate() method
  // Currently causes infinite loops during ViewModel initialization
  // Need to investigate the interaction between _createFunction() and ViewModel.init()
  //
  // /// Recreates the notifier instance with a fresh ViewModel/state
  // ///
  // /// This method:
  // /// 1. Creates a new instance using the original factory function
  // /// 2. Maintains the same key and related states configuration
  // /// 3. Notifies all current listeners with the new state
  // ///
  // /// Use cases:
  // /// - After logout to create fresh user state
  // /// - Reset application state to initial values
  // /// - Testing scenarios where clean state is needed
  // /// - Recovery from corrupted or invalid state
  // ///
  // /// Example:
  // /// ```dart
  // /// mixin UserService {
  // ///   static final instance = ReactiveNotifier<UserViewModel>(() => UserViewModel());
  // ///
  // ///   static void logout() {
  // ///     instance.recreate(); // Fresh UserViewModel with clean state
  // ///   }
  // /// }
  // /// ```
  // void recreate() {
  //   // Implementation pending - needs to handle ViewModel initialization properly
  // }

  @override
  void dispose() {
    assert(() {
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

    // 1. Stop any active listeners
    if (hasListeners) {
      stopListening();
    }

    // 2. If notifier is a ViewModel/AsyncViewModel, dispose it (but avoid circular calls)
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

    // 3. Call ChangeNotifier dispose
    super.dispose();
  }
  
  /// Check if we're running in a test environment
  static bool get _isTestEnvironment {
    try {
      // Check for flutter_test environment variable
      if (const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        return true;
      }
      
      // Check for test-related zones
      final zone = Zone.current;
      final zoneValues = zone.toString();
      if (zoneValues.contains('flutter_test') || 
          zoneValues.contains('test_api') ||
          zoneValues.contains('TestWidgetsFlutterBinding') ||
          zoneValues.contains('FakeAsync')) {
        return true;
      }
      
      // Check for test binding
      try {
        final binding = WidgetsBinding.instance;
        final bindingType = binding.runtimeType.toString();
        if (bindingType.contains('Test') || 
            bindingType.contains('AutomatedTest')) {
          return true;
        }
      } catch (_) {
        // Ignore errors when WidgetsBinding is not available
      }
      
      return false;
    } catch (_) {
      return false;
    }
  }
}
