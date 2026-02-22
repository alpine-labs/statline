import '../models/game.dart';
import '../models/game_period.dart';
import '../models/game_summary.dart';
import '../models/play_event.dart';
import '../models/player.dart';
import '../stats/stat_calculator.dart';

/// Generates a [GameSummary] from raw game data by delegating to
/// the sport-specific plugin.
class GameSummaryService {
  GameSummaryService._();

  static GameSummary generate({
    required Game game,
    required List<GamePeriod> periods,
    required List<PlayEvent> events,
    required List<Player> roster,
  }) {
    final plugin = StatCalculator.getSportPlugin(game.sport);
    return plugin.generateGameSummary(
      gameId: game.id,
      opponentName: game.opponentName,
      periods: periods,
      events: events,
      roster: roster,
    );
  }
}
