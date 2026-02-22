import '../../models/play_event.dart';
import '../../models/player_stats.dart';

/// Volleyball-specific stat calculation helpers.
class VolleyballStats {
  VolleyballStats._();

  // ── Hitting % thresholds ─────────────────────────────────────────────────
  static const double hittingPctGood = 0.250;
  static const double hittingPctAverage = 0.150;
  static const double hittingPctPoor = 0.100;

  // ── Service error thresholds (per game) ──────────────────────────────────
  static const double serviceErrorsHighPerGame = 5.0;
  static const double serviceErrorsModeratePerGame = 3.0;

  /// Aggregate team hitting percentage from all players' season totals.
  static double computeTeamHittingPercentage(
      List<PlayerSeasonStatsModel> stats) {
    int totalKills = 0;
    int totalErrors = 0;
    int totalAttempts = 0;
    for (final s in stats) {
      totalKills += (s.statsTotals['kills'] as num?)?.toInt() ?? 0;
      totalErrors += (s.statsTotals['errors'] as num?)?.toInt() ?? 0;
      totalAttempts += (s.statsTotals['totalAttempts'] as num?)?.toInt() ?? 0;
    }
    return computeHittingPercentage(totalKills, totalErrors, totalAttempts);
  }

  /// Hitting percentage: (kills - errors) / attempts.
  /// Returns 0.0 if attempts is 0.
  static double computeHittingPercentage(int kills, int errors, int attempts) {
    if (attempts == 0) return 0.0;
    return (kills - errors) / attempts;
  }

  /// Pass rating on a 0.00–3.00 scale from a list of individual ratings.
  /// Returns 0.0 if ratings is empty.
  static double computePassRating(List<double> ratings) {
    if (ratings.isEmpty) return 0.0;
    final sum = ratings.fold<double>(0.0, (a, b) => a + b);
    return sum / ratings.length;
  }

  /// Perfect pass percentage: pass_3_count / total receptions.
  /// Returns 0.0 if totalReceptions is 0.
  static double computePerfectPassPercentage(int pass3Count, int totalReceptions) {
    if (totalReceptions == 0) return 0.0;
    return pass3Count / totalReceptions;
  }

  /// Serve efficiency: (aces - serveErrors) / serveAttempts.
  /// Returns 0.0 if serveAttempts is 0.
  static double computeServeEfficiency(int aces, int serveErrors, int serveAttempts) {
    if (serveAttempts == 0) return 0.0;
    return (aces - serveErrors) / serveAttempts;
  }

  /// Side-out percentage: points scored on opponent's serve / opponent serve attempts.
  static double computeSideOutPercentage(
      int pointsScoredOnOpponentServe, int opponentServeAttempts) {
    if (opponentServeAttempts == 0) return 0.0;
    return pointsScoredOnOpponentServe / opponentServeAttempts;
  }

  /// Total points contributed: kills + aces + blockSolos + (blockAssists * 0.5).
  static double computePoints(
      int kills, int aces, int blockSolos, int blockAssists) {
    return (kills + aces + blockSolos + blockAssists * 0.5);
  }

  /// Aggregate stats from a list of play events for a single player.
  /// If [playerId] is null, aggregates for all events (team stats).
  static Map<String, dynamic> aggregateFromEvents(
    List<PlayEvent> events, {
    String? playerId,
    bool isOpponent = false,
  }) {
    final filtered = events.where((e) {
      if (e.isDeleted) return false;
      if (isOpponent) return e.isOpponent;
      if (!isOpponent && e.isOpponent) return false;
      if (playerId != null) return e.playerId == playerId;
      return true;
    }).toList();

    int kills = 0;
    int attackErrors = 0;
    int attackAttempts = 0;
    int oppKills = 0;
    int oppErrors = 0;
    int oppAttempts = 0;
    int aces = 0;
    int serveErrors = 0;
    int servesInPlay = 0;
    int blockSolos = 0;
    int blockAssists = 0;
    int blockErrors = 0;
    int digs = 0;
    int digErrors = 0;
    int assists = 0;
    int setErrors = 0;
    int passAttempts = 0;
    int pass3Count = 0;
    int overpasses = 0;
    final List<double> passRatings = [];

    for (final event in filtered) {
      switch (event.eventType) {
        // Attack
        case 'kill':
          kills++;
          attackAttempts++;
          break;
        case 'attack_error':
          attackErrors++;
          attackAttempts++;
          break;
        case 'blocked':
          attackErrors++;
          attackAttempts++;
          break;
        case 'zero_attack':
          attackAttempts++;
          break;
        // Serve
        case 'ace':
          aces++;
          break;
        case 'serve_error':
          serveErrors++;
          break;
        case 'serve_in_play':
          servesInPlay++;
          break;
        // Block
        case 'block_solo':
          blockSolos++;
          break;
        case 'block_assist':
          blockAssists++;
          break;
        case 'block_error':
          blockErrors++;
          break;
        // Dig
        case 'dig':
          digs++;
          break;
        case 'dig_error':
          digErrors++;
          break;
        // Set
        case 'set_assist':
          assists++;
          break;
        case 'set_error':
          setErrors++;
          break;
        // Pass
        case 'pass_3':
          passRatings.add(3.0);
          passAttempts++;
          pass3Count++;
          break;
        case 'pass_2':
          passRatings.add(2.0);
          passAttempts++;
          break;
        case 'pass_1':
          passRatings.add(1.0);
          passAttempts++;
          break;
        case 'pass_0':
          passRatings.add(0.0);
          passAttempts++;
          break;
        case 'overpass':
          overpasses++;
          passRatings.add(0.0);
          passAttempts++;
          break;
        case 'pass_error':
          passRatings.add(0.0);
          passAttempts++;
          break;
        // Opponent events
        case 'opp_kill':
          oppKills++;
          oppAttempts++;
          break;
        case 'opp_error':
          oppErrors++;
          oppAttempts++;
          break;
        case 'opp_attempt':
          oppAttempts++;
          break;
      }
    }

    final totalBlocks = blockSolos + blockAssists;
    final oppHittingPct =
        computeHittingPercentage(oppKills, oppErrors, oppAttempts);
    final serveAttempts = aces + serveErrors + servesInPlay;
    final hittingPct =
        computeHittingPercentage(kills, attackErrors, attackAttempts);
    final passRating = computePassRating(passRatings);
    final perfectPassPct = computePerfectPassPercentage(pass3Count, passAttempts);
    final serveEfficiency = computeServeEfficiency(aces, serveErrors, serveAttempts);
    final points = computePoints(kills, aces, blockSolos, blockAssists);

    return {
      'kills': kills,
      'errors': attackErrors,
      'totalAttempts': attackAttempts,
      'hittingPercentage': hittingPct,
      'serviceAces': aces,
      'serviceErrors': serveErrors,
      'servesInPlay': servesInPlay,
      'blockSolos': blockSolos,
      'blockAssists': blockAssists,
      'blockErrors': blockErrors,
      'totalBlocks': totalBlocks,
      'digs': digs,
      'digErrors': digErrors,
      'assists': assists,
      'setErrors': setErrors,
      'passAttempts': passAttempts,
      'pass3Count': pass3Count,
      'passRating': passRating,
      'perfectPassPct': perfectPassPct,
      'serveAttempts': serveAttempts,
      'serveEfficiency': serveEfficiency,
      'points': points,
      'oppKills': oppKills,
      'oppErrors': oppErrors,
      'oppAttempts': oppAttempts,
      'oppHittingPct': oppHittingPct,
      'overpasses': overpasses,
    };
  }
}
