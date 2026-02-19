import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO for teams, players, seasons, and roster operations.
class TeamDao {
  final AppDatabase _db;

  TeamDao(this._db);

  // --------------- Teams ---------------

  Future<int> insertTeam(Map<String, dynamic> team) {
    return _db.customInsert(
      'INSERT INTO teams (id, organization_id, name, sport, level, gender, age_group, logo_uri, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(team['id']),
        Variable<String>(team['organization_id']),
        Variable<String>(team['name']),
        Variable<String>(team['sport']),
        Variable<String>(team['level'] ?? 'recreational'),
        Variable<String>(team['gender'] ?? 'coed'),
        Variable<String>(team['age_group']),
        Variable<String>(team['logo_uri']),
        Variable<int>(team['created_at']),
        Variable<int>(team['updated_at']),
      ],
    );
  }

  Future<int> updateTeam(Map<String, dynamic> team) {
    return _db.customUpdate(
      'UPDATE teams SET organization_id = ?, name = ?, sport = ?, level = ?, gender = ?, age_group = ?, logo_uri = ?, updated_at = ? '
      'WHERE id = ?',
      variables: [
        Variable<String>(team['organization_id']),
        Variable<String>(team['name']),
        Variable<String>(team['sport']),
        Variable<String>(team['level']),
        Variable<String>(team['gender']),
        Variable<String>(team['age_group']),
        Variable<String>(team['logo_uri']),
        Variable<int>(team['updated_at']),
        Variable<String>(team['id']),
      ],
      updateKind: UpdateKind.update,
    );
  }

  Future<int> deleteTeam(String id) {
    return _db.customUpdate(
      'DELETE FROM teams WHERE id = ?',
      variables: [Variable<String>(id)],
      updateKind: UpdateKind.delete,
    );
  }

  Future<Map<String, dynamic>?> getTeam(String id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM teams WHERE id = ?',
      variables: [Variable<String>(id)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  Future<List<Map<String, dynamic>>> getAllTeams() async {
    final rows = await _db.customSelect(
      'SELECT * FROM teams ORDER BY name',
    ).get();
    return rows.map((r) => r.data).toList();
  }

  // --------------- Players ---------------

  Future<int> insertPlayer(Map<String, dynamic> player) {
    return _db.customInsert(
      'INSERT INTO players (id, first_name, last_name, jersey_number, positions, photo_uri, email, is_active, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(player['id']),
        Variable<String>(player['first_name']),
        Variable<String>(player['last_name']),
        Variable<String>(player['jersey_number']),
        Variable<String>(player['positions'] ?? '[]'),
        Variable<String>(player['photo_uri']),
        Variable<String>(player['email']),
        Variable<int>(player['is_active'] ?? 1),
        Variable<int>(player['created_at']),
        Variable<int>(player['updated_at']),
      ],
    );
  }

  Future<int> updatePlayer(Map<String, dynamic> player) {
    return _db.customUpdate(
      'UPDATE players SET first_name = ?, last_name = ?, jersey_number = ?, positions = ?, photo_uri = ?, email = ?, is_active = ?, updated_at = ? '
      'WHERE id = ?',
      variables: [
        Variable<String>(player['first_name']),
        Variable<String>(player['last_name']),
        Variable<String>(player['jersey_number']),
        Variable<String>(player['positions']),
        Variable<String>(player['photo_uri']),
        Variable<String>(player['email']),
        Variable<int>(player['is_active']),
        Variable<int>(player['updated_at']),
        Variable<String>(player['id']),
      ],
      updateKind: UpdateKind.update,
    );
  }

  Future<Map<String, dynamic>?> getPlayer(String id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM players WHERE id = ?',
      variables: [Variable<String>(id)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  Future<List<Map<String, dynamic>>> getPlayersForTeam(
    String teamId,
    String seasonId,
  ) async {
    final rows = await _db.customSelect(
      'SELECT p.* FROM players p '
      'INNER JOIN team_rosters tr ON tr.player_id = p.id '
      'WHERE tr.team_id = ? AND tr.season_id = ? '
      'ORDER BY p.last_name, p.first_name',
      variables: [
        Variable<String>(teamId),
        Variable<String>(seasonId),
      ],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  // --------------- Seasons ---------------

  Future<int> insertSeason(Map<String, dynamic> season) {
    return _db.customInsert(
      'INSERT INTO seasons (id, team_id, name, start_date, end_date, is_active, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(season['id']),
        Variable<String>(season['team_id']),
        Variable<String>(season['name']),
        Variable<String>(season['start_date']),
        Variable<String>(season['end_date']),
        Variable<int>(season['is_active'] ?? 1),
        Variable<int>(season['created_at']),
        Variable<int>(season['updated_at']),
      ],
    );
  }

  Future<int> updateSeason(Map<String, dynamic> season) {
    return _db.customUpdate(
      'UPDATE seasons SET name = ?, start_date = ?, end_date = ?, is_active = ?, updated_at = ? '
      'WHERE id = ?',
      variables: [
        Variable<String>(season['name']),
        Variable<String>(season['start_date']),
        Variable<String>(season['end_date']),
        Variable<int>(season['is_active']),
        Variable<int>(season['updated_at']),
        Variable<String>(season['id']),
      ],
      updateKind: UpdateKind.update,
    );
  }

  Future<Map<String, dynamic>?> getActiveSeason(String teamId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM seasons WHERE team_id = ? AND is_active = 1 ORDER BY created_at DESC LIMIT 1',
      variables: [Variable<String>(teamId)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  Future<List<Map<String, dynamic>>> getSeasonsForTeam(String teamId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM seasons WHERE team_id = ? ORDER BY start_date DESC',
      variables: [Variable<String>(teamId)],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  // --------------- Team Rosters ---------------

  Future<int> insertRosterEntry(Map<String, dynamic> entry) {
    return _db.customInsert(
      'INSERT INTO team_rosters (id, team_id, player_id, season_id, jersey_number, role, is_libero, joined_date) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>(entry['id']),
        Variable<String>(entry['team_id']),
        Variable<String>(entry['player_id']),
        Variable<String>(entry['season_id']),
        Variable<String>(entry['jersey_number']),
        Variable<String>(entry['role'] ?? 'reserve'),
        Variable<int>(entry['is_libero'] ?? 0),
        Variable<String>(entry['joined_date']),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getRosterForSeason(
    String teamId,
    String seasonId,
  ) async {
    final rows = await _db.customSelect(
      'SELECT tr.*, p.first_name, p.last_name, p.positions, p.photo_uri, p.is_active '
      'FROM team_rosters tr '
      'INNER JOIN players p ON p.id = tr.player_id '
      'WHERE tr.team_id = ? AND tr.season_id = ? '
      'ORDER BY p.last_name, p.first_name',
      variables: [
        Variable<String>(teamId),
        Variable<String>(seasonId),
      ],
    ).get();
    return rows.map((r) => r.data).toList();
  }
}
