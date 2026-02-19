/// Structured summary of a completed game.
///
/// Powers the dashboard last-game card and future sharing features.
class GameSummary {
  final String gameId;
  final String opponentName;
  final String result; // 'win', 'loss', 'tie'
  final int setsWonUs;
  final int setsWonThem;
  final List<({int scoreUs, int scoreThem})> setScores;
  final String? mvpPlayerId;
  final String? mvpPlayerName;
  final double mvpPoints;
  final Map<String, ({String playerId, String playerName, dynamic value})>
      topPerformers;
  final List<String> notableStats;

  const GameSummary({
    required this.gameId,
    required this.opponentName,
    required this.result,
    required this.setsWonUs,
    required this.setsWonThem,
    required this.setScores,
    this.mvpPlayerId,
    this.mvpPlayerName,
    this.mvpPoints = 0,
    this.topPerformers = const {},
    this.notableStats = const [],
  });

  @override
  String toString() {
    return 'GameSummary(gameId: $gameId, opponent: $opponentName, '
        'result: $result, sets: $setsWonUs-$setsWonThem, '
        'mvp: $mvpPlayerName)';
  }
}
