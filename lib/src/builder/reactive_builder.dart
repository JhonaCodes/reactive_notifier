import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/implements/notifier_impl.dart';

/// Reactive Builder for simple state or direct model state.
class ReactiveBuilder<T> extends StatefulWidget {
  final NotifierImpl<T> notifier;
  final Widget Function(
    T state,
    Widget Function(Widget child) keep,
  ) builder;

  const ReactiveBuilder({
    super.key,
    required this.notifier,
    required this.builder,
  });

  @override
  State<ReactiveBuilder<T>> createState() => _ReactiveBuilderState<T>();
}

class _ReactiveBuilderState<T> extends State<ReactiveBuilder<T>> {
  late T value;
  final Map<String, _NoRebuildWrapper> _noRebuildWidgets = {};
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    value = widget.notifier.notifier;
    widget.notifier.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ReactiveBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_valueChanged);
      value = widget.notifier.notifier;
      widget.notifier.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_valueChanged);
    debounceTimer?.cancel();
    super.dispose();
  }

  void _valueChanged() {
    // Cancel any existing timer to prevent multiple updates within the debounce period.
    debounceTimer?.cancel();

    // Start a new timer. After 100 milliseconds, update the state and rebuild the widget.
    if (!isTesting) {
      debounceTimer = Timer(const Duration(milliseconds: 100), () {
        setState(() {
          value = widget.notifier.notifier;
        });
      });
    } else {
      setState(() {
        value = widget.notifier.notifier;
      });
    }
  }

  Widget _noRebuild(Widget keep) {
    final key = keep.hashCode.toString();
    if (!_noRebuildWidgets.containsKey(key)) {
      _noRebuildWidgets[key] = _NoRebuildWrapper(builder: keep);
    }
    return _noRebuildWidgets[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(value, _noRebuild);
  }
}

class _NoRebuildWrapper extends StatefulWidget {
  final Widget builder;

  const _NoRebuildWrapper({required this.builder});

  @override
  _NoRebuildWrapperState createState() => _NoRebuildWrapperState();
}

class _NoRebuildWrapperState extends State<_NoRebuildWrapper> {
  late Widget child;

  @override
  void initState() {
    super.initState();
    child = widget.builder;
  }

  @override
  Widget build(BuildContext context) => child;
}

/// [ReactiveViewModelBuilder]
/// ReactiveViewModelBuilder is a specialized widget for handling ViewModel states
/// It's designed to work specifically with StateNotifierImpl implementations
/// and provides efficient state management and rebuilding mechanisms
///
class ReactiveViewModelBuilder<T> extends StatefulWidget {
  /// [StateNotifierImpl]
  /// The notifier should be a StateNotifierImpl that manages the ViewModel's data
  /// T represents the data type being managed, not the ViewModel class itself
  ///
  final StateNotifierImpl<T> notifier;

  /// Builder function that creates the widget tree
  /// Takes two parameters:
  /// - state: Current state of type T
  /// - keep: Function to prevent unnecessary rebuilds of child widgets
  ///
  final Widget Function(
    T state,
    Widget Function(Widget child) keep,
  ) builder;

  const ReactiveViewModelBuilder({
    super.key,
    required this.notifier,
    required this.builder,
  });

  @override
  State<ReactiveViewModelBuilder<T>> createState() =>
      _ReactiveBuilderStateViewModel<T>();
}

/// State class for ReactiveViewModelBuilder
/// Handles state management and widget rebuilding
class _ReactiveBuilderStateViewModel<T>
    extends State<ReactiveViewModelBuilder<T>> {
  /// Current value of the state
  late T value;

  /// Cache for widgets that shouldn't rebuild
  final Map<String, _NoRebuildWrapperViewModel> _noRebuildWidgets = {};

  /// Timer for debouncing updates
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize with current data from notifier
    value = widget.notifier.data;
    // Subscribe to changes
    widget.notifier.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ReactiveViewModelBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle notifier changes by updating subscriptions
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_valueChanged);
      value = widget.notifier.data;
      widget.notifier.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    // Cleanup subscriptions and timer
    widget.notifier.removeListener(_valueChanged);
    debounceTimer?.cancel();
    super.dispose();
  }

  /// Handles state changes from the notifier
  /// Implements debouncing to prevent too frequent updates
  void _valueChanged() {
    // Cancel existing debounce timer
    debounceTimer?.cancel();

    // Debounce updates with 100ms delay
    if (!isTesting) {
      debounceTimer = Timer(const Duration(milliseconds: 100), () {
        setState(() {
          value = widget.notifier.data;
        });
      });
    } else {
      // Immediate update during testing
      setState(() {
        value = widget.notifier.data;
      });
    }
  }

  /// Creates or retrieves a cached widget that shouldn't rebuild
  Widget _noRebuild(Widget keep) {
    final key = keep.hashCode.toString();
    if (!_noRebuildWidgets.containsKey(key)) {
      _noRebuildWidgets[key] = _NoRebuildWrapperViewModel(builder: keep);
    }
    return _noRebuildWidgets[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(value, _noRebuild);
  }
}

/// Widget wrapper that prevents rebuilds of its children
/// Used by the _noRebuild function to optimize performance
class _NoRebuildWrapperViewModel extends StatefulWidget {
  /// The widget to be wrapped and prevented from rebuilding
  final Widget builder;

  const _NoRebuildWrapperViewModel({required this.builder});

  @override
  _NoRebuildWrapperStateViewModel createState() =>
      _NoRebuildWrapperStateViewModel();
}

/// State for _NoRebuildWrapperViewModel
/// Maintains a single instance of the child widget
class _NoRebuildWrapperStateViewModel
    extends State<_NoRebuildWrapperViewModel> {
  /// Cached instance of the child widget
  late Widget child;

  @override
  void initState() {
    super.initState();
    // Store the initial widget
    child = widget.builder;
  }

  @override
  Widget build(BuildContext context) => child;
}

bool get isTesting => const bool.fromEnvironment('dart.vm.product') == true;
