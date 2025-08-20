import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/reactive_notifier_extension.dart';

void main() {
  runApp(const ReactiveNotifierDevToolsExtension());
}

class ReactiveNotifierDevToolsExtension extends StatelessWidget {
  const ReactiveNotifierDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: ReactiveNotifierExtensionScreen(),
    );
  }
}