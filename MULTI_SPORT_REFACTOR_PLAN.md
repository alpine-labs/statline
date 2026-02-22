# StatLine — Multi-Sport Refactoring Plan

**Created:** 2026-02-22
**Status:** Planning — not yet started
**Scope:** Architecture changes needed to support a second sport plugin while preserving shared systems (Teams, Players, Seasons, Roster)

---

## Problem Statement

StatLine has a well-designed `SportPlugin` abstraction, but the implementation bypasses it almost everywhere. Volleyball logic is hard-coded into the live game engine, UI screens, stats services, and export layer. Adding a second sport (e.g., slowpitch softball) currently requires either invasive `if (sport == 'volleyball')` guards throughout the codebase or a clean refactor.

This plan covers the refactoring work — not the sport-specific plugin implementation itself.

### What's Already Sport-Agnostic (No Changes Needed)
- `SportPlugin` interface (`lib/domain/sports/sport_plugin.dart`)
- `SportConfig` enum + default formats (`lib/core/constants/sport_config.dart`)
- Core models: `Game`, `PlayEvent`, `GamePeriod`, `Player`, `Team`, `Season`, `PlayerGameStatsModel`, `PlayerSeasonStatsModel`
- `StatsAggregationService` — correctly delegates to `StatCalculator` → plugin
- Database schema for: `teams`, `players`, `seasons`, `games`, `game_periods`, `play_events`, `player_game_stats`, `player_season_stats`, `sync_queue`
- JSON columns for stats/metadata — appropriate for per-sport flexibility

---

## Phase 1 — Core Engine Refactor

*Unblocks multi-sport at the engine level. No UI changes yet.*

### 1.1 Extract Sport-Specific State from LiveGameNotifier

**File:** `lib/presentation/providers/live_game_providers.dart`
**Priority:** 🔴 Critical — this is the #1 blocker

**Problem:** `LiveGameState` has 15+ volleyball-specific fields baked in:
- `currentRotation` (volleyball 1-6)
- `liberoPlayerId`, `liberoIsIn`, `liberoReplacedPlayerId`
- `firstBallSideouts`, `totalSideouts`, `sideoutOpportunities`, `inFirstBallSequence`, `attacksSinceReception`
- `servingTeam` ('us'/'them')
- `maxTimeoutsPerSet` (default 2), `subsThisSet`, `maxSubsPerSet` (default 15)
- `recordEvent()` contains 70 lines of volleyball rally state machine
- `advancePeriod()` assumes set-based scoring with serve alternation
- `endGame()` determines winner by sets won
- `_isReceptionEvent()` / `_isAttackEvent()` hard-code volleyball event strings

**Approach:**

1. Define a `SportGameEngine` abstract class that each sport plugin can provide:
```dart
/// Each sport implements this to handle sport-specific live game logic.
abstract class SportGameEngine {
  /// Sport-specific state as a generic map (rotation, libero, batting order, etc.)
  Map<String, dynamic> get initialSportState;

  /// Called when a play event is recorded. Returns updated sport state + any
  /// modifications to shared state (score, serving team, etc.)
  SportEventResult processEvent(PlayEvent event, LiveGameState currentState);

  /// Called when advancing to the next period. Returns updated sport state.
  Map<String, dynamic> onAdvancePeriod(LiveGameState currentState);

  /// Determines if the game is over based on periods and format.
  bool isGameOver(List<GamePeriod> periods, Map<String, dynamic> gameFormat);

  /// Determines the match result (win/loss/tie) from final state.
  String determineResult(LiveGameState finalState);

  /// Returns the player ID of the current server/batter/etc. (null if N/A).
  String? getActivePlayerId(LiveGameState state);
}

class SportEventResult {
  final Map<String, dynamic> updatedSportState;
  final String? newServingTeam;
  final int? newRotation; // null = no change
  final String? autoSelectPlayerId;
  // ... other shared state overrides
}
```

2. Move all volleyball state into `VolleyballGameEngine implements SportGameEngine`:
   - Rotation tracking, libero in/out, sideout analytics, serve toggling
   - `_isReceptionEvent()`, `_isAttackEvent()` helpers

3. Refactor `LiveGameState` to hold only universal fields:
   - `game`, `periods`, `currentPeriod`, `playEvents`, `scoreUs`, `scoreThem`
   - `entryMode`, `undoStack`, `roster`, `selectedPlayerId`, `lineup`
   - `Map<String, dynamic> sportState` — opaque bag for sport-specific data

4. Refactor `LiveGameNotifier` to delegate to the sport engine:
   - `recordEvent()` calls `engine.processEvent()` instead of inline volleyball logic
   - `advancePeriod()` calls `engine.onAdvancePeriod()`
   - `endGame()` calls `engine.determineResult()`

**Files to change:**
- `lib/presentation/providers/live_game_providers.dart` — refactor
- `lib/domain/sports/sport_plugin.dart` — add `SportGameEngine createGameEngine()`
- `lib/domain/sports/volleyball/` — new `volleyball_game_engine.dart`

### 1.2 Fix StatCalculator Volleyball Leak

**File:** `lib/domain/stats/stat_calculator.dart` (lines 84-91)
**Priority:** 🔴 Critical

**Problem:** Direct `if (sport == 'volleyball')` check with `VolleyballStats.computeHittingPercentage()` call in shared code.

**Fix:** Move this recalculation into `VolleyballPlugin.computeSeasonMetrics()` which is already called on line 81. Delete the `if` block and the `volleyball_stats.dart` import.

**Files to change:**
- `lib/domain/stats/stat_calculator.dart` — remove lines 84-91 and volleyball import
- `lib/domain/sports/volleyball/volleyball_plugin.dart` — ensure `computeSeasonMetrics()` includes the `hittingPercentage` recalculation from totals (it may already — verify)

### 1.3 Refactor GameSummaryService

**File:** `lib/domain/stats/game_summary_service.dart`
**Priority:** 🔴 Critical

**Problem:** Every line is volleyball-specific — event type switches, MVP formula, top performer categories, notable stat thresholds, set-based win logic.

**Approach:** Add a `generateGameSummary()` method to `SportPlugin`:
```dart
abstract class SportPlugin {
  // ... existing methods ...

  /// Generates a game summary from raw data.
  /// Handles sport-specific MVP calculation, top performers, notable stats.
  GameSummary generateGameSummary({
    required Game game,
    required List<GamePeriod> periods,
    required List<PlayEvent> events,
    required List<Player> roster,
  });
}
```

Move the current `GameSummaryService.generate()` body into `VolleyballPlugin.generateGameSummary()`. The service class becomes a thin dispatcher:
```dart
class GameSummaryService {
  static GameSummary generate({...}) {
    final plugin = StatCalculator.getSportPlugin(game.sport);
    return plugin.generateGameSummary(game: game, periods: periods, events: events, roster: roster);
  }
}
```

**Files to change:**
- `lib/domain/sports/sport_plugin.dart` — add `generateGameSummary()` abstract method
- `lib/domain/sports/volleyball/volleyball_plugin.dart` — implement it (move code from service)
- `lib/domain/stats/game_summary_service.dart` — thin dispatcher

### 1.4 Consolidate Duplicate DAO / Repository Layers

**Priority:** 🟡 Important

**Problem:** Both DAOs (`team_dao.dart`, `game_dao.dart`, `stats_dao.dart`, `sync_dao.dart`) AND repositories (`team_repository.dart`, `game_repository.dart`, `stats_repository.dart`, `sync_repository.dart`) contain overlapping raw SQL for the same operations. DAOs use `customInsert/customSelect`, repos use `db.execute/db.query`. Every schema change requires updating both.

**Decision needed:** Pick one layer, delete the other.

**Recommendation:** Keep repositories (they work with domain models, have richer methods like `getSeasonRecord()`, `getLeaderboard()`). Remove DAOs.

**If keeping repositories:**
- Delete `lib/data/database/daos/team_dao.dart`
- Delete `lib/data/database/daos/game_dao.dart`
- Delete `lib/data/database/daos/stats_dao.dart`
- Delete `lib/data/database/daos/sync_dao.dart`
- Remove DAO references from `app_database.dart` (the `late final` DAO fields)
- Update any code that directly references DAOs to use repositories instead
- Search for `teamDao`, `gameDao`, `statsDao`, `syncDao` references and replace

---

## Phase 2 — Sport-Aware UI

*Wires the plugin into all UI screens so they render correctly for any sport.*

### 2.1 Wire ActionPalette to SportPlugin

**File:** `lib/presentation/screens/live_game/widgets/action_palette.dart`
**Priority:** 🔴 Critical

**Problem:** Hard-codes volleyball events as `const` lists. `SportPlugin` already exposes `eventCategories` and `quickModeEvents` — they're just not used.

**Fix:** Accept the sport plugin (or its event definitions) as a parameter. Replace hard-coded lists with `plugin.eventCategories` for detailed mode and `plugin.quickModeEvents` for quick mode.

### 2.2 Make Scoreboard Sport-Configurable

**File:** `lib/presentation/screens/live_game/widgets/scoreboard_widget.dart`
**Priority:** 🔴 Critical

**Problem:** Displays volleyball-specific sideout %, sub limits, timeout dots with volleyball defaults.

**Approach:** Split into:
- Shared scoreboard shell (team names, period scores, game score)
- Sport-specific scoreboard section provided by plugin or driven by config

Option A: Plugin provides a widget:
```dart
abstract class SportPlugin {
  Widget? buildScoreboardExtras(LiveGameState state);
}
```

Option B: Plugin provides a data config and shared widget renders it:
```dart
abstract class SportPlugin {
  List<ScoreboardMetric> getScoreboardMetrics(LiveGameState state);
}
```

### 2.3 Refactor Stats Screens to Use Plugin Columns

**Files:**
- `lib/presentation/screens/stats/season_stats_screen.dart`
- `lib/presentation/screens/stats/leaderboard_screen.dart`
- `lib/presentation/screens/stats/player_detail_screen.dart`

**Priority:** 🔴 Critical

**Problem:**
- `season_stats_screen.dart` hard-codes filter categories `['All', 'Hitting', 'Serving', 'Defense', 'Blocking', 'Passing']` and volleyball stat columns
- `leaderboard_screen.dart` hard-codes `['Kills', 'Hitting %', 'Aces', 'Digs', 'Blocks', 'Points', 'Assists']`
- `player_detail_screen.dart` hard-codes volleyball stat keys, `'volleyball'` strings for exports, trend chart tracks `kills` and `hittingPercentage`

**Fix:** `SportPlugin` already defines `gameStatsColumns` and `seasonStatsColumns` — use them.

Add to `SportPlugin`:
```dart
abstract class SportPlugin {
  // ... existing ...

  /// Filter categories for the season stats screen (e.g., ['All', 'Hitting', 'Serving', ...])
  List<StatFilterCategory> get statFilterCategories;

  /// Leaderboard stat categories (e.g., ['Kills', 'Hitting %', ...])
  List<LeaderboardCategory> get leaderboardCategories;

  /// Key stats to show on the player detail summary card
  List<String> get playerDetailHighlightStats;

  /// Stat keys to chart on the player trend screen
  List<({String key, String label})> get trendChartStats;
}
```

Each screen reads these from the plugin based on the current team's sport.

### 2.4 Sport-Specific Lineup/Field Widgets

**Files:**
- `lib/presentation/screens/live_game/widgets/court_lineup_panel.dart` — volleyball 6-position court
- `lib/presentation/screens/live_game/widgets/rotation_indicator.dart` — volleyball R1-R6
- `lib/presentation/screens/live_game/widgets/lineup_setup_sheet.dart` — 6-position setup

**Priority:** 🟡 Important

**Problem:** These are volleyball-specific widgets used unconditionally in the live game screen.

**Fix:** Keep these as volleyball implementations. Have the sport plugin provide its own:
```dart
abstract class SportPlugin {
  Widget buildLineupPanel(LiveGameState state, {required Function(String) onPlayerTap});
  Widget buildLineupSetupSheet({required List<RosterEntry> roster, ...});
  Widget? buildRotationIndicator(LiveGameState state); // null if sport has no rotation
}
```

Or simpler: use the sport ID to conditionally render:
```dart
// In live_game_screen.dart
switch (game.sport) {
  case 'volleyball':
    return CourtLineupPanel(...);
  case 'slowpitch':
    return DiamondLineupPanel(...);
  default:
    return GenericPlayerList(...);
}
```

### 2.5 Refactor LiveGameScreen

**File:** `lib/presentation/screens/live_game/live_game_screen.dart`
**Priority:** 🔴 Critical

**Problem:**
- Imports `volleyball_stats.dart` directly
- `_computeAllPlayerStats()` calls `VolleyballStats.aggregateFromEvents()` directly
- `_showNewGameDialog()` has `if (team.sport == 'volleyball')` branches
- "Next Set" assumes set-based structure
- Libero toggle in overflow menu

**Fix:**
- Replace `VolleyballStats.aggregateFromEvents()` with `StatCalculator.computePlayerGameStats(sport, events, playerId)`
- Remove direct volleyball import
- Replace `if (sport == 'volleyball')` branches with plugin-driven behavior
- Rename "Next Set" to use `plugin.periodLabel()` (e.g., "Next Inning", "Next Quarter")
- Move libero toggle into the sport-specific scoreboard/menu extras

### 2.6 Refactor Export Layer

**Files:**
- `lib/export/csv_exporter.dart`
- `lib/export/pdf_exporter.dart`
- `lib/export/stats_email_formatter.dart`

**Priority:** 🟡 Important

**Problem:** All have `switch(sport)` with volleyball-only branches and no fallback.

**Fix:** Exporters should read column definitions from `SportPlugin.gameStatsColumns` and `SportPlugin.seasonStatsColumns`. These already contain `key`, `label`, `shortLabel`, `format` — everything an exporter needs.

---

## Phase 3 — Database & Infrastructure

*Cleanup and hardening. Not blocking, but prevents tech debt accumulation.*

### 3.1 Add `sport_metadata` JSON Columns

**File:** `lib/data/database/app_database.dart`
**Priority:** 🟡 Important

**Problem:** Sport-specific columns in shared tables:
- `team_rosters.is_libero` — volleyball-only
- `game_lineups.batting_order` — baseball/softball-only
- `game_lineups.starting_rotation` — volleyball-only
- `substitutions.is_libero_replacement` — volleyball-only

**Fix:** Add `sport_metadata TEXT DEFAULT '{}'` to `team_rosters` and `game_lineups`. Migrate existing data. Keep old columns for backwards compatibility (SQLite doesn't support DROP COLUMN easily).

**Migration (bump to version 3):**
```dart
if (from < 3) {
  await customStatement(
    "ALTER TABLE team_rosters ADD COLUMN sport_metadata TEXT DEFAULT '{}'");
  await customStatement(
    "ALTER TABLE game_lineups ADD COLUMN sport_metadata TEXT DEFAULT '{}'");

  // Migrate existing volleyball data into sport_metadata
  await customStatement('''
    UPDATE team_rosters
    SET sport_metadata = json_object('is_libero', is_libero)
    WHERE is_libero = 1
  ''');
  await customStatement('''
    UPDATE game_lineups
    SET sport_metadata = json_object(
      'batting_order', batting_order,
      'starting_rotation', starting_rotation
    )
    WHERE batting_order IS NOT NULL OR starting_rotation IS NOT NULL
  ''');

  // Add sport-filtering indexes
  await customStatement('CREATE INDEX idx_teams_sport ON teams(sport)');
  await customStatement('CREATE INDEX idx_games_sport ON games(sport)');
  await customStatement('CREATE INDEX idx_pgs_sport ON player_game_stats(sport)');
  await customStatement('CREATE INDEX idx_pss_sport ON player_season_stats(sport)');
}
```

Update `RosterEntry` and `GameLineup` models to read from `sportMetadata` map instead of dedicated fields. Keep old fields as deprecated getters for a transitional period.

### 3.2 Replace Database Singleton with Riverpod DI

**File:** `lib/data/database/app_database.dart`
**Priority:** 🟡 Important

**Problem:** `AppDatabase.getInstance()` global singleton blocks test isolation.

**Fix:**
```dart
// Remove static singleton from AppDatabase

// Add Riverpod provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase._(openConnection());
});

// In tests
final testDb = AppDatabase._(NativeDatabase.memory());
final container = ProviderContainer(
  overrides: [databaseProvider.overrideWithValue(testDb)],
);
```

Update all repository/DAO instantiations to use the provider.

### 3.3 Enable Foreign Key Enforcement

**File:** `lib/data/database/app_database.dart`
**Priority:** 🟢 Quick win

**Fix:** Add `beforeOpen` callback:
```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async { /* existing */ },
  onUpgrade: (m, from, to) async { /* existing */ },
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

### 3.4 Add Sport-Specific Indexes

**Priority:** 🟢 Quick win

Include in the version 3 migration (see 3.1 above). Indexes on `teams(sport)`, `games(sport)`, `player_game_stats(sport)`, `player_season_stats(sport)` for filtering by sport.

---

## Phase 4 — Future DX Improvements (Defer)

These are valuable but not blocking. Tackle when there's bandwidth.

### 4.1 Migrate to Drift Table Classes
Replace raw SQL `customStatement` table definitions with Dart table classes for type safety, IDE autocomplete, reactive `watch()` streams, and compile-time query validation. Large refactor (~16-24h). Coordinate with any ongoing feature work.

### 4.2 JSON Schema Validation
Add optional runtime validation of JSON stat columns on insert/update to catch malformed data early. Document expected JSON shapes per sport in code comments.

---

## Implementation Order & Dependencies

```
Phase 1 (no order dependency between items):
  1.1  LiveGameNotifier refactor
  1.2  StatCalculator fix ← quick, do first
  1.3  GameSummaryService refactor
  1.4  Consolidate DAO/Repository

Phase 2 (depends on Phase 1.1 being complete):
  2.1  ActionPalette ← depends on 1.1 (needs sport plugin in scope)
  2.2  Scoreboard ← depends on 1.1 (reads from refactored state)
  2.3  Stats screens ← independent of 1.1, needs plugin columns
  2.4  Lineup widgets ← depends on 1.1
  2.5  LiveGameScreen ← depends on 1.1, 2.1, 2.2, 2.4
  2.6  Export layer ← independent

Phase 3 (independent of Phases 1-2, can be interleaved):
  3.1  sport_metadata columns
  3.2  DI refactor
  3.3  Foreign key pragma
  3.4  Sport indexes
```

### Suggested Execution Strategy

1. **Start with 1.2** (StatCalculator fix) — 15 minutes, zero risk, removes a code smell
2. **Then 1.4** (consolidate DAO/repo) — reduces surface area before the bigger refactors
3. **Then 1.1** (LiveGameNotifier) — the big one; do this in a feature branch
4. **Then 1.3** (GameSummaryService) — straightforward delegation
5. **Then 3.3 + 3.4** (pragma + indexes) — quick wins, bundle together
6. **Then Phase 2** in order: 2.1 → 2.3 → 2.6 → 2.2 → 2.4 → 2.5
7. **Then 3.1 + 3.2** (schema migration + DI)
8. **Phase 4** whenever bandwidth allows

---

## Validation Checklist

After completing all phases, verify:

- [ ] `flutter analyze` passes with no new warnings
- [ ] `flutter test` passes — all existing tests still green
- [ ] Volleyball live game works identically to before (regression test)
- [ ] A new sport plugin can be created by only adding files under `lib/domain/sports/{sport}/` and registering in `StatCalculator._plugins`
- [ ] No file outside `lib/domain/sports/volleyball/` imports any volleyball-specific file
- [ ] Stats screens, leaderboards, player detail render correctly for the new sport
- [ ] Export (CSV, PDF, email) works for the new sport without modifying exporter code
- [ ] Live game engine works for the new sport without modifying `LiveGameNotifier`
- [ ] `grep -r "volleyball" lib/ --include="*.dart"` only returns hits inside `lib/domain/sports/volleyball/`, `lib/core/constants/sport_config.dart`, and test files
