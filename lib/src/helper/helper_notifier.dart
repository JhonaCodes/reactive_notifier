import 'dart:developer';

import 'package:flutter/foundation.dart';

mixin HelperNotifier{
  bool isEmpty(dynamic value) {
    // Si es null
    if (value == null) {
      log("Your current result is null");
      return true;
    }

    // Si es String
    if (value is String) {
      return value.trim().isEmpty;
    }

    // Si es Iterable (List, Set, etc.)
    if (value is Iterable) {
      return value.isEmpty;
    }

    // Si es Map
    if (value is Map) {
      return value.isEmpty;
    }

    // Para otros tipos específicos de Dart
    if (value is Uint8List || value is Int32List || value is Float64List) {
      return value.isEmpty;
    }

    // Para objetos con una propiedad isEmpty o length
    try {
      // Intenta acceder dinámicamente a la propiedad isEmpty si existe
      return value.isEmpty == true;
    } catch (_) {
      try {
        // O verifica si length es 0
        return value.length == 0;
      } catch (_) {
        // No tiene propiedades de vacío estándar
        return false;
      }
    }
  }
}