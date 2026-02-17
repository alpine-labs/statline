import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO for games, game periods, lineups, and substitutions.
class GameDao {
  final AppDatabase _db;

  GameDao(this._db);

  // --------------- Games ---------------

  Future<int> insertGame(Map<String, dynamic> game) {
    return _db.customInsert(
      'INSERT INTO games (id, season_id, team_id, opponent_name, opponent_team_id, game_date, location, is_home, '
      'sport, game_format, status, final_score_us, final_score_them, result, notes, entry_mode, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(game['id']),
        Variable<String>(game['season_id']),
        Variable<String>(game['team_id']),
        Variable<String>(game['opponent_name']),
        Variable<String>(game['opponent_team_id']),
        Variable<String>(game['game_date']),
        Variable<String>(game['location']),
        Variable<int>(game['is_home'] ?? 1),
        Variable<String>(game['sport']),
        Variable<String>(game['game_format'] ?? '{}'),
        Variable<String>(game['status'] ?? 'scheduled'),
        Variable<int>(game['final_score_us']),
        Variable<int>(game['final_score_them']),
        Variable<String>(game['result']),
        Variable<String>(game['notes']),
        Variable<String>(game['entry_mode'] ?? 'quick'),
        Variable<int>(game['created_at']),
        Variable<int>(game['updated_at']),
      ],
    );
  }

  Future<int> updateGame(Map<String, dynamic> game) {
    return _db.customUpdate(
      'UPDATE games SET opponent_name = ?, opponent_team_id = ?, game_date = ?, location = ?, is_home = ?, '
      'game_format = ?, status = ?, final_score_us = ?, final_score_them = ?, result = ?, notes = ?, '
      'entry_mode = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable<String>(game['opponent_name']),
        Variable<String>(game['opponent_team_id']),
        Variable<String>(game['game_date']),
        Variable<String>(game['location']),
        Variable<int>(game['is_home']),
        Variable<String>(game['game_format']),
        Variable<String>(game['status']),
        Variable<int>(game['final_score_us']),
        Variable<int>(game['final_score_them']),
        Variable<String>(game['result']),
        Variable<String>(game['notes']),
        Variable<String>(game['entry_mode']),
        Variable<int>(game['updated_at']),
        Variable<String>(game['id']),
      ],
      updateKind: UpdateKind.update,
    );
  }

  Future<Map<String, dynamic>?> getGame(String id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM games WHERE id = ?',
      variables: [Variable<String>(id)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  Future<List<Map<String, dynamic>>> getGamesForSeason(
      String seasonId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM games WHERE season_id = ? ORDER BY game_date DESC',
      variables: [Variable<String>(seasonId)],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  // --------------- Game Periods ---------------

  Future<int> insertGamePeriod(Map<String, dynamic> period) {
    return _db.customInsert(
      'INSERT INTO game_periods (id, game_id, period_number, period_type, score_us, score_them) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(period['id']),
        Variable<String>(period['game_id']),
        Variable<int>(period['period_number']),
        Variable<String>(period['period_type']),
        Variable<int>(period['score_us'] ?? 0),
        Variable<int>(period['score_them'] ?? 0),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getPeriodsForGame(
      String gameId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM game_periods WHERE game_id = ? ORDER BY period_number',
      variables: [Variable<String>(gameId)],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  // --------------- Game Lineups ---------------

  Future<int> insertGameLineup(Map<String, dynamic> lineup) {
    return _db.customInsert(
      'INSERT INTO game_lineups (id, game_id, player_id, batting_order, position, starting_rotation, is_starter, status) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(lineup['id']),
        Variable<String>(lineup['game_id']),
        Variable<String>(lineup['player_id']),
        Variable<int>(lineup['batting_order']),
        Variable<String>(lineup['position']),
        Variable<int>(lineup['starting_rotation']),
        Variable<int>(lineup['is_starter'] ?? 1),
        Variable<String>(lineup['status'] ?? 'active'),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getLineupForGame(
      String gameId) async {
    final rows = await _db.customSelect(
      'SELECT gl.*, p.first_name, p.last_name, p.jersey_number '
      'FROM game_lineups gl '
      'INNER JOIN players p ON p.id = gl.player_id '
      'WHERE gl.game_id = ? '
      'ORDER BY gl.batting_order, gl.starting_rotation',
      variables: [Variable<String>(gameId)],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  // --------------- Substitutions ---------------

  Future<int> insertSubstitution(Map<String, dynamic> sub) {
    return _db.customInsert(
      'INSERT INTO substitutions (id, game_id, period_id, player_in_id, player_out_id, game_clock, is_libero_replacement) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(sub['id']),
        Variable<String>(sub['game_id']),
        Variable<String>(sub['period_id']),
        Variable<String>(sub['player_in_id']),
        Variable<String>(sub['player_out_id']),
        Variable<String>(sub['game_clock']),
        Variable<int>(sub['is_libero_replacement'] ?? 0),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getSubstitutionsForGame(
      String gameId) async {
    final rows = await _db.customSelect(
      'SELECT s.*, '
      'pin.first_name AS player_in_first, pin.last_name AS player_in_last, '
      'pout.first_name AS player_out_first, pout.last_name AS player_out_last '
      'FROM substitutions s '
      'INNER JOIN players pin ON pin.id = s.player_in_id '
      'INNER JOIN players pout ON pout.id = s.player_out_id '
      'WHERE s.game_id = ? '
      'ORDER BY s.rowid',
      variables: [Variable<String>(gameId)],
    ).get();
    return rows.map((r) => r.data).toList();
  }
}
