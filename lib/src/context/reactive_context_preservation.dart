/// Widget preservation functionality for ReactiveContext
///
/// This module provides enhanced widget preservation capabilities through
/// extension methods and automatic key management, replacing the basic
/// NoRebuildWrapper with a more intuitive and powerful API.
///
/// Key improvements over NoRebuildWrapper:
/// - Extension methods for cleaner API
/// - Automatic key generation and management
/// - Batch preservation for multiple widgets
/// - Better debugging and logging
library reactive_context_preservation;

import 'dart:developer';

import 'package:flutter/widgets.dart';

/// Enhanced widget preservation registry with automatic key management
///
/// This class provides a global registry for preserved widgets, automatically
/// managing keys and ensuring optimal performance through intelligent caching.
///
/// @protected - Internal class, not meant for direct usage
@protected
class _PreservationRegistry {
  /// Global registry for preserved widgets
  static final Map<String, Widget> _preservedWidgets = {};
  static final Map<String, int> _widgetBuildCounts = {};
  static final Map<String, DateTime> _lastAccessed = {};

  /// Maximum cache size to prevent memory leaks
  static const int _maxCacheSize = 1000;

  /// Cache cleanup interval (in minutes)
  static const int _cleanupIntervalMinutes = 5;

  /// Preserve a widget with automatic key management
  @protected
  static Widget preserve(Widget widget, [String? key]) {
    // Generate automatic key if not provided
    final effectiveKey = key ?? _generateAutomaticKey(widget);

    // Check if widget is already preserved
    if (_preservedWidgets.containsKey(effectiveKey)) {
      _updateAccessTime(effectiveKey);

      assert(() {
        log('[ReactiveContext] Using preserved widget: $effectiveKey');
        return true;
      }());

      return _preservedWidgets[effectiveKey]!;
    }

    // Clean up cache if necessary
    _cleanupCacheIfNeeded();

    // Create preserved widget
    final preservedWidget = _PreservedWidget(
      key: ValueKey(effectiveKey),
      child: widget,
    );

    // Store in registry
    _preservedWidgets[effectiveKey] = preservedWidget;
    _widgetBuildCounts[effectiveKey] = 0;
    _updateAccessTime(effectiveKey);

    assert(() {
      log('[ReactiveContext] Created preserved widget: $effectiveKey');
      return true;
    }());

    return preservedWidget;
  }

  /// Preserve multiple widgets with batch operation
  @protected
  static List<Widget> preserveAll(List<Widget> widgets, [String? baseKey]) {
    final baseEffectiveKey =
        baseKey ?? 'batch_${DateTime.now().millisecondsSinceEpoch}';

    return widgets.asMap().entries.map((entry) {
      final index = entry.key;
      final widget = entry.value;
      final key = '${baseEffectiveKey}_$index';

      return preserve(widget, key);
    }).toList();
  }

  /// Generate automatic key based on widget properties
  @protected
  static String _generateAutomaticKey(Widget widget) {
    final widgetType = widget.runtimeType.toString();
    final widgetKey = widget.key?.toString() ?? 'null';

    // Create hash based on widget properties without timestamp for stability
    var hash = widgetType.hashCode;
    hash = hash * 31 + widgetKey.hashCode;

    return '${widgetType}_${hash.abs()}';
  }

  /// Update access time for LRU cache management
  @protected
  static void _updateAccessTime(String key) {
    _lastAccessed[key] = DateTime.now();
  }

  /// Clean up cache if it exceeds maximum size
  @protected
  static void _cleanupCacheIfNeeded() {
    if (_preservedWidgets.length < _maxCacheSize) return;

    final now = DateTime.now();
    final cutoffTime =
        now.subtract(const Duration(minutes: _cleanupIntervalMinutes));

    // Remove old entries
    final keysToRemove = _lastAccessed.entries
        .where((entry) => entry.value.isBefore(cutoffTime))
        .map((entry) => entry.key)
        .toList();

    for (final key in keysToRemove) {
      _preservedWidgets.remove(key);
      _widgetBuildCounts.remove(key);
      _lastAccessed.remove(key);
    }

    // If still too large, remove least recently used
    if (_preservedWidgets.length >= _maxCacheSize) {
      final sortedByAccess = _lastAccessed.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final toRemove =
          sortedByAccess.take(_maxCacheSize ~/ 2).map((e) => e.key);
      for (final key in toRemove) {
        _preservedWidgets.remove(key);
        _widgetBuildCounts.remove(key);
        _lastAccessed.remove(key);
      }
    }

    assert(() {
      log(
          '[ReactiveContext] Cleaned up preservation cache. Size: ${_preservedWidgets.length}');
      return true;
    }());
  }

  /// Get debug statistics for preservation registry
  @protected
  static Map<String, dynamic> getDebugStatistics() {
    return {
      'totalPreservedWidgets': _preservedWidgets.length,
      'averageBuildCount': _widgetBuildCounts.values.isEmpty
          ? 0
          : _widgetBuildCounts.values.reduce((a, b) => a + b) /
              _widgetBuildCounts.length,
      'oldestPreservedWidget': _lastAccessed.values.isEmpty
          ? null
          : _lastAccessed.values
              .reduce((a, b) => a.isBefore(b) ? a : b)
              .toString(),
      'cacheUtilization':
          '${((_preservedWidgets.length / _maxCacheSize) * 100).toStringAsFixed(1)}%',
    };
  }

  /// Clear all preserved widgets
  @protected
  static void cleanup() {
    _preservedWidgets.clear();
    _widgetBuildCounts.clear();
    _lastAccessed.clear();

    assert(() {
      log('[ReactiveContext] Preservation registry cleaned up');
      return true;
    }());
  }
}

/// Enhanced preserved widget with better lifecycle management
///
/// This widget provides better lifecycle management than NoRebuildWrapper,
/// with proper handling of widget updates and debugging capabilities.
///
/// @protected - Internal widget, not meant for direct usage
@protected
class _PreservedWidget extends StatefulWidget {
  final Widget child;

  const _PreservedWidget({
    super.key,
    required this.child,
  });

  @override
  State<_PreservedWidget> createState() => _PreservedWidgetState();
}

@protected
class _PreservedWidgetState extends State<_PreservedWidget> {
  late Widget _preservedChild;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    _preservedChild = widget.child;
    _incrementBuildCount();

    assert(() {
      log(
          '[ReactiveContext] Preserved widget initialized: ${widget.key}');
      return true;
    }());
  }

  @override
  void didUpdateWidget(covariant _PreservedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if the child widget has actually changed
    if (oldWidget.child != widget.child) {
      _preservedChild = widget.child;
      _incrementBuildCount();

      assert(() {
        log('[ReactiveContext] Preserved widget updated: ${widget.key}');
        return true;
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      log(
          '[ReactiveContext] Building preserved widget: ${widget.key} (build #$_buildCount)');
      return true;
    }());

    return _preservedChild;
  }

  @protected
  void _incrementBuildCount() {
    _buildCount++;
    final keyStr = widget.key.toString();
    _PreservationRegistry._widgetBuildCounts[keyStr] = _buildCount;
  }
}

/// Extension methods for widget preservation
///
/// These extensions provide a clean, intuitive API for widget preservation
/// directly on Widget objects, making it easy to preserve expensive widgets
/// without manual wrapper management.
extension ReactiveContextWidgetPreservation on Widget {
  /// Preserve this widget with an optional key
  ///
  /// This method creates a preserved version of the widget that won't rebuild
  /// when its parent rebuilds, providing significant performance benefits for
  /// expensive widgets.
  ///
  /// Usage:
  /// ```dart
  /// ExpensiveWidget().keep('my_key')
  /// ExpensiveWidget().keep() // Auto-generated key
  /// ```
  Widget keep([String? key]) {
    return _PreservationRegistry.preserve(this, key);
  }
}

/// Extension methods for BuildContext preservation
///
/// These extensions provide context-aware widget preservation capabilities,
/// allowing for more dynamic preservation strategies based on the current
/// build context.
extension ReactiveContextPreservation on BuildContext {
  /// Preserve a widget with context-aware key generation
  ///
  /// This method provides context-aware preservation, automatically generating
  /// keys based on the current widget context for better uniqueness.
  ///
  /// Usage:
  /// ```dart
  /// context.keep(ExpensiveWidget(), 'my_key')
  /// context.keep(ExpensiveWidget()) // Auto-generated key
  /// ```
  Widget keep(Widget widget, [String? key]) {
    final contextKey = key ?? '${widget.runtimeType}_${widget.hashCode}';
    return _PreservationRegistry.preserve(widget, contextKey);
  }

  /// Preserve multiple widgets with batch operation
  ///
  /// This method allows for batch preservation of multiple widgets with a
  /// single operation, automatically managing keys for each widget.
  ///
  /// Usage:
  /// ```dart
  /// context.keepAll([widget1, widget2, widget3], 'batch_key')
  /// context.keepAll([widget1, widget2, widget3]) // Auto-generated keys
  /// ```
  List<Widget> keepAll(List<Widget> widgets, [String? baseKey]) {
    final contextBaseKey =
        baseKey ?? 'batch_${DateTime.now().millisecondsSinceEpoch}';
    return _PreservationRegistry.preserveAll(widgets, contextBaseKey);
  }
}

/// Enhanced widget preservation with intelligent caching
///
/// This widget provides explicit control over widget preservation with
/// advanced caching strategies and automatic cleanup.
class ReactiveContextPreservationWrapper extends StatelessWidget {
  final Widget child;
  final String? preservationKey;
  final bool enableAutomaticCleanup;

  const ReactiveContextPreservationWrapper({
    super.key,
    required this.child,
    this.preservationKey,
    this.enableAutomaticCleanup = true,
  });

  @override
  Widget build(BuildContext context) {
    return _PreservationRegistry.preserve(child, preservationKey);
  }
}

/// Public API functions for widget preservation
///
/// These functions provide a clean public API for widget preservation
/// while using the enhanced internal implementation.

/// Preserve a widget with automatic key management
///
/// This function provides a simple way to preserve widgets without using
/// extension methods, useful for functional programming patterns.
Widget preserveWidget(Widget widget, [String? key]) {
  return _PreservationRegistry.preserve(widget, key);
}

/// Preserve multiple widgets with batch operation
///
/// This function allows for batch preservation of multiple widgets with
/// automatic key management and optimization.
List<Widget> preserveWidgets(List<Widget> widgets, [String? baseKey]) {
  return _PreservationRegistry.preserveAll(widgets, baseKey);
}

/// Get debug statistics for widget preservation
///
/// This function provides detailed statistics about the preservation registry
/// for debugging and performance monitoring.
Map<String, dynamic> getPreservationStatistics() {
  return _PreservationRegistry.getDebugStatistics();
}

/// Clean up all preserved widgets
///
/// This function clears all preserved widgets from the registry, useful
/// for testing or memory management.
void cleanupPreservedWidgets() {
  _PreservationRegistry.cleanup();
}
