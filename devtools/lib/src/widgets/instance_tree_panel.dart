import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import '../models/debug_data.dart';
import '../services/reactive_notifier_service.dart';
import 'state_editor_dialog.dart';

class InstanceTreePanel extends StatefulWidget {
  const InstanceTreePanel({super.key});

  @override
  State<InstanceTreePanel> createState() => _InstanceTreePanelState();
}

class _InstanceTreePanelState extends State<InstanceTreePanel> {
  late final ReactiveNotifierService _service;
  List<InstanceData> _instances = [];
  String _filter = '';
  String _sortBy = 'type';

  @override
  void initState() {
    super.initState();
    _service = ReactiveNotifierService();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _service.initialize();
    _service.debugDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _instances = data.instances;
        });
      }
    });
  }

  List<InstanceData> get _filteredInstances {
    var filtered = _instances.where((instance) {
      if (_filter.isEmpty) return true;
      return instance.type.toLowerCase().contains(_filter.toLowerCase()) ||
          instance.id.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    // Sort instances
    switch (_sortBy) {
      case 'type':
        filtered.sort((a, b) => a.type.compareTo(b.type));
        break;
      case 'created':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'updated':
        filtered.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
      case 'memory':
        filtered.sort((a, b) => b.memoryUsageKB.compareTo(a.memoryUsageKB));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlsSection(),
        Expanded(
          child: _buildInstanceList(),
        ),
      ],
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filter instances...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sortBy = value;
                });
              }
            },
            items: const [
              DropdownMenuItem(value: 'type', child: Text('Sort by Type')),
              DropdownMenuItem(value: 'created', child: Text('Sort by Created')),
              DropdownMenuItem(value: 'updated', child: Text('Sort by Updated')),
              DropdownMenuItem(value: 'memory', child: Text('Sort by Memory')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceList() {
    final instances = _filteredInstances;

    if (instances.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No instances found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: instances.length,
      itemBuilder: (context, index) {
        final instance = instances[index];
        return _buildInstanceCard(instance);
      },
    );
  }

  Widget _buildInstanceCard(InstanceData instance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: _buildInstanceIcon(instance),
        title: Text(
          instance.type,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'ID: ${instance.id.substring(0, 8)}... • '
          'Updates: ${instance.updateCount} • '
          'Memory: ${instance.memoryUsageKB.toStringAsFixed(1)} KB',
        ),
        trailing: instance.hasMemoryLeak
            ? Icon(Icons.warning, color: Colors.red[700])
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstanceDetails(instance),
                const SizedBox(height: 16),
                _buildInstanceActions(instance),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceIcon(InstanceData instance) {
    IconData icon;
    Color color;

    if (instance.type.contains('ViewModel')) {
      icon = Icons.view_module;
      color = Colors.blue;
    } else if (instance.type.contains('Async')) {
      icon = Icons.sync;
      color = Colors.orange;
    } else {
      icon = Icons.widgets;
      color = Colors.green;
    }

    if (instance.hasMemoryLeak) {
      color = Colors.red;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildInstanceDetails(InstanceData instance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instance Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Full ID', instance.id),
        _buildDetailRow('Type', instance.type),
        _buildDetailRow('Created', _formatDateTime(instance.createdAt)),
        _buildDetailRow('Last Updated', _formatDateTime(instance.lastUpdated)),
        _buildDetailRow('Update Count', '${instance.updateCount}'),
        _buildDetailRow('Listeners', '${instance.listeners.length}'),
        _buildDetailRow('Memory Usage', '${instance.memoryUsageKB} KB'),
        if (instance.hasMemoryLeak)
          _buildDetailRow('Memory Leak', 'DETECTED', Colors.red),
        const SizedBox(height: 16),
        Text(
          'Current State',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            instance.state,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        if (instance.listeners.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Listeners',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...instance.listeners.map((listener) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(listener)),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceActions(InstanceData instance) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showStateEditor(instance),
          icon: const Icon(Icons.edit),
          label: const Text('Edit State'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _exportInstance(instance),
          icon: const Icon(Icons.download),
          label: const Text('Export'),
        ),
        const SizedBox(width: 8),
        if (instance.hasMemoryLeak)
          ElevatedButton.icon(
            onPressed: () => _forceCleanup(instance),
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Force Cleanup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
              foregroundColor: Colors.red[700],
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.toLocal().toString().substring(0, 19)}';
  }

  void _showStateEditor(InstanceData instance) {
    showDialog(
      context: context,
      builder: (context) => StateEditorDialog(
        instance: instance,
        service: _service,
      ),
    ).then((result) {
      if (result == true) {
        // State was updated, refresh the list
        _service.refreshDebugData();
      }
    });
  }

  void _exportInstance(InstanceData instance) {
    // TODO: Implement instance export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported instance ${instance.id.substring(0, 8)}...'),
      ),
    );
  }

  void _forceCleanup(InstanceData instance) {
    // TODO: Implement force cleanup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleaned up instance ${instance.id.substring(0, 8)}...'),
      ),
    );
  }
}