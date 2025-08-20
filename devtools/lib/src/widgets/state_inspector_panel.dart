import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import '../models/debug_data.dart';
import '../services/reactive_notifier_service.dart';

class StateInspectorPanel extends StatefulWidget {
  const StateInspectorPanel({super.key});

  @override
  State<StateInspectorPanel> createState() => _StateInspectorPanelState();
}

class _StateInspectorPanelState extends State<StateInspectorPanel> {
  late final ReactiveNotifierService _service;
  List<StateChangeEvent> _stateChanges = [];
  InstanceData? _selectedInstance;
  bool _isPaused = false;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _service = ReactiveNotifierService();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _service.initialize();
    
    _service.stateChangeStream.listen((event) {
      if (!_isPaused && mounted) {
        setState(() {
          _stateChanges.insert(0, event);
          // Keep only last 1000 events to prevent memory issues
          if (_stateChanges.length > 1000) {
            _stateChanges = _stateChanges.take(1000).toList();
          }
        });
      }
    });
  }

  List<StateChangeEvent> get _filteredStateChanges {
    if (_filter.isEmpty) return _stateChanges;
    
    return _stateChanges.where((event) {
      return event.type.toLowerCase().contains(_filter.toLowerCase()) ||
          event.instanceId.toLowerCase().contains(_filter.toLowerCase()) ||
          (event.source?.toLowerCase().contains(_filter.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlsSection(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildStateChangesList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: _buildStateDetails(),
              ),
            ],
          ),
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
          IconButton(
            onPressed: () {
              setState(() {
                _isPaused = !_isPaused;
              });
            },
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: _isPaused ? 'Resume' : 'Pause',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _stateChanges.clear();
                _selectedInstance = null;
              });
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filter state changes...',
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
          Text(
            '${_filteredStateChanges.length} events',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStateChangesList() {
    final changes = _filteredStateChanges;

    if (changes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPaused ? Icons.pause_circle : Icons.hourglass_empty,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(_isPaused ? 'Recording paused' : 'No state changes recorded'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: changes.length,
      itemBuilder: (context, index) {
        final change = changes[index];
        return _buildStateChangeItem(change);
      },
    );
  }

  Widget _buildStateChangeItem(StateChangeEvent change) {
    final isSelected = _selectedInstance?.id == change.instanceId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        dense: true,
        leading: _buildChangeIcon(change),
        title: Text(
          change.type,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${change.instanceId.substring(0, 8)}...'),
            Text(
              _formatDateTime(change.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (change.isSilent)
              const Icon(Icons.volume_off, size: 16, color: Colors.orange),
            if (change.source != null)
              Chip(
                label: Text(change.source!, style: const TextStyle(fontSize: 10)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        onTap: () => _selectStateChange(change),
      ),
    );
  }

  Widget _buildChangeIcon(StateChangeEvent change) {
    IconData icon;
    Color color;

    if (change.type.contains('Async')) {
      icon = Icons.sync;
      color = Colors.orange;
    } else if (change.type.contains('ViewModel')) {
      icon = Icons.view_module;
      color = Colors.blue;
    } else {
      icon = Icons.widgets;
      color = Colors.green;
    }

    if (change.isSilent) {
      color = color.withOpacity(0.6);
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildStateDetails() {
    if (_selectedInstance == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a state change to view details'),
          ],
        ),
      );
    }

    final selectedEvent = _stateChanges.firstWhere(
      (event) => event.instanceId == _selectedInstance!.id,
      orElse: () => _stateChanges.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'State Change Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildDetailCard('Event Information', [
            _buildDetailRow('Timestamp', _formatDateTime(selectedEvent.timestamp)),
            _buildDetailRow('Type', selectedEvent.type),
            _buildDetailRow('Instance ID', selectedEvent.instanceId),
            _buildDetailRow('Source', selectedEvent.source ?? 'Unknown'),
            _buildDetailRow('Silent Update', selectedEvent.isSilent ? 'Yes' : 'No'),
          ]),
          const SizedBox(height: 16),
          _buildStateComparisonCard(selectedEvent),
          const SizedBox(height: 16),
          _buildActionsCard(selectedEvent),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  Widget _buildStateComparisonCard(StateChangeEvent event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'State Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous State',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          _formatState(event.oldState),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New State',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[200]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          _formatState(event.newState),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(StateChangeEvent event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _rollbackState(event),
                  icon: const Icon(Icons.undo),
                  label: const Text('Rollback'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _replayState(event),
                  icon: const Icon(Icons.replay),
                  label: const Text('Replay'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportEvent(event),
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.toLocal().toString().substring(0, 23)}';
  }

  String _formatState(dynamic state) {
    if (state == null) return 'null';
    try {
      return state.toString();
    } catch (e) {
      return 'Unable to display state: $e';
    }
  }

  void _selectStateChange(StateChangeEvent change) async {
    final instance = await _service.getInstanceDetails(change.instanceId);
    setState(() {
      _selectedInstance = instance;
    });
  }

  void _rollbackState(StateChangeEvent event) {
    // TODO: Implement state rollback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rollback not yet implemented')),
    );
  }

  void _replayState(StateChangeEvent event) {
    // TODO: Implement state replay
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replay not yet implemented')),
    );
  }

  void _exportEvent(StateChangeEvent event) {
    // TODO: Implement event export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event exported')),
    );
  }
}