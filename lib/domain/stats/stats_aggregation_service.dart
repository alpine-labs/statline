import '../../data/repositories/stats_repository.dart';
import '../models/game.dart';
import '../models/game_period.dart';
import '../models/play_event.dart';
import '../models/player_stats.dart';
import 'stat_calculator.dart';

/// Aggregates play events into per-player game and season stats.
///
/// Designed to be idempotent — safe to call multiple times for the same game
/// since the repository uses INSERT OR REPLACE.
class StatsAggregationService {
  final StatsRepository _repository;

  StatsAggregationService(this._repository);

  /// Computes and persists game stats and season stats for all participating
  /// players. Accepts in-memory [events] and [periods] directly so events
  /// don't need to be persisted to the DB first.
  Future<void> aggregateGameStats({
    required Game game,
    required List<PlayEvent> events,
    required List<String> playerIds,
    required List<GamePeriod> periods,
  }) async {
    final activeEvents =
        events.where((e) => !e.isDeleted && !e.isOpponent).toList();

    // Determine which players actually participated (have ≥1 event)
    final participatingPlayerIds = playerIds
        .where((pid) => activeEvents.any((e) => e.playerId == pid))
        .toSet();

    // Phase 1: Compute and save game stats for each participating player
    for (final playerId in participatingPlayerIds) {
      final statsMap = StatCalculator.computePlayerGameStats(
        game.sport,
        events, // pass all events; calculator filters by playerId
        playerId,
      );

      // Compute sets_played: count distinct periodIds where player has ≥1 event
      final setsPlayed = activeEvents
          .where((e) => e.playerId == playerId)
          .map((e) => e.periodId)
          .toSet()
          .length;
      statsMap['sets_played'] = setsPlayed;

      final gameStats = PlayerGameStatsModel(
        id: '${game.id}_$playerId',
        gameId: game.id,
        playerId: playerId,
        sport: game.sport,
        stats: statsMap,
        computedAt: DateTime.now(),
      );

      await _repository.savePlayerGameStats(gameStats);
    }

    // Phase 2: Recompute season stats for each affected player
    for (final playerId in participatingPlayerIds) {
      await _recomputeSeasonStats(
        seasonId: game.seasonId,
        playerId: playerId,
        sport: game.sport,
      );
    }
  }

  /// Fetches all game stats for a player in the season and recomputes the
  /// aggregated season stats.
  Future<PlayerSeasonStatsModel> _recomputeSeasonStats({
    required String seasonId,
    required String playerId,
    required String sport,
  }) async {
    final gameLog = await _repository.getPlayerGameLog(playerId, seasonId);
    final gameStatsList = gameLog.map((g) => g.stats).toList();
    final gamesPlayed = gameLog.length;

    // Sum total sets across all games
    final totalSets = gameLog.fold<int>(
      0,
      (sum, g) => sum + ((g.stats['sets_played'] as num?)?.toInt() ?? 0),
    );

    final seasonStats = StatCalculator.computePlayerSeasonStats(
      id: '${seasonId}_$playerId',
      sport: sport,
      seasonId: seasonId,
      playerId: playerId,
      gameStatsList: gameStatsList,
      gamesPlayed: gamesPlayed,
      totalSets: totalSets,
    );

    await _repository.savePlayerSeasonStats(seasonStats);
    return seasonStats;
  }
}
