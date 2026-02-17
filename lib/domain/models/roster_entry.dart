import 'player.dart';

class RosterEntry {
  final String id;
  final String teamId;
  final String playerId;
  final String seasonId;
  final String jerseyNumber;
  final String role;
  final bool isLibero;
  final DateTime joinedDate;
  final Player? player;

  const RosterEntry({
    required this.id,
    required this.teamId,
    required this.playerId,
    required this.seasonId,
    required this.jerseyNumber,
    this.role = 'reserve',
    this.isLibero = false,
    required this.joinedDate,
    this.player,
  });

  RosterEntry copyWith({
    String? id,
    String? teamId,
    String? playerId,
    String? seasonId,
    String? jerseyNumber,
    String? role,
    bool? isLibero,
    DateTime? joinedDate,
    Player? Function()? player,
  }) {
    return RosterEntry(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      seasonId: seasonId ?? this.seasonId,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      role: role ?? this.role,
      isLibero: isLibero ?? this.isLibero,
      joinedDate: joinedDate ?? this.joinedDate,
      player: player != null ? player() : this.player,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_id': teamId,
      'player_id': playerId,
      'season_id': seasonId,
      'jersey_number': jerseyNumber,
      'role': role,
      'is_libero': isLibero ? 1 : 0,
      'joined_date': joinedDate.toIso8601String(),
    };
  }

  factory RosterEntry.fromMap(Map<String, dynamic> map, {Player? player}) {
    return RosterEntry(
      id: map['id'] as String,
      teamId: map['team_id'] as String,
      playerId: map['player_id'] as String,
      seasonId: map['season_id'] as String,
      jerseyNumber: map['jersey_number'] as String,
      role: map['role'] as String? ?? 'reserve',
      isLibero: map['is_libero'] == 1 || map['is_libero'] == true,
      joinedDate: DateTime.parse(map['joined_date'] as String),
      player: player,
    );
  }

  @override
  String toString() {
    return 'RosterEntry(id: $id, teamId: $teamId, playerId: $playerId, #$jerseyNumber, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RosterEntry &&
        other.id == id &&
        other.teamId == teamId &&
        other.playerId == playerId &&
        other.seasonId == seasonId &&
        other.jerseyNumber == jerseyNumber &&
        other.role == role &&
        other.isLibero == isLibero &&
        other.joinedDate == joinedDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      teamId,
      playerId,
      seasonId,
      jerseyNumber,
      role,
      isLibero,
      joinedDate,
    );
  }
}
