import '../models/play_event.dart';
import '../models/player_stats.dart';
import '../sports/sport_plugin.dart';
import '../sports/volleyball/volleyball_plugin.dart';
import '../sports/volleyball/volleyball_stats.dart';

/// Generic stat calculation engine that delegates to sport-specific plugins.
class StatCalculator {
  static final Map<String, SportPlugin> _plugins = {
    'volleyball': VolleyballPlugin(),
  };

  /// Returns the appropriate sport plugin.
  static SportPlugin getSportPlugin(String sport) {
    final plugin = _plugins[sport];
    if (plugin == null) {
      throw ArgumentError('Unsupported sport: $sport');
    }
    return plugin;
  }

  /// Computes per-player game stats by filtering events for [playerId]
  /// and delegating to the sport plugin.
  static Map<String, dynamic> computePlayerGameStats(
    String sport,
    List<PlayEvent> events,
    String playerId,
  ) {
    final plugin = getSportPlugin(sport);
    final playerEvents =
        events.where((e) => e.playerId == playerId && !e.isDeleted && !e.isOpponent).toList();
    return plugin.computeGameStats(playerEvents);
  }

  /// Computes team-level game stats across all (non-opponent) events.
  static Map<String, dynamic> computeTeamGameStats(
    String sport,
    List<PlayEvent> events,
  ) {
    final plugin = getSportPlugin(sport);
    return plugin.computeGameStats(events);
  }

  /// Computes season stats by summing all game stats and computing
  /// per-set / per-game metrics via the sport plugin.
  static PlayerSeasonStatsModel computePlayerSeasonStats({
    required String id,
    required String sport,
    required String seasonId,
    required String playerId,
    required List<Map<String, dynamic>> gameStatsList,
    required int gamesPlayed,
    required int totalSets,
  }) {
    final plugin = getSportPlugin(sport);

    // Sum all game stats into totals
    final totals = <String, dynamic>{};
    for (final gameStats in gameStatsList) {
      for (final entry in gameStats.entries) {
        final value = entry.value;
        if (value is num) {
          totals[entry.key] =
              ((totals[entry.key] as num?) ?? 0) + value;
        }
      }
    }

    // Compute averages per game
    final averages = <String, dynamic>{};
    if (gamesPlayed > 0) {
      for (final entry in totals.entries) {
        if (entry.value is num) {
          averages[entry.key] = (entry.value as num) / gamesPlayed;
        }
      }
    }

    // Delegate sport-specific computed metrics
    final computedMetrics =
        plugin.computeSeasonMetrics(totals, gamesPlayed, totalSets);

    // Recalculate hitting_pct from season totals
    if (sport == 'volleyball') {
      totals['hitting_pct'] = VolleyballStats.computeHittingPercentage(
        (totals['kills'] as num?)?.toInt() ?? 0,
        (totals['attack_errors'] as num?)?.toInt() ?? 0,
        (totals['attack_attempts'] as num?)?.toInt() ?? 0,
      );
    }

    return PlayerSeasonStatsModel(
      id: id,
      seasonId: seasonId,
      playerId: playerId,
      sport: sport,
      gamesPlayed: gamesPlayed,
      statsTotals: totals,
      statsAverages: averages,
      computedMetrics: computedMetrics,
      computedAt: DateTime.now(),
    );
  }
}
