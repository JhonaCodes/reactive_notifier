import 'dart:async';
import 'dart:convert';

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
  bool isLoading = true;
  bool isConnected = false;
  String? error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadInstancesFromService();
    // Auto-refresh every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadInstancesFromService();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInstancesFromService() async {
    try {
      // Call the VM Service extension using the new API
      final service = serviceManager.service;
      if (service == null) {
        throw Exception('VM Service not available');
      }

      final response = await service.callServiceExtension(
        'ext.reactive_notifier.getData',
      );

      final data = response.json;
      if (data != null) {
        final instancesData = data['instances'] as List<dynamic>?;

        if (!mounted) return;

        setState(() {
          instances = instancesData
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];
          isConnected = true;
          isLoading = false;
          error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Failed to connect to service: $e';
        isLoading = false;
        isConnected = false;
      });
    }
  }

  Future<void> _handleCleanup() async {
    try {
      final service = serviceManager.service;
      if (service == null) {
        throw Exception('VM Service not available');
      }

      await service.callServiceExtension(
        'ext.reactive_notifier.cleanup',
      );
      _loadInstancesFromService();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Failed to cleanup: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.memory, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 12),
            const Text('ReactiveNotifier DevTools'),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // Connection status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.circle : Icons.error_outline,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstancesFromService,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Instances?'),
                  content: const Text(
                    'This will dispose all ReactiveNotifier instances. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleCleanup();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear All Instances',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to ReactiveNotifier service...'),
          ],
        ),
      );
    }

    if (error != null && !isConnected) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 24),
              Text(
                'Connection Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInstancesFromService,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Troubleshooting',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Make sure your app is running in debug mode\n'
                        '2. Add initializeReactiveNotifierDevTools() to main()\n'
                        '3. Ensure reactive_notifier 2.13.0+ is installed\n'
                        '4. Check that you have ReactiveNotifier instances created',
                        style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (instances.isEmpty) {
      return EmptyStateWidget(onRefresh: _loadInstancesFromService);
    }

    return InstancesListWidget(
      instances: instances,
      onRefresh: _loadInstancesFromService,
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
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No ReactiveNotifier Instances',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create ReactiveNotifier instances in your app to monitor them here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
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
  final VoidCallback onRefresh;

  const InstancesListWidget({
    super.key,
    required this.instances,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final viewModels = instances.where((i) => i['isViewModel'] == true).toList();
    final asyncVMs = instances.where((i) => i['isAsync'] == true).toList();
    final simple = instances
        .where((i) => i['isViewModel'] == false && i['isAsync'] == false)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          SummaryCardsWidget(instances: instances),
          const SizedBox(height: 32),

          // Async ViewModels section
          if (asyncVMs.isNotEmpty) ...[
            DevToolsSectionHeader(
              title: 'Async ViewModels (${asyncVMs.length})',
              icon: Icons.cloud_sync,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            ...asyncVMs.map((instance) => InstanceCard(instance: instance)),
            const SizedBox(height: 24),
          ],

          // ViewModels section
          if (viewModels.isNotEmpty) ...[
            DevToolsSectionHeader(
              title: 'ViewModels (${viewModels.length})',
              icon: Icons.view_module,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            ...viewModels.map((instance) => InstanceCard(instance: instance)),
            const SizedBox(height: 24),
          ],

          // Simple notifiers section
          if (simple.isNotEmpty) ...[
            DevToolsSectionHeader(
              title: 'Simple Notifiers (${simple.length})',
              icon: Icons.circle,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
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
    final asyncVMs = instances.where((i) => i['isAsync'] == true).length;
    final viewModels = instances.where((i) => i['isViewModel'] == true).length;
    final autoDispose = instances.where((i) => i['autoDispose'] == true).length;

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'Total',
            value: '$total',
            icon: Icons.memory,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            title: 'Async VMs',
            value: '$asyncVMs',
            icon: Icons.cloud_sync,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            title: 'ViewModels',
            value: '$viewModels',
            icon: Icons.view_module,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            title: 'Auto Dispose',
            value: '$autoDispose',
            icon: Icons.auto_delete,
            color: autoDispose > 0 ? Colors.orange : Colors.grey,
          ),
        ),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DevToolsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const DevToolsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class InstanceCard extends StatelessWidget {
  final Map<String, dynamic> instance;

  const InstanceCard({super.key, required this.instance});

  Color _getStateColor(String stateType) {
    switch (stateType) {
      case 'loading':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(String stateType) {
    switch (stateType) {
      case 'loading':
        return Icons.hourglass_empty;
      case 'error':
        return Icons.error;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = instance['type'] as String;
    final key = instance['key'] as String;
    final hasListeners = instance['hasListeners'] as bool;
    final autoDispose = instance['autoDispose'] as bool;
    final referenceCount = instance['referenceCount'] as int;
    final relatedCount = instance['relatedCount'] as int;
    final statePreview = instance['statePreview'] as String;
    final stateType = instance['stateType'] as String;
    final isAsync = instance['isAsync'] as bool;
    final isViewModel = instance['isViewModel'] as bool;

    final stateColor = _getStateColor(stateType);
    final stateIcon = _getStateIcon(stateType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAsync
                ? Colors.purple.withOpacity(0.1)
                : isViewModel
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isAsync
                ? Icons.cloud_sync
                : isViewModel
                    ? Icons.view_module
                    : Icons.circle,
            color: isAsync
                ? Colors.purple
                : isViewModel
                    ? Colors.green
                    : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            // State badge for async
            if (isAsync) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: stateColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(stateIcon, size: 14, color: stateColor),
                    const SizedBox(width: 4),
                    Text(
                      stateType.toUpperCase(),
                      style: TextStyle(
                        color: stateColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Active/Idle badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    hasListeners ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hasListeners ? Colors.green : Colors.grey),
              ),
              child: Text(
                hasListeners ? 'ACTIVE' : 'IDLE',
                style: TextStyle(
                  color: hasListeners ? Colors.green : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            statePreview,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailRow(label: '🔑 Key', value: key),
                const SizedBox(height: 8),
                DetailRow(
                  label: '📡 Listeners',
                  value: hasListeners ? 'Active (Has listeners)' : 'Idle (No listeners)',
                ),
                const SizedBox(height: 8),
                DetailRow(
                  label: '👥 References',
                  value: '$referenceCount active reference(s)',
                ),
                const SizedBox(height: 8),
                DetailRow(
                  label: '🗑️ Auto Dispose',
                  value: autoDispose ? 'Enabled' : 'Disabled',
                ),
                if (relatedCount > 0) ...[
                  const SizedBox(height: 8),
                  DetailRow(
                    label: '🔗 Related',
                    value: '$relatedCount related state(s)',
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  '📋 Full State:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    statePreview,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
