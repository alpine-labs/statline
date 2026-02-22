# StatLine Multi-Sport Refactor Plan

> **Purpose:** Identify and fix all volleyball-specific coupling throughout the codebase so a second sport can be implemented cleanly using the existing `SportPlugin` abstraction and shared systems (Teams, Players, Seasons, Roster).
>
> **Status:** Ready for implementation. Do NOT start until ready — this is a reference plan.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Phase 1 — Unblock Multi-Sport (Core Refactors)](#phase-1--unblock-multi-sport-core-refactors)
3. [Phase 2 — Sport-Aware UI](#phase-2--sport-aware-ui)
4. [Phase 3 — Database & DX Improvements](#phase-3--database--dx-improvements)
5. [Phase 4 — Future (Defer)](#phase-4--future-defer)
6. [Test Strategy](#test-strategy)
7. [Dependency Graph](#dependency-graph)
8. [Validation Checklist](#validation-checklist)
9. [Files Index](#files-index)

---

## Executive Summary

**The `SportPlugin` abstraction is well-designed — but almost nothing in the app actually uses it.** The UI, state management, live game engine, stats screens, game summary, and export layers all hard-code volleyball logic, bypassing the plugin entirely. The database layer works but has Drift anti-patterns and sport-specific column leakage.

**Good news:** The core models (`Game`, `PlayEvent`, `GamePeriod`, `Player`, `Team`, `Season`) and the stats pipeline (`StatsAggregationService` → `StatCalculator` → `SportPlugin`) are sport-agnostic and well-structured.

### What's Already Good (No Changes Needed)

- `SportPlugin` interface — events, formats, stats computation, columns, periods, game state
- `SportConfig` enum — defaults for 5 sports
- Core models — sport-agnostic
- `StatsAggregationService` → `StatCalculator` → plugin delegation (correct pattern)
- `sport_icon.dart` and `colors.dart` — already sport-aware
- Feature flags, routing, sync layer — generic

---

## Phase 1 — Unblock Multi-Sport (Core Refactors)

These are **blocking** — no second sport can work without these changes.

### 1.1 Extract Volleyball State from LiveGameNotifier

**File:** `lib/presentation/providers/live_game_providers.dart`

The #1 blocker. `LiveGameState` has 15+ volleyball fields baked into shared state, and `LiveGameNotifier` is a volleyball game engine wearing a generic name.

**Volleyball fields to extract:**
- `currentRotation` (1-6), `rotateForward()`, `rotateBackward()` (modulo 6)
- `liberoPlayerId`, `liberoIsIn`, `liberoReplacedPlayerId`, `setLibero()`, `liberoIn()`, `liberoOut()`
- `firstBallSideouts`, `totalSideouts`, `sideoutOpportunities`, `inFirstBallSequence`, `attacksSinceReception`
- `servingTeam` ('us'/'them')
- `maxTimeoutsPerSet` (default 2), `subsThisSet`, `maxSubsPerSet` (default 15)
- `_isReceptionEvent()`, `_isAttackEvent()` with volleyball event type strings
- `recordEvent()` — 70 lines of volleyball rally state machine
- `advancePeriod()` — resets scores + alternates serve (wrong for innings/quarters)
- `endGame()` — determines winner by sets won (wrong for baseball)

**Solution — `SportGameEngine` interface:**

```dart
/// lib/domain/sports/sport_game_engine.dart
abstract class SportGameEngine {
  /// Sport-specific live game state (rotation, batting order, etc.)
  Map<String, dynamic> get sportState;

  /// Called when an event is recorded — update sport-specific state.
  /// Return updated sport state map.
  Map<String, dynamic> onEventRecorded(PlayEvent event, LiveGameState state);

  /// Called when period advances — return updated sport state.
  Map<String, dynamic> onPeriodAdvanced(int newPeriod, LiveGameState state);

  /// Determine the game winner. Return 'us', 'them', or 'tie'.
  String determineWinner(LiveGameState state);

  /// Can a substitution be made right now?
  bool canSubstitute(LiveGameState state);

  /// Validate event before recording (e.g., can't serve from wrong rotation)
  String? validateEvent(PlayEvent event, LiveGameState state);
}
```

`LiveGameState` keeps only universal fields: `game`, `periods`, `scores`, `events`, `roster`, `lineup`, `undoStack`, `entryMode`, and a `Map<String, dynamic> sportState` bag. `LiveGameNotifier.recordEvent()` delegates sport logic to `sportEngine.onEventRecorded()`.

**Tests impacted:** `live_game_providers_test.dart` (40+ tests) — see [Test Strategy](#test-strategy).

---

### 1.2 Fix StatCalculator Volleyball Leak

**File:** `lib/domain/stats/stat_calculator.dart` lines 84-91

Direct `if (sport == 'volleyball')` guard with `VolleyballStats.computeHittingPercentage()` import.

**Fix:** Move the `hittingPercentage` recalculation into `VolleyballPlugin.computeSeasonMetrics()` which already exists and is the correct place.

**Tests impacted:** `stat_calculator_test.dart` (11 tests) — update to verify delegation, not volleyball-specific computation.

---

### 1.3 Move GameSummaryService Into Plugin

**File:** `lib/domain/stats/game_summary_service.dart` (171 lines)

100% volleyball — event type switches, MVP formula (`kills + aces + blocks × 0.5`), top performer categories (`kills`, `digs`, `aces`, `blocks`, `assists`), notable stat thresholds (`≥10 kills`), set-based win detection.

**Solution — add to `SportPlugin`:**

```dart
/// In SportPlugin
GameSummary generateGameSummary(List<PlayEvent> events, List<PlayerStats> stats);

/// GameSummary is a generic container
class GameSummary {
  final String mvpPlayerId;
  final String mvpReason;
  final List<TopPerformer> topPerformers;
  final List<String> notableStats;
  final String winnerDetermination; // 'us', 'them', 'tie'
}
```

`GameSummaryService` becomes a thin dispatcher that gets the plugin and calls `plugin.generateGameSummary()`.

**Tests needed:** New `game_summary_service_test.dart` — see [Test Strategy](#test-strategy).

---

### 1.4 Wire ActionPalette to Plugin

**File:** `lib/presentation/screens/live_game/widgets/action_palette.dart`

Hard-codes volleyball events as `const` lists. Ignores `SportPlugin.eventCategories` and `SportPlugin.quickModeEvents` which already exist and contain the correct data.

**Fix:** Read from `sportPlugin.eventCategories` / `sportPlugin.quickModeEvents` at build time.

---

### 1.5 Consolidate Duplicate DAO/Repository Layer

DAOs (`team_dao.dart`, `game_dao.dart`, etc.) AND repositories (`team_repository.dart`, etc.) contain overlapping raw SQL. DAOs use `customInsert/customSelect`, repos use `db.execute/db.query`. Every schema change requires updating 2+ files.

**Fix:** Pick one layer. Recommended: keep repositories (domain-level interface), have them use DAOs internally, remove direct `db.execute/db.query` from repos. Or collapse DAOs into repos entirely.

---

## Phase 2 — Sport-Aware UI

### 2.1 Scoreboard Widget

**File:** `lib/presentation/screens/live_game/widgets/scoreboard_widget.dart`

Displays volleyball-specific: `subsThisSet`/`maxSubsPerSet`, sideout %, first-ball sideout %, timeout dots with volleyball defaults.

**Fix:** Have sport plugin provide scoreboard configuration or a custom widget. Keep volleyball scoreboard as `VolleyballScoreboardSection`.

---

### 2.2 Sport-Specific Live Game Widgets

**Files:**
- `court_lineup_panel.dart` — volleyball 6-position court layout
- `rotation_indicator.dart` — volleyball R1-R6
- `lineup_setup_sheet.dart` — requires exactly 6 players

**Fix:** Have sport plugin provide its lineup/field widget. These become the volleyball implementations (fine to keep, just not used unconditionally).

---

### 2.3 Season Stats Screen

**File:** `lib/presentation/screens/stats/season_stats_screen.dart`

- Filters: `['All', 'Hitting', 'Serving', 'Defense', 'Blocking', 'Passing']` — volleyball categories
- Columns: volleyball stat keys
- Default sort: `'kills'`

**Fix:** Add to `SportPlugin`:

```dart
List<StatFilter> get statFilters;       // e.g., [StatFilter('Hitting', ['kills','errors','ta','hitPct'])]
String get defaultSortStat;             // e.g., 'kills' for volleyball
```

---

### 2.4 Leaderboard Screen

**File:** `lib/presentation/screens/stats/leaderboard_screen.dart`

`_statCategories = ['Kills', 'Hitting %', 'Aces', 'Digs', 'Blocks', 'Points', 'Assists']`

**Fix:** Add to `SportPlugin`:

```dart
List<LeaderboardCategory> get leaderboardCategories;
```

---

### 2.5 Player Detail Screen

**File:** `lib/presentation/screens/stats/player_detail_screen.dart`

Hard-coded volleyball stat display, `'volleyball'` for exports, game log columns, trend chart tracks `kills`/`hittingPercentage`.

**Fix:** Use `plugin.gameStatsColumns`/`plugin.seasonStatsColumns` for display. Add to plugin:

```dart
List<TrendMetric> get trendMetrics; // e.g., [TrendMetric('kills', 'Kills'), TrendMetric('hittingPercentage', 'Hit%')]
```

---

### 2.6 Live Game Screen

**File:** `lib/presentation/screens/live_game/live_game_screen.dart`

- Imports `volleyball_stats.dart` directly
- `_computeAllPlayerStats()` calls `VolleyballStats.aggregateFromEvents()` directly
- `_showNewGameDialog()` has `if (team.sport == 'volleyball')` branches
- "Next Set" menu item assumes set-based structure
- Libero toggle in overflow menu

**Fix:** After Phase 1.1 (LiveGameNotifier refactor), this screen should consume generic state. Replace direct `VolleyballStats` calls with `StatCalculator` or plugin delegation. Period label should come from `SportConfig.periodLabel`.

---

### 2.7 Per-Set Stats Widget *(NEW — missed in initial review)*

**File:** `lib/presentation/screens/stats/widgets/per_set_stats.dart` lines 17-26

Hard-coded volleyball stat rows:
```dart
(key: 'kills', label: 'K'),
(key: 'attackErrors', label: 'E'),
(key: 'totalAttacks', label: 'TA'),
(key: 'hittingPercentage', label: 'Hit%'),
(key: 'serviceAces', label: 'SA'),
(key: 'serviceErrors', label: 'SE'),
(key: 'digs', label: 'D'),
```

**Fix:** Read stat rows from `plugin.gameStatsColumns` — the plugin already defines these.

---

### 2.8 Game Detail Screen *(NEW — missed in initial review)*

**File:** `lib/presentation/screens/game_detail/game_detail_screen.dart`

Multiple volleyball coupling points:
- **Box score columns** (lines 510-540): Hard-coded K, E, TA, Hit%, A, SA, SE, D, BS, BA
- **Correction categories** (lines 1194-1215): Hard-coded `attack`/`serve`/`block`/`defense` event groups with action-to-result mappings (`'kill' → 'point_us'`, etc.)
- **Default event type** (line 1555): `_selectedEventType = 'kill'`
- **Serve indicator** in play-by-play (line 890)

**Fix:**
- Box score: Use `plugin.gameStatsColumns` for column definitions
- Correction categories: Add `Map<String, List<String>> get correctionCategories` and `Map<String, String> get eventResultMappings` to `SportPlugin`
- Default event: Use `plugin.quickModeEvents.first` or similar

---

### 2.9 Dashboard Screen *(NEW — missed in initial review)*

**File:** `lib/presentation/screens/dashboard/dashboard_screen.dart`

Volleyball coupling:
- **Kill leaderboard** (lines 583-634): Sorts by `statsTotals['kills']`, displays kill counts
- **Hitting % leaderboard** (lines 589-650): Sorts by `computedMetrics['hittingPercentage']`
- **Coach insights** (lines 514-532): "Top hitter hitting % dip check" — volleyball-specific analytics
- **Hardcoded text** (line 823): `'Kills, aces, digs, hitting % and more'`
- **Volleyball icons** (lines 708, 737): `Icons.sports_volleyball`

**Fix:** Add to `SportPlugin`:

```dart
List<DashboardLeaderboard> get dashboardLeaderboards;
// e.g., [DashboardLeaderboard(title: 'Top Hitters', statKey: 'kills', ...)]

List<CoachInsight> generateCoachInsights(List<PlayerSeasonStats> stats);

String get statsDescription; // 'Kills, aces, digs, hitting % and more'
```

Icon already handled by `sport_icon.dart`.

---

### 2.10 Player Form Screen *(NEW — missed in initial review)*

**File:** `lib/presentation/screens/teams/player_form_screen.dart` lines 34-41

Hard-coded positions:
```dart
static const _volleyballPositions = ['OH', 'MB', 'S', 'OPP', 'L', 'DS'];
```

Also auto-detects libero from position containing `'L'` (line ~245).

**Fix:** Add to `SportPlugin`:

```dart
List<String> get playerPositions;      // ['OH', 'MB', 'S', 'OPP', 'L', 'DS'] for volleyball
String? get specialRolePosition;       // 'L' for volleyball (triggers isLibero flag)
```

The form reads positions from the plugin based on the team's sport.

---

### 2.11 Roster Screen *(NEW — missed in initial review)*

**File:** `lib/presentation/screens/teams/roster_screen.dart` lines 179-196

Hard-coded "Libero" badge with volleyball-specific styling.

**Fix:** Generalize to show sport-specific role badges from plugin:

```dart
List<RoleBadge> get roleBadges;
// e.g., [RoleBadge(label: 'Libero', condition: (entry) => entry.isLibero)]
```

Or simpler: use `sportMetadata` on the roster entry + plugin to determine badge text.

---

### 2.12 Settings Screen *(NEW — missed in initial review)*

**File:** `lib/presentation/screens/settings/settings_screen.dart` lines 84-95

Hard-coded sport dropdown list.

**Fix:** Derive from `SportConfig.values` or `Sport` enum. Minor change.

---

### 2.13 Stats Table Widget

**File:** `lib/presentation/screens/stats/widgets/stats_table.dart` line 122

Special-cases `hittingPercentage` formatting (`.toStringAsFixed(3)`).

**Fix:** Add a `StatColumnFormat` enum to `StatColumn` (percentage, integer, decimal) so the table uses generic formatting. Minor.

---

### 2.14 Export Layer

**Files:** `csv_exporter.dart`, `pdf_exporter.dart`, `stats_email_formatter.dart`

All have `switch(sport)` with volleyball-only branches. No fallback for unknown sports.

**Fix:** Have the plugin provide export column definitions (reuse `gameStatsColumns`/`seasonStatsColumns`).

---

## Phase 3 — Database & DX Improvements

### 3.1 Sport-Specific Columns → JSON Metadata

**Tables affected:**
- `team_rosters.is_libero` → `sport_metadata TEXT DEFAULT '{}'`
- `game_lineups.batting_order` → move to `sport_metadata`
- `game_lineups.starting_rotation` → move to `sport_metadata`
- `substitutions.is_libero_replacement` → move to `sport_metadata`

**Migration:** Schema version 3. Add `sport_metadata` column, migrate existing boolean values into JSON, keep old columns temporarily for backward compatibility.

**Models affected:**
- `RosterEntry.isLibero` → derive from `sportMetadata['isLibero']` or keep as convenience getter
- `Substitution.isLiberoReplacement` → same

---

### 3.2 Replace DB Singleton with Riverpod DI

**File:** `lib/data/database/app_database.dart`

`AppDatabase.getInstance()` static singleton blocks test isolation.

**Fix:** Create a Riverpod provider:

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase(NativeDatabase.createInBackground(...));
});
```

Tests can override with `NativeDatabase.memory()`.

---

### 3.3 Enable Foreign Key Pragma

Schema declares `REFERENCES` but SQLite doesn't enforce without `PRAGMA foreign_keys = ON`.

**Fix:** Add `beforeOpen` callback:

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

---

### 3.4 Add Sport-Specific Indexes

Add indexes on frequently-queried sport columns:

```sql
CREATE INDEX IF NOT EXISTS idx_play_events_game_type ON play_events(game_id, event_type);
CREATE INDEX IF NOT EXISTS idx_player_game_stats_game ON player_game_stats(game_id, player_id);
CREATE INDEX IF NOT EXISTS idx_games_team_season ON games(team_id, season_id);
```

---

## Phase 4 — Future (Defer)

### 4.1 Migrate to Drift Table Classes

Currently the entire DB layer uses raw SQL strings (`customStatement`, `db.execute`, `db.query`). Migrating to Drift's type-safe table classes would give autocomplete, reactive `watch()` streams, and compile-time schema validation. This is a large effort (16-24h) and can be deferred.

### 4.2 Add JSON Schema Validation

Validate the stats JSON columns against sport-specific schemas to catch bad data early.

### 4.3 Empty `allTables` / `allSchemaEntities`

Drift features (migrations, schema validation, DevTools) are broken because tables are raw SQL. Drift doesn't know the schema exists. Fixing this requires Phase 4.1.

---

## Test Strategy

### Current Test Inventory

| File | Tests | Sport Coupling | Phase Impact |
|------|-------|---------------|--------------|
| `volleyball_plugin_test.dart` | ~30 | Volleyball (by design) | None — these stay as-is |
| `volleyball_stats_test.dart` | ~35 | Volleyball (by design) | None — these stay as-is |
| `live_game_providers_test.dart` | ~40+ | **EXTREME** — rotation R1-R6, sideouts, libero, serve tracking | **Phase 1.1** — must restructure |
| `game_detail_corrections_test.dart` | ~27 | Volleyball events/results | **Phase 2.8** — update when corrections become plugin-driven |
| `stat_calculator_test.dart` | ~11 | Volleyball leak at lines 84-91 | **Phase 1.2** — update delegation tests |
| `sport_config_test.dart` | ~37 | Generic ✅ | None |
| `stats_repository_corrections_test.dart` | ~7 | Generic ✅ | None |
| `widget_test.dart` | 1 | Generic ✅ | None |

### Test Principles

1. **Volleyball behavior must remain identical after refactor** — every existing volleyball test should still pass (possibly moved to a volleyball-specific test file)
2. **New shared code gets sport-agnostic tests** — use a `FakeSportPlugin` / `TestSportPlugin` to verify the generic pipeline without volleyball coupling
3. **Each phase updates/adds tests before or alongside the refactor** (not after)

### Phase 1 Test Changes

#### 1.1 — LiveGameNotifier Refactor

**Restructure `live_game_providers_test.dart`:**

Split into two files:
- `live_game_providers_test.dart` — Tests for generic `LiveGameNotifier` behavior (event recording, undo, period tracking, score keeping, roster management). Uses a `FakeSportGameEngine`.
- `volleyball_live_game_test.dart` — Tests for volleyball-specific behavior (rotation, sideout, libero, serve tracking, set-based winning). Uses `VolleyballGameEngine`.

**New tests to add:**
- `SportGameEngine` contract test — verifies any implementation handles the basic lifecycle: `onEventRecorded`, `onPeriodAdvanced`, `determineWinner`, `canSubstitute`, `validateEvent`
- Test that `LiveGameNotifier` correctly delegates to `SportGameEngine` and doesn't contain sport logic

**Create `FakeSportGameEngine`:**

```dart
/// test/helpers/fake_sport_game_engine.dart
class FakeSportGameEngine implements SportGameEngine {
  final List<PlayEvent> recordedEvents = [];
  Map<String, dynamic> _state = {};

  @override
  Map<String, dynamic> get sportState => _state;

  @override
  Map<String, dynamic> onEventRecorded(PlayEvent event, LiveGameState state) {
    recordedEvents.add(event);
    return _state;
  }

  @override
  Map<String, dynamic> onPeriodAdvanced(int newPeriod, LiveGameState state) => _state;

  @override
  String determineWinner(LiveGameState state) {
    final us = state.scores.values.fold(0, (sum, s) => sum + s.us);
    final them = state.scores.values.fold(0, (sum, s) => sum + s.them);
    return us > them ? 'us' : (them > us ? 'them' : 'tie');
  }

  @override
  bool canSubstitute(LiveGameState state) => true;

  @override
  String? validateEvent(PlayEvent event, LiveGameState state) => null;
}
```

#### 1.2 — StatCalculator Fix

**Update `stat_calculator_test.dart`:**
- Remove tests that verify volleyball-specific `hittingPercentage` computation in `StatCalculator`
- Add tests that verify `StatCalculator` delegates `computeSeasonMetrics()` to the plugin
- Keep tests for generic aggregation logic

#### 1.3 — GameSummaryService

**New file: `test/domain/stats/game_summary_service_test.dart`:**
- Test that `GameSummaryService` dispatches to the correct plugin
- Test with `FakeSportPlugin` that returns a canned `GameSummary`
- Move existing volleyball MVP/top-performer logic tests to `test/domain/sports/volleyball/volleyball_summary_test.dart`

### Phase 2 Test Changes

#### 2.7–2.9 — Stats Widgets & Screens

**New file: `test/presentation/screens/stats/stats_screens_test.dart`:**
- Test that stats screens read columns/filters from the plugin (not hard-coded)
- Use `FakeSportPlugin` with custom column definitions to verify dynamic rendering
- Widget tests for `PerSetStats`, `StatsTable`, `LeaderboardScreen` with non-volleyball data

#### 2.8 — Game Detail Corrections

**Update `game_detail_corrections_test.dart`:**
- Once correction categories come from the plugin, update tests to verify plugin-driven categories
- Add test with `FakeSportPlugin` that defines different correction categories

#### 2.10 — Player Form

**New test: `test/presentation/screens/teams/player_form_test.dart`:**
- Verify positions dropdown reads from plugin
- Verify sport-specific role detection (libero for volleyball, DH for softball, etc.)

### Phase 3 Test Changes

#### 3.2 — DB DI Refactor

**Update all test files:**
- Replace `AppDatabase.getInstance()` calls with provider overrides
- Use `NativeDatabase.memory()` for test isolation
- This enables proper integration tests with real SQL

**New file: `test/data/database/migration_test.dart`:**
- Test schema version 2 → 3 migration (sport_metadata columns)
- Verify existing data migrates correctly (e.g., `is_libero = true` → `sport_metadata = '{"isLibero": true}'`)

#### 3.3 — Foreign Keys

**New test in migration_test.dart:**
- Verify `PRAGMA foreign_keys = ON` is active after DB open
- Test that invalid foreign key references are rejected

### New Test Helpers

Create `test/helpers/` directory with reusable test utilities:

```
test/helpers/
  fake_sport_plugin.dart       # Generic FakeSportPlugin for testing shared code
  fake_sport_game_engine.dart  # Generic FakeSportGameEngine for LiveGameNotifier tests
  test_database.dart           # Helper to create in-memory test databases
  sample_data.dart             # Factory methods for test Game, Player, Event objects
```

**`FakeSportPlugin`:**

```dart
class FakeSportPlugin implements SportPlugin {
  final String sportName;
  final List<EventCategory> _eventCategories;
  final List<StatColumn> _columns;

  FakeSportPlugin({
    this.sportName = 'test_sport',
    List<EventCategory>? eventCategories,
    List<StatColumn>? columns,
  }) : _eventCategories = eventCategories ?? _defaultCategories,
       _columns = columns ?? _defaultColumns;

  // ... implement all SportPlugin methods with configurable test data
}
```

### Test Summary by Phase

| Phase | Existing Tests to Update | New Tests to Add |
|-------|------------------------|-----------------|
| 1.1 | `live_game_providers_test.dart` → split into generic + volleyball | `SportGameEngine` contract tests, `FakeSportGameEngine` |
| 1.2 | `stat_calculator_test.dart` → delegation tests | — |
| 1.3 | — | `game_summary_service_test.dart`, volleyball summary tests |
| 1.4 | — | Action palette widget test with fake plugin |
| 2.x | `game_detail_corrections_test.dart` | Stats widget tests, player form test, dashboard test |
| 3.2 | All test files (DI swap) | `migration_test.dart` |
| 3.3 | — | FK enforcement test |

---

## Dependency Graph

```
Phase 1.1 (LiveGameNotifier)
  ├── Phase 1.4 (ActionPalette) — depends on plugin wiring
  ├── Phase 2.1 (Scoreboard) — depends on sport state extraction
  ├── Phase 2.2 (Live Game Widgets) — depends on sport state extraction
  └── Phase 2.6 (Live Game Screen) — depends on all Phase 1

Phase 1.2 (StatCalculator) — independent
Phase 1.3 (GameSummaryService) — independent
Phase 1.5 (DAO/Repo consolidation) — independent

Phase 2.3 (Season Stats) ← depends on SportPlugin additions from Phase 1
Phase 2.4 (Leaderboard) ← depends on SportPlugin additions
Phase 2.5 (Player Detail) ← depends on SportPlugin additions
Phase 2.7 (Per-Set Stats) ← depends on plugin column definitions
Phase 2.8 (Game Detail) ← depends on plugin correction categories
Phase 2.9 (Dashboard) ← depends on plugin leaderboard/insights config
Phase 2.10 (Player Form) ← depends on plugin positions
Phase 2.11 (Roster Screen) ← depends on plugin role badges
Phase 2.12 (Settings) — independent (minor)
Phase 2.13 (Stats Table) — independent (minor)
Phase 2.14 (Export) ← depends on plugin column definitions

Phase 3.x — all independent of Phase 1-2 (can be parallelized)
```

### Recommended Execution Order

1. **Phase 1.2** (StatCalculator fix — smallest, quick win)
2. **Phase 1.3** (GameSummaryService → plugin)
3. **Phase 1.1** (LiveGameNotifier — largest, most impactful)
4. **Phase 1.4** (ActionPalette)
5. **Phase 1.5** (DAO/Repo consolidation)
6. **Phase 2.10, 2.11, 2.12** (Teams screens — small, low-risk)
7. **Phase 2.3, 2.4, 2.5** (Stats screens)
8. **Phase 2.7, 2.8, 2.13** (Stats widgets)
9. **Phase 2.9** (Dashboard)
10. **Phase 2.1, 2.2, 2.6** (Live game UI)
11. **Phase 2.14** (Export)
12. **Phase 3.1–3.4** (Database improvements)

---

## Validation Checklist

After completing all phases, verify:

- [ ] `flutter analyze` — zero warnings/errors
- [ ] `flutter test` — all tests pass (existing + new)
- [ ] Volleyball behavior is identical — no regressions in game play, stats, export
- [ ] `SportPlugin` is the ONLY place sport-specific logic lives (outside `domain/sports/{sport}/`)
- [ ] No file outside `domain/sports/volleyball/` imports from volleyball directly
- [ ] A new `FakeSportPlugin` can go through the entire pipeline: create team → add players → start game → record events → view stats → export
- [ ] `build_runner` generates cleanly after any Drift/Riverpod changes
- [ ] `flutter build web --release --no-tree-shake-icons` succeeds

---

## Files Index

Complete list of files requiring changes, organized by phase:

### Phase 1 (Core)
| File | Change | Lines |
|------|--------|-------|
| `lib/presentation/providers/live_game_providers.dart` | Extract sport state → `SportGameEngine` | ~497 |
| `lib/domain/stats/stat_calculator.dart` | Remove volleyball leak (lines 84-91) | ~105 |
| `lib/domain/stats/game_summary_service.dart` | Delegate to plugin | ~171 |
| `lib/presentation/screens/live_game/widgets/action_palette.dart` | Read from plugin | — |
| `lib/data/repositories/*.dart` + `lib/data/database/daos/*.dart` | Consolidate | — |

### Phase 2 (UI)
| File | Change | Lines |
|------|--------|-------|
| `lib/presentation/screens/live_game/widgets/scoreboard_widget.dart` | Sport-configurable | — |
| `lib/presentation/screens/live_game/widgets/court_lineup_panel.dart` | Conditional per sport | — |
| `lib/presentation/screens/live_game/widgets/rotation_indicator.dart` | Conditional per sport | — |
| `lib/presentation/screens/live_game/widgets/lineup_setup_sheet.dart` | Conditional per sport | — |
| `lib/presentation/screens/stats/season_stats_screen.dart` | Plugin columns/filters | — |
| `lib/presentation/screens/stats/leaderboard_screen.dart` | Plugin categories | — |
| `lib/presentation/screens/stats/player_detail_screen.dart` | Plugin columns/trends | — |
| `lib/presentation/screens/live_game/live_game_screen.dart` | Remove volleyball imports | — |
| `lib/presentation/screens/stats/widgets/per_set_stats.dart` | Plugin stat rows | ~130 |
| `lib/presentation/screens/game_detail/game_detail_screen.dart` | Plugin columns/corrections | ~1660 |
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | Plugin leaderboards/insights | ~830 |
| `lib/presentation/screens/teams/player_form_screen.dart` | Plugin positions | ~300 |
| `lib/presentation/screens/teams/roster_screen.dart` | Plugin role badges | ~220 |
| `lib/presentation/screens/settings/settings_screen.dart` | Derive from Sport enum | — |
| `lib/presentation/screens/stats/widgets/stats_table.dart` | Generic stat formatting | — |
| `lib/domain/stats/csv_exporter.dart` | Plugin column definitions | — |
| `lib/domain/stats/pdf_exporter.dart` | Plugin column definitions | — |
| `lib/domain/stats/stats_email_formatter.dart` | Plugin column definitions | — |

### Phase 3 (Database)
| File | Change | Lines |
|------|--------|-------|
| `lib/data/database/app_database.dart` | Migration v3, DI, FK pragma, indexes | ~277 |
| `lib/domain/models/roster_entry.dart` | `sportMetadata` field | — |
| `lib/domain/models/substitution.dart` | `sportMetadata` field | — |

### New Files to Create
| File | Purpose |
|------|---------|
| `lib/domain/sports/sport_game_engine.dart` | Abstract game engine interface |
| `lib/domain/sports/volleyball/volleyball_game_engine.dart` | Volleyball implementation |
| `lib/domain/models/game_summary.dart` | Generic game summary model |
| `test/helpers/fake_sport_plugin.dart` | Test helper |
| `test/helpers/fake_sport_game_engine.dart` | Test helper |
| `test/helpers/test_database.dart` | In-memory DB helper |
| `test/helpers/sample_data.dart` | Test data factories |
| `test/domain/stats/game_summary_service_test.dart` | Summary service tests |
| `test/presentation/screens/stats/stats_screens_test.dart` | Stats UI tests |
| `test/presentation/screens/teams/player_form_test.dart` | Player form tests |
| `test/data/database/migration_test.dart` | DB migration tests |

### SportPlugin Additions Summary

New methods/getters to add to the `SportPlugin` interface:

```dart
// Phase 1.1
SportGameEngine createGameEngine();

// Phase 1.3
GameSummary generateGameSummary(List<PlayEvent> events, List<PlayerStats> stats);

// Phase 2.3
List<StatFilter> get statFilters;
String get defaultSortStat;

// Phase 2.4
List<LeaderboardCategory> get leaderboardCategories;

// Phase 2.5
List<TrendMetric> get trendMetrics;

// Phase 2.8
Map<String, List<String>> get correctionCategories;
Map<String, String> get eventResultMappings;

// Phase 2.9
List<DashboardLeaderboard> get dashboardLeaderboards;
List<CoachInsight> generateCoachInsights(List<PlayerSeasonStats> stats);
String get statsDescription;

// Phase 2.10
List<String> get playerPositions;
String? get specialRolePosition;

// Phase 2.11
List<RoleBadge> get roleBadges;

// Phase 2.13
StatColumnFormat (enum on StatColumn)
```