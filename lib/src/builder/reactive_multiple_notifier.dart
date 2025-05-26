import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'no_rebuild_wrapper.dart';

/// Reactive Builder for simple state or direct model state.
class ReactiveMultipleNotifierBuilder<T> extends StatefulWidget {
  final List<ViewModel<T>> notifier;
  final Widget Function(
      List<T> state,
      Widget Function(Widget child) keep,
      ) builder;

  const ReactiveMultipleNotifierBuilder({
    super.key,
    required this.notifier,
    required this.builder,
  });

  @override
  State<ReactiveMultipleNotifierBuilder<T>> createState() => _ReactiveMultipleNotifierBuilderState<T>();
}

class _ReactiveMultipleNotifierBuilderState<T> extends State<ReactiveMultipleNotifierBuilder<T>> {
  late List<T> value;
  final Map<String, NoRebuildWrapper> _noRebuildWidgets = {};

  @override
  void initState() {
    super.initState();
    value = List.generate(widget.notifier.length, (index) => widget.notifier[index].data);
    for (final its in widget.notifier) {
      its.addListener(_valueChanged);
    }
  }

  @override
  void didUpdateWidget(ReactiveMultipleNotifierBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier.any((it) => widget.notifier.contains(it))) {
      for (final its in oldWidget.notifier) {
        its.removeListener(_valueChanged);
      }
      value = List.generate(widget.notifier.length, (index) => widget.notifier[index].data);
      for (final its in widget.notifier) {
        its.addListener(_valueChanged);
      }
    }
  }

  @override
  void dispose() {

    for (final its in widget.notifier) {
      its.removeListener(_valueChanged);
    }

    if (widget.notifier.any((it) => it is ReactiveNotifier)) {
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
        value = List.generate(widget.notifier.length, (index) => widget.notifier[index].data);
      });
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
    return widget.builder(value, _noRebuild);
  }
}