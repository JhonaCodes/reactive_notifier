import 'dart:developer';
import 'implements/notifier_impl.dart';
import 'package:flutter/foundation.dart';

/// A reactive state management solution that supports:
/// - Singleton instances with key-based identity
/// - Related states management
/// - Circular reference detection
/// - Notification overflow detection
/// - Detailed debug logging
class ReactiveNotifier<T> extends NotifierImpl<T> {
  // Singleton management
  static final Map<Key, dynamic> _instances = {};

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

  ReactiveNotifier._(T Function() create, this.related, this.keyNotifier)
      : super(create()) {
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
          log('➕ Added parent-child relation: $T -> ${child.value.runtimeType}',
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
      {List<ReactiveNotifier>? related, Key? key}) {
    key ??= UniqueKey();

    assert(() {
      log('''
📦 Creating ReactiveNotifier<$T>
${related != null ? '🔗 With related types: ${related.map((r) => r.value.runtimeType).join(', ')}' : ''}
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
      _instances[key] = ReactiveNotifier._(create, related, key);
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
    if (value != newState) {
      // Prevent circular update
      if (_updatingNotifiers.contains(this)) {
        return;
      }

      // Check for possible notification overflow
      _checkNotificationOverflow();

      assert(() {
        log('📝 Updating state for $T: $value -> $newState', level: 10);
        return true;
      }());

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
Current Value: $value
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
   Type: ${notifier.value.runtimeType}
   Value: ${notifier.value}
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
        .map((key) => '${_instances[key]?.value.runtimeType}($key)')
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
            (n) => n.value is R && n.keyNotifier == key,
            orElse: () => throw StateError('''
❌ Related State Not Found
━━━━━━━━━━━━━━━━━━━━━
Looking for: $R with key: $key
Parent type: $T
Available types: ${related!.map((r) => '${r.value.runtimeType}(${r.keyNotifier})').join(', ')}
━━━━━━━━━━━━━━━━━━━━━
'''),
          )
        : related!.firstWhere(
            (n) => n.value is R,
            orElse: () => throw StateError('''
❌ Related State Not Found
━━━━━━━━━━━━━━━━━━━━━
Looking for: $R
Parent type: $T
Available types: ${related!.map((r) => '${r.value.runtimeType}(${r.keyNotifier})').join(', ')}
━━━━━━━━━━━━━━━━━━━━━
'''),
          );

    return result.value as R;
  }

  /// Utility methods
  static void cleanup() {
    _instances.clear();
    _updatingNotifiers.clear();
  }

  static int get instanceCount => _instances.length;

  static int instanceCountByType<S>() {
    return _instances.values.whereType<ReactiveNotifier<S>>().length;
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}



class ReactiveListenableNotifier<T> extends NotifierImpl<T> {
  // Singleton management
  static final Map<Key, dynamic> _instances = {};

  // Relations management
  final List<ReactiveListenableNotifier>? related;
  final Set<ReactiveListenableNotifier> _parents = {};
  static final Set<ReactiveListenableNotifier> _updatingNotifiers = {};
  final Key keyNotifier;

  // Notification overflow detection
  static const _notificationThreshold = 50;
  static const _thresholdTimeWindow = Duration(milliseconds: 500);
  DateTime? _firstNotificationTime;
  int _notificationCount = 0;

  ReactiveListenableNotifier._(T Function() create, this.related, this.keyNotifier)
      : super(create()) {
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
          log('➕ Added parent-child relation: $T -> ${child.value.runtimeType}',
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
  factory ReactiveListenableNotifier(T Function() create,
      {List<ReactiveListenableNotifier>? related, Key? key}) {
    key ??= UniqueKey();

    assert(() {
      log('''
📦 Creating ReactiveNotifier<$T>
${related != null ? '🔗 With related types: ${related.map((r) => r.value.runtimeType).join(', ')}' : ''}
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
      _instances[key] = ReactiveListenableNotifier._(create, related, key);
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

    return _instances[key] as ReactiveListenableNotifier<T>;
  }

  @override
  void updateState(T newState) {
    if (value != newState) {
      // Prevent circular update
      if (_updatingNotifiers.contains(this)) {
        return;
      }

      // Check for possible notification overflow
      _checkNotificationOverflow();

      assert(() {
        log('📝 Updating state for $T: $value -> $newState', level: 10);
        return true;
      }());

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
Current Value: $value
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

  String _formatNotifierInfo(ReactiveListenableNotifier notifier) {
    return '''
   Type: ${notifier.value.runtimeType}
   Value: ${notifier.value}
   Key: ${notifier.keyNotifier}''';
  }

  void _collectAncestors(ReactiveListenableNotifier node, Set<Key> ancestorKeys) {
    if (node.related == null) return;
    for (final related in node.related!) {
      ancestorKeys.add(related.keyNotifier);
      _collectAncestors(related, ancestorKeys);
    }
  }

  void _validateNodeReferences(
      ReactiveListenableNotifier node,
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
      ReactiveListenableNotifier node,
      ReactiveListenableNotifier child,
      Set<Key> pathKeys,
      ) {
    final cycle = [...pathKeys, child.keyNotifier]
        .map((key) => '${_instances[key]?.value.runtimeType}($key)')
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
      ReactiveListenableNotifier node,
      ReactiveListenableNotifier child,
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

  void _validateCircularReferences(ReactiveListenableNotifier root) {
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
          (n) => n.value is R && n.keyNotifier == key,
      orElse: () => throw StateError('''
❌ Related State Not Found
━━━━━━━━━━━━━━━━━━━━━
Looking for: $R with key: $key
Parent type: $T
Available types: ${related!.map((r) => '${r.value.runtimeType}(${r.keyNotifier})').join(', ')}
━━━━━━━━━━━━━━━━━━━━━
'''),
    )
        : related!.firstWhere(
          (n) => n.value is R,
      orElse: () => throw StateError('''
❌ Related State Not Found
━━━━━━━━━━━━━━━━━━━━━
Looking for: $R
Parent type: $T
Available types: ${related!.map((r) => '${r.value.runtimeType}(${r.keyNotifier})').join(', ')}
━━━━━━━━━━━━━━━━━━━━━
'''),
    );

    return result.value as R;
  }

  /// Utility methods
  static void cleanup() {
    _instances.clear();
    _updatingNotifiers.clear();
  }

  static int get instanceCount => _instances.length;

  static int instanceCountByType<S>() {
    return _instances.values.whereType<ReactiveNotifier<S>>().length;
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}