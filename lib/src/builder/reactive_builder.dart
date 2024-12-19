import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/implements/notifier_impl.dart';

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
  Timer? debounceTimer;

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
    debounceTimer?.cancel();
    super.dispose();
  }

  void _valueChanged() {
    // Cancel any existing timer to prevent multiple updates within the debounce period.
    debounceTimer?.cancel();

    // Start a new timer. After 100 milliseconds, update the state and rebuild the widget.
    if (!isTesting) {
      debounceTimer = Timer(const Duration(milliseconds: 100), () {
        setState(() {
          value = widget.notifier.notifier;
        });
      });
    } else {
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
    return widget.builder( value, _noRebuild);
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

bool get isTesting => const bool.fromEnvironment('dart.vm.product') == true;



