import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models/play_event.dart';
import '../domain/models/player_stats.dart';

/// Utility for exporting stat data to CSV format.
class CsvExporter {
  CsvExporter._();

  static const _csvConverter = ListToCsvConverter();

  // ── Season stats ─────────────────────────────────────────────────────

  /// Export season stats to a CSV string.
  ///
  /// Headers are sport-specific. Each [PlayerSeasonStatsModel] produces one
  /// row. The caller supplies a [playerNames] map (playerId → display name)
  /// so the CSV includes human-readable names.
  static String exportSeasonStats(
    List<PlayerSeasonStatsModel> stats,
    String sport, {
    Map<String, String> playerNames = const {},
  }) {
    final headers = _seasonHeaders(sport);
    final rows = <List<dynamic>>[
      headers,
      for (final s in stats) _seasonRow(s, sport, playerNames),
    ];
    return _csvConverter.convert(rows);
  }

  // ── Play-by-play ─────────────────────────────────────────────────────

  /// Export a list of [PlayEvent]s to CSV.
  static String exportPlayByPlay(
    List<PlayEvent> events,
    Map<String, String> playerNames,
  ) {
    const headers = [
      'Sequence',
      'Time',
      'Player',
      'Category',
      'Type',
      'Result',
      'Score',
    ];

    final rows = <List<dynamic>>[
      headers,
      for (final e in events)
        [
          e.sequenceNumber,
          e.gameClock ?? e.timestamp.toIso8601String(),
          playerNames[e.playerId] ?? e.playerId,
          e.eventCategory,
          e.eventType,
          e.result,
          '${e.scoreUsAfter}-${e.scoreThemAfter}',
        ],
    ];
    return _csvConverter.convert(rows);
  }

  // ── Player game log ──────────────────────────────────────────────────

  /// Export a player's game-by-game stats to CSV.
  static String exportPlayerGameLog(
    List<PlayerGameStatsModel> gameLog,
    String playerName,
    String sport,
  ) {
    final headers = _gameLogHeaders(sport);
    final rows = <List<dynamic>>[
      ['Player: $playerName'],
      headers,
      for (final g in gameLog) _gameLogRow(g, sport),
    ];
    return _csvConverter.convert(rows);
  }

  // ── File I/O ─────────────────────────────────────────────────────────

  /// Save [csvContent] to a file in the documents directory and return the
  /// full file path.
  static Future<String> saveToFile(
    String csvContent,
    String fileName,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvContent);
    return file.path;
  }

  /// Save [csvContent] to a temporary file and share it via the platform
  /// share sheet.
  static Future<void> shareCsv(
    String csvContent,
    String fileName,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvContent);
    await Share.shareXFiles([XFile(file.path)]);
  }

  // ── Private helpers ──────────────────────────────────────────────────

  static List<String> _seasonHeaders(String sport) {
    return switch (sport.toLowerCase()) {
      'volleyball' => [
          'Player', 'GP', 'K', 'E', 'TA', 'Hit%',
          'A', 'SA', 'SE', 'D', 'BS', 'BA', 'TB', 'Pts',
        ],
      'basketball' => [
          'Player', 'GP', 'PTS', 'FGM', 'FGA', 'FG%',
          '3PM', '3PA', '3P%', 'FTM', 'FTA', 'FT%',
          'ORB', 'DRB', 'REB', 'AST', 'STL', 'BLK', 'TO',
        ],
      'baseball' || 'slowpitch' => [
          'Player', 'GP', 'AB', 'R', 'H', '2B', '3B', 'HR',
          'RBI', 'BB', 'SO', 'AVG', 'OBP', 'SLG',
        ],
      'football' => [
          'Player', 'GP', 'COMP', 'ATT', 'YDS', 'TD', 'INT',
          'RUSH_ATT', 'RUSH_YDS', 'RUSH_TD',
          'REC', 'REC_YDS', 'REC_TD', 'TACKLES', 'SACKS',
        ],
      _ => ['Player', 'GP', 'Stats'],
    };
  }

  static List<dynamic> _seasonRow(
    PlayerSeasonStatsModel s,
    String sport,
    Map<String, String> playerNames,
  ) {
    final name = playerNames[s.playerId] ?? s.playerId;
    final t = s.statsTotals;
    final m = s.computedMetrics;

    return switch (sport.toLowerCase()) {
      'volleyball' => [
          name, s.gamesPlayed,
          t['kills'] ?? 0, t['errors'] ?? 0, t['totalAttempts'] ?? 0,
          _fmt(m['hittingPercentage']),
          t['assists'] ?? 0, t['serviceAces'] ?? 0, t['serviceErrors'] ?? 0,
          t['digs'] ?? 0, t['blockSolos'] ?? 0, t['blockAssists'] ?? 0,
          t['totalBlocks'] ?? 0, t['points'] ?? 0,
        ],
      'basketball' => [
          name, s.gamesPlayed,
          t['points'] ?? 0, t['fgm'] ?? 0, t['fga'] ?? 0,
          _fmt(m['fgPct']),
          t['threePm'] ?? 0, t['threePa'] ?? 0, _fmt(m['threePct']),
          t['ftm'] ?? 0, t['fta'] ?? 0, _fmt(m['ftPct']),
          t['orb'] ?? 0, t['drb'] ?? 0, t['reb'] ?? 0,
          t['ast'] ?? 0, t['stl'] ?? 0, t['blk'] ?? 0, t['turnovers'] ?? 0,
        ],
      'baseball' || 'slowpitch' => [
          name, s.gamesPlayed,
          t['atBats'] ?? 0, t['runs'] ?? 0, t['hits'] ?? 0,
          t['doubles'] ?? 0, t['triples'] ?? 0, t['homeRuns'] ?? 0,
          t['rbi'] ?? 0, t['walks'] ?? 0, t['strikeouts'] ?? 0,
          _fmt(m['avg']), _fmt(m['obp']), _fmt(m['slg']),
        ],
      'football' => [
          name, s.gamesPlayed,
          t['completions'] ?? 0, t['passAttempts'] ?? 0,
          t['passYards'] ?? 0, t['passTd'] ?? 0, t['interceptions'] ?? 0,
          t['rushAttempts'] ?? 0, t['rushYards'] ?? 0, t['rushTd'] ?? 0,
          t['receptions'] ?? 0, t['recYards'] ?? 0, t['recTd'] ?? 0,
          t['tackles'] ?? 0, t['sacks'] ?? 0,
        ],
      _ => [name, s.gamesPlayed, t.toString()],
    };
  }

  static List<String> _gameLogHeaders(String sport) {
    return switch (sport.toLowerCase()) {
      'volleyball' => [
          'Game', 'K', 'E', 'TA', 'Hit%',
          'A', 'SA', 'SE', 'D', 'BS', 'BA', 'TB', 'Pts',
        ],
      'basketball' => [
          'Game', 'PTS', 'FGM', 'FGA', 'FG%',
          '3PM', '3PA', '3P%', 'FTM', 'FTA', 'FT%',
          'ORB', 'DRB', 'REB', 'AST', 'STL', 'BLK', 'TO',
        ],
      'baseball' || 'slowpitch' => [
          'Game', 'AB', 'R', 'H', '2B', '3B', 'HR',
          'RBI', 'BB', 'SO', 'AVG', 'OBP', 'SLG',
        ],
      'football' => [
          'Game', 'COMP', 'ATT', 'YDS', 'TD', 'INT',
          'RUSH_ATT', 'RUSH_YDS', 'RUSH_TD',
          'REC', 'REC_YDS', 'REC_TD', 'TACKLES', 'SACKS',
        ],
      _ => ['Game', 'Stats'],
    };
  }

  static List<dynamic> _gameLogRow(PlayerGameStatsModel g, String sport) {
    final s = g.stats;
    final gameLabel = g.gameId;

    return switch (sport.toLowerCase()) {
      'volleyball' => [
          gameLabel,
          s['kills'] ?? 0, s['errors'] ?? 0, s['totalAttempts'] ?? 0,
          _fmt(s['hittingPercentage']),
          s['assists'] ?? 0, s['serviceAces'] ?? 0, s['serviceErrors'] ?? 0,
          s['digs'] ?? 0, s['blockSolos'] ?? 0, s['blockAssists'] ?? 0,
          s['totalBlocks'] ?? 0, s['points'] ?? 0,
        ],
      'basketball' => [
          gameLabel,
          s['points'] ?? 0, s['fgm'] ?? 0, s['fga'] ?? 0,
          _fmt(s['fgPct']),
          s['threePm'] ?? 0, s['threePa'] ?? 0, _fmt(s['threePct']),
          s['ftm'] ?? 0, s['fta'] ?? 0, _fmt(s['ftPct']),
          s['orb'] ?? 0, s['drb'] ?? 0, s['reb'] ?? 0,
          s['ast'] ?? 0, s['stl'] ?? 0, s['blk'] ?? 0, s['turnovers'] ?? 0,
        ],
      'baseball' || 'slowpitch' => [
          gameLabel,
          s['atBats'] ?? 0, s['runs'] ?? 0, s['hits'] ?? 0,
          s['doubles'] ?? 0, s['triples'] ?? 0, s['homeRuns'] ?? 0,
          s['rbi'] ?? 0, s['walks'] ?? 0, s['strikeouts'] ?? 0,
          _fmt(s['avg']), _fmt(s['obp']), _fmt(s['slg']),
        ],
      'football' => [
          gameLabel,
          s['completions'] ?? 0, s['passAttempts'] ?? 0,
          s['passYards'] ?? 0, s['passTd'] ?? 0, s['interceptions'] ?? 0,
          s['rushAttempts'] ?? 0, s['rushYards'] ?? 0, s['rushTd'] ?? 0,
          s['receptions'] ?? 0, s['recYards'] ?? 0, s['recTd'] ?? 0,
          s['tackles'] ?? 0, s['sacks'] ?? 0,
        ],
      _ => [gameLabel, s.toString()],
    };
  }

  /// Format a numeric value to 3 decimal places (e.g. batting average) or
  /// return an empty string when null.
  static String _fmt(dynamic value) {
    if (value == null) return '';
    if (value is num) return value.toStringAsFixed(3);
    return value.toString();
  }
}
