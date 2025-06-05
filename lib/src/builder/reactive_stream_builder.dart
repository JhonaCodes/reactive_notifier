import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/handler/stream_state.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

import 'no_rebuild_wrapper.dart';

class ReactiveStreamBuilder<VM, T> extends StatefulWidget {
  final ReactiveNotifier<Stream<T>> notifier;

  /// Called when the reactive [Stream] emits a new data event.
  ///
  /// This function provides:
  /// - [data]: The latest value emitted by the stream.
  /// - [state]: The [ReactiveNotifier] that holds the current stream state and allows additional interactions.
  /// - [keep]: A helper function to wrap widgets that should avoid unnecessary rebuilds.
  ///
  /// Use this builder to render UI based on live stream data while keeping performance optimizations in place.
  final Widget Function(
    /// Latest value emitted by the stream.
    T data,

    /// The reactive state that wraps the stream and handles updates.
    VM viewmodel,

    /// Function to prevent unnecessary widget rebuilds.
    /// Wrap stable child widgets with this to preserve identity across builds.
    Widget Function(Widget child) keep,
  ) onData;
  final Widget Function()? onLoading;
  final Widget Function(Object error)? onError;
  final Widget Function()? onEmpty;
  final Widget Function()? onDone;

  const ReactiveStreamBuilder({
    super.key,
    required this.notifier,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.onDone,
  });

  @override
  State<ReactiveStreamBuilder<VM, T>> createState() =>
      _ReactiveStreamBuilderState<VM, T>();
}

class _ReactiveStreamBuilderState<VM, T>
    extends State<ReactiveStreamBuilder<VM, T>> {
  StreamSubscription<T>? _subscription;
  StreamState<T> _state = StreamState<T>.initial();
  final Map<String, NoRebuildWrapper> _noRebuildWidgets = {};

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onStreamChanged);
    _subscribe(widget.notifier.notifier);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onStreamChanged);
    _unsubscribe();
    super.dispose();
  }

  void _onStreamChanged() {
    _unsubscribe();
    _subscribe(widget.notifier.notifier);
  }

  void _subscribe(Stream<T> stream) {
    setState(() => _state = StreamState.loading());

    _subscription = stream.listen(
      (data) => setState(() => _state = StreamState.data(data)),
      onError: (error) => setState(() => _state = StreamState.error(error)),
      onDone: () => setState(() => _state = StreamState.done()),
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
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
    return _state.when(
      initial: () => widget.onEmpty?.call() ?? const SizedBox.shrink(),
      loading: () =>
          widget.onLoading?.call() ??
          const Center(child: CircularProgressIndicator.adaptive()),
      data: (data) => widget.onData(data, (widget.notifier as VM), _noRebuild),
      error: (error) =>
          widget.onError?.call(error) ?? Center(child: Text('Error: $error')),
      done: () => widget.onDone?.call() ?? const SizedBox.shrink(),
    );
  }
}
