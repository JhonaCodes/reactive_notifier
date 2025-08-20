import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'reactive_notifier_debug_service.dart';

/// Auto-initializes the ReactiveNotifier debug service when imported
/// This ensures the DevTools extension works automatically without manual setup
class AutoDebugInit {
  static bool _initialized = false;
  
  /// Check if we're running in a test environment
  static bool get _isTestEnvironment {
    // Multiple ways to detect test environment
    try {
      // Check for flutter_test environment variable
      if (const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        return true;
      }
      
      // Check for dart test environment
      if (const bool.fromEnvironment('DART_TEST', defaultValue: false)) {
        return true;
      }
      
      // Check if we're in a test by looking for test-related zones
      final zone = Zone.current;
      final zoneValues = zone.toString();
      if (zoneValues.contains('flutter_test') || 
          zoneValues.contains('test_api') ||
          zoneValues.contains('TestWidgetsFlutterBinding') ||
          zoneValues.contains('FakeAsync')) {
        return true;
      }
      
      // Check for test-related stack traces in current zone
      try {
        throw Exception('test');
      } catch (e, stack) {
        final stackString = stack.toString();
        if (stackString.contains('flutter_test') ||
            stackString.contains('test_api') ||
            stackString.contains('package:test') ||
            stackString.contains('golden_')) {
          return true;
        }
      }
      
      // Check for common test frameworks
      try {
        // This will throw if not in test environment
        final binding = WidgetsBinding.instance;
        final bindingType = binding.runtimeType.toString();
        if (bindingType.contains('Test') || 
            bindingType.contains('AutomatedTest') ||
            bindingType.contains('LiveTest')) {
          return true;
        }
      } catch (_) {
        // Ignore errors when WidgetsBinding is not available
      }
      
      return false;
    } catch (_) {
      // If any detection fails, assume not test environment
      return false;
    }
  }
  
  /// Automatically initializes debug service in debug mode (but not during tests)
  static void ensureInitialized() {
    if (!_initialized && kDebugMode && !_isTestEnvironment) {
      _initialized = true;
      
      // Use microtask to avoid initialization during import
      scheduleMicrotask(() {
        try {
          // Initialize the debug service
          ReactiveNotifierDebugService.instance;
          
          if (kDebugMode) {
            print('🔧 ReactiveNotifier DevTools extension initialized automatically');
            print('   Open Flutter DevTools to see the "ReactiveNotifier" tab');
          }
        } catch (error) {
          // Silently handle initialization errors to avoid breaking apps
          if (kDebugMode) {
            print('⚠️ ReactiveNotifier DevTools initialization failed: $error');
          }
        }
      });
    }
  }
  
  /// Force reset initialization state (for testing)
  static void reset() {
    _initialized = false;
  }
}

// Auto-initialize when this file is imported (only if not in test environment)
final _autoInit = (() {
  if (!AutoDebugInit._isTestEnvironment) {
    AutoDebugInit.ensureInitialized();
  }
  return true;
})();