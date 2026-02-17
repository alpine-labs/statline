import 'package:flutter/material.dart';

import '../models/game_period.dart';
import '../models/play_event.dart';

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
