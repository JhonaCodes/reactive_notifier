import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart'
    show ReactiveNotifier, ViewModel;
import 'package:reactive_notifier/src/implements/notifier_impl.dart';

import '../reactive_notifier_viewmodel.dart';

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

    debounceTimer?.cancel();

    if (widget.notifier is ReactiveNotifier) {
      final reactiveNotifier = widget.notifier as ReactiveNotifier;
      if (reactiveNotifier.autoDispose && !reactiveNotifier.hasListeners) {
        /// Clean current reactive and any dispose on Viewmodel
        reactiveNotifier.cleanCurrentNotifier();
      }
    }

    super.dispose();
  }

  void _valueChanged() {
    // Cancel any existing timer to prevent multiple updates within the debounce period.
    debounceTimer?.cancel();

    // Start a new timer. After 100 milliseconds, update the state and rebuild the widget.
    setState(() {
      value = widget.notifier.notifier;
    });
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
  /// The notifier should be a StateNotifierImpl that manages the ViewModel's data
  /// This is optional if viewmodel is provided
  final StateNotifierImpl<T>? notifier;

  /// New ViewModel approach, takes precedence over notifier if both are provided
  final ViewModel<T>? viewmodel;

  /// Builder function that creates the widget tree
  final Widget Function(
    T state,
    Widget Function(Widget child) keep,
  ) builder;

  /// Constructor that ensures either notifier or viewmodel is provided
  const ReactiveViewModelBuilder({
    super.key,
    this.notifier,
    this.viewmodel,
    required this.builder,
  }) : assert(notifier != null || viewmodel != null,
            'Either notifier or viewmodel must be provided');

  @override
  State<ReactiveViewModelBuilder<T>> createState() =>
      _ReactiveBuilderStateViewModel<T>();
}

/// State class for ReactiveViewModelBuilder
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
    // Initialize with data from either source
    value = widget.viewmodel?.data ?? widget.notifier!.data;

    // Subscribe to changes from either source
    if (widget.viewmodel != null) {
      widget.viewmodel!.addListener(_valueChanged);
    } else {
      widget.notifier!.addListener(_valueChanged);
    }
  }

  @override
  void didUpdateWidget(ReactiveViewModelBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle changes in the provided sources
    final bool viewModelChanged = widget.viewmodel != oldWidget.viewmodel;
    final bool notifierChanged = widget.notifier != oldWidget.notifier;

    // First, clean up old listeners
    if (viewModelChanged && oldWidget.viewmodel != null) {
      oldWidget.viewmodel!.removeListener(_valueChanged);
    } else if (notifierChanged && oldWidget.notifier != null) {
      oldWidget.notifier!.removeListener(_valueChanged);
    }

    // Then set up new state and listeners
    if (widget.viewmodel != null) {
      value = widget.viewmodel!.data;
      widget.viewmodel!.addListener(_valueChanged);
    } else if (widget.notifier != null) {
      value = widget.notifier!.data;
      widget.notifier!.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    // Cleanup subscriptions and timer
    if (widget.viewmodel != null) {
      widget.viewmodel!.removeListener(_valueChanged);

      // Handle auto-dispose if applicable
      if (widget.viewmodel is ReactiveNotifierViewModel) {
        final reactiveViewModel = widget.viewmodel as ReactiveNotifierViewModel;
        if (reactiveViewModel.autoDispose &&
            !reactiveViewModel.notifier.hasListeners) {
          reactiveViewModel.dispose();
        }
      }
    } else if (widget.notifier != null) {
      widget.notifier!.removeListener(_valueChanged);
    }

    debounceTimer?.cancel();
    super.dispose();
  }

  /// Handles state changes from the notifier
  void _valueChanged() {
    // Cancel existing debounce timer
    debounceTimer?.cancel();
    setState(() {
      value = widget.viewmodel?.data ?? widget.notifier!.data;
    });
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
