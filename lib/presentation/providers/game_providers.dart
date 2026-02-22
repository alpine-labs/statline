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
  return repo.getGamePeriods(gameId);
});

/// Fetches per-player game stats (box score data).
final gamePlayerStatsProvider =
    FutureProvider.family<List<PlayerGameStatsModel>, String>(
        (ref, gameId) async {
  final statsRepo = ref.read(_statsRepoForGameDetail);
  return statsRepo.getAllPlayerGameStats(gameId);
});

/// Fetches active play events for a game (play-by-play).
final gamePlayEventsProvider =
    FutureProvider.family<List<PlayEvent>, String>((ref, gameId) async {
  final statsRepo = ref.read(_statsRepoForGameDetail);
  return statsRepo.getActivePlayEventsForGame(gameId);
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
