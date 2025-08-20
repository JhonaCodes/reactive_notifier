import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import '../services/reactive_notifier_service.dart';
import '../models/debug_data.dart';

class DebugDashboard extends StatefulWidget {
  const DebugDashboard({super.key});

  @override
  State<DebugDashboard> createState() => _DebugDashboardState();
}

class _DebugDashboardState extends State<DebugDashboard> {
  late final ReactiveNotifierService _service;
  DebugData _debugData = DebugData.empty();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _service = ReactiveNotifierService();
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    try {
      await _service.initialize();
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
        _startPolling();
      }
    } catch (e) {
      debugPrint('Failed to initialize ReactiveNotifier service: $e');
    }
  }

  void _startPolling() {
    _service.debugDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _debugData = data;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to ReactiveNotifier debug API...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSection(),
          const SizedBox(height: 24),
          _buildInstanceSummarySection(),
          const SizedBox(height: 24),
          _buildPerformanceSection(),
          const SizedBox(height: 24),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'ReactiveNotifier Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Instances',
                    '${_debugData.totalInstances}',
                    Icons.widgets,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active ViewModels',
                    '${_debugData.activeViewModels}',
                    Icons.view_module,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Memory Usage',
                    '${_debugData.memoryUsageKB} KB',
                    Icons.memory,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list),
                const SizedBox(width: 8),
                Text(
                  'Instance Types',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_debugData.instancesByType.isEmpty)
              const Text('No instances found')
            else
              ..._debugData.instancesByType.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Chip(
                        label: Text('${entry.value}'),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed),
                const SizedBox(width: 8),
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricRow(
                    'State Updates',
                    '${_debugData.stateUpdatesCount}',
                  ),
                ),
                Expanded(
                  child: _buildMetricRow(
                    'Widget Rebuilds',
                    '${_debugData.widgetRebuildsCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricRow(
                    'Avg Update Time',
                    '${_debugData.avgUpdateTimeMs.toStringAsFixed(2)} ms',
                  ),
                ),
                Expanded(
                  child: _buildMetricRow(
                    'Memory Leaks',
                    '${_debugData.potentialMemoryLeaks}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _service.triggerGarbageCollection(),
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Force GC'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _service.clearAllInstances(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _service.exportDebugData(),
                  icon: const Icon(Icons.download),
                  label: const Text('Export Data'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _service.refreshDebugData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}