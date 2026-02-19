import '../models/game.dart';
import '../models/game_period.dart';
import '../models/game_summary.dart';
import '../models/play_event.dart';
import '../models/player.dart';

/// Generates a [GameSummary] from raw game data.
class GameSummaryService {
  GameSummaryService._();

  static GameSummary generate({
    required Game game,
    required List<GamePeriod> periods,
    required List<PlayEvent> events,
    required List<Player> roster,
  }) {
    // ── Set scores ──────────────────────────────────────────────────
    final sortedPeriods = [...periods]
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

    final setScores = <({int scoreUs, int scoreThem})>[
      for (final p in sortedPeriods) (scoreUs: p.scoreUs, scoreThem: p.scoreThem),
    ];

    int setsWonUs = 0;
    int setsWonThem = 0;
    for (final p in sortedPeriods) {
      if (p.scoreUs > p.scoreThem) {
        setsWonUs++;
      } else if (p.scoreThem > p.scoreUs) {
        setsWonThem++;
      }
    }

    final result = setsWonUs > setsWonThem
        ? 'win'
        : setsWonThem > setsWonUs
            ? 'loss'
            : 'tie';

    // ── Per-player accumulators ─────────────────────────────────────
    final playerMap = <String, Player>{
      for (final p in roster) p.id: p,
    };

    final nonDeletedOwn =
        events.where((e) => !e.isDeleted && !e.isOpponent).toList();

    final kills = <String, int>{};
    final aces = <String, int>{};
    final blockSolos = <String, int>{};
    final blockAssists = <String, int>{};
    final digs = <String, int>{};
    final assists = <String, int>{};
    final errors = <String, int>{};

    for (final e in nonDeletedOwn) {
      final pid = e.playerId;
      switch (e.eventType) {
        case 'kill':
          kills[pid] = (kills[pid] ?? 0) + 1;
          break;
        case 'ace':
          aces[pid] = (aces[pid] ?? 0) + 1;
          break;
        case 'block_solo':
          blockSolos[pid] = (blockSolos[pid] ?? 0) + 1;
          break;
        case 'block_assist':
          blockAssists[pid] = (blockAssists[pid] ?? 0) + 1;
          break;
        case 'dig':
          digs[pid] = (digs[pid] ?? 0) + 1;
          break;
        case 'set_assist':
          assists[pid] = (assists[pid] ?? 0) + 1;
          break;
        case 'attack_error':
        case 'blocked':
        case 'serve_error':
        case 'set_error':
        case 'block_error':
        case 'dig_error':
          errors[pid] = (errors[pid] ?? 0) + 1;
          break;
      }
    }

    // ── MVP (kills + aces + blocks × 0.5) ──────────────────────────
    final allPlayerIds = <String>{
      ...kills.keys,
      ...aces.keys,
      ...blockSolos.keys,
      ...blockAssists.keys,
    };

    String? mvpId;
    double mvpPoints = 0;
    for (final pid in allPlayerIds) {
      final pts = (kills[pid] ?? 0) +
          (aces[pid] ?? 0) +
          ((blockSolos[pid] ?? 0) + (blockAssists[pid] ?? 0)) * 0.5;
      if (pts > mvpPoints) {
        mvpPoints = pts;
        mvpId = pid;
      }
    }

    // ── Top performers ─────────────────────────────────────────────
    final topPerformers =
        <String, ({String playerId, String playerName, dynamic value})>{};

    void addTop(String category, Map<String, int> map) {
      if (map.isEmpty) return;
      final sorted = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final name = playerMap[top.key]?.displayName ?? top.key;
      topPerformers[category] =
          (playerId: top.key, playerName: name, value: top.value);
    }

    addTop('kills', kills);
    addTop('digs', digs);
    addTop('aces', aces);

    // Combine block solos + assists for block leader
    final totalBlocks = <String, int>{};
    for (final pid in {...blockSolos.keys, ...blockAssists.keys}) {
      totalBlocks[pid] = (blockSolos[pid] ?? 0) + (blockAssists[pid] ?? 0);
    }
    addTop('blocks', totalBlocks);
    addTop('assists', assists);

    // ── Notable stats ──────────────────────────────────────────────
    final notableStats = <String>[];

    for (final pid in allPlayerIds) {
      final name = playerMap[pid]?.displayName ?? pid;
      final k = kills[pid] ?? 0;
      final a = aces[pid] ?? 0;
      final b = (blockSolos[pid] ?? 0) + (blockAssists[pid] ?? 0);

      if (k >= 10) notableStats.add('$name had $k kills');
      if (a >= 3) notableStats.add('$name had $a aces');
      if (b >= 5) notableStats.add('$name had $b blocks');
    }

    // Players with 0 errors
    for (final pid in allPlayerIds) {
      if ((errors[pid] ?? 0) == 0) {
        final name = playerMap[pid]?.displayName ?? pid;
        notableStats.add('$name had 0 errors');
      }
    }

    return GameSummary(
      gameId: game.id,
      opponentName: game.opponentName,
      result: result,
      setsWonUs: setsWonUs,
      setsWonThem: setsWonThem,
      setScores: setScores,
      mvpPlayerId: mvpId,
      mvpPlayerName: mvpId != null ? playerMap[mvpId]?.displayName : null,
      mvpPoints: mvpPoints,
      topPerformers: topPerformers,
      notableStats: notableStats,
    );
  }
}
