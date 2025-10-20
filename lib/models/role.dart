class Role {
  int id;
  String name;
  String? description;
  List<String> permissions;
  bool isActive;
  DateTime? createdAt;

  Role({
    this.id = 0,
    required this.name,
    this.description,
    this.permissions = const [],
    this.isActive = true,
    this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      permissions: json['permissions'] != null 
          ? List<String>.from(json['permissions'])
          : [],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Role copyWith({
    int? id,
    String? name,
    String? description,
    List<String>? permissions,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<String> requiredPermissions) {
    return requiredPermissions.any((permission) => permissions.contains(permission));
  }

  bool hasAllPermissions(List<String> requiredPermissions) {
    return requiredPermissions.every((permission) => permissions.contains(permission));
  }
}
