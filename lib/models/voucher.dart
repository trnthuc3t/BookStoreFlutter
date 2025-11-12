class Voucher {
  int id;
  String? name;
  String? description;
  int discount;
  String? code;
  int minPrice;
  int maxDiscount;
  String? startDate;
  String? endDate;
  DateTime? expiryDate; // For easier date handling
  int maxUses; // Maximum number of uses
  int remainingUses; // Remaining uses
  bool isActive;
  String? discountType; // 'percentage', 'fixed_amount', 'free_shipping'
  double? discountValue; // The actual discount value from backend

  Voucher({
    this.id = 0,
    this.name,
    this.description,
    this.discount = 0,
    this.code,
    this.minPrice = 0,
    this.maxDiscount = 0,
    this.startDate,
    this.endDate,
    this.expiryDate,
    this.maxUses = 1,
    this.remainingUses = 1,
    this.isActive = true,
    this.discountType,
    this.discountValue,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    try {
      return Voucher(
        id: json['id'] ?? 0,
        name: json['name']?.toString(),
        description: json['description']?.toString(),
        discount: _parseInt(json['discount']) ?? 0,
        code: json['code']?.toString(),
        minPrice: _parseInt(json['minPrice']) ?? 0,
        maxDiscount: _parseInt(json['maxDiscount']) ?? 0,
        startDate: json['startDate']?.toString(),
        endDate: json['endDate']?.toString(),
        expiryDate: json['expiryDate'] != null 
            ? DateTime.tryParse(json['expiryDate'].toString())
            : null,
        maxUses: _parseInt(json['maxUses']) ?? 1,
        remainingUses: _parseInt(json['remainingUses']) ?? 1,
        isActive: json['isActive'] == true || json['isActive'] == 'true',
        discountType: json['discount_type']?.toString(),
        discountValue: _parseDouble(json['discount_value']),
      );
    } catch (e) {
      print('⚠️ Error parsing Voucher from JSON: $e');
      print('JSON data: $json');
      // Return a minimal valid voucher on error
      return Voucher(
        id: json['id'] ?? 0,
        name: json['name']?.toString() ?? 'Unknown',
        code: json['code']?.toString() ?? 'UNKNOWN',
      );
    }
  }
  
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'discount': discount,
      'code': code,
      'minPrice': minPrice,
      'maxDiscount': maxDiscount,
      'startDate': startDate,
      'endDate': endDate,
      'expiryDate': expiryDate?.toIso8601String(),
      'maxUses': maxUses,
      'remainingUses': remainingUses,
      'isActive': isActive,
      'discount_type': discountType,
      'discount_value': discountValue,
    };
  }

  // Calculate discount amount
  int getPriceDiscount(int totalPrice) {
    if (totalPrice < minPrice) return 0;
    
    int discountAmount = (totalPrice * discount / 100).round();
    
    if (maxDiscount > 0 && discountAmount > maxDiscount) {
      return maxDiscount;
    }
    
    return discountAmount;
  }

  Voucher copyWith({
    int? id,
    String? name,
    String? description,
    int? discount,
    String? code,
    int? minPrice,
    int? maxDiscount,
    String? startDate,
    String? endDate,
    DateTime? expiryDate,
    int? maxUses,
    int? remainingUses,
    bool? isActive,
    String? discountType,
    double? discountValue,
  }) {
    return Voucher(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      code: code ?? this.code,
      minPrice: minPrice ?? this.minPrice,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      expiryDate: expiryDate ?? this.expiryDate,
      maxUses: maxUses ?? this.maxUses,
      remainingUses: remainingUses ?? this.remainingUses,
      isActive: isActive ?? this.isActive,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }
}
