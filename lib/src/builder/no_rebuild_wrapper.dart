import 'package:flutter/material.dart';

class NoRebuildWrapper extends StatefulWidget {
  final Widget builder;

  const NoRebuildWrapper({super.key, required this.builder});

  @override
  NoRebuildWrapperState createState() => NoRebuildWrapperState();
}

class NoRebuildWrapperState extends State<NoRebuildWrapper> {
  late Widget child;

  @override
  void initState() {
    super.initState();
    child = widget.builder;
  }

  @override
  Widget build(BuildContext context) => child;
}
