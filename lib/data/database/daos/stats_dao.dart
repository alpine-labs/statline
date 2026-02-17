import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO for play events, player game stats, and player season stats.
class StatsDao {
  final AppDatabase _db;

  StatsDao(this._db);

  // --------------- Play Events ---------------

  Future<int> insertPlayEvent(Map<String, dynamic> event) {
    return _db.customInsert(
      'INSERT INTO play_events (id, game_id, period_id, sequence_number, timestamp, game_clock, '
      'player_id, secondary_player_id, event_category, event_type, result, '
      'score_us_after, score_them_after, is_opponent, notes, metadata, is_deleted, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(event['id']),
        Variable<String>(event['game_id']),
        Variable<String>(event['period_id']),
        Variable<int>(event['sequence_number']),
        Variable<int>(event['timestamp']),
        Variable<String>(event['game_clock']),
        Variable<String>(event['player_id']),
        Variable<String>(event['secondary_player_id']),
        Variable<String>(event['event_category']),
        Variable<String>(event['event_type']),
        Variable<String>(event['result']),
        Variable<int>(event['score_us_after'] ?? 0),
        Variable<int>(event['score_them_after'] ?? 0),
        Variable<int>(event['is_opponent'] ?? 0),
        Variable<String>(event['notes']),
        Variable<String>(event['metadata'] ?? '{}'),
        Variable<int>(event['is_deleted'] ?? 0),
        Variable<int>(event['created_at']),
      ],
    );
  }

  Future<int> softDeletePlayEvent(String id) {
    return _db.customUpdate(
      'UPDATE play_events SET is_deleted = 1 WHERE id = ?',
      variables: [Variable<String>(id)],
      updateKind: UpdateKind.update,
    );
  }

  Future<List<Map<String, dynamic>>> getPlayEventsForGame(
      String gameId) async {
    final rows = await _db.customSelect(
      'SELECT pe.*, p.first_name, p.last_name, p.jersey_number '
      'FROM play_events pe '
      'LEFT JOIN players p ON p.id = pe.player_id '
      'WHERE pe.game_id = ? AND pe.is_deleted = 0 '
      'ORDER BY pe.sequence_number',
      variables: [Variable<String>(gameId)],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  Future<Map<String, dynamic>?> getLastPlayEvent(String gameId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM play_events '
      'WHERE game_id = ? AND is_deleted = 0 '
      'ORDER BY sequence_number DESC LIMIT 1',
      variables: [Variable<String>(gameId)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  // --------------- Player Game Stats ---------------

  Future<int> upsertPlayerGameStats(Map<String, dynamic> stats) async {
    // Try update first, then insert if no rows affected
    final updated = await _db.customUpdate(
      'UPDATE player_game_stats SET stats = ?, computed_at = ? '
      'WHERE game_id = ? AND player_id = ?',
      variables: [
        Variable<String>(stats['stats'] ?? '{}'),
        Variable<int>(stats['computed_at']),
        Variable<String>(stats['game_id']),
        Variable<String>(stats['player_id']),
      ],
      updateKind: UpdateKind.update,
    );
    if (updated == 0) {
      return _db.customInsert(
        'INSERT INTO player_game_stats (id, game_id, player_id, sport, stats, computed_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        variables: [
          Variable<String>(stats['id']),
          Variable<String>(stats['game_id']),
          Variable<String>(stats['player_id']),
          Variable<String>(stats['sport']),
          Variable<String>(stats['stats'] ?? '{}'),
          Variable<int>(stats['computed_at']),
        ],
      );
    }
    return updated;
  }

  Future<Map<String, dynamic>?> getPlayerGameStats(
    String gameId,
    String playerId,
  ) async {
    final rows = await _db.customSelect(
      'SELECT * FROM player_game_stats WHERE game_id = ? AND player_id = ?',
      variables: [
        Variable<String>(gameId),
        Variable<String>(playerId),
      ],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  // --------------- Player Season Stats ---------------

  Future<int> upsertPlayerSeasonStats(Map<String, dynamic> stats) async {
    final updated = await _db.customUpdate(
      'UPDATE player_season_stats SET games_played = ?, stats_totals = ?, stats_averages = ?, '
      'computed_metrics = ?, computed_at = ? '
      'WHERE season_id = ? AND player_id = ?',
      variables: [
        Variable<int>(stats['games_played'] ?? 0),
        Variable<String>(stats['stats_totals'] ?? '{}'),
        Variable<String>(stats['stats_averages'] ?? '{}'),
        Variable<String>(stats['computed_metrics'] ?? '{}'),
        Variable<int>(stats['computed_at']),
        Variable<String>(stats['season_id']),
        Variable<String>(stats['player_id']),
      ],
      updateKind: UpdateKind.update,
    );
    if (updated == 0) {
      return _db.customInsert(
        'INSERT INTO player_season_stats (id, season_id, player_id, sport, games_played, '
        'stats_totals, stats_averages, computed_metrics, computed_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable<String>(stats['id']),
          Variable<String>(stats['season_id']),
          Variable<String>(stats['player_id']),
          Variable<String>(stats['sport']),
          Variable<int>(stats['games_played'] ?? 0),
          Variable<String>(stats['stats_totals'] ?? '{}'),
          Variable<String>(stats['stats_averages'] ?? '{}'),
          Variable<String>(stats['computed_metrics'] ?? '{}'),
          Variable<int>(stats['computed_at']),
        ],
      );
    }
    return updated;
  }

  Future<Map<String, dynamic>?> getPlayerSeasonStats(
    String seasonId,
    String playerId,
  ) async {
    final rows = await _db.customSelect(
      'SELECT * FROM player_season_stats WHERE season_id = ? AND player_id = ?',
      variables: [
        Variable<String>(seasonId),
        Variable<String>(playerId),
      ],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  Future<List<Map<String, dynamic>>> getTeamSeasonStats(
      String seasonId) async {
    final rows = await _db.customSelect(
      'SELECT pss.*, p.first_name, p.last_name, p.jersey_number '
      'FROM player_season_stats pss '
      'INNER JOIN players p ON p.id = pss.player_id '
      'WHERE pss.season_id = ? '
      'ORDER BY p.last_name, p.first_name',
      variables: [Variable<String>(seasonId)],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  Future<List<Map<String, dynamic>>> getPlayerGameLog(
    String playerId,
    String seasonId,
  ) async {
    final rows = await _db.customSelect(
      'SELECT pgs.*, g.opponent_name, g.game_date, g.result, g.final_score_us, g.final_score_them '
      'FROM player_game_stats pgs '
      'INNER JOIN games g ON g.id = pgs.game_id '
      'WHERE pgs.player_id = ? AND g.season_id = ? '
      'ORDER BY g.game_date DESC',
      variables: [
        Variable<String>(playerId),
        Variable<String>(seasonId),
      ],
    ).get();
    return rows.map((r) => r.data).toList();
  }
}
