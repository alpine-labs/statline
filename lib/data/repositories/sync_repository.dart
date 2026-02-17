import 'dart:convert';

import '../database/app_database.dart';

class SyncRepository {
  final AppDatabase _db;

  SyncRepository(this._db);

  /// Enqueues a change to be synced to the cloud.
  Future<void> enqueue(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    await _db.execute(
      '''INSERT INTO sync_queue (table_name, record_id, operation, payload,
         created_at, retry_count)
         VALUES (?, ?, ?, ?, ?, 0)''',
      [
        tableName,
        recordId,
        operation,
        jsonEncode(payload),
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  /// Returns all pending (un-synced) items ordered by creation time.
  Future<List<Map<String, dynamic>>> getPendingItems() async {
    return _db.query(
      '''SELECT * FROM sync_queue
         WHERE synced_at IS NULL
         ORDER BY created_at ASC''',
    );
  }

  /// Marks a sync queue item as successfully synced.
  Future<void> markSynced(int id) async {
    await _db.execute(
      'UPDATE sync_queue SET synced_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  /// Marks a sync queue item as failed, recording the error and incrementing
  /// the retry counter.
  Future<void> markFailed(int id, String error) async {
    await _db.execute(
      '''UPDATE sync_queue
         SET error = ?, retry_count = retry_count + 1
         WHERE id = ?''',
      [error, id],
    );
  }

  /// Deletes all successfully synced items from the queue.
  Future<void> clearSynced() async {
    await _db.execute(
      'DELETE FROM sync_queue WHERE synced_at IS NOT NULL',
    );
  }

  /// Returns the number of pending (un-synced) items.
  Future<int> getPendingCount() async {
    final rows = await _db.query(
      'SELECT COUNT(*) as count FROM sync_queue WHERE synced_at IS NULL',
    );
    return rows.first['count'] as int;
  }
}
