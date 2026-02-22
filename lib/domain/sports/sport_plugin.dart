import 'package:flutter/material.dart';

import '../models/game_period.dart';
import '../models/game_summary.dart';
import '../models/play_event.dart';
import '../models/player.dart';

abstract class SportPlugin {
  String get sportId;
  String get displayName;
  IconData get icon;

  // Event definitions
  List<EventCategory> get eventCategories;
  List<EventCategory> get quickModeEvents;

  // Game format
  Map<String, dynamic> get defaultGameFormat;

  // Stat calculations
  Map<String, dynamic> computeGameStats(List<PlayEvent> events,
      {bool isOpponent = false});
  Map<String, dynamic> computeSeasonMetrics(
      Map<String, dynamic> totals, int gamesPlayed, int totalSets);

  // Enrich season totals with sport-specific computed values.
  // Called after summing game stats into totals. Default: no-op.
  Map<String, dynamic> enrichSeasonTotals(Map<String, dynamic> totals) => totals;

  // Table column definitions for display
  List<StatColumn> get gameStatsColumns;
  List<StatColumn> get seasonStatsColumns;

  // Game state
  bool isGameOver(
      List<GamePeriod> periods, Map<String, dynamic> gameFormat);
  bool isPeriodOver(GamePeriod period, Map<String, dynamic> gameFormat);
  String periodLabel(GamePeriod period);

  // Period management
  GamePeriod createNextPeriod(
      String gameId, List<GamePeriod> existing, Map<String, dynamic> gameFormat);

  // Game summary generation.
  // Default implementation returns a minimal summary. Override for sport-specific
  // MVP formulas, top performers, and notable stat thresholds.
  GameSummary generateGameSummary({
    required String gameId,
    required String opponentName,
    required List<GamePeriod> periods,
    required List<PlayEvent> events,
    required List<Player> roster,
  }) {
    final sortedPeriods = [...periods]
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

    int periodsWonUs = 0;
    int periodsWonThem = 0;
    for (final p in sortedPeriods) {
      if (p.scoreUs > p.scoreThem) {
        periodsWonUs++;
      } else if (p.scoreThem > p.scoreUs) {
        periodsWonThem++;
      }
    }

    final result = periodsWonUs > periodsWonThem
        ? 'win'
        : periodsWonThem > periodsWonUs
            ? 'loss'
            : 'tie';

    return GameSummary(
      gameId: gameId,
      opponentName: opponentName,
      result: result,
      setsWonUs: periodsWonUs,
      setsWonThem: periodsWonThem,
      setScores: [
        for (final p in sortedPeriods)
          (scoreUs: p.scoreUs, scoreThem: p.scoreThem),
      ],
    );
  }
}

class EventCategory {
  final String id;
  final String label;
  final List<EventType> eventTypes;

  const EventCategory({
    required this.id,
    required this.label,
    required this.eventTypes,
  });
}

class EventType {
  final String id;
  final String label;
  final String category;
  final String defaultResult;
  final bool availableInQuickMode;
  final IconData? icon;

  const EventType({
    required this.id,
    required this.label,
    required this.category,
    this.defaultResult = 'rally_continues',
    this.availableInQuickMode = false,
    this.icon,
  });
}

class StatColumn {
  final String key;
  final String label;
  final String shortLabel;
  final String? format;

  const StatColumn({
    required this.key,
    required this.label,
    required this.shortLabel,
    this.format,
  });
}
