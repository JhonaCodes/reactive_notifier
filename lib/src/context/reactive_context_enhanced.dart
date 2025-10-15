/// Enhanced ReactiveContext implementation with improved performance and API
///
/// This implementation solves key problems from the original ReactiveContextHybrid:
/// - Cross-rebuilds eliminated (type-specific markNeedsBuild)
/// - Cleaner API with extension methods
/// - Better error handling and logging
/// - Automatic strategy detection
library reactive_context_enhanced;

import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:reactive_notifier/src/context/reactive_inherited_context.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Enhanced ReactiveContext with improved notifier-specific rebuild strategy
///
/// Key improvements over ReactiveContextHybrid:
/// - No cross-rebuilds: Only elements using specific notifier rebuild
/// - Cleaner API: context.lang.name vs ReactiveContextHybrid.getReactiveState()
/// - Better error handling with specific error messages
/// - Automatic strategy detection and logging
///
/// @protected - Internal class, not meant for direct usage
@protected
class ReactiveContextEnhanced {
  /// Notifier-specific element tracking prevents cross-rebuilds
  static final Map<ReactiveNotifier, Set<Element>> _markNeedsBuildElements = {};
  static final Map<ReactiveNotifier, bool> _globalListenersSetup = {};

  /// Enhanced getState with type-specific rebuild strategy
  static T getReactiveState<T>(
    BuildContext context,
    ReactiveNotifier<T> notifier,
  ) {
    // Auto-register notifier for InheritedWidget strategy
    ReactiveContextRegistry.registerNotifier<T>(notifier);

    // Strategy 1: Try existing InheritedWidget in tree
    final inheritedWidget = ReactiveInheritedContext.maybeOf<T>(context);
    if (inheritedWidget != null) {
      assert(() {
        log(
            '[ReactiveContext] Using InheritedWidget strategy for $T in ${context.widget.runtimeType}');
        return true;
      }());
      return inheritedWidget.notifier!.notifier;
    }

    // Strategy 2: Fallback to enhanced markNeedsBuild strategy
    assert(() {
      log(
          '[ReactiveContext] Using markNeedsBuild strategy for $T in ${context.widget.runtimeType}');
      return true;
    }());

    final element = context as Element;

    // Register for type-specific rebuilds (deferred to avoid build-time issues)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerForTypeSpecificRebuilds<T>(element, notifier);
    });

    return notifier.notifier;
  }

  /// Enhanced markNeedsBuild with notifier-specific element tracking
  @protected
  static void _registerForTypeSpecificRebuilds<T>(
    Element element,
    ReactiveNotifier<T> notifier,
  ) {
    if (!element.mounted) return;

    // Initialize Set for this notifier if it doesn't exist
    _markNeedsBuildElements.putIfAbsent(notifier, () => <Element>{});

    // Setup global listener once per notifier
    if (!_globalListenersSetup.containsKey(notifier)) {
      notifier.listen((newValue) {
        // Clean up disposed elements of this specific notifier
        _markNeedsBuildElements[notifier]?.removeWhere((e) => !e.mounted);

        // Rebuild elements active ONLY for this notifier
        final elementsForNotifier = _markNeedsBuildElements[notifier];
        if (elementsForNotifier != null) {
          assert(() {
            log(
                '[ReactiveContext] Rebuilding ${elementsForNotifier.length} elements for notifier $notifier');
            return true;
          }());

          for (final elem in elementsForNotifier) {
            if (elem.mounted) {
              elem.markNeedsBuild();
            }
          }
        }
      });
      _globalListenersSetup[notifier] = true;
    }

    // Add element to notifier-specific rebuild list
    _markNeedsBuildElements[notifier]!.add(element);
  }

  /// Register a ReactiveNotifier for InheritedWidget strategy
  @protected
  static void registerNotifier<T>(ReactiveNotifier<T> notifier) {
    ReactiveContextRegistry.registerNotifier<T>(notifier);
  }

  /// Enhanced cleanup with type-specific clearing

  static void cleanup() {
    _markNeedsBuildElements.clear();
    _globalListenersSetup.clear();
    ReactiveContextRegistry.cleanup();

    assert(() {
      log('[ReactiveContext] Enhanced cleanup completed');
      return true;
    }());
  }

  /// Enhanced debug statistics
  @protected
  static Map<String, dynamic> getEnhancedDebugStatistics() {
    return {
      'notifierSpecificElements': _markNeedsBuildElements.map(
          (notifier, elements) =>
              MapEntry(notifier.toString(), elements.length)),
      'globalListenersSetup': _globalListenersSetup.length,
      'registeredNotifierTypes': ReactiveContextRegistry.registeredTypes.length,
      'totalActiveElements': _markNeedsBuildElements.values
          .map((set) => set.length)
          .fold(0, (sum, count) => sum + count),
    };
  }
}

/// Enhanced auto-registration mixin with better performance
///
/// Automatically registers ReactiveNotifier when mixin is used
/// ensuring it's available for InheritedWidget strategy
///
/// @protected - Internal mixin, not meant for direct usage
@protected
mixin ReactiveContextEnhancedMixin<T> {
  static final Map<Type, bool> _registrationCache = {};

  /// Enhanced auto-registration with caching
  @protected
  static void autoRegisterNotifier<T>(ReactiveNotifier<T> notifier) {
    if (!_registrationCache.containsKey(T)) {
      ReactiveContextEnhanced.registerNotifier<T>(notifier);
      _registrationCache[T] = true;

      assert(() {
        log(
            '[ReactiveContext] Auto-registered enhanced notifier for $T');
        return true;
      }());
    }
  }
}

/// ReactiveContextBuilder for explicit InheritedWidget strategy
///
/// Forces InheritedWidget strategy for specified notifiers
/// providing maximum performance for known reactive dependencies
///
/// This is a public API widget that developers can use
class ReactiveContextBuilder extends StatelessWidget {
  final Widget child;
  final List<ReactiveNotifier> forceInheritedFor;

  const ReactiveContextBuilder({
    super.key,
    required this.child,
    required this.forceInheritedFor,
  });

  @override
  Widget build(BuildContext context) {
    Widget current = child;

    // Create InheritedWidgets for all specified notifiers
    for (final notifier in forceInheritedFor.reversed) {
      current = _createInheritedWidget(notifier, current);
    }

    return current;
  }

  @protected
  Widget _createInheritedWidget(ReactiveNotifier notifier, Widget child) {
    return ReactiveInheritedContext(
      notifier: notifier,
      contextType: notifier.notifier.runtimeType,
      child: child,
    );
  }
}

/// Public API function for easy access to enhanced reactive state
///
/// This function provides a clean public API while using the enhanced
/// internal implementation with type-specific rebuilds
///
/// @protected - Internal function, use extensions instead
@protected
T getReactiveStateEnhanced<T>(
    BuildContext context, ReactiveNotifier<T> notifier) {
  return ReactiveContextEnhanced.getReactiveState<T>(context, notifier);
}
