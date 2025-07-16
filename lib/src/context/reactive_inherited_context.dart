import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Internal InheritedWidget that provides reactive state through ReactiveNotifier
/// This widget is created dynamically and injected into the widget tree automatically
/// when context<T>() or extensions like context.lang are used
class ReactiveInheritedContext<T>
    extends InheritedNotifier<ReactiveNotifier<T>> {
  /// The type identifier for this reactive context
  final Type contextType;

  const ReactiveInheritedContext({
    super.key,
    required ReactiveNotifier<T> super.notifier,
    required this.contextType,
    required super.child,
  });

  /// Find an existing ReactiveInheritedContext of type T in the widget tree
  static ReactiveInheritedContext<T>? maybeOf<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ReactiveInheritedContext<T>>();
  }

  /// Get the reactive state of type T from the nearest ReactiveInheritedContext
  /// Throws if no ReactiveInheritedContext<T> is found
  static T of<T>(BuildContext context) {
    final inherited = maybeOf<T>(context);
    if (inherited == null) {
      throw FlutterError(
          'ReactiveInheritedContext.of<$T>() called with a context that does not contain a ReactiveInheritedContext<$T>.\n'
          'No ReactiveInheritedContext<$T> ancestor could be found starting from the context that was passed to ReactiveInheritedContext.of<$T>().\n'
          'The context used was: $context');
    }
    return inherited.notifier!.notifier;
  }

  /// Safely get the reactive state, returning null if not found
  static T? maybeGet<T>(BuildContext context) {
    final inherited = maybeOf<T>(context);
    return inherited?.notifier?.notifier;
  }

  @override
  bool updateShouldNotify(ReactiveInheritedContext<T> oldWidget) {
    return notifier != oldWidget.notifier;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ReactiveInheritedContext<$T>(contextType: $contextType, notifier: $notifier)';
  }
}

/// Registry for managing ReactiveInheritedContext instances
/// Handles automatic creation, injection, and cleanup
class ReactiveContextRegistry {
  static final Map<Type, ReactiveInheritedContext> _activeContexts = {};
  static final Map<Type, ReactiveNotifier> _notifierRegistry = {};
  static final Set<BuildContext> _contextAwaitingInjection = {};

  /// Register a ReactiveNotifier for a specific type
  static void registerNotifier<T>(ReactiveNotifier<T> notifier) {
    _notifierRegistry[T] = notifier;

    assert(() {
      log('''
🔧 ReactiveContextRegistry: Registered notifier for type $T
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Notifier: ${notifier.runtimeType}
Total registered types: ${_notifierRegistry.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  /// Get or create a ReactiveInheritedContext for type T
  static ReactiveInheritedContext<T>? getOrCreateContext<T>(Type contextType) {
    // Check if we already have an active context for this type
    if (_activeContexts.containsKey(T)) {
      return _activeContexts[T] as ReactiveInheritedContext<T>?;
    }

    // Check if we have a registered notifier for this type
    final notifier = _notifierRegistry[T] as ReactiveNotifier<T>?;
    if (notifier == null) {
      assert(() {
        log('''
⚠️ ReactiveContextRegistry: No notifier registered for type $T
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Available types: ${_notifierRegistry.keys.join(', ')}
Context type requested: $contextType
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
        return true;
      }());
      return null;
    }

    // Create new ReactiveInheritedContext but don't store it yet
    // It will be stored when properly injected into widget tree
    final context = ReactiveInheritedContext<T>(
      notifier: notifier,
      contextType: contextType,
      child: const SizedBox.shrink(), // Placeholder child
    );

    assert(() {
      log('''
✅ ReactiveContextRegistry: Created new context for type $T
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Context type: $contextType
Notifier: ${notifier.runtimeType}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());

    return context;
  }

  /// Try to find an existing ReactiveInheritedContext in the widget tree
  static ReactiveInheritedContext<T>? findExistingContext<T>(
      BuildContext context) {
    return ReactiveInheritedContext.maybeOf<T>(context);
  }

  /// Attempt to inject ReactiveInheritedContext into the widget tree
  /// This is a complex operation that tries to modify the widget tree dynamically
  static bool tryInjectContext<T>(
      BuildContext context, ReactiveInheritedContext<T> reactiveContext) {
    try {
      // This is a conceptual implementation
      // In practice, dynamic widget tree injection is very complex in Flutter
      // We would need to work with the Element tree directly

      // For now, return false to fallback to markNeedsBuild approach
      return false;
    } catch (e) {
      assert(() {
        log('''
⚠️ ReactiveContextRegistry: Failed to inject context for type $T
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Error: $e
Falling back to markNeedsBuild approach
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 50);
        return true;
      }());
      return false;
    }
  }

  /// Cleanup inactive contexts
  static void cleanup() {
    _activeContexts.clear();
    _contextAwaitingInjection.clear();

    assert(() {
      log('''
🧹 ReactiveContextRegistry: Cleaned up all contexts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Remaining notifiers: ${_notifierRegistry.length}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''', level: 10);
      return true;
    }());
  }

  /// Get registered notifier for debugging
  static ReactiveNotifier<T>? getRegisteredNotifier<T>() {
    return _notifierRegistry[T] as ReactiveNotifier<T>?;
  }

  /// Get all registered types for debugging
  static List<Type> get registeredTypes => _notifierRegistry.keys.toList();
}
