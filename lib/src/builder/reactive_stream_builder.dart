import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/handler/stream_state.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';

class ReactiveStreamBuilder<T> extends StatefulWidget {
  final ReactiveNotifier<Stream<T>> notifier;
  final Widget Function(T data) onData;
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
  State<ReactiveStreamBuilder<T>> createState() =>
      _ReactiveStreamBuilderState<T>();
}

class _ReactiveStreamBuilderState<T> extends State<ReactiveStreamBuilder<T>> {
  StreamSubscription<T>? _subscription;
  StreamState<T> _state = StreamState<T>.initial();

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

  @override
  Widget build(BuildContext context) {
    return _state.when(
      initial: () => widget.onEmpty?.call() ?? const SizedBox.shrink(),
      loading: () =>
          widget.onLoading?.call() ??
          const Center(child: CircularProgressIndicator.adaptive()),
      data: (data) => widget.onData(data),
      error: (error) =>
          widget.onError?.call(error) ?? Center(child: Text('Error: $error')),
      done: () => widget.onDone?.call() ?? const SizedBox.shrink(),
    );
  }
}
