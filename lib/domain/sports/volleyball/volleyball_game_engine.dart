import '../../models/game.dart';
import '../../models/game_lineup.dart';
import '../../models/game_period.dart';
import '../../models/play_event.dart';
import '../sport_game_engine.dart';

/// Volleyball-specific live game engine.
///
/// Handles rotation (R1–R6), serve tracking, side-out detection,
/// first-ball side-out tracking, libero state, and substitution limits.
class VolleyballGameEngine implements SportGameEngine {
  @override
  Map<String, dynamic> initialState({
    required Game game,
    required List<GameLineup> lineup,
  }) {
    return {
      'currentRotation': 1,
      'servingTeam': 'us',
      'liberoPlayerId': null,
      'liberoIsIn': false,
      'liberoReplacedPlayerId': null,
      'firstBallSideouts': 0,
      'totalSideouts': 0,
      'sideoutOpportunities': 0,
      'inFirstBallSequence': false,
      'attacksSinceReception': 0,
      'subsThisSet': 0,
      'maxSubsPerSet': 15,
    };
  }

  @override
  Map<String, dynamic> onEventRecorded({
    required PlayEvent event,
    required Map<String, dynamic> sportState,
    required int scoreUs,
    required int scoreThem,
    required int prevScoreUs,
    required int prevScoreThem,
    required List<GameLineup> lineup,
  }) {
    final state = Map<String, dynamic>.from(sportState);
    final servingTeam = state['servingTeam'] as String?;

    // ── First-ball sideout tracking ──
    bool inFirstBall = state['inFirstBallSequence'] as bool? ?? false;
    int attacks = state['attacksSinceReception'] as int? ?? 0;
    int firstBallSideouts = state['firstBallSideouts'] as int? ?? 0;
    int totalSideouts = state['totalSideouts'] as int? ?? 0;
    int sideoutOpps = state['sideoutOpportunities'] as int? ?? 0;

    if (_isReceptionEvent(event.eventType)) {
      inFirstBall = true;
      attacks = 0;
    }
    if (_isAttackEvent(event.eventType)) {
      attacks++;
    }
    if (event.eventType == 'dig' || event.eventType == 'dig_error') {
      inFirstBall = false;
    }

    // ── Score changes, serving team toggle, auto-rotate ──
    String? newServingTeam = servingTeam;
    int rotation = state['currentRotation'] as int? ?? 1;
    final scoredUs = scoreUs > prevScoreUs;
    final scoredThem = scoreThem > prevScoreThem;

    // Sideout opportunity: any point while opponent serves
    if (servingTeam == 'them' && (scoredUs || scoredThem)) {
      sideoutOpps++;
    }

    if (scoredUs && servingTeam == 'them') {
      // Side-out for us: we get serve, advance rotation
      newServingTeam = 'us';
      totalSideouts++;
      if (inFirstBall && attacks == 1) {
        firstBallSideouts++;
      }
      rotation = (rotation % 6) + 1;
    } else if (scoredThem && servingTeam == 'us') {
      // Side-out for them
      newServingTeam = 'them';
    }

    // Reset first-ball tracking on any point
    if (scoredUs || scoredThem) {
      inFirstBall = false;
      attacks = 0;
    }

    state['currentRotation'] = rotation;
    state['servingTeam'] = newServingTeam;
    state['firstBallSideouts'] = firstBallSideouts;
    state['totalSideouts'] = totalSideouts;
    state['sideoutOpportunities'] = sideoutOpps;
    state['inFirstBallSequence'] = inFirstBall;
    state['attacksSinceReception'] = attacks;

    return state;
  }

  @override
  Map<String, dynamic> onPeriodAdvanced({
    required int newPeriodNumber,
    required Map<String, dynamic> sportState,
  }) {
    final state = Map<String, dynamic>.from(sportState);
    final currentServing = state['servingTeam'] as String? ?? 'us';
    state['servingTeam'] = currentServing == 'us' ? 'them' : 'us';
    state['subsThisSet'] = 0;
    state['inFirstBallSequence'] = false;
    state['attacksSinceReception'] = 0;
    return state;
  }

  @override
  GameResult determineWinner(List<GamePeriod> periods) {
    int setsWonUs = 0;
    int setsWonThem = 0;
    for (final period in periods) {
      if (period.scoreUs > period.scoreThem) {
        setsWonUs++;
      } else if (period.scoreThem > period.scoreUs) {
        setsWonThem++;
      }
    }
    if (setsWonUs > setsWonThem) return GameResult.win;
    if (setsWonThem > setsWonUs) return GameResult.loss;
    return GameResult.tie;
  }

  @override
  ({int scoreUs, int scoreThem}) finalScore(List<GamePeriod> periods) {
    int setsWonUs = 0;
    int setsWonThem = 0;
    for (final period in periods) {
      if (period.scoreUs > period.scoreThem) {
        setsWonUs++;
      } else if (period.scoreThem > period.scoreUs) {
        setsWonThem++;
      }
    }
    return (scoreUs: setsWonUs, scoreThem: setsWonThem);
  }

  @override
  bool canSubstitute(Map<String, dynamic> sportState) {
    final subs = sportState['subsThisSet'] as int? ?? 0;
    final max = sportState['maxSubsPerSet'] as int? ?? 15;
    return subs < max;
  }

  @override
  int get maxTimeoutsPerPeriod => 2;

  @override
  String get periodType => 'set';

  @override
  String? getActivePlayerId(
      Map<String, dynamic> sportState, List<GameLineup> lineup) {
    final rotation = sportState['currentRotation'] as int?;
    if (rotation == null || lineup.isEmpty) return null;
    final match = lineup.where((l) => l.startingRotation == rotation);
    return match.isNotEmpty ? match.first.playerId : null;
  }

  // ── Volleyball-specific public methods ──

  /// Set the libero player.
  Map<String, dynamic> setLibero(Map<String, dynamic> sportState, String playerId) {
    final state = Map<String, dynamic>.from(sportState);
    state['liberoPlayerId'] = playerId;
    state['liberoIsIn'] = false;
    state['liberoReplacedPlayerId'] = null;
    return state;
  }

  /// Sub libero in for a back-row player.
  Map<String, dynamic> liberoIn(Map<String, dynamic> sportState, String replacedPlayerId) {
    final state = Map<String, dynamic>.from(sportState);
    if (state['liberoPlayerId'] == null) return state;
    state['liberoIsIn'] = true;
    state['liberoReplacedPlayerId'] = replacedPlayerId;
    return state;
  }

  /// Sub libero out.
  Map<String, dynamic> liberoOut(Map<String, dynamic> sportState) {
    final state = Map<String, dynamic>.from(sportState);
    state['liberoIsIn'] = false;
    state['liberoReplacedPlayerId'] = null;
    return state;
  }

  /// Manually rotate forward.
  Map<String, dynamic> rotateForward(Map<String, dynamic> sportState) {
    final state = Map<String, dynamic>.from(sportState);
    final current = state['currentRotation'] as int? ?? 1;
    state['currentRotation'] = current >= 6 ? 1 : current + 1;
    return state;
  }

  /// Manually rotate backward.
  Map<String, dynamic> rotateBackward(Map<String, dynamic> sportState) {
    final state = Map<String, dynamic>.from(sportState);
    final current = state['currentRotation'] as int? ?? 1;
    state['currentRotation'] = current <= 1 ? 6 : current - 1;
    return state;
  }

  /// Toggle serving team.
  Map<String, dynamic> toggleServe(Map<String, dynamic> sportState) {
    final state = Map<String, dynamic>.from(sportState);
    final current = state['servingTeam'] as String? ?? 'us';
    state['servingTeam'] = current == 'us' ? 'them' : 'us';
    return state;
  }

  /// Increment substitution counter.
  Map<String, dynamic> recordSubstitution(Map<String, dynamic> sportState) {
    final state = Map<String, dynamic>.from(sportState);
    final subs = state['subsThisSet'] as int? ?? 0;
    final max = state['maxSubsPerSet'] as int? ?? 15;
    if (subs < max) {
      state['subsThisSet'] = subs + 1;
    }
    return state;
  }

  // ── Private helpers ──

  static bool _isReceptionEvent(String eventType) {
    return const {'pass_3', 'pass_2', 'pass_1', 'pass_0', 'overpass', 'pass_error'}
        .contains(eventType);
  }

  static bool _isAttackEvent(String eventType) {
    return const {'kill', 'attack_error', 'blocked', 'zero_attack'}
        .contains(eventType);
  }
}
