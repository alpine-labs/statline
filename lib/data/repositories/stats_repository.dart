import 'dart:convert';

import '../../domain/models/play_event.dart';
import '../../domain/models/stats.dart';
import '../database/app_database.dart';

class StatsRepository {
  final AppDatabase _db;

  StatsRepository(this._db);

  // ---------------------------------------------------------------------------
  // Play Events
  // ---------------------------------------------------------------------------

  Future<void> recordPlayEvent(PlayEvent event) async {
    final map = event.toMap();
    await _db.execute(
      '''INSERT INTO play_events (id, game_id, period_id, sequence_number,
         timestamp, game_clock, player_id, secondary_player_id,
         event_category, event_type, result, score_us_after, score_them_after,
         is_opponent, notes, metadata, is_deleted, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['game_id'],
        map['period_id'],
        map['sequence_number'],
        map['timestamp'],
        map['game_clock'],
        map['player_id'],
        map['secondary_player_id'],
        map['event_category'],
        map['event_type'],
        map['result'],
        map['score_us_after'],
        map['score_them_after'],
        map['is_opponent'],
        map['notes'],
        map['metadata'],
        map['is_deleted'],
        map['created_at'],
      ],
    );
  }

  Future<void> undoLastPlayEvent(String gameId) async {
    // Soft-delete the most recent non-deleted event for this game
    await _db.execute(
      '''UPDATE play_events SET is_deleted = 1
         WHERE id = (
           SELECT id FROM play_events
           WHERE game_id = ? AND is_deleted = 0
           ORDER BY sequence_number DESC
           LIMIT 1
         )''',
      [gameId],
    );
  }

  Future<PlayEvent?> getLastPlayEvent(String gameId) async {
    final rows = await _db.query(
      '''SELECT * FROM play_events
         WHERE game_id = ? AND is_deleted = 0
         ORDER BY sequence_number DESC LIMIT 1''',
      [gameId],
    );
    if (rows.isEmpty) return null;
    return PlayEvent.fromMap(rows.first);
  }

  Future<List<PlayEvent>> getPlayEventsForGame(String gameId) async {
    final rows = await _db.query(
      '''SELECT * FROM play_events
         WHERE game_id = ?
         ORDER BY sequence_number''',
      [gameId],
    );
    return rows.map(PlayEvent.fromMap).toList();
  }

  Future<List<PlayEvent>> getActivePlayEventsForGame(String gameId) async {
    final rows = await _db.query(
      '''SELECT * FROM play_events
         WHERE game_id = ? AND is_deleted = 0
         ORDER BY sequence_number''',
      [gameId],
    );
    return rows.map(PlayEvent.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Player Game Stats
  // ---------------------------------------------------------------------------

  Future<void> savePlayerGameStats(PlayerGameStatsModel stats) async {
    final map = stats.toMap();
    // Upsert: insert or replace if the same game+player combo already exists
    await _db.execute(
      '''INSERT OR REPLACE INTO player_game_stats
         (id, game_id, player_id, sport, stats, computed_at)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['game_id'],
        map['player_id'],
        map['sport'],
        map['stats'],
        map['computed_at'],
      ],
    );
  }

  Future<PlayerGameStatsModel?> getPlayerGameStats(
      String gameId, String playerId) async {
    final rows = await _db.query(
      '''SELECT * FROM player_game_stats
         WHERE game_id = ? AND player_id = ?''',
      [gameId, playerId],
    );
    if (rows.isEmpty) return null;
    return PlayerGameStatsModel.fromMap(rows.first);
  }

  Future<List<PlayerGameStatsModel>> getAllPlayerGameStats(
      String gameId) async {
    final rows = await _db.query(
      'SELECT * FROM player_game_stats WHERE game_id = ?',
      [gameId],
    );
    return rows.map(PlayerGameStatsModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Player Season Stats
  // ---------------------------------------------------------------------------

  Future<void> savePlayerSeasonStats(PlayerSeasonStatsModel stats) async {
    final map = stats.toMap();
    await _db.execute(
      '''INSERT OR REPLACE INTO player_season_stats
         (id, season_id, player_id, sport, games_played, stats_totals,
          stats_averages, computed_metrics, computed_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['season_id'],
        map['player_id'],
        map['sport'],
        map['games_played'],
        map['stats_totals'],
        map['stats_averages'],
        map['computed_metrics'],
        map['computed_at'],
      ],
    );
  }

  Future<PlayerSeasonStatsModel?> getPlayerSeasonStats(
      String seasonId, String playerId) async {
    final rows = await _db.query(
      '''SELECT * FROM player_season_stats
         WHERE season_id = ? AND player_id = ?''',
      [seasonId, playerId],
    );
    if (rows.isEmpty) return null;
    return PlayerSeasonStatsModel.fromMap(rows.first);
  }

  Future<List<PlayerSeasonStatsModel>> getTeamSeasonStats(
      String seasonId) async {
    final rows = await _db.query(
      'SELECT * FROM player_season_stats WHERE season_id = ?',
      [seasonId],
    );
    return rows.map(PlayerSeasonStatsModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Player Game Log
  // ---------------------------------------------------------------------------

  Future<List<PlayerGameStatsModel>> getPlayerGameLog(
      String playerId, String seasonId) async {
    final rows = await _db.query(
      '''SELECT pgs.* FROM player_game_stats pgs
         INNER JOIN games g ON g.id = pgs.game_id
         WHERE pgs.player_id = ? AND g.season_id = ?
         ORDER BY g.game_date DESC''',
      [playerId, seasonId],
    );
    return rows.map(PlayerGameStatsModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Leaderboards
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getLeaderboard(
    String seasonId,
    String statKey, {
    int limit = 5,
    bool descending = true,
  }) async {
    // Read all season stats for the season, then sort by the requested key.
    // We extract the stat value from the JSON stats_totals column in Dart
    // because SQLite's JSON support varies across platforms.
    final rows = await _db.query(
      '''SELECT pss.*, p.first_name, p.last_name, p.jersey_number
         FROM player_season_stats pss
         INNER JOIN players p ON p.id = pss.player_id
         WHERE pss.season_id = ?''',
      [seasonId],
    );

    // Parse and sort by the requested stat key
    final entries = rows.map((row) {
      final totals =
          jsonDecode(row['stats_totals'] as String) as Map<String, dynamic>;
      final value = (totals[statKey] as num?)?.toDouble() ?? 0.0;
      return {
        'player_id': row['player_id'],
        'first_name': row['first_name'],
        'last_name': row['last_name'],
        'jersey_number': row['jersey_number'],
        'stat_key': statKey,
        'value': value,
        'games_played': row['games_played'],
      };
    }).toList();

    entries.sort((a, b) {
      final av = a['value'] as double;
      final bv = b['value'] as double;
      return descending ? bv.compareTo(av) : av.compareTo(bv);
    });

    return entries.take(limit).toList();
  }
}
