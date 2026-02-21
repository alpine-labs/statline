import 'package:flutter_test/flutter_test.dart';
import 'package:statline/domain/sports/volleyball/volleyball_stats.dart';
import 'package:statline/domain/models/play_event.dart';

void main() {
  group('computeHittingPercentage', () {
    test('normal case', () {
      expect(VolleyballStats.computeHittingPercentage(10, 3, 25),
          closeTo(0.28, 0.001));
    });

    test('zero attempts returns 0.0', () {
      expect(VolleyballStats.computeHittingPercentage(0, 0, 0), 0.0);
    });

    test('negative when errors > kills', () {
      expect(VolleyballStats.computeHittingPercentage(2, 5, 10),
          closeTo(-0.3, 0.001));
    });

    test('perfect hitting (all kills)', () {
      expect(VolleyballStats.computeHittingPercentage(10, 0, 10), 1.0);
    });
  });

  group('computePassRating', () {
    test('normal case', () {
      expect(VolleyballStats.computePassRating([3.0, 2.0, 1.0]),
          closeTo(2.0, 0.001));
    });

    test('empty returns 0.0', () {
      expect(VolleyballStats.computePassRating([]), 0.0);
    });

    test('all perfect passes', () {
      expect(VolleyballStats.computePassRating([3.0, 3.0, 3.0]), 3.0);
    });

    test('all shanks', () {
      expect(VolleyballStats.computePassRating([0.0, 0.0, 0.0]), 0.0);
    });
  });

  group('computePerfectPassPercentage', () {
    test('normal case', () {
      expect(VolleyballStats.computePerfectPassPercentage(5, 20),
          closeTo(0.25, 0.001));
    });

    test('zero receptions returns 0.0', () {
      expect(VolleyballStats.computePerfectPassPercentage(0, 0), 0.0);
    });

    test('all perfect', () {
      expect(VolleyballStats.computePerfectPassPercentage(10, 10), 1.0);
    });
  });

  group('computeServeEfficiency', () {
    test('normal case', () {
      expect(VolleyballStats.computeServeEfficiency(5, 3, 50),
          closeTo(0.04, 0.001));
    });

    test('zero attempts returns 0.0', () {
      expect(VolleyballStats.computeServeEfficiency(0, 0, 0), 0.0);
    });

    test('negative when errors > aces', () {
      expect(VolleyballStats.computeServeEfficiency(1, 5, 20),
          closeTo(-0.2, 0.001));
    });
  });

  group('computeSideOutPercentage', () {
    test('normal case', () {
      expect(VolleyballStats.computeSideOutPercentage(15, 25),
          closeTo(0.6, 0.001));
    });

    test('zero opponent serves returns 0.0', () {
      expect(VolleyballStats.computeSideOutPercentage(0, 0), 0.0);
    });
  });

  group('computePoints', () {
    test('normal case', () {
      // 10 kills + 3 aces + 2 solos + (4 assists * 0.5) = 17.0
      expect(VolleyballStats.computePoints(10, 3, 2, 4), 17.0);
    });

    test('zero everything', () {
      expect(VolleyballStats.computePoints(0, 0, 0, 0), 0.0);
    });
  });

  group('aggregateFromEvents', () {
    test('empty events returns zero stats', () {
      final stats = VolleyballStats.aggregateFromEvents([]);
      expect(stats['kills'], 0);
      expect(stats['errors'], 0);
      expect(stats['points'], 0.0);
      expect(stats['hittingPercentage'], 0.0);
    });

    test('filters deleted events', () {
      final events = [
        _makeEvent('kill', 'attack', playerId: 'p1'),
        _makeEvent('kill', 'attack', playerId: 'p1', isDeleted: true),
        _makeEvent('kill', 'attack', playerId: 'p1'),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events, playerId: 'p1');
      expect(stats['kills'], 2);
    });

    test('filters by playerId', () {
      final events = [
        _makeEvent('kill', 'attack', playerId: 'p1'),
        _makeEvent('kill', 'attack', playerId: 'p2'),
        _makeEvent('ace', 'serve', playerId: 'p1'),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events, playerId: 'p1');
      expect(stats['kills'], 1);
      expect(stats['serviceAces'], 1);
    });

    test('counts all attack types correctly', () {
      final events = [
        _makeEvent('kill', 'attack'),
        _makeEvent('kill', 'attack'),
        _makeEvent('attack_error', 'attack'),
        _makeEvent('blocked', 'attack'),
        _makeEvent('zero_attack', 'attack'),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['kills'], 2);
      expect(stats['errors'], 2); // attack_error + blocked
      expect(stats['totalAttempts'], 5);
      expect(stats['hittingPercentage'], closeTo(0.0, 0.001)); // (2-2)/5
    });

    test('counts serve events', () {
      final events = [
        _makeEvent('ace', 'serve'),
        _makeEvent('ace', 'serve'),
        _makeEvent('serve_error', 'serve'),
        _makeEvent('serve_in_play', 'serve'),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['serviceAces'], 2);
      expect(stats['serviceErrors'], 1);
      expect(stats['servesInPlay'], 1);
      expect(stats['serveAttempts'], 4);
    });

    test('counts block events', () {
      final events = [
        _makeEvent('block_solo', 'block'),
        _makeEvent('block_assist', 'block'),
        _makeEvent('block_assist', 'block'),
        _makeEvent('block_error', 'block'),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['blockSolos'], 1);
      expect(stats['blockAssists'], 2);
      expect(stats['blockErrors'], 1);
      expect(stats['totalBlocks'], 3);
    });

    test('counts pass events and computes ratings', () {
      final events = [
        _makeEvent('pass_3', 'pass'),
        _makeEvent('pass_2', 'pass'),
        _makeEvent('pass_1', 'pass'),
        _makeEvent('pass_0', 'pass'),
        _makeEvent('pass_error', 'pass'),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['passAttempts'], 5);
      expect(stats['pass3Count'], 1);
      expect(stats['passRating'], closeTo(1.2, 0.001)); // (3+2+1+0+0)/5
      expect(stats['perfectPassPct'], closeTo(0.2, 0.001)); // 1/5
    });

    test('counts dig and set events', () {
      final events = [
        _makeEvent('dig', 'dig'),
        _makeEvent('dig', 'dig'),
        _makeEvent('dig_error', 'dig'),
        _makeEvent('set_assist', 'set'),
        _makeEvent('set_error', 'set'),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['digs'], 2);
      expect(stats['digErrors'], 1);
      expect(stats['assists'], 1);
      expect(stats['setErrors'], 1);
    });

    test('opponent events aggregated with isOpponent flag', () {
      final events = [
        _makeEvent('opp_kill', 'opponent', isOpponent: true),
        _makeEvent('opp_error', 'opponent', isOpponent: true),
        _makeEvent('opp_attempt', 'opponent', isOpponent: true),
      ];
      final stats =
          VolleyballStats.aggregateFromEvents(events, isOpponent: true);
      expect(stats['oppKills'], 1);
      expect(stats['oppErrors'], 1);
      expect(stats['oppAttempts'], 3);
    });

    test('computes points from mixed events', () {
      final events = [
        _makeEvent('kill', 'attack'), // +1
        _makeEvent('kill', 'attack'), // +1
        _makeEvent('ace', 'serve'), // +1
        _makeEvent('block_solo', 'block'), // +1
        _makeEvent('block_assist', 'block'), // +0.5
        _makeEvent('block_assist', 'block'), // +0.5
        _makeEvent('dig', 'dig'), // +0
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['points'], 5.0);
    });

    test('counts overpass events separately from shank', () {
      final events = [
        _makeEvent('pass_0', 'pass'), // shank
        _makeEvent('overpass', 'pass'), // overpass
        _makeEvent('pass_3', 'pass'),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['passAttempts'], 3);
      expect(stats['overpasses'], 1);
      expect(stats['pass3Count'], 1);
      // Ratings: 0 + 0 + 3 = 3/3 = 1.0
      expect(stats['passRating'], closeTo(1.0, 0.001));
    });

    test('all events deleted returns zero stats', () {
      final events = [
        _makeEvent('kill', 'attack', isDeleted: true),
        _makeEvent('ace', 'serve', isDeleted: true),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['kills'], 0);
      expect(stats['serviceAces'], 0);
      expect(stats['points'], 0.0);
    });

    test('excludes opponent events from non-opponent aggregation', () {
      final events = [
        _makeEvent('kill', 'attack'),
        _makeEvent('opp_kill', 'opponent', isOpponent: true),
      ];
      final stats = VolleyballStats.aggregateFromEvents(events);
      expect(stats['kills'], 1);
      expect(stats['oppKills'], 0);
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
