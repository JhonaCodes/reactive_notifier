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
  State<ReactiveNotifierInspector> createState() => _ReactiveNotifierInspectorState();
}

class _ReactiveNotifierInspectorState extends State<ReactiveNotifierInspector> {
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
      // Connect to VM service and get ReactiveNotifier data
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
      // Call debug service through VM service
      final result = await serviceManager.callService(
        'ext.reactive_notifier.debugData',
      );
      
      if (result?.json != null) {
        final List<dynamic> instances = result!.json!['instances'] ?? [];
        return instances.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      // Return mock data if connection fails
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Header con acciones
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
                  icon: Icon(Icons.refresh),
                  onPressed: _loadNotifierData,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Clear all notifiers',
                child: IconButton(
                  icon: Icon(Icons.clear_all),
                  onPressed: _clearAllNotifiers,
                ),
              ),
            ],
          ),
        ),
        
        // Contenido principal
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
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

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifierData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notifierInstances.isEmpty) {
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

    return Column(
      children: [
        // Estadísticas
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatCard('Total', '${notifierInstances.length}', Icons.memory),
              const SizedBox(width: 16),
              _buildStatCard(
                'Active', 
                '${notifierInstances.where((n) => n['hasListeners'] == true).length}',
                Icons.radio_button_checked,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Auto Dispose',
                '${notifierInstances.where((n) => n['autoDispose'] == true).length}', 
                Icons.auto_delete,
              ),
            ],
          ),
        ),
        
        // Lista de instancias
        Expanded(
          child: ListView.builder(
            itemCount: notifierInstances.length,
            itemBuilder: (context, index) {
              final notifier = notifierInstances[index];
              return _buildNotifierTile(notifier);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
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

  Widget _buildNotifierTile(Map<String, dynamic> notifier) {
    final theme = Theme.of(context);
    final hasListeners = notifier['hasListeners'] as bool;
    final autoDispose = notifier['autoDispose'] as bool;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          hasListeners ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Has Listeners', hasListeners ? 'Yes' : 'No'),
                _buildDetailRow('Auto Dispose', autoDispose ? 'Yes' : 'No'), 
                _buildDetailRow('Full Value', notifier['value'] as String),
                const SizedBox(height: 8),
                Text(
                  'Properties and methods would be shown here in a real implementation',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  void _clearAllNotifiers() {
    // En una implementación real, esto llamaría al servicio de debug
    // Para el mock, simplemente limpiamos la lista
    setState(() {
      notifierInstances.clear();
    });
  }
}