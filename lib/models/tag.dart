class Tag {
  final int? id;
  final String name;

  Tag({
    this.id,
    required this.name,
  });

  // Create a copy of the current tag with updated fields
  Tag copyWith({
    int? id,
    String? name,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  // Convert a Tag object to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tag_name': name,
    };
  }

  // Create a Tag object from a database map
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['tag_name'],
    );
  }

  @override
  String toString() {
    return 'Tag(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 