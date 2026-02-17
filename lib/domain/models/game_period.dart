class GamePeriod {
  final String id;
  final String gameId;
  final int periodNumber;
  final String periodType;
  final int scoreUs;
  final int scoreThem;

  const GamePeriod({
    required this.id,
    required this.gameId,
    required this.periodNumber,
    required this.periodType,
    this.scoreUs = 0,
    this.scoreThem = 0,
  });

  GamePeriod copyWith({
    String? id,
    String? gameId,
    int? periodNumber,
    String? periodType,
    int? scoreUs,
    int? scoreThem,
  }) {
    return GamePeriod(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      periodNumber: periodNumber ?? this.periodNumber,
      periodType: periodType ?? this.periodType,
      scoreUs: scoreUs ?? this.scoreUs,
      scoreThem: scoreThem ?? this.scoreThem,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'period_number': periodNumber,
      'period_type': periodType,
      'score_us': scoreUs,
      'score_them': scoreThem,
    };
  }

  factory GamePeriod.fromMap(Map<String, dynamic> map) {
    return GamePeriod(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      periodNumber: map['period_number'] as int,
      periodType: map['period_type'] as String,
      scoreUs: map['score_us'] as int? ?? 0,
      scoreThem: map['score_them'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'GamePeriod(id: $id, gameId: $gameId, period: $periodNumber, score: $scoreUs-$scoreThem)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamePeriod &&
        other.id == id &&
        other.gameId == gameId &&
        other.periodNumber == periodNumber &&
        other.periodType == periodType &&
        other.scoreUs == scoreUs &&
        other.scoreThem == scoreThem;
  }

  @override
  int get hashCode {
    return Object.hash(id, gameId, periodNumber, periodType, scoreUs, scoreThem);
  }
}
