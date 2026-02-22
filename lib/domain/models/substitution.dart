import 'dart:convert';

class Substitution {
  final String id;
  final String gameId;
  final String periodId;
  final String playerInId;
  final String playerOutId;
  final String? gameClock;
  final bool isLiberoReplacement;
  final Map<String, dynamic> sportMetadata;

  const Substitution({
    required this.id,
    required this.gameId,
    required this.periodId,
    required this.playerInId,
    required this.playerOutId,
    this.gameClock,
    this.isLiberoReplacement = false,
    this.sportMetadata = const {},
  });

  Substitution copyWith({
    String? id,
    String? gameId,
    String? periodId,
    String? playerInId,
    String? playerOutId,
    String? Function()? gameClock,
    bool? isLiberoReplacement,
    Map<String, dynamic>? sportMetadata,
  }) {
    return Substitution(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      periodId: periodId ?? this.periodId,
      playerInId: playerInId ?? this.playerInId,
      playerOutId: playerOutId ?? this.playerOutId,
      gameClock: gameClock != null ? gameClock() : this.gameClock,
      isLiberoReplacement: isLiberoReplacement ?? this.isLiberoReplacement,
      sportMetadata: sportMetadata ?? this.sportMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'period_id': periodId,
      'player_in_id': playerInId,
      'player_out_id': playerOutId,
      'game_clock': gameClock,
      'is_libero_replacement': isLiberoReplacement ? 1 : 0,
      'sport_metadata': jsonEncode(sportMetadata),
    };
  }

  factory Substitution.fromMap(Map<String, dynamic> map) {
    final rawMeta = map['sport_metadata'];
    Map<String, dynamic> meta = const {};
    if (rawMeta is String && rawMeta.isNotEmpty) {
      try {
        meta = Map<String, dynamic>.from(jsonDecode(rawMeta) as Map);
      } catch (_) {}
    } else if (rawMeta is Map) {
      meta = Map<String, dynamic>.from(rawMeta);
    }

    return Substitution(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      periodId: map['period_id'] as String,
      playerInId: map['player_in_id'] as String,
      playerOutId: map['player_out_id'] as String,
      gameClock: map['game_clock'] as String?,
      isLiberoReplacement: map['is_libero_replacement'] == 1 ||
          map['is_libero_replacement'] == true,
      sportMetadata: meta,
    );
  }

  @override
  String toString() {
    return 'Substitution(id: $id, gameId: $gameId, in: $playerInId, out: $playerOutId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Substitution &&
        other.id == id &&
        other.gameId == gameId &&
        other.periodId == periodId &&
        other.playerInId == playerInId &&
        other.playerOutId == playerOutId &&
        other.gameClock == gameClock &&
        other.isLiberoReplacement == isLiberoReplacement;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      gameId,
      periodId,
      playerInId,
      playerOutId,
      gameClock,
      isLiberoReplacement,
    );
  }
}
