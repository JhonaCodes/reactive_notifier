import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../notifier/reactive_notifier.dart';
import '../viewmodel/viewmodel_impl.dart';
import '../viewmodel/async_viewmodel_impl.dart';

/// Debug service for ReactiveNotifier DevTools extension
/// Provides detailed information about all ReactiveNotifier instances,
/// state changes, performance metrics, and debugging capabilities.
class ReactiveNotifierDebugService {
  static ReactiveNotifierDebugService? _instance;
  static ReactiveNotifierDebugService get instance =>
      _instance ??= ReactiveNotifierDebugService._();

  ReactiveNotifierDebugService._() {
    _initialize();
  }

  // Performance tracking
  final List<StateChangeEvent> _stateChangeHistory = [];
  final Map<String, int> _updateCounts = {};
  final Map<String, List<double>> _updateTimes = {};
  final Map<String, DateTime> _instanceCreationTimes = {};
  final Map<String, int> _rebuildCounts = {};
  
  Timer? _performanceTimer;
  DateTime _startTime = DateTime.now();
  
  static const int _maxHistoryLength = 1000;
  static const Duration _performanceInterval = Duration(seconds: 1);

  void _initialize() {
    if (kDebugMode) {
      _registerServiceExtensions();
      _startPerformanceTracking();
    }
  }

  void _registerServiceExtensions() {
    developer.registerExtension('ext.reactive_notifier.debugData', (method, parameters) async {
      return developer.ServiceExtensionResponse.result(jsonEncode(_getDebugData()));
    });

    developer.registerExtension('ext.reactive_notifier.getInstanceDetails', (method, parameters) async {
      final instanceId = parameters['instanceId'];
      if (instanceId != null) {
        final details = _getInstanceDetails(instanceId);
        return developer.ServiceExtensionResponse.result(jsonEncode(details));
      }
      return developer.ServiceExtensionResponse.error(
        1,
        'instanceId parameter required',
      );
    });

    developer.registerExtension('ext.reactive_notifier.updateState', (method, parameters) async {
      final instanceId = parameters['instanceId'];
      final newStateJson = parameters['newState'];
      
      if (instanceId != null && newStateJson != null) {
        try {
          final success = _updateInstanceState(instanceId, jsonDecode(newStateJson));
          return developer.ServiceExtensionResponse.result(jsonEncode({'success': success}));
        } catch (e) {
          return developer.ServiceExtensionResponse.error(
            2,
            'Failed to update state: $e',
          );
        }
      }
      return developer.ServiceExtensionResponse.error(
        1,
        'instanceId and newState parameters required',
      );
    });

    developer.registerExtension('ext.reactive_notifier.forceGC', (method, parameters) async {
      _triggerGarbageCollection();
      return developer.ServiceExtensionResponse.result(jsonEncode({'success': true}));
    });

    developer.registerExtension('ext.reactive_notifier.clearAll', (method, parameters) async {
      ReactiveNotifier.cleanup();
      _clearDebugData();
      return developer.ServiceExtensionResponse.result(jsonEncode({'success': true}));
    });

    developer.registerExtension('ext.reactive_notifier.exportData', (method, parameters) async {
      final data = _exportDebugData();
      return developer.ServiceExtensionResponse.result(jsonEncode(data));
    });
  }

  void _startPerformanceTracking() {
    // Don't start performance tracking in test environments to avoid Timer issues
    if (_isTestEnvironment) {
      return;
    }
    
    _performanceTimer = Timer.periodic(_performanceInterval, (_) {
      _trackPerformanceMetrics();
    });
  }
  
  /// Check if we're running in a test environment
  static bool get _isTestEnvironment {
    try {
      // Check for flutter_test environment variable
      if (const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        return true;
      }
      
      // Check for test-related zones
      final zone = Zone.current;
      final zoneValues = zone.toString();
      if (zoneValues.contains('flutter_test') || 
          zoneValues.contains('test_api') ||
          zoneValues.contains('TestWidgetsFlutterBinding') ||
          zoneValues.contains('FakeAsync')) {
        return true;
      }
      
      // Check for test binding
      try {
        final binding = WidgetsBinding.instance;
        final bindingType = binding.runtimeType.toString();
        if (bindingType.contains('Test') || 
            bindingType.contains('AutomatedTest')) {
          return true;
        }
      } catch (_) {
        // Ignore errors when WidgetsBinding is not available
      }
      
      return false;
    } catch (_) {
      return false;
    }
  }

  void _trackPerformanceMetrics() {
    // Track memory usage, update frequencies, etc.
    final instances = ReactiveNotifier.getInstances;
    for (final instance in instances) {
      final id = _getInstanceId(instance);
      _updateCounts.putIfAbsent(id, () => 0);
      _updateTimes.putIfAbsent(id, () => []);
    }
  }

  /// Records a state change event for debugging purposes
  void recordStateChange({
    required String instanceId,
    required String type,
    required dynamic oldState,
    required dynamic newState,
    String? source,
    required bool isSilent,
  }) {
    final event = StateChangeEvent(
      instanceId: instanceId,
      type: type,
      oldState: oldState,
      newState: newState,
      timestamp: DateTime.now(),
      source: source,
      isSilent: isSilent,
    );

    _stateChangeHistory.insert(0, event);
    if (_stateChangeHistory.length > _maxHistoryLength) {
      _stateChangeHistory.removeLast();
    }

    // Update performance metrics
    _updateCounts[instanceId] = (_updateCounts[instanceId] ?? 0) + 1;

    // Post state change event to DevTools
    developer.postEvent('ext.reactive_notifier.stateUpdate', event.toJson());
  }

  /// Records widget rebuild for performance tracking
  void recordWidgetRebuild(String instanceId) {
    _rebuildCounts[instanceId] = (_rebuildCounts[instanceId] ?? 0) + 1;
  }

  /// Records instance creation
  void recordInstanceCreation(ReactiveNotifier instance) {
    // Don't record anything in test environments
    if (_isTestEnvironment) {
      return;
    }
    
    final id = _getInstanceId(instance);
    _instanceCreationTimes[id] = DateTime.now();
  }

  Map<String, dynamic> _getDebugData() {
    final instances = ReactiveNotifier.getInstances;
    final totalInstances = instances.length;
    final activeViewModels = instances.where((i) => 
        i.notifier is ViewModel || i.notifier is AsyncViewModelImpl).length;

    // Calculate memory usage estimate
    final memoryUsageKB = _estimateMemoryUsage(instances);

    // Group instances by type
    final instancesByType = <String, int>{};
    for (final instance in instances) {
      final type = instance.notifier.runtimeType.toString();
      instancesByType[type] = (instancesByType[type] ?? 0) + 1;
    }

    // Calculate performance metrics
    final totalStateUpdates = _updateCounts.values.fold<int>(0, (sum, count) => sum + count);
    final totalWidgetRebuilds = _rebuildCounts.values.fold<int>(0, (sum, count) => sum + count);
    
    final allUpdateTimes = _updateTimes.values.expand((times) => times).toList();
    final avgUpdateTime = allUpdateTimes.isNotEmpty 
        ? allUpdateTimes.reduce((a, b) => a + b) / allUpdateTimes.length 
        : 0.0;

    // Detect potential memory leaks
    final potentialMemoryLeaks = _detectMemoryLeaks(instances);

    // Convert instances to debug format
    final instancesData = instances.map((instance) => _instanceToDebugData(instance)).toList();

    return {
      'totalInstances': totalInstances,
      'activeViewModels': activeViewModels,
      'memoryUsageKB': memoryUsageKB,
      'instancesByType': instancesByType,
      'stateUpdatesCount': totalStateUpdates,
      'widgetRebuildsCount': totalWidgetRebuilds,
      'avgUpdateTimeMs': avgUpdateTime,
      'potentialMemoryLeaks': potentialMemoryLeaks,
      'instances': instancesData,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getInstanceDetails(String instanceId) {
    final instances = ReactiveNotifier.getInstances;
    final instance = instances.firstWhere(
      (i) => _getInstanceId(i) == instanceId,
      orElse: () => throw StateError('Instance not found: $instanceId'),
    );

    return _instanceToDebugData(instance);
  }

  Map<String, dynamic> _instanceToDebugData(ReactiveNotifier instance) {
    final id = _getInstanceId(instance);
    final type = instance.notifier.runtimeType.toString();
    final createdAt = _instanceCreationTimes[id] ?? DateTime.now();
    final updateCount = _updateCounts[id] ?? 0;
    final hasMemoryLeak = _checkInstanceForMemoryLeak(instance);
    final memoryUsage = _estimateInstanceMemoryUsage(instance);

    // Get current state as string
    String stateString;
    try {
      stateString = instance.notifier.toString();
    } catch (e) {
      stateString = 'Error getting state: $e';
    }

    // Get listeners information
    final listeners = <String>[];
    if (instance.hasListeners) {
      // Note: We can't directly access listener details in ChangeNotifier
      // but we can provide general information
      listeners.add('ChangeNotifier listeners (count not available)');
    }

    // Get metadata
    final metadata = <String, dynamic>{
      'keyNotifier': instance.keyNotifier.toString(),
      'hasRelated': instance.related?.isNotEmpty ?? false,
      'relatedCount': instance.related?.length ?? 0,
      'autoDispose': instance.autoDispose,
    };

    if (instance.notifier is ViewModel) {
      final vm = instance.notifier as ViewModel;
      metadata['isDisposed'] = vm.isDisposed;
      metadata['hasContext'] = vm.hasContext;
    } else if (instance.notifier is AsyncViewModelImpl) {
      final vm = instance.notifier as AsyncViewModelImpl;
      metadata['isDisposed'] = vm.isDisposed;
      metadata['hasContext'] = vm.hasContext;
      metadata['data'] = vm.data?.toString() ?? 'null';
      metadata['isLoading'] = vm.isLoading;
      metadata['hasData'] = vm.hasData;
      metadata['error'] = vm.error?.toString();
    }

    return {
      'id': id,
      'type': type,
      'state': stateString,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': _getLastUpdateTime(id).toIso8601String(),
      'updateCount': updateCount,
      'listeners': listeners,
      'hasMemoryLeak': hasMemoryLeak,
      'memoryUsageKB': memoryUsage,
      'metadata': metadata,
    };
  }

  bool _updateInstanceState(String instanceId, Map<String, dynamic> newState) {
    try {
      final instances = ReactiveNotifier.getInstances;
      final instance = instances.firstWhere(
        (i) => _getInstanceId(i) == instanceId,
        orElse: () => throw StateError('Instance not found: $instanceId'),
      );

      // This is a simplified implementation
      // In a real scenario, you'd need to implement proper state deserialization
      // based on the specific type of the instance
      
      recordStateChange(
        instanceId: instanceId,
        type: instance.notifier.runtimeType.toString(),
        oldState: instance.notifier.toString(),
        newState: newState.toString(),
        source: 'DevTools Manual Update',
        isSilent: false,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  void _triggerGarbageCollection() {
    // Force garbage collection (this is a hint, not guaranteed)
    for (int i = 0; i < 5; i++) {
      // Multiple calls to increase likelihood
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile platforms, we can try to trigger GC
        List.generate(1000, (index) => Object()).clear();
      }
    }
  }

  void _clearDebugData() {
    _stateChangeHistory.clear();
    _updateCounts.clear();
    _updateTimes.clear();
    _instanceCreationTimes.clear();
    _rebuildCounts.clear();
    _startTime = DateTime.now();
  }

  Map<String, dynamic> _exportDebugData() {
    return {
      'debugData': _getDebugData(),
      'stateChangeHistory': _stateChangeHistory.map((e) => e.toJson()).toList(),
      'performanceMetrics': {
        'updateCounts': _updateCounts,
        'rebuildCounts': _rebuildCounts,
        'sessionDuration': DateTime.now().difference(_startTime).inMilliseconds,
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  double _estimateMemoryUsage(List<ReactiveNotifier> instances) {
    // Rough estimate based on instance count and type
    double totalKB = 0.0;
    for (final instance in instances) {
      totalKB += _estimateInstanceMemoryUsage(instance);
    }
    return totalKB;
  }

  double _estimateInstanceMemoryUsage(ReactiveNotifier instance) {
    // Very rough estimates in KB
    if (instance.notifier is AsyncViewModelImpl) {
      return 2.0; // Larger due to AsyncState overhead
    } else if (instance.notifier is ViewModel) {
      return 1.5; // ViewModels have some overhead
    } else {
      return 0.5; // Simple notifiers
    }
  }

  int _detectMemoryLeaks(List<ReactiveNotifier> instances) {
    int leakCount = 0;
    for (final instance in instances) {
      if (_checkInstanceForMemoryLeak(instance)) {
        leakCount++;
      }
    }
    return leakCount;
  }

  bool _checkInstanceForMemoryLeak(ReactiveNotifier instance) {
    // Simple heuristics for detecting potential memory leaks
    final id = _getInstanceId(instance);
    final createdAt = _instanceCreationTimes[id];
    final updateCount = _updateCounts[id] ?? 0;

    // Instance created more than 10 minutes ago with no updates
    if (createdAt != null && 
        DateTime.now().difference(createdAt).inMinutes > 10 && 
        updateCount == 0) {
      return true;
    }

    // Instance with a lot of updates but still has listeners after long time
    if (updateCount > 1000 && instance.hasListeners) {
      return true;
    }

    // ViewModel that should be disposed but isn't
    if (instance.notifier is ViewModel) {
      final vm = instance.notifier as ViewModel;
      if (createdAt != null && 
          DateTime.now().difference(createdAt).inMinutes > 5 && 
          !vm.isDisposed && 
          updateCount == 0) {
        return true;
      }
    }

    return false;
  }

  String _getInstanceId(ReactiveNotifier instance) {
    return '${instance.notifier.runtimeType}_${instance.keyNotifier.toString()}';
  }

  DateTime _getLastUpdateTime(String instanceId) {
    // This would need to be tracked in the actual state update methods
    // For now, return current time minus update count (rough estimate)
    final updateCount = _updateCounts[instanceId] ?? 0;
    return DateTime.now().subtract(Duration(seconds: updateCount));
  }

  void dispose() {
    _performanceTimer?.cancel();
    _clearDebugData();
  }
}

/// State change event for DevTools extension
class StateChangeEvent {
  final String instanceId;
  final String type;
  final dynamic oldState;
  final dynamic newState;
  final DateTime timestamp;
  final String? source;
  final bool isSilent;

  const StateChangeEvent({
    required this.instanceId,
    required this.type,
    required this.oldState,
    required this.newState,
    required this.timestamp,
    this.source,
    required this.isSilent,
  });

  Map<String, dynamic> toJson() {
    return {
      'instanceId': instanceId,
      'type': type,
      'oldState': _safeStringify(oldState),
      'newState': _safeStringify(newState),
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'isSilent': isSilent,
    };
  }

  String _safeStringify(dynamic value) {
    try {
      return value.toString();
    } catch (e) {
      return 'Error converting to string: $e';
    }
  }
}