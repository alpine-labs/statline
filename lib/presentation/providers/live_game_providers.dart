import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game.dart';
import '../../domain/models/game_lineup.dart';
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
  final int timeoutsUs;
  final int timeoutsThem;
  final int maxTimeoutsPerSet;
  final int subsThisSet;
  final int maxSubsPerSet;
  final String? liberoPlayerId;
  final bool liberoIsIn;
  final String? liberoReplacedPlayerId;
  final String? servingTeam; // 'us' or 'them'
  final int firstBallSideouts;
  final int totalSideouts;
  final int sideoutOpportunities;
  final bool inFirstBallSequence;
  final int attacksSinceReception;
  final List<GameLineup> lineup;

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
    this.timeoutsUs = 0,
    this.timeoutsThem = 0,
    this.maxTimeoutsPerSet = 2,
    this.subsThisSet = 0,
    this.maxSubsPerSet = 15,
    this.liberoPlayerId,
    this.liberoIsIn = false,
    this.liberoReplacedPlayerId,
    this.servingTeam,
    this.firstBallSideouts = 0,
    this.totalSideouts = 0,
    this.sideoutOpportunities = 0,
    this.inFirstBallSequence = false,
    this.attacksSinceReception = 0,
    this.lineup = const [],
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
    int? timeoutsUs,
    int? timeoutsThem,
    int? maxTimeoutsPerSet,
    int? subsThisSet,
    int? maxSubsPerSet,
    String? Function()? liberoPlayerId,
    bool? liberoIsIn,
    String? Function()? liberoReplacedPlayerId,
    String? Function()? servingTeam,
    int? firstBallSideouts,
    int? totalSideouts,
    int? sideoutOpportunities,
    bool? inFirstBallSequence,
    int? attacksSinceReception,
    List<GameLineup>? lineup,
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
      timeoutsUs: timeoutsUs ?? this.timeoutsUs,
      timeoutsThem: timeoutsThem ?? this.timeoutsThem,
      maxTimeoutsPerSet: maxTimeoutsPerSet ?? this.maxTimeoutsPerSet,
      subsThisSet: subsThisSet ?? this.subsThisSet,
      maxSubsPerSet: maxSubsPerSet ?? this.maxSubsPerSet,
      liberoPlayerId:
          liberoPlayerId != null ? liberoPlayerId() : this.liberoPlayerId,
      liberoIsIn: liberoIsIn ?? this.liberoIsIn,
      liberoReplacedPlayerId: liberoReplacedPlayerId != null
          ? liberoReplacedPlayerId()
          : this.liberoReplacedPlayerId,
      servingTeam:
          servingTeam != null ? servingTeam() : this.servingTeam,
      firstBallSideouts: firstBallSideouts ?? this.firstBallSideouts,
      totalSideouts: totalSideouts ?? this.totalSideouts,
      sideoutOpportunities: sideoutOpportunities ?? this.sideoutOpportunities,
      inFirstBallSequence: inFirstBallSequence ?? this.inFirstBallSequence,
      attacksSinceReception: attacksSinceReception ?? this.attacksSinceReception,
      lineup: lineup ?? this.lineup,
    );
  }
}

// ── LiveGameNotifier ─────────────────────────────────────────────────────────

class LiveGameNotifier extends StateNotifier<LiveGameState> {
  LiveGameNotifier() : super(LiveGameState.initial());

  void startGame(Game game, List<Player> roster, {int? maxSubsPerSet, List<GameLineup>? lineup}) {
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
      timeoutsUs: 0,
      timeoutsThem: 0,
      subsThisSet: 0,
      maxSubsPerSet: maxSubsPerSet,
      servingTeam: () => 'us',
      firstBallSideouts: 0,
      totalSideouts: 0,
      sideoutOpportunities: 0,
      inFirstBallSequence: false,
      attacksSinceReception: 0,
      lineup: lineup ?? const [],
    );
  }

  void selectPlayer(String? playerId) {
    state = state.copyWith(selectedPlayerId: () => playerId);
  }

  void recordEvent(PlayEvent event) {
    // Enrich event with current rotation and serving team metadata
    final metadata = {
      ...event.metadata,
      if (state.currentRotation != null) 'rotation': state.currentRotation,
      if (state.servingTeam != null) 'servingTeam': state.servingTeam,
    };
    final enrichedEvent = event.copyWith(metadata: metadata);

    // ── First-ball sideout tracking ──
    bool newInFirstBall = state.inFirstBallSequence;
    int newAttacks = state.attacksSinceReception;
    int newFirstBallSideouts = state.firstBallSideouts;
    int newTotalSideouts = state.totalSideouts;
    int newSideoutOpps = state.sideoutOpportunities;

    if (_isReceptionEvent(enrichedEvent.eventType)) {
      newInFirstBall = true;
      newAttacks = 0;
    }
    if (_isAttackEvent(enrichedEvent.eventType)) {
      newAttacks++;
    }
    // Dig breaks first-ball sequence (extended rally)
    if (enrichedEvent.eventType == 'dig' ||
        enrichedEvent.eventType == 'dig_error') {
      newInFirstBall = false;
    }

    // ── Score changes, serving team toggle, auto-rotate ──
    String? newServingTeam = state.servingTeam;
    int? newRotation = state.currentRotation;
    final scoredUs = enrichedEvent.scoreUsAfter > state.scoreUs;
    final scoredThem = enrichedEvent.scoreThemAfter > state.scoreThem;

    // Sideout opportunity: any point while opponent serves
    if (state.servingTeam == 'them' && (scoredUs || scoredThem)) {
      newSideoutOpps++;
    }

    if (scoredUs && state.servingTeam == 'them') {
      // Side-out for us: we get serve, advance rotation
      newServingTeam = 'us';
      newTotalSideouts++;
      if (newInFirstBall && newAttacks == 1) {
        newFirstBallSideouts++;
      }
      if (newRotation != null) {
        newRotation = (newRotation % 6) + 1;
      }
    } else if (scoredThem && state.servingTeam == 'us') {
      // Side-out for them
      newServingTeam = 'them';
    }

    // Reset first-ball tracking on any point
    if (scoredUs || scoredThem) {
      newInFirstBall = false;
      newAttacks = 0;
    }

    // Auto-select server when we gain serve via sideout
    String? newSelectedPlayer;
    if (scoredUs && state.servingTeam == 'them') {
      newSelectedPlayer = _getServerPlayerId(newRotation);
    }

    state = state.copyWith(
      playEvents: [...state.playEvents, enrichedEvent],
      undoStack: [...state.undoStack, enrichedEvent],
      scoreUs: enrichedEvent.scoreUsAfter,
      scoreThem: enrichedEvent.scoreThemAfter,
      selectedPlayerId: () => newSelectedPlayer,
      servingTeam: () => newServingTeam,
      currentRotation: () => newRotation,
      firstBallSideouts: newFirstBallSideouts,
      totalSideouts: newTotalSideouts,
      sideoutOpportunities: newSideoutOpps,
      inFirstBallSequence: newInFirstBall,
      attacksSinceReception: newAttacks,
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
    if (state.game == null) return;

    final nextNumber = state.periods.length + 1;
    final newPeriod = GamePeriod(
      id: 'period_$nextNumber',
      gameId: state.game!.id,
      periodNumber: nextNumber,
      periodType: 'set',
    );

    // Alternate serve at the start of each new set
    final newServing = state.servingTeam == 'us' ? 'them' : 'us';

    state = state.copyWith(
      periods: [...state.periods, newPeriod],
      currentPeriod: () => newPeriod,
      scoreUs: 0,
      scoreThem: 0,
      timeoutsUs: 0,
      timeoutsThem: 0,
      subsThisSet: 0,
      servingTeam: () => newServing,
      inFirstBallSequence: false,
      attacksSinceReception: 0,
    );
  }

  void callTimeout(bool isUs) {
    if (isUs) {
      if (state.timeoutsUs >= state.maxTimeoutsPerSet) return;
      state = state.copyWith(timeoutsUs: state.timeoutsUs + 1);
    } else {
      if (state.timeoutsThem >= state.maxTimeoutsPerSet) return;
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
    if (state.subsThisSet >= state.maxSubsPerSet) return;
    state = state.copyWith(subsThisSet: state.subsThisSet + 1);
  }

  /// Swaps a court player out and a bench player in, updating the lineup.
  /// Also increments the substitution counter.
  void substitutePlayer({
    required String playerOutId,
    required String playerInId,
  }) {
    if (state.subsThisSet >= state.maxSubsPerSet) return;
    final updatedLineup = state.lineup.map((entry) {
      if (entry.playerId == playerOutId) {
        return entry.copyWith(playerId: playerInId);
      }
      return entry;
    }).toList();
    state = state.copyWith(
      lineup: updatedLineup,
      subsThisSet: state.subsThisSet + 1,
      selectedPlayerId: () => null,
    );
  }

  void toggleServe() {
    final current = state.servingTeam ?? 'us';
    state = state.copyWith(
      servingTeam: () => current == 'us' ? 'them' : 'us',
    );
  }

  void rotateForward() {
    final current = state.currentRotation ?? 1;
    final next = current >= 6 ? 1 : current + 1;
    state = state.copyWith(currentRotation: () => next);
  }

  void rotateBackward() {
    final current = state.currentRotation ?? 1;
    final prev = current <= 1 ? 6 : current - 1;
    state = state.copyWith(currentRotation: () => prev);
  }

  void setLibero(String playerId) {
    state = state.copyWith(
      liberoPlayerId: () => playerId,
      liberoIsIn: false,
      liberoReplacedPlayerId: () => null,
    );
  }

  void liberoIn(String replacedPlayerId) {
    if (state.liberoPlayerId == null) return;
    state = state.copyWith(
      liberoIsIn: true,
      liberoReplacedPlayerId: () => replacedPlayerId,
    );
  }

  void liberoOut() {
    state = state.copyWith(
      liberoIsIn: false,
      liberoReplacedPlayerId: () => null,
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

  // ── Serve tracking ──────────────────────────────────────────────────────

  /// Returns the player ID of the current server (Position 1 in rotation).
  String? getServerPlayerId() => _getServerPlayerId(state.currentRotation);

  String? _getServerPlayerId(int? rotation) {
    if (rotation == null || state.lineup.isEmpty) return null;
    final match = state.lineup.where((l) => l.startingRotation == rotation);
    return match.isNotEmpty ? match.first.playerId : null;
  }

  // ── Event classification helpers ────────────────────────────────────────

  static bool _isReceptionEvent(String eventType) {
    return const {'pass_3', 'pass_2', 'pass_1', 'pass_0', 'overpass', 'pass_error'}
        .contains(eventType);
  }

  static bool _isAttackEvent(String eventType) {
    return const {'kill', 'attack_error', 'blocked', 'zero_attack'}
        .contains(eventType);
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
