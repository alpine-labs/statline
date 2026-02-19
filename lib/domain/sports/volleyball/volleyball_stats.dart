import '../../models/play_event.dart';

/// Volleyball-specific stat calculation helpers.
class VolleyballStats {
  VolleyballStats._();

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
        case 'pass_error':
          passRatings.add(0.0);
          passAttempts++;
          break;
        // Opponent events
        case 'opp_kill':
        case 'opp_error':
        case 'opp_attempt':
          break;
      }
    }

    final totalBlocks = blockSolos + blockAssists;
    final serveAttempts = aces + serveErrors + servesInPlay;
    final hittingPct =
        computeHittingPercentage(kills, attackErrors, attackAttempts);
    final passRating = computePassRating(passRatings);
    final perfectPassPct = computePerfectPassPercentage(pass3Count, passAttempts);
    final serveEfficiency = computeServeEfficiency(aces, serveErrors, serveAttempts);
    final points = computePoints(kills, aces, blockSolos, blockAssists);

    return {
      'kills': kills,
      'attack_errors': attackErrors,
      'attack_attempts': attackAttempts,
      'hitting_pct': hittingPct,
      'aces': aces,
      'serve_errors': serveErrors,
      'serves_in_play': servesInPlay,
      'block_solos': blockSolos,
      'block_assists': blockAssists,
      'block_errors': blockErrors,
      'total_blocks': totalBlocks,
      'digs': digs,
      'dig_errors': digErrors,
      'assists': assists,
      'set_errors': setErrors,
      'pass_attempts': passAttempts,
      'pass_3_count': pass3Count,
      'pass_rating': passRating,
      'perfect_pass_pct': perfectPassPct,
      'serve_attempts': serveAttempts,
      'serve_efficiency': serveEfficiency,
      'points': points,
    };
  }
}
