class Address {
  int id;
  String? recipientName;
  String? phone;
  String? addressLine1;
  String? addressLine2;
  String? ward;
  String? district;
  String? city;
  String? country;
  bool isDefault;

  Address({
    this.id = 0,
    this.recipientName,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.ward,
    this.district,
    this.city,
    this.country = 'Vietnam',
    this.isDefault = false,
  });

  // Factory từ API backend
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0,
      recipientName: json['recipient_name'],
      phone: json['phone'],
      addressLine1: json['address_line1'],
      addressLine2: json['address_line2'],
      ward: json['ward'],
      district: json['district'],
      city: json['city'],
      country: json['country'] ?? 'Vietnam',
      isDefault: json['is_default'] ?? false,
    );
  }

  // Chuyển sang format API backend
  Map<String, dynamic> toJson() {
    return {
      'recipient_name': recipientName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'ward': ward,
      'district': district,
      'city': city,
      'country': country,
      'is_default': isDefault,
    };
  }

  // Địa chỉ đầy đủ để hiển thị
  String get fullAddress {
    final parts = <String>[];
    if (addressLine1 != null && addressLine1!.isNotEmpty) {
      parts.add(addressLine1!);
    }
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }

  Address copyWith({
    int? id,
    String? recipientName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? ward,
    String? district,
    String? city,
    String? country,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
