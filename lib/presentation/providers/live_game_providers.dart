import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game.dart';
import '../../domain/models/game_lineup.dart';
import '../../domain/models/game_period.dart';
import '../../domain/models/play_event.dart';
import '../../domain/models/player.dart';
import '../../domain/sports/sport_game_engine.dart';
import '../../domain/sports/sport_engine_registry.dart';

// ── LiveGameState ────────────────────────────────────────────────────────────

class LiveGameState {
  final Game? game;
  final List<GamePeriod> periods;
  final GamePeriod? currentPeriod;
  final List<PlayEvent> playEvents;
  final int scoreUs;
  final int scoreThem;
  final String entryMode; // 'quick' or 'detailed'
  final List<PlayEvent> undoStack;
  final List<Player> roster;
  final String? selectedPlayerId;
  final int timeoutsUs;
  final int timeoutsThem;
  final List<GameLineup> lineup;
  /// Sport-specific state managed by [SportGameEngine].
  final Map<String, dynamic> sportState;

  const LiveGameState({
    this.game,
    this.periods = const [],
    this.currentPeriod,
    this.playEvents = const [],
    this.scoreUs = 0,
    this.scoreThem = 0,
    this.entryMode = 'quick',
    this.undoStack = const [],
    this.roster = const [],
    this.selectedPlayerId,
    this.timeoutsUs = 0,
    this.timeoutsThem = 0,
    this.lineup = const [],
    this.sportState = const {},
  });

  factory LiveGameState.initial() => const LiveGameState();

  bool get isActive => game != null && game!.status == GameStatus.inProgress;

  // ── Convenience getters for volleyball sport state (backward compat) ──
  int? get currentRotation => sportState['currentRotation'] as int?;
  String? get servingTeam => sportState['servingTeam'] as String?;
  String? get liberoPlayerId => sportState['liberoPlayerId'] as String?;
  bool get liberoIsIn => sportState['liberoIsIn'] as bool? ?? false;
  String? get liberoReplacedPlayerId =>
      sportState['liberoReplacedPlayerId'] as String?;
  int get firstBallSideouts =>
      sportState['firstBallSideouts'] as int? ?? 0;
  int get totalSideouts => sportState['totalSideouts'] as int? ?? 0;
  int get sideoutOpportunities =>
      sportState['sideoutOpportunities'] as int? ?? 0;
  bool get inFirstBallSequence =>
      sportState['inFirstBallSequence'] as bool? ?? false;
  int get attacksSinceReception =>
      sportState['attacksSinceReception'] as int? ?? 0;
  int get subsThisSet => sportState['subsThisSet'] as int? ?? 0;
  int get maxSubsPerSet => sportState['maxSubsPerSet'] as int? ?? 15;
  int get maxTimeoutsPerSet {
    if (_engine != null) return _engine!.maxTimeoutsPerPeriod;
    return 2;
  }

  // Engine reference for computed properties (not serialized)
  SportGameEngine? get _engine {
    final sport = game?.sport;
    if (sport == null) return null;
    return SportEngineRegistry.tryGetEngine(sport);
  }

  LiveGameState copyWith({
    Game? Function()? game,
    List<GamePeriod>? periods,
    GamePeriod? Function()? currentPeriod,
    List<PlayEvent>? playEvents,
    int? scoreUs,
    int? scoreThem,
    String? entryMode,
    List<PlayEvent>? undoStack,
    List<Player>? roster,
    String? Function()? selectedPlayerId,
    int? timeoutsUs,
    int? timeoutsThem,
    List<GameLineup>? lineup,
    Map<String, dynamic>? sportState,
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
      undoStack: undoStack ?? this.undoStack,
      roster: roster ?? this.roster,
      selectedPlayerId:
          selectedPlayerId != null ? selectedPlayerId() : this.selectedPlayerId,
      timeoutsUs: timeoutsUs ?? this.timeoutsUs,
      timeoutsThem: timeoutsThem ?? this.timeoutsThem,
      lineup: lineup ?? this.lineup,
      sportState: sportState ?? this.sportState,
    );
  }
}

// ── LiveGameNotifier ─────────────────────────────────────────────────────────

class LiveGameNotifier extends StateNotifier<LiveGameState> {
  LiveGameNotifier() : super(LiveGameState.initial());

  SportGameEngine? _engine;

  void startGame(Game game, List<Player> roster,
      {int? maxSubsPerSet, List<GameLineup>? lineup}) {
    _engine = SportEngineRegistry.getEngine(game.sport);

    final firstPeriod = GamePeriod(
      id: 'period_1',
      gameId: game.id,
      periodNumber: 1,
      periodType: _engine!.periodType,
    );

    var sportState = _engine!.initialState(
      game: game,
      lineup: lineup ?? const [],
    );
    if (maxSubsPerSet != null) {
      sportState = Map<String, dynamic>.from(sportState);
      sportState['maxSubsPerSet'] = maxSubsPerSet;
    }

    state = state.copyWith(
      game: () => game.copyWith(status: GameStatus.inProgress),
      roster: roster,
      periods: [firstPeriod],
      currentPeriod: () => firstPeriod,
      playEvents: [],
      scoreUs: 0,
      scoreThem: 0,
      undoStack: [],
      selectedPlayerId: () => null,
      timeoutsUs: 0,
      timeoutsThem: 0,
      lineup: lineup ?? const [],
      sportState: sportState,
    );
  }

  void selectPlayer(String? playerId) {
    state = state.copyWith(selectedPlayerId: () => playerId);
  }

  void recordEvent(PlayEvent event) {
    if (_engine == null) return;

    // Enrich event with sport-specific metadata
    final metadata = {
      ...event.metadata,
      if (state.currentRotation != null) 'rotation': state.currentRotation,
      if (state.servingTeam != null) 'servingTeam': state.servingTeam,
    };
    final enrichedEvent = event.copyWith(metadata: metadata);

    final prevScoreUs = state.scoreUs;
    final prevScoreThem = state.scoreThem;

    // Delegate sport-specific state update to the engine
    final newSportState = _engine!.onEventRecorded(
      event: enrichedEvent,
      sportState: state.sportState,
      scoreUs: enrichedEvent.scoreUsAfter,
      scoreThem: enrichedEvent.scoreThemAfter,
      prevScoreUs: prevScoreUs,
      prevScoreThem: prevScoreThem,
      lineup: state.lineup,
    );

    // Auto-select server when we gain serve via sideout
    String? newSelectedPlayer;
    final scoredUs = enrichedEvent.scoreUsAfter > prevScoreUs;
    final prevServing = state.servingTeam;
    if (scoredUs && prevServing == 'them') {
      newSelectedPlayer =
          _engine!.getActivePlayerId(newSportState, state.lineup);
    }

    state = state.copyWith(
      playEvents: [...state.playEvents, enrichedEvent],
      undoStack: [...state.undoStack, enrichedEvent],
      scoreUs: enrichedEvent.scoreUsAfter,
      scoreThem: enrichedEvent.scoreThemAfter,
      selectedPlayerId: () => newSelectedPlayer,
      sportState: newSportState,
    );

    // Update current period score
    if (state.currentPeriod != null) {
      final updatedPeriod = state.currentPeriod!.copyWith(
        scoreUs: enrichedEvent.scoreUsAfter,
        scoreThem: enrichedEvent.scoreThemAfter,
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
    if (state.game == null || _engine == null) return;

    final nextNumber = state.periods.length + 1;
    final newPeriod = GamePeriod(
      id: 'period_$nextNumber',
      gameId: state.game!.id,
      periodNumber: nextNumber,
      periodType: _engine!.periodType,
    );

    final newSportState = _engine!.onPeriodAdvanced(
      newPeriodNumber: nextNumber,
      sportState: state.sportState,
    );

    state = state.copyWith(
      periods: [...state.periods, newPeriod],
      currentPeriod: () => newPeriod,
      scoreUs: 0,
      scoreThem: 0,
      timeoutsUs: 0,
      timeoutsThem: 0,
      sportState: newSportState,
    );
  }

  void callTimeout(bool isUs) {
    final maxTimeouts = _engine?.maxTimeoutsPerPeriod ?? 2;
    if (isUs) {
      if (state.timeoutsUs >= maxTimeouts) return;
      state = state.copyWith(timeoutsUs: state.timeoutsUs + 1);
    } else {
      if (state.timeoutsThem >= maxTimeouts) return;
      state = state.copyWith(timeoutsThem: state.timeoutsThem + 1);
    }
  }

  void undoTimeout(bool isUs) {
    if (isUs) {
      if (state.timeoutsUs <= 0) return;
      state = state.copyWith(timeoutsUs: state.timeoutsUs - 1);
    } else {
      if (state.timeoutsThem <= 0) return;
      state = state.copyWith(timeoutsThem: state.timeoutsThem - 1);
    }
  }

  void recordSubstitution() {
    if (_engine == null) return;
    if (!_engine!.canSubstitute(state.sportState)) return;
    try {
      final newState = (_engine as dynamic).recordSubstitution(state.sportState) as Map<String, dynamic>;
      state = state.copyWith(sportState: newState);
    } catch (_) {
      // Engine doesn't support recordSubstitution — no-op
    }
  }

  /// Swaps a court player out and a bench player in, updating the lineup.
  /// Also increments the substitution counter.
  void substitutePlayer({
    required String playerOutId,
    required String playerInId,
  }) {
    if (_engine == null || !_engine!.canSubstitute(state.sportState)) return;
    final updatedLineup = state.lineup.map((entry) {
      if (entry.playerId == playerOutId) {
        return entry.copyWith(playerId: playerInId);
      }
      return entry;
    }).toList();

    Map<String, dynamic>? newSportState;
    try {
      newSportState = (_engine as dynamic).recordSubstitution(state.sportState) as Map<String, dynamic>;
    } catch (_) {
      newSportState = state.sportState;
    }

    state = state.copyWith(
      lineup: updatedLineup,
      selectedPlayerId: () => null,
      sportState: newSportState,
    );
  }

  // ── Sport-specific delegated methods ────────────────────────────────────
  // These delegate to the engine for sport-specific operations.
  // UI code can call these and the engine handles the details.

  void toggleServe() {
    if (_engine == null) return;
    try {
      final newState = (_engine as dynamic).toggleServe(state.sportState) as Map<String, dynamic>;
      state = state.copyWith(sportState: newState);
    } catch (_) {
      // Fallback for engines that don't support toggleServe
    }
  }

  void rotateForward() {
    if (_engine == null) return;
    try {
      final newState = (_engine as dynamic).rotateForward(state.sportState) as Map<String, dynamic>;
      state = state.copyWith(sportState: newState);
    } catch (_) {}
  }

  void rotateBackward() {
    if (_engine == null) return;
    try {
      final newState = (_engine as dynamic).rotateBackward(state.sportState) as Map<String, dynamic>;
      state = state.copyWith(sportState: newState);
    } catch (_) {}
  }

  void setLibero(String playerId) {
    if (_engine == null) return;
    try {
      final newState = (_engine as dynamic).setLibero(state.sportState, playerId) as Map<String, dynamic>;
      state = state.copyWith(sportState: newState);
    } catch (_) {}
  }

  void liberoIn(String replacedPlayerId) {
    if (_engine == null) return;
    try {
      final newState = (_engine as dynamic).liberoIn(state.sportState, replacedPlayerId) as Map<String, dynamic>;
      state = state.copyWith(sportState: newState);
    } catch (_) {}
  }

  void liberoOut() {
    if (_engine == null) return;
    try {
      final newState = (_engine as dynamic).liberoOut(state.sportState) as Map<String, dynamic>;
      state = state.copyWith(sportState: newState);
    } catch (_) {}
  }

  void updateScore(int us, int them) {
    state = state.copyWith(scoreUs: us, scoreThem: them);
  }

  void endGame() {
    if (state.game == null || _engine == null) return;

    final result = _engine!.determineWinner(state.periods);
    final scores = _engine!.finalScore(state.periods);

    state = state.copyWith(
      game: () => state.game!.copyWith(
        status: GameStatus.completed,
        finalScoreUs: () => scores.scoreUs,
        finalScoreThem: () => scores.scoreThem,
        result: () => result,
      ),
    );
  }

  void reset() {
    _engine = null;
    state = LiveGameState.initial();
  }

  // ── Server identification ───────────────────────────────────────────────

  /// Returns the player ID of the current active player (server for volleyball).
  String? getServerPlayerId() {
    if (_engine == null) return null;
    return _engine!.getActivePlayerId(state.sportState, state.lineup);
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
