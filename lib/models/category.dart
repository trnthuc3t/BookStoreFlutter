class Category {
  int id;
  String? name;
  String? description;
  String? image;

  Category({
    this.id = 0,
    this.name,
    this.description,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'],
      description: json['description'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? image,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
    );
  }
}
