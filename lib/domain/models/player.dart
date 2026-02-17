import 'dart:convert';

class Player {
  final String id;
  final String firstName;
  final String lastName;
  final String jerseyNumber;
  final List<String> positions;
  final String? photoUri;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName => '$firstName $lastName';
  String get shortName => '${firstName[0]}. $lastName';

  const Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.jerseyNumber,
    required this.positions,
    this.photoUri,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Player copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? jerseyNumber,
    List<String>? positions,
    String? Function()? photoUri,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Player(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      positions: positions ?? this.positions,
      photoUri: photoUri != null ? photoUri() : this.photoUri,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'jersey_number': jerseyNumber,
      'positions': jsonEncode(positions),
      'photo_uri': photoUri,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    final positionsRaw = map['positions'];
    List<String> positions;
    if (positionsRaw is String) {
      positions = (jsonDecode(positionsRaw) as List).cast<String>();
    } else if (positionsRaw is List) {
      positions = positionsRaw.cast<String>();
    } else {
      positions = [];
    }

    return Player(
      id: map['id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      jerseyNumber: map['jersey_number'] as String,
      positions: positions,
      photoUri: map['photo_uri'] as String?,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $displayName, #$jerseyNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Player) return false;
    if (other.id != id ||
        other.firstName != firstName ||
        other.lastName != lastName ||
        other.jerseyNumber != jerseyNumber ||
        other.photoUri != photoUri ||
        other.isActive != isActive ||
        other.createdAt != createdAt ||
        other.updatedAt != updatedAt) {
      return false;
    }
    if (other.positions.length != positions.length) return false;
    for (int i = 0; i < positions.length; i++) {
      if (other.positions[i] != positions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      firstName,
      lastName,
      jerseyNumber,
      Object.hashAll(positions),
      photoUri,
      isActive,
      createdAt,
      updatedAt,
    );
  }
}
