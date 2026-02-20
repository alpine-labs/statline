import '../domain/models/player_stats.dart';

/// Formats player season stats as readable plain text for email bodies.
class StatsEmailFormatter {
  StatsEmailFormatter._();

  static String formatPlayerStats(
    PlayerSeasonStatsModel stats,
    String playerName,
    String sport,
  ) {
    final t = stats.statsTotals;
    final m = stats.computedMetrics;
    final buf = StringBuffer();

    buf.writeln('Hi $playerName,');
    buf.writeln();
    buf.writeln('Here are your season stats:');
    buf.writeln();
    buf.writeln('Games Played: ${stats.gamesPlayed}');

    switch (sport.toLowerCase()) {
      case 'volleyball':
        buf.writeln('Kills: ${t['kills'] ?? 0}');
        buf.writeln('Errors: ${t['errors'] ?? 0}');
        buf.writeln('Total Attempts: ${t['totalAttempts'] ?? 0}');
        buf.writeln('Hitting %: ${_pct(m['hittingPercentage'])}');
        buf.writeln('Assists: ${t['assists'] ?? 0}');
        buf.writeln('Service Aces: ${t['serviceAces'] ?? 0}');
        buf.writeln('Service Errors: ${t['serviceErrors'] ?? 0}');
        buf.writeln('Digs: ${t['digs'] ?? 0}');
        buf.writeln('Block Solos: ${t['blockSolos'] ?? 0}');
        buf.writeln('Block Assists: ${t['blockAssists'] ?? 0}');
        buf.writeln('Total Blocks: ${t['totalBlocks'] ?? 0}');
        buf.writeln('Points: ${t['points'] ?? 0}');
        break;
      default:
        for (final entry in t.entries) {
          buf.writeln('${entry.key}: ${entry.value}');
        }
    }

    buf.writeln();
    buf.writeln('— Sent from StatLine');
    return buf.toString();
  }

  static String _pct(dynamic value) {
    if (value == null) return '---';
    if (value is num) return value.toStringAsFixed(3);
    return value.toString();
  }
}
