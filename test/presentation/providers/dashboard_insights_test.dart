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
    int serviceErrors = 2,
    int serveAttempts = 0,
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
        'serviceErrors': serviceErrors,
        'serveAttempts': serveAttempts,
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

  // ── Service Efficiency ──────────────────────────────────────────────────

  group('computeServiceEfficiency', () {
    test('computes from per-game stats', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 3),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.loss, daysAgo: 2),
      ];
      final gameStats = [
        PlayerGameStatsModel(
          id: 'gs1', gameId: 'g1', playerId: 'p1', sport: 'volleyball',
          stats: {'serviceAces': 4, 'serviceErrors': 2},
          computedAt: now,
        ),
        PlayerGameStatsModel(
          id: 'gs2', gameId: 'g2', playerId: 'p1', sport: 'volleyball',
          stats: {'serviceAces': 1, 'serviceErrors': 3},
          computedAt: now,
        ),
      ];

      final result = computeServiceEfficiency(games, [], gameStats);
      expect(result.length, 2);
      expect(result[0].aces, 4);
      expect(result[0].errors, 2);
      expect(result[0].isWin, true);
      expect(result[1].aces, 1);
      expect(result[1].errors, 3);
      expect(result[1].isWin, false);
    });

    test('approximates from season stats when no game stats', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 1),
      ];
      final seasonStats = [
        makeStat(playerId: 'p1', aces: 10, serviceErrors: 5, gamesPlayed: 5),
      ];

      final result = computeServiceEfficiency(games, seasonStats, []);
      expect(result.length, 1);
      // Should have derived approximation
      expect(result[0].gameLabel, contains('A'));
    });

    test('returns empty for no games', () {
      expect(computeServiceEfficiency([], [], []), isEmpty);
    });

    test('handles single game', () {
      final games = [
        makeGame(id: 'g1', opponent: 'X', result: GameResult.win, daysAgo: 1),
      ];
      final gameStats = [
        PlayerGameStatsModel(
          id: 'gs1', gameId: 'g1', playerId: 'p1', sport: 'volleyball',
          stats: {'serviceAces': 5, 'serviceErrors': 1},
          computedAt: now,
        ),
      ];

      final result = computeServiceEfficiency(games, [], gameStats);
      expect(result.length, 1);
      expect(result[0].aces, 5);
      expect(result[0].errors, 1);
    });
  });

  // ── Home vs Away ────────────────────────────────────────────────────────

  group('computeHomeAwayComparison', () {
    test('all home games', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, isHome: true),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.win, isHome: true),
      ];
      final stats = [
        makeStat(playerId: 'p1', kills: 20, errors: 5, totalAttempts: 50, aces: 8, digs: 30),
      ];

      final result = computeHomeAwayComparison(games, stats);
      expect(result.homeGames, 2);
      expect(result.awayGames, 0);
      expect(result.homeWinPct, 100.0);
      expect(result.awayWinPct, 0.0);
    });

    test('all away games', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.loss, isHome: false),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.win, isHome: false),
      ];
      final stats = [
        makeStat(playerId: 'p1', kills: 20, errors: 5, totalAttempts: 50, aces: 8, digs: 30),
      ];

      final result = computeHomeAwayComparison(games, stats);
      expect(result.homeGames, 0);
      expect(result.awayGames, 2);
      expect(result.awayWinPct, 50.0);
    });

    test('mixed home and away', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, isHome: true),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.loss, isHome: false),
        makeGame(id: 'g3', opponent: 'C', result: GameResult.win, isHome: true),
        makeGame(id: 'g4', opponent: 'D', result: GameResult.win, isHome: false),
      ];
      final stats = [
        makeStat(playerId: 'p1', kills: 40, errors: 10, totalAttempts: 100, aces: 12, digs: 50),
      ];

      final result = computeHomeAwayComparison(games, stats);
      expect(result.homeGames, 2);
      expect(result.awayGames, 2);
      expect(result.homeWinPct, 100.0);
      expect(result.awayWinPct, 50.0);
      expect(result.homeHittingPct, greaterThan(result.awayHittingPct));
      expect(result.homeAcesPerGame, greaterThan(result.awayAcesPerGame));
    });

    test('empty games returns zeros', () {
      final result = computeHomeAwayComparison([], []);
      expect(result.homeGames, 0);
      expect(result.awayGames, 0);
      expect(result.homeWinPct, 0.0);
      expect(result.awayWinPct, 0.0);
    });
  });

  // ── Needs Attention ─────────────────────────────────────────────────────

  group('computeNeedsAttention', () {
    test('detects critically low hitting %', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 1),
      ];
      final stats = [
        makeStat(
          playerId: 'p1',
          kills: 2,
          errors: 8,
          totalAttempts: 25,
          gamesPlayed: 5,
          hittingPct: -0.240,
        ),
      ];

      final result = computeNeedsAttention(games, stats, (id) => 'TestPlayer');
      expect(result.any((a) => a.message.contains('hitting%')), true);
      expect(result.any((a) => a.message.contains('TestPlayer')), true);
    });

    test('detects high service error rate', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 1),
      ];
      final stats = [
        makeStat(
          playerId: 'p1',
          aces: 5,
          serviceErrors: 15,
          serveAttempts: 80,
          gamesPlayed: 5,
        ),
      ];

      final result = computeNeedsAttention(games, stats, (id) => 'Player');
      expect(result.any((a) => a.message.contains('Service errors')), true);
    });

    test('detects losing streak', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.loss, daysAgo: 1),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.loss, daysAgo: 2),
        makeGame(id: 'g3', opponent: 'C', result: GameResult.loss, daysAgo: 3),
      ];

      final result = computeNeedsAttention(games, [], (id) => 'Player');
      expect(result.any((a) => a.message.contains('losing streak')), true);
    });

    test('detects zero kills player', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 1),
      ];
      final stats = [
        makeStat(
          playerId: 'p1',
          kills: 0,
          totalAttempts: 0,
          gamesPlayed: 5,
        ),
      ];

      final result = computeNeedsAttention(games, stats, (id) => 'Libero');
      expect(result.any((a) => a.message.contains("hasn't recorded a kill")), true);
      expect(result.any((a) => a.message.contains('Libero')), true);
    });

    test('returns empty when no issues', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 1),
      ];
      final stats = [
        makeStat(
          playerId: 'p1',
          kills: 20,
          errors: 5,
          totalAttempts: 50,
          aces: 5,
          serviceErrors: 2,
          serveAttempts: 40,
          gamesPlayed: 5,
          hittingPct: 0.300,
        ),
      ];

      final result = computeNeedsAttention(games, stats, (id) => 'Player');
      expect(result, isEmpty);
    });

    test('limits to max 3 alerts', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.loss, daysAgo: 1),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.loss, daysAgo: 2),
        makeGame(id: 'g3', opponent: 'C', result: GameResult.loss, daysAgo: 3),
      ];
      final stats = [
        makeStat(playerId: 'p1', kills: 2, errors: 8, totalAttempts: 25, aces: 2, serviceErrors: 15, serveAttempts: 80, gamesPlayed: 5),
        makeStat(playerId: 'p2', kills: 1, errors: 7, totalAttempts: 20, aces: 1, serviceErrors: 10, serveAttempts: 50, gamesPlayed: 5),
        makeStat(playerId: 'p3', kills: 0, totalAttempts: 0, gamesPlayed: 5),
      ];

      final result = computeNeedsAttention(games, stats, (id) => 'Player_$id');
      expect(result.length, lessThanOrEqualTo(3));
    });

    test('handles empty games', () {
      final result = computeNeedsAttention([], [], (id) => 'Player');
      expect(result, isEmpty);
    });
  });

  // ── Game Margin Classification ──────────────────────────────────────────

  group('VolleyballStats.classifyGameMargin', () {
    test('3-0 is blowout win', () {
      expect(VolleyballStats.classifyGameMargin(3, 0), 'blowoutWin');
    });

    test('3-1 is win', () {
      expect(VolleyballStats.classifyGameMargin(3, 1), 'win');
    });

    test('3-2 is win', () {
      expect(VolleyballStats.classifyGameMargin(3, 2), 'win');
    });

    test('2-3 is loss', () {
      expect(VolleyballStats.classifyGameMargin(2, 3), 'loss');
    });

    test('1-3 is loss', () {
      expect(VolleyballStats.classifyGameMargin(1, 3), 'loss');
    });

    test('0-3 is blowout loss', () {
      expect(VolleyballStats.classifyGameMargin(0, 3), 'blowoutLoss');
    });
  });

  // ── Game Margin Distribution ────────────────────────────────────────────

  group('computeGameMargin', () {
    test('all 4 categories', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win).copyWith(
          finalScoreUs: () => 3, finalScoreThem: () => 0),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.win).copyWith(
          finalScoreUs: () => 3, finalScoreThem: () => 1),
        makeGame(id: 'g3', opponent: 'C', result: GameResult.win).copyWith(
          finalScoreUs: () => 3, finalScoreThem: () => 2),
        makeGame(id: 'g4', opponent: 'D', result: GameResult.loss).copyWith(
          finalScoreUs: () => 2, finalScoreThem: () => 3),
        makeGame(id: 'g5', opponent: 'E', result: GameResult.loss).copyWith(
          finalScoreUs: () => 1, finalScoreThem: () => 3),
        makeGame(id: 'g6', opponent: 'F', result: GameResult.loss).copyWith(
          finalScoreUs: () => 0, finalScoreThem: () => 3),
      ];

      final result = computeGameMargin(games);
      expect(result.blowoutWins, 1);  // 3-0
      expect(result.wins, 2);          // 3-1, 3-2
      expect(result.losses, 2);        // 2-3, 1-3
      expect(result.blowoutLosses, 1); // 0-3
      expect(result.total, 6);
    });

    test('no completed games returns zeros', () {
      final result = computeGameMargin([]);
      expect(result.blowoutWins, 0);
      expect(result.wins, 0);
      expect(result.losses, 0);
      expect(result.blowoutLosses, 0);
      expect(result.total, 0);
    });

    test('skips games with 0-0 scores', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win).copyWith(
          finalScoreUs: () => 0, finalScoreThem: () => 0),
      ];

      final result = computeGameMargin(games);
      expect(result.total, 0);
    });
  });

  // ── Recent Form Data ────────────────────────────────────────────────────

  group('computeRecentForm', () {
    test('correct ordering newest first', () {
      final games = List.generate(5, (i) => makeGame(
        id: 'g$i',
        opponent: 'Team $i',
        result: i % 2 == 0 ? GameResult.win : GameResult.loss,
        daysAgo: i,
      ));
      final stats = [
        makeStat(playerId: 'p1', kills: 40, errors: 10, totalAttempts: 100,
            aces: 10, serviceErrors: 5, digs: 50, gamesPlayed: 5),
      ];

      final result = computeRecentForm(games, stats, []);
      expect(result.games.length, 5);
      // Newest first
      expect(result.games.first.opponent, 'Team 0');
      expect(result.games.last.opponent, 'Team 4');
    });

    test('returns empty when < 3 games', () {
      final games = [
        makeGame(id: 'g1', opponent: 'A', result: GameResult.win, daysAgo: 1),
        makeGame(id: 'g2', opponent: 'B', result: GameResult.loss, daysAgo: 2),
      ];
      final stats = [
        makeStat(playerId: 'p1', kills: 20, errors: 5, totalAttempts: 50),
      ];

      final result = computeRecentForm(games, stats, []);
      expect(result.games, isEmpty);
    });

    test('limits to 10 games', () {
      final games = List.generate(15, (i) => makeGame(
        id: 'g$i',
        opponent: 'Team $i',
        result: GameResult.win,
        daysAgo: i,
      ));
      final stats = [
        makeStat(playerId: 'p1', kills: 40, errors: 10, totalAttempts: 100,
            aces: 15, serviceErrors: 5, digs: 60, gamesPlayed: 15),
      ];

      final result = computeRecentForm(games, stats, []);
      expect(result.games.length, 10);
    });

    test('percentile thresholds computed correctly', () {
      final formData = RecentFormData(games: [
        const RecentFormGame(gameId: 'g1', opponent: 'A', isWin: true,
            hittingPct: 0.300, aces: 5, errors: 1, digs: 20),
        const RecentFormGame(gameId: 'g2', opponent: 'B', isWin: false,
            hittingPct: 0.100, aces: 1, errors: 5, digs: 10),
        const RecentFormGame(gameId: 'g3', opponent: 'C', isWin: true,
            hittingPct: 0.200, aces: 3, errors: 3, digs: 15),
      ]);

      final (low, high) = formData.thresholdsFor((g) => g.hittingPct);
      // Sorted: [0.100, 0.200, 0.300]
      // lowIdx = floor(3/3) = 1 → 0.200, highIdx = floor(6/3) = 2 → 0.300
      expect(low, closeTo(0.200, 0.001));
      expect(high, closeTo(0.300, 0.001));
    });

    test('empty games returns empty thresholds', () {
      const formData = RecentFormData(games: []);
      final (low, high) = formData.thresholdsFor((g) => g.hittingPct);
      expect(low, 0);
      expect(high, 0);
    });
  });
}
