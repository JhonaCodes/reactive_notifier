import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

/// Opt-in lifecycle observer to reduce memory usage when the app is inactive.
///
/// Only performs safe garbage collection of unused auto-dispose instances.
/// Does NOT clean context listeners or preserved widgets, as widgets may
/// still be mounted when the app is paused.
///
/// Usage:
/// ```dart
/// final observer = ReactiveNotifierLifecycleObserver()..start();
/// ```
///
/// Call [stop] when you no longer need it (e.g., in dispose).
class ReactiveNotifierLifecycleObserver with WidgetsBindingObserver {
  bool _isStarted = false;

  /// Attach this observer to WidgetsBinding.
  void start() {
    if (_isStarted) return;
    WidgetsBinding.instance.addObserver(this);
    _isStarted = true;
  }

  /// Detach this observer from WidgetsBinding.
  void stop() {
    if (!_isStarted) return;
    WidgetsBinding.instance.removeObserver(this);
    _isStarted = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _runBackgroundCleanup();
    }
  }

  void _runBackgroundCleanup() {
    try {
      final cleaned = ReactiveNotifier.garbageCollectUnused();

      assert(() {
        log('[ReactiveNotifier] Background cleanup completed. Cleaned: $cleaned');
        return true;
      }());
    } catch (e) {
      assert(() {
        log('[ReactiveNotifier] Background cleanup error: $e');
        return true;
      }());
    }
  }
}
