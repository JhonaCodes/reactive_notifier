import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'widgets/debug_dashboard.dart';
import 'widgets/instance_tree_panel.dart';
import 'widgets/performance_panel.dart';
import 'widgets/state_inspector_panel.dart';

class ReactiveNotifierExtensionScreen extends StatefulWidget {
  const ReactiveNotifierExtensionScreen({super.key});

  @override
  State<ReactiveNotifierExtensionScreen> createState() =>
      _ReactiveNotifierExtensionScreenState();
}

class _ReactiveNotifierExtensionScreenState
    extends State<ReactiveNotifierExtensionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  static const List<Tab> _tabs = [
    Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
    Tab(text: 'Instances', icon: Icon(Icons.account_tree)),
    Tab(text: 'State Inspector', icon: Icon(Icons.search)),
    Tab(text: 'Performance', icon: Icon(Icons.analytics)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReactiveNotifier DevTools'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DebugDashboard(),
          InstanceTreePanel(),
          StateInspectorPanel(),
          PerformancePanel(),
        ],
      ),
    );
  }
}