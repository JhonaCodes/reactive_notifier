import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:reactive_notifier/src/tracker/state_tracker.dart';
import '../implements/repository_impl.dart';

import '../implements/notifier_impl.dart';

/// [ViewModelImpl]
/// Base ViewModel implementation with repository integration for domain logic and data handling.
/// Use this when you need to interact with repositories and manage business logic.
/// For simple state management without repository, use [ViewModelStateImpl] instead.
///
abstract class ViewModelImpl<T> extends StateNotifierImpl<T> {
  final String? _id;
  final String? _location;

  // ignore_for_file: unused_field
  final RepositoryImpl _repository;

  ViewModelImpl(this._repository, super._data, [this._id, this._location]) {
    _initialization();

    if (!kReleaseMode && (_id != null && _location != null)) {
      StateTracker.setLocation(_id, _location);
    }
  }

  @immutable
  void init();

  bool _initialized = false;

  void _initialization() {
    if (!_initialized) {
      log('ViewModelImpl.init');

      init();
      _initialized = true;
    }
  }

  void addDependencyTracker(String notifyId, String dependentId) {
    if (!kReleaseMode) {
      StateTracker.addDependency(notifyId, dependentId);
    }
  }

  void currentTracker() {
    if (!kReleaseMode && _id != null) {
      StateTracker.trackStateChange(_id);
    }
  }
}

/// [ViewModelStateImpl]
/// Base ViewModel implementation for simple state management without repository dependencies.
/// Use this when you only need to handle UI state without domain logic or data layer interactions.
/// For cases requiring repository access, use [ViewModelImpl] instead.
///
abstract class ViewModelStateImpl<T> extends StateNotifierImpl<T> {
  final String? _id;
  final String? _location;

  ViewModelStateImpl(super._data, [this._id, this._location]) {
    _initialization();

    if (!kReleaseMode && (_id != null && _location != null)) {
      StateTracker.setLocation(_id, _location);
    }
  }

  @immutable
  void init();

  bool _initialized = false;

  void _initialization() {
    if (!_initialized) {
      log('ViewModelStateImpl.init');

      init();
      _initialized = true;
    }
  }

  @immutable
  void addDependencyTracker(String notifyId, String dependentId) {
    if (!kReleaseMode) {
      StateTracker.addDependency(notifyId, dependentId);
    }
  }

  @immutable
  void currentTracker() {
    if (!kReleaseMode && _id != null) {
      StateTracker.trackStateChange(_id);
    }
  }
}
