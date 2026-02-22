import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:statline/domain/models/roster_entry.dart';
import 'package:statline/domain/models/game_lineup.dart';
import 'package:statline/domain/models/substitution.dart';

void main() {
  group('RosterEntry sportMetadata', () {
    test('toMap serializes sportMetadata as JSON string', () {
      final entry = RosterEntry(
        id: 'r1',
        teamId: 't1',
        playerId: 'p1',
        seasonId: 's1',
        jerseyNumber: '7',
        isLibero: true,
        sportMetadata: const {'isLibero': true, 'customField': 42},
        joinedDate: DateTime(2025, 1, 1),
      );

      final map = entry.toMap();
      expect(map['sport_metadata'], isA<String>());
      final decoded = jsonDecode(map['sport_metadata'] as String);
      expect(decoded['isLibero'], true);
      expect(decoded['customField'], 42);
    });

    test('fromMap deserializes sportMetadata from JSON string', () {
      final map = {
        'id': 'r1',
        'team_id': 't1',
        'player_id': 'p1',
        'season_id': 's1',
        'jersey_number': '7',
        'role': 'starter',
        'is_libero': 1,
        'sport_metadata': '{"isLibero":true}',
        'joined_date': '2025-01-01T00:00:00.000',
      };

      final entry = RosterEntry.fromMap(map);
      expect(entry.sportMetadata['isLibero'], true);
      expect(entry.isLibero, true);
    });

    test('fromMap handles missing sportMetadata gracefully', () {
      final map = {
        'id': 'r1',
        'team_id': 't1',
        'player_id': 'p1',
        'season_id': 's1',
        'jersey_number': '7',
        'role': 'reserve',
        'is_libero': 0,
        'joined_date': '2025-01-01T00:00:00.000',
      };

      final entry = RosterEntry.fromMap(map);
      expect(entry.sportMetadata, isEmpty);
    });

    test('fromMap handles empty string sportMetadata', () {
      final map = {
        'id': 'r1',
        'team_id': 't1',
        'player_id': 'p1',
        'season_id': 's1',
        'jersey_number': '7',
        'role': 'reserve',
        'is_libero': 0,
        'sport_metadata': '',
        'joined_date': '2025-01-01T00:00:00.000',
      };

      final entry = RosterEntry.fromMap(map);
      expect(entry.sportMetadata, isEmpty);
    });
  });

  group('GameLineup sportMetadata', () {
    test('round-trips through toMap/fromMap', () {
      final lineup = GameLineup(
        id: 'gl1',
        gameId: 'g1',
        playerId: 'p1',
        position: 'OH',
        startingRotation: 3,
        sportMetadata: const {'customPosition': 'outsideHitter'},
      );

      final map = lineup.toMap();
      final restored = GameLineup.fromMap(map);
      expect(restored.sportMetadata['customPosition'], 'outsideHitter');
      expect(restored.startingRotation, 3);
    });

    test('handles null sport_metadata in DB row', () {
      final map = {
        'id': 'gl1',
        'game_id': 'g1',
        'player_id': 'p1',
        'position': 'OH',
        'is_starter': 1,
        'status': 'active',
      };

      final lineup = GameLineup.fromMap(map);
      expect(lineup.sportMetadata, isEmpty);
    });
  });

  group('Substitution sportMetadata', () {
    test('round-trips through toMap/fromMap', () {
      final sub = Substitution(
        id: 'sub1',
        gameId: 'g1',
        periodId: 'per1',
        playerInId: 'p1',
        playerOutId: 'p2',
        isLiberoReplacement: true,
        sportMetadata: const {'isLiberoReplacement': true},
      );

      final map = sub.toMap();
      final restored = Substitution.fromMap(map);
      expect(restored.isLiberoReplacement, true);
      expect(restored.sportMetadata['isLiberoReplacement'], true);
    });

    test('handles missing sport_metadata', () {
      final map = {
        'id': 'sub1',
        'game_id': 'g1',
        'period_id': 'per1',
        'player_in_id': 'p1',
        'player_out_id': 'p2',
        'is_libero_replacement': 0,
      };

      final sub = Substitution.fromMap(map);
      expect(sub.sportMetadata, isEmpty);
      expect(sub.isLiberoReplacement, false);
    });
  });
}
