import 'package:flutter_test/flutter_test.dart';
import 'package:statline/domain/sports/volleyball/volleyball_plugin.dart';
import 'package:statline/domain/sports/sport_plugin.dart';
import 'package:statline/domain/models/game_period.dart';
import 'package:statline/domain/models/play_event.dart';

/// Tests the SportPlugin contract via VolleyballPlugin.
/// Every future sport plugin must pass an equivalent set of tests.
void main() {
  late VolleyballPlugin plugin;

  setUp(() {
    plugin = VolleyballPlugin();
  });

  group('SportPlugin identity', () {
    test('sportId returns volleyball', () {
      expect(plugin.sportId, 'volleyball');
    });

    test('displayName returns Volleyball', () {
      expect(plugin.displayName, 'Volleyball');
    });

    test('icon is not null', () {
      expect(plugin.icon, isNotNull);
    });
  });

  group('Event definitions', () {
    test('eventCategories is non-empty', () {
      expect(plugin.eventCategories, isNotEmpty);
    });

    test('quickModeEvents is non-empty', () {
      expect(plugin.quickModeEvents, isNotEmpty);
    });

    test('every event type has an id and category', () {
      for (final category in plugin.eventCategories) {
        expect(category.id, isNotEmpty);
        expect(category.label, isNotEmpty);
        for (final eventType in category.eventTypes) {
          expect(eventType.id, isNotEmpty);
          expect(eventType.category, equals(category.id));
        }
      }
    });

    test('quick mode events are a subset of all events', () {
      final allIds = plugin.eventCategories
          .expand((c) => c.eventTypes)
          .map((e) => e.id)
          .toSet();
      final quickIds = plugin.quickModeEvents
          .expand((c) => c.eventTypes)
          .map((e) => e.id)
          .toSet();
      expect(allIds.containsAll(quickIds), isTrue);
    });
  });

  group('defaultGameFormat', () {
    test('contains required keys', () {
      final format = plugin.defaultGameFormat;
      expect(format, contains('sets_to_win'));
      expect(format, contains('points_per_set'));
      expect(format, contains('deciding_set_points'));
      expect(format, contains('min_advantage'));
    });

    test('values are positive integers', () {
      final format = plugin.defaultGameFormat;
      expect(format['sets_to_win'], isA<int>());
      expect((format['sets_to_win'] as int), greaterThan(0));
      expect((format['points_per_set'] as int), greaterThan(0));
    });
  });

  group('computeGameStats', () {
    test('returns zero stats for empty events', () {
      final stats = plugin.computeGameStats([]);
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['kills'], 0);
      expect(stats['points'], 0.0);
    });

    test('correctly counts kills', () {
      final events = [
        _makeEvent('kill', 'attack', 'point_us'),
        _makeEvent('kill', 'attack', 'point_us'),
        _makeEvent('attack_error', 'attack', 'point_them'),
      ];
      final stats = plugin.computeGameStats(events);
      expect(stats['kills'], 2);
      expect(stats['errors'], 1);
      expect(stats['totalAttempts'], 3);
    });

    test('filters deleted events', () {
      final events = [
        _makeEvent('kill', 'attack', 'point_us'),
        _makeEvent('kill', 'attack', 'point_us', isDeleted: true),
      ];
      final stats = plugin.computeGameStats(events);
      expect(stats['kills'], 1);
    });

    test('isOpponent flag aggregates opponent events', () {
      final events = [
        _makeEvent('opp_kill', 'opponent', 'point_them', isOpponent: true),
        _makeEvent('kill', 'attack', 'point_us'),
      ];
      final oppStats = plugin.computeGameStats(events, isOpponent: true);
      expect(oppStats['oppKills'], 1);
    });
  });

  group('computeSeasonMetrics', () {
    test('computes per-set metrics', () {
      final totals = {
        'kills': 40,
        'errors': 10,
        'totalAttempts': 100,
        'serviceAces': 5,
        'serviceErrors': 3,
        'servesInPlay': 42,
        'digs': 30,
        'totalBlocks': 8,
        'passRating': 6.0,
        'pass3Count': 10,
        'passAttempts': 20,
        'points': 55.0,
      };
      final metrics = plugin.computeSeasonMetrics(totals, 4, 16);
      expect(metrics['kills_per_set'], 2.5);
      expect(metrics['digs_per_set'], closeTo(1.875, 0.001));
    });

    test('handles zero totalSets gracefully', () {
      final totals = {'kills': 10, 'errors': 0, 'totalAttempts': 20};
      final metrics = plugin.computeSeasonMetrics(totals, 1, 0);
      expect(metrics, isA<Map<String, dynamic>>());
    });
  });

  group('Column definitions', () {
    test('gameStatsColumns is non-empty with valid StatColumns', () {
      expect(plugin.gameStatsColumns, isNotEmpty);
      for (final col in plugin.gameStatsColumns) {
        expect(col.key, isNotEmpty);
        expect(col.label, isNotEmpty);
        expect(col.shortLabel, isNotEmpty);
      }
    });

    test('seasonStatsColumns is superset of gameStatsColumns', () {
      expect(plugin.seasonStatsColumns.length,
          greaterThan(plugin.gameStatsColumns.length));
      final seasonKeys = plugin.seasonStatsColumns.map((c) => c.key).toSet();
      for (final col in plugin.gameStatsColumns) {
        expect(seasonKeys, contains(col.key));
      }
    });
  });

  group('isPeriodOver', () {
    final format = {
      'sets_to_win': 3,
      'points_per_set': 25,
      'deciding_set_points': 15,
      'min_advantage': 2,
    };

    test('standard set not over at 24-20', () {
      final period = GamePeriod(
          id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
          scoreUs: 24, scoreThem: 20);
      expect(plugin.isPeriodOver(period, format), isFalse);
    });

    test('standard set over at 25-20', () {
      final period = GamePeriod(
          id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
          scoreUs: 25, scoreThem: 20);
      expect(plugin.isPeriodOver(period, format), isTrue);
    });

    test('needs 2-point advantage at 25-24', () {
      final period = GamePeriod(
          id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
          scoreUs: 25, scoreThem: 24);
      expect(plugin.isPeriodOver(period, format), isFalse);
    });

    test('deuce resolved at 26-24', () {
      final period = GamePeriod(
          id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
          scoreUs: 26, scoreThem: 24);
      expect(plugin.isPeriodOver(period, format), isTrue);
    });

    test('deciding set (5th) uses 15 points', () {
      final period = GamePeriod(
          id: 'p5', gameId: 'g1', periodNumber: 5, periodType: 'set',
          scoreUs: 15, scoreThem: 10);
      expect(plugin.isPeriodOver(period, format), isTrue);
    });

    test('deciding set needs 2-point advantage at 15-14', () {
      final period = GamePeriod(
          id: 'p5', gameId: 'g1', periodNumber: 5, periodType: 'set',
          scoreUs: 15, scoreThem: 14);
      expect(plugin.isPeriodOver(period, format), isFalse);
    });

    test('0-0 set is not over', () {
      final period = GamePeriod(
          id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
          scoreUs: 0, scoreThem: 0);
      expect(plugin.isPeriodOver(period, format), isFalse);
    });
  });

  group('isGameOver', () {
    final format = {
      'sets_to_win': 3,
      'points_per_set': 25,
      'deciding_set_points': 15,
      'min_advantage': 2,
    };

    test('game not over after 2 sets won by same team', () {
      final periods = [
        GamePeriod(id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
            scoreUs: 25, scoreThem: 20),
        GamePeriod(id: 'p2', gameId: 'g1', periodNumber: 2, periodType: 'set',
            scoreUs: 25, scoreThem: 18),
      ];
      expect(plugin.isGameOver(periods, format), isFalse);
    });

    test('game over when home team wins 3 sets', () {
      final periods = [
        GamePeriod(id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
            scoreUs: 25, scoreThem: 20),
        GamePeriod(id: 'p2', gameId: 'g1', periodNumber: 2, periodType: 'set',
            scoreUs: 20, scoreThem: 25),
        GamePeriod(id: 'p3', gameId: 'g1', periodNumber: 3, periodType: 'set',
            scoreUs: 25, scoreThem: 22),
        GamePeriod(id: 'p4', gameId: 'g1', periodNumber: 4, periodType: 'set',
            scoreUs: 25, scoreThem: 19),
      ];
      expect(plugin.isGameOver(periods, format), isTrue);
    });

    test('game over when opponent wins 3 sets', () {
      final periods = [
        GamePeriod(id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
            scoreUs: 20, scoreThem: 25),
        GamePeriod(id: 'p2', gameId: 'g1', periodNumber: 2, periodType: 'set',
            scoreUs: 25, scoreThem: 20),
        GamePeriod(id: 'p3', gameId: 'g1', periodNumber: 3, periodType: 'set',
            scoreUs: 18, scoreThem: 25),
        GamePeriod(id: 'p4', gameId: 'g1', periodNumber: 4, periodType: 'set',
            scoreUs: 22, scoreThem: 25),
      ];
      expect(plugin.isGameOver(periods, format), isTrue);
    });

    test('best-of-3: game over after 2 wins', () {
      final bo3Format = {
        'sets_to_win': 2,
        'points_per_set': 21,
        'deciding_set_points': 15,
        'min_advantage': 2,
      };
      final periods = [
        GamePeriod(id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set',
            scoreUs: 21, scoreThem: 15),
        GamePeriod(id: 'p2', gameId: 'g1', periodNumber: 2, periodType: 'set',
            scoreUs: 21, scoreThem: 18),
      ];
      expect(plugin.isGameOver(periods, bo3Format), isTrue);
    });

    test('no periods means game not over', () {
      expect(plugin.isGameOver([], format), isFalse);
    });
  });

  group('periodLabel', () {
    test('returns "Set N"', () {
      final period = GamePeriod(
          id: 'p1', gameId: 'g1', periodNumber: 3, periodType: 'set');
      expect(plugin.periodLabel(period), 'Set 3');
    });
  });

  group('createNextPeriod', () {
    test('first period is number 1', () {
      final period = plugin.createNextPeriod('g1', [], {});
      expect(period.periodNumber, 1);
      expect(period.gameId, 'g1');
      expect(period.periodType, 'set');
      expect(period.scoreUs, 0);
      expect(period.scoreThem, 0);
    });

    test('next period increments number', () {
      final existing = [
        GamePeriod(id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set'),
        GamePeriod(id: 'p2', gameId: 'g1', periodNumber: 2, periodType: 'set'),
      ];
      final period = plugin.createNextPeriod('g1', existing, {});
      expect(period.periodNumber, 3);
    });

    test('generated periods have unique ids', () {
      final p1 = plugin.createNextPeriod('g1', [], {});
      final p2 = plugin.createNextPeriod('g1', [p1], {});
      expect(p1.id, isNot(equals(p2.id)));
    });
  });
}

int _eventCounter = 0;

PlayEvent _makeEvent(
  String eventType,
  String category,
  String result, {
  bool isDeleted = false,
  bool isOpponent = false,
  String playerId = 'player1',
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
    result: result,
    scoreUsAfter: 0,
    scoreThemAfter: 0,
    isOpponent: isOpponent,
    isDeleted: isDeleted,
    metadata: {},
    createdAt: DateTime(2025, 1, 1),
  );
}
