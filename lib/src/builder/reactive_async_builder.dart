import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'no_rebuild_wrapper.dart';

class ReactiveAsyncBuilder<VM, T> extends StatefulWidget {
  final AsyncViewModelImpl<T> notifier;
  final Widget Function(T data)? onSuccess;

  /// Called when the asynchronous state is available and ready to render.
  ///
  /// - [data]: The latest data value emitted by the state (typically a model or primitive).
  /// - [state]: The associated [AsyncViewModelImpl] that contains internal logic, actions,
  ///   and mutation methods related to this state.
  /// - [keep]: A helper function used to wrap widgets that should be preserved across rebuilds,
  ///   preventing unnecessary widget reconstruction.
  ///
  /// This function is called only when the state has successfully loaded data.
  ///
  /// Example usage:
  /// ```dart
  /// onData: (data, viewModel, keep) {
  ///   return keep(
  ///     Text(data.title),
  ///   );
  /// }
  /// ```
  final Widget Function(
      T data, VM viewmodel, Widget Function(Widget child) keep)? onData;
  final Widget Function()? onLoading;
  final Widget Function(Object? error, StackTrace? stackTrace)? onError;
  final Widget Function()? onInitial;

  const ReactiveAsyncBuilder({
    super.key,
    required this.notifier,

    /// Called when the data has been successfully loaded.
    ///
    /// **Deprecated:** Use [onData] instead.
    /// This field will be removed in version **3.0.0**.
    @Deprecated(
        "Use 'onData' instead. 'onSuccess' will be removed in version 3.0.0.")
    this.onSuccess,
    this.onData,
    this.onLoading,
    this.onError,
    this.onInitial,
  });

  @override
  State<ReactiveAsyncBuilder<VM, T>> createState() =>
      _ReactiveAsyncBuilderState<VM, T>();
}

class _ReactiveAsyncBuilderState<VM, T>
    extends State<ReactiveAsyncBuilder<VM, T>> {
  final Map<String, NoRebuildWrapper> _noRebuildWidgets = {};

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ReactiveAsyncBuilder<VM, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_valueChanged);
      widget.notifier.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _noRebuild(Widget keep) {
    final key = keep.hashCode.toString();
    if (!_noRebuildWidgets.containsKey(key)) {
      _noRebuildWidgets[key] = NoRebuildWrapper(builder: keep);
    }
    return _noRebuildWidgets[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return widget.notifier.when(
      initial: () => widget.onInitial?.call() ?? const SizedBox.shrink(),
      loading: () =>
          widget.onLoading?.call() ??
          const Center(child: CircularProgressIndicator.adaptive()),
      success: (data) =>
          widget.onData?.call(data, (widget.notifier as VM), _noRebuild) ??
          widget.onSuccess?.call(data) ??
          const SizedBox.shrink(),
      error: (error, stackTrace) => widget.onError != null
          ? widget.onError!(error, stackTrace)
          : Center(child: Text('Error: $error')),
    );
  }
}

/// A widget that handles a Future and provides reactive notification
/// through a ReactiveNotifier to avoid flickering when navigating between screens.
///
/// This widget combines the functionality of Flutter's FutureBuilder with a reactive
/// state management approach, allowing immediate data display through [defaultData]
/// and notification of state changes through [createStateNotifier].
///
/// Example usage:
/// ```dart
/// ReactiveFutureBuilder<OrderItem?>(
///   future: OrderService.instance.notifier.loadById(orderId),
///   defaultData: OrderService.instance.notifier.getByPid(orderId),
///   createStateNotifier: OrderService.currentOrderItem,
///   onSuccess: (order) => ReactiveBuilder(
///     notifier: OrderService.currentOrderItem,
///     builder: (orderData, _) {
///       if (orderData == null) {
///         return const Text('Not found');
///       }
///       return OrderDetailView(order: orderData);
///     },
///   ),
///   onLoading: () => const Center(child: CircularProgressIndicator()),
///   onError: (error, stackTrace) => Center(child: Text('Error: $error')),
/// )
/// ```
///
/// In this example, the widget:
/// 1. Attempts to load data using a Future
/// 2. Shows default data immediately (if available) to prevent flickering
/// 3. Updates a ReactiveNotifier so other widgets can access the same data
/// 4. Handles loading, error, and success states appropriately
class ReactiveFutureBuilder<T> extends StatefulWidget {
  /// The Future that will provide the data.
  final Future<T> future;

  /// Builder function for rendering the UI when the Future completes successfully.
  /// Receives the data of type T from the Future.
  final Widget Function(T data) onSuccess;

  final Widget Function(T data, Widget Function(Widget child) keep)? onData;

  /// Optional builder function for the loading state.
  /// If not provided, a default CircularProgressIndicator will be shown.
  final Widget Function()? onLoading;

  /// Optional builder function for handling errors.
  /// Receives the error object and stack trace.
  final Widget Function(Object? error, StackTrace? stackTrace)? onError;

  /// Optional builder function for the initial state before the Future is processed.
  /// If not provided, a SizedBox.shrink() will be returned.
  final Widget Function()? onInitial;

  /// Optional ReactiveNotifier that will be updated with the data from the Future.
  /// This allows other widgets to react to data changes.
  final ReactiveNotifier<T>?
      createStateNotifier; // Not sure if we need for AsyncViewmodelImpl, maybe just use ReactiveNotifier

  /// Controls whether state updates should trigger UI rebuilds.
  /// - If true, updates will notify listeners and trigger rebuilds.
  /// - If false, updates will be silent and won't trigger rebuilds.
  final bool notifyChangesFromNewState;

  /// Optional default data to display immediately without waiting for the Future.
  /// This is particularly useful to avoid flickering when navigating back to a screen.
  /// If provided, the Future will still be executed, but the UI will show these data first.
  final T? defaultData;

  /// Creates a ReactiveFutureBuilder.
  ///
  /// The [future] and [onSuccess] parameters are required.
  /// All other parameters are optional.
  const ReactiveFutureBuilder({
    super.key,
    required this.future,
    @Deprecated("Use onData, contain keep function") required this.onSuccess,
    this.onData,
    this.onLoading,
    this.onError,
    this.onInitial,
    this.defaultData,
    this.createStateNotifier,
    this.notifyChangesFromNewState = false,
  });

  @override
  State<ReactiveFutureBuilder<T>> createState() =>
      _ReactiveFutureBuilderState<T>();
}

class _ReactiveFutureBuilderState<T> extends State<ReactiveFutureBuilder<T>> {
  final Map<String, NoRebuildWrapper> _noRebuildWidgets = {};

  /// Updates the ReactiveNotifier with new data.
  ///
  /// Uses [widget.notifyChangesFromNewState] to determine whether to call
  /// [updateState] or [updateSilently] on the notifier.
  void _onCreateNotify(T val) {
    if (widget.createStateNotifier != null) {
      widget.notifyChangesFromNewState
          ? widget.createStateNotifier!.updateState(val)
          : widget.createStateNotifier!.updateSilently(val);
    }
  }

  Widget _noRebuild(Widget keep) {
    final key = keep.hashCode.toString();
    if (!_noRebuildWidgets.containsKey(key)) {
      _noRebuildWidgets[key] = NoRebuildWrapper(builder: keep);
    }
    return _noRebuildWidgets[key]!;
  }

  @override
  void dispose() {
    if (widget.createStateNotifier != null) {
      widget.createStateNotifier!.cleanCurrentNotifier();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If default data is provided, show it immediately to avoid flickering
    if (widget.defaultData != null) {
      final defaultData = (widget.defaultData as T);
      _onCreateNotify(defaultData);
      if (widget.onData != null) return widget.onData!(defaultData, _noRebuild);
      return widget.onSuccess(defaultData);
    }

    // Otherwise, use a standard FutureBuilder
    return FutureBuilder<T>(
      future: widget.future,
      builder: (context, snapshot) {
        // Initial state - Future hasn't started processing
        if (!snapshot.hasData &&
            !snapshot.hasError &&
            snapshot.connectionState == ConnectionState.none) {
          return widget.onInitial?.call() ?? const SizedBox.shrink();
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.onLoading?.call() ??
              const Center(child: CircularProgressIndicator.adaptive());
        }

        // Error state
        if (snapshot.hasError) {
          return widget.onError != null
              ? widget.onError!(snapshot.error, snapshot.stackTrace)
              : Center(child: Text('Error: ${snapshot.error}'));
        }

        // Success state
        if (snapshot.hasData) {
          final response = snapshot.data as T;
          _onCreateNotify(response);
          return widget.onData?.call(response, _noRebuild) ??
              widget.onSuccess(response);
        } else {
          // Unexpected state (should rarely occur)
          return const Center(child: Text('Unexpected state'));
        }
      },
    );
  }
}
