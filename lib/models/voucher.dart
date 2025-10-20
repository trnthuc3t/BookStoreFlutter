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
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] ?? 0,
      name: json['name'],
      description: json['description'],
      discount: json['discount'] ?? 0,
      code: json['code'],
      minPrice: json['minPrice'] ?? 0,
      maxDiscount: json['maxDiscount'] ?? 0,
      startDate: json['startDate'],
      endDate: json['endDate'],
      expiryDate: json['expiryDate'] != null 
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      maxUses: json['maxUses'] ?? 1,
      remainingUses: json['remainingUses'] ?? 1,
      isActive: json['isActive'] ?? true,
    );
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
    );
  }
}
