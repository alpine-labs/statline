import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/game_period.dart';
import '../../models/play_event.dart';
import '../sport_plugin.dart';
import 'volleyball_events.dart';
import 'volleyball_stats.dart';

class VolleyballPlugin extends SportPlugin {
  static const _uuid = Uuid();

  @override
  String get sportId => 'volleyball';

  @override
  String get displayName => 'Volleyball';

  @override
  IconData get icon => Icons.sports_volleyball;

  // ── Event definitions ───────────────────────────────────────────────────
  @override
  List<EventCategory> get eventCategories => VolleyballEvents.allCategories;

  @override
  List<EventCategory> get quickModeEvents =>
      VolleyballEvents.quickModeCategories;

  // ── Game format ─────────────────────────────────────────────────────────
  @override
  Map<String, dynamic> get defaultGameFormat => {
        'sets_to_win': 3,
        'points_per_set': 25,
        'deciding_set_points': 15,
        'min_advantage': 2,
      };

  // ── Stat calculations ──────────────────────────────────────────────────
  @override
  Map<String, dynamic> computeGameStats(List<PlayEvent> events,
      {bool isOpponent = false}) {
    return VolleyballStats.aggregateFromEvents(events, isOpponent: isOpponent);
  }

  @override
  Map<String, dynamic> computeSeasonMetrics(
      Map<String, dynamic> totals, int gamesPlayed, int totalSets) {
    if (totalSets == 0) totalSets = 1;

    final kills = (totals['kills'] as num?)?.toInt() ?? 0;
    final aces = (totals['serviceAces'] as num?)?.toInt() ?? 0;
    final digs = (totals['digs'] as num?)?.toInt() ?? 0;
    final totalBlocks = (totals['totalBlocks'] as num?)?.toInt() ?? 0;
    final attackErrors = (totals['errors'] as num?)?.toInt() ?? 0;
    final attackAttempts = (totals['totalAttempts'] as num?)?.toInt() ?? 0;
    final serveErrors = (totals['serviceErrors'] as num?)?.toInt() ?? 0;
    final servesTotal =
        aces + serveErrors + ((totals['servesInPlay'] as num?)?.toInt() ?? 0);
    final passRatingTotal = (totals['passRating'] as num?)?.toDouble() ?? 0.0;
    final pass3Count = (totals['pass3Count'] as num?)?.toInt() ?? 0;
    final passAttempts = (totals['passAttempts'] as num?)?.toInt() ?? 0;
    final points = (totals['points'] as num?)?.toDouble() ?? 0.0;

    return {
      'kills_per_set': kills / totalSets,
      'aces_per_set': aces / totalSets,
      'digs_per_set': digs / totalSets,
      'blocks_per_set': totalBlocks / totalSets,
      'hittingPercentage': VolleyballStats.computeHittingPercentage(
          kills, attackErrors, attackAttempts),
      'pass_rating_avg':
          gamesPlayed > 0 ? passRatingTotal / gamesPlayed : 0.0,
      'serve_error_pct': servesTotal > 0 ? serveErrors / servesTotal : 0.0,
      'perfectPassPct': VolleyballStats.computePerfectPassPercentage(
          pass3Count, passAttempts),
      'serveEfficiency': VolleyballStats.computeServeEfficiency(
          aces, serveErrors, servesTotal),
      'points_per_set': points / totalSets,
    };
  }

  // ── Table column definitions ───────────────────────────────────────────
  @override
  List<StatColumn> get gameStatsColumns => const [
        StatColumn(
            key: 'games_played', label: 'Games Played', shortLabel: 'GP', format: 'int'),
        StatColumn(key: 'kills', label: 'Kills', shortLabel: 'K', format: 'int'),
        StatColumn(
            key: 'errors', label: 'Errors', shortLabel: 'E', format: 'int'),
        StatColumn(
            key: 'totalAttempts',
            label: 'Total Attacks',
            shortLabel: 'TA',
            format: 'int'),
        StatColumn(
            key: 'hittingPercentage',
            label: 'Hitting %',
            shortLabel: 'Hit%',
            format: 'decimal3'),
        StatColumn(
            key: 'assists', label: 'Assists', shortLabel: 'A', format: 'int'),
        StatColumn(
            key: 'serviceAces', label: 'Service Aces', shortLabel: 'SA', format: 'int'),
        StatColumn(
            key: 'serviceErrors',
            label: 'Serve Errors',
            shortLabel: 'SE',
            format: 'int'),
        StatColumn(key: 'digs', label: 'Digs', shortLabel: 'D', format: 'int'),
        StatColumn(
            key: 'blockSolos',
            label: 'Block Solos',
            shortLabel: 'BS',
            format: 'int'),
        StatColumn(
            key: 'blockAssists',
            label: 'Block Assists',
            shortLabel: 'BA',
            format: 'int'),
        StatColumn(
            key: 'totalBlocks',
            label: 'Total Blocks',
            shortLabel: 'TB',
            format: 'int'),
        StatColumn(
            key: 'points', label: 'Points', shortLabel: 'Pts', format: 'decimal2'),
      ];

  @override
  List<StatColumn> get seasonStatsColumns => [
        ...gameStatsColumns,
        const StatColumn(
            key: 'kills_per_set',
            label: 'Kills/Set',
            shortLabel: 'K/S',
            format: 'decimal2'),
        const StatColumn(
            key: 'aces_per_set',
            label: 'Aces/Set',
            shortLabel: 'A/S',
            format: 'decimal2'),
        const StatColumn(
            key: 'digs_per_set',
            label: 'Digs/Set',
            shortLabel: 'D/S',
            format: 'decimal2'),
        const StatColumn(
            key: 'blocks_per_set',
            label: 'Blocks/Set',
            shortLabel: 'B/S',
            format: 'decimal2'),
        const StatColumn(
            key: 'pass_rating_avg',
            label: 'Pass Rating',
            shortLabel: 'PR',
            format: 'decimal2'),
        const StatColumn(
            key: 'serve_error_pct',
            label: 'Serve Error %',
            shortLabel: 'SE%',
            format: 'percentage'),
        const StatColumn(
            key: 'perfectPassPct',
            label: 'Perfect Pass %',
            shortLabel: 'PP%',
            format: 'decimal3'),
        const StatColumn(
            key: 'serveEfficiency',
            label: 'Serve Efficiency',
            shortLabel: 'SrEff',
            format: 'decimal3'),
        const StatColumn(
            key: 'points_per_set',
            label: 'Points/Set',
            shortLabel: 'P/S',
            format: 'decimal2'),
      ];

  // ── Game state ─────────────────────────────────────────────────────────
  @override
  bool isGameOver(List<GamePeriod> periods, Map<String, dynamic> gameFormat) {
    final setsToWin = (gameFormat['sets_to_win'] as num?)?.toInt() ?? 3;
    int setsWonUs = 0;
    int setsWonThem = 0;

    for (final period in periods) {
      if (isPeriodOver(period, gameFormat)) {
        if (period.scoreUs > period.scoreThem) {
          setsWonUs++;
        } else {
          setsWonThem++;
        }
      }
    }

    return setsWonUs >= setsToWin || setsWonThem >= setsToWin;
  }

  @override
  bool isPeriodOver(GamePeriod period, Map<String, dynamic> gameFormat) {
    final setsToWin = (gameFormat['sets_to_win'] as num?)?.toInt() ?? 3;
    final totalSets = setsToWin * 2 - 1;
    final isDecidingSet = period.periodNumber >= totalSets;
    final pointsNeeded = isDecidingSet
        ? (gameFormat['deciding_set_points'] as num?)?.toInt() ?? 15
        : (gameFormat['points_per_set'] as num?)?.toInt() ?? 25;
    final minAdvantage = (gameFormat['min_advantage'] as num?)?.toInt() ?? 2;

    final maxScore =
        period.scoreUs > period.scoreThem ? period.scoreUs : period.scoreThem;
    final diff = (period.scoreUs - period.scoreThem).abs();

    return maxScore >= pointsNeeded && diff >= minAdvantage;
  }

  @override
  String periodLabel(GamePeriod period) {
    return 'Set ${period.periodNumber}';
  }

  // ── Period management ──────────────────────────────────────────────────
  @override
  GamePeriod createNextPeriod(
    String gameId,
    List<GamePeriod> existing,
    Map<String, dynamic> gameFormat,
  ) {
    final nextNumber = existing.isEmpty
        ? 1
        : existing
                .map((p) => p.periodNumber)
                .reduce((a, b) => a > b ? a : b) +
            1;

    return GamePeriod(
      id: _uuid.v4(),
      gameId: gameId,
      periodNumber: nextNumber,
      periodType: 'set',
      scoreUs: 0,
      scoreThem: 0,
    );
  }
}
