import 'dart:developer';

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class StateTracker {
  static final Map<String, Set<String>> _dependencyGraph = {};
  static final Map<String, String> _locationMap = {};
  static LogLevel _logLevel = LogLevel.info;

  static void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  static void addDependency(String notifyId, String dependentId) {
    _dependencyGraph.putIfAbsent(notifyId, () => {}).add(dependentId);
  }

  static void setLocation(String notifyId, String location) {
    _locationMap[notifyId] = location;
  }

  static void trackStateChange(String notifyId) {
    if (_locationMap.isNotEmpty) {
      if (kReleaseMode) return;
      _log(LogLevel.info,
          'Status changed: $notifyId en ${_locationMap[notifyId]}');
      final affected = _dependencyGraph[notifyId] ?? {};
      for (final dependentId in affected) {
        _log(LogLevel.debug,
            '  Subject to: $dependentId on ${_locationMap[dependentId]}');
      }
    }
  }

  static void _log(LogLevel level, String message) {
    if (level.index >= _logLevel.index) {
      log('[$level] $message');
    }
  }
}
