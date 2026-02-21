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

## Team Level Field — Expert Recommendations

*Source: sports-stats-designer agent review, Feb 2026.*

### Current State
The `level` field (Club, High School, College, Recreation) is stored in the DB and shown as a subtitle label on the teams list. It has **zero behavioral impact** on the app today.

### Option Set Fix (do now)
Add **Youth** to the level enum — it's the most rules-sensitive level and covers the core target audience (youth baseball, youth basketball, club volleyball, flag football). The revised enum:

| Value | Notes |
|---|---|
| `Youth` | ➕ Add — Under ~14; Little League, U12/U14 club, flag football |
| `High School` | ✅ Keep |
| `College` | ✅ Keep |
| `Club` | ✅ Keep (rename to "Club / Travel" optional) |
| `Recreation` | ✅ Keep |

### Behavioral Impact by Sport

Level should graduate from a cosmetic label to a **configuration preset engine**: it sets smart defaults per game/match, but every default is overridable.

#### 🏐 Volleyball (live — act now)
- Wire level → match format defaults when starting a game/match:
  - Youth/Rec → best-of-3, sets to 21
  - HS/College → best-of-5, sets to 25 (5th to 15)
- Substitution limit default: NCAA = 15, NFHS = 12, Youth/Rec = custom

#### ⚾ Baseball (Phase 2 — highest priority level-driven feature)
- Pitch count tracking with rest-day warnings is a **player safety issue** at Youth and HS levels.
- Youth (Little League): 85-pitch daily limit (13-16 yr), mandatory rest tiers
- High School: varies by state (~105/wk), display running count with color warning (yellow at 75%, red at limit)
- Mercy/run rule: Youth (10-run after 4 inn), HS (10-run after 5 inn) — app offers to end game
- Inning count default: Youth = 6, HS/College = 9

#### 🏀 Basketball (Phase 2)
- Period structure default from level:
  - Youth → 4 × 8-min quarters
  - HS (NFHS) → 4 × 8-min quarters
  - College Men → 2 × 20-min halves
  - College Women → 4 × 10-min quarters
- Period structure changes how stats are segmented — wire early

#### 🏈 Football (Phase 2)
- Quarter length default: Youth = 8–10 min, HS = 12 min, College = 15 min
- Running clock (mercy rule): default ON for Youth, per-game toggle for others

#### 🥎 Slowpitch Softball (Phase 2)
- Skip level-driven rules — variance is per-league, not per-level
- Add per-game league rule toggles instead: run limit per inning, HR cap before outs rule

### Sprint Placement

| Task ID | Sprint | Description |
|---|---|---|
| `level-youth-option` | Sprint 2 | Add `Youth` to the level dropdown in both Add Team and Edit Team forms (teams_screen.dart + edit_team_screen.dart). One-line change. |
| `level-volleyball-defaults` | Sprint 2 | When starting a match, pre-populate format (best-of, set score) based on team level. Overridable per game. |
| `level-baseball-pitchcount` | Phase 2 / Baseball sprint | Level-aware pitch count panel with color warnings and rest-day calculator for Youth and HS. |
| `level-basketball-periods` | Phase 2 / Basketball sprint | Default period structure (halves vs quarters, duration) from team level. |
| `level-football-clock` | Phase 2 / Football sprint | Default quarter duration and running-clock mercy rule from team level. |
| `level-softball-toggles` | Phase 2 / Softball sprint | Per-game league rule toggles (run limit, HR cap) — not level-driven. |

---

## Volleyball Expert Review — Sports Stats Designer

*Source: sports-stats-designer agent review, Feb 2026.*

### What's Working Well

- **Stat coverage is solid.** Hitting %, pass rating (0-3), perfect pass %, serve efficiency, points formula — these are the right core metrics. Most competitors miss at least one of these.
- **Quick Mode action selection is well-chosen.** The 8-action set (Kill, Error, Dig, Assist, Block, Ace, SrvErr, OppErr) covers ~85% of rally-ending actions. Good for single-scorekeeper coaches.
- **Detailed Mode has real depth.** Pass 3/2/1/0 grading, block assists, zero attacks, set errors — this is what separates a serious tool from a toy.
- **Libero tracking exists.** Manual In/Out is the right approach — don't automate this.
- **Level-aware match format defaults are in place.** Youth/Rec → best-of-3/21, HS/College/Club → best-of-5/25 with override.
- **Offline-first architecture.** Essential for gyms with poor connectivity.

### Gaps & Recommended Changes

#### PRIORITY 1 — High-impact coaching features (do next)

| ID | Change | Why It Matters | Size |
|----|--------|----------------|------|
| `vb-side-out-display` | Display side-out % on scoreboard and in game stats | Side-out % is THE #1 team-level metric in competitive volleyball. Formula already exists in `volleyball_stats.dart` but is never shown. Coaches check this every set transition. | Small |
| `vb-rotation-on-events` | Store `currentRotation` on every PlayEvent | Without rotation stored per-event, you can never compute stats-by-rotation, which is the single highest-value coaching analysis in volleyball ("we leak points in rotation 3"). Already tracking rotation in state — just write it to each event. | Small |
| `vb-pass-0-split` | Split "Pass 0 (Overpass/Shank)" into two separate events: "Pass 0 (Shank)" and "Overpass" | An overpass results in a free ball or kill for the opponent — it's functionally a reception error. A shank (zero) stays on your side. Conflating them gives misleading pass ratings. | Small |
| `vb-sub-limit-by-level` | Default substitution limit from team level: NCAA → 15, NFHS → 12, Youth/Rec → 18 (unlimited effectively) | The sub counter already exists but is hardcoded to 15. A HS coach will see "Subs: 12/15" and think they have 3 left when they don't. | Small |
| `vb-first-ball-sideout` | Track first-ball side-out: side-out scored on the first attack after reception (pass → set → kill, no rally) | Distinguishes clean offensive execution from grinding out a rally. Coaches use this to evaluate serve-receive offense independent of defense. | Medium |

#### PRIORITY 2 — Live game UX improvements

| ID | Change | Why It Matters | Size |
|----|--------|----------------|------|
| `vb-auto-rotate` | Auto-advance rotation on side-out (when your team wins a rally on opponent's serve) | Manual-only rotation is error-prone under game pressure. Auto-rotate on side-out, manual override stays available. This is how every serious stat tool works. | Medium |
| `vb-serve-tracking` | When recording an Ace or Serve Error, auto-identify the server based on rotation position (position 1 = server) | Eliminates one tap per serve event. If the app knows the lineup and current rotation, the server is always the player in position 1. Reduces entry time by ~15%. | Medium |
| `vb-score-flow-priority` | Prioritize the score flow chart (already planned as `score-flow-chart` in Sprint 3) | This is the #1 competitive differentiator. No consumer app does it. Score flow with timeout annotations answers "when did we lose momentum?" which is the question coaches ask most. Move it up. | Large |
| `vb-player-stat-peek` | Long-press player button during live game → popup with current game stats (already planned as `player-stat-peek` in Sprint 3) | During timeouts, coaches need instant access to "how's she hitting?" without leaving the live entry screen. This is the difference between a stat tool and a coaching tool. Move it up. | Medium |

#### PRIORITY 3 — Stats display & analysis

| ID | Change | Why It Matters | Size |
|----|--------|----------------|------|
| `vb-rotation-stats` | Stats-by-rotation analysis screen: show hitting %, side-out %, points scored/lost per rotation | Requires `vb-rotation-on-events` first. This is the most requested analysis feature from competitive coaches. "Show me which rotation is bleeding points." | Large |
| `vb-per-set-stats` | Per-set stat breakdown for a single game (already planned as `per-set-breakdown` in Sprint 3) | Answers "why did we lose set 3?" — coaches ask this after every loss. | Medium |
| `vb-assist-to-kill` | Display assist-to-kill ratio on setter's player detail (assists / team_kills) | Measures setter quality relative to team offense. | Small |
| `vb-reception-filter` | Add "Passing" filter chip to season stats table (columns: GP, Receptions, Pass Rating, PP%, Reception Errors) | Passing stats exist in the data but are buried — no dedicated view. Serve-receive is 50% of the game and deserves its own filter. | Small |

### Things to NOT Do

- **Don't add a 0-4 pass rating scale option.** The 0-3 scale is standard and simpler. The 0-4 scale is used by a minority of college programs and adds confusion for your target audience (youth/HS/club).
- **Don't auto-track digs.** Some apps try to infer digs from rally context — this is unreliable and frustrating. Manual entry is correct.
- **Don't build rotation-based lineup management** (drag-and-drop court view with 6 slots). It's a massive time sink, coaches don't use it live, and it adds complexity that slows down entry. The simple R1-R6 indicator + auto-rotate is the right approach.
- **Don't add touch zones / heat maps for attacks.** This requires a second input (where on the court) for every attack, which doubles entry time and isn't feasible for a single scorekeeper. It's a college analytics team feature, not a coaching tool feature.
- **Don't implement real-time cloud sync during games.** Offline-first is correct. Sync after game end is fine. Mid-game sync adds latency and failure modes that will cause stat loss.

### Sprint Placement

| Sprint | Tasks |
|--------|-------|
| **Immediate (next sprint)** | `vb-side-out-display`, `vb-rotation-on-events`, `vb-pass-0-split`, `vb-sub-limit-by-level`, `vb-reception-filter` |
| **Sprint 3 (move up)** | `vb-auto-rotate`, `vb-serve-tracking`, `vb-player-stat-peek`, `vb-first-ball-sideout`, `vb-score-flow-priority` |
| **Sprint 4** | `vb-rotation-stats`, `vb-per-set-stats`, `vb-assist-to-kill` |

---

## Decisions (Resolved)
- **Dashboard**: Start minimal — don't over-engineer. Start Game hero, last game card, season record w/ streaks, team leaders. Add trends card later once aggregation is solid.
- **Quick+ Mode**: No. Quick (8 buttons) and Detailed (20 buttons) is sufficient.
- **Pass rating scale**: 0-3 only. Keep it simple.
- **Substitution limit**: Configurable per team (NCAA 15 / NFHS 12 / custom).
- **Target audience**: Youth, high school, & rec. Avoid complexity. Keep UX fast and approachable.
