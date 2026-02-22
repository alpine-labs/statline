import 'package:statline/domain/models/game.dart';
import 'package:statline/domain/models/game_lineup.dart';
import 'package:statline/domain/models/game_period.dart';
import 'package:statline/domain/models/play_event.dart';
import 'package:statline/domain/sports/sport_game_engine.dart';

/// A fake [SportGameEngine] for testing generic game logic
/// without volleyball coupling.
class FakeSportGameEngine implements SportGameEngine {
  final Map<String, dynamic> _initialState;
  final List<PlayEvent> recordedEvents = [];

  FakeSportGameEngine({
    Map<String, dynamic>? initialState,
  }) : _initialState = initialState ??
            {
              'servingTeam': 'us',
            };

  @override
  Map<String, dynamic> initialState({
    required Game game,
    required List<GameLineup> lineup,
  }) {
    return Map<String, dynamic>.from(_initialState);
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
    recordedEvents.add(event);
    return Map<String, dynamic>.from(sportState);
  }

  @override
  Map<String, dynamic> onPeriodAdvanced({
    required int newPeriodNumber,
    required Map<String, dynamic> sportState,
  }) {
    return Map<String, dynamic>.from(sportState);
  }

  @override
  GameResult determineWinner(List<GamePeriod> periods) {
    int totalUs = 0;
    int totalThem = 0;
    for (final p in periods) {
      totalUs += p.scoreUs;
      totalThem += p.scoreThem;
    }
    if (totalUs > totalThem) return GameResult.win;
    if (totalThem > totalUs) return GameResult.loss;
    return GameResult.tie;
  }

  @override
  ({int scoreUs, int scoreThem}) finalScore(List<GamePeriod> periods) {
    int totalUs = 0;
    int totalThem = 0;
    for (final p in periods) {
      totalUs += p.scoreUs;
      totalThem += p.scoreThem;
    }
    return (scoreUs: totalUs, scoreThem: totalThem);
  }

  @override
  bool canSubstitute(Map<String, dynamic> sportState) => true;

  @override
  int get maxTimeoutsPerPeriod => 2;

  @override
  String get periodType => 'period';

  @override
  String? getActivePlayerId(
      Map<String, dynamic> sportState, List<GameLineup> lineup) {
    return null;
  }
}
