import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

class ConnectionManagerVM extends ViewModelStateImpl<ConnectionState> {
  ConnectionManagerVM() : super(ConnectionState.offline);

  Timer? _reconnectTimer;
  bool _isReconnecting = false;

  @override
  void init() {
    simulateNetworkConditions();
  }

  void simulateNetworkConditions() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isReconnecting) return;
      _simulateStateChange();
    });
  }

  Future<void> _simulateStateChange() async {
    _isReconnecting = true;

    try {
      updateState(ConnectionState.connecting);
      await Future.delayed(const Duration(seconds: 1));

      if (Random().nextDouble() < 0.7) {
        updateState(ConnectionState.connected);
        await Future.delayed(const Duration(seconds: 1));
        updateState(ConnectionState.syncing);
        await Future.delayed(const Duration(seconds: 1));
        updateState(ConnectionState.synced);
      } else {
        if (Random().nextBool()) {
          updateState(ConnectionState.error);
        } else {
          updateState(ConnectionState.syncError);
        }
      }
    } finally {
      _isReconnecting = false;
    }
  }

  void manualReconnect() {
    if (!_isReconnecting) _simulateStateChange();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    super.dispose();
  }
}

enum ConnectionState {
  connected,
  disconnected,
  connecting,
  error,
  uploading,
  waiting,
  offline,
  syncError,
  syncing,
  synced,
  pendingSync
}

extension ConnectionStateX on ConnectionState {
  bool get isConnected => this == ConnectionState.connected;
  bool get isError =>
      this == ConnectionState.error || this == ConnectionState.syncError;
  bool get isSyncing =>
      this == ConnectionState.syncing || this == ConnectionState.pendingSync;

  IconData get icon {
    return switch (this) {
      ConnectionState.connected => Icons.cloud_done,
      ConnectionState.disconnected => Icons.cloud_off,
      ConnectionState.connecting => Icons.cloud_sync,
      ConnectionState.error => Icons.error_outline,
      ConnectionState.uploading => Icons.upload,
      ConnectionState.waiting => Icons.hourglass_empty,
      ConnectionState.offline => Icons.signal_wifi_off,
      ConnectionState.syncError => Icons.sync_problem,
      ConnectionState.syncing => Icons.sync,
      ConnectionState.synced => Icons.sync_alt,
      ConnectionState.pendingSync => Icons.pending,
    };
  }

  Color get color {
    return switch (this) {
      ConnectionState.connected => Colors.green,
      ConnectionState.synced => Colors.lightGreen,
      ConnectionState.uploading ||
      ConnectionState.syncing ||
      ConnectionState.connecting =>
        Colors.blue,
      ConnectionState.waiting || ConnectionState.pendingSync => Colors.orange,
      _ => Colors.red,
    };
  }

  String get message {
    return switch (this) {
      ConnectionState.connected => 'Connected to server',
      ConnectionState.disconnected => 'Connection lost',
      ConnectionState.connecting => 'Establishing connection...',
      ConnectionState.error => 'Connection error',
      ConnectionState.uploading => 'Uploading data...',
      ConnectionState.waiting => 'Waiting for connection',
      ConnectionState.offline => 'Device offline',
      ConnectionState.syncError => 'Sync failed',
      ConnectionState.syncing => 'Syncing data...',
      ConnectionState.synced => 'Data synchronized',
      ConnectionState.pendingSync => 'Pending sync',
    };
  }
}
