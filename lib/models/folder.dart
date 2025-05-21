class Folder {
  final int? id;
  final String name;
  final int? parentId;
  final int order;

  Folder({
    this.id,
    required this.name,
    this.parentId,
    this.order = 0,
  });

  // Create a copy of the current folder with updated fields
  Folder copyWith({
    int? id,
    String? name,
    int? parentId,
    int? order,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      order: order ?? this.order,
    );
  }

  // Convert a Folder object to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_name': name,
      'parent_id': parentId,
      'sort_order': order,
    };
  }

  // Create a Folder object from a database map
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['folder_name'],
      parentId: map['parent_id'],
      order: map['sort_order'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, parentId: $parentId, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Folder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 