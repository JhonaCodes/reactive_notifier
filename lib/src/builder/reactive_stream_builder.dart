import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/handler/stream_state.dart';
import 'package:reactive_notifier/src/reactive_notifier.dart';

class ReactiveStreamBuilder<T> extends StatefulWidget {
  final ReactiveNotifier<Stream<T>> streamNotifier;
  final Widget Function(T data) buildData;
  final Widget Function()? buildLoading;
  final Widget Function(Object error)? buildError;
  final Widget Function()? buildEmpty;
  final Widget Function()? buildDone;

  const ReactiveStreamBuilder({
    super.key,
    required this.streamNotifier,
    required this.buildData,
    this.buildLoading,
    this.buildError,
    this.buildEmpty,
    this.buildDone,
  });

  @override
  State<ReactiveStreamBuilder<T>> createState() =>
      _ReactiveStreamBuilderState<T>();
}

class _ReactiveStreamBuilderState<T> extends State<ReactiveStreamBuilder<T>> {
  StreamSubscription<T>? _subscription;
  StreamState<T> _state = StreamState<T>.initial();

  @override
  void initState() {
    super.initState();
    widget.streamNotifier.addListener(_onStreamChanged);
    _subscribe(widget.streamNotifier.notifier);
  }

  @override
  void dispose() {
    widget.streamNotifier.removeListener(_onStreamChanged);
    _unsubscribe();
    super.dispose();
  }

  void _onStreamChanged() {
    _unsubscribe();
    _subscribe(widget.streamNotifier.notifier);
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

  @override
  Widget build(BuildContext context) {
    return _state.when(
      initial: () => widget.buildEmpty?.call() ?? const SizedBox.shrink(),
      loading: () =>
          widget.buildLoading?.call() ??
          const Center(child: CircularProgressIndicator.adaptive()),
      data: (data) => widget.buildData(data),
      error: (error) =>
          widget.buildError?.call(error) ??
          Center(child: Text('Error: $error')),
      done: () => widget.buildDone?.call() ?? const SizedBox.shrink(),
    );
  }
}
