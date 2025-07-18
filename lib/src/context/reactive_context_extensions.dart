/// ReactiveContext Extensions - Public API
///
/// This file provides the clean API extensions that developers will use
library reactive_context_extensions;

import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/context/reactive_context_enhanced.dart';

/// Base extension for creating specific extensions
///
/// Developers should create their own extensions using this pattern:
///
/// ```dart
/// extension YourStateContext on BuildContext {
///   YourState get yourState => getReactiveState(YourService.instance);
/// }
/// ```
extension ReactiveContextBase on BuildContext {
  /// Helper method for creating custom extensions
  T getReactiveState<T>(ReactiveNotifier<T> notifier) {
    return ReactiveContextEnhanced.getReactiveState<T>(this, notifier);
  }
}

/// Optional generic extension
///
/// Allows using:
/// ```dart
/// context<MyType>() and context.getByKey('key')
/// ```
extension ReactiveContextGeneric on BuildContext {
  /// Access by type:
  /// ```dart
  /// context<MyLang>()
  /// ```
  T call<T>() {
    // Search for ReactiveNotifier in global ReactiveNotifier registry
    final instances = ReactiveNotifier.getInstances;
    for (final instance in instances) {
      // Check if this ReactiveNotifier is parametrized with type T
      if (instance is ReactiveNotifier<T>) {
        return getReactiveState(instance);
      }
    }
    throw StateError(
        'No ReactiveNotifier found for type $T. Make sure it\'s registered in a Service mixin.');
  }

  /// Access by key: context.getByKey('languageService')
  T getByKey<T>(String key) {
    // Search for ReactiveNotifier by custom key
    final instances = ReactiveNotifier.getInstances;
    for (final instance in instances) {
      // Search by class name or custom key
      if (instance.runtimeType
              .toString()
              .toLowerCase()
              .contains(key.toLowerCase()) ||
          instance.notifier.runtimeType
              .toString()
              .toLowerCase()
              .contains(key.toLowerCase())) {
        if (instance.notifier is T) {
          return getReactiveState(instance as ReactiveNotifier<T>);
        }
      }
    }
    throw StateError('No ReactiveNotifier found for key "$key" with type $T');
  }
}
