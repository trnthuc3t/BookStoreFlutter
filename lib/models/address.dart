class Address {
  int id;
  String? name;
  String? phone;
  String? address;
  String? userEmail;

  Address({
    this.id = 0,
    this.name,
    this.phone,
    this.address,
    this.userEmail,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0,
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      userEmail: json['userEmail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'userEmail': userEmail,
    };
  }

  Address copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? userEmail,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
