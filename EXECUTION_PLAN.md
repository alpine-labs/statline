# StatLine — Expert-Informed Execution Plan

## Problem Statement

The app has a solid Phase 1 foundation (teams, rosters, seasons, live game entry, stat calculations) but several critical gaps prevent it from being usable as a real product:

1. **Game stats are not persisted** — events are recorded but never aggregated to PlayerGameStats/PlayerSeasonStats on game end
2. **Player detail screens use mock data** — game log and charts show hardcoded fake data
3. **Dashboard is too thin** — only shows season record, recent games, top 3 leaders. Team creation prompt should move to Teams tab.
4. **Missing key volleyball features** — no rotation tracking, timeout tracking, substitution counter, or libero handling
5. **No export or sharing** — PNG/PDF/CSV stubs only
6. **No score flow or trend analysis** — high-value differentiators from competitors

## Dashboard Redesign Decision

**Current state**: Dashboard shows season record, recent games, team leaders, and a "Create Team" prompt when no team exists.

**Expert recommendation**: Transform into a "Coach's Command Center":
- **Remove** "Create Team" from dashboard → move to Teams tab with first-run onboarding
- **Add** "Start Game" hero card with next scheduled game info
- **Add** Team Trends Alert card (auto-generated insights like "Serve errors up 40% over last 3 games")
- **Add** Last Game Box Score card (shareable)
- **Add** Sparkline mini-charts next to team leaders
- **Keep** Season record bar (add streak tracking)
- **Future**: Upcoming schedule, season milestones, practice focus suggestions

---

## Sprint Plan

### SPRINT 1 — Critical Path (Stats Pipeline)
*Everything downstream depends on this being right.*

| ID | Task | Description |
|----|------|-------------|
| `stats-aggregation` | Stats aggregation pipeline | Build `StatsAggregationService` that runs on game completion: query non-deleted PlayEvents, call sport plugin's `computeGameStats()`, upsert PlayerGameStats rows, recompute PlayerSeasonStats. Must be idempotent and re-triggerable for stat corrections. |
| `sets-played-tracking` | Sets played per player | When computing game stats, count distinct period_ids where the player has ≥1 event. Store as `sets_played` in PlayerGameStats.stats. Critical for accurate per-set metrics for substitutes. |
| `real-game-log` | Real game log data | Replace mock data in Player Detail "Game Log" tab. Query PlayerGameStats joined with Game table. Show actual per-game stats. |
| `real-chart-data` | Real chart data | Replace mock data in Player Detail "Charts" tab. Pull from PlayerGameStats for per-game line/bar charts (hitting % trend, kills per game). |
| `hitting-pct-display` | Hitting % edge case | Show "---" (not "0.000" or NaN) when attack attempts = 0. Zero attempts ≠ zero hitting %. |

### SPRINT 2 — Dashboard & Live Game UX
*Makes it feel like a real product.*

| ID | Task | Description |
|----|------|-------------|
| `dashboard-redesign` | Dashboard redesign | Remove "Create Team" prompt (move to Teams tab with onboarding). Add: "Start Game" hero card, last game box score card, season record with streak tracking. Restructure layout as Coach's Command Center. |
| `dashboard-trends` | Dashboard trends card | Auto-generated insight sentences comparing last 3 games vs. season average. Flag metrics with >15% negative delta. E.g., "Serve errors up 40%", "Side-out % dropped from 65% to 52%". |
| `timeout-tracking` | Timeout tracking | Add Our TO / Their TO buttons to scoreboard area. Track count per set (max 2 standard). Visual indicator of remaining timeouts. |
| `sub-counter` | Substitution counter | Display "Subs: 8/15" (NCAA) or "Subs: 8/12" (NFHS) counter per set. Configurable limit. Prevents illegal substitutions. |
| `rotation-indicator` | Rotation indicator (basic) | 6-position circle/semicircle showing who's in each position. Auto-rotate on side-out. Manual override available. |
| `reorder-quick-actions` | Reorder Quick Mode actions | Change from Kill,Error,Ace,SrvErr,Block,Dig,Assist,OppErr → Kill,Error,Dig,Assist,Block,Ace,SrvErr,OppErr (frequency-based ordering). |
| `perfect-pass-pct` | Perfect pass % metric | Add (pass_3_count / total_receptions) * 100 to stats. College coaches specifically request this separate from avg pass rating. |
| `serve-efficiency` | Serve efficiency metric | Add (aces - serve_errors) / serve_attempts. Parallel to hitting % for serving. |

### SPRINT 3 — Visualizations & Sharing
*Growth features and competitive differentiators.*

| ID | Task | Description |
|----|------|-------------|
| `score-flow-chart` | Score flow chart | Point-by-point score progression within a set. X-axis = rally number, Y-axis = score differential. Already have score_us_after/score_them_after on PlayEvent. Annotate timeouts. **Key differentiator** — GameChanger/MaxPreps don't do this at consumer level. |
| `png-export` | PNG box score export | Styled, branded box score card as PNG image. Shareable to social media/text. Use screenshot + share_plus. |
| `radar-chart` | Radar chart player profiles | Spider chart with K/S, D/S, A/S, B/S, Ace/S, Pass Avg — normalized to team average. Highly shareable. Players/parents love these. |
| `leaderboard-screen` | Leaderboard screen | Top players by stat category. Sortable, filterable. Drives competitive motivation. |
| `player-stat-peek` | Long-press player stat peek | During live game, long-press player grid button → popup with current game stats (8K, 2E, 18TA, .333). No navigation required. |
| `per-set-breakdown` | Per-set stat breakdown | For a single game, show stats broken out by set. Answers "why did we lose set 3?" |
| `opponent-hitting-pct` | Opponent hitting % | Track opponent attack attempts/kills/errors for team defensive metric. |

### SPRINT 4 — Polish & Export
*Rounding out the MVP.*

| ID | Task | Description |
|----|------|-------------|
| `csv-export` | CSV data export | Export games, player stats, play-by-play as CSV files. |
| `pdf-reports` | PDF game reports | Game summary with box score, set scores, team totals. |
| `action-grouping` | Detailed mode action grouping | Group 20 buttons by category with dividers/headers: ATTACK | SERVE | BLOCK | DIG/PASS | SET | OPP. Color-code backgrounds. |
| `last-action-badge` | Player last-action badge | After recording, show small icon on player grid button (tiny "K" badge) that fades after 3s. Visual confirmation. |
| `sparkline-leaders` | Dashboard sparkline leaders | Add tiny sparkline mini-charts next to team leader names showing last 5 game trends. |
| `libero-basic` | Basic libero handling | Mark libero player, manual "Libero In/Out" button that swaps with back-row player. Don't over-engineer. |
| `game-summary-object` | Game summary generation | On game end, generate structured GameSummary: final score, set scores, MVP, top per category, notable stats (double-digit kills, 0-error games). Powers dashboard + sharing. |

---

## Key Expert Insights (Reference)

### Metrics to Add
- **Perfect pass %**: (pass_3_count / total_receptions) × 100
- **Serve efficiency**: (aces - serve_errors) / serve_attempts
- **Kills per set**, **Errors per set**, **Attack attempts per set** — display prominently
- **Assist-to-kill ratio**: assists / team_kills (setter quality)
- Side-out % by rotation (requires rotation tracking)
- First-ball side-out % (advanced, later)

### Competitive Differentiators
1. **Score flow chart** — no consumer-level competitor does this well
2. **Dashboard trend alerts** — automated insight generation, makes app feel intelligent
3. **Shareable radar charts** — viral growth through social sharing
4. **Long-press stat peek** — reduces friction during live games

### Architecture Notes
- Stats aggregation must be **idempotent** (re-runnable for corrections)
- Store `sets_played` per player per game (count distinct periods with events)
- Score flow data already exists in PlayEvent (score_us_after, score_them_after)
- Trend calculations: compare last N games avg vs. season avg, flag >15% delta
- Consider 0-4 pass rating scale as a setting option (some programs use it)

---

## Decisions (Resolved)
- **Dashboard**: Start minimal — don't over-engineer. Start Game hero, last game card, season record w/ streaks, team leaders. Add trends card later once aggregation is solid.
- **Quick+ Mode**: No. Quick (8 buttons) and Detailed (20 buttons) is sufficient.
- **Pass rating scale**: 0-3 only. Keep it simple.
- **Substitution limit**: Configurable per team (NCAA 15 / NFHS 12 / custom).
- **Target audience**: Youth, high school, & rec. Avoid complexity. Keep UX fast and approachable.
