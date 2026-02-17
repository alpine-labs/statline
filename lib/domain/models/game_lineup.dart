class GameLineup {
  final String id;
  final String gameId;
  final String playerId;
  final int? battingOrder;
  final String position;
  final int? startingRotation;
  final bool isStarter;
  final String status;

  const GameLineup({
    required this.id,
    required this.gameId,
    required this.playerId,
    this.battingOrder,
    required this.position,
    this.startingRotation,
    this.isStarter = true,
    this.status = 'active',
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
    };
  }

  factory GameLineup.fromMap(Map<String, dynamic> map) {
    return GameLineup(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      playerId: map['player_id'] as String,
      battingOrder: map['batting_order'] as int?,
      position: map['position'] as String,
      startingRotation: map['starting_rotation'] as int?,
      isStarter: map['is_starter'] == 1 || map['is_starter'] == true,
      status: map['status'] as String? ?? 'active',
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
