class Revenue {
  int id;
  DateTime date;
  double totalRevenue;
  int totalOrders;
  double averageOrderValue;
  Map<String, double> revenueByCategory;
  Map<String, int> ordersByStatus;
  DateTime? createdAt;

  Revenue({
    this.id = 0,
    required this.date,
    this.totalRevenue = 0.0,
    this.totalOrders = 0,
    this.averageOrderValue = 0.0,
    this.revenueByCategory = const {},
    this.ordersByStatus = const {},
    this.createdAt,
  });

  factory Revenue.fromJson(Map<String, dynamic> json) {
    return Revenue(
      id: json['id'] ?? 0,
      date: json['date'] != null 
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0.0).toDouble(),
      revenueByCategory: json['revenueByCategory'] != null 
          ? Map<String, double>.from(json['revenueByCategory'])
          : {},
      ordersByStatus: json['ordersByStatus'] != null 
          ? Map<String, int>.from(json['ordersByStatus'])
          : {},
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'revenueByCategory': revenueByCategory,
      'ordersByStatus': ordersByStatus,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Revenue copyWith({
    int? id,
    DateTime? date,
    double? totalRevenue,
    int? totalOrders,
    double? averageOrderValue,
    Map<String, double>? revenueByCategory,
    Map<String, int>? ordersByStatus,
    DateTime? createdAt,
  }) {
    return Revenue(
      id: id ?? this.id,
      date: date ?? this.date,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      revenueByCategory: revenueByCategory ?? this.revenueByCategory,
      ordersByStatus: ordersByStatus ?? this.ordersByStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedTotalRevenue {
    return totalRevenue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String get formattedAverageOrderValue {
    return averageOrderValue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  double get completionRate {
    if (totalOrders == 0) return 0.0;
    final completedOrders = ordersByStatus['completed'] ?? 0;
    return (completedOrders / totalOrders) * 100;
  }

  String get topCategory {
    if (revenueByCategory.isEmpty) return 'N/A';
    return revenueByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
