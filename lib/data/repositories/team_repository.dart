import '../../domain/models/team.dart';
import '../../domain/models/player.dart';
import '../../domain/models/season.dart';
import '../../domain/models/roster_entry.dart';
import '../database/app_database.dart';

class TeamRepository {
  final AppDatabase _db;

  TeamRepository(this._db);

  // ---------------------------------------------------------------------------
  // Teams
  // ---------------------------------------------------------------------------

  Future<void> createTeam(Team team) async {
    final map = team.toMap();
    await _db.execute(
      '''INSERT INTO teams (id, organization_id, name, sport, level, gender,
         age_group, logo_uri, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['organization_id'],
        map['name'],
        map['sport'],
        map['level'],
        map['gender'],
        map['age_group'],
        map['logo_uri'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }

  Future<void> updateTeam(Team team) async {
    final map = team.toMap();
    await _db.execute(
      '''UPDATE teams SET organization_id = ?, name = ?, sport = ?, level = ?,
         gender = ?, age_group = ?, logo_uri = ?, updated_at = ?
         WHERE id = ?''',
      [
        map['organization_id'],
        map['name'],
        map['sport'],
        map['level'],
        map['gender'],
        map['age_group'],
        map['logo_uri'],
        map['updated_at'],
        map['id'],
      ],
    );
  }

  Future<void> deleteTeam(String teamId) async {
    await _db.execute('DELETE FROM teams WHERE id = ?', [teamId]);
  }

  Future<Team?> getTeam(String teamId) async {
    final rows = await _db.query(
      'SELECT * FROM teams WHERE id = ?',
      [teamId],
    );
    if (rows.isEmpty) return null;
    return Team.fromMap(rows.first);
  }

  Future<List<Team>> getAllTeams() async {
    final rows = await _db.query('SELECT * FROM teams ORDER BY name');
    return rows.map(Team.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Players
  // ---------------------------------------------------------------------------

  Future<void> createPlayer(Player player) async {
    final map = player.toMap();
    await _db.execute(
      '''INSERT INTO players (id, first_name, last_name, jersey_number,
         positions, photo_uri, is_active, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['first_name'],
        map['last_name'],
        map['jersey_number'],
        map['positions'],
        map['photo_uri'],
        map['is_active'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }

  Future<void> updatePlayer(Player player) async {
    final map = player.toMap();
    await _db.execute(
      '''UPDATE players SET first_name = ?, last_name = ?, jersey_number = ?,
         positions = ?, photo_uri = ?, is_active = ?, updated_at = ?
         WHERE id = ?''',
      [
        map['first_name'],
        map['last_name'],
        map['jersey_number'],
        map['positions'],
        map['photo_uri'],
        map['is_active'],
        map['updated_at'],
        map['id'],
      ],
    );
  }

  Future<Player?> getPlayer(String playerId) async {
    final rows = await _db.query(
      'SELECT * FROM players WHERE id = ?',
      [playerId],
    );
    if (rows.isEmpty) return null;
    return Player.fromMap(rows.first);
  }

  Future<List<Player>> getPlayersForTeam(
      String teamId, String seasonId) async {
    final rows = await _db.query(
      '''SELECT p.* FROM players p
         INNER JOIN team_rosters tr ON tr.player_id = p.id
         WHERE tr.team_id = ? AND tr.season_id = ?
         ORDER BY p.last_name, p.first_name''',
      [teamId, seasonId],
    );
    return rows.map(Player.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Seasons
  // ---------------------------------------------------------------------------

  Future<void> createSeason(Season season) async {
    final map = season.toMap();
    await _db.execute(
      '''INSERT INTO seasons (id, team_id, name, start_date, end_date,
         is_active, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['team_id'],
        map['name'],
        map['start_date'],
        map['end_date'],
        map['is_active'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }

  Future<void> updateSeason(Season season) async {
    final map = season.toMap();
    await _db.execute(
      '''UPDATE seasons SET name = ?, start_date = ?, end_date = ?,
         is_active = ?, updated_at = ?
         WHERE id = ?''',
      [
        map['name'],
        map['start_date'],
        map['end_date'],
        map['is_active'],
        map['updated_at'],
        map['id'],
      ],
    );
  }

  Future<Season?> getActiveSeason(String teamId) async {
    final rows = await _db.query(
      'SELECT * FROM seasons WHERE team_id = ? AND is_active = 1 LIMIT 1',
      [teamId],
    );
    if (rows.isEmpty) return null;
    return Season.fromMap(rows.first);
  }

  Future<List<Season>> getSeasonsForTeam(String teamId) async {
    final rows = await _db.query(
      'SELECT * FROM seasons WHERE team_id = ? ORDER BY start_date DESC',
      [teamId],
    );
    return rows.map(Season.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Roster
  // ---------------------------------------------------------------------------

  Future<void> addToRoster(RosterEntry entry) async {
    final map = entry.toMap();
    await _db.execute(
      '''INSERT INTO team_rosters (id, team_id, player_id, season_id,
         jersey_number, role, is_libero, joined_date)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        map['id'],
        map['team_id'],
        map['player_id'],
        map['season_id'],
        map['jersey_number'],
        map['role'],
        map['is_libero'],
        map['joined_date'],
      ],
    );
  }

  Future<void> removeFromRoster(String rosterId) async {
    await _db.execute('DELETE FROM team_rosters WHERE id = ?', [rosterId]);
  }

  Future<List<RosterEntry>> getRoster(
      String teamId, String seasonId) async {
    final rows = await _db.query(
      '''SELECT * FROM team_rosters
         WHERE team_id = ? AND season_id = ?
         ORDER BY jersey_number''',
      [teamId, seasonId],
    );
    return rows.map(RosterEntry.fromMap).toList();
  }
}
