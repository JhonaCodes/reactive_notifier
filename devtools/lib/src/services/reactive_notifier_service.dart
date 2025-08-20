import 'dart:async';
import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';

import '../models/debug_data.dart';

class ReactiveNotifierService {
  static const String _serviceExtensionName = 'ext.reactive_notifier.debugData';
  static const String _updateEventName = 'ext.reactive_notifier.stateUpdate';
  
  final StreamController<DebugData> _debugDataController = StreamController<DebugData>.broadcast();
  final StreamController<StateChangeEvent> _stateChangeController = StreamController<StateChangeEvent>.broadcast();
  
  Timer? _pollingTimer;
  bool _isInitialized = false;

  Stream<DebugData> get debugDataStream => _debugDataController.stream;
  Stream<StateChangeEvent> get stateChangeStream => _stateChangeController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register for state change events
      serviceManager.service!.onExtensionEvent.listen((event) {
        if (event.extensionKind == _updateEventName) {
          _handleStateChangeEvent(event.extensionData?.data);
        }
      });

      // Start polling for debug data
      _startPolling();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize ReactiveNotifier service: $e');
      rethrow;
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchDebugData();
    });
    
    // Fetch initial data
    _fetchDebugData();
  }

  Future<void> _fetchDebugData() async {
    try {
      final response = await serviceManager.service!.callServiceExtension(
        _serviceExtensionName,
        isolateId: serviceManager.isolateManager.selectedIsolate.value?.id,
      );

      if (response.json != null) {
        final debugData = DebugData.fromJson(response.json!);
        _debugDataController.add(debugData);
      }
    } catch (e) {
      // Silently handle errors - service extension might not be available
      if (kDebugMode) {
        debugPrint('Failed to fetch debug data: $e');
      }
    }
  }

  void _handleStateChangeEvent(Map<String, dynamic>? data) {
    if (data != null) {
      try {
        final stateChange = StateChangeEvent.fromJson(data);
        _stateChangeController.add(stateChange);
      } catch (e) {
        debugPrint('Failed to parse state change event: $e');
      }
    }
  }

  Future<void> triggerGarbageCollection() async {
    try {
      await serviceManager.service!.callServiceExtension(
        'ext.reactive_notifier.forceGC',
        isolateId: serviceManager.isolateManager.selectedIsolate.value?.id,
      );
    } catch (e) {
      debugPrint('Failed to trigger garbage collection: $e');
    }
  }

  Future<void> clearAllInstances() async {
    try {
      await serviceManager.service!.callServiceExtension(
        'ext.reactive_notifier.clearAll',
        isolateId: serviceManager.isolateManager.selectedIsolate.value?.id,
      );
    } catch (e) {
      debugPrint('Failed to clear all instances: $e');
    }
  }

  Future<void> exportDebugData() async {
    try {
      final response = await serviceManager.service!.callServiceExtension(
        'ext.reactive_notifier.exportData',
        isolateId: serviceManager.isolateManager.selectedIsolate.value?.id,
      );
      
      if (response.json != null) {
        // In a real implementation, this would trigger a download
        debugPrint('Debug data exported: ${jsonEncode(response.json)}');
      }
    } catch (e) {
      debugPrint('Failed to export debug data: $e');
    }
  }

  Future<void> refreshDebugData() async {
    await _fetchDebugData();
  }

  Future<void> updateInstanceState(String instanceId, Map<String, dynamic> newState) async {
    try {
      await serviceManager.service!.callServiceExtension(
        'ext.reactive_notifier.updateState',
        isolateId: serviceManager.isolateManager.selectedIsolate.value?.id,
        args: {
          'instanceId': instanceId,
          'newState': jsonEncode(newState),
        },
      );
    } catch (e) {
      debugPrint('Failed to update instance state: $e');
    }
  }

  Future<InstanceData?> getInstanceDetails(String instanceId) async {
    try {
      final response = await serviceManager.service!.callServiceExtension(
        'ext.reactive_notifier.getInstanceDetails',
        isolateId: serviceManager.isolateManager.selectedIsolate.value?.id,
        args: {'instanceId': instanceId},
      );

      if (response.json != null) {
        return InstanceData.fromJson(response.json!);
      }
    } catch (e) {
      debugPrint('Failed to get instance details: $e');
    }
    return null;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _debugDataController.close();
    _stateChangeController.close();
  }
}