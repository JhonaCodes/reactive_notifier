import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Service extension for ReactiveNotifier DevTools integration
///
/// This service provides real-time access to ReactiveNotifier instances
/// through the Dart VM Service Protocol, enabling the DevTools extension
/// to display actual state, metrics, and debugging information.
class ReactiveNotifierDevToolsService {
  static ReactiveNotifierDevToolsService? _instance;
  static ReactiveNotifierDevToolsService get instance {
    _instance ??= ReactiveNotifierDevToolsService._();
    return _instance!;
  }

  ReactiveNotifierDevToolsService._() {
    _registerServiceExtensions();
  }

  /// Register service extensions with the VM service
  void _registerServiceExtensions() {
    if (!kDebugMode) {
      // Only register in debug mode
      return;
    }

    try {
      // Register main data endpoint
      developer.registerExtension(
        'ext.reactive_notifier.getData',
        _handleGetDataRequest,
      );

      // Register instance details endpoint
      developer.registerExtension(
        'ext.reactive_notifier.getInstanceDetails',
        _handleGetInstanceDetailsRequest,
      );

      // Register cleanup endpoint
      developer.registerExtension(
        'ext.reactive_notifier.cleanup',
        _handleCleanupRequest,
      );

      developer.log('''
✅ ReactiveNotifier DevTools Service Extensions Registered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Endpoints:
  - ext.reactive_notifier.getData
  - ext.reactive_notifier.getInstanceDetails
  - ext.reactive_notifier.cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
    } catch (e) {
      developer.log('⚠️ Failed to register DevTools service extensions: $e');
    }
  }

  /// Handle getData request - Returns all ReactiveNotifier instances
  Future<developer.ServiceExtensionResponse> _handleGetDataRequest(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final instances = ReactiveNotifier.getInstances;
      final data = instances.map((instance) => _serializeInstance(instance)).toList();

      return developer.ServiceExtensionResponse.result(
        json.encode({
          'type': 'ReactiveNotifierData',
          'timestamp': DateTime.now().toIso8601String(),
          'totalInstances': instances.length,
          'instances': data,
        }),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'Failed to get data: $e',
      );
    }
  }

  /// Handle getInstanceDetails request - Returns detailed info for a specific instance
  Future<developer.ServiceExtensionResponse> _handleGetInstanceDetailsRequest(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final keyParam = parameters['key'];
      if (keyParam == null) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.invalidParams,
          'Missing required parameter: key',
        );
      }

      final instances = ReactiveNotifier.getInstances;
      final instance = instances.where((i) => i.keyNotifier.toString() == keyParam).firstOrNull;

      if (instance == null) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.invalidParams,
          'Instance not found with key: $keyParam',
        );
      }

      return developer.ServiceExtensionResponse.result(
        json.encode(_serializeInstanceDetails(instance)),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'Failed to get instance details: $e',
      );
    }
  }

  /// Handle cleanup request - Clears all ReactiveNotifier instances
  Future<developer.ServiceExtensionResponse> _handleCleanupRequest(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final countBefore = ReactiveNotifier.instanceCount;
      ReactiveNotifier.cleanup();
      final countAfter = ReactiveNotifier.instanceCount;

      return developer.ServiceExtensionResponse.result(
        json.encode({
          'type': 'CleanupResult',
          'success': true,
          'instancesCleared': countBefore - countAfter,
          'remainingInstances': countAfter,
        }),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'Failed to cleanup: $e',
      );
    }
  }

  /// Serialize a ReactiveNotifier instance to JSON
  Map<String, dynamic> _serializeInstance(ReactiveNotifier instance) {
    final notifier = instance.notifier;
    final type = notifier.runtimeType.toString();
    final isViewModel = notifier is ViewModel || notifier is AsyncViewModelImpl;
    final isAsync = notifier is AsyncViewModelImpl;

    return {
      'key': instance.keyNotifier.toString(),
      'type': type,
      'isViewModel': isViewModel,
      'isAsync': isAsync,
      'hasListeners': instance.hasListeners,
      'autoDispose': instance.autoDispose,
      'referenceCount': instance.referenceCount,
      'isScheduledForDispose': instance.isScheduledForDispose,
      'activeReferences': instance.activeReferences.toList(),
      'relatedCount': instance.related?.length ?? 0,
      'relatedTypes': instance.related?.map((r) => r.notifier.runtimeType.toString()).toList() ?? [],
      'statePreview': _getStatePreview(notifier),
      'stateType': _getStateType(notifier),
    };
  }

  /// Serialize instance details with full state information
  Map<String, dynamic> _serializeInstanceDetails(ReactiveNotifier instance) {
    final basic = _serializeInstance(instance);
    final notifier = instance.notifier;

    // Add detailed state information
    basic['fullState'] = _getFullState(notifier);
    basic['listenerCount'] = instance.hasListeners ? 'Active' : '0';

    // Add ViewModel-specific info
    if (notifier is ViewModel) {
      basic['viewModelData'] = _getViewModelData(notifier);
    } else if (notifier is AsyncViewModelImpl) {
      basic['asyncViewModelData'] = _getAsyncViewModelData(notifier);
    }

    return basic;
  }

  /// Get state preview (truncated for list view)
  String _getStatePreview(dynamic notifier) {
    try {
      if (notifier is AsyncViewModelImpl) {
        if (notifier.isLoading) return 'Loading...';
        if (notifier.error != null) return 'Error: ${notifier.error}';
        if (notifier.hasData) {
          final dataStr = notifier.data.toString();
          return dataStr.length > 50 ? '${dataStr.substring(0, 47)}...' : dataStr;
        }
        return 'Initial';
      } else if (notifier is ViewModel) {
        final dataStr = notifier.data.toString();
        return dataStr.length > 50 ? '${dataStr.substring(0, 47)}...' : dataStr;
      } else {
        final str = notifier.toString();
        return str.length > 50 ? '${str.substring(0, 47)}...' : str;
      }
    } catch (e) {
      return 'Error getting preview: $e';
    }
  }

  /// Get full state (for detail view)
  String _getFullState(dynamic notifier) {
    try {
      if (notifier is AsyncViewModelImpl) {
        if (notifier.isLoading) return 'Loading...';
        if (notifier.error != null) {
          return 'Error: ${notifier.error}${notifier.stackTrace != null ? '\nStackTrace: ${notifier.stackTrace}' : ''}';
        }
        if (notifier.hasData) return 'Data: ${notifier.data}';
        return 'Initial (no data)';
      } else if (notifier is ViewModel) {
        return notifier.data.toString();
      } else {
        return notifier.toString();
      }
    } catch (e) {
      return 'Error getting full state: $e';
    }
  }

  /// Get state type string
  String _getStateType(dynamic notifier) {
    if (notifier is AsyncViewModelImpl) {
      if (notifier.isLoading) return 'loading';
      if (notifier.error != null) return 'error';
      if (notifier.hasData) return 'success';
      return 'initial';
    } else if (notifier is ViewModel) {
      return 'data';
    } else {
      return 'simple';
    }
  }

  /// Get ViewModel-specific data
  Map<String, dynamic> _getViewModelData(ViewModel viewModel) {
    return {
      'isDisposed': viewModel.isDisposed,
      'dataType': viewModel.data.runtimeType.toString(),
      'hasContext': viewModel.hasContext,
    };
  }

  /// Get AsyncViewModel-specific data
  Map<String, dynamic> _getAsyncViewModelData(AsyncViewModelImpl asyncViewModel) {
    return {
      'isDisposed': asyncViewModel.isDisposed,
      'dataType': asyncViewModel.data?.runtimeType.toString() ?? 'null',
      'isLoading': asyncViewModel.isLoading,
      'isError': asyncViewModel.error != null,
      'isSuccess': asyncViewModel.hasData,
      'isInitial': !asyncViewModel.isLoading && asyncViewModel.error == null && !asyncViewModel.hasData,
      'hasContext': asyncViewModel.hasContext,
      'errorMessage': asyncViewModel.error?.toString(),
      'stackTrace': asyncViewModel.stackTrace?.toString(),
    };
  }
}

/// Initialize DevTools service automatically
/// Call this in your main() or MyApp to enable DevTools integration
void initializeReactiveNotifierDevTools() {
  if (kDebugMode) {
    ReactiveNotifierDevToolsService.instance;
    developer.log('🔧 ReactiveNotifier DevTools Service initialized');
  }
}
