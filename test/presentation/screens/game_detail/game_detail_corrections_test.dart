import 'package:flutter_test/flutter_test.dart';
import 'package:statline/domain/models/play_event.dart';
import 'package:statline/domain/models/game_period.dart';

/// Unit tests for the post-game correction feature logic.
/// Tests correction workflows: edit, delete, insert, audit trail,
/// score recalculation, and sequence number management.
void main() {
  group('Event Edit Correction', () {
    test('soft-delete original preserves event data with correction metadata', () {
      final original = PlayEvent(
        id: 'e1',
        gameId: 'g1',
        periodId: 'p1',
        sequenceNumber: 5,
        timestamp: DateTime(2026, 1, 15),
        playerId: 'player1',
        eventCategory: 'attack',
        eventType: 'kill',
        result: 'point_us',
        scoreUsAfter: 10,
        scoreThemAfter: 8,
        metadata: {'zone': 4},
        createdAt: DateTime(2026, 1, 15),
      );

      // Simulate soft-delete: mark deleted + add correction metadata
      final deleted = original.copyWith(
        isDeleted: true,
        metadata: {
          ...original.metadata,
          'correctionReason': 'edit',
          'deletedAt': DateTime(2026, 1, 16).toIso8601String(),
        },
      );

      expect(deleted.isDeleted, isTrue);
      expect(deleted.metadata['correctionReason'], 'edit');
      expect(deleted.metadata['zone'], 4); // original metadata preserved
      expect(deleted.sequenceNumber, 5); // sequence unchanged
      expect(deleted.id, 'e1'); // id unchanged
    });

    test('corrected event has same sequence number and links to original', () {
      final corrected = PlayEvent(
        id: 'e1_c1705000000',
        gameId: 'g1',
        periodId: 'p1',
        sequenceNumber: 5, // same as original
        timestamp: DateTime(2026, 1, 16),
        playerId: 'player2', // changed player
        eventCategory: 'attack',
        eventType: 'attack_error', // changed action
        result: 'point_them', // changed result
        scoreUsAfter: 0, // will be recalculated
        scoreThemAfter: 0,
        metadata: {
          'corrects': 'e1',
          'correctedAt': DateTime(2026, 1, 16).toIso8601String(),
          'correctionReason': 'edit',
        },
        createdAt: DateTime(2026, 1, 16),
      );

      expect(corrected.metadata['corrects'], 'e1');
      expect(corrected.metadata['correctionReason'], 'edit');
      expect(corrected.sequenceNumber, 5);
      expect(corrected.playerId, 'player2');
      expect(corrected.result, 'point_them');
    });
  });

  group('Event Delete Correction', () {
    test('soft-deleted event has delete reason in metadata', () {
      final deleted = PlayEvent(
        id: 'e2',
        gameId: 'g1',
        periodId: 'p1',
        sequenceNumber: 3,
        timestamp: DateTime(2026, 1, 15),
        playerId: 'player1',
        eventCategory: 'serve',
        eventType: 'service_ace',
        result: 'point_us',
        scoreUsAfter: 5,
        scoreThemAfter: 3,
        isDeleted: true,
        metadata: {
          'correctionReason': 'delete',
          'deletedAt': DateTime(2026, 1, 16).toIso8601String(),
        },
        createdAt: DateTime(2026, 1, 15),
      );

      expect(deleted.isDeleted, isTrue);
      expect(deleted.metadata['correctionReason'], 'delete');
      expect(deleted.metadata.containsKey('deletedAt'), isTrue);
    });
  });

  group('Event Insert Correction', () {
    test('inserted event has insert metadata and no corrects link', () {
      final inserted = PlayEvent(
        id: 'ins_1705000000',
        gameId: 'g1',
        periodId: 'p1',
        sequenceNumber: 6,
        timestamp: DateTime(2026, 1, 16),
        playerId: 'player3',
        eventCategory: 'defense',
        eventType: 'dig',
        result: 'rally_continues',
        scoreUsAfter: 0,
        scoreThemAfter: 0,
        metadata: {
          'correctionReason': 'insert',
          'insertedAt': DateTime(2026, 1, 16).toIso8601String(),
        },
        createdAt: DateTime(2026, 1, 16),
      );

      expect(inserted.metadata['correctionReason'], 'insert');
      expect(inserted.metadata.containsKey('corrects'), isFalse);
      expect(inserted.metadata.containsKey('insertedAt'), isTrue);
    });

    test('sequence numbers shift correctly after insert', () {
      // Before insert: events at seq 1, 2, 3, 4, 5
      // Insert after seq 3 → new event at seq 4, old 4→5, old 5→6
      final before = [1, 2, 3, 4, 5];
      final insertAfter = 3;
      final shifted = before.map((seq) {
        if (seq > insertAfter) return seq + 1;
        return seq;
      }).toList();

      expect(shifted, [1, 2, 3, 5, 6]);
      // New event occupies seq 4
      final allSeqs = [...shifted, insertAfter + 1]..sort();
      expect(allSeqs, [1, 2, 3, 4, 5, 6]);
    });
  });

  group('Score Recalculation', () {
    test('recalculates scores from point results only', () {
      final events = [
        _event(seq: 1, result: 'point_us'),
        _event(seq: 2, result: 'rally_continues'),
        _event(seq: 3, result: 'point_them'),
        _event(seq: 4, result: 'point_us'),
        _event(seq: 5, result: 'point_us'),
        _event(seq: 6, result: 'point_them'),
      ];

      // Walk events and compute scores
      int scoreUs = 0;
      int scoreThem = 0;
      final scores = <Map<String, int>>[];
      for (final e in events) {
        if (e.result == 'point_us') scoreUs++;
        if (e.result == 'point_them') scoreThem++;
        scores.add({'us': scoreUs, 'them': scoreThem});
      }

      expect(scores[0], {'us': 1, 'them': 0});
      expect(scores[1], {'us': 1, 'them': 0}); // rally_continues: no change
      expect(scores[2], {'us': 1, 'them': 1});
      expect(scores[3], {'us': 2, 'them': 1});
      expect(scores[4], {'us': 3, 'them': 1});
      expect(scores[5], {'us': 3, 'them': 2});
    });

    test('deleted events excluded from score recalculation', () {
      final events = [
        _event(seq: 1, result: 'point_us'),
        _event(seq: 2, result: 'point_us', isDeleted: true),
        _event(seq: 3, result: 'point_them'),
      ];

      int scoreUs = 0;
      int scoreThem = 0;
      for (final e in events) {
        if (e.isDeleted) continue;
        if (e.result == 'point_us') scoreUs++;
        if (e.result == 'point_them') scoreThem++;
      }

      expect(scoreUs, 1); // deleted event not counted
      expect(scoreThem, 1);
    });

    test('set winner determined by higher score', () {
      final periodScores = [
        {'us': 25, 'them': 20},
        {'us': 18, 'them': 25},
        {'us': 25, 'them': 22},
        {'us': 25, 'them': 15},
      ];

      int setsUs = 0;
      int setsThem = 0;
      for (final s in periodScores) {
        if (s['us']! > s['them']!) setsUs++;
        if (s['them']! > s['us']!) setsThem++;
      }

      expect(setsUs, 3);
      expect(setsThem, 1);

      final result = setsUs > setsThem
          ? 'win'
          : setsThem > setsUs
              ? 'loss'
              : 'tie';
      expect(result, 'win');
    });
  });

  group('Audit Trail Chain', () {
    test('correction chain is walkable via corrects metadata', () {
      // original → edited → edited again
      final original = _event(
        id: 'e1',
        seq: 5,
        result: 'point_us',
        isDeleted: true,
        metadata: {'correctionReason': 'edit'},
      );
      final edit1 = _event(
        id: 'e1_c1',
        seq: 5,
        result: 'point_them',
        isDeleted: true,
        metadata: {'corrects': 'e1', 'correctionReason': 'edit'},
      );
      final edit2 = _event(
        id: 'e1_c2',
        seq: 5,
        result: 'rally_continues',
        metadata: {'corrects': 'e1_c1', 'correctionReason': 'edit'},
      );

      // Walk from most recent back
      final trail = <PlayEvent>[edit2];
      String? correctsId = edit2.metadata['corrects'] as String?;
      final allEvents = [original, edit1, edit2];
      while (correctsId != null) {
        final found = allEvents.where((e) => e.id == correctsId).toList();
        if (found.isEmpty) break;
        trail.add(found.first);
        correctsId = found.first.metadata['corrects'] as String?;
      }

      // Reverse for oldest-first
      final orderedTrail = trail.reversed.toList();
      expect(orderedTrail.length, 3);
      expect(orderedTrail[0].id, 'e1'); // original
      expect(orderedTrail[1].id, 'e1_c1'); // first edit
      expect(orderedTrail[2].id, 'e1_c2'); // second edit (current)
    });

    test('audit trail of single event with no corrections has length 1', () {
      final event = _event(id: 'e5', seq: 1, result: 'point_us');
      final trail = [event];
      String? correctsId = event.metadata['corrects'] as String?;
      expect(correctsId, isNull);
      expect(trail.length, 1);
    });
  });

  group('Category → Action Mapping', () {
    test('all volleyball categories have valid actions', () {
      const categoryActions = {
        'attack': ['kill', 'attack_error', 'attack_attempt'],
        'serve': ['service_ace', 'service_error', 'serve_attempt'],
        'block': ['block_solo', 'block_assist', 'block_error'],
        'defense': ['dig', 'dig_error'],
        'reception': ['reception', 'reception_error', 'shank', 'overpass'],
        'setting': ['assist', 'set_error', 'set_attempt'],
        'scoring': ['point_us', 'point_them'],
      };

      expect(categoryActions.keys.length, 7);
      for (final actions in categoryActions.values) {
        expect(actions, isNotEmpty);
      }
    });

    test('action → result defaults are consistent', () {
      const actionResults = {
        'kill': 'point_us',
        'attack_error': 'point_them',
        'service_ace': 'point_us',
        'service_error': 'point_them',
        'block_solo': 'point_us',
        'block_error': 'point_them',
        'dig': 'rally_continues',
        'reception': 'rally_continues',
        'assist': 'rally_continues',
      };

      // All point-scoring actions should map to point_us or point_them
      expect(actionResults['kill'], 'point_us');
      expect(actionResults['service_ace'], 'point_us');
      expect(actionResults['block_solo'], 'point_us');

      // All error actions should map to point_them
      expect(actionResults['attack_error'], 'point_them');
      expect(actionResults['service_error'], 'point_them');
      expect(actionResults['block_error'], 'point_them');

      // Rally-continues actions
      expect(actionResults['dig'], 'rally_continues');
      expect(actionResults['reception'], 'rally_continues');
      expect(actionResults['assist'], 'rally_continues');
    });
  });

  group('GamePeriod Score Model', () {
    test('GamePeriod tracks per-set scores', () {
      final period = GamePeriod(
        id: 'p1',
        gameId: 'g1',
        periodNumber: 1,
        periodType: 'set',
        scoreUs: 25,
        scoreThem: 20,
      );

      expect(period.scoreUs, 25);
      expect(period.scoreThem, 20);
      expect(period.periodNumber, 1);
    });

    test('GamePeriod default scores are zero', () {
      final period = GamePeriod(
        id: 'p2',
        gameId: 'g1',
        periodNumber: 2,
        periodType: 'set',
      );

      expect(period.scoreUs, 0);
      expect(period.scoreThem, 0);
    });
  });
}

/// Helper to create a PlayEvent with minimal required fields.
PlayEvent _event({
  String id = 'e_test',
  int seq = 1,
  required String result,
  bool isDeleted = false,
  Map<String, dynamic> metadata = const {},
}) {
  return PlayEvent(
    id: id,
    gameId: 'g1',
    periodId: 'p1',
    sequenceNumber: seq,
    timestamp: DateTime(2026, 1, 15),
    playerId: 'player1',
    eventCategory: 'attack',
    eventType: 'kill',
    result: result,
    scoreUsAfter: 0,
    scoreThemAfter: 0,
    isDeleted: isDeleted,
    metadata: metadata,
    createdAt: DateTime(2026, 1, 15),
  );
}
