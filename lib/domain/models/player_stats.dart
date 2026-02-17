import 'dart:convert';

class PlayerGameStatsModel {
  final String id;
  final String gameId;
  final String playerId;
  final String sport;
  final Map<String, dynamic> stats;
  final DateTime computedAt;

  const PlayerGameStatsModel({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.sport,
    required this.stats,
    required this.computedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'player_id': playerId,
      'sport': sport,
      'stats': jsonEncode(stats),
      'computed_at': computedAt.toIso8601String(),
    };
  }

  factory PlayerGameStatsModel.fromMap(Map<String, dynamic> map) {
    final statsRaw = map['stats'];
    Map<String, dynamic> stats;
    if (statsRaw is String) {
      stats = Map<String, dynamic>.from(jsonDecode(statsRaw) as Map);
    } else if (statsRaw is Map) {
      stats = Map<String, dynamic>.from(statsRaw);
    } else {
      stats = {};
    }

    return PlayerGameStatsModel(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      playerId: map['player_id'] as String,
      sport: map['sport'] as String,
      stats: stats,
      computedAt: DateTime.parse(map['computed_at'] as String),
    );
  }

  @override
  String toString() {
    return 'PlayerGameStatsModel(id: $id, gameId: $gameId, playerId: $playerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerGameStatsModel &&
        other.id == id &&
        other.gameId == gameId &&
        other.playerId == playerId &&
        other.sport == sport &&
        other.computedAt == computedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, gameId, playerId, sport, computedAt);
  }
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
  final DateTime computedAt;

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'season_id': seasonId,
      'player_id': playerId,
      'sport': sport,
      'games_played': gamesPlayed,
      'stats_totals': jsonEncode(statsTotals),
      'stats_averages': jsonEncode(statsAverages),
      'computed_metrics': jsonEncode(computedMetrics),
      'computed_at': computedAt.toIso8601String(),
    };
  }

  factory PlayerSeasonStatsModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parseJsonField(dynamic raw) {
      if (raw is String) {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } else if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return {};
    }

    return PlayerSeasonStatsModel(
      id: map['id'] as String,
      seasonId: map['season_id'] as String,
      playerId: map['player_id'] as String,
      sport: map['sport'] as String,
      gamesPlayed: map['games_played'] as int,
      statsTotals: parseJsonField(map['stats_totals']),
      statsAverages: parseJsonField(map['stats_averages']),
      computedMetrics: parseJsonField(map['computed_metrics']),
      computedAt: DateTime.parse(map['computed_at'] as String),
    );
  }

  @override
  String toString() {
    return 'PlayerSeasonStatsModel(id: $id, seasonId: $seasonId, playerId: $playerId, gamesPlayed: $gamesPlayed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerSeasonStatsModel &&
        other.id == id &&
        other.seasonId == seasonId &&
        other.playerId == playerId &&
        other.sport == sport &&
        other.gamesPlayed == gamesPlayed &&
        other.computedAt == computedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, seasonId, playerId, sport, gamesPlayed, computedAt);
  }
}
