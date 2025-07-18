import 'dart:developer';

import 'package:flutter/foundation.dart';

mixin HelperNotifier {
  bool isEmptyData(dynamic value) {
    // If null
    if (value == null) {
      log("Your current result is null");
      return true;
    }

    // If String
    if (value is String) {
      return value.trim().isEmpty;
    }

    // If Iterable (List, Set, etc.)
    if (value is Iterable) {
      return value.isEmpty;
    }

    // If Map
    if (value is Map) {
      return value.isEmpty;
    }

    // For other specific Dart types
    if (value is Uint8List || value is Int32List || value is Float64List) {
      return value.isEmpty;
    }

    // For objects with isEmpty or length property
    try {
      // Try to access isEmpty property dynamically if it exists
      return value.isEmpty == true;
    } catch (_) {
      try {
        // Or check if length is 0
        return value.length == 0;
      } catch (_) {
        // Doesn't have standard empty properties
        return false;
      }
    }
  }

  void _logListeners<T>({
    String? typeName,
    required List<String> listeners,
    int level = 10,
    String action = 'setup',
    String emoji = '🎧',
  }) {
    if (listeners.isEmpty) return;

    final typeStr = typeName ?? T.toString();
    final actionCapitalized = action[0].toUpperCase() + action.substring(1);
    final header = '$emoji ViewModel<$typeStr> Listeners $actionCapitalized';
    final divider = '=' * (header.length - 2);

    final formattedListeners = listeners
        .asMap()
        .entries
        .map((entry) => '  ${entry.key + 1}. ${entry.value}')
        .join('\n');

    log('''
$divider
$header
$divider
• Count: ${listeners.length}
• Listeners:
$formattedListeners
$divider''', level: level);
  }

  void logSetup<T>({
    String? typeName,
    required List<String> listeners,
    int level = 10,
  }) {
    _logListeners<T>(
      typeName: typeName,
      listeners: listeners,
      level: level,
      action: 'setup',
      emoji: '🎧',
    );
  }

  void logRemove<T>({
    String? typeName,
    required List<String> listeners,
    int level = 10,
  }) {
    _logListeners<T>(
      typeName: typeName,
      listeners: listeners,
      level: level,
      action: 'remove',
      emoji: '🔕',
    );
  }
}
