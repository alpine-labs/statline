import 'package:flutter_test/flutter_test.dart';
import 'package:statline/presentation/providers/live_game_providers.dart';
import 'package:statline/domain/models/game.dart';
import 'package:statline/domain/models/play_event.dart';
import 'package:statline/domain/models/player.dart';

/// Integration-style tests for the LiveGameNotifier state machine.
/// Validates the full recording pipeline: start game → record events →
/// score updates → undo → advance set → serve tracking → end game.
void main() {
  late LiveGameNotifier notifier;

  final now = DateTime(2025, 6, 1);
  final game = Game(
    id: 'g1',
    seasonId: 's1',
    teamId: 't1',
    opponentName: 'Rival',
    gameDate: now,
    sport: 'volleyball',
    gameFormat: {'setsToWin': 3, 'maxSets': 5, 'pointsPerSet': 25},
    createdAt: now,
    updatedAt: now,
  );

  final roster = [
    Player(
        id: 'p1', firstName: 'Alice', lastName: 'A', jerseyNumber: '1',
        positions: ['OH'], createdAt: now, updatedAt: now),
    Player(
        id: 'p2', firstName: 'Bob', lastName: 'B', jerseyNumber: '2',
        positions: ['S'], createdAt: now, updatedAt: now),
  ];

  setUp(() {
    notifier = LiveGameNotifier();
  });

  group('startGame', () {
    test('initializes game state correctly', () {
      notifier.startGame(game, roster);
      final state = notifier.state;

      expect(state.game, isNotNull);
      expect(state.game!.status, GameStatus.inProgress);
      expect(state.roster.length, 2);
      expect(state.periods.length, 1);
      expect(state.currentPeriod!.periodNumber, 1);
      expect(state.scoreUs, 0);
      expect(state.scoreThem, 0);
      expect(state.currentRotation, 1);
      expect(state.servingTeam, 'us');
    });

    test('accepts custom maxSubsPerSet', () {
      notifier.startGame(game, roster, maxSubsPerSet: 12);
      expect(notifier.state.maxSubsPerSet, 12);
    });
  });

  group('recordEvent', () {
    setUp(() => notifier.startGame(game, roster));

    test('records event and updates score', () {
      notifier.selectPlayer('p1');
      final event = _makeEvent('kill', 'attack', 'point_us',
          scoreUs: 1, scoreThem: 0);
      notifier.recordEvent(event);

      final state = notifier.state;
      expect(state.playEvents.length, 1);
      expect(state.scoreUs, 1);
      expect(state.scoreThem, 0);
      expect(state.selectedPlayerId, isNull);
    });

    test('enriches event with rotation metadata', () {
      final event = _makeEvent('kill', 'attack', 'point_us',
          scoreUs: 1, scoreThem: 0);
      notifier.recordEvent(event);

      final recorded = notifier.state.playEvents.first;
      expect(recorded.metadata['rotation'], 1);
    });

    test('enriches event with servingTeam metadata', () {
      final event = _makeEvent('kill', 'attack', 'point_us',
          scoreUs: 1, scoreThem: 0);
      notifier.recordEvent(event);

      final recorded = notifier.state.playEvents.first;
      expect(recorded.metadata['servingTeam'], 'us');
    });

    test('updates period score', () {
      notifier.recordEvent(_makeEvent('kill', 'attack', 'point_us',
          scoreUs: 1, scoreThem: 0));
      expect(notifier.state.currentPeriod!.scoreUs, 1);
      expect(notifier.state.currentPeriod!.scoreThem, 0);
    });
  });

  group('serve tracking', () {
    setUp(() => notifier.startGame(game, roster));

    test('serve stays with us when we score on our serve', () {
      notifier.recordEvent(_makeEvent('ace', 'serve', 'point_us',
          scoreUs: 1, scoreThem: 0));
      expect(notifier.state.servingTeam, 'us');
    });

    test('serve transfers on side-out (they score while we serve)', () {
      notifier.recordEvent(_makeEvent('serve_error', 'serve', 'point_them',
          scoreUs: 0, scoreThem: 1));
      expect(notifier.state.servingTeam, 'them');
    });

    test('serve transfers back on our side-out', () {
      notifier.recordEvent(_makeEvent('serve_error', 'serve', 'point_them',
          scoreUs: 0, scoreThem: 1));
      expect(notifier.state.servingTeam, 'them');

      notifier.recordEvent(_makeEvent('kill', 'attack', 'point_us',
          scoreUs: 1, scoreThem: 1));
      expect(notifier.state.servingTeam, 'us');
    });

    test('toggleServe manually corrects serve state', () {
      expect(notifier.state.servingTeam, 'us');
      notifier.toggleServe();
      expect(notifier.state.servingTeam, 'them');
      notifier.toggleServe();
      expect(notifier.state.servingTeam, 'us');
    });
  });

  group('undo', () {
    setUp(() => notifier.startGame(game, roster));

    test('undoes last event and reverts score', () {
      notifier.recordEvent(_makeEvent('kill', 'attack', 'point_us',
          scoreUs: 1, scoreThem: 0));
      notifier.recordEvent(_makeEvent('ace', 'serve', 'point_us',
          scoreUs: 2, scoreThem: 0));

      notifier.undoLastEvent();

      expect(notifier.state.playEvents.length, 1);
      expect(notifier.state.scoreUs, 1);
      expect(notifier.state.scoreThem, 0);
    });

    test('undo on empty stack is no-op', () {
      notifier.undoLastEvent();
      expect(notifier.state.playEvents, isEmpty);
    });

    test('undo all events resets score to 0-0', () {
      notifier.recordEvent(_makeEvent('kill', 'attack', 'point_us',
          scoreUs: 1, scoreThem: 0));
      notifier.undoLastEvent();

      expect(notifier.state.scoreUs, 0);
      expect(notifier.state.scoreThem, 0);
    });
  });

  group('advancePeriod', () {
    setUp(() => notifier.startGame(game, roster));

    test('creates new set with incremented number', () {
      notifier.advancePeriod();

      final state = notifier.state;
      expect(state.periods.length, 2);
      expect(state.currentPeriod!.periodNumber, 2);
      expect(state.scoreUs, 0);
      expect(state.scoreThem, 0);
    });

    test('resets timeouts and subs on new set', () {
      notifier.callTimeout(true);
      notifier.recordSubstitution();
      notifier.advancePeriod();

      expect(notifier.state.timeoutsUs, 0);
      expect(notifier.state.timeoutsThem, 0);
      expect(notifier.state.subsThisSet, 0);
    });

    test('alternates serve on set advance', () {
      expect(notifier.state.servingTeam, 'us');
      notifier.advancePeriod();
      expect(notifier.state.servingTeam, 'them');
      notifier.advancePeriod();
      expect(notifier.state.servingTeam, 'us');
    });
  });

  group('rotation', () {
    setUp(() => notifier.startGame(game, roster));

    test('rotates forward 1-6 and wraps', () {
      expect(notifier.state.currentRotation, 1);
      for (int i = 2; i <= 6; i++) {
        notifier.rotateForward();
        expect(notifier.state.currentRotation, i);
      }
      notifier.rotateForward();
      expect(notifier.state.currentRotation, 1);
    });

    test('rotates backward and wraps', () {
      notifier.rotateBackward();
      expect(notifier.state.currentRotation, 6);
    });
  });

  group('substitutions', () {
    setUp(() => notifier.startGame(game, roster));

    test('increments sub count', () {
      notifier.recordSubstitution();
      expect(notifier.state.subsThisSet, 1);
    });

    test('respects max subs limit', () {
      notifier.startGame(game, roster, maxSubsPerSet: 2);
      notifier.recordSubstitution();
      notifier.recordSubstitution();
      notifier.recordSubstitution();
      expect(notifier.state.subsThisSet, 2);
    });
  });

  group('timeouts', () {
    setUp(() => notifier.startGame(game, roster));

    test('increments timeout count', () {
      notifier.callTimeout(true);
      expect(notifier.state.timeoutsUs, 1);
      notifier.callTimeout(false);
      expect(notifier.state.timeoutsThem, 1);
    });

    test('respects max timeouts per set', () {
      notifier.callTimeout(true);
      notifier.callTimeout(true);
      notifier.callTimeout(true);
      expect(notifier.state.timeoutsUs, 2);
    });
  });

  group('endGame', () {
    setUp(() => notifier.startGame(game, roster));

    test('sets status to completed and determines winner', () {
      // Set 1: us 25-20
      final p1 = notifier.state.currentPeriod!;
      notifier.recordEvent(_makeEvent('kill', 'attack', 'point_us',
          scoreUs: 25, scoreThem: 20, periodId: p1.id));
      notifier.advancePeriod();

      // Set 2: us 25-18
      final p2 = notifier.state.currentPeriod!;
      notifier.recordEvent(_makeEvent('kill', 'attack', 'point_us',
          scoreUs: 25, scoreThem: 18, periodId: p2.id));
      notifier.advancePeriod();

      // Set 3: us 25-22
      final p3 = notifier.state.currentPeriod!;
      notifier.recordEvent(_makeEvent('kill', 'attack', 'point_us',
          scoreUs: 25, scoreThem: 22, periodId: p3.id));

      notifier.endGame();

      final state = notifier.state;
      expect(state.game!.status, GameStatus.completed);
      expect(state.game!.result, GameResult.win);
      expect(state.game!.finalScoreUs, 3);
    });
  });

  group('entryMode', () {
    setUp(() => notifier.startGame(game, roster));

    test('toggles between quick and detailed', () {
      expect(notifier.state.entryMode, 'quick');
      notifier.toggleEntryMode();
      expect(notifier.state.entryMode, 'detailed');
      notifier.toggleEntryMode();
      expect(notifier.state.entryMode, 'quick');
    });
  });

  group('reset', () {
    test('returns to initial state', () {
      notifier.startGame(game, roster);
      notifier.recordEvent(_makeEvent('kill', 'attack', 'point_us',
          scoreUs: 1, scoreThem: 0));
      notifier.reset();

      final state = notifier.state;
      expect(state.game, isNull);
      expect(state.playEvents, isEmpty);
      expect(state.scoreUs, 0);
    });
  });
}

int _eventCounter = 0;

PlayEvent _makeEvent(
  String eventType,
  String category,
  String result, {
  int scoreUs = 0,
  int scoreThem = 0,
  String periodId = 'period_1',
  String playerId = 'p1',
}) {
  _eventCounter++;
  return PlayEvent(
    id: 'evt_$_eventCounter',
    gameId: 'g1',
    periodId: periodId,
    sequenceNumber: _eventCounter,
    timestamp: DateTime(2025, 6, 1),
    playerId: playerId,
    eventCategory: category,
    eventType: eventType,
    result: result,
    scoreUsAfter: scoreUs,
    scoreThemAfter: scoreThem,
    createdAt: DateTime(2025, 6, 1),
  );
}
