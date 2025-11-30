/// TagItem
/// =======
/// Immutable model representing a YS-specific tag that can be attached
/// to videos, folders, or playlists. Color is stored as a hex string
/// (e.g. "#FF0000") to avoid UI framework coupling in the model layer.
class TagItem {
  final String id;
  final String name;
  final String colorHex;
  final DateTime createdAt;

  const TagItem({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
  });

  TagItem copyWith({
    String? id,
    String? name,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return TagItem(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TagItem.fromMap(Map<String, dynamic> map) {
    return TagItem(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'TagItem('
        'id: $id, '
        'name: $name, '
        'colorHex: $colorHex, '
        'createdAt: $createdAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagItem) return false;
    return other.id == id &&
        other.name == name &&
        other.colorHex == colorHex &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, createdAt);
}
