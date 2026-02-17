import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';

import 'sync_service.dart';

/// Listens for connectivity changes and automatically processes the sync queue
/// when a network connection is available.
class SyncQueueProcessor {
  final SyncService _syncService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncQueueProcessor(this._syncService);

  /// Starts listening for connectivity changes.
  ///
  /// When the device transitions to a connected state the pending sync queue
  /// is processed automatically.
  void startListening() {
    _connectivitySubscription ??=
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  /// Stops listening for connectivity changes.
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Forces a sync attempt regardless of connectivity state.
  Future<void> manualSync() async {
    developer.log('SyncQueueProcessor: manual sync requested',
        name: 'SyncQueueProcessor');
    await _syncService.processQueue();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection =
        results.any((r) => r != ConnectivityResult.none);

    if (hasConnection && !_syncService.isSyncing) {
      developer.log('SyncQueueProcessor: connectivity restored, processing queue',
          name: 'SyncQueueProcessor');
      _syncService.processQueue();
    }
  }
}
