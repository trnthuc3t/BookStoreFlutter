class PaymentMethod {
  int id;
  String? name;
  String? description;
  String? icon;
  bool isActive;

  PaymentMethod({
    this.id = 0,
    this.name,
    this.description,
    this.icon,
    this.isActive = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? 0,
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isActive': isActive,
    };
  }

  PaymentMethod copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    bool? isActive,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }
}
