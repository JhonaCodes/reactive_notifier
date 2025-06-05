import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// [ReactiveViewModelBuilder]
/// ReactiveViewModelBuilder is a specialized widget for handling ViewModel states
/// It's designed to work specifically with StateNotifierImpl implementations
/// and provides efficient state management and rebuilding mechanisms
///
class ReactiveViewModelBuilder<T> extends StatefulWidget {
  /// New ViewModel approach, takes precedence over notifier if both are provided
  final ViewModel<T> viewmodel;

  /// Builder function that creates the widget tree
  final Widget Function(
    T state,
    Widget Function(Widget child) keep,
  ) builder;

  /// Builds the widget based on the current [ViewModel] state.
  ///
  /// This function provides:
  /// - [state]: The current state value managed by the [ViewModel].
  /// - [viewmodel]: The [ViewModel] instance containing business logic, async control, and update methods.
  /// - [keep]: A helper function to prevent unnecessary widget rebuilds by maintaining widget identity.
  ///
  /// Use this builder when working with complex state logic encapsulated in a [ViewModel<T>].
  final Widget Function(
      /// The current value of the reactive state.
      T state,

      /// The ViewModel that manages the internal logic and state updates.
      ViewModel<T> viewmodel,

      /// Function used to wrap widgets that should remain stable across rebuilds.
      Widget Function(Widget child) keep,
      )? build;

  /// Constructor that ensures either notifier or viewmodel is provided
  const ReactiveViewModelBuilder({super.key,
      required this.viewmodel,

    @Deprecated("Use 'build' instead. 'builder' will be removed in version 3.0.0.")
    required this.builder,
      this.build,
  });

  @override
  State<ReactiveViewModelBuilder<T>> createState() => _ReactiveBuilderStateViewModel<T>();
}

/// State class for ReactiveViewModelBuilder
class _ReactiveBuilderStateViewModel<T> extends State<ReactiveViewModelBuilder<T>> {
  /// Current value of the state
  late T value;

  /// Cache for widgets that shouldn't rebuild
  final Map<String, _NoRebuildWrapperViewModel> _noRebuildWidgets = {};

  @override
  void initState() {
    super.initState();
    // Initialize with data from either source
    value = widget.viewmodel.data;

    // Subscribe to changes from either source
    widget.viewmodel.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ReactiveViewModelBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewmodel != widget.viewmodel) {
      oldWidget.viewmodel.removeListener(_valueChanged);
      value = widget.viewmodel.data;
      widget.viewmodel.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    // Cleanup subscriptions and timer
    widget.viewmodel.removeListener(_valueChanged);

    // Handle auto-dispose if applicable
    if (widget.viewmodel is ReactiveNotifierViewModel) {
      final reactiveViewModel = widget.viewmodel as ReactiveNotifierViewModel;
      if (reactiveViewModel.autoDispose && !reactiveViewModel.notifier.hasListeners) {
        reactiveViewModel.dispose();
      }
    }
    super.dispose();
  }

  /// Handles state changes from the notifier
  void _valueChanged() {
    if (mounted) {
      setState(() {
        value = widget.viewmodel.data;
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
    return widget.build?.call(value, widget.viewmodel, _noRebuild) ??
        widget.builder(value, _noRebuild);
  }
}

/// Widget wrapper that prevents rebuilds of its children
/// Used by the _noRebuild function to optimize performance
class _NoRebuildWrapperViewModel extends StatefulWidget {
  /// The widget to be wrapped and prevented from rebuilding
  final Widget builder;

  const _NoRebuildWrapperViewModel({required this.builder});

  @override
  _NoRebuildWrapperStateViewModel createState() => _NoRebuildWrapperStateViewModel();
}

/// State for _NoRebuildWrapperViewModel
/// Maintains a single instance of the child widget
class _NoRebuildWrapperStateViewModel extends State<_NoRebuildWrapperViewModel> {
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
