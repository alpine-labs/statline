import 'package:flutter/material.dart';

/// Supported sports in StatLine.
enum Sport {
  volleyball(
    displayName: 'Volleyball',
    icon: Icons.sports_volleyball,
    accentColor: Color(0xFF555B73),
  ),
  basketball(
    displayName: 'Basketball',
    icon: Icons.sports_basketball,
    accentColor: Color(0xFF1565C0),
  ),
  slowpitch(
    displayName: 'Slowpitch Softball',
    icon: Icons.sports_baseball,
    accentColor: Color(0xFF2E7D32),
  ),
  baseball(
    displayName: 'Baseball',
    icon: Icons.sports_baseball,
    accentColor: Color(0xFFC62828),
  ),
  football(
    displayName: 'Football',
    icon: Icons.sports_football,
    accentColor: Color(0xFF5D4037),
  );

  const Sport({
    required this.displayName,
    required this.icon,
    required this.accentColor,
  });

  final String displayName;
  final IconData icon;
  final Color accentColor;
}

/// Sport-specific default game format configurations.
class SportConfig {
  SportConfig._();

  /// Returns the default game configuration for the given [sport].
  static Map<String, dynamic> defaultFormat(Sport sport) {
    return switch (sport) {
      Sport.volleyball => _volleyballDefaults,
      Sport.basketball => _basketballDefaults,
      Sport.slowpitch => _slowpitchDefaults,
      Sport.baseball => _baseballDefaults,
      Sport.football => _footballDefaults,
    };
  }

  // ── Volleyball ─────────────────────────────────────────────────────────

  static const Map<String, dynamic> _volleyballDefaults = {
    'setsToWin': 3, // best of 5 (3 to win)
    'maxSets': 5,
    'pointsPerSet': 25,
    'decidingSetPoints': 15,
    'minPointAdvantage': 2,
    'bestOf3': {
      'setsToWin': 2,
      'maxSets': 3,
      'pointsPerSet': 25,
      'decidingSetPoints': 15,
      'minPointAdvantage': 2,
    },
    'bestOf5': {
      'setsToWin': 3,
      'maxSets': 5,
      'pointsPerSet': 25,
      'decidingSetPoints': 15,
      'minPointAdvantage': 2,
    },
  };

  // ── Basketball ─────────────────────────────────────────────────────────

  static const Map<String, dynamic> _basketballDefaults = {
    'quarters': 4,
    'quarterLengthMinutes': 12, // NBA default; configurable
    'overtimeLengthMinutes': 5,
    'personalFoulLimit': 6,
    'teamFoulLimitPerQuarter': 5,
    'timeoutsPerHalf': 4,
  };

  // ── Slowpitch Softball ─────────────────────────────────────────────────

  static const Map<String, dynamic> _slowpitchDefaults = {
    'innings': 7,
    'homeRunLimit': 0, // 0 = unlimited; league-configurable
    'runRuleDifference': 15,
    'runRuleInning': 4,
    'maxRunsPerInning': 0, // 0 = unlimited
  };

  // ── Baseball ───────────────────────────────────────────────────────────

  static const Map<String, dynamic> _baseballDefaults = {
    'innings': 9,
    'designatedHitter': true,
    'mercyRuleDifference': 10,
    'mercyRuleInning': 7,
  };

  // ── Football ───────────────────────────────────────────────────────────

  static const Map<String, dynamic> _footballDefaults = {
    'quarters': 4,
    'quarterLengthMinutes': 15, // NFL default; configurable
    'overtimeLengthMinutes': 10,
    'timeoutsPerHalf': 3,
  };
}
