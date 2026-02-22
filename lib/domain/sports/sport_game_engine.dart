import '../models/game.dart';
import '../models/game_lineup.dart';
import '../models/game_period.dart';
import '../models/play_event.dart';

/// Abstract interface for sport-specific live game logic.
///
/// Each sport implements this to handle its own state machine (rotation,
/// serve tracking, batting order, etc.) without leaking into the shared
/// [LiveGameNotifier].
abstract class SportGameEngine {
  /// Initial sport-specific state when a game starts.
  Map<String, dynamic> initialState({
    required Game game,
    required List<GameLineup> lineup,
  });

  /// Called when an event is recorded. Returns updated sport state.
  Map<String, dynamic> onEventRecorded({
    required PlayEvent event,
    required Map<String, dynamic> sportState,
    required int scoreUs,
    required int scoreThem,
    required int prevScoreUs,
    required int prevScoreThem,
    required List<GameLineup> lineup,
  });

  /// Called when a period advances. Returns updated sport state.
  Map<String, dynamic> onPeriodAdvanced({
    required int newPeriodNumber,
    required Map<String, dynamic> sportState,
  });

  /// Determine the game winner from period scores.
  /// Returns [GameResult.win], [GameResult.loss], or [GameResult.tie].
  GameResult determineWinner(List<GamePeriod> periods);

  /// Final score values for the game (e.g., sets won for volleyball).
  ({int scoreUs, int scoreThem}) finalScore(List<GamePeriod> periods);

  /// Whether a substitution can be made given current sport state.
  bool canSubstitute(Map<String, dynamic> sportState);

  /// Maximum timeouts per period for this sport.
  int get maxTimeoutsPerPeriod;

  /// The period type label (e.g., 'set' for volleyball, 'inning' for baseball).
  String get periodType;

  /// Returns the player ID who should serve/bat next, or null if not applicable.
  String? getActivePlayerId(Map<String, dynamic> sportState, List<GameLineup> lineup);
}
