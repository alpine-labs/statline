import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO for offline sync queue operations.
class SyncDao {
  final AppDatabase _db;

  SyncDao(this._db);

  /// Enqueue a record change for future sync.
  Future<int> enqueue({
    required String tableName,
    required String recordId,
    required String operation,
    required String payload,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.customInsert(
      'INSERT INTO sync_queue (table_name, record_id, operation, payload, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(tableName),
        Variable<String>(recordId),
        Variable<String>(operation),
        Variable<String>(payload),
        Variable<int>(now),
      ],
    );
  }

  /// Get all items that have not been synced yet.
  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final rows = await _db.customSelect(
      'SELECT * FROM sync_queue WHERE synced_at IS NULL ORDER BY created_at',
    ).get();
    return rows.map((r) => r.data).toList();
  }

  /// Mark an item as successfully synced.
  Future<int> markSynced(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.customUpdate(
      'UPDATE sync_queue SET synced_at = ? WHERE id = ?',
      variables: [
        Variable<int>(now),
        Variable<int>(id),
      ],
      updateKind: UpdateKind.update,
    );
  }

  /// Mark an item as failed and increment the retry count.
  Future<int> markFailed(int id, String error) {
    return _db.customUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, error = ? WHERE id = ?',
      variables: [
        Variable<String>(error),
        Variable<int>(id),
      ],
      updateKind: UpdateKind.update,
    );
  }

  /// Remove all items that have already been synced.
  Future<int> clearSynced() {
    return _db.customUpdate(
      'DELETE FROM sync_queue WHERE synced_at IS NOT NULL',
      updateKind: UpdateKind.delete,
    );
  }
}
