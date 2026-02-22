import 'dart:convert';

class GameLineup {
  final String id;
  final String gameId;
  final String playerId;
  final int? battingOrder;
  final String position;
  final int? startingRotation;
  final bool isStarter;
  final String status;
  final Map<String, dynamic> sportMetadata;

  const GameLineup({
    required this.id,
    required this.gameId,
    required this.playerId,
    this.battingOrder,
    required this.position,
    this.startingRotation,
    this.isStarter = true,
    this.status = 'active',
    this.sportMetadata = const {},
  });

  GameLineup copyWith({
    String? id,
    String? gameId,
    String? playerId,
    int? Function()? battingOrder,
    String? position,
    int? Function()? startingRotation,
    bool? isStarter,
    String? status,
    Map<String, dynamic>? sportMetadata,
  }) {
    return GameLineup(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      battingOrder:
          battingOrder != null ? battingOrder() : this.battingOrder,
      position: position ?? this.position,
      startingRotation: startingRotation != null
          ? startingRotation()
          : this.startingRotation,
      isStarter: isStarter ?? this.isStarter,
      status: status ?? this.status,
      sportMetadata: sportMetadata ?? this.sportMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'player_id': playerId,
      'batting_order': battingOrder,
      'position': position,
      'starting_rotation': startingRotation,
      'is_starter': isStarter ? 1 : 0,
      'status': status,
      'sport_metadata': jsonEncode(sportMetadata),
    };
  }

  factory GameLineup.fromMap(Map<String, dynamic> map) {
    final rawMeta = map['sport_metadata'];
    Map<String, dynamic> meta = const {};
    if (rawMeta is String && rawMeta.isNotEmpty) {
      try {
        meta = Map<String, dynamic>.from(jsonDecode(rawMeta) as Map);
      } catch (_) {}
    } else if (rawMeta is Map) {
      meta = Map<String, dynamic>.from(rawMeta);
    }

    return GameLineup(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      playerId: map['player_id'] as String,
      battingOrder: map['batting_order'] as int?,
      position: map['position'] as String,
      startingRotation: map['starting_rotation'] as int?,
      isStarter: map['is_starter'] == 1 || map['is_starter'] == true,
      status: map['status'] as String? ?? 'active',
      sportMetadata: meta,
    );
  }

  @override
  String toString() {
    return 'GameLineup(id: $id, gameId: $gameId, playerId: $playerId, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameLineup &&
        other.id == id &&
        other.gameId == gameId &&
        other.playerId == playerId &&
        other.battingOrder == battingOrder &&
        other.position == position &&
        other.startingRotation == startingRotation &&
        other.isStarter == isStarter &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      gameId,
      playerId,
      battingOrder,
      position,
      startingRotation,
      isStarter,
      status,
    );
  }
}
