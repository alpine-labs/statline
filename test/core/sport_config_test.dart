import 'package:flutter_test/flutter_test.dart';
import 'package:statline/core/constants/sport_config.dart';

void main() {
  group('SportConfig.defaultFormat', () {
    test('returns non-empty map for every sport', () {
      for (final sport in Sport.values) {
        final format = SportConfig.defaultFormat(sport);
        expect(format, isNotEmpty, reason: '${sport.name} should have a format');
      }
    });

    test('volleyball format has setsToWin', () {
      final format = SportConfig.defaultFormat(Sport.volleyball);
      expect(format, contains('setsToWin'));
      expect(format['setsToWin'], 3);
    });

    test('basketball format has quarters', () {
      final format = SportConfig.defaultFormat(Sport.basketball);
      expect(format, contains('quarters'));
    });

    test('baseball format has innings', () {
      final format = SportConfig.defaultFormat(Sport.baseball);
      expect(format, contains('innings'));
    });

    test('football format has quarters', () {
      final format = SportConfig.defaultFormat(Sport.football);
      expect(format, contains('quarters'));
    });

    test('slowpitch format has innings', () {
      final format = SportConfig.defaultFormat(Sport.slowpitch);
      expect(format, contains('innings'));
    });
  });

  group('SportConfig.volleyballFormatForLevel', () {
    test('Youth returns best-of-3 with sets to 21', () {
      final format = SportConfig.volleyballFormatForLevel('Youth');
      expect(format['setsToWin'], 2);
      expect(format['maxSets'], 3);
      expect(format['pointsPerSet'], 21);
      expect(format['decidingSetPoints'], 15);
      expect(format['minPointAdvantage'], 2);
    });

    test('Recreation returns best-of-3 with sets to 21', () {
      final format = SportConfig.volleyballFormatForLevel('Recreation');
      expect(format['setsToWin'], 2);
      expect(format['maxSets'], 3);
      expect(format['pointsPerSet'], 21);
    });

    test('High School returns best-of-5 with sets to 25', () {
      final format = SportConfig.volleyballFormatForLevel('High School');
      expect(format['setsToWin'], 3);
      expect(format['maxSets'], 5);
      expect(format['pointsPerSet'], 25);
    });

    test('College returns best-of-5 with sets to 25', () {
      final format = SportConfig.volleyballFormatForLevel('College');
      expect(format['setsToWin'], 3);
      expect(format['maxSets'], 5);
      expect(format['pointsPerSet'], 25);
    });

    test('Club returns best-of-5 with sets to 25', () {
      final format = SportConfig.volleyballFormatForLevel('Club');
      expect(format['setsToWin'], 3);
      expect(format['maxSets'], 5);
      expect(format['pointsPerSet'], 25);
    });

    test('all levels have deciding set at 15 with 2-point advantage', () {
      for (final level in [
        'Youth', 'Recreation', 'High School', 'College', 'Club'
      ]) {
        final format = SportConfig.volleyballFormatForLevel(level);
        expect(format['decidingSetPoints'], 15,
            reason: '$level should have deciding set at 15');
        expect(format['minPointAdvantage'], 2,
            reason: '$level should require 2-point advantage');
      }
    });
  });

  group('SportConfig.volleyballSubLimitForLevel', () {
    test('College returns 15', () {
      expect(SportConfig.volleyballSubLimitForLevel('College'), 15);
    });

    test('Club returns 15', () {
      expect(SportConfig.volleyballSubLimitForLevel('Club'), 15);
    });

    test('High School returns 12', () {
      expect(SportConfig.volleyballSubLimitForLevel('High School'), 12);
    });

    test('Youth returns 18', () {
      expect(SportConfig.volleyballSubLimitForLevel('Youth'), 18);
    });

    test('Recreation returns 18', () {
      expect(SportConfig.volleyballSubLimitForLevel('Recreation'), 18);
    });

    test('unknown level defaults to 15', () {
      expect(SportConfig.volleyballSubLimitForLevel('Unknown'), 15);
    });
  });
}
