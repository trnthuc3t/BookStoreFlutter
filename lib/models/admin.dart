class Admin {
  int id;
  String? email;
  String? name;
  String? role;
  bool isActive;
  DateTime? createdAt;
  DateTime? lastLogin;

  Admin({
    this.id = 0,
    this.email,
    this.name,
    this.role,
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? 0,
      email: json['email'],
      name: json['name'],
      role: json['role'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  Admin copyWith({
    int? id,
    String? email,
    String? name,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return Admin(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
