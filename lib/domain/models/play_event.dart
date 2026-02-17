import 'dart:convert';

class PlayEvent {
  final String id;
  final String gameId;
  final String periodId;
  final int sequenceNumber;
  final DateTime timestamp;
  final String? gameClock;
  final String playerId;
  final String? secondaryPlayerId;
  final String eventCategory;
  final String eventType;
  final String result;
  final int scoreUsAfter;
  final int scoreThemAfter;
  final bool isOpponent;
  final String? notes;
  final Map<String, dynamic> metadata;
  final bool isDeleted;
  final DateTime createdAt;

  const PlayEvent({
    required this.id,
    required this.gameId,
    required this.periodId,
    required this.sequenceNumber,
    required this.timestamp,
    this.gameClock,
    required this.playerId,
    this.secondaryPlayerId,
    required this.eventCategory,
    required this.eventType,
    required this.result,
    required this.scoreUsAfter,
    required this.scoreThemAfter,
    this.isOpponent = false,
    this.notes,
    this.metadata = const {},
    this.isDeleted = false,
    required this.createdAt,
  });

  PlayEvent copyWith({
    String? id,
    String? gameId,
    String? periodId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? Function()? gameClock,
    String? playerId,
    String? Function()? secondaryPlayerId,
    String? eventCategory,
    String? eventType,
    String? result,
    int? scoreUsAfter,
    int? scoreThemAfter,
    bool? isOpponent,
    String? Function()? notes,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return PlayEvent(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      periodId: periodId ?? this.periodId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      gameClock: gameClock != null ? gameClock() : this.gameClock,
      playerId: playerId ?? this.playerId,
      secondaryPlayerId: secondaryPlayerId != null
          ? secondaryPlayerId()
          : this.secondaryPlayerId,
      eventCategory: eventCategory ?? this.eventCategory,
      eventType: eventType ?? this.eventType,
      result: result ?? this.result,
      scoreUsAfter: scoreUsAfter ?? this.scoreUsAfter,
      scoreThemAfter: scoreThemAfter ?? this.scoreThemAfter,
      isOpponent: isOpponent ?? this.isOpponent,
      notes: notes != null ? notes() : this.notes,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'period_id': periodId,
      'sequence_number': sequenceNumber,
      'timestamp': timestamp.toIso8601String(),
      'game_clock': gameClock,
      'player_id': playerId,
      'secondary_player_id': secondaryPlayerId,
      'event_category': eventCategory,
      'event_type': eventType,
      'result': result,
      'score_us_after': scoreUsAfter,
      'score_them_after': scoreThemAfter,
      'is_opponent': isOpponent ? 1 : 0,
      'notes': notes,
      'metadata': jsonEncode(metadata),
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PlayEvent.fromMap(Map<String, dynamic> map) {
    final metadataRaw = map['metadata'];
    Map<String, dynamic> metadata;
    if (metadataRaw is String) {
      metadata = Map<String, dynamic>.from(jsonDecode(metadataRaw) as Map);
    } else if (metadataRaw is Map) {
      metadata = Map<String, dynamic>.from(metadataRaw);
    } else {
      metadata = {};
    }

    return PlayEvent(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      periodId: map['period_id'] as String,
      sequenceNumber: map['sequence_number'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      gameClock: map['game_clock'] as String?,
      playerId: map['player_id'] as String,
      secondaryPlayerId: map['secondary_player_id'] as String?,
      eventCategory: map['event_category'] as String,
      eventType: map['event_type'] as String,
      result: map['result'] as String,
      scoreUsAfter: map['score_us_after'] as int,
      scoreThemAfter: map['score_them_after'] as int,
      isOpponent: map['is_opponent'] == 1 || map['is_opponent'] == true,
      notes: map['notes'] as String?,
      metadata: metadata,
      isDeleted: map['is_deleted'] == 1 || map['is_deleted'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'PlayEvent(id: $id, type: $eventType, result: $result, score: $scoreUsAfter-$scoreThemAfter)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlayEvent) return false;
    return other.id == id &&
        other.gameId == gameId &&
        other.periodId == periodId &&
        other.sequenceNumber == sequenceNumber &&
        other.timestamp == timestamp &&
        other.gameClock == gameClock &&
        other.playerId == playerId &&
        other.secondaryPlayerId == secondaryPlayerId &&
        other.eventCategory == eventCategory &&
        other.eventType == eventType &&
        other.result == result &&
        other.scoreUsAfter == scoreUsAfter &&
        other.scoreThemAfter == scoreThemAfter &&
        other.isOpponent == isOpponent &&
        other.notes == notes &&
        other.isDeleted == isDeleted &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      gameId,
      periodId,
      sequenceNumber,
      timestamp,
      gameClock,
      playerId,
      secondaryPlayerId,
      eventCategory,
      eventType,
      result,
      scoreUsAfter,
      scoreThemAfter,
      isOpponent,
      notes,
      isDeleted,
      createdAt,
    );
  }
}
