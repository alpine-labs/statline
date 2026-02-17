class Season {
  final String id;
  final String teamId;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Season({
    required this.id,
    required this.teamId,
    required this.name,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Season copyWith({
    String? id,
    String? teamId,
    String? name,
    DateTime? startDate,
    DateTime? Function()? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Season(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Season.fromMap(Map<String, dynamic> map) {
    return Season(
      id: map['id'] as String,
      teamId: map['team_id'] as String,
      name: map['name'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Season(id: $id, teamId: $teamId, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Season &&
        other.id == id &&
        other.teamId == teamId &&
        other.name == name &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      teamId,
      name,
      startDate,
      endDate,
      isActive,
      createdAt,
      updatedAt,
    );
  }
}
