class Team {
  final String id;
  final String? organizationId;
  final String name;
  final String sport;
  final String level;
  final String gender;
  final String? ageGroup;
  final String? logoUri;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Team({
    required this.id,
    this.organizationId,
    required this.name,
    required this.sport,
    required this.level,
    required this.gender,
    this.ageGroup,
    this.logoUri,
    required this.createdAt,
    required this.updatedAt,
  });

  Team copyWith({
    String? id,
    String? Function()? organizationId,
    String? name,
    String? sport,
    String? level,
    String? gender,
    String? Function()? ageGroup,
    String? Function()? logoUri,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      organizationId:
          organizationId != null ? organizationId() : this.organizationId,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      level: level ?? this.level,
      gender: gender ?? this.gender,
      ageGroup: ageGroup != null ? ageGroup() : this.ageGroup,
      logoUri: logoUri != null ? logoUri() : this.logoUri,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'sport': sport,
      'level': level,
      'gender': gender,
      'age_group': ageGroup,
      'logo_uri': logoUri,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String?,
      name: map['name'] as String,
      sport: map['sport'] as String,
      level: map['level'] as String,
      gender: map['gender'] as String,
      ageGroup: map['age_group'] as String?,
      logoUri: map['logo_uri'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Team(id: $id, name: $name, sport: $sport, level: $level, gender: $gender)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team &&
        other.id == id &&
        other.organizationId == organizationId &&
        other.name == name &&
        other.sport == sport &&
        other.level == level &&
        other.gender == gender &&
        other.ageGroup == ageGroup &&
        other.logoUri == logoUri &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      organizationId,
      name,
      sport,
      level,
      gender,
      ageGroup,
      logoUri,
      createdAt,
      updatedAt,
    );
  }
}
