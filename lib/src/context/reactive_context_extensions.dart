/// ReactiveContext Extensions - Public API
///
/// This file provides the clean API extensions that developers will use
library reactive_context_extensions;

import 'package:flutter/material.dart';
import 'package:reactive_notifier/src/notifier/reactive_notifier.dart';
import 'package:reactive_notifier/src/context/reactive_context_enhanced.dart';

/// Base extension para crear extensions específicas
///
/// Los developers deben crear sus propias extensions usando este patrón:
///
/// ```dart
/// extension YourStateContext on BuildContext {
///   YourState get yourState => getReactiveState(YourService.instance);
/// }
/// ```
extension ReactiveContextBase on BuildContext {
  /// Método helper para crear extensions personalizadas
  T getReactiveState<T>(ReactiveNotifier<T> notifier) {
    return ReactiveContextEnhanced.getReactiveState<T>(this, notifier);
  }
}

/// Extension genérica opcional
///
/// Permite usar: context<MyType>() y context.getByKey('key')
extension ReactiveContextGeneric on BuildContext {
  /// Acceso por tipo: context<MyLang>()
  T call<T>() {
    // Buscar ReactiveNotifier en registry global de ReactiveNotifier
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

  /// Acceso por clave: context.getByKey('languageService')
  T getByKey<T>(String key) {
    // Buscar ReactiveNotifier por clave personalizada
    final instances = ReactiveNotifier.getInstances;
    for (final instance in instances) {
      // Buscar por nombre de clase o clave personalizada
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
