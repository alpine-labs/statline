# StatLine — Multi-Sport Stats Tracker — Design Plan

## Overview

**StatLine** is a cross-platform (iOS, Android, Web) sports stat-tracking app that lets coaches, stat keepers, and players record play-by-play stats during live games and track ongoing metrics across games and seasons with tables and charts.

**Target Audience:** All levels from recreational to college — the UI offers both a quick mode for casual use and a detailed mode for serious analysis.

**Supported Sports (in rollout order):**
1. Volleyball (MVP)
2. Basketball
3. Slowpitch Softball
4. Baseball
5. Football

**Approach:** Build volleyball first and nail it, then expand to other sports using a shared data model with sport-specific plugins.

---

## Tech Stack

| Layer | Technology | Rationale |
|---|---|---|
| **Framework** | Flutter 3.x | Single codebase for iOS, Android, Web. Compiled rendering (Skia/Impeller) for sub-100ms tap response during live stat entry. |
| **Language** | Dart | Strong typing, null safety, async/await, great tooling |
| **State Management** | Riverpod 2.x | Type-safe, testable, supports code generation |
| **Local Database** | Drift (SQLite) | Offline-first, strongly-typed SQL, reactive queries, migration support |
| **Cloud Backend** | Supabase | PostgreSQL + Auth + Realtime + Storage. Generous free tier. |
| **Navigation** | GoRouter | Declarative, deep-link support, web-friendly URLs |
| **Charts** | fl_chart | High-performance Flutter-native charting (line, bar, pie, radar) |
| **Design System** | Material 3 + custom sport theme | M3 foundations for structure, custom sporty brand layer |
| **Feature Flags** | Local config (expandable to remote) | Future monetization gating without architectural rework |
| **Image Export** | screenshot + share_plus | Generate shareable box score images |
| **PDF Export** | pdf package | Generate professional game/season reports |
| **Connectivity** | connectivity_plus | Detect network status for sync queue processing |
| **Testing** | flutter_test + integration_test + mocktail | Unit, widget, and integration testing |

---

## App Structure — Navigation

### Bottom Navigation (5 Tabs)

#### Tab 1: 🏠 Dashboard
- Active season summary: team record (W-L), recent games
- Quick-start: "New Game" button (prominent)
- Upcoming scheduled games
- Team leaderboard snapshot (top 3 in key stats)
- Last game highlights card

#### Tab 2: 🏐 Live Game (contextual — active during a game)
- **Scoreboard**: Always visible at top (us vs. them, set/inning/quarter scores)
- **Quick/Detailed mode toggle** (persistent setting)
- **Player grid/list**: Tap player → action palette
- **Action palette**: Sport-specific actions (kill, error, ace, block, dig, etc.)
- **Undo button**: Always visible, prominent
- **Rotation/lineup indicator**: Current rotation (volleyball), batting order (baseball), lineup (basketball)
- **Game clock/period indicator**: Current set, quarter, inning
- **Substitution flow**: Quick in/out with libero handling (volleyball)

#### Tab 3: 📊 Stats & Metrics
- **Season stats table**: Sortable columns per stat category
- **Player detail view**: Individual stat breakdown, game log
- **Leaderboards**: Top performers by category
- **Basic charts**: Line charts (trend over games), bar charts (comparisons)
- **Filters**: By season, by game, by date range
- **Opponent head-to-head view**: Record and stats vs. specific opponents

#### Tab 4: 👥 Teams & Rosters
- **Team management**: Create/edit teams, set sport, level, gender
- **Roster management**: Add/edit players (name, number, position, photo)
- **Season management**: Create seasons, set active season
- **Game schedule**: List of games (past with results, future scheduled)
- **Multi-team support**: Switch between teams

#### Tab 5: ⚙️ Settings
- Profile / account
- App preferences (theme, default mode, notifications)
- Data export (CSV, PDF)
- Cloud sync settings
- Feature flags / premium features (future)
- About / help

---

## Live Stat Entry — Dual Mode Design

### Quick Mode (Recreational / Fast-Paced)
**Flow: 2-3 taps per event**
```
[Player Button] → [Action Button] → Auto-recorded
                                     ↓
                    Score auto-updates, undo available
```
- Player grid shows all active players with jersey numbers
- Action palette shows only the most common actions:
  - Volleyball: Kill, Error, Ace, Serve Error, Block, Dig
- Result is inferred (e.g., Kill = point for us, Error = point for them)
- No metadata captured (rotation, shot type, etc.)

### Detailed Mode (Competitive / Coaching)
**Flow: 3-4 taps per event**
```
[Player Button] → [Action Category] → [Specific Result] → [Optional Metadata]
                                                            ↓
                                             Rotation, assist credit, quality rating
```
- Full action palette with sub-categories:
  - Volleyball Attack: Kill, Error, Blocked (→ who blocked?), Zero Attack
  - Volleyball Serve: Ace, Error (→ type: net/out/foot), In-play
  - Volleyball Pass: Rating 0-3, Error
- Optional metadata: rotation number, assist credit, pass quality
- Opponent stat tracking: simplified opponent action buttons

### Shared UX Principles (Both Modes)
- **Undo**: Single-tap undo with 3-second auto-dismiss toast. Undo stack (last 10 actions).
- **Scoreboard**: Always pinned at top, never scrolls away
- **Haptic feedback**: Subtle vibration on stat recording (mobile)
- **Landscape support**: Optional landscape mode for tablets
- **Keep screen awake**: Prevent auto-lock during live games

---

## Data Model (Drift / SQLite)

### Core Entities (Shared Across All Sports)

```
── Organization & Teams ──────────────────────────────────────

Organization
  - id (TEXT PK, UUID)
  - name (TEXT)
  - logo_uri (TEXT, nullable)
  - created_at (INTEGER, epoch ms)
  - updated_at (INTEGER, epoch ms)

Team
  - id (TEXT PK, UUID)
  - organization_id (TEXT FK, nullable)
  - name (TEXT)
  - sport (TEXT: 'volleyball' | 'baseball' | 'slowpitch' | 'basketball' | 'football')
  - level (TEXT: 'recreational' | 'high_school' | 'club' | 'travel' | 'college' | 'adult_league')
  - gender (TEXT: 'mens' | 'womens' | 'coed')
  - age_group (TEXT, nullable — e.g., "14U", "Varsity")
  - logo_uri (TEXT, nullable)
  - created_at (INTEGER)
  - updated_at (INTEGER)

Season
  - id (TEXT PK, UUID)
  - team_id (TEXT FK)
  - name (TEXT — e.g., "Spring 2026")
  - start_date (TEXT, ISO 8601)
  - end_date (TEXT, ISO 8601, nullable)
  - is_active (INTEGER, boolean)
  - created_at (INTEGER)
  - updated_at (INTEGER)

Player
  - id (TEXT PK, UUID)
  - first_name (TEXT)
  - last_name (TEXT)
  - jersey_number (TEXT — TEXT to support "00", "0", etc.)
  - positions (TEXT, JSON array — sport-specific)
  - photo_uri (TEXT, nullable)
  - is_active (INTEGER, boolean)
  - created_at (INTEGER)
  - updated_at (INTEGER)

TeamRoster
  - id (TEXT PK, UUID)
  - team_id (TEXT FK)
  - player_id (TEXT FK)
  - season_id (TEXT FK)
  - jersey_number (TEXT — can vary by season)
  - role (TEXT: 'starter' | 'reserve' | 'captain' | 'injured')
  - is_libero (INTEGER, boolean — volleyball-specific but useful in shared table)
  - joined_date (TEXT)

── Game Structure ─────────────────────────────────────────────

Game
  - id (TEXT PK, UUID)
  - season_id (TEXT FK)
  - team_id (TEXT FK)
  - opponent_name (TEXT)
  - opponent_team_id (TEXT FK, nullable)
  - game_date (TEXT, ISO 8601)
  - location (TEXT, nullable)
  - is_home (INTEGER, boolean)
  - sport (TEXT — denormalized for fast queries)
  - game_format (TEXT, JSON — sport-specific config)
  - status (TEXT: 'scheduled' | 'in_progress' | 'completed' | 'canceled')
  - final_score_us (INTEGER, nullable)
  - final_score_them (INTEGER, nullable)
  - result (TEXT: 'win' | 'loss' | 'tie' | null)
  - notes (TEXT, nullable)
  - entry_mode (TEXT: 'quick' | 'detailed')
  - created_at (INTEGER)
  - updated_at (INTEGER)

GamePeriod
  - id (TEXT PK, UUID)
  - game_id (TEXT FK)
  - period_number (INTEGER)
  - period_type (TEXT: 'set' | 'inning_top' | 'inning_bottom' | 'quarter' | 'half' | 'overtime')
  - score_us (INTEGER)
  - score_them (INTEGER)

GameLineup
  - id (TEXT PK, UUID)
  - game_id (TEXT FK)
  - player_id (TEXT FK)
  - batting_order (INTEGER, nullable)
  - position (TEXT)
  - starting_rotation (INTEGER, nullable — volleyball rotation 1-6)
  - is_starter (INTEGER, boolean)
  - status (TEXT: 'active' | 'subbed_out' | 'ejected')

Substitution
  - id (TEXT PK, UUID)
  - game_id (TEXT FK)
  - period_id (TEXT FK)
  - player_in_id (TEXT FK)
  - player_out_id (TEXT FK)
  - game_clock (TEXT, nullable)
  - is_libero_replacement (INTEGER, boolean)

── Play-by-Play ──────────────────────────────────────────────

PlayEvent
  - id (TEXT PK, UUID)
  - game_id (TEXT FK)
  - period_id (TEXT FK)
  - sequence_number (INTEGER)
  - timestamp (INTEGER, epoch ms)
  - game_clock (TEXT, nullable)
  - player_id (TEXT FK)
  - secondary_player_id (TEXT FK, nullable — assist, blocker, etc.)
  - event_category (TEXT — e.g., 'attack', 'serve', 'block', 'dig', 'pass', 'set')
  - event_type (TEXT — e.g., 'kill', 'error', 'ace', 'block_solo', 'block_assist')
  - result (TEXT — e.g., 'point_us', 'point_them', 'rally_continues')
  - score_us_after (INTEGER)
  - score_them_after (INTEGER)
  - is_opponent (INTEGER, boolean — flag for opponent events)
  - notes (TEXT, nullable)
  - metadata (TEXT, JSON — sport-specific: rotation, pass quality, shot location, etc.)
  - is_deleted (INTEGER, boolean — soft delete for undo)
  - created_at (INTEGER)

── Stat Aggregation ──────────────────────────────────────────

PlayerGameStats
  - id (TEXT PK, UUID)
  - game_id (TEXT FK)
  - player_id (TEXT FK)
  - sport (TEXT)
  - stats (TEXT, JSON — sport-specific stat totals)
  - computed_at (INTEGER)

PlayerSeasonStats
  - id (TEXT PK, UUID)
  - season_id (TEXT FK)
  - player_id (TEXT FK)
  - sport (TEXT)
  - games_played (INTEGER)
  - stats_totals (TEXT, JSON)
  - stats_averages (TEXT, JSON)
  - computed_metrics (TEXT, JSON — e.g., hitting %, side-out %, OPS, TS%)
  - computed_at (INTEGER)

── Sync Queue ────────────────────────────────────────────────

SyncQueue
  - id (INTEGER PK, auto-increment)
  - table_name (TEXT)
  - record_id (TEXT)
  - operation (TEXT: 'insert' | 'update' | 'delete')
  - payload (TEXT, JSON)
  - created_at (INTEGER)
  - synced_at (INTEGER, nullable)
  - retry_count (INTEGER, default 0)
  - error (TEXT, nullable)

── Feature Flags ─────────────────────────────────────────────

FeatureFlag
  - key (TEXT PK — e.g., 'advanced_charts', 'cloud_sync', 'multi_team')
  - enabled (INTEGER, boolean)
  - tier (TEXT: 'free' | 'premium' | 'pro' — for future monetization)
```

### Volleyball-Specific Stats JSON Examples

**PlayerGameStats.stats for volleyball:**
```json
{
  "kills": 12,
  "attack_errors": 3,
  "attack_attempts": 28,
  "hitting_pct": 0.321,
  "aces": 3,
  "serve_errors": 1,
  "serve_attempts": 15,
  "digs": 8,
  "dig_errors": 2,
  "block_solos": 1,
  "block_assists": 3,
  "total_blocks": 4,
  "block_errors": 0,
  "assists": 2,
  "setting_errors": 0,
  "reception_attempts": 10,
  "reception_errors": 1,
  "pass_rating_total": 22,
  "pass_rating_avg": 2.20,
  "ball_handling_errors": 0,
  "points": 16
}
```

**PlayerSeasonStats.computed_metrics for volleyball:**
```json
{
  "hitting_pct": 0.287,
  "kills_per_set": 3.4,
  "aces_per_set": 0.8,
  "digs_per_set": 2.5,
  "blocks_per_set": 1.2,
  "assists_per_set": 0.6,
  "pass_rating_avg": 2.15,
  "serve_error_pct": 0.08,
  "points_per_set": 4.2,
  "side_out_pct": 0.62
}
```

---

## Volleyball MVP — Event Categories & Types

| Category | Event Types | Quick Mode? | Result |
|----------|------------|-------------|--------|
| **Attack** | Kill | ✅ | point_us |
| | Attack Error | ✅ | point_them |
| | Attack Blocked | ❌ (detailed) | point_them |
| | Zero Attack (kept in play) | ❌ (detailed) | rally_continues |
| **Serve** | Ace | ✅ | point_us |
| | Serve Error | ✅ | point_them |
| | Serve In Play | ❌ (detailed) | rally_continues |
| **Block** | Block Solo | ✅ (as "Block") | point_us |
| | Block Assist | ❌ (detailed) | point_us |
| | Block Error | ❌ (detailed) | point_them |
| **Dig** | Dig | ✅ | rally_continues |
| | Dig Error | ❌ (detailed) | rally_continues |
| **Pass/Reception** | Pass (with quality 0-3) | ❌ (detailed) | rally_continues |
| | Reception Error | ❌ (detailed) | point_them |
| **Set** | Assist | ✅ | rally_continues |
| | Setting Error | ❌ (detailed) | point_them |
| **Opponent** | Opp Kill | ❌ (detailed) | point_them |
| | Opp Error | ✅ | point_us |
| | Opp Attack Attempt | ❌ (detailed) | rally_continues |

---

## Season Stats & Metrics Display

### Tables (MVP)
- **Team season stats table**: All players as rows, key stats as sortable columns
  - Volleyball columns: GP, Sets, K, E, TA, Hit%, A, SA, SE, Digs, BS, BA, TB, Pts
- **Player game log**: Each game as a row with stats for that game
- **Opponent stats table**: Opponent name, result, their key stats
- **Leaderboards**: Top 5 in each stat category

### Charts (MVP — Basic)
- **Line chart**: Hitting % over games (per player or team)
- **Bar chart**: Kills/Errors/Attempts per game
- **Line chart**: Aces per game trend
- **Bar chart**: Player comparison (select 2-3 players, compare stats side-by-side)

### Charts (Post-MVP)
- Radar/spider chart: Player profile (kills/set, digs/set, aces/set, blocks/set, pass avg)
- Heat map: Points by rotation
- Rolling average lines (5-game window)
- Scatter plot: Kills vs. Errors (efficiency profile)

---

## Offline-First Architecture

1. **SQLite (via Drift) is the single source of truth.** All reads and writes go to local DB. Zero network dependency for core functionality.
2. **Sync queue table** buffers all changes when offline. Processes automatically when connectivity returns.
3. **Pre-cache game data**: Before a game starts, ensure full roster/season/settings are local.
4. **Connectivity monitoring**: `connectivity_plus` package detects network state changes and triggers sync.
5. **Sync indicators**: Small icon (✓ synced, ↻ pending, ✕ error) in the UI.
6. **Conflict resolution**: Last-write-wins with timestamps. Only one scorer per game, so conflicts are rare.

---

## Export & Sharing

| Format | Content | Priority |
|--------|---------|----------|
| **PNG Image** | Styled box score card (shareable to social media/text) | MVP |
| **PDF Report** | Game summary with box score, scoring by set, team totals | MVP |
| **CSV** | Raw stat export (games, player stats, play-by-play) | MVP |
| **Shareable Link** | Cloud-hosted game summary page | Post-MVP |

---

## Visual Design

### Theme: Custom Sporty + Material 3 Foundations
- **Material 3**: Navigation, inputs, cards, dialogs, bottom sheets
- **Custom brand layer**:
  - Dark mode primary (game mode): Dark backgrounds reduce sideline glare
  - Bold accent colors per sport (e.g., volleyball = energetic orange, basketball = deep blue)
  - Athletic typography: Bold headers, condensed stat numbers
  - Stat highlighting: Animated counters, color-coded performance (green = good, red = below average)
- **Scoreboard design**: High-contrast, large numerals, always visible
- **Player buttons**: Large touch targets (56x56dp+), jersey number prominent, foul/stat badges

### Color Palette (Dark Game Mode)
- Background: #121212 (Material Dark)
- Surface: #1E1E1E
- Primary accent: #FF6B35 (energetic orange — volleyball)
- Secondary: #00B4D8 (teal)
- Point scored: #4CAF50 (green flash)
- Error/point lost: #EF5350 (red flash)
- Text primary: #FFFFFF
- Text secondary: #B0B0B0

### Light Mode (non-game screens)
- Background: #FAFAFA
- Surface: #FFFFFF
- Same accent colors, adjusted for contrast

---

## Project Structure

```
statline/
├── lib/
│   ├── main.dart
│   ├── app.dart                        # App root, theme, router
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart          # Material 3 + custom sport theme
│   │   │   ├── colors.dart             # Color constants per sport
│   │   │   └── typography.dart         # Athletic typography
│   │   ├── constants/
│   │   │   └── sport_config.dart       # Sport-specific configurations
│   │   ├── utils/
│   │   │   ├── uuid.dart
│   │   │   └── date_utils.dart
│   │   └── feature_flags/
│   │       └── feature_flags.dart      # Feature flag system
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart       # Drift database definition
│   │   │   ├── tables/                 # Drift table definitions
│   │   │   │   ├── teams.dart
│   │   │   │   ├── players.dart
│   │   │   │   ├── seasons.dart
│   │   │   │   ├── games.dart
│   │   │   │   ├── game_periods.dart
│   │   │   │   ├── game_lineups.dart
│   │   │   │   ├── play_events.dart
│   │   │   │   ├── player_game_stats.dart
│   │   │   │   ├── player_season_stats.dart
│   │   │   │   ├── sync_queue.dart
│   │   │   │   └── feature_flags.dart
│   │   │   ├── daos/                   # Data access objects
│   │   │   │   ├── team_dao.dart
│   │   │   │   ├── game_dao.dart
│   │   │   │   ├── stats_dao.dart
│   │   │   │   └── sync_dao.dart
│   │   │   └── migrations/
│   │   ├── repositories/              # Repository pattern (abstracts DB)
│   │   │   ├── team_repository.dart
│   │   │   ├── game_repository.dart
│   │   │   ├── stats_repository.dart
│   │   │   └── sync_repository.dart
│   │   └── sync/
│   │       ├── sync_service.dart       # Supabase sync logic
│   │       └── sync_queue_processor.dart
│   ├── domain/
│   │   ├── models/                     # Domain models (not DB models)
│   │   │   ├── team.dart
│   │   │   ├── player.dart
│   │   │   ├── game.dart
│   │   │   ├── play_event.dart
│   │   │   └── stats.dart
│   │   ├── sports/                     # Sport-specific logic plugins
│   │   │   ├── sport_plugin.dart       # Abstract interface
│   │   │   ├── volleyball/
│   │   │   │   ├── volleyball_plugin.dart
│   │   │   │   ├── volleyball_events.dart
│   │   │   │   ├── volleyball_stats.dart
│   │   │   │   └── volleyball_rules.dart  # Rotation logic, set scoring, libero rules
│   │   │   ├── basketball/             # Phase 2
│   │   │   ├── slowpitch/              # Phase 3
│   │   │   ├── baseball/               # Phase 4
│   │   │   └── football/               # Phase 5
│   │   └── stats/
│   │       ├── stat_calculator.dart    # Aggregation engine
│   │       └── metric_definitions.dart # Per-sport metric formulas
│   ├── presentation/
│   │   ├── router/
│   │   │   └── app_router.dart         # GoRouter config
│   │   ├── providers/                  # Riverpod providers
│   │   │   ├── team_providers.dart
│   │   │   ├── game_providers.dart
│   │   │   ├── live_game_providers.dart
│   │   │   └── stats_providers.dart
│   │   ├── screens/
│   │   │   ├── dashboard/
│   │   │   │   └── dashboard_screen.dart
│   │   │   ├── live_game/
│   │   │   │   ├── live_game_screen.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── scoreboard_widget.dart
│   │   │   │   │   ├── player_grid.dart
│   │   │   │   │   ├── action_palette.dart
│   │   │   │   │   ├── undo_bar.dart
│   │   │   │   │   ├── rotation_indicator.dart
│   │   │   │   │   └── mode_toggle.dart
│   │   │   │   └── controllers/
│   │   │   │       └── live_game_controller.dart
│   │   │   ├── stats/
│   │   │   │   ├── season_stats_screen.dart
│   │   │   │   ├── player_detail_screen.dart
│   │   │   │   ├── leaderboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── stats_table.dart
│   │   │   │       ├── line_chart_widget.dart
│   │   │   │       └── bar_chart_widget.dart
│   │   │   ├── teams/
│   │   │   │   ├── teams_screen.dart
│   │   │   │   ├── roster_screen.dart
│   │   │   │   ├── player_form_screen.dart
│   │   │   │   └── season_screen.dart
│   │   │   └── settings/
│   │   │       └── settings_screen.dart
│   │   └── widgets/                    # Shared UI components
│   │       ├── stat_card.dart
│   │       ├── sport_icon.dart
│   │       └── export_button.dart
│   └── export/
│       ├── image_exporter.dart         # PNG box score generation
│       ├── pdf_exporter.dart           # PDF report generation
│       └── csv_exporter.dart           # CSV data export
├── test/
│   ├── unit/
│   │   ├── stats/
│   │   │   └── volleyball_stats_test.dart
│   │   └── domain/
│   │       └── volleyball_rules_test.dart
│   ├── widget/
│   │   ├── scoreboard_test.dart
│   │   └── action_palette_test.dart
│   └── integration/
│       └── live_game_flow_test.dart
├── assets/
│   ├── images/
│   │   └── sport_icons/
│   └── fonts/
├── pubspec.yaml
└── README.md
```

---

## Sport Plugin Architecture

Each sport implements a `SportPlugin` interface:

```dart
abstract class SportPlugin {
  String get sportId;           // 'volleyball', 'basketball', etc.
  String get displayName;
  
  // Event definitions
  List<EventCategory> get eventCategories;
  List<EventCategory> get quickModeEvents;  // Subset for quick mode
  
  // Game format
  GameFormatConfig get defaultGameFormat;
  
  // Stat calculations
  Map<String, dynamic> computeGameStats(List<PlayEvent> events);
  Map<String, dynamic> computeSeasonMetrics(List<Map<String, dynamic>> gameStats);
  
  // Table column definitions
  List<StatColumn> get gameStatsColumns;
  List<StatColumn> get seasonStatsColumns;
  
  // Validation
  bool isGameOver(Game game, List<GamePeriod> periods);
  
  // Period management
  String periodLabel(GamePeriod period);  // "Set 1", "Q1", "Top 3rd"
}
```

This allows adding new sports without modifying core app logic.

---

## Implementation Phases

### Phase 1 — Foundation & Volleyball MVP
- [ ] Initialize Flutter project with Dart
- [ ] Set up project structure (core, data, domain, presentation)
- [ ] Configure Drift database with full schema
- [ ] Build Material 3 + custom sport theme (dark game mode + light mode)
- [ ] Set up GoRouter navigation (bottom tabs)
- [ ] Build Team & Roster management screens (CRUD)
- [ ] Build Season management
- [ ] Build Game creation screen
- [ ] Implement SportPlugin interface
- [ ] Implement VolleyballPlugin (events, stats, rules)
- [ ] Build Live Game screen — scoreboard + player grid + action palette
- [ ] Implement Quick Mode stat entry (2-3 taps)
- [ ] Implement Detailed Mode stat entry (3-4 taps + metadata)
- [ ] Implement undo/redo system
- [ ] Implement rotation tracking (volleyball)
- [ ] Implement libero substitution handling
- [ ] Build play-by-play log view (scrollable, editable)
- [ ] Auto-compute PlayerGameStats on game completion
- [ ] Build Dashboard screen
- [ ] Build Season Stats table (sortable)
- [ ] Build Player Detail screen with game log
- [ ] Build basic leaderboards
- [ ] Implement basic line/bar charts (hitting %, kills per game)
- [ ] Feature flags system (local config)
- [ ] Keep-screen-awake during live games

### Phase 2 — Export & Polish
- [ ] PNG box score image export (shareable card)
- [ ] PDF game report generation
- [ ] CSV data export (games, player stats, play-by-play)
- [ ] Set-by-set score breakdown display
- [ ] Opponent stat tracking (basic)
- [ ] Head-to-head opponent records
- [ ] Post-game stat correction/editing
- [ ] Haptic feedback on stat entry (mobile)
- [ ] Dark/light mode toggle
- [ ] Accessibility audit

### Phase 3 — Cloud Sync
- [ ] Supabase project setup (PostgreSQL schema mirroring local)
- [ ] User authentication (email/password)
- [ ] Sync queue processor (local → cloud)
- [ ] Pull sync (cloud → local for multi-device)
- [ ] Sync status indicators in UI
- [ ] Offline-first testing & edge cases

### Phase 4 — Basketball
- [ ] Implement BasketballPlugin
- [ ] Basketball-specific live entry (shot type, 2pt/3pt, fouls, rebounds)
- [ ] Basketball stat calculations (FG%, TS%, eFG%, AST/TO)
- [ ] Basketball game format (configurable quarters, foul limits)
- [ ] Foul trouble badges on player buttons
- [ ] Team foul / bonus tracking

### Phase 5 — Slowpitch Softball
- [ ] Implement SlowpitchPlugin
- [ ] Batting-focused entry (hit type, location)
- [ ] HR limit tracking & warnings
- [ ] Simplified pitching stats
- [ ] AVG/OBP/SLG/OPS calculations
- [ ] Flexible roster/lineup sizes (10-16)
- [ ] Run-rule detection

### Phase 6 — Baseball
- [ ] Implement BaseballPlugin (extends slowpitch with additions)
- [ ] Pitch count tracking (prominent display)
- [ ] Stolen base / caught stealing
- [ ] Earned vs. unearned run tracking
- [ ] Full pitching stats (ERA, WHIP, K/9, K/BB)
- [ ] DH rule support
- [ ] At-bat vs. plate appearance distinction
- [ ] Inning context (top/bottom)

### Phase 7 — Football
- [ ] Implement FootballPlugin
- [ ] Down & distance auto-advancement
- [ ] Play-by-play entry (play type → result → yards)
- [ ] Passing/rushing/receiving stat tracking
- [ ] Defensive stats (tackles, sacks, INTs)
- [ ] Special teams (punts, kicks, returns)
- [ ] Penalty handling
- [ ] Drive summary grouping
- [ ] Passer rating calculation
- [ ] Configurable game format (HS/college/flag)

### Phase 8 — Advanced Features (Post-MVP)
- [ ] Shot charts / spray charts / field diagrams
- [ ] Radar/spider chart player profiles
- [ ] Player comparison tools
- [ ] Advanced metrics (wOBA, PER, QBR, etc.)
- [ ] Live game sharing (read-only link)
- [ ] Role-based team access (coach, stat keeper, viewer)
- [ ] Season-over-season comparison
- [ ] Auto-detected milestones / awards
- [ ] Video timestamp tagging

---

## Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^14.0.0
  
  # Database
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.0
  
  # Backend
  supabase_flutter: ^2.3.0
  
  # Charts
  fl_chart: ^0.68.0
  
  # UI
  material_design_icons_flutter: ^7.0.0
  
  # Utilities
  uuid: ^4.3.0
  connectivity_plus: ^6.0.0
  share_plus: ^9.0.0
  wakelock_plus: ^1.2.0
  
  # Export
  pdf: ^3.10.0
  screenshot: ^3.0.0
  csv: ^6.0.0
  path_provider: ^2.1.0
  
  # Haptics
  vibration: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.16.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
```

---

## Expert Recommendations Incorporated

The sports stats expert provided key insights that shaped this design:

1. **"Nail one sport first"** → Volleyball MVP, then expand via plugin architecture
2. **"3 taps max per rally"** → Quick mode with 2-3 taps, detailed mode for 3-4
3. **"Undo is essential"** → Prominent undo button with 10-action stack
4. **"Track opponent stats"** → Basic opponent tracking included in MVP
5. **"Rotation tracking is foundational"** → Built into volleyball data model
6. **"Libero handling is special"** → Dedicated libero substitution flow
7. **"Offline-first is non-negotiable"** → SQLite as source of truth, sync queue pattern
8. **"Quick/detailed modes serve different audiences"** → Dual-mode toggle serves rec through college
9. **"Side-out % is the single best team metric"** → Included in computed metrics
10. **"Export as image for social sharing"** → PNG box score card as MVP export

---

## Open Questions / Future Considerations

- Should we support multiple stat keepers for the same game (real-time collaboration)?
- Tablet-optimized layout with side-by-side panels (lineup + stat entry)?
- Integration with MaxPreps / GameChanger for import/export?
- Apple Watch companion for quick stat entry from the wrist?
- AI-assisted stat suggestions (e.g., "That looked like a block assist, confirm?")?
- Barcode scanning for player IDs / equipment tracking?
- Tournament bracket management?
- Practice stat tracking (separate from game stats)?

