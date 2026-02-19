import 'package:drift/drift.dart';

import 'connection.dart';
import 'daos/team_dao.dart';
import 'daos/game_dao.dart';
import 'daos/stats_dao.dart';
import 'daos/sync_dao.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase._(super.e);

  static AppDatabase? _instance;

  static AppDatabase getInstance() {
    return _instance ??= AppDatabase._(openConnection());
  }

  // DAOs — lazily initialized
  late final TeamDao teamDao = TeamDao(this);
  late final GameDao gameDao = GameDao(this);
  late final StatsDao statsDao = StatsDao(this);
  late final SyncDao syncDao = SyncDao(this);

  /// Executes a raw SELECT query and returns rows as maps.
  Future<List<Map<String, dynamic>>> query(String sql,
      [List<Object?> params = const []]) async {
    final result = await customSelect(sql,
        variables: params.map((p) => Variable(p)).toList()).get();
    return result.map((row) => row.data).toList();
  }

  /// Executes a raw statement (INSERT, UPDATE, DELETE, etc.) with no return.
  Future<void> execute(String sql,
      [List<Object?> params = const []]) async {
    await customStatement(sql, params);
  }

  /// Executes a raw INSERT and returns the last inserted row ID.
  Future<int> insert(String sql,
      [List<Object?> params = const []]) async {
    await customStatement(sql, params);
    final result = await customSelect('SELECT last_insert_rowid() AS id').get();
    return result.first.data['id'] as int;
  }

  @override
  int get schemaVersion => 2;

  @override
  List<TableInfo<Table, dynamic>> get allTables => [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await customStatement('''
            CREATE TABLE teams (
              id TEXT PRIMARY KEY,
              organization_id TEXT,
              name TEXT NOT NULL,
              sport TEXT NOT NULL,
              level TEXT NOT NULL DEFAULT 'recreational',
              gender TEXT NOT NULL DEFAULT 'coed',
              age_group TEXT,
              logo_uri TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          await customStatement('''
            CREATE TABLE players (
              id TEXT PRIMARY KEY,
              first_name TEXT NOT NULL,
              last_name TEXT NOT NULL,
              jersey_number TEXT NOT NULL,
              positions TEXT NOT NULL DEFAULT '[]',
              photo_uri TEXT,
              email TEXT,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          await customStatement('''
            CREATE TABLE seasons (
              id TEXT PRIMARY KEY,
              team_id TEXT NOT NULL REFERENCES teams(id),
              name TEXT NOT NULL,
              start_date TEXT NOT NULL,
              end_date TEXT,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          await customStatement('''
            CREATE TABLE team_rosters (
              id TEXT PRIMARY KEY,
              team_id TEXT NOT NULL REFERENCES teams(id),
              player_id TEXT NOT NULL REFERENCES players(id),
              season_id TEXT NOT NULL REFERENCES seasons(id),
              jersey_number TEXT NOT NULL,
              role TEXT NOT NULL DEFAULT 'reserve',
              is_libero INTEGER NOT NULL DEFAULT 0,
              joined_date TEXT NOT NULL
            )
          ''');

          await customStatement('''
            CREATE TABLE games (
              id TEXT PRIMARY KEY,
              season_id TEXT NOT NULL REFERENCES seasons(id),
              team_id TEXT NOT NULL REFERENCES teams(id),
              opponent_name TEXT NOT NULL,
              opponent_team_id TEXT,
              game_date TEXT NOT NULL,
              location TEXT,
              is_home INTEGER NOT NULL DEFAULT 1,
              sport TEXT NOT NULL,
              game_format TEXT NOT NULL DEFAULT '{}',
              status TEXT NOT NULL DEFAULT 'scheduled',
              final_score_us INTEGER,
              final_score_them INTEGER,
              result TEXT,
              notes TEXT,
              entry_mode TEXT NOT NULL DEFAULT 'quick',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          await customStatement('''
            CREATE TABLE game_periods (
              id TEXT PRIMARY KEY,
              game_id TEXT NOT NULL REFERENCES games(id),
              period_number INTEGER NOT NULL,
              period_type TEXT NOT NULL,
              score_us INTEGER NOT NULL DEFAULT 0,
              score_them INTEGER NOT NULL DEFAULT 0
            )
          ''');

          await customStatement('''
            CREATE TABLE game_lineups (
              id TEXT PRIMARY KEY,
              game_id TEXT NOT NULL REFERENCES games(id),
              player_id TEXT NOT NULL REFERENCES players(id),
              batting_order INTEGER,
              position TEXT NOT NULL,
              starting_rotation INTEGER,
              is_starter INTEGER NOT NULL DEFAULT 1,
              status TEXT NOT NULL DEFAULT 'active'
            )
          ''');

          await customStatement('''
            CREATE TABLE substitutions (
              id TEXT PRIMARY KEY,
              game_id TEXT NOT NULL REFERENCES games(id),
              period_id TEXT NOT NULL REFERENCES game_periods(id),
              player_in_id TEXT NOT NULL REFERENCES players(id),
              player_out_id TEXT NOT NULL REFERENCES players(id),
              game_clock TEXT,
              is_libero_replacement INTEGER NOT NULL DEFAULT 0
            )
          ''');

          await customStatement('''
            CREATE TABLE play_events (
              id TEXT PRIMARY KEY,
              game_id TEXT NOT NULL REFERENCES games(id),
              period_id TEXT NOT NULL REFERENCES game_periods(id),
              sequence_number INTEGER NOT NULL,
              timestamp INTEGER NOT NULL,
              game_clock TEXT,
              player_id TEXT NOT NULL,
              secondary_player_id TEXT,
              event_category TEXT NOT NULL,
              event_type TEXT NOT NULL,
              result TEXT NOT NULL,
              score_us_after INTEGER NOT NULL DEFAULT 0,
              score_them_after INTEGER NOT NULL DEFAULT 0,
              is_opponent INTEGER NOT NULL DEFAULT 0,
              notes TEXT,
              metadata TEXT NOT NULL DEFAULT '{}',
              is_deleted INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            )
          ''');

          await customStatement('''
            CREATE TABLE player_game_stats (
              id TEXT PRIMARY KEY,
              game_id TEXT NOT NULL REFERENCES games(id),
              player_id TEXT NOT NULL REFERENCES players(id),
              sport TEXT NOT NULL,
              stats TEXT NOT NULL DEFAULT '{}',
              computed_at INTEGER NOT NULL
            )
          ''');

          await customStatement('''
            CREATE TABLE player_season_stats (
              id TEXT PRIMARY KEY,
              season_id TEXT NOT NULL REFERENCES seasons(id),
              player_id TEXT NOT NULL REFERENCES players(id),
              sport TEXT NOT NULL,
              games_played INTEGER NOT NULL DEFAULT 0,
              stats_totals TEXT NOT NULL DEFAULT '{}',
              stats_averages TEXT NOT NULL DEFAULT '{}',
              computed_metrics TEXT NOT NULL DEFAULT '{}',
              computed_at INTEGER NOT NULL
            )
          ''');

          await customStatement('''
            CREATE TABLE sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              table_name TEXT NOT NULL,
              record_id TEXT NOT NULL,
              operation TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              synced_at INTEGER,
              retry_count INTEGER NOT NULL DEFAULT 0,
              error TEXT
            )
          ''');

          await customStatement('''
            CREATE TABLE feature_flags (
              key TEXT PRIMARY KEY,
              enabled INTEGER NOT NULL DEFAULT 1,
              tier TEXT NOT NULL DEFAULT 'free'
            )
          ''');

          // Indexes for common queries
          await customStatement(
              'CREATE INDEX idx_seasons_team ON seasons(team_id)');
          await customStatement(
              'CREATE INDEX idx_team_rosters_team_season ON team_rosters(team_id, season_id)');
          await customStatement(
              'CREATE INDEX idx_games_season ON games(season_id)');
          await customStatement(
              'CREATE INDEX idx_game_periods_game ON game_periods(game_id)');
          await customStatement(
              'CREATE INDEX idx_game_lineups_game ON game_lineups(game_id)');
          await customStatement(
              'CREATE INDEX idx_substitutions_game ON substitutions(game_id)');
          await customStatement(
              'CREATE INDEX idx_play_events_game ON play_events(game_id)');
          await customStatement(
              'CREATE INDEX idx_play_events_game_period ON play_events(game_id, period_id)');
          await customStatement(
              'CREATE INDEX idx_player_game_stats_game ON player_game_stats(game_id)');
          await customStatement(
              'CREATE INDEX idx_player_game_stats_player ON player_game_stats(player_id)');
          await customStatement(
              'CREATE INDEX idx_player_season_stats_season ON player_season_stats(season_id)');
          await customStatement(
              'CREATE INDEX idx_sync_queue_pending ON sync_queue(synced_at)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
                'ALTER TABLE players ADD COLUMN email TEXT');
          }
        },
      );
}
