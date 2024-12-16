import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

class ReactiveFutureBuilder<T> extends StatefulWidget {
  final Future<T> Function() futureBuilder;
  final Widget Function(T data)? onData;
  final Widget Function(Object error, StackTrace? stackTrace) onError;
  final Widget Function()? onLoading;
  final bool autoLoad;

  const ReactiveFutureBuilder({
    super.key,
    required this.futureBuilder,
    this.onData,
    required this.onError,
    this.onLoading,
    this.autoLoad = true,
  });

  @override
  _ReactiveFutureBuilderState<T> createState() => _ReactiveFutureBuilderState<T>();
}

class _ReactiveFutureBuilderState<T> extends State<ReactiveFutureBuilder<State>> {
  AsyncState<State> _state = AsyncState.initial();
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    if (widget.autoLoad) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_state.isLoading) return;

    setState(() {
      _state = AsyncState.loading();
    });

    try {
      final result = await widget.futureBuilder();
      if (!_isMounted) return;

      setState(() {
        _state = AsyncState.success(result);
      });
    } catch (error, stackTrace) {
      if (!_isMounted) return;

      setState(() {
        _state = AsyncState.error(error, stackTrace);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _state.when(
      initial: () => widget.onLoading?.call() ?? const SizedBox.shrink(),
      loading: () => widget.onLoading?.call() ??
          const Center(child: CircularProgressIndicator.adaptive()),
      success: (data) => widget.onData?.call(data) ?? const SizedBox.shrink(),
      error: (error, stackTrace) {

        if(error != null) return widget.onError(error, stackTrace);

        return const SizedBox.shrink();
      },
    );
  }

  void reload() {
    _loadData();
  }
}