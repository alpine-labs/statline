import 'package:flutter_test/flutter_test.dart';
import 'package:statline/domain/models/game.dart';
import 'package:statline/domain/models/game_lineup.dart';
import 'package:statline/domain/models/game_period.dart';
import 'package:statline/domain/models/play_event.dart';
import 'package:statline/domain/sports/volleyball/volleyball_game_engine.dart';

void main() {
  late VolleyballGameEngine engine;
  late Map<String, dynamic> state;

  final now = DateTime(2025, 6, 1);
  final game = Game(
    id: 'g1',
    seasonId: 's1',
    teamId: 't1',
    opponentName: 'Rival',
    gameDate: now,
    sport: 'volleyball',
    gameFormat: {'setsToWin': 3},
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    engine = VolleyballGameEngine();
    state = engine.initialState(game: game, lineup: []);
  });

  group('initialState', () {
    test('sets rotation to 1 and serving to us', () {
      expect(state['currentRotation'], 1);
      expect(state['servingTeam'], 'us');
    });

    test('initializes sideout tracking to zero', () {
      expect(state['firstBallSideouts'], 0);
      expect(state['totalSideouts'], 0);
      expect(state['sideoutOpportunities'], 0);
    });

    test('sets default sub limit', () {
      expect(state['maxSubsPerSet'], 15);
      expect(state['subsThisSet'], 0);
    });
  });

  group('onEventRecorded - serve tracking', () {
    test('serve stays when serving team scores', () {
      final event = _makeEvent('ace', 'serve', 'point_us');
      state = engine.onEventRecorded(
        event: event,
        sportState: state,
        scoreUs: 1,
        scoreThem: 0,
        prevScoreUs: 0,
        prevScoreThem: 0,
        lineup: [],
      );
      expect(state['servingTeam'], 'us');
    });

    test('serve transfers on sideout', () {
      // We serve, they score
      state = engine.onEventRecorded(
        event: _makeEvent('serve_error', 'serve', 'point_them'),
        sportState: state,
        scoreUs: 0,
        scoreThem: 1,
        prevScoreUs: 0,
        prevScoreThem: 0,
        lineup: [],
      );
      expect(state['servingTeam'], 'them');
    });
  });

  group('onEventRecorded - rotation', () {
    test('rotation advances on sideout for us', () {
      // First, lose serve
      state = engine.onEventRecorded(
        event: _makeEvent('serve_error', 'serve', 'point_them'),
        sportState: state,
        scoreUs: 0,
        scoreThem: 1,
        prevScoreUs: 0,
        prevScoreThem: 0,
        lineup: [],
      );
      expect(state['currentRotation'], 1); // no rotation for us losing serve

      // Sideout: we score while they serve
      state = engine.onEventRecorded(
        event: _makeEvent('kill', 'attack', 'point_us'),
        sportState: state,
        scoreUs: 1,
        scoreThem: 1,
        prevScoreUs: 0,
        prevScoreThem: 1,
        lineup: [],
      );
      expect(state['currentRotation'], 2);
      expect(state['servingTeam'], 'us');
    });

    test('rotation wraps from 6 to 1', () {
      state['currentRotation'] = 6;
      state['servingTeam'] = 'them';
      state = engine.onEventRecorded(
        event: _makeEvent('kill', 'attack', 'point_us'),
        sportState: state,
        scoreUs: 1,
        scoreThem: 0,
        prevScoreUs: 0,
        prevScoreThem: 0,
        lineup: [],
      );
      expect(state['currentRotation'], 1);
    });

    test('no rotation when serving team scores', () {
      state = engine.onEventRecorded(
        event: _makeEvent('ace', 'serve', 'point_us'),
        sportState: state,
        scoreUs: 1,
        scoreThem: 0,
        prevScoreUs: 0,
        prevScoreThem: 0,
        lineup: [],
      );
      expect(state['currentRotation'], 1);
    });
  });

  group('onEventRecorded - first-ball sideout', () {
    setUp(() {
      state['servingTeam'] = 'them';
    });

    test('detected on kill after reception', () {
      // Reception
      state = engine.onEventRecorded(
        event: _makeEvent('pass_3', 'pass', 'rally_continues'),
        sportState: state,
        scoreUs: 0,
        scoreThem: 1,
        prevScoreUs: 0,
        prevScoreThem: 1,
        lineup: [],
      );
      // Kill (first attack)
      state = engine.onEventRecorded(
        event: _makeEvent('kill', 'attack', 'point_us'),
        sportState: state,
        scoreUs: 1,
        scoreThem: 1,
        prevScoreUs: 0,
        prevScoreThem: 1,
        lineup: [],
      );
      expect(state['firstBallSideouts'], 1);
      expect(state['totalSideouts'], 1);
    });

    test('NOT detected when dig breaks sequence', () {
      state = engine.onEventRecorded(
        event: _makeEvent('pass_2', 'pass', 'rally_continues'),
        sportState: state,
        scoreUs: 0,
        scoreThem: 1,
        prevScoreUs: 0,
        prevScoreThem: 1,
        lineup: [],
      );
      state = engine.onEventRecorded(
        event: _makeEvent('dig', 'defense', 'rally_continues'),
        sportState: state,
        scoreUs: 0,
        scoreThem: 1,
        prevScoreUs: 0,
        prevScoreThem: 1,
        lineup: [],
      );
      state = engine.onEventRecorded(
        event: _makeEvent('kill', 'attack', 'point_us'),
        sportState: state,
        scoreUs: 1,
        scoreThem: 1,
        prevScoreUs: 0,
        prevScoreThem: 1,
        lineup: [],
      );
      expect(state['firstBallSideouts'], 0);
      expect(state['totalSideouts'], 1);
    });
  });

  group('onPeriodAdvanced', () {
    test('alternates serve', () {
      state = engine.onPeriodAdvanced(
          newPeriodNumber: 2, sportState: state);
      expect(state['servingTeam'], 'them');
      state = engine.onPeriodAdvanced(
          newPeriodNumber: 3, sportState: state);
      expect(state['servingTeam'], 'us');
    });

    test('resets subs', () {
      state['subsThisSet'] = 5;
      state = engine.onPeriodAdvanced(
          newPeriodNumber: 2, sportState: state);
      expect(state['subsThisSet'], 0);
    });
  });

  group('determineWinner', () {
    test('win when more sets won', () {
      final periods = [
        GamePeriod(id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set', scoreUs: 25, scoreThem: 20),
        GamePeriod(id: 'p2', gameId: 'g1', periodNumber: 2, periodType: 'set', scoreUs: 25, scoreThem: 18),
        GamePeriod(id: 'p3', gameId: 'g1', periodNumber: 3, periodType: 'set', scoreUs: 25, scoreThem: 22),
      ];
      expect(engine.determineWinner(periods), GameResult.win);
    });

    test('loss when fewer sets won', () {
      final periods = [
        GamePeriod(id: 'p1', gameId: 'g1', periodNumber: 1, periodType: 'set', scoreUs: 20, scoreThem: 25),
        GamePeriod(id: 'p2', gameId: 'g1', periodNumber: 2, periodType: 'set', scoreUs: 18, scoreThem: 25),
        GamePeriod(id: 'p3', gameId: 'g1', periodNumber: 3, periodType: 'set', scoreUs: 22, scoreThem: 25),
      ];
      expect(engine.determineWinner(periods), GameResult.loss);
    });
  });

  group('manual controls', () {
    test('rotateForward and rotateBackward', () {
      state = engine.rotateForward(state);
      expect(state['currentRotation'], 2);
      state = engine.rotateBackward(state);
      expect(state['currentRotation'], 1);
      state = engine.rotateBackward(state);
      expect(state['currentRotation'], 6);
    });

    test('toggleServe', () {
      state = engine.toggleServe(state);
      expect(state['servingTeam'], 'them');
      state = engine.toggleServe(state);
      expect(state['servingTeam'], 'us');
    });

    test('setLibero / liberoIn / liberoOut', () {
      state = engine.setLibero(state, 'p5');
      expect(state['liberoPlayerId'], 'p5');
      expect(state['liberoIsIn'], false);

      state = engine.liberoIn(state, 'p3');
      expect(state['liberoIsIn'], true);
      expect(state['liberoReplacedPlayerId'], 'p3');

      state = engine.liberoOut(state);
      expect(state['liberoIsIn'], false);
    });

    test('recordSubstitution respects limit', () {
      state['maxSubsPerSet'] = 2;
      state = engine.recordSubstitution(state);
      expect(state['subsThisSet'], 1);
      state = engine.recordSubstitution(state);
      expect(state['subsThisSet'], 2);
      state = engine.recordSubstitution(state);
      expect(state['subsThisSet'], 2); // capped
    });
  });

  group('getActivePlayerId', () {
    final lineup = [
      GameLineup(id: 'l1', gameId: 'g1', playerId: 'p1', position: 'OH', startingRotation: 1),
      GameLineup(id: 'l2', gameId: 'g1', playerId: 'p2', position: 'S', startingRotation: 2),
    ];

    test('returns player at current rotation', () {
      state['currentRotation'] = 1;
      expect(engine.getActivePlayerId(state, lineup), 'p1');
      state['currentRotation'] = 2;
      expect(engine.getActivePlayerId(state, lineup), 'p2');
    });

    test('returns null when no lineup', () {
      expect(engine.getActivePlayerId(state, []), isNull);
    });
  });
}

int _eventCounter = 0;

PlayEvent _makeEvent(String eventType, String category, String result) {
  _eventCounter++;
  return PlayEvent(
    id: 'e_$_eventCounter',
    gameId: 'g1',
    periodId: 'p1',
    sequenceNumber: _eventCounter,
    timestamp: DateTime(2025, 6, 1),
    playerId: 'p1',
    eventCategory: category,
    eventType: eventType,
    result: result,
    scoreUsAfter: 0,
    scoreThemAfter: 0,
    createdAt: DateTime(2025, 6, 1),
  );
}
