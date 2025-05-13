import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

class ReactiveAsyncBuilder<T> extends StatefulWidget {
  final AsyncViewModelImpl<T> notifier;
  final Widget Function(T data) onSuccess;
  final Widget Function()? onLoading;
  final Widget Function(Object? error, StackTrace? stackTrace)? onError;
  final Widget Function()? onInitial;

  const ReactiveAsyncBuilder({
    super.key,
    required this.notifier,
    required this.onSuccess,
    this.onLoading,
    this.onError,
    this.onInitial,
  });

  @override
  State<ReactiveAsyncBuilder<T>> createState() => _ReactiveAsyncBuilderState<T>();
}

class _ReactiveAsyncBuilderState<T> extends State<ReactiveAsyncBuilder<T>> {

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ReactiveAsyncBuilder<T> oldWidget) {
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


  @override
  Widget build(BuildContext context) {
    return widget.notifier.when(
      initial: () => widget.onInitial?.call() ?? const SizedBox.shrink(),
      loading: () =>
      widget.onLoading?.call() ??
          const Center(child: CircularProgressIndicator.adaptive()),
      success: (data) => widget.onSuccess(data),
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
  final ReactiveNotifier<T>? createStateNotifier;// Not sure if we need for AsyncViewmodelImpl, maybe just use ReactiveNotifier

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
    required this.onSuccess,
    this.onLoading,
    this.onError,
    this.onInitial,
    this.defaultData,
    this.createStateNotifier,
    this.notifyChangesFromNewState = false,
  });

  @override
  State<ReactiveFutureBuilder<T>> createState() => _ReactiveFutureBuilderState<T>();
}

class _ReactiveFutureBuilderState<T> extends State<ReactiveFutureBuilder<T>> {
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


  @override
  void dispose() {
    if(widget.createStateNotifier != null){
      widget.createStateNotifier!.cleanCurrentNotifier();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If default data is provided, show it immediately to avoid flickering
    if (widget.defaultData != null) {
      _onCreateNotify(widget.defaultData!);
      return widget.onSuccess(widget.defaultData!);
    }

    // Otherwise, use a standard FutureBuilder
    return FutureBuilder<T>(
      future: widget.future,
      builder: (context, snapshot) {
        // Initial state - Future hasn't started processing
        if (!snapshot.hasData && !snapshot.hasError &&
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
          return widget.onSuccess(response);
        } else {
          // Unexpected state (should rarely occur)
          return const Center(child: Text('Unexpected state'));
        }
      },
    );
  }
}