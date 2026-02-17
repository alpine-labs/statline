import '../../domain/models/game.dart';
import '../../domain/models/game_period.dart';
import '../../domain/models/game_lineup.dart';
import '../../domain/models/substitution.dart';
import '../database/app_database.dart';

class GameRepository {
  final AppDatabase _db;

  GameRepository(this._db);

  // ---------------------------------------------------------------------------
  // Games
  // ---------------------------------------------------------------------------

  Future<void> createGame(Game game) async {
    final map = game.toMap();
    await _db.execute(
      '''INSERT INTO games (id, season_id, team_id, opponent_name,
         opponent_team_id, game_date, location, is_home, sport, game_format,
         status, final_score_us, final_score_them, result, notes, entry_mode,
         created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['season_id'],
        map['team_id'],
        map['opponent_name'],
        map['opponent_team_id'],
        map['game_date'],
        map['location'],
        map['is_home'],
        map['sport'],
        map['game_format'],
        map['status'],
        map['final_score_us'],
        map['final_score_them'],
        map['result'],
        map['notes'],
        map['entry_mode'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }

  Future<void> updateGame(Game game) async {
    final map = game.toMap();
    await _db.execute(
      '''UPDATE games SET season_id = ?, team_id = ?, opponent_name = ?,
         opponent_team_id = ?, game_date = ?, location = ?, is_home = ?,
         sport = ?, game_format = ?, status = ?, final_score_us = ?,
         final_score_them = ?, result = ?, notes = ?, entry_mode = ?,
         updated_at = ?
         WHERE id = ?''',
      [
        map['season_id'],
        map['team_id'],
        map['opponent_name'],
        map['opponent_team_id'],
        map['game_date'],
        map['location'],
        map['is_home'],
        map['sport'],
        map['game_format'],
        map['status'],
        map['final_score_us'],
        map['final_score_them'],
        map['result'],
        map['notes'],
        map['entry_mode'],
        map['updated_at'],
        map['id'],
      ],
    );
  }

  Future<Game?> getGame(String gameId) async {
    final rows = await _db.query(
      'SELECT * FROM games WHERE id = ?',
      [gameId],
    );
    if (rows.isEmpty) return null;
    return Game.fromMap(rows.first);
  }

  Future<List<Game>> getGamesForSeason(String seasonId) async {
    final rows = await _db.query(
      'SELECT * FROM games WHERE season_id = ? ORDER BY game_date DESC',
      [seasonId],
    );
    return rows.map(Game.fromMap).toList();
  }

  Future<List<Game>> getRecentGames(String teamId, {int limit = 5}) async {
    final rows = await _db.query(
      '''SELECT * FROM games
         WHERE team_id = ? AND status = 'completed'
         ORDER BY game_date DESC LIMIT ?''',
      [teamId, limit],
    );
    return rows.map(Game.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Game Periods
  // ---------------------------------------------------------------------------

  Future<void> createGamePeriod(GamePeriod period) async {
    final map = period.toMap();
    await _db.execute(
      '''INSERT INTO game_periods (id, game_id, period_number, period_type,
         score_us, score_them)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['game_id'],
        map['period_number'],
        map['period_type'],
        map['score_us'],
        map['score_them'],
      ],
    );
  }

  Future<void> updateGamePeriod(GamePeriod period) async {
    final map = period.toMap();
    await _db.execute(
      '''UPDATE game_periods SET period_number = ?, period_type = ?,
         score_us = ?, score_them = ?
         WHERE id = ?''',
      [
        map['period_number'],
        map['period_type'],
        map['score_us'],
        map['score_them'],
        map['id'],
      ],
    );
  }

  Future<List<GamePeriod>> getGamePeriods(String gameId) async {
    final rows = await _db.query(
      'SELECT * FROM game_periods WHERE game_id = ? ORDER BY period_number',
      [gameId],
    );
    return rows.map(GamePeriod.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Lineup
  // ---------------------------------------------------------------------------

  Future<void> setGameLineup(
      String gameId, List<GameLineup> entries) async {
    // Replace the entire lineup for a game in a single transaction
    await _db.execute(
      'DELETE FROM game_lineups WHERE game_id = ?',
      [gameId],
    );
    for (final entry in entries) {
      final map = entry.toMap();
      await _db.execute(
        '''INSERT INTO game_lineups (id, game_id, player_id, batting_order,
           position, starting_rotation, is_starter, status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          map['id'],
          map['game_id'],
          map['player_id'],
          map['batting_order'],
          map['position'],
          map['starting_rotation'],
          map['is_starter'],
          map['status'],
        ],
      );
    }
  }

  Future<List<GameLineup>> getGameLineup(String gameId) async {
    final rows = await _db.query(
      'SELECT * FROM game_lineups WHERE game_id = ? ORDER BY batting_order',
      [gameId],
    );
    return rows.map(GameLineup.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Substitutions
  // ---------------------------------------------------------------------------

  Future<void> recordSubstitution(Substitution sub) async {
    final map = sub.toMap();
    await _db.execute(
      '''INSERT INTO substitutions (id, game_id, period_id, player_in_id,
         player_out_id, game_clock, is_libero_replacement)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['game_id'],
        map['period_id'],
        map['player_in_id'],
        map['player_out_id'],
        map['game_clock'],
        map['is_libero_replacement'],
      ],
    );
  }

  Future<List<Substitution>> getSubstitutions(String gameId) async {
    final rows = await _db.query(
      'SELECT * FROM substitutions WHERE game_id = ?',
      [gameId],
    );
    return rows.map(Substitution.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Season Record (W-L-T)
  // ---------------------------------------------------------------------------

  Future<Map<String, int>> getSeasonRecord(String seasonId) async {
    final rows = await _db.query(
      '''SELECT result, COUNT(*) as count FROM games
         WHERE season_id = ? AND status = 'completed' AND result IS NOT NULL
         GROUP BY result''',
      [seasonId],
    );

    final record = {'wins': 0, 'losses': 0, 'ties': 0};
    for (final row in rows) {
      final result = row['result'] as String?;
      final count = row['count'] as int;
      switch (result) {
        case 'win':
          record['wins'] = count;
        case 'loss':
          record['losses'] = count;
        case 'tie':
          record['ties'] = count;
      }
    }
    return record;
  }
}
