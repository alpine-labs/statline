import 'dart:convert';

import '../../domain/models/play_event.dart';
import '../../domain/models/player_stats.dart';
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
  // Correction Operations
  // ---------------------------------------------------------------------------

  /// Soft-deletes an event and stores correction metadata.
  Future<void> softDeleteEventForCorrection(
      String eventId, String reason) async {
    // Read existing metadata, merge correction info, write back
    final rows = await _db.query(
      'SELECT metadata FROM play_events WHERE id = ?',
      [eventId],
    );
    if (rows.isEmpty) return;

    final existing = rows.first['metadata'] as String? ?? '{}';
    final meta = Map<String, dynamic>.from(
        jsonDecode(existing) as Map<String, dynamic>);
    meta['correctionReason'] = reason;
    meta['deletedAt'] = DateTime.now().toIso8601String();

    await _db.execute(
      'UPDATE play_events SET is_deleted = 1, metadata = ? WHERE id = ?',
      [jsonEncode(meta), eventId],
    );
  }

  /// Inserts a correction event that replaces a soft-deleted original.
  Future<void> insertCorrectionEvent(
      PlayEvent event, String? originalEventId) async {
    final map = event.toMap();
    // Merge correction metadata into the event's existing metadata
    final correctionMeta = <String, dynamic>{
      'correctionReason': originalEventId != null ? 'edit' : 'insert',
      if (originalEventId != null) 'corrects': originalEventId,
      if (originalEventId != null)
        'correctedAt': DateTime.now().toIso8601String()
      else
        'insertedAt': DateTime.now().toIso8601String(),
    };
    final mergedMetadata = {...event.metadata, ...correctionMeta};
    final metadataStr = jsonEncode(mergedMetadata);

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
        metadataStr,
        map['is_deleted'],
        map['created_at'],
      ],
    );
  }

  /// Re-sequences events in a period to have contiguous integer sequence numbers.
  Future<void> resequenceEvents(String gameId, String periodId) async {
    // Get all active events for this period in order
    final rows = await _db.query(
      '''SELECT id FROM play_events
         WHERE game_id = ? AND period_id = ? AND is_deleted = 0
         ORDER BY sequence_number, created_at''',
      [gameId, periodId],
    );
    // Assign contiguous sequence numbers
    for (int i = 0; i < rows.length; i++) {
      await _db.execute(
        'UPDATE play_events SET sequence_number = ? WHERE id = ?',
        [i + 1, rows[i]['id']],
      );
    }
  }

  /// Gets an event and its correction audit trail (original + all corrections).
  Future<List<PlayEvent>> getEventAuditTrail(String eventId) async {
    // Get the event itself
    final eventRows = await _db.query(
      'SELECT * FROM play_events WHERE id = ?',
      [eventId],
    );
    if (eventRows.isEmpty) return [];
    final event = PlayEvent.fromMap(eventRows.first);

    final trail = <PlayEvent>[event];

    // Find all deleted events that this event corrects (walk back the chain)
    String? correctsId = event.metadata['corrects'] as String?;
    while (correctsId != null) {
      final rows = await _db.query(
        'SELECT * FROM play_events WHERE id = ?',
        [correctsId],
      );
      if (rows.isEmpty) break;
      final original = PlayEvent.fromMap(rows.first);
      trail.add(original);
      correctsId = original.metadata['corrects'] as String?;
    }

    return trail.reversed.toList(); // oldest first
  }

  /// Gets ALL events for a game (including deleted) for correction mode.
  Future<List<PlayEvent>> getAllPlayEventsForGame(String gameId) async {
    final rows = await _db.query(
      '''SELECT * FROM play_events
         WHERE game_id = ?
         ORDER BY period_id, sequence_number, created_at''',
      [gameId],
    );
    return rows.map(PlayEvent.fromMap).toList();
  }

  /// Recalculates scores for all active events in a game.
  /// Walks events per period, recomputing scoreUsAfter/scoreThemAfter
  /// from point results. Updates GamePeriod and Game final scores.
  Future<void> recalculateGameScores(String gameId) async {
    // Get periods in order
    final periodRows = await _db.query(
      'SELECT * FROM game_periods WHERE game_id = ? ORDER BY period_number',
      [gameId],
    );

    int setsWonUs = 0;
    int setsWonThem = 0;

    for (final periodRow in periodRows) {
      final periodId = periodRow['id'] as String;

      // Get active events for this period
      final events = await _db.query(
        '''SELECT id, result FROM play_events
           WHERE game_id = ? AND period_id = ? AND is_deleted = 0
           ORDER BY sequence_number''',
        [gameId, periodId],
      );

      int scoreUs = 0;
      int scoreThem = 0;

      for (final event in events) {
        final result = event['result'] as String;
        if (result == 'point_us') scoreUs++;
        if (result == 'point_them') scoreThem++;

        await _db.execute(
          'UPDATE play_events SET score_us_after = ?, score_them_after = ? WHERE id = ?',
          [scoreUs, scoreThem, event['id']],
        );
      }

      // Update period score
      await _db.execute(
        'UPDATE game_periods SET score_us = ?, score_them = ? WHERE id = ?',
        [scoreUs, scoreThem, periodId],
      );

      if (scoreUs > scoreThem) setsWonUs++;
      if (scoreThem > scoreUs) setsWonThem++;
    }

    // Update game final scores and result
    String? result;
    if (setsWonUs > setsWonThem) {
      result = 'win';
    } else if (setsWonThem > setsWonUs) {
      result = 'loss';
    } else {
      result = 'tie';
    }

    await _db.execute(
      '''UPDATE games SET final_score_us = ?, final_score_them = ?,
         result = ?, updated_at = ?
         WHERE id = ?''',
      [
        setsWonUs,
        setsWonThem,
        result,
        DateTime.now().millisecondsSinceEpoch,
        gameId,
      ],
    );
  }

  /// Shifts sequence numbers up by 1 for events after a given position.
  Future<void> shiftSequenceNumbers(
      String gameId, String periodId, int afterSequence) async {
    await _db.execute(
      '''UPDATE play_events SET sequence_number = sequence_number + 1
         WHERE game_id = ? AND period_id = ? AND is_deleted = 0
         AND sequence_number > ?''',
      [gameId, periodId, afterSequence],
    );
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

  /// Returns game log rows with joined game info (opponent, date, result).
  Future<List<Map<String, dynamic>>> getPlayerGameLogWithGameInfo(
      String playerId, String seasonId) async {
    return await _db.query(
      '''SELECT pgs.*, g.opponent_name, g.game_date, g.result,
                g.final_score_us, g.final_score_them
         FROM player_game_stats pgs
         INNER JOIN games g ON g.id = pgs.game_id
         WHERE pgs.player_id = ? AND g.season_id = ?
         ORDER BY g.game_date ASC''',
      [playerId, seasonId],
    );
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
