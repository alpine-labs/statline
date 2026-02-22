import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game.dart';
import '../../domain/models/game_period.dart';
import '../../domain/models/play_event.dart';
import '../../domain/models/player_stats.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/database/app_database.dart';

// ── Repository Providers ─────────────────────────────────────────────────────

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(AppDatabase.getInstance());
});

// ── Game Detail Providers ────────────────────────────────────────────────────

/// Fetches a single game by ID from the database, falling back to in-memory.
final gameDetailProvider =
    FutureProvider.family<Game?, String>((ref, gameId) async {
  final repo = ref.read(gameRepositoryProvider);
  final dbGame = await repo.getGame(gameId);
  if (dbGame != null) return dbGame;
  // Fallback: search in-memory games list
  final gamesAsync = ref.read(gamesProvider);
  return gamesAsync.whenOrNull(
    data: (games) {
      try {
        return games.firstWhere((g) => g.id == gameId);
      } catch (_) {
        return null;
      }
    },
  );
});

/// Fetches game periods (sets) for a game.
final gamePeriodsProvider =
    FutureProvider.family<List<GamePeriod>, String>((ref, gameId) async {
  final repo = ref.read(gameRepositoryProvider);
  final dbPeriods = await repo.getGamePeriods(gameId);
  if (dbPeriods.isNotEmpty) return dbPeriods;
  return _mockGamePeriods.where((p) => p.gameId == gameId).toList();
});

/// Fetches per-player game stats (box score data).
final gamePlayerStatsProvider =
    FutureProvider.family<List<PlayerGameStatsModel>, String>(
        (ref, gameId) async {
  final statsRepo = ref.read(_statsRepoForGameDetail);
  final dbStats = await statsRepo.getAllPlayerGameStats(gameId);
  if (dbStats.isNotEmpty) return dbStats;
  return _mockPlayerGameStats.where((s) => s.gameId == gameId).toList();
});

/// Fetches active play events for a game (play-by-play).
final gamePlayEventsProvider =
    FutureProvider.family<List<PlayEvent>, String>((ref, gameId) async {
  final statsRepo = ref.read(_statsRepoForGameDetail);
  final dbEvents = await statsRepo.getActivePlayEventsForGame(gameId);
  if (dbEvents.isNotEmpty) return dbEvents;
  return _mockPlayEvents.where((e) => e.gameId == gameId && !e.isDeleted).toList();
});

/// Fetches ALL play events for a game including deleted (correction mode).
final gameAllPlayEventsProvider =
    FutureProvider.family<List<PlayEvent>, String>((ref, gameId) async {
  final statsRepo = ref.read(_statsRepoForGameDetail);
  final dbEvents = await statsRepo.getAllPlayEventsForGame(gameId);
  if (dbEvents.isNotEmpty) return dbEvents;
  return _mockPlayEvents.where((e) => e.gameId == gameId).toList();
});

final _statsRepoForGameDetail = Provider<StatsRepository>((ref) {
  return StatsRepository(AppDatabase.getInstance());
});

// ── Mock data ────────────────────────────────────────────────────────────────

final _now = DateTime.now();

final _mockGames = [
  Game(
    id: 'g1', seasonId: 's1', teamId: 't1', opponentName: 'Rockets VBC',
    gameDate: _now.subtract(const Duration(days: 2)),
    location: 'Main Gym', isHome: true, sport: 'volleyball',
    gameFormat: {'setsToWin': 3, 'maxSets': 5, 'pointsPerSet': 25},
    status: GameStatus.completed, finalScoreUs: 3, finalScoreThem: 1,
    result: GameResult.win, entryMode: 'quick',
    createdAt: _now, updatedAt: _now,
  ),
  Game(
    id: 'g2', seasonId: 's1', teamId: 't1', opponentName: 'Eagles Club',
    gameDate: _now.subtract(const Duration(days: 5)),
    location: 'Convention Center', isHome: false, sport: 'volleyball',
    gameFormat: {'setsToWin': 3, 'maxSets': 5, 'pointsPerSet': 25},
    status: GameStatus.completed, finalScoreUs: 2, finalScoreThem: 3,
    result: GameResult.loss, entryMode: 'quick',
    createdAt: _now, updatedAt: _now,
  ),
  Game(
    id: 'g3', seasonId: 's1', teamId: 't1', opponentName: 'Panthers VB',
    gameDate: _now.subtract(const Duration(days: 9)),
    location: 'High School Gym', isHome: true, sport: 'volleyball',
    gameFormat: {'setsToWin': 2, 'maxSets': 3, 'pointsPerSet': 25},
    status: GameStatus.completed, finalScoreUs: 2, finalScoreThem: 0,
    result: GameResult.win, entryMode: 'detailed',
    createdAt: _now, updatedAt: _now,
  ),
  Game(
    id: 'g4', seasonId: 's1', teamId: 't1', opponentName: 'Wolves Academy',
    gameDate: _now.subtract(const Duration(days: 14)),
    location: 'Recreation Center', isHome: false, sport: 'volleyball',
    gameFormat: {'setsToWin': 3, 'maxSets': 5, 'pointsPerSet': 25},
    status: GameStatus.completed, finalScoreUs: 3, finalScoreThem: 2,
    result: GameResult.win, entryMode: 'quick',
    createdAt: _now, updatedAt: _now,
  ),
  Game(
    id: 'g5', seasonId: 's1', teamId: 't1', opponentName: 'Blaze VBC',
    gameDate: _now.subtract(const Duration(days: 18)),
    location: 'Sports Complex', isHome: true, sport: 'volleyball',
    gameFormat: {'setsToWin': 3, 'maxSets': 5, 'pointsPerSet': 25},
    status: GameStatus.completed, finalScoreUs: 0, finalScoreThem: 3,
    result: GameResult.loss, entryMode: 'quick',
    createdAt: _now, updatedAt: _now,
  ),
];

// ── Mock Helper Functions ────────────────────────────────────────────────────

PlayEvent _evt(
  String id, String gameId, int period, int seq,
  String playerId, String? secondaryPlayerId,
  String cat, String type, String result,
  int scoreUs, int scoreThem, {
  bool isOpponent = false,
}) {
  final gameDate = _mockGames.firstWhere((g) => g.id == gameId).gameDate;
  return PlayEvent(
    id: id,
    gameId: gameId,
    periodId: '${gameId}_s$period',
    sequenceNumber: seq,
    timestamp: gameDate.add(Duration(minutes: period * 25 + seq)),
    playerId: playerId,
    secondaryPlayerId: secondaryPlayerId,
    eventCategory: cat,
    eventType: type,
    result: result,
    scoreUsAfter: scoreUs,
    scoreThemAfter: scoreThem,
    isOpponent: isOpponent,
    createdAt: _now,
  );
}

// ── Mock Game Periods ────────────────────────────────────────────────────────

final _mockGamePeriods = [
  GamePeriod(id: 'g1_s1', gameId: 'g1', periodNumber: 1, periodType: 'set', scoreUs: 25, scoreThem: 20),
  GamePeriod(id: 'g1_s2', gameId: 'g1', periodNumber: 2, periodType: 'set', scoreUs: 22, scoreThem: 25),
  GamePeriod(id: 'g1_s3', gameId: 'g1', periodNumber: 3, periodType: 'set', scoreUs: 25, scoreThem: 18),
  GamePeriod(id: 'g1_s4', gameId: 'g1', periodNumber: 4, periodType: 'set', scoreUs: 25, scoreThem: 21),
  GamePeriod(id: 'g2_s1', gameId: 'g2', periodNumber: 1, periodType: 'set', scoreUs: 25, scoreThem: 23),
  GamePeriod(id: 'g2_s2', gameId: 'g2', periodNumber: 2, periodType: 'set', scoreUs: 20, scoreThem: 25),
  GamePeriod(id: 'g2_s3', gameId: 'g2', periodNumber: 3, periodType: 'set', scoreUs: 25, scoreThem: 22),
  GamePeriod(id: 'g2_s4', gameId: 'g2', periodNumber: 4, periodType: 'set', scoreUs: 19, scoreThem: 25),
  GamePeriod(id: 'g2_s5', gameId: 'g2', periodNumber: 5, periodType: 'set', scoreUs: 12, scoreThem: 15),
  GamePeriod(id: 'g3_s1', gameId: 'g3', periodNumber: 1, periodType: 'set', scoreUs: 25, scoreThem: 17),
  GamePeriod(id: 'g3_s2', gameId: 'g3', periodNumber: 2, periodType: 'set', scoreUs: 25, scoreThem: 19),
  GamePeriod(id: 'g4_s1', gameId: 'g4', periodNumber: 1, periodType: 'set', scoreUs: 25, scoreThem: 23),
  GamePeriod(id: 'g4_s2', gameId: 'g4', periodNumber: 2, periodType: 'set', scoreUs: 21, scoreThem: 25),
  GamePeriod(id: 'g4_s3', gameId: 'g4', periodNumber: 3, periodType: 'set', scoreUs: 25, scoreThem: 20),
  GamePeriod(id: 'g4_s4', gameId: 'g4', periodNumber: 4, periodType: 'set', scoreUs: 23, scoreThem: 25),
  GamePeriod(id: 'g4_s5', gameId: 'g4', periodNumber: 5, periodType: 'set', scoreUs: 15, scoreThem: 12),
  GamePeriod(id: 'g5_s1', gameId: 'g5', periodNumber: 1, periodType: 'set', scoreUs: 18, scoreThem: 25),
  GamePeriod(id: 'g5_s2', gameId: 'g5', periodNumber: 2, periodType: 'set', scoreUs: 20, scoreThem: 25),
  GamePeriod(id: 'g5_s3', gameId: 'g5', periodNumber: 3, periodType: 'set', scoreUs: 15, scoreThem: 25),
];

// ── Mock Play Events ─────────────────────────────────────────────────────────

final _mockPlayEvents = [
  // G1 vs Rockets VBC (3-1 win): Sets 25-20, 22-25, 25-18, 25-21
  _evt('g1_e1', 'g1', 1, 1, 'p2', 'p1', 'attack', 'kill', 'point_us', 1, 0),
  _evt('g1_e2', 'g1', 1, 2, 'p7', null, 'reception', 'reception', 'in_play', 1, 0),
  _evt('g1_e3', 'g1', 1, 3, 'opponent', null, 'attack', 'kill', 'point_them', 1, 1, isOpponent: true),
  _evt('g1_e4', 'g1', 1, 4, 'p3', null, 'serve', 'ace', 'point_us', 5, 3),
  _evt('g1_e5', 'g1', 1, 5, 'p4', null, 'block', 'block_solo', 'point_us', 8, 6),
  _evt('g1_e6', 'g1', 1, 6, 'p7', null, 'dig', 'dig', 'in_play', 8, 6),
  _evt('g1_e7', 'g1', 1, 7, 'p6', 'p1', 'attack', 'kill', 'point_us', 12, 9),
  _evt('g1_e8', 'g1', 1, 8, 'p2', null, 'serve', 'serve_error', 'point_them', 14, 12),
  _evt('g1_e9', 'g1', 1, 9, 'p3', 'p1', 'attack', 'kill', 'point_us', 16, 12),
  _evt('g1_e10', 'g1', 1, 10, 'opponent', null, 'attack', 'kill', 'point_them', 18, 15, isOpponent: true),
  _evt('g1_e11', 'g1', 1, 11, 'p2', 'p1', 'attack', 'kill', 'point_us', 22, 18),
  _evt('g1_e12', 'g1', 1, 12, 'p6', null, 'serve', 'ace', 'point_us', 25, 20),
  _evt('g1_e13', 'g1', 2, 13, 'opponent', null, 'attack', 'kill', 'point_them', 0, 2, isOpponent: true),
  _evt('g1_e14', 'g1', 2, 14, 'p2', 'p1', 'attack', 'kill', 'point_us', 3, 3),
  _evt('g1_e15', 'g1', 2, 15, 'p5', 'p4', 'block', 'block_assist', 'point_us', 6, 5),
  _evt('g1_e16', 'g1', 2, 16, 'p3', null, 'attack', 'attack_error', 'point_them', 8, 10),
  _evt('g1_e17', 'g1', 2, 17, 'p7', null, 'dig', 'dig', 'in_play', 8, 10),
  _evt('g1_e18', 'g1', 2, 18, 'p2', 'p1', 'attack', 'kill', 'point_us', 12, 13),
  _evt('g1_e19', 'g1', 2, 19, 'opponent', null, 'serve', 'ace', 'point_them', 15, 18, isOpponent: true),
  _evt('g1_e20', 'g1', 2, 20, 'p4', 'p1', 'attack', 'kill', 'point_us', 19, 21),
  _evt('g1_e21', 'g1', 2, 21, 'p6', 'p1', 'attack', 'kill', 'point_us', 21, 23),
  _evt('g1_e22', 'g1', 2, 22, 'opponent', null, 'attack', 'kill', 'point_them', 22, 25, isOpponent: true),
  _evt('g1_e23', 'g1', 3, 23, 'p3', null, 'serve', 'ace', 'point_us', 2, 0),
  _evt('g1_e24', 'g1', 3, 24, 'p2', 'p1', 'attack', 'kill', 'point_us', 5, 2),
  _evt('g1_e25', 'g1', 3, 25, 'p7', null, 'dig', 'dig', 'in_play', 5, 2),
  _evt('g1_e26', 'g1', 3, 26, 'opponent', null, 'attack', 'kill', 'point_them', 6, 4, isOpponent: true),
  _evt('g1_e27', 'g1', 3, 27, 'p4', null, 'block', 'block_solo', 'point_us', 10, 6),
  _evt('g1_e28', 'g1', 3, 28, 'p6', 'p1', 'attack', 'kill', 'point_us', 14, 9),
  _evt('g1_e29', 'g1', 3, 29, 'p3', 'p1', 'attack', 'kill', 'point_us', 18, 12),
  _evt('g1_e30', 'g1', 3, 30, 'p7', null, 'reception', 'reception', 'in_play', 18, 12),
  _evt('g1_e31', 'g1', 3, 31, 'p5', null, 'block', 'block_solo', 'point_us', 22, 15),
  _evt('g1_e32', 'g1', 3, 32, 'p2', 'p1', 'attack', 'kill', 'point_us', 25, 18),
  _evt('g1_e33', 'g1', 4, 33, 'p6', 'p1', 'attack', 'kill', 'point_us', 2, 1),
  _evt('g1_e34', 'g1', 4, 34, 'opponent', null, 'attack', 'kill', 'point_them', 3, 3, isOpponent: true),
  _evt('g1_e35', 'g1', 4, 35, 'p2', null, 'serve', 'ace', 'point_us', 6, 4),
  _evt('g1_e36', 'g1', 4, 36, 'p3', 'p1', 'attack', 'kill', 'point_us', 9, 7),
  _evt('g1_e37', 'g1', 4, 37, 'p7', null, 'dig', 'dig', 'in_play', 9, 7),
  _evt('g1_e38', 'g1', 4, 38, 'p4', 'p5', 'block', 'block_assist', 'point_us', 13, 10),
  _evt('g1_e39', 'g1', 4, 39, 'p2', null, 'serve', 'serve_error', 'point_them', 15, 13),
  _evt('g1_e40', 'g1', 4, 40, 'p3', 'p1', 'attack', 'kill', 'point_us', 19, 16),
  _evt('g1_e41', 'g1', 4, 41, 'p6', 'p1', 'attack', 'kill', 'point_us', 22, 19),
  _evt('g1_e42', 'g1', 4, 42, 'p2', 'p1', 'attack', 'kill', 'point_us', 25, 21),
  // G2 vs Eagles Club (2-3 loss): Sets 25-23, 20-25, 25-22, 19-25, 12-15
  _evt('g2_e1', 'g2', 1, 1, 'p3', 'p1', 'attack', 'kill', 'point_us', 2, 1),
  _evt('g2_e2', 'g2', 1, 2, 'p7', null, 'dig', 'dig', 'in_play', 2, 1),
  _evt('g2_e3', 'g2', 1, 3, 'p2', null, 'serve', 'ace', 'point_us', 5, 3),
  _evt('g2_e4', 'g2', 1, 4, 'opponent', null, 'attack', 'kill', 'point_them', 7, 6, isOpponent: true),
  _evt('g2_e5', 'g2', 1, 5, 'p4', null, 'block', 'block_solo', 'point_us', 10, 8),
  _evt('g2_e6', 'g2', 1, 6, 'p6', 'p1', 'attack', 'kill', 'point_us', 14, 11),
  _evt('g2_e7', 'g2', 1, 7, 'p3', null, 'serve', 'serve_error', 'point_them', 16, 14),
  _evt('g2_e8', 'g2', 1, 8, 'p2', 'p1', 'attack', 'kill', 'point_us', 20, 18),
  _evt('g2_e9', 'g2', 1, 9, 'opponent', null, 'attack', 'kill', 'point_them', 22, 21, isOpponent: true),
  _evt('g2_e10', 'g2', 1, 10, 'p3', 'p1', 'attack', 'kill', 'point_us', 25, 23),
  _evt('g2_e11', 'g2', 2, 11, 'opponent', null, 'serve', 'ace', 'point_them', 0, 2, isOpponent: true),
  _evt('g2_e12', 'g2', 2, 12, 'p2', 'p1', 'attack', 'kill', 'point_us', 2, 3),
  _evt('g2_e13', 'g2', 2, 13, 'p5', 'p4', 'block', 'block_assist', 'point_us', 5, 6),
  _evt('g2_e14', 'g2', 2, 14, 'p7', null, 'dig', 'dig', 'in_play', 5, 6),
  _evt('g2_e15', 'g2', 2, 15, 'p3', null, 'attack', 'attack_error', 'point_them', 7, 10),
  _evt('g2_e16', 'g2', 2, 16, 'p6', 'p1', 'attack', 'kill', 'point_us', 10, 12),
  _evt('g2_e17', 'g2', 2, 17, 'opponent', null, 'attack', 'kill', 'point_them', 13, 17, isOpponent: true),
  _evt('g2_e18', 'g2', 2, 18, 'p2', 'p1', 'attack', 'kill', 'point_us', 16, 19),
  _evt('g2_e19', 'g2', 2, 19, 'p4', 'p1', 'attack', 'kill', 'point_us', 19, 23),
  _evt('g2_e20', 'g2', 2, 20, 'opponent', null, 'attack', 'kill', 'point_them', 20, 25, isOpponent: true),
  _evt('g2_e21', 'g2', 3, 21, 'p3', null, 'serve', 'ace', 'point_us', 3, 1),
  _evt('g2_e22', 'g2', 3, 22, 'p2', 'p1', 'attack', 'kill', 'point_us', 6, 4),
  _evt('g2_e23', 'g2', 3, 23, 'opponent', null, 'block', 'block_solo', 'point_them', 8, 7, isOpponent: true),
  _evt('g2_e24', 'g2', 3, 24, 'p4', null, 'block', 'block_solo', 'point_us', 12, 9),
  _evt('g2_e25', 'g2', 3, 25, 'p7', null, 'reception', 'reception', 'in_play', 12, 9),
  _evt('g2_e26', 'g2', 3, 26, 'p6', 'p1', 'attack', 'kill', 'point_us', 16, 13),
  _evt('g2_e27', 'g2', 3, 27, 'p2', null, 'serve', 'serve_error', 'point_them', 18, 16),
  _evt('g2_e28', 'g2', 3, 28, 'p3', 'p1', 'attack', 'kill', 'point_us', 21, 18),
  _evt('g2_e29', 'g2', 3, 29, 'p2', 'p1', 'attack', 'kill', 'point_us', 24, 21),
  _evt('g2_e30', 'g2', 3, 30, 'p6', null, 'serve', 'ace', 'point_us', 25, 22),
  _evt('g2_e31', 'g2', 4, 31, 'opponent', null, 'attack', 'kill', 'point_them', 0, 3, isOpponent: true),
  _evt('g2_e32', 'g2', 4, 32, 'p2', 'p1', 'attack', 'kill', 'point_us', 3, 5),
  _evt('g2_e33', 'g2', 4, 33, 'p3', 'p1', 'attack', 'kill', 'point_us', 6, 8),
  _evt('g2_e34', 'g2', 4, 34, 'opponent', null, 'serve', 'ace', 'point_them', 8, 12, isOpponent: true),
  _evt('g2_e35', 'g2', 4, 35, 'p7', null, 'dig', 'dig', 'in_play', 8, 12),
  _evt('g2_e36', 'g2', 4, 36, 'p6', null, 'attack', 'attack_error', 'point_them', 10, 15),
  _evt('g2_e37', 'g2', 4, 37, 'p5', null, 'block', 'block_solo', 'point_us', 13, 17),
  _evt('g2_e38', 'g2', 4, 38, 'opponent', null, 'attack', 'kill', 'point_them', 15, 20, isOpponent: true),
  _evt('g2_e39', 'g2', 4, 39, 'p2', 'p1', 'attack', 'kill', 'point_us', 18, 23),
  _evt('g2_e40', 'g2', 4, 40, 'opponent', null, 'block', 'block_solo', 'point_them', 19, 25, isOpponent: true),
  _evt('g2_e41', 'g2', 5, 41, 'p3', 'p1', 'attack', 'kill', 'point_us', 2, 1),
  _evt('g2_e42', 'g2', 5, 42, 'opponent', null, 'attack', 'kill', 'point_them', 3, 4, isOpponent: true),
  _evt('g2_e43', 'g2', 5, 43, 'p2', 'p1', 'attack', 'kill', 'point_us', 5, 5),
  _evt('g2_e44', 'g2', 5, 44, 'p4', 'p5', 'block', 'block_assist', 'point_us', 7, 7),
  _evt('g2_e45', 'g2', 5, 45, 'opponent', null, 'serve', 'ace', 'point_them', 8, 10, isOpponent: true),
  _evt('g2_e46', 'g2', 5, 46, 'p7', null, 'dig', 'dig', 'in_play', 8, 10),
  _evt('g2_e47', 'g2', 5, 47, 'p6', 'p1', 'attack', 'kill', 'point_us', 11, 12),
  _evt('g2_e48', 'g2', 5, 48, 'opponent', null, 'attack', 'kill', 'point_them', 12, 15, isOpponent: true),
  // G3 vs Panthers VB (2-0 win): Sets 25-17, 25-19
  _evt('g3_e1', 'g3', 1, 1, 'p2', 'p1', 'attack', 'kill', 'point_us', 3, 1),
  _evt('g3_e2', 'g3', 1, 2, 'p3', null, 'serve', 'ace', 'point_us', 5, 2),
  _evt('g3_e3', 'g3', 1, 3, 'p7', null, 'dig', 'dig', 'in_play', 5, 2),
  _evt('g3_e4', 'g3', 1, 4, 'p4', null, 'block', 'block_solo', 'point_us', 9, 5),
  _evt('g3_e5', 'g3', 1, 5, 'opponent', null, 'attack', 'kill', 'point_them', 10, 7, isOpponent: true),
  _evt('g3_e6', 'g3', 1, 6, 'p6', 'p1', 'attack', 'kill', 'point_us', 14, 9),
  _evt('g3_e7', 'g3', 1, 7, 'p3', 'p1', 'attack', 'kill', 'point_us', 18, 12),
  _evt('g3_e8', 'g3', 1, 8, 'p7', null, 'reception', 'reception', 'in_play', 18, 12),
  _evt('g3_e9', 'g3', 1, 9, 'p5', 'p4', 'block', 'block_assist', 'point_us', 22, 15),
  _evt('g3_e10', 'g3', 1, 10, 'p2', 'p1', 'attack', 'kill', 'point_us', 25, 17),
  _evt('g3_e11', 'g3', 2, 11, 'p6', null, 'serve', 'ace', 'point_us', 2, 0),
  _evt('g3_e12', 'g3', 2, 12, 'p3', 'p1', 'attack', 'kill', 'point_us', 5, 3),
  _evt('g3_e13', 'g3', 2, 13, 'opponent', null, 'block', 'block_solo', 'point_them', 6, 5, isOpponent: true),
  _evt('g3_e14', 'g3', 2, 14, 'p2', 'p1', 'attack', 'kill', 'point_us', 10, 7),
  _evt('g3_e15', 'g3', 2, 15, 'p7', null, 'dig', 'dig', 'in_play', 10, 7),
  _evt('g3_e16', 'g3', 2, 16, 'p4', 'p1', 'attack', 'kill', 'point_us', 14, 10),
  _evt('g3_e17', 'g3', 2, 17, 'p2', null, 'serve', 'serve_error', 'point_them', 16, 13),
  _evt('g3_e18', 'g3', 2, 18, 'p3', 'p1', 'attack', 'kill', 'point_us', 20, 15),
  _evt('g3_e19', 'g3', 2, 19, 'p5', null, 'block', 'block_solo', 'point_us', 23, 18),
  _evt('g3_e20', 'g3', 2, 20, 'p2', 'p1', 'attack', 'kill', 'point_us', 25, 19),
  // G4 vs Wolves Academy (3-2 win): Sets 25-23, 21-25, 25-20, 23-25, 15-12
  _evt('g4_e1', 'g4', 1, 1, 'p2', 'p1', 'attack', 'kill', 'point_us', 4, 3),
  _evt('g4_e2', 'g4', 1, 2, 'p4', null, 'block', 'block_solo', 'point_us', 10, 8),
  _evt('g4_e3', 'g4', 1, 3, 'opponent', null, 'attack', 'kill', 'point_them', 15, 14, isOpponent: true),
  _evt('g4_e4', 'g4', 1, 4, 'p3', 'p1', 'attack', 'kill', 'point_us', 22, 20),
  _evt('g4_e5', 'g4', 1, 5, 'p6', 'p1', 'attack', 'kill', 'point_us', 25, 23),
  _evt('g4_e6', 'g4', 2, 6, 'opponent', null, 'serve', 'ace', 'point_them', 1, 3, isOpponent: true),
  _evt('g4_e7', 'g4', 2, 7, 'p2', null, 'serve', 'ace', 'point_us', 6, 7),
  _evt('g4_e8', 'g4', 2, 8, 'p3', null, 'attack', 'attack_error', 'point_them', 10, 14),
  _evt('g4_e9', 'g4', 2, 9, 'p6', 'p1', 'attack', 'kill', 'point_us', 17, 20),
  _evt('g4_e10', 'g4', 2, 10, 'opponent', null, 'attack', 'kill', 'point_them', 21, 25, isOpponent: true),
  _evt('g4_e11', 'g4', 3, 11, 'p3', 'p1', 'attack', 'kill', 'point_us', 5, 3),
  _evt('g4_e12', 'g4', 3, 12, 'p5', 'p4', 'block', 'block_assist', 'point_us', 10, 7),
  _evt('g4_e13', 'g4', 3, 13, 'p7', null, 'dig', 'dig', 'in_play', 10, 7),
  _evt('g4_e14', 'g4', 3, 14, 'p2', 'p1', 'attack', 'kill', 'point_us', 19, 14),
  _evt('g4_e15', 'g4', 3, 15, 'p3', null, 'serve', 'ace', 'point_us', 25, 20),
  _evt('g4_e16', 'g4', 4, 16, 'opponent', null, 'attack', 'kill', 'point_them', 2, 4, isOpponent: true),
  _evt('g4_e17', 'g4', 4, 17, 'p4', 'p1', 'attack', 'kill', 'point_us', 8, 8),
  _evt('g4_e18', 'g4', 4, 18, 'p6', 'p1', 'attack', 'kill', 'point_us', 15, 15),
  _evt('g4_e19', 'g4', 4, 19, 'p2', 'p1', 'attack', 'kill', 'point_us', 21, 22),
  _evt('g4_e20', 'g4', 4, 20, 'opponent', null, 'block', 'block_solo', 'point_them', 23, 25, isOpponent: true),
  _evt('g4_e21', 'g4', 5, 21, 'p3', 'p1', 'attack', 'kill', 'point_us', 3, 2),
  _evt('g4_e22', 'g4', 5, 22, 'p4', null, 'block', 'block_solo', 'point_us', 7, 5),
  _evt('g4_e23', 'g4', 5, 23, 'opponent', null, 'attack', 'kill', 'point_them', 9, 8, isOpponent: true),
  _evt('g4_e24', 'g4', 5, 24, 'p2', 'p1', 'attack', 'kill', 'point_us', 13, 11),
  _evt('g4_e25', 'g4', 5, 25, 'p6', null, 'serve', 'ace', 'point_us', 15, 12),
  // G5 vs Blaze VBC (0-3 loss): Sets 18-25, 20-25, 15-25
  _evt('g5_e1', 'g5', 1, 1, 'opponent', null, 'serve', 'ace', 'point_them', 0, 3, isOpponent: true),
  _evt('g5_e2', 'g5', 1, 2, 'p2', 'p1', 'attack', 'kill', 'point_us', 3, 5),
  _evt('g5_e3', 'g5', 1, 3, 'p3', null, 'serve', 'serve_error', 'point_them', 6, 10),
  _evt('g5_e4', 'g5', 1, 4, 'p7', null, 'dig', 'dig', 'in_play', 6, 10),
  _evt('g5_e5', 'g5', 1, 5, 'p6', 'p1', 'attack', 'kill', 'point_us', 10, 14),
  _evt('g5_e6', 'g5', 1, 6, 'opponent', null, 'attack', 'kill', 'point_them', 14, 20, isOpponent: true),
  _evt('g5_e7', 'g5', 1, 7, 'opponent', null, 'block', 'block_solo', 'point_them', 18, 25, isOpponent: true),
  _evt('g5_e8', 'g5', 2, 8, 'p3', 'p1', 'attack', 'kill', 'point_us', 2, 1),
  _evt('g5_e9', 'g5', 2, 9, 'opponent', null, 'attack', 'kill', 'point_them', 4, 5, isOpponent: true),
  _evt('g5_e10', 'g5', 2, 10, 'p2', 'p1', 'attack', 'kill', 'point_us', 8, 8),
  _evt('g5_e11', 'g5', 2, 11, 'p4', null, 'block', 'block_solo', 'point_us', 12, 12),
  _evt('g5_e12', 'g5', 2, 12, 'opponent', null, 'serve', 'ace', 'point_them', 14, 17, isOpponent: true),
  _evt('g5_e13', 'g5', 2, 13, 'p2', null, 'attack', 'attack_error', 'point_them', 17, 21),
  _evt('g5_e14', 'g5', 2, 14, 'opponent', null, 'attack', 'kill', 'point_them', 20, 25, isOpponent: true),
  _evt('g5_e15', 'g5', 3, 15, 'opponent', null, 'attack', 'kill', 'point_them', 0, 4, isOpponent: true),
  _evt('g5_e16', 'g5', 3, 16, 'p3', 'p1', 'attack', 'kill', 'point_us', 3, 7),
  _evt('g5_e17', 'g5', 3, 17, 'p7', null, 'dig', 'dig', 'in_play', 3, 7),
  _evt('g5_e18', 'g5', 3, 18, 'p6', 'p1', 'attack', 'kill', 'point_us', 7, 13),
  _evt('g5_e19', 'g5', 3, 19, 'opponent', null, 'serve', 'ace', 'point_them', 10, 19, isOpponent: true),
  _evt('g5_e20', 'g5', 3, 20, 'opponent', null, 'attack', 'kill', 'point_them', 15, 25, isOpponent: true),
];

// ── Mock Player Game Stats ───────────────────────────────────────────────────

final _mockPlayerGameStats = [
  // G1 vs Rockets VBC
  PlayerGameStatsModel(id: 'g1_p1', gameId: 'g1', playerId: 'p1', sport: 'volleyball', stats: {'kills': 2, 'errors': 1, 'totalAttempts': 5, 'assists': 35, 'serviceAces': 1, 'serviceErrors': 1, 'digs': 8, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 0, 'points': 4}, computedAt: _now),
  PlayerGameStatsModel(id: 'g1_p2', gameId: 'g1', playerId: 'p2', sport: 'volleyball', stats: {'kills': 14, 'errors': 4, 'totalAttempts': 32, 'assists': 1, 'serviceAces': 2, 'serviceErrors': 2, 'digs': 6, 'blockSolos': 0, 'blockAssists': 2, 'receptionErrors': 1, 'points': 18}, computedAt: _now),
  PlayerGameStatsModel(id: 'g1_p3', gameId: 'g1', playerId: 'p3', sport: 'volleyball', stats: {'kills': 12, 'errors': 3, 'totalAttempts': 28, 'assists': 0, 'serviceAces': 1, 'serviceErrors': 0, 'digs': 5, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 2, 'points': 14}, computedAt: _now),
  PlayerGameStatsModel(id: 'g1_p4', gameId: 'g1', playerId: 'p4', sport: 'volleyball', stats: {'kills': 6, 'errors': 2, 'totalAttempts': 14, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 1, 'digs': 2, 'blockSolos': 3, 'blockAssists': 2, 'receptionErrors': 0, 'points': 11}, computedAt: _now),
  PlayerGameStatsModel(id: 'g1_p5', gameId: 'g1', playerId: 'p5', sport: 'volleyball', stats: {'kills': 5, 'errors': 1, 'totalAttempts': 11, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 1, 'blockSolos': 2, 'blockAssists': 3, 'receptionErrors': 0, 'points': 9}, computedAt: _now),
  PlayerGameStatsModel(id: 'g1_p6', gameId: 'g1', playerId: 'p6', sport: 'volleyball', stats: {'kills': 8, 'errors': 2, 'totalAttempts': 20, 'assists': 0, 'serviceAces': 2, 'serviceErrors': 1, 'digs': 3, 'blockSolos': 1, 'blockAssists': 2, 'receptionErrors': 1, 'points': 13}, computedAt: _now),
  PlayerGameStatsModel(id: 'g1_p7', gameId: 'g1', playerId: 'p7', sport: 'volleyball', stats: {'kills': 0, 'errors': 0, 'totalAttempts': 0, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 14, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 1, 'points': 0}, computedAt: _now),
  // G2 vs Eagles Club
  PlayerGameStatsModel(id: 'g2_p1', gameId: 'g2', playerId: 'p1', sport: 'volleyball', stats: {'kills': 1, 'errors': 0, 'totalAttempts': 3, 'assists': 38, 'serviceAces': 0, 'serviceErrors': 1, 'digs': 10, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 0, 'points': 1}, computedAt: _now),
  PlayerGameStatsModel(id: 'g2_p2', gameId: 'g2', playerId: 'p2', sport: 'volleyball', stats: {'kills': 16, 'errors': 5, 'totalAttempts': 38, 'assists': 0, 'serviceAces': 2, 'serviceErrors': 1, 'digs': 7, 'blockSolos': 1, 'blockAssists': 1, 'receptionErrors': 2, 'points': 20}, computedAt: _now),
  PlayerGameStatsModel(id: 'g2_p3', gameId: 'g2', playerId: 'p3', sport: 'volleyball', stats: {'kills': 11, 'errors': 4, 'totalAttempts': 30, 'assists': 1, 'serviceAces': 1, 'serviceErrors': 2, 'digs': 4, 'blockSolos': 0, 'blockAssists': 2, 'receptionErrors': 1, 'points': 14}, computedAt: _now),
  PlayerGameStatsModel(id: 'g2_p4', gameId: 'g2', playerId: 'p4', sport: 'volleyball', stats: {'kills': 5, 'errors': 2, 'totalAttempts': 12, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 2, 'blockSolos': 2, 'blockAssists': 1, 'receptionErrors': 0, 'points': 8}, computedAt: _now),
  PlayerGameStatsModel(id: 'g2_p5', gameId: 'g2', playerId: 'p5', sport: 'volleyball', stats: {'kills': 4, 'errors': 1, 'totalAttempts': 10, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 1, 'digs': 1, 'blockSolos': 1, 'blockAssists': 2, 'receptionErrors': 0, 'points': 7}, computedAt: _now),
  PlayerGameStatsModel(id: 'g2_p6', gameId: 'g2', playerId: 'p6', sport: 'volleyball', stats: {'kills': 9, 'errors': 3, 'totalAttempts': 24, 'assists': 0, 'serviceAces': 1, 'serviceErrors': 1, 'digs': 4, 'blockSolos': 1, 'blockAssists': 1, 'receptionErrors': 0, 'points': 12}, computedAt: _now),
  PlayerGameStatsModel(id: 'g2_p7', gameId: 'g2', playerId: 'p7', sport: 'volleyball', stats: {'kills': 0, 'errors': 0, 'totalAttempts': 0, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 18, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 2, 'points': 0}, computedAt: _now),
  // G3 vs Panthers VB
  PlayerGameStatsModel(id: 'g3_p1', gameId: 'g3', playerId: 'p1', sport: 'volleyball', stats: {'kills': 1, 'errors': 0, 'totalAttempts': 2, 'assists': 25, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 5, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 0, 'points': 2}, computedAt: _now),
  PlayerGameStatsModel(id: 'g3_p2', gameId: 'g3', playerId: 'p2', sport: 'volleyball', stats: {'kills': 10, 'errors': 2, 'totalAttempts': 22, 'assists': 0, 'serviceAces': 1, 'serviceErrors': 1, 'digs': 4, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 0, 'points': 12}, computedAt: _now),
  PlayerGameStatsModel(id: 'g3_p3', gameId: 'g3', playerId: 'p3', sport: 'volleyball', stats: {'kills': 8, 'errors': 1, 'totalAttempts': 18, 'assists': 0, 'serviceAces': 2, 'serviceErrors': 0, 'digs': 3, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 1, 'points': 10}, computedAt: _now),
  PlayerGameStatsModel(id: 'g3_p4', gameId: 'g3', playerId: 'p4', sport: 'volleyball', stats: {'kills': 4, 'errors': 1, 'totalAttempts': 9, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 1, 'blockSolos': 2, 'blockAssists': 1, 'receptionErrors': 0, 'points': 7}, computedAt: _now),
  PlayerGameStatsModel(id: 'g3_p5', gameId: 'g3', playerId: 'p5', sport: 'volleyball', stats: {'kills': 3, 'errors': 1, 'totalAttempts': 7, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 0, 'blockSolos': 1, 'blockAssists': 2, 'receptionErrors': 0, 'points': 5}, computedAt: _now),
  PlayerGameStatsModel(id: 'g3_p6', gameId: 'g3', playerId: 'p6', sport: 'volleyball', stats: {'kills': 6, 'errors': 1, 'totalAttempts': 14, 'assists': 0, 'serviceAces': 1, 'serviceErrors': 0, 'digs': 2, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 0, 'points': 8}, computedAt: _now),
  PlayerGameStatsModel(id: 'g3_p7', gameId: 'g3', playerId: 'p7', sport: 'volleyball', stats: {'kills': 0, 'errors': 0, 'totalAttempts': 0, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 12, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 0, 'points': 0}, computedAt: _now),
  // G4 vs Wolves Academy
  PlayerGameStatsModel(id: 'g4_p1', gameId: 'g4', playerId: 'p1', sport: 'volleyball', stats: {'kills': 2, 'errors': 1, 'totalAttempts': 4, 'assists': 40, 'serviceAces': 0, 'serviceErrors': 1, 'digs': 9, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 0, 'points': 3}, computedAt: _now),
  PlayerGameStatsModel(id: 'g4_p2', gameId: 'g4', playerId: 'p2', sport: 'volleyball', stats: {'kills': 13, 'errors': 4, 'totalAttempts': 34, 'assists': 1, 'serviceAces': 1, 'serviceErrors': 2, 'digs': 8, 'blockSolos': 0, 'blockAssists': 2, 'receptionErrors': 1, 'points': 16}, computedAt: _now),
  PlayerGameStatsModel(id: 'g4_p3', gameId: 'g4', playerId: 'p3', sport: 'volleyball', stats: {'kills': 11, 'errors': 3, 'totalAttempts': 26, 'assists': 0, 'serviceAces': 2, 'serviceErrors': 1, 'digs': 5, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 2, 'points': 14}, computedAt: _now),
  PlayerGameStatsModel(id: 'g4_p4', gameId: 'g4', playerId: 'p4', sport: 'volleyball', stats: {'kills': 7, 'errors': 2, 'totalAttempts': 16, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 2, 'blockSolos': 3, 'blockAssists': 2, 'receptionErrors': 0, 'points': 12}, computedAt: _now),
  PlayerGameStatsModel(id: 'g4_p5', gameId: 'g4', playerId: 'p5', sport: 'volleyball', stats: {'kills': 5, 'errors': 2, 'totalAttempts': 12, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 1, 'digs': 1, 'blockSolos': 2, 'blockAssists': 2, 'receptionErrors': 0, 'points': 9}, computedAt: _now),
  PlayerGameStatsModel(id: 'g4_p6', gameId: 'g4', playerId: 'p6', sport: 'volleyball', stats: {'kills': 9, 'errors': 3, 'totalAttempts': 22, 'assists': 0, 'serviceAces': 1, 'serviceErrors': 0, 'digs': 3, 'blockSolos': 1, 'blockAssists': 1, 'receptionErrors': 1, 'points': 12}, computedAt: _now),
  PlayerGameStatsModel(id: 'g4_p7', gameId: 'g4', playerId: 'p7', sport: 'volleyball', stats: {'kills': 0, 'errors': 0, 'totalAttempts': 0, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 16, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 1, 'points': 0}, computedAt: _now),
  // G5 vs Blaze VBC
  PlayerGameStatsModel(id: 'g5_p1', gameId: 'g5', playerId: 'p1', sport: 'volleyball', stats: {'kills': 0, 'errors': 1, 'totalAttempts': 2, 'assists': 18, 'serviceAces': 0, 'serviceErrors': 1, 'digs': 4, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 0, 'points': 0}, computedAt: _now),
  PlayerGameStatsModel(id: 'g5_p2', gameId: 'g5', playerId: 'p2', sport: 'volleyball', stats: {'kills': 8, 'errors': 5, 'totalAttempts': 24, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 1, 'digs': 3, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 2, 'points': 9}, computedAt: _now),
  PlayerGameStatsModel(id: 'g5_p3', gameId: 'g5', playerId: 'p3', sport: 'volleyball', stats: {'kills': 6, 'errors': 4, 'totalAttempts': 20, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 2, 'digs': 2, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 1, 'points': 6}, computedAt: _now),
  PlayerGameStatsModel(id: 'g5_p4', gameId: 'g5', playerId: 'p4', sport: 'volleyball', stats: {'kills': 3, 'errors': 2, 'totalAttempts': 10, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 1, 'blockSolos': 1, 'blockAssists': 1, 'receptionErrors': 0, 'points': 5}, computedAt: _now),
  PlayerGameStatsModel(id: 'g5_p5', gameId: 'g5', playerId: 'p5', sport: 'volleyball', stats: {'kills': 2, 'errors': 1, 'totalAttempts': 6, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 0, 'blockSolos': 1, 'blockAssists': 0, 'receptionErrors': 0, 'points': 3}, computedAt: _now),
  PlayerGameStatsModel(id: 'g5_p6', gameId: 'g5', playerId: 'p6', sport: 'volleyball', stats: {'kills': 5, 'errors': 3, 'totalAttempts': 16, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 1, 'digs': 2, 'blockSolos': 0, 'blockAssists': 1, 'receptionErrors': 1, 'points': 6}, computedAt: _now),
  PlayerGameStatsModel(id: 'g5_p7', gameId: 'g5', playerId: 'p7', sport: 'volleyball', stats: {'kills': 0, 'errors': 0, 'totalAttempts': 0, 'assists': 0, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 10, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 3, 'points': 0}, computedAt: _now),
];

// ── Providers ────────────────────────────────────────────────────────────────

final gamesProvider =
    StateNotifierProvider<GamesNotifier, AsyncValue<List<Game>>>((ref) {
  return GamesNotifier();
});

final selectedGameProvider = StateProvider<Game?>((ref) => null);

final seasonRecordProvider = Provider<Map<String, int>>((ref) {
  final gamesAsync = ref.watch(gamesProvider);
  return gamesAsync.when(
    data: (games) {
      int wins = 0, losses = 0, ties = 0;
      for (final game in games) {
        if (game.status != GameStatus.completed) continue;
        switch (game.result) {
          case GameResult.win:
            wins++;
          case GameResult.loss:
            losses++;
          case GameResult.tie:
            ties++;
          case null:
            break;
        }
      }
      return {'wins': wins, 'losses': losses, 'ties': ties};
    },
    loading: () => {'wins': 0, 'losses': 0, 'ties': 0},
    error: (_, __) => {'wins': 0, 'losses': 0, 'ties': 0},
  );
});

// ── Notifiers ────────────────────────────────────────────────────────────────

class GamesNotifier extends StateNotifier<AsyncValue<List<Game>>> {
  GamesNotifier() : super(const AsyncValue.loading()) {
    loadGames();
  }

  void loadGames() {
    state = AsyncValue.data(List.from(_mockGames));
  }

  void addGame(Game game) {
    state.whenData((games) {
      state = AsyncValue.data([game, ...games]);
    });
  }

  void updateGame(Game game) {
    state.whenData((games) {
      state = AsyncValue.data(
        games.map((g) => g.id == game.id ? game : g).toList(),
      );
    });
  }

  void deleteGame(String id) {
    state.whenData((games) {
      state = AsyncValue.data(games.where((g) => g.id != id).toList());
    });
  }
}
