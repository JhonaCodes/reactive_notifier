import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import '../models/debug_data.dart';
import '../services/reactive_notifier_service.dart';

class PerformancePanel extends StatefulWidget {
  const PerformancePanel({super.key});

  @override
  State<PerformancePanel> createState() => _PerformancePanelState();
}

class _PerformancePanelState extends State<PerformancePanel>
    with TickerProviderStateMixin {
  late final ReactiveNotifierService _service;
  late final AnimationController _animationController;
  
  List<DebugData> _dataHistory = [];
  String _selectedMetric = 'stateUpdates';
  bool _isRecording = true;

  static const int _maxHistoryLength = 100;

  @override
  void initState() {
    super.initState();
    _service = ReactiveNotifierService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeService();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    await _service.initialize();
    
    _service.debugDataStream.listen((data) {
      if (_isRecording && mounted) {
        setState(() {
          _dataHistory.insert(0, data);
          if (_dataHistory.length > _maxHistoryLength) {
            _dataHistory = _dataHistory.take(_maxHistoryLength).toList();
          }
        });
        _animationController.forward(from: 0);
      }
    });
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
                child: _buildPerformanceChart(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: _buildMetricsPanel(),
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
                _isRecording = !_isRecording;
              });
            },
            icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
            tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _dataHistory.clear();
              });
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear History',
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedMetric,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMetric = value;
                });
              }
            },
            items: const [
              DropdownMenuItem(
                value: 'stateUpdates',
                child: Text('State Updates'),
              ),
              DropdownMenuItem(
                value: 'widgetRebuilds',
                child: Text('Widget Rebuilds'),
              ),
              DropdownMenuItem(
                value: 'memoryUsage',
                child: Text('Memory Usage'),
              ),
              DropdownMenuItem(
                value: 'updateTime',
                child: Text('Update Time'),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${_dataHistory.length}/$_maxHistoryLength samples',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (_dataHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No performance data available'),
            Text('Start your app to see real-time metrics'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Chart - ${_getMetricLabel(_selectedMetric)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final data = _dataHistory.reversed.toList();
    if (data.isEmpty) return const SizedBox();

    final values = data.map((d) => _getMetricValue(d, _selectedMetric)).toList();
    final maxValue = values.fold<double>(0, (prev, element) => element > prev ? element : prev);
    final minValue = values.fold<double>(double.infinity, (prev, element) => element < prev ? element : prev);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ChartPainter(
            values: values,
            maxValue: maxValue,
            minValue: minValue,
            animation: _animationController.value,
            color: _getMetricColor(_selectedMetric),
          ),
        );
      },
    );
  }

  Widget _buildMetricsPanel() {
    final currentData = _dataHistory.isNotEmpty ? _dataHistory.first : DebugData.empty();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Metrics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'State Updates',
            '${currentData.stateUpdatesCount}',
            'Total state updates since start',
            Icons.update,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Widget Rebuilds',
            '${currentData.widgetRebuildsCount}',
            'Total widget rebuilds triggered',
            Icons.refresh,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Memory Usage',
            '${currentData.memoryUsageKB.toStringAsFixed(1)} KB',
            'Current memory usage',
            Icons.memory,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Average Update Time',
            '${currentData.avgUpdateTimeMs.toStringAsFixed(2)} ms',
            'Average time per state update',
            Icons.timer,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Potential Memory Leaks',
            '${currentData.potentialMemoryLeaks}',
            'Instances that may have memory leaks',
            Icons.warning,
            Colors.red,
          ),
          const SizedBox(height: 24),
          _buildPerformanceInsights(currentData),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsights(DebugData data) {
    final insights = _generateInsights(data);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline),
                const SizedBox(width: 8),
                Text(
                  'Performance Insights',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Text('No performance issues detected')
            else
              ...insights.map((insight) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          insight.severity == 'warning' ? Icons.warning : Icons.info,
                          size: 16,
                          color: insight.severity == 'warning' ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(insight.message)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  String _getMetricLabel(String metric) {
    switch (metric) {
      case 'stateUpdates':
        return 'State Updates per Second';
      case 'widgetRebuilds':
        return 'Widget Rebuilds per Second';
      case 'memoryUsage':
        return 'Memory Usage (KB)';
      case 'updateTime':
        return 'Average Update Time (ms)';
      default:
        return metric;
    }
  }

  double _getMetricValue(DebugData data, String metric) {
    switch (metric) {
      case 'stateUpdates':
        return data.stateUpdatesCount.toDouble();
      case 'widgetRebuilds':
        return data.widgetRebuildsCount.toDouble();
      case 'memoryUsage':
        return data.memoryUsageKB;
      case 'updateTime':
        return data.avgUpdateTimeMs;
      default:
        return 0.0;
    }
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'stateUpdates':
        return Colors.blue;
      case 'widgetRebuilds':
        return Colors.green;
      case 'memoryUsage':
        return Colors.orange;
      case 'updateTime':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<PerformanceInsight> _generateInsights(DebugData data) {
    final insights = <PerformanceInsight>[];

    if (data.potentialMemoryLeaks > 0) {
      insights.add(PerformanceInsight(
        'warning',
        'Detected ${data.potentialMemoryLeaks} potential memory leaks. Check instance disposal.',
      ));
    }

    if (data.avgUpdateTimeMs > 16.0) {
      insights.add(PerformanceInsight(
        'warning',
        'Average update time is ${data.avgUpdateTimeMs.toStringAsFixed(1)}ms. Consider optimizing state updates.',
      ));
    }

    if (data.widgetRebuildsCount > data.stateUpdatesCount * 3) {
      insights.add(PerformanceInsight(
        'warning',
        'Widget rebuilds significantly exceed state updates. Check for unnecessary rebuilds.',
      ));
    }

    if (data.memoryUsageKB > 10000) {
      insights.add(PerformanceInsight(
        'info',
        'High memory usage detected (${data.memoryUsageKB.toStringAsFixed(1)} KB). Monitor for leaks.',
      ));
    }

    if (insights.isEmpty && data.totalInstances > 0) {
      insights.add(PerformanceInsight(
        'info',
        'Performance looks good! No issues detected.',
      ));
    }

    return insights;
  }
}

class PerformanceInsight {
  final String severity;
  final String message;

  PerformanceInsight(this.severity, this.message);
}

class ChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final double minValue;
  final double animation;
  final Color color;

  ChartPainter({
    required this.values,
    required this.maxValue,
    required this.minValue,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final width = size.width;
    final height = size.height;
    final valueRange = maxValue - minValue;
    final stepX = width / (values.length - 1).clamp(1, double.infinity);

    // Start paths
    final startY = height - ((values.first - minValue) / valueRange) * height;
    path.moveTo(0, startY);
    fillPath.moveTo(0, height);
    fillPath.lineTo(0, startY);

    // Draw the line and fill
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX * animation;
      final normalizedValue = valueRange > 0 ? (values[i] - minValue) / valueRange : 0.5;
      final y = height - normalizedValue * height;

      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // Complete fill path
    fillPath.lineTo(values.length * stepX * animation, height);
    fillPath.close();

    // Draw fill first, then line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      if (i * stepX > width * animation) break;
      
      final x = i * stepX * animation;
      final normalizedValue = valueRange > 0 ? (values[i] - minValue) / valueRange : 0.5;
      final y = height - normalizedValue * height;

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}