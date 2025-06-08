import 'dart:developer';

import 'package:flutter/material.dart';

class NoRebuildWrapper extends StatefulWidget {
  final Widget child;

  const NoRebuildWrapper({super.key, required this.child});

  @override
  NoRebuildWrapperState createState() => NoRebuildWrapperState();
}

class NoRebuildWrapperState extends State<NoRebuildWrapper> {
  late Widget _child;

  @override
  void initState() {
    super.initState();
    _child = widget.child;
  }

  @override
  void didUpdateWidget(covariant NoRebuildWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      log('Rebuild on keep old key: ${oldWidget.key.hashCode}  new key: ${widget.key.hashCode}');
      // Warning: this breaks the "no rebuild" contract but is safer.
      _child = widget.child;
    }
  }

  @override
  Widget build(BuildContext context) => _child;
}
