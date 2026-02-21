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

## Post-Game Stat Corrections — Design & Plan

*Source: sports-stats-designer agent review, Feb 2026.*

### 1. Should Post-Game Corrections Be Implemented?

**Yes — unequivocally.** This is not a nice-to-have; it is a prerequisite for the app being trusted with real game data. Here's why:

- **Single-scorekeeper reality.** There is no second person verifying entries during live play. Every competitive stat system that relies on a single operator provides a correction workflow. Without it, coaches will stop using the tool the first time they see stats they know are wrong but can't fix.
- **Tournament cadence creates delayed discovery.** A coach running 5 games on Saturday won't review stats until Sunday or Monday. The "undo last action" window is long closed. The only path to accurate records is post-game editing.
- **The data layer already supports it.** `PlayEvent` is soft-deleted (never hard-deleted), `StatsAggregationService` is idempotent and filters deleted events, `copyWith` exists on the model, and the repository has raw SQL access. The plumbing is 80% done — the missing piece is the UI and the edit/insert operations.
- **Trust drives adoption.** Coaches share stats with parents, players, and recruiting contacts. If the numbers can't be corrected, coaches won't share them. If they won't share, they won't use the app.
- **Undo-only is insufficient.** You can delete a wrong event but you can't change a "Kill" to a "Zero Attack" — you'd have to delete the original, then somehow insert a replacement at the right sequence position with correct scores. That workflow doesn't exist today.

**Risk of NOT building it:** The app becomes a novelty that coaches try once and abandon because they can't fix inevitable errors.

---

### 2. Complete UX/UI Design for the Correction Workflow

#### 2A. Entry Points (Two Paths to Corrections)

**Path 1 — Game Detail Screen (primary)**
- **Where:** Tap any completed game from the Dashboard "Recent Games" list, the Player Detail "Game Log" tab, or the Season Stats screen.
- **Screen:** A new **Game Detail Screen** (`/games/:gameId`) — this screen is also needed independently as a game review/box-score screen. It shows: final score, set scores, box score table, and a **"Play-by-Play" tab**.
- **Button:** Inside the Play-by-Play tab, a **"Correction Mode" toggle** in the app bar (pencil icon). Tapping it enters correction mode. No confirmation dialog — it's a mode toggle, not a destructive action.

**Path 2 — Quick access from Dashboard**
- **Where:** On the "Last Game" card on the Dashboard, add a small **"Review"** text button (not prominent — it's secondary to "Share"). This deep-links to the Game Detail Screen's Play-by-Play tab.

**Why not "Re-open game"?** The game status stays `completed`. Corrections don't change game status. There's no "re-open" concept — you're editing the event record, not resuming live play. This avoids the confused state of a game being "in progress" when it's really just being reviewed.

#### 2B. Game Detail Screen Layout (New Screen)

**Route:** `/games/:gameId`

**Two tabs:**

| Tab | Contents |
|-----|----------|
| **Box Score** | Final score, set scores, per-player stat table (K, E, TA, H%, A, D, BS, BA, SA, SE, RE, Pts). Same layout coaches expect from MaxPreps/GameChanger. |
| **Play-by-Play** | Chronological event list grouped by set. This is where corrections happen. |

**Box Score tab** is the default view. This screen has standalone value even without corrections — it's the missing "game detail" that coaches need to review any completed game.

#### 2C. Play-by-Play Review Screen (The Correction Surface)

**Layout (vertical, full-screen on phone):**

```
┌──────────────────────────────────────────┐
│ [←] Game vs. Opponent    [✏️ Edit Mode]  │  ← App bar with correction toggle
├──────────────────────────────────────────┤
│ Set 1 (25-20)                        ▼   │  ← Collapsible set headers
├──────────────────────────────────────────┤
│ #1  │ 1-0  │ Smith    │ Ace        │ ▸  │  ← Event row
│ #2  │ 1-1  │ (Opp)   │ Kill       │ ▸  │
│ #3  │ 2-1  │ Jones   │ Kill       │ ▸  │
│ #4  │ 2-1  │ Adams   │ Dig        │    │  ← rally_continues (no score change)
│ #5  │ 3-1  │ Lee     │ Block Solo │ ▸  │
│ ...                                      │
├──────────────────────────────────────────┤
│ Set 2 (25-22)                        ▼   │
├──────────────────────────────────────────┤
│ ...                                      │
└──────────────────────────────────────────┘
```

**Columns per event row:**
| Column | Width | Content |
|--------|-------|---------|
| **Seq** | 36px | `#1`, `#2`, etc. — sequence number within the set |
| **Score** | 48px | `1-0`, `2-1` — score after this event (us-them) |
| **Player** | flex | Player last name (or "(Opp)" for opponent events) |
| **Action** | flex | Human-readable: "Kill", "Serve Error", "Pass 3", "Block Assist" |
| **Chevron** | 24px | `▸` indicates tappable in correction mode |

**Visual treatment:**
- Rows alternate with subtle grey/white banding for scanability.
- Score-changing events (point_us, point_them) have a colored left-edge indicator: green for us, red for them.
- Deleted events are shown in correction mode only: struck-through text, 40% opacity, with a red "Deleted" chip.
- Rally-continues events (dig, pass, zero_attack, serve_in_play) have no score-change indicator and no chevron in normal mode.
- Set headers show set score and are collapsible (default expanded for most recent set).

**Scrolling:** Standard `ListView.builder` with set headers as sticky/sliver headers. For a typical 5-set match (~150-250 events), this is trivially performant. No pagination needed.

**Normal mode (Edit Mode OFF):** Read-only. Tapping a row does nothing. The screen is purely for review.

**Correction mode (Edit Mode ON):** Tapping a row opens the Event Detail Bottom Sheet (see 2D below). A floating action button appears at bottom-right: **"+ Add Event"** for inserting missing events.

#### 2D. Editing an Individual Event (Change Type, Player, Result)

**Trigger:** Tap any event row while in Correction Mode.

**UI:** Bottom sheet (not a new screen — stays in context of the play-by-play list).

```
┌──────────────────────────────────────────┐
│         Edit Event #14                   │
├──────────────────────────────────────────┤
│ Player      [▼ Smith, J.            ]    │  ← Dropdown of roster players
│ Category    [▼ Attack               ]    │  ← Dropdown: Attack/Serve/Block/etc.
│ Action      [▼ Kill                 ]    │  ← Filtered by category
│ Result      [  point_us     ] (auto)     │  ← Auto-set from action, read-only
│ Opponent?   [ ] (toggle)                 │
│                                          │
│ [Delete Event]           [Save Changes]  │
│                                          │
│ ── History ──                            │
│ Created: Jan 15, 2:14 PM                 │
│ Edited: Jan 16, 9:30 AM — Changed       │
│   action from "Zero Attack" to "Kill"    │
└──────────────────────────────────────────┘
```

**Field behavior:**
- **Player dropdown:** Shows all players on the roster for this game. Current player pre-selected.
- **Category dropdown:** Attack, Serve, Block, Dig, Pass, Set, Opponent. Current category pre-selected.
- **Action dropdown:** Filters to valid event types for the selected category (e.g., selecting "Attack" shows Kill, Attack Error, Blocked, Zero Attack). This reuses the existing `VolleyballPlugin.getEventTypes()` data.
- **Result:** Auto-determined from the action (Kill → point_us, Attack Error → point_them, Dig → rally_continues). Read-only — the user picks the action, not the result. This prevents invalid combinations.
- **Opponent toggle:** Marks event as opponent action. When toggled, player dropdown is disabled.

**Save behavior:**
1. The original `PlayEvent` is soft-deleted (`is_deleted = true`).
2. A new `PlayEvent` is inserted with the corrected values, same `sequenceNumber` and `periodId`, new `id` and `createdAt`.
3. The new event's `metadata` stores a correction reference: `{"corrects": "<original_event_id>", "correctedAt": "<ISO timestamp>", "correctionReason": "edit"}`.
4. Scores are NOT manually adjusted at this point — they are recalculated in bulk (see 2G).

**Why soft-delete + new insert instead of UPDATE?** This preserves the complete audit trail. The original event still exists with `is_deleted = true`. The replacement event links back to it via metadata. Both are visible in the audit trail. This pattern is already established by the undo system.

#### 2E. Deleting an Event

**Trigger:** Tap "Delete Event" button in the Edit Event bottom sheet, OR swipe-left on an event row in correction mode.

**Confirmation:** A single inline confirmation — the "Delete Event" button turns red and text changes to "Confirm Delete" for 3 seconds, then reverts. One-tap to initiate, second tap to confirm. No dialog popup (too slow for batch corrections).

**Behavior:**
1. Sets `is_deleted = true` on the event.
2. Stores correction metadata: `{"deletedAt": "<ISO timestamp>", "correctionReason": "delete"}`.
3. The row visually strikes through and fades to 40% opacity. It remains visible in correction mode but disappears from normal view.
4. Scores recalculated on exiting correction mode (see 2G).

#### 2F. Adding a Missing Event (Insert at Correct Position)

**Trigger:** FAB "**+ Add Event**" button visible in correction mode, OR long-press between two event rows to insert at that position.

**UI:** Same bottom sheet as Edit, but titled "Add Event" with all fields blank.

**Additional field: Insert Position.**
- Default: "End of Set [current set]" — appends after the last event in the currently-viewed set.
- Alternative: "After Event #N" — dropdown showing nearby events for context. If triggered via long-press between rows, this is pre-filled.
- The user does NOT need to manually set sequence numbers. The system auto-assigns the sequence number by inserting between the surrounding events (e.g., between seq 14 and 15, the new event gets 14.5, then all events are re-sequenced as integers on save).

**Behavior:**
1. New `PlayEvent` is created with a new `id`, the correct `periodId`, and a `sequenceNumber` that places it at the chosen position.
2. Metadata: `{"insertedAt": "<ISO timestamp>", "correctionReason": "insert"}`.
3. All subsequent events in the set have their `sequenceNumber` values shifted up by 1 to maintain ordering.
4. Scores recalculated on exiting correction mode (see 2G).

**Constraint:** You can only add events within an existing set. You cannot add a new set or change set boundaries. This is intentional — set structure is established during live play and shouldn't be editable post-game.

#### 2G. Score Recalculation & Re-Aggregation

**When:** Triggered automatically when the user exits Correction Mode (toggles the edit pencil OFF).

**What happens (in order):**

1. **Score recalculation within the game:**
   - Walk all active (non-deleted) events in sequence order, per set.
   - Reset running score to 0-0 at each set boundary.
   - For each event: if `result == 'point_us'`, increment our score. If `result == 'point_them'`, increment their score. If `rally_continues`, score unchanged.
   - Write the recalculated `scoreUsAfter` and `scoreThemAfter` back to each event.
   - Update the `GamePeriod` set scores.
   - Update the `Game` final set scores (`finalScoreUs`, `finalScoreThem`) and re-derive `result` (win/loss).

2. **Re-aggregate player game stats:**
   - Call `StatsAggregationService.aggregateGameStats()` — it's already idempotent and filters deleted events. This is a direct re-run of the existing pipeline.

3. **Re-aggregate season stats:**
   - Already handled inside `aggregateGameStats()` — it recomputes season stats for all affected players.

**UI feedback:** A brief loading indicator ("Recalculating stats...") overlays the screen during re-aggregation. For a typical game (~200 events), this takes <500ms on any modern phone. After completion, the play-by-play list refreshes with corrected scores, and the Box Score tab shows updated stats.

**Why not recalculate per-edit?** Batch recalculation on mode-exit is simpler, faster, and avoids confusing intermediate score states while the user is making multiple corrections. A coach correcting "she had 12 kills, not 10" will add 2 events — they want to see the final result, not two intermediate recalculations.

#### 2H. Audit Trail

**What's tracked per correction:**
| Field | Stored In | Value |
|-------|-----------|-------|
| Original event (preserved) | `play_events` table | `is_deleted = true`, all original values intact |
| Correction type | New event's `metadata.correctionReason` | `"edit"`, `"delete"`, or `"insert"` |
| Link to original | New event's `metadata.corrects` | Original event ID (for edits) |
| Correction timestamp | New event's `metadata.correctedAt` / `metadata.insertedAt` / `metadata.deletedAt` | ISO 8601 |

**How it's displayed:**
- In the Edit Event bottom sheet (2D above), a "History" section at the bottom shows the correction chain for that event: created timestamp, each edit with what changed, deletion if applicable.
- In normal (non-correction) mode, corrected events look identical to original events — no visual noise. The audit trail is only visible inside correction mode when you tap an event.
- **No separate "audit log" screen.** The audit trail is inline, per-event. A dedicated audit screen is overkill for this audience (see Section 3).

**Storage:** All audit data lives in the existing `metadata` JSON column on `PlayEvent`. No new tables, no new columns. The correction metadata keys (`corrects`, `correctedAt`, `correctionReason`) are reserved keys in the metadata map.

#### 2I. Mobile UX Considerations

| Concern | Design Decision |
|---------|-----------------|
| **Fat fingers in noisy gyms** | Correction mode is a deliberate toggle — you can't accidentally edit. Event rows have 56px min height (Material touch target). |
| **Batch corrections** | Coach stays in correction mode across multiple edits. No re-authentication or repeated mode entry. Score recalculates once on exit. |
| **Context preservation** | Bottom sheet (not full-screen navigation) for edits — the play-by-play list stays visible behind the sheet. Coach doesn't lose their place. |
| **Offline** | All correction operations are local SQLite writes. No network required. Corrections work on the bus ride home from a tournament. |
| **Discoverability** | The pencil icon in the app bar is standard for "edit mode." First-time tooltip: "Tap to correct stats." No onboarding flow needed. |
| **Speed** | Swipe-to-delete for fast deletions. Bottom sheet with dropdowns (not free-text) for edits. Category → Action cascading dropdowns prevent invalid entries. |
| **Undo corrections** | If a correction was wrong, the coach edits again — another soft-delete + new insert. The audit trail preserves everything. No "undo correction" button needed. |
| **Set navigation** | Collapsible set headers with sticky behavior. Coach can jump to Set 3 without scrolling through Sets 1-2. |

---

### 3. What Should NOT Be Built

| Feature | Why It's Overkill |
|---------|-------------------|
| **Separate "audit log" screen** | A dedicated screen listing all corrections across all games is admin tooling, not coaching tooling. Per-event history in the bottom sheet is sufficient. |
| **Correction approval workflow** | No second person to approve. Single-scorekeeper app. An approval flow adds friction with zero value. |
| **Correction reasons / comments** | Don't require the coach to explain why they're correcting. They're fixing a mistake — the "why" is self-evident. Free-text correction notes are write-only data nobody reads. |
| **Bulk edit operations** | "Change all Player X events to Player Y" or "delete all events in a time range." These are power-user features for professional analytics teams, not volunteer scorekeepers. |
| **Version history with rollback** | "Restore to original" / "revert all corrections" adds complexity. If a correction was wrong, just correct again. The soft-delete chain already preserves history. |
| **Visual diff of corrections** | Side-by-side "before vs. after" comparison of the entire game. Overkill. The per-event history section in the bottom sheet shows what changed. |
| **Correction permissions / locking** | "Lock game after 48 hours" or "only head coach can correct." This app has no user accounts or roles. Locking adds friction without a security model to justify it. |
| **Score override** | Manual score editing separate from event corrections. Scores should always be derived from events — a manual override breaks the single-source-of-truth model and creates impossible audit states. |
| **Re-order events by drag-and-drop** | Dragging events to new positions in the timeline. The sequenceNumber insertion approach (2F) handles reordering implicitly when you delete + re-add. Drag-and-drop is fiddly on mobile and error-prone. |
| **Partial set corrections** | "Replay from event #14" — recalculate only events after a correction point. Full recalculation (2G) is fast enough (<500ms) that partial recalc optimization is unnecessary complexity. |

---

### 4. Task Breakdown

#### Prerequisites
The Game Detail Screen (Box Score + Play-by-Play tabs) is a prerequisite for corrections, but it has standalone value as the missing "game review" screen. Build it first.

#### Tasks

| ID | Task | Description | Depends On | Size |
|----|------|-------------|------------|------|
| `game-detail-screen` | Game Detail Screen (Box Score tab) | New screen at `/games/:gameId`. Shows final score, set scores, per-player box score table (K, E, TA, H%, A, D, BS, BA, SA, SE, RE, Pts). Wire navigation from Dashboard recent games, Player Detail game log, and Season Stats. This screen has value independent of corrections. | `stats-aggregation` | Medium |
| `play-by-play-view` | Play-by-Play tab (read-only) | Second tab on Game Detail Screen. Query `play_events` for the game, group by `periodId`, display as scrollable list with sticky set headers. Columns: seq#, score, player name, action label. Collapsible set sections. Read-only — no editing yet. | `game-detail-screen` | Medium |
| `correction-mode-toggle` | Correction Mode toggle | Add pencil icon to Game Detail app bar. Toggles between normal and correction mode. In correction mode: event rows become tappable, deleted events become visible (struck-through), FAB "Add Event" appears. State managed locally in the screen widget. | `play-by-play-view` | Small |
| `event-edit-sheet` | Edit Event bottom sheet | Bottom sheet opened by tapping an event row in correction mode. Player dropdown (roster), Category dropdown, Action dropdown (filtered by category), auto-derived Result. Save creates a soft-delete of the original + insert of corrected event with `metadata.corrects` link. | `correction-mode-toggle` | Large |
| `event-delete-correction` | Delete Event (correction mode) | Swipe-to-delete on event rows in correction mode + "Delete Event" button in the edit sheet. Two-tap confirmation (button turns red → "Confirm Delete"). Soft-deletes with `metadata.correctionReason = "delete"`. Row shows struck-through at 40% opacity. | `correction-mode-toggle` | Small |
| `event-insert-correction` | Add Missing Event | FAB "Add Event" in correction mode opens the edit sheet in insert mode. "Insert After Event #N" position picker. Auto-assigns sequence number and shifts subsequent events. Stores `metadata.correctionReason = "insert"`. | `event-edit-sheet` | Medium |
| `score-recalculation` | Score recalculation engine | On exiting correction mode: walk all active events per set, recompute `scoreUsAfter`/`scoreThemAfter` from point results, update `GamePeriod` set scores, update `Game` final scores and result. Loading overlay during recalculation. | `event-edit-sheet`, `event-delete-correction` | Medium |
| `reaggregation-trigger` | Re-aggregation after corrections | After score recalculation completes, call `StatsAggregationService.aggregateGameStats()` to recompute PlayerGameStats and PlayerSeasonStats. Service is already idempotent — this is just wiring the trigger. | `score-recalculation`, `stats-aggregation` | Small |
| `correction-audit-display` | Per-event audit trail | In the Edit Event bottom sheet, show "History" section: created timestamp, list of corrections (what changed, when). Query: find deleted events where `metadata.corrects` matches, plus the event's own correction metadata. | `event-edit-sheet` | Small |
| `correction-dao-methods` | DAO methods for corrections | Add to `StatsDao`: `updatePlayEvent()` (update fields on an event), `resequenceEvents(gameId, periodId)` (renumber sequence_numbers as contiguous integers), `getEventWithAuditTrail(eventId)` (fetch event + its correction chain via metadata links). | — | Small |

#### Dependency Graph

```
stats-aggregation (Sprint 1, already planned)
  └─► game-detail-screen
        └─► play-by-play-view
              └─► correction-mode-toggle
                    ├─► event-edit-sheet ◄── correction-dao-methods
                    │     ├─► event-insert-correction
                    │     ├─► correction-audit-display
                    │     └─► score-recalculation
                    │           └─► reaggregation-trigger
                    └─► event-delete-correction
```

#### Sprint Placement

| Sprint | Tasks | Rationale |
|--------|-------|-----------|
| **Sprint 2** | `game-detail-screen`, `play-by-play-view` | These have standalone value — every coach wants to review a completed game's box score and play-by-play. They're the foundation for corrections but useful without them. |
| **Sprint 3** | `correction-dao-methods`, `correction-mode-toggle`, `event-edit-sheet`, `event-delete-correction`, `event-insert-correction`, `score-recalculation`, `reaggregation-trigger`, `correction-audit-display` | Full correction workflow. By Sprint 3 the stats pipeline is solid and the game detail screen exists. This is when corrections become the highest-value unbuilt feature. |

#### Total Estimated Effort
- 3 Small tasks (~1-2 hours each): `correction-mode-toggle`, `event-delete-correction`, `reaggregation-trigger`, `correction-audit-display`, `correction-dao-methods`
- 3 Medium tasks (~3-5 hours each): `game-detail-screen`, `play-by-play-view`, `event-insert-correction`, `score-recalculation`
- 1 Large task (~5-8 hours): `event-edit-sheet`

**Total: ~25-35 hours of implementation work**, with the first ~10 hours producing a usable game detail screen independent of corrections.

---

## Post-Game Stat Corrections — Expert Design

*Source: sports-stats-designer agent review, Feb 2026.*

### Verdict: Yes, Build This

This is a must-have, not a nice-to-have. Reasons:

1. **Single-scorekeeper reality.** With no second person to verify, every game has 5-15 misrecorded events. Without corrections, coaches lose trust in the data.
2. **Tournament cadence.** Coaches play 4-6 games in a day. They catch mistakes between games or that evening reviewing stats. There is no way to fix them today.
3. **Data layer is 80% done.** Soft deletes, idempotent aggregation, `isDeleted` filtering — the hard parts exist. This is a UI problem, not an architecture problem.
4. **Adoption blocker.** A coach who can't fix a wrong stat will stop trusting the app. Trust is the #1 driver of continued use for stat tools.

### Entry Points

1. **Game Detail Screen** (new screen — also has standalone value as a game review/summary view)
   - Accessed from: Recent Games list on Dashboard, Season Stats game log, completed game end screen
   - Shows: opponent, date, final score, set scores, box score summary
   - Button: **"Review Play-by-Play"** → opens the event list

2. **Correction Mode Toggle**
   - Inside the play-by-play view, a pencil icon in the app bar toggles correction mode on/off
   - Normal mode: read-only event list (for game review)
   - Correction mode: edit/delete/add controls appear

### Play-by-Play Review Screen Layout

**Structure:** Scrollable list grouped by set with sticky set headers.

**Set Header (sticky):**
```
── Set 1 (25-20) ──────────────────────
```

**Event Row (each play):**
```
┌─────────────────────────────────────┐
│  #12  │  #7 S. Johnson  │  Kill  →  │
│  15-12│                  │  Point Us │
└─────────────────────────────────────┘
```

- **Left column:** Sequence number + score at that point (e.g., `#12  15-12`)
- **Center column:** Jersey number + player name
- **Right column:** Action type + result (color-coded: green = point_us, red = point_them, gray = rally_continues)
- **Correction mode additions:** Edit icon (pencil) on right edge, swipe-left to delete

**Filter chips** at top: All, Points Only, Errors Only, By Player (dropdown)

### Correction Operations

#### EDIT an Event
- Tap the pencil icon on an event row → **Bottom sheet** slides up
- Bottom sheet shows:
  - **Player** dropdown (pre-filled, changeable)
  - **Category** dropdown (Attack, Serve, Block, etc.) — changing this updates the Action dropdown
  - **Action** dropdown (Kill, Error, Ace, etc.) — changing this auto-updates Result
  - **Result** dropdown (point_us, point_them, rally_continues) — pre-filled from action default, overridable
  - **Save / Cancel** buttons
- Implementation: Soft-delete original event, insert new corrected event with same `sequenceNumber` and `metadata: { correctedFrom: originalEventId }`
- Original event preserved in DB (audit trail)

#### DELETE an Event
- **Swipe left** on event row → red "Delete" button appears
- Tap Delete → inline confirmation: row turns red with "Tap again to confirm"
- Second tap → soft-delete (`isDeleted = true`)
- Event row shows strikethrough text with "Deleted" label (stays visible in correction mode, hidden in normal mode)

#### ADD a Missing Event
- **FAB** (floating action button) appears in correction mode only
- Tap FAB → bottom sheet with:
  - **Insert after:** dropdown showing recent events (defaults to end of current set)
  - **Player, Category, Action, Result** dropdowns (same as Edit)
  - **Save** → inserts event, auto-resequences subsequent events

### Score & Stats Recalculation

- **When correction mode is exited** (toggle pencil off), the app:
  1. Walks all active (non-deleted) events in sequence order
  2. Recalculates `scoreUsAfter` / `scoreThemAfter` for every event
  3. Recalculates set scores and final game score/result
  4. Calls `StatsAggregationService.aggregateGame()` (already idempotent)
  5. Shows brief snackbar: "Stats recalculated — 3 corrections applied"
- **No manual score override.** Scores are always derived from events. This prevents score/event mismatches.

### Audit Trail

- **Storage:** `metadata` JSON field on PlayEvent: `{ correctedFrom: "event_123", correctedAt: "2026-02-21T..." }`
- **Display:** In correction mode, corrected events show a small "Edited" badge. Tap for details showing original action and correction timestamp.
- **No separate audit log screen.** Overkill for this audience. The metadata is there if ever needed.

### Mobile UX Considerations

- Bottom sheets (not full-screen modals) for edits — keeps context visible
- Swipe-to-delete is natural on mobile, avoids clutter of delete buttons on every row
- Filter chips reduce scrolling through 150+ events per game
- Set grouping with sticky headers lets coaches jump to "set 3" quickly
- Large touch targets (48dp minimum) on all correction controls — gyms are bumpy

### What NOT to Build

- **Audit log screen** — metadata is sufficient; a dedicated screen is enterprise complexity
- **Approval workflows** — no second reviewer exists at this level
- **Correction reason dropdowns** ("why did you change this?") — adds friction, no one reads these
- **Bulk edit** — coaches fix 3-5 events, not 50; one-at-a-time is fine
- **Version rollback** ("revert to original game") — soft deletes make this theoretically possible, but no coach has ever asked for this
- **Visual diff view** (before/after side-by-side) — over-engineered for the use case
- **Permissions / game locking** — there's one user per team; locking solves no real problem
- **Manual score override** — scores must derive from events to stay consistent
- **Drag-and-drop event reorder** — complex to build, sequence numbers + insert-after is sufficient
- **Partial recalculation** (only recompute from correction point forward) — premature optimization; full recalc on a 150-event game takes <100ms

### Task Breakdown

| ID | Task | Description | Depends On | Size |
|----|------|-------------|------------|------|
| `game-detail-screen` | Game detail screen | New screen showing game metadata, final score, set scores, box score summary. Entry point from dashboard recent games and season game log. Standalone value as game review. | — | Medium |
| `play-by-play-view` | Play-by-play event list | Scrollable list of all PlayEvents for a game, grouped by set with sticky headers. Read-only mode. Filter chips (All, Points, Errors, By Player). | `game-detail-screen` | Medium |
| `correction-mode-toggle` | Correction mode toggle | Pencil icon in play-by-play app bar. Toggles between read-only and correction mode. Shows/hides edit controls, FAB, swipe-delete. | `play-by-play-view` | Small |
| `correction-edit-event` | Edit event bottom sheet | Tap pencil on event row → bottom sheet with Player, Category, Action, Result dropdowns. Saves as soft-delete original + insert corrected event with metadata link. | `correction-mode-toggle` | Medium |
| `correction-delete-event` | Swipe-to-delete event | Swipe left on event row → Delete button → tap-again confirmation → soft-delete. Strikethrough display in correction mode, hidden in normal mode. | `correction-mode-toggle` | Small |
| `correction-add-event` | Add missing event | FAB in correction mode → bottom sheet with insert-after position picker + Player/Category/Action/Result. Auto-resequences subsequent events. | `correction-mode-toggle` | Medium |
| `correction-recalc` | Score & stats recalculation | On correction mode exit: walk all active events, recalculate scores, set scores, game result. Call `StatsAggregationService.aggregateGame()`. Show snackbar summary. | `correction-edit-event`, `correction-delete-event`, `correction-add-event` | Medium |
| `correction-audit-badge` | Audit trail badges | Corrected events show "Edited" badge in correction mode. Tap for details (original action, correction timestamp). Data stored in PlayEvent metadata. | `correction-edit-event` | Small |

### Sprint Placement

| Sprint | Tasks |
|--------|-------|
| **Sprint 2** (standalone value) | `game-detail-screen`, `play-by-play-view` |
| **Sprint 3** (correction workflow) | `correction-mode-toggle`, `correction-edit-event`, `correction-delete-event`, `correction-add-event`, `correction-recalc`, `correction-audit-badge` |

---

## Decisions (Resolved)
- **Dashboard**: Start minimal — don't over-engineer. Start Game hero, last game card, season record w/ streaks, team leaders. Add trends card later once aggregation is solid.
- **Quick+ Mode**: No. Quick (8 buttons) and Detailed (20 buttons) is sufficient.
- **Pass rating scale**: 0-3 only. Keep it simple.
- **Substitution limit**: Configurable per team (NCAA 15 / NFHS 12 / custom).
- **Target audience**: Youth, high school, & rec. Avoid complexity. Keep UX fast and approachable.
