import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ReactiveNotifierDevToolsExtension());
}

class ReactiveNotifierDevToolsExtension extends StatelessWidget {
  const ReactiveNotifierDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: ReactiveNotifierInspector(),
    );
  }
}

class ReactiveNotifierInspector extends StatefulWidget {
  const ReactiveNotifierInspector({super.key});

  @override
  State<ReactiveNotifierInspector> createState() =>
      _ReactiveNotifierInspectorState();
}

class _ReactiveNotifierInspectorState
    extends State<ReactiveNotifierInspector> {
  List<Map<String, dynamic>> notifierInstances = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadNotifierData();
  }

  void _loadNotifierData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final instances = await _getReactiveNotifierInstances();

      setState(() {
        notifierInstances = instances;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getReactiveNotifierInstances() async {
    try {
      final result = await serviceManager.callService(
        'ext.reactive_notifier.debugData',
      );

      if (result?.json != null) {
        final List<dynamic> instances = result!.json!['instances'] ?? [];
        return instances.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 200));
      return [
        {
          'id': 'CounterService_count',
          'type': 'ReactiveNotifier<int>',
          'value': '5',
          'hasListeners': true,
          'autoDispose': false,
        },
        {
          'id': 'UserService_user',
          'type': 'UserViewModel',
          'value': 'UserModel(name: John, age: 25)',
          'hasListeners': true,
          'autoDispose': false,
        },
      ];
    }
  }

  void _clearAllNotifiers() {
    setState(() {
      notifierInstances.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.memory, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ReactiveNotifier Inspector',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Refresh data',
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadNotifierData,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Clear all notifiers',
                  child: IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: _clearAllNotifiers,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InspectorContent(
              isLoading: isLoading,
              error: error,
              notifierInstances: notifierInstances,
              onRetry: _loadNotifierData,
            ),
          ),
        ],
      ),
    );
  }
}

class InspectorContent extends StatelessWidget {
  const InspectorContent({
    super.key,
    required this.isLoading,
    required this.error,
    required this.notifierInstances,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> notifierInstances;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingView();
    }

    if (error != null) {
      return ErrorView(error: error!, onRetry: onRetry);
    }

    if (notifierInstances.isEmpty) {
      return const EmptyView();
    }

    return NotifierListView(notifierInstances: notifierInstances);
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading ReactiveNotifier data...'),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No ReactiveNotifier instances found'),
          SizedBox(height: 8),
          Text(
            'Create some notifiers in your app to see them here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class NotifierListView extends StatelessWidget {
  const NotifierListView({
    super.key,
    required this.notifierInstances,
  });

  final List<Map<String, dynamic>> notifierInstances;

  @override
  Widget build(BuildContext context) {
    final activeCount = notifierInstances
        .where((n) => n['hasListeners'] == true)
        .length;
    final autoDisposeCount = notifierInstances
        .where((n) => n['autoDispose'] == true)
        .length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              StatCard(
                label: 'Total',
                value: '${notifierInstances.length}',
                icon: Icons.memory,
              ),
              const SizedBox(width: 16),
              StatCard(
                label: 'Active',
                value: '$activeCount',
                icon: Icons.radio_button_checked,
              ),
              const SizedBox(width: 16),
              StatCard(
                label: 'Auto Dispose',
                value: '$autoDisposeCount',
                icon: Icons.auto_delete,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: notifierInstances.length,
            itemBuilder: (context, index) {
              return NotifierTile(notifier: notifierInstances[index]);
            },
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotifierTile extends StatelessWidget {
  const NotifierTile({
    super.key,
    required this.notifier,
  });

  final Map<String, dynamic> notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasListeners = notifier['hasListeners'] as bool;
    final autoDispose = notifier['autoDispose'] as bool;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          hasListeners
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: hasListeners ? Colors.green : Colors.grey,
        ),
        title: Text(
          notifier['type'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${notifier['id']}'),
            Text(
              'Value: ${notifier['value']}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: NotifierDetails(
              hasListeners: hasListeners,
              autoDispose: autoDispose,
              value: notifier['value'] as String,
            ),
          ),
        ],
      ),
    );
  }
}

class NotifierDetails extends StatelessWidget {
  const NotifierDetails({
    super.key,
    required this.hasListeners,
    required this.autoDispose,
    required this.value,
  });

  final bool hasListeners;
  final bool autoDispose;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRow(label: 'Has Listeners', value: hasListeners ? 'Yes' : 'No'),
        DetailRow(label: 'Auto Dispose', value: autoDispose ? 'Yes' : 'No'),
        DetailRow(label: 'Full Value', value: value),
        const SizedBox(height: 8),
        Text(
          'Properties and methods would be shown here in a real implementation',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
