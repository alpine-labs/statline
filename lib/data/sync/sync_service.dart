import 'dart:developer' as developer;

import '../repositories/sync_repository.dart';

class SyncService {
  final SyncRepository _syncRepo;
  bool _isSyncing = false;
  int _pendingCount = 0;

  SyncService(this._syncRepo);

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;

  /// Processes all pending items in the sync queue.
  ///
  /// Each item is pushed to the cloud. On success the item is marked as synced;
  /// on failure the error is recorded so it can be retried later.
  Future<void> processQueue() async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      final items = await _syncRepo.getPendingItems();
      _pendingCount = items.length;

      for (final item in items) {
        final id = item['id'] as int;
        try {
          final success = await _pushToCloud(item);
          if (success) {
            await _syncRepo.markSynced(id);
            _pendingCount--;
          } else {
            await _syncRepo.markFailed(id, 'Push returned false');
          }
        } catch (e) {
          await _syncRepo.markFailed(id, e.toString());
        }
      }

      // Clean up successfully synced items
      await _syncRepo.clearSynced();
    } finally {
      _isSyncing = false;
      _pendingCount = await _syncRepo.getPendingCount();
    }
  }

  /// Stub for cloud push — always returns true.
  /// Actual Supabase integration will replace this implementation.
  Future<bool> _pushToCloud(Map<String, dynamic> item) async {
    developer.log(
      'SyncService: would push ${item['table_name']}/${item['record_id']} '
      '(${item['operation']})',
      name: 'SyncService',
    );
    return true;
  }
}
