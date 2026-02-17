import 'dart:convert';

class PlayerGameStatsModel {
  final String id;
  final String gameId;
  final String playerId;
  final String sport;
  final Map<String, dynamic> stats;
  final int computedAt;

  const PlayerGameStatsModel({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.sport,
    required this.stats,
    required this.computedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'game_id': gameId,
        'player_id': playerId,
        'sport': sport,
        'stats': jsonEncode(stats),
        'computed_at': computedAt,
      };

  factory PlayerGameStatsModel.fromMap(Map<String, dynamic> map) =>
      PlayerGameStatsModel(
        id: map['id'] as String,
        gameId: map['game_id'] as String,
        playerId: map['player_id'] as String,
        sport: map['sport'] as String,
        stats:
            jsonDecode(map['stats'] as String) as Map<String, dynamic>,
        computedAt: map['computed_at'] as int,
      );
}

class PlayerSeasonStatsModel {
  final String id;
  final String seasonId;
  final String playerId;
  final String sport;
  final int gamesPlayed;
  final Map<String, dynamic> statsTotals;
  final Map<String, dynamic> statsAverages;
  final Map<String, dynamic> computedMetrics;
  final int computedAt;

  const PlayerSeasonStatsModel({
    required this.id,
    required this.seasonId,
    required this.playerId,
    required this.sport,
    required this.gamesPlayed,
    required this.statsTotals,
    required this.statsAverages,
    required this.computedMetrics,
    required this.computedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'season_id': seasonId,
        'player_id': playerId,
        'sport': sport,
        'games_played': gamesPlayed,
        'stats_totals': jsonEncode(statsTotals),
        'stats_averages': jsonEncode(statsAverages),
        'computed_metrics': jsonEncode(computedMetrics),
        'computed_at': computedAt,
      };

  factory PlayerSeasonStatsModel.fromMap(Map<String, dynamic> map) =>
      PlayerSeasonStatsModel(
        id: map['id'] as String,
        seasonId: map['season_id'] as String,
        playerId: map['player_id'] as String,
        sport: map['sport'] as String,
        gamesPlayed: map['games_played'] as int,
        statsTotals: jsonDecode(map['stats_totals'] as String)
            as Map<String, dynamic>,
        statsAverages: jsonDecode(map['stats_averages'] as String)
            as Map<String, dynamic>,
        computedMetrics: jsonDecode(map['computed_metrics'] as String)
            as Map<String, dynamic>,
        computedAt: map['computed_at'] as int,
      );
}
