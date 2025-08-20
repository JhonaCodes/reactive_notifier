class DebugData {
  final int totalInstances;
  final int activeViewModels;
  final double memoryUsageKB;
  final Map<String, int> instancesByType;
  final int stateUpdatesCount;
  final int widgetRebuildsCount;
  final double avgUpdateTimeMs;
  final int potentialMemoryLeaks;
  final List<InstanceData> instances;
  final DateTime timestamp;

  const DebugData({
    required this.totalInstances,
    required this.activeViewModels,
    required this.memoryUsageKB,
    required this.instancesByType,
    required this.stateUpdatesCount,
    required this.widgetRebuildsCount,
    required this.avgUpdateTimeMs,
    required this.potentialMemoryLeaks,
    required this.instances,
    required this.timestamp,
  });

  factory DebugData.empty() {
    return DebugData(
      totalInstances: 0,
      activeViewModels: 0,
      memoryUsageKB: 0.0,
      instancesByType: {},
      stateUpdatesCount: 0,
      widgetRebuildsCount: 0,
      avgUpdateTimeMs: 0.0,
      potentialMemoryLeaks: 0,
      instances: [],
      timestamp: DateTime.now(),
    );
  }

  factory DebugData.fromJson(Map<String, dynamic> json) {
    return DebugData(
      totalInstances: json['totalInstances'] ?? 0,
      activeViewModels: json['activeViewModels'] ?? 0,
      memoryUsageKB: (json['memoryUsageKB'] ?? 0).toDouble(),
      instancesByType: Map<String, int>.from(json['instancesByType'] ?? {}),
      stateUpdatesCount: json['stateUpdatesCount'] ?? 0,
      widgetRebuildsCount: json['widgetRebuildsCount'] ?? 0,
      avgUpdateTimeMs: (json['avgUpdateTimeMs'] ?? 0).toDouble(),
      potentialMemoryLeaks: json['potentialMemoryLeaks'] ?? 0,
      instances: (json['instances'] as List<dynamic>? ?? [])
          .map((e) => InstanceData.fromJson(e))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalInstances': totalInstances,
      'activeViewModels': activeViewModels,
      'memoryUsageKB': memoryUsageKB,
      'instancesByType': instancesByType,
      'stateUpdatesCount': stateUpdatesCount,
      'widgetRebuildsCount': widgetRebuildsCount,
      'avgUpdateTimeMs': avgUpdateTimeMs,
      'potentialMemoryLeaks': potentialMemoryLeaks,
      'instances': instances.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class InstanceData {
  final String id;
  final String type;
  final String state;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int updateCount;
  final List<String> listeners;
  final bool hasMemoryLeak;
  final double memoryUsageKB;
  final Map<String, dynamic> metadata;

  const InstanceData({
    required this.id,
    required this.type,
    required this.state,
    required this.createdAt,
    required this.lastUpdated,
    required this.updateCount,
    required this.listeners,
    required this.hasMemoryLeak,
    required this.memoryUsageKB,
    required this.metadata,
  });

  factory InstanceData.fromJson(Map<String, dynamic> json) {
    return InstanceData(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      state: json['state'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      updateCount: json['updateCount'] ?? 0,
      listeners: List<String>.from(json['listeners'] ?? []),
      hasMemoryLeak: json['hasMemoryLeak'] ?? false,
      memoryUsageKB: (json['memoryUsageKB'] ?? 0).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'state': state,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'updateCount': updateCount,
      'listeners': listeners,
      'hasMemoryLeak': hasMemoryLeak,
      'memoryUsageKB': memoryUsageKB,
      'metadata': metadata,
    };
  }
}

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

  factory StateChangeEvent.fromJson(Map<String, dynamic> json) {
    return StateChangeEvent(
      instanceId: json['instanceId'] ?? '',
      type: json['type'] ?? '',
      oldState: json['oldState'],
      newState: json['newState'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      source: json['source'],
      isSilent: json['isSilent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instanceId': instanceId,
      'type': type,
      'oldState': oldState,
      'newState': newState,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'isSilent': isSilent,
    };
  }
}