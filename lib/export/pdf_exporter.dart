import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../domain/models/game.dart';
import '../domain/models/game_period.dart';
import '../domain/models/season.dart';
import '../domain/models/stats.dart';

/// Generates professional PDF reports for games and seasons.
class PdfExporter {
  PdfExporter._();

  static final _dateFormat = DateFormat('MMM d, yyyy');

  // ── Game report ──────────────────────────────────────────────────────

  /// Generate a game summary PDF and return its bytes.
  static Future<Uint8List> generateGameReport({
    required Game game,
    required List<GamePeriod> periods,
    required List<PlayerGameStatsModel> playerStats,
    required String teamName,
    required String sport,
    Map<String, String> playerNames = const {},
  }) async {
    final pdf = pw.Document(
      title: '$teamName vs ${game.opponentName}',
      author: 'StatLine',
    );

    final headers = _boxScoreHeaders(sport);
    final dataRows = playerStats.map((s) {
      return _boxScoreRow(s, sport, playerNames);
    }).toList();

    // Compute team totals by summing numeric columns.
    final totals = _computeTotals(dataRows, headers.length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ── Header ────────────────────────────────────────────────
          pw.Center(
            child: pw.Text(
              '$teamName vs ${game.opponentName}',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              '${_dateFormat.format(game.gameDate)}'
              '${game.location != null ? '  •  ${game.location}' : ''}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ),
          if (game.finalScoreUs != null && game.finalScoreThem != null) ...[
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Final: ${game.finalScoreUs} – ${game.finalScoreThem}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],

          // ── Score by period ────────────────────────────────────────
          if (periods.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _periodTable(periods, teamName, game.opponentName, sport),
          ],

          // ── Box score ─────────────────────────────────────────────
          pw.SizedBox(height: 16),
          pw.Text(
            'Box Score',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          _statsTable(headers, dataRows, totals),

          // ── Notes ─────────────────────────────────────────────────
          if (game.notes != null && game.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Notes',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(game.notes!, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ── Season report ────────────────────────────────────────────────────

  /// Generate a season summary PDF and return its bytes.
  static Future<Uint8List> generateSeasonReport({
    required String teamName,
    required Season season,
    required List<Game> games,
    required List<PlayerSeasonStatsModel> stats,
    required String sport,
    Map<String, String> playerNames = const {},
  }) async {
    final pdf = pw.Document(
      title: '$teamName – ${season.name}',
      author: 'StatLine',
    );

    // Win / loss / tie record
    int wins = 0, losses = 0, ties = 0;
    for (final g in games) {
      switch (g.result) {
        case GameResult.win:
          wins++;
        case GameResult.loss:
          losses++;
        case GameResult.tie:
          ties++;
        case null:
          break;
      }
    }
    final record = ties > 0 ? '$wins-$losses-$ties' : '$wins-$losses';

    final headers = _seasonHeaders(sport);
    final dataRows = stats.map((s) {
      return _seasonRow(s, sport, playerNames);
    }).toList();
    final totals = _computeTotals(dataRows, headers.length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ── Header ────────────────────────────────────────────────
          pw.Center(
            child: pw.Text(
              teamName,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              '${season.name}  •  Record: $record',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ),

          // ── Season stats table ────────────────────────────────────
          pw.SizedBox(height: 16),
          pw.Text(
            'Season Statistics',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          _statsTable(headers, dataRows, totals),

          // ── Game results ──────────────────────────────────────────
          pw.SizedBox(height: 20),
          pw.Text(
            'Game Results',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          ...games.map(
            (g) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${_dateFormat.format(g.gameDate)}  –  '
                      '${g.isHome ? 'vs' : '@'} ${g.opponentName}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    g.finalScoreUs != null && g.finalScoreThem != null
                        ? '${g.finalScoreUs}-${g.finalScoreThem}'
                            '${g.result != null ? ' (${g.result!.name.toUpperCase()[0]})' : ''}'
                        : g.status.name,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Top performers ────────────────────────────────────────
          if (stats.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Top Performers',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            ..._topPerformers(stats, sport, playerNames).map(
              (line) => pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ── File I/O ─────────────────────────────────────────────────────────

  /// Save PDF bytes to a file and return the full path.
  static Future<String> saveToFile(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Save PDF bytes to a temp file and share via the platform share sheet.
  static Future<void> sharePdf(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  // ── Private helpers ──────────────────────────────────────────────────

  /// Build a pw.Table showing scores by period / set / inning.
  static pw.Widget _periodTable(
    List<GamePeriod> periods,
    String teamName,
    String opponentName,
    String sport,
  ) {
    final periodLabel = switch (sport.toLowerCase()) {
      'volleyball' => 'Set',
      'basketball' || 'football' => 'Q',
      'baseball' || 'slowpitch' => 'Inn',
      _ => 'P',
    };

    final sorted = List<GamePeriod>.from(periods)
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.center,
      headerAlignment: pw.Alignment.center,
      headers: [
        '',
        ...sorted.map((p) => '$periodLabel ${p.periodNumber}'),
        'Total',
      ],
      data: [
        [
          teamName,
          ...sorted.map((p) => '${p.scoreUs}'),
          '${sorted.fold<int>(0, (sum, p) => sum + p.scoreUs)}',
        ],
        [
          opponentName,
          ...sorted.map((p) => '${p.scoreThem}'),
          '${sorted.fold<int>(0, (sum, p) => sum + p.scoreThem)}',
        ],
      ],
    );
  }

  /// Build a box-score / stats table with totals row.
  static pw.Widget _statsTable(
    List<String> headers,
    List<List<dynamic>> dataRows,
    List<dynamic> totals,
  ) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.center,
      headerAlignment: pw.Alignment.center,
      headers: headers,
      data: [
        ...dataRows,
        totals,
      ],
    );
  }

  /// Sum numeric columns for a totals row. The first column becomes "TOTALS".
  static List<dynamic> _computeTotals(
    List<List<dynamic>> rows,
    int columnCount,
  ) {
    final totals = List<dynamic>.filled(columnCount, '');
    totals[0] = 'TOTALS';
    for (int col = 1; col < columnCount; col++) {
      num sum = 0;
      bool allNumeric = true;
      for (final row in rows) {
        final val = col < row.length ? row[col] : null;
        if (val is num) {
          sum += val;
        } else {
          allNumeric = false;
          break;
        }
      }
      totals[col] = allNumeric ? sum : '';
    }
    return totals;
  }

  static List<String> _boxScoreHeaders(String sport) {
    return switch (sport.toLowerCase()) {
      'volleyball' => [
          'Player', 'K', 'E', 'TA', 'Hit%',
          'A', 'SA', 'SE', 'D', 'BS', 'BA', 'TB', 'Pts',
        ],
      'basketball' => [
          'Player', 'PTS', 'FGM', 'FGA', 'FG%',
          '3PM', '3PA', '3P%', 'FTM', 'FTA', 'FT%',
          'REB', 'AST', 'STL', 'BLK', 'TO',
        ],
      'baseball' || 'slowpitch' => [
          'Player', 'AB', 'R', 'H', '2B', '3B', 'HR',
          'RBI', 'BB', 'SO',
        ],
      'football' => [
          'Player', 'COMP', 'ATT', 'YDS', 'TD', 'INT',
          'RUSH_YDS', 'RUSH_TD', 'REC', 'REC_YDS', 'REC_TD',
          'TACKLES', 'SACKS',
        ],
      _ => ['Player', 'Stats'],
    };
  }

  static List<dynamic> _boxScoreRow(
    PlayerGameStatsModel g,
    String sport,
    Map<String, String> playerNames,
  ) {
    final name = playerNames[g.playerId] ?? g.playerId;
    final s = g.stats;

    return switch (sport.toLowerCase()) {
      'volleyball' => [
          name,
          s['kills'] ?? 0, s['errors'] ?? 0, s['totalAttempts'] ?? 0,
          _fmt(s['hittingPercentage']),
          s['assists'] ?? 0, s['serviceAces'] ?? 0, s['serviceErrors'] ?? 0,
          s['digs'] ?? 0, s['blockSolos'] ?? 0, s['blockAssists'] ?? 0,
          s['totalBlocks'] ?? 0, s['points'] ?? 0,
        ],
      'basketball' => [
          name,
          s['points'] ?? 0, s['fgm'] ?? 0, s['fga'] ?? 0,
          _fmt(s['fgPct']),
          s['threePm'] ?? 0, s['threePa'] ?? 0, _fmt(s['threePct']),
          s['ftm'] ?? 0, s['fta'] ?? 0, _fmt(s['ftPct']),
          s['reb'] ?? 0, s['ast'] ?? 0, s['stl'] ?? 0, s['blk'] ?? 0,
          s['turnovers'] ?? 0,
        ],
      'baseball' || 'slowpitch' => [
          name,
          s['atBats'] ?? 0, s['runs'] ?? 0, s['hits'] ?? 0,
          s['doubles'] ?? 0, s['triples'] ?? 0, s['homeRuns'] ?? 0,
          s['rbi'] ?? 0, s['walks'] ?? 0, s['strikeouts'] ?? 0,
        ],
      'football' => [
          name,
          s['completions'] ?? 0, s['passAttempts'] ?? 0,
          s['passYards'] ?? 0, s['passTd'] ?? 0, s['interceptions'] ?? 0,
          s['rushYards'] ?? 0, s['rushTd'] ?? 0,
          s['receptions'] ?? 0, s['recYards'] ?? 0, s['recTd'] ?? 0,
          s['tackles'] ?? 0, s['sacks'] ?? 0,
        ],
      _ => [name, s.toString()],
    };
  }

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

  /// Highlight lines for top performers in a season.
  static List<String> _topPerformers(
    List<PlayerSeasonStatsModel> stats,
    String sport,
    Map<String, String> playerNames,
  ) {
    final lines = <String>[];
    if (stats.isEmpty) return lines;

    String nameOf(PlayerSeasonStatsModel s) =>
        playerNames[s.playerId] ?? s.playerId;

    switch (sport.toLowerCase()) {
      case 'volleyball':
        final byKills = List<PlayerSeasonStatsModel>.from(stats)
          ..sort((a, b) =>
              (b.statsTotals['kills'] ?? 0)
                  .compareTo(a.statsTotals['kills'] ?? 0));
        lines.add('Kills leader: ${nameOf(byKills.first)} '
            '(${byKills.first.statsTotals['kills'] ?? 0})');
        final byAces = List<PlayerSeasonStatsModel>.from(stats)
          ..sort((a, b) =>
              (b.statsTotals['serviceAces'] ?? 0)
                  .compareTo(a.statsTotals['serviceAces'] ?? 0));
        lines.add('Aces leader: ${nameOf(byAces.first)} '
            '(${byAces.first.statsTotals['serviceAces'] ?? 0})');
      case 'basketball':
        final byPts = List<PlayerSeasonStatsModel>.from(stats)
          ..sort((a, b) =>
              (b.statsTotals['points'] ?? 0)
                  .compareTo(a.statsTotals['points'] ?? 0));
        lines.add('Points leader: ${nameOf(byPts.first)} '
            '(${byPts.first.statsTotals['points'] ?? 0})');
        final byReb = List<PlayerSeasonStatsModel>.from(stats)
          ..sort((a, b) =>
              (b.statsTotals['reb'] ?? 0)
                  .compareTo(a.statsTotals['reb'] ?? 0));
        lines.add('Rebounds leader: ${nameOf(byReb.first)} '
            '(${byReb.first.statsTotals['reb'] ?? 0})');
      case 'baseball' || 'slowpitch':
        final byHits = List<PlayerSeasonStatsModel>.from(stats)
          ..sort((a, b) =>
              (b.statsTotals['hits'] ?? 0)
                  .compareTo(a.statsTotals['hits'] ?? 0));
        lines.add('Hits leader: ${nameOf(byHits.first)} '
            '(${byHits.first.statsTotals['hits'] ?? 0})');
        final byHR = List<PlayerSeasonStatsModel>.from(stats)
          ..sort((a, b) =>
              (b.statsTotals['homeRuns'] ?? 0)
                  .compareTo(a.statsTotals['homeRuns'] ?? 0));
        lines.add('HR leader: ${nameOf(byHR.first)} '
            '(${byHR.first.statsTotals['homeRuns'] ?? 0})');
      default:
        break;
    }

    return lines;
  }

  static String _fmt(dynamic value) {
    if (value == null) return '';
    if (value is num) return value.toStringAsFixed(3);
    return value.toString();
  }
}
