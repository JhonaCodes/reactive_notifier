import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart' show ReactiveNotifier;
import 'package:reactive_notifier/src/notifier/notifier_impl.dart';

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
    if (mounted) {
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
