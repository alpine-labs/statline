import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game.dart';
import '../../domain/models/game_period.dart';
import '../../domain/models/play_event.dart';
import '../../domain/models/player.dart';

// ── LiveGameState ────────────────────────────────────────────────────────────

class LiveGameState {
  final Game? game;
  final List<GamePeriod> periods;
  final GamePeriod? currentPeriod;
  final List<PlayEvent> playEvents;
  final int scoreUs;
  final int scoreThem;
  final String entryMode; // 'quick' or 'detailed'
  final int? currentRotation; // volleyball: 1-6
  final List<PlayEvent> undoStack;
  final List<Player> roster;
  final String? selectedPlayerId;

  const LiveGameState({
    this.game,
    this.periods = const [],
    this.currentPeriod,
    this.playEvents = const [],
    this.scoreUs = 0,
    this.scoreThem = 0,
    this.entryMode = 'quick',
    this.currentRotation,
    this.undoStack = const [],
    this.roster = const [],
    this.selectedPlayerId,
  });

  factory LiveGameState.initial() => const LiveGameState();

  bool get isActive => game != null && game!.status == GameStatus.inProgress;

  LiveGameState copyWith({
    Game? Function()? game,
    List<GamePeriod>? periods,
    GamePeriod? Function()? currentPeriod,
    List<PlayEvent>? playEvents,
    int? scoreUs,
    int? scoreThem,
    String? entryMode,
    int? Function()? currentRotation,
    List<PlayEvent>? undoStack,
    List<Player>? roster,
    String? Function()? selectedPlayerId,
  }) {
    return LiveGameState(
      game: game != null ? game() : this.game,
      periods: periods ?? this.periods,
      currentPeriod:
          currentPeriod != null ? currentPeriod() : this.currentPeriod,
      playEvents: playEvents ?? this.playEvents,
      scoreUs: scoreUs ?? this.scoreUs,
      scoreThem: scoreThem ?? this.scoreThem,
      entryMode: entryMode ?? this.entryMode,
      currentRotation:
          currentRotation != null ? currentRotation() : this.currentRotation,
      undoStack: undoStack ?? this.undoStack,
      roster: roster ?? this.roster,
      selectedPlayerId:
          selectedPlayerId != null ? selectedPlayerId() : this.selectedPlayerId,
    );
  }
}

// ── LiveGameNotifier ─────────────────────────────────────────────────────────

class LiveGameNotifier extends StateNotifier<LiveGameState> {
  LiveGameNotifier() : super(LiveGameState.initial());

  void startGame(Game game, List<Player> roster) {
    final firstPeriod = GamePeriod(
      id: 'period_1',
      gameId: game.id,
      periodNumber: 1,
      periodType: 'set',
    );

    state = state.copyWith(
      game: () => game.copyWith(status: GameStatus.inProgress),
      roster: roster,
      periods: [firstPeriod],
      currentPeriod: () => firstPeriod,
      playEvents: [],
      scoreUs: 0,
      scoreThem: 0,
      undoStack: [],
      currentRotation: () => 1,
      selectedPlayerId: () => null,
    );
  }

  void selectPlayer(String? playerId) {
    state = state.copyWith(selectedPlayerId: () => playerId);
  }

  void recordEvent(PlayEvent event) {
    state = state.copyWith(
      playEvents: [...state.playEvents, event],
      undoStack: [...state.undoStack, event],
      scoreUs: event.scoreUsAfter,
      scoreThem: event.scoreThemAfter,
      selectedPlayerId: () => null,
    );

    // Update current period score
    if (state.currentPeriod != null) {
      final updatedPeriod = state.currentPeriod!.copyWith(
        scoreUs: event.scoreUsAfter,
        scoreThem: event.scoreThemAfter,
      );
      final updatedPeriods = state.periods
          .map((p) => p.id == updatedPeriod.id ? updatedPeriod : p)
          .toList();
      state = state.copyWith(
        periods: updatedPeriods,
        currentPeriod: () => updatedPeriod,
      );
    }
  }

  void undoLastEvent() {
    if (state.undoStack.isEmpty) return;

    final lastEvent = state.undoStack.last;
    final newUndoStack = List<PlayEvent>.from(state.undoStack)..removeLast();
    final newPlayEvents =
        state.playEvents.where((e) => e.id != lastEvent.id).toList();

    // Revert score to previous state
    int prevScoreUs = 0;
    int prevScoreThem = 0;
    if (newPlayEvents.isNotEmpty) {
      prevScoreUs = newPlayEvents.last.scoreUsAfter;
      prevScoreThem = newPlayEvents.last.scoreThemAfter;
    }

    state = state.copyWith(
      playEvents: newPlayEvents,
      undoStack: newUndoStack,
      scoreUs: prevScoreUs,
      scoreThem: prevScoreThem,
    );
  }

  void toggleEntryMode() {
    state = state.copyWith(
      entryMode: state.entryMode == 'quick' ? 'detailed' : 'quick',
    );
  }

  void advancePeriod() {
    if (state.game == null) return;

    final nextNumber = state.periods.length + 1;
    final newPeriod = GamePeriod(
      id: 'period_$nextNumber',
      gameId: state.game!.id,
      periodNumber: nextNumber,
      periodType: 'set',
    );

    state = state.copyWith(
      periods: [...state.periods, newPeriod],
      currentPeriod: () => newPeriod,
      scoreUs: 0,
      scoreThem: 0,
    );
  }

  void updateScore(int us, int them) {
    state = state.copyWith(scoreUs: us, scoreThem: them);
  }

  void endGame() {
    if (state.game == null) return;

    // Determine result
    int setsWonUs = 0;
    int setsWonThem = 0;
    for (final period in state.periods) {
      if (period.scoreUs > period.scoreThem) {
        setsWonUs++;
      } else if (period.scoreThem > period.scoreUs) {
        setsWonThem++;
      }
    }

    GameResult result;
    if (setsWonUs > setsWonThem) {
      result = GameResult.win;
    } else if (setsWonThem > setsWonUs) {
      result = GameResult.loss;
    } else {
      result = GameResult.tie;
    }

    state = state.copyWith(
      game: () => state.game!.copyWith(
        status: GameStatus.completed,
        finalScoreUs: () => setsWonUs,
        finalScoreThem: () => setsWonThem,
        result: () => result,
      ),
    );
  }

  void reset() {
    state = LiveGameState.initial();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final liveGameStateProvider =
    StateNotifierProvider<LiveGameNotifier, LiveGameState>((ref) {
  return LiveGameNotifier();
});

final selectedPlayerIdProvider = Provider<String?>((ref) {
  return ref.watch(liveGameStateProvider).selectedPlayerId;
});
