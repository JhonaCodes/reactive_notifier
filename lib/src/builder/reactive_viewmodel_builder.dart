import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/context/viewmodel_context_notifier.dart';

/// [ReactiveViewModelBuilder]
/// ReactiveViewModelBuilder is a specialized widget for handling ViewModel states
/// It's designed to work specifically with StateNotifierImpl implementations
/// and provides efficient state management and rebuilding mechanisms
///
class ReactiveViewModelBuilder<VM, T> extends StatefulWidget {
  /// New ViewModel approach, takes precedence over notifier if both are provided
  final ViewModel<T> viewmodel;

  /// Builder function that creates the widget tree
  final Widget Function(
    T viewmodel,
    Widget Function(Widget child) keep,
  )? builder;

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
    VM viewmodel,

    /// Function used to wrap widgets that should remain stable across rebuilds.
    Widget Function(Widget child) keep,
  )? build;

  /// Constructor that ensures either notifier or viewmodel is provided
  const ReactiveViewModelBuilder({
    super.key,
    required this.viewmodel,
    @Deprecated(
        "Use 'build' instead. 'builder' will be removed in version 3.0.0.")
    this.builder,
    this.build,
  });

  @override
  State<ReactiveViewModelBuilder<VM, T>> createState() =>
      _ReactiveBuilderStateViewModel<VM, T>();
}

/// State class for ReactiveViewModelBuilder
class _ReactiveBuilderStateViewModel<VM, T>
    extends State<ReactiveViewModelBuilder<VM, T>> {
  /// Current value of the state
  late T value;

  /// Cache for widgets that shouldn't rebuild
  final HashMap<Key, _NoRebuildWrapperViewModel> _noRebuildWidgets =
      HashMap.from({});

  @override
  void initState() {
    super.initState();
    
    // Register context BEFORE accessing the viewmodel to ensure it's available during init()
    // Use unique identifier for each builder instance to handle multiple builders for same ViewModel
    final uniqueBuilderType = 'ReactiveViewModelBuilder<$VM,$T>_${hashCode}';
    context.registerForViewModels(uniqueBuilderType, widget.viewmodel);
    
    // Add reference for widget-aware lifecycle if viewmodel is from ReactiveNotifier
    // We need to find the parent ReactiveNotifier that contains this ViewModel
    _addReferenceToParentNotifier();
    
    // Re-initialize ViewModels that were created without context
    if (widget.viewmodel is ViewModel) {
      (widget.viewmodel as ViewModel).reinitializeWithContext();
    }
    
    // Initialize with data from either source
    value = widget.viewmodel.data;

    // Subscribe to changes from either source
    widget.viewmodel.addListener(_valueChanged);
  }

  /// Find and add reference to the parent ReactiveNotifier that contains this ViewModel
  void _addReferenceToParentNotifier() {
    try {
      // Look for a ReactiveNotifier that contains this ViewModel
      final instances = ReactiveNotifier.getInstances;
      for (final instance in instances) {
        if (instance.notifier == widget.viewmodel) {
          // Found the ReactiveNotifier containing this ViewModel
          instance.addReference('ReactiveViewModelBuilder_${hashCode}');
          break;
        }
      }
    } catch (e) {
      // If we can't find the parent ReactiveNotifier, that's okay
      // This ViewModel might be used directly without ReactiveNotifier wrapper
    }
  }

  @override
  void didUpdateWidget(ReactiveViewModelBuilder<VM, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewmodel != widget.viewmodel) {
      // Remove reference from old viewmodel's parent ReactiveNotifier
      _removeReferenceFromParentNotifier(oldWidget.viewmodel);
      
      oldWidget.viewmodel.removeListener(_valueChanged);
      value = widget.viewmodel.data;
      widget.viewmodel.addListener(_valueChanged);
      
      // Add reference to new viewmodel's parent ReactiveNotifier
      _addReferenceToParentNotifier();
    }
  }

  /// Find and remove reference from the parent ReactiveNotifier that contains this ViewModel
  void _removeReferenceFromParentNotifier(dynamic viewmodel) {
    try {
      // Look for a ReactiveNotifier that contains this ViewModel
      final instances = ReactiveNotifier.getInstances;
      for (final instance in instances) {
        if (instance.notifier == viewmodel) {
          // Found the ReactiveNotifier containing this ViewModel
          instance.removeReference('ReactiveViewModelBuilder_${hashCode}');
          break;
        }
      }
    } catch (e) {
      // If we can't find the parent ReactiveNotifier, that's okay
      // This ViewModel might be used directly without ReactiveNotifier wrapper
    }
  }

  @override
  void dispose() {
    // Cleanup subscriptions and timer
    widget.viewmodel.removeListener(_valueChanged);
    
    // Remove reference from parent ReactiveNotifier
    _removeReferenceFromParentNotifier(widget.viewmodel);
    
    // Automatically unregister context using the same unique identifier
    final uniqueBuilderType = 'ReactiveViewModelBuilder<$VM,$T>_${hashCode}';
    context.unregisterFromViewModels(uniqueBuilderType, widget.viewmodel);

    // Handle auto-dispose if applicable
    if (widget.viewmodel is ReactiveNotifierViewModel) {
      final reactiveViewModel = widget.viewmodel as ReactiveNotifierViewModel;
      if (reactiveViewModel.autoDispose &&
          !reactiveViewModel.notifier.hasListeners) {
        reactiveViewModel.dispose();
      }
    }

    _noRebuildWidgets.clear();

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
    final key = keep.key ?? ValueKey(keep.hashCode);
    if (!_noRebuildWidgets.containsKey(key)) {
      _noRebuildWidgets[key] = _NoRebuildWrapperViewModel(builder: keep);
    }
    return _noRebuildWidgets[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return widget.build?.call(value, (widget.viewmodel as VM), _noRebuild) ??
        widget.builder?.call(value, _noRebuild) ??
        const SizedBox.shrink();
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
