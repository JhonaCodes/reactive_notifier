import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:reactive_notifier_devtools_extension/reactive_notifier_stub.dart';

void main() {
  runApp(const ReactiveNotifierDevToolsExtension());
}

class ReactiveNotifierDevToolsExtension extends StatelessWidget {
  const ReactiveNotifierDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: ReactiveNotifierDevToolsScreen(),
    );
  }
}

class ReactiveNotifierDevToolsScreen extends StatefulWidget {
  const ReactiveNotifierDevToolsScreen({super.key});

  @override
  State<ReactiveNotifierDevToolsScreen> createState() =>
      _ReactiveNotifierDevToolsScreenState();
}

class _ReactiveNotifierDevToolsScreenState
    extends State<ReactiveNotifierDevToolsScreen> {
  List<Map<String, dynamic>> instances = [];
  bool isConnected = false;
  String connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  void _loadInstances() {
    // Get instances from ReactiveNotifier
    final activeInstances = ReactiveNotifier.getInstances;

    setState(() {
      instances = activeInstances.map((instance) {
        return {
          'type': instance.notifier.runtimeType.toString(),
          'key': instance.keyNotifier.toString(),
          'hasListeners': instance.hasListeners,
          'autoDispose': instance.autoDispose,
          'relatedCount': instance.related?.length ?? 0,
          'state': _getStateString(instance.notifier),
          'isViewModel':
              instance.notifier.runtimeType.toString().contains('ViewModel'),
        };
      }).toList();
    });
  }

  String _getStateString(dynamic notifier) {
    try {
      final stateStr = notifier.toString();
      return stateStr.length > 100
          ? '${stateStr.substring(0, 97)}...'
          : stateStr;
    } catch (e) {
      return 'Error getting state: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReactiveNotifier DevTools'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstances,
            tooltip: 'Refresh Instances',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              ReactiveNotifier.cleanup();
              _loadInstances();
            },
            tooltip: 'Clear All Instances',
          ),
        ],
      ),
      body: instances.isEmpty
          ? EmptyStateWidget(onRefresh: _loadInstances)
          : InstancesListWidget(
              instances: instances, onInstanceTap: _loadInstances),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const EmptyStateWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No ReactiveNotifier Instances',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create ReactiveNotifier instances in your app to monitor them here.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class InstancesListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> instances;
  final VoidCallback onInstanceTap;

  const InstancesListWidget({
    super.key,
    required this.instances,
    required this.onInstanceTap,
  });

  @override
  Widget build(BuildContext context) {
    final viewModels =
        instances.where((i) => i['isViewModel'] as bool).toList();
    final simple = instances.where((i) => !(i['isViewModel'] as bool)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryCardsWidget(instances: instances),
          const SizedBox(height: 24),
          if (viewModels.isNotEmpty) ...[
            DevToolsSectionHeader(
              title: 'ViewModels (${viewModels.length})',
              icon: Icons.view_module,
            ),
            const SizedBox(height: 8),
            ...viewModels.map((instance) => InstanceCard(instance: instance)),
            const SizedBox(height: 24),
          ],
          if (simple.isNotEmpty) ...[
            DevToolsSectionHeader(
              title: 'Simple Notifiers (${simple.length})',
              icon: Icons.circle,
            ),
            const SizedBox(height: 8),
            ...simple.map((instance) => InstanceCard(instance: instance)),
          ],
        ],
      ),
    );
  }
}

class SummaryCardsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> instances;

  const SummaryCardsWidget({super.key, required this.instances});

  @override
  Widget build(BuildContext context) {
    final total = instances.length;
    final viewModelCount =
        instances.where((i) => i['isViewModel'] as bool).length;
    final withoutListeners =
        instances.where((i) => !(i['hasListeners'] as bool)).length;

    return Row(
      children: [
        Expanded(
            child: SummaryCard(
                title: 'Total',
                value: '$total',
                icon: Icons.memory,
                color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(
            child: SummaryCard(
                title: 'ViewModels',
                value: '$viewModelCount',
                icon: Icons.view_module,
                color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(
            child: SummaryCard(
                title: 'Simple',
                value: '${total - viewModelCount}',
                icon: Icons.circle,
                color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(
            child: SummaryCard(
          title: 'No Listeners',
          value: '$withoutListeners',
          icon: withoutListeners > 0 ? Icons.warning : Icons.check,
          color: withoutListeners > 0 ? Colors.red : Colors.green,
        )),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class DevToolsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const DevToolsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class InstanceCard extends StatelessWidget {
  final Map<String, dynamic> instance;

  const InstanceCard({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    final type = instance['type'] as String;
    final key = instance['key'] as String;
    final hasListeners = instance['hasListeners'] as bool;
    final autoDispose = instance['autoDispose'] as bool;
    final relatedCount = instance['relatedCount'] as int;
    final state = instance['state'] as String;
    final isViewModel = instance['isViewModel'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          isViewModel ? Icons.view_module : Icons.circle,
          color: isViewModel ? Colors.green : Colors.blue,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                type,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hasListeners ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasListeners ? 'ACTIVE' : 'IDLE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Key: $key',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailRow(label: '🔑 Key', value: key),
                DetailRow(
                    label: '📡 Has Listeners',
                    value: hasListeners ? 'Yes ✅' : 'No ❌'),
                DetailRow(
                    label: '🗑️ Auto Dispose',
                    value: autoDispose ? 'Enabled' : 'Disabled'),
                if (relatedCount > 0)
                  DetailRow(
                      label: '🔗 Related States',
                      value: '$relatedCount connected'),
                DetailRow(
                    label: '📊 Type',
                    value:
                        isViewModel ? 'Complex ViewModel' : 'Simple Notifier'),
                const SizedBox(height: 8),
                const Text('📋 Current State:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    state,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
