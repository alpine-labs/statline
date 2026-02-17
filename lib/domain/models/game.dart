import 'dart:convert';

enum GameStatus { scheduled, inProgress, completed, canceled }

enum GameResult { win, loss, tie }

class Game {
  final String id;
  final String seasonId;
  final String teamId;
  final String opponentName;
  final String? opponentTeamId;
  final DateTime gameDate;
  final String? location;
  final bool isHome;
  final String sport;
  final Map<String, dynamic> gameFormat;
  final GameStatus status;
  final int? finalScoreUs;
  final int? finalScoreThem;
  final GameResult? result;
  final String? notes;
  final String entryMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Game({
    required this.id,
    required this.seasonId,
    required this.teamId,
    required this.opponentName,
    this.opponentTeamId,
    required this.gameDate,
    this.location,
    this.isHome = true,
    required this.sport,
    required this.gameFormat,
    this.status = GameStatus.scheduled,
    this.finalScoreUs,
    this.finalScoreThem,
    this.result,
    this.notes,
    this.entryMode = 'quick',
    required this.createdAt,
    required this.updatedAt,
  });

  Game copyWith({
    String? id,
    String? seasonId,
    String? teamId,
    String? opponentName,
    String? Function()? opponentTeamId,
    DateTime? gameDate,
    String? Function()? location,
    bool? isHome,
    String? sport,
    Map<String, dynamic>? gameFormat,
    GameStatus? status,
    int? Function()? finalScoreUs,
    int? Function()? finalScoreThem,
    GameResult? Function()? result,
    String? Function()? notes,
    String? entryMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Game(
      id: id ?? this.id,
      seasonId: seasonId ?? this.seasonId,
      teamId: teamId ?? this.teamId,
      opponentName: opponentName ?? this.opponentName,
      opponentTeamId:
          opponentTeamId != null ? opponentTeamId() : this.opponentTeamId,
      gameDate: gameDate ?? this.gameDate,
      location: location != null ? location() : this.location,
      isHome: isHome ?? this.isHome,
      sport: sport ?? this.sport,
      gameFormat: gameFormat ?? this.gameFormat,
      status: status ?? this.status,
      finalScoreUs:
          finalScoreUs != null ? finalScoreUs() : this.finalScoreUs,
      finalScoreThem:
          finalScoreThem != null ? finalScoreThem() : this.finalScoreThem,
      result: result != null ? result() : this.result,
      notes: notes != null ? notes() : this.notes,
      entryMode: entryMode ?? this.entryMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'season_id': seasonId,
      'team_id': teamId,
      'opponent_name': opponentName,
      'opponent_team_id': opponentTeamId,
      'game_date': gameDate.toIso8601String(),
      'location': location,
      'is_home': isHome ? 1 : 0,
      'sport': sport,
      'game_format': jsonEncode(gameFormat),
      'status': status.name,
      'final_score_us': finalScoreUs,
      'final_score_them': finalScoreThem,
      'result': result?.name,
      'notes': notes,
      'entry_mode': entryMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    final gameFormatRaw = map['game_format'];
    Map<String, dynamic> gameFormat;
    if (gameFormatRaw is String) {
      gameFormat = Map<String, dynamic>.from(jsonDecode(gameFormatRaw) as Map);
    } else if (gameFormatRaw is Map) {
      gameFormat = Map<String, dynamic>.from(gameFormatRaw);
    } else {
      gameFormat = {};
    }

    return Game(
      id: map['id'] as String,
      seasonId: map['season_id'] as String,
      teamId: map['team_id'] as String,
      opponentName: map['opponent_name'] as String,
      opponentTeamId: map['opponent_team_id'] as String?,
      gameDate: DateTime.parse(map['game_date'] as String),
      location: map['location'] as String?,
      isHome: map['is_home'] == 1 || map['is_home'] == true,
      sport: map['sport'] as String,
      gameFormat: gameFormat,
      status: GameStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GameStatus.scheduled,
      ),
      finalScoreUs: map['final_score_us'] as int?,
      finalScoreThem: map['final_score_them'] as int?,
      result: map['result'] != null
          ? GameResult.values.firstWhere(
              (e) => e.name == map['result'],
              orElse: () => GameResult.loss,
            )
          : null,
      notes: map['notes'] as String?,
      entryMode: map['entry_mode'] as String? ?? 'quick',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Game(id: $id, opponent: $opponentName, status: $status, sport: $sport)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Game) return false;
    return other.id == id &&
        other.seasonId == seasonId &&
        other.teamId == teamId &&
        other.opponentName == opponentName &&
        other.opponentTeamId == opponentTeamId &&
        other.gameDate == gameDate &&
        other.location == location &&
        other.isHome == isHome &&
        other.sport == sport &&
        other.status == status &&
        other.finalScoreUs == finalScoreUs &&
        other.finalScoreThem == finalScoreThem &&
        other.result == result &&
        other.notes == notes &&
        other.entryMode == entryMode &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      seasonId,
      teamId,
      opponentName,
      opponentTeamId,
      gameDate,
      location,
      isHome,
      sport,
      status,
      finalScoreUs,
      finalScoreThem,
      result,
      notes,
      entryMode,
      createdAt,
      updatedAt,
    );
  }
}
