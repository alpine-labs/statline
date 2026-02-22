import 'package:flutter_test/flutter_test.dart';
import 'package:statline/domain/models/game.dart';
import 'package:statline/domain/models/player_stats.dart';
import 'package:statline/domain/sports/volleyball/volleyball_stats.dart';
import 'package:statline/presentation/providers/dashboard_insights_provider.dart';

void main() {
  final now = DateTime.now();

  // ── Test helpers ─────────────────────────────────────────────────────────

  PlayerSeasonStatsModel makeStat({
    required String playerId,
    int kills = 0,
    int errors = 0,
    int totalAttempts = 0,
    int aces = 0,
    int digs = 0,
    int blockSolos = 0,
    int blockAssists = 0,
    int points = 0,
    int gamesPlayed = 5,
    double hittingPct = 0.0,
  }) {
    return PlayerSeasonStatsModel(
      id: 'ss_$playerId',
      seasonId: 's1',
      playerId: playerId,
      sport: 'volleyball',
      gamesPlayed: gamesPlayed,
      statsTotals: {
        'kills': kills,
        'errors': errors,
        'totalAttempts': totalAttempts,
        'serviceAces': aces,
        'serviceErrors': 2,
        'digs': digs,
        'blockSolos': blockSolos,
        'blockAssists': blockAssists,
        'receptionErrors': 0,
        'points': points,
      },
      statsAverages: {},
      computedMetrics: {'hittingPercentage': hittingPct},
      computedAt: now,
    );
  }

  Game makeGame({
    required String id,
    required String opponent,
    required GameResult result,
    int daysAgo = 0,
    bool isHome = true,
  }) {
    return Game(
      id: id,
      seasonId: 's1',
      teamId: 't1',
      opponentName: opponent,
      gameDate: now.subtract(Duration(days: daysAgo)),
      isHome: isHome,
      sport: 'volleyball',
      gameFormat: {'setsToWin': 3, 'maxSets': 5, 'pointsPerSet': 25},
      status: GameStatus.completed,
      finalScoreUs: result == GameResult.win ? 3 : 1,
      finalScoreThem: result == GameResult.win ? 1 : 3,
      result: result,
      createdAt: now,
      updatedAt: now,
    );
  }

  PlayerGameStatsModel makeGameStatRow({
    required String gameId,
    required String playerId,
    int kills = 10,
    int errors = 3,
    int totalAttempts = 25,
  }) {
    return PlayerGameStatsModel(
      id: '${gameId}_$playerId',
      gameId: gameId,
      playerId: playerId,
      sport: 'volleyball',
      stats: {
        'kills': kills,
        'errors': errors,
        'totalAttempts': totalAttempts,
      },
      computedAt: now,
    );
  }

  // ── VolleyballStats thresholds ──────────────────────────────────────────

  group('VolleyballStats thresholds', () {
    test('threshold constants have correct values', () {
      expect(VolleyballStats.hittingPctGood, 0.250);
      expect(VolleyballStats.hittingPctAverage, 0.150);
      expect(VolleyballStats.hittingPctPoor, 0.100);
      expect(VolleyballStats.serviceErrorsHighPerGame, 5.0);
    });

    test('computeTeamHittingPercentage aggregates across players', () {
      final stats = [
        makeStat(playerId: 'p1', kills: 40, errors: 10, totalAttempts: 100),
        makeStat(playerId: 'p2', kills: 20, errors: 5, totalAttempts: 50),
      ];
      // (60 - 15) / 150 = 0.3
      expect(
        VolleyballStats.computeTeamHittingPercentage(stats),
        closeTo(0.300, 0.001),
      );
    });

    test('computeTeamHittingPercentage returns 0 for empty list', () {
      expect(VolleyballStats.computeTeamHittingPercentage([]), 0.0);
    });

    test('computeTeamHittingPercentage returns 0 when attempts are 0', () {
      final stats = [
        makeStat(playerId: 'p1', kills: 0, errors: 0, totalAttempts: 0),
      ];
      expect(VolleyballStats.computeTeamHittingPercentage(stats), 0.0);
    });
  });

  // ── Efficiency Trend ────────────────────────────────────────────────────

  group('computeEfficiencyTrend', () {
    test('correct hitting % for each game', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 3),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.loss, daysAgo: 2),
        makeGame(id: 'g3', opponent: 'C', result: GameResult.win, daysAgo: 1),
      ];
      final gameStats = [
        makeGameStatRow(gameId: 'g1', playerId: 'p1', kills: 10, errors: 2, totalAttempts: 30),
        makeGameStatRow(gameId: 'g2', playerId: 'p1', kills: 5, errors: 5, totalAttempts: 20),
        makeGameStatRow(gameId: 'g3', playerId: 'p1', kills: 8, errors: 1, totalAttempts: 25),
      ];

      final result = computeEfficiencyTrend(games, gameStats);

      expect(result.length, 3);
      // g1: (10-2)/30 = 0.2667
      expect(result[0].hittingPct, closeTo(0.267, 0.001));
      // g2: (5-5)/20 = 0.0
      expect(result[1].hittingPct, closeTo(0.0, 0.001));
      // g3: (8-1)/25 = 0.28
      expect(result[2].hittingPct, closeTo(0.280, 0.001));
    });

    test('rolling average starts at game 3', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 5),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.loss, daysAgo: 3),
        makeGame(id: 'g3', opponent: 'C', result: GameResult.win, daysAgo: 1),
      ];
      final gameStats = [
        makeGameStatRow(gameId: 'g1', playerId: 'p1', kills: 9, errors: 3, totalAttempts: 30),
        makeGameStatRow(gameId: 'g2', playerId: 'p1', kills: 6, errors: 3, totalAttempts: 30),
        makeGameStatRow(gameId: 'g3', playerId: 'p1', kills: 12, errors: 3, totalAttempts: 30),
      ];

      final result = computeEfficiencyTrend(games, gameStats);

      expect(result[0].rollingAvg, isNull);
      expect(result[1].rollingAvg, isNull);
      expect(result[2].rollingAvg, isNotNull);
      // (0.2 + 0.1 + 0.3) / 3 = 0.2
      expect(result[2].rollingAvg!, closeTo(0.200, 0.001));
    });

    test('handles less than 3 games', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 1),
      ];
      final gameStats = [
        makeGameStatRow(gameId: 'g1', playerId: 'p1'),
      ];

      final result = computeEfficiencyTrend(games, gameStats);
      expect(result.length, 1);
      expect(result[0].rollingAvg, isNull);
    });

    test('limits to 10 most recent games', () {
      final games = List.generate(
        15,
        (i) => makeGame(
          id: 'g$i',
          opponent: 'Team $i',
          result: GameResult.win,
          daysAgo: 15 - i,
        ),
      );
      final gameStats = games.map((g) =>
        makeGameStatRow(gameId: g.id, playerId: 'p1'),
      ).toList();

      final result = computeEfficiencyTrend(games, gameStats);
      expect(result.length, 10);
    });

    test('empty games returns empty list', () {
      expect(computeEfficiencyTrend([], []), isEmpty);
    });

    test('win/loss state is preserved', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 2),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.loss, daysAgo: 1),
        makeGame(id: 'g3', opponent: 'C', result: GameResult.win, daysAgo: 0),
      ];
      final gameStats = games.map((g) =>
        makeGameStatRow(gameId: g.id, playerId: 'p1'),
      ).toList();

      final result = computeEfficiencyTrend(games, gameStats);
      expect(result[0].isWin, true);
      expect(result[1].isWin, false);
      expect(result[2].isWin, true);
    });
  });

  // ── Points Source ───────────────────────────────────────────────────────

  group('computePointsSource', () {
    test('correct breakdown from season totals', () {
      final stats = [
        makeStat(playerId: 'p1', kills: 40, aces: 8, blockSolos: 3, blockAssists: 2, points: 60),
        makeStat(playerId: 'p2', kills: 20, aces: 4, blockSolos: 1, blockAssists: 1, points: 30),
      ];

      final result = computePointsSource(stats);

      expect(result.kills, 60);
      expect(result.aces, 12);
      expect(result.blocks, 7); // 3+2+1+1
      expect(result.opponentErrors, 11); // 90 - (60+12+7) = 11
      expect(result.total, 90);
    });

    test('handles zero points', () {
      final stats = [
        makeStat(playerId: 'p1', kills: 0, aces: 0, blockSolos: 0, blockAssists: 0, points: 0),
      ];

      final result = computePointsSource(stats);

      expect(result.total, 0);
      expect(result.killsPct, 0.0);
      expect(result.acesPct, 0.0);
    });

    test('empty stats returns all zeros', () {
      final result = computePointsSource([]);

      expect(result.total, 0);
      expect(result.kills, 0);
      expect(result.aces, 0);
      expect(result.blocks, 0);
      expect(result.opponentErrors, 0);
    });

    test('percentages sum to ~1.0', () {
      final stats = [
        makeStat(playerId: 'p1', kills: 50, aces: 10, blockSolos: 5, blockAssists: 5, points: 80),
      ];

      final result = computePointsSource(stats);
      final sum = result.killsPct + result.acesPct + result.blocksPct + result.opponentErrorsPct;
      expect(sum, closeTo(1.0, 0.001));
    });

    test('opponent errors cannot be negative', () {
      // If direct points > total points (shouldn't happen but edge case)
      final stats = [
        makeStat(playerId: 'p1', kills: 50, aces: 10, blockSolos: 5, blockAssists: 5, points: 60),
      ];

      final result = computePointsSource(stats);
      expect(result.opponentErrors, 0); // clamped to 0
    });
  });

  // ── Player Contribution ─────────────────────────────────────────────────

  group('computePlayerContributions', () {
    test('returns top 5 by kills', () {
      final stats = List.generate(8, (i) => makeStat(
        playerId: 'p$i',
        kills: (8 - i) * 5,
        digs: 10,
        aces: 3,
      ));

      String getName(String id) => 'Player $id';
      final result = computePlayerContributions(stats, getName);

      expect(result.length, 5);
      expect(result[0].kills, 40);
      expect(result[4].kills, 20);
    });

    test('handles single player', () {
      final stats = [
        makeStat(playerId: 'p1', kills: 30, digs: 15, aces: 5),
      ];

      String getName(String id) => 'Solo';
      final result = computePlayerContributions(stats, getName);

      expect(result.length, 1);
      expect(result[0].playerName, 'Solo');
      expect(result[0].kills, 30);
      expect(result[0].digs, 15);
      expect(result[0].aces, 5);
    });

    test('handles empty stats', () {
      final result = computePlayerContributions([], (id) => '');
      expect(result, isEmpty);
    });

    test('all zeros produces results', () {
      final stats = [
        makeStat(playerId: 'p1', kills: 0, digs: 0, aces: 0),
        makeStat(playerId: 'p2', kills: 0, digs: 0, aces: 0),
      ];

      final result = computePlayerContributions(stats, (id) => id);
      expect(result.length, 2);
      expect(result[0].kills, 0);
    });

    test('correctly uses player names from resolver', () {
      final stats = [
        makeStat(playerId: 'p1', kills: 10, digs: 5, aces: 2),
      ];

      final result = computePlayerContributions(stats, (id) => 'TestName');
      expect(result[0].playerName, 'TestName');
    });
  });
}
