import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart' show ReactiveNotifier;
import 'package:reactive_notifier/src/notifier/notifier_impl.dart';

import 'no_rebuild_wrapper.dart';

/// Reactive Builder for simple state or direct model state.
class ReactiveBuilder<T> extends StatefulWidget {
  final NotifierImpl<T> notifier;
  final Widget Function(
    T state,
    Widget Function(Widget child) keep,
  )? builder;

  /// Builds the widget based on the current reactive state.
  ///
  /// This function provides:
  /// - [state]: The current reactive value of type `T`.
  /// - [notifier]: The internal [NotifierImpl<T>] containing state update methods and logic.
  /// - [keep]: A wrapper function used to prevent unnecessary widget rebuilds by maintaining widget identity.
  ///
  /// Useful for customizing the UI based on reactive changes while having full access to state logic and optimization tools.
  final Widget Function(
    /// The current state value.
    T state,

    /// The notifier instance that provides update methods and internal logic.
    NotifierImpl<T> notifier,

    /// A wrapper that helps prevent unnecessary rebuilds.
    /// Wrap any widget that should remain stable between state updates.
    Widget Function(Widget child) keep,
  )? build;

  const ReactiveBuilder(
      {super.key,
      required this.notifier,
      @Deprecated(
          "Use 'build' instead. 'builder' will be removed in version 3.0.0.")
      this.builder,
      this.build});

  @override
  State<ReactiveBuilder<T>> createState() => _ReactiveBuilderState<T>();
}

class _ReactiveBuilderState<T> extends State<ReactiveBuilder<T>> {
  late T value;
  final HashMap<Key, NoRebuildWrapper> _noRebuildWidgets = HashMap.from({});

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

    _noRebuildWidgets.clear();

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
    final key = keep.key ?? ValueKey(keep.hashCode + keep.runtimeType.hashCode);
    if (!_noRebuildWidgets.containsKey(key)) {
      _noRebuildWidgets[key] = NoRebuildWrapper(child: keep);
    }
    return _noRebuildWidgets[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return widget.build?.call(value, widget.notifier, _noRebuild) ??
        widget.builder?.call(value, _noRebuild) ??
        const SizedBox.shrink();
  }
}
