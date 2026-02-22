import 'package:flutter_test/flutter_test.dart';
import 'package:statline/domain/stats/stat_calculator.dart';
import 'package:statline/domain/models/play_event.dart';

void main() {
  group('StatCalculator.getSportPlugin', () {
    test('returns plugin for volleyball', () {
      final plugin = StatCalculator.getSportPlugin('volleyball');
      expect(plugin.sportId, 'volleyball');
    });

    test('throws for unsupported sport', () {
      expect(
        () => StatCalculator.getSportPlugin('curling'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('StatCalculator.computePlayerGameStats', () {
    test('filters events to single player', () {
      final events = [
        _makeEvent('kill', 'attack', playerId: 'p1'),
        _makeEvent('kill', 'attack', playerId: 'p2'),
        _makeEvent('ace', 'serve', playerId: 'p1'),
      ];
      final stats =
          StatCalculator.computePlayerGameStats('volleyball', events, 'p1');
      expect(stats['kills'], 1);
      expect(stats['serviceAces'], 1);
    });

    test('excludes deleted events', () {
      final events = [
        _makeEvent('kill', 'attack', playerId: 'p1'),
        _makeEvent('kill', 'attack', playerId: 'p1', isDeleted: true),
      ];
      final stats =
          StatCalculator.computePlayerGameStats('volleyball', events, 'p1');
      expect(stats['kills'], 1);
    });

    test('excludes opponent events from player stats', () {
      final events = [
        _makeEvent('kill', 'attack', playerId: 'p1'),
        _makeEvent('opp_kill', 'opponent', playerId: 'p1', isOpponent: true),
      ];
      final stats =
          StatCalculator.computePlayerGameStats('volleyball', events, 'p1');
      expect(stats['kills'], 1);
    });

    test('returns zero stats for player with no events', () {
      final events = [
        _makeEvent('kill', 'attack', playerId: 'p1'),
      ];
      final stats =
          StatCalculator.computePlayerGameStats('volleyball', events, 'p2');
      expect(stats['kills'], 0);
    });
  });

  group('StatCalculator.computeTeamGameStats', () {
    test('aggregates all non-opponent events across players', () {
      final events = [
        _makeEvent('kill', 'attack', playerId: 'p1'),
        _makeEvent('kill', 'attack', playerId: 'p2'),
        _makeEvent('ace', 'serve', playerId: 'p3'),
      ];
      final stats = StatCalculator.computeTeamGameStats('volleyball', events);
      expect(stats['kills'], 2);
      expect(stats['serviceAces'], 1);
    });
  });

  group('StatCalculator.computePlayerSeasonStats', () {
    test('sums totals across multiple games', () {
      final gameStats = [
        {
          'kills': 10, 'errors': 3, 'totalAttempts': 25, 'points': 12.0,
          'serviceAces': 2, 'serviceErrors': 1, 'servesInPlay': 10,
          'digs': 5, 'totalBlocks': 3, 'passRating': 2.5,
          'pass3Count': 3, 'passAttempts': 8, 'sets_played': 4,
        },
        {
          'kills': 8, 'errors': 2, 'totalAttempts': 20, 'points': 10.0,
          'serviceAces': 1, 'serviceErrors': 2, 'servesInPlay': 8,
          'digs': 7, 'totalBlocks': 2, 'passRating': 2.0,
          'pass3Count': 2, 'passAttempts': 6, 'sets_played': 3,
        },
      ];

      final result = StatCalculator.computePlayerSeasonStats(
        id: 'season_p1',
        sport: 'volleyball',
        seasonId: 's1',
        playerId: 'p1',
        gameStatsList: gameStats,
        gamesPlayed: 2,
        totalSets: 7,
      );

      expect(result.gamesPlayed, 2);
      expect(result.statsTotals['kills'], 18);
      expect(result.statsTotals['errors'], 5);
      expect(result.statsTotals['totalAttempts'], 45);
      expect(result.statsAverages['kills'], 9.0);
    });

    test('recalculates season hittingPercentage from totals', () {
      final gameStats = [
        {
          'kills': 20, 'errors': 5, 'totalAttempts': 50, 'points': 25.0,
          'serviceAces': 4, 'serviceErrors': 2, 'servesInPlay': 14,
          'digs': 15, 'totalBlocks': 6, 'passRating': 2.5,
          'pass3Count': 5, 'passAttempts': 10, 'sets_played': 8,
          'blockSolos': 3, 'blockAssists': 3,
        },
      ];

      final result = StatCalculator.computePlayerSeasonStats(
        id: 'season_p1',
        sport: 'volleyball',
        seasonId: 's1',
        playerId: 'p1',
        gameStatsList: gameStats,
        gamesPlayed: 1,
        totalSets: 8,
      );

      // (20-5)/50 = 0.3
      expect(result.statsTotals['hittingPercentage'], closeTo(0.3, 0.001));
      expect(result.computedMetrics['kills_per_set'], 2.5); // 20/8
    });

    test('handles empty game stats list', () {
      final result = StatCalculator.computePlayerSeasonStats(
        id: 'season_p1',
        sport: 'volleyball',
        seasonId: 's1',
        playerId: 'p1',
        gameStatsList: [],
        gamesPlayed: 0,
        totalSets: 0,
      );

      expect(result.gamesPlayed, 0);
      // Season recalculation always produces hittingPercentage (0.0 from 0/0)
      expect(result.statsTotals['hittingPercentage'], 0.0);
    });
  });
}

int _eventCounter = 0;

PlayEvent _makeEvent(
  String eventType,
  String category, {
  String playerId = 'player1',
  bool isDeleted = false,
  bool isOpponent = false,
}) {
  _eventCounter++;
  return PlayEvent(
    id: 'e_$_eventCounter',
    gameId: 'g1',
    periodId: 'p1',
    sequenceNumber: _eventCounter,
    timestamp: DateTime(2025, 1, 1),
    playerId: playerId,
    eventCategory: category,
    eventType: eventType,
    result: 'point_us',
    scoreUsAfter: 0,
    scoreThemAfter: 0,
    isOpponent: isOpponent,
    isDeleted: isDeleted,
    metadata: {},
    createdAt: DateTime(2025, 1, 1),
  );
}
