import 'package:flutter_test/flutter_test.dart';
import 'package:statline/domain/sports/sport_engine_registry.dart';
import 'package:statline/domain/sports/volleyball/volleyball_game_engine.dart';
import '../../helpers/fake_sport_game_engine.dart';

void main() {
  group('SportEngineRegistry', () {
    test('returns VolleyballGameEngine for volleyball', () {
      final engine = SportEngineRegistry.getEngine('volleyball');
      expect(engine, isA<VolleyballGameEngine>());
    });

    test('throws for unregistered sport', () {
      expect(
        () => SportEngineRegistry.getEngine('curling'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('tryGetEngine returns null for unregistered sport', () {
      expect(SportEngineRegistry.tryGetEngine('curling'), isNull);
    });

    test('register allows adding new engines', () {
      final fake = FakeSportGameEngine();
      SportEngineRegistry.register('test_sport', fake);
      expect(SportEngineRegistry.getEngine('test_sport'), same(fake));
      // Clean up
      SportEngineRegistry.register('test_sport', fake); // idempotent
    });
  });
}
