// Statistics models for admin dashboard

class RevenueStatistic {
  final String period;
  final String startDate;
  final String endDate;
  final int totalOrders;
  final int totalBooksSold;
  final double totalRevenue;
  final double totalRevenueBeforeDiscount;
  final double totalDiscount;
  final double totalProfit;
  final double totalProfitAfterDiscount;

  RevenueStatistic({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalBooksSold,
    required this.totalRevenue,
    required this.totalRevenueBeforeDiscount,
    required this.totalDiscount,
    required this.totalProfit,
    required this.totalProfitAfterDiscount,
  });

  factory RevenueStatistic.fromJson(Map<String, dynamic> json) {
    return RevenueStatistic(
      period: json['period'] ?? 'day',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      totalOrders: json['total_orders'] ?? 0,
      totalBooksSold: json['total_books_sold'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
      totalRevenueBeforeDiscount: (json['total_revenue_before_discount'] ?? 0.0).toDouble(),
      totalDiscount: (json['total_discount'] ?? 0.0).toDouble(),
      totalProfit: (json['total_profit'] ?? 0.0).toDouble(),
      totalProfitAfterDiscount: (json['total_profit_after_discount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'start_date': startDate,
      'end_date': endDate,
      'total_orders': totalOrders,
      'total_books_sold': totalBooksSold,
      'total_revenue': totalRevenue,
      'total_revenue_before_discount': totalRevenueBeforeDiscount,
      'total_discount': totalDiscount,
      'total_profit': totalProfit,
      'total_profit_after_discount': totalProfitAfterDiscount,
    };
  }
}

class BookStatistic {
  final int bookId;
  final String bookName;
  final String category;
  final int soldQuantity;
  final double revenue;
  final double profit;
  final int stockRemaining;

  BookStatistic({
    required this.bookId,
    required this.bookName,
    required this.category,
    required this.soldQuantity,
    required this.revenue,
    required this.profit,
    required this.stockRemaining,
  });

  factory BookStatistic.fromJson(Map<String, dynamic> json) {
    return BookStatistic(
      bookId: json['book_id'] ?? 0,
      bookName: json['book_name'] ?? '',
      category: json['category'] ?? '',
      soldQuantity: json['sold_quantity'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      profit: (json['profit'] ?? 0.0).toDouble(),
      stockRemaining: json['stock_remaining'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'book_name': bookName,
      'category': category,
      'sold_quantity': soldQuantity,
      'revenue': revenue,
      'profit': profit,
      'stock_remaining': stockRemaining,
    };
  }
}

class BookStatisticResponse {
  final String period;
  final String startDate;
  final String endDate;
  final List<BookStatistic> books;

  BookStatisticResponse({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.books,
  });

  factory BookStatisticResponse.fromJson(Map<String, dynamic> json) {
    return BookStatisticResponse(
      period: json['period'] ?? 'day',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      books: (json['books'] as List<dynamic>?)
              ?.map((item) => BookStatistic.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class BookInCategory {
  final int bookId;
  final String bookName;
  final int soldQuantity;
  final double profit;
  final int stockRemaining;

  BookInCategory({
    required this.bookId,
    required this.bookName,
    required this.soldQuantity,
    required this.profit,
    required this.stockRemaining,
  });

  factory BookInCategory.fromJson(Map<String, dynamic> json) {
    return BookInCategory(
      bookId: json['book_id'] ?? 0,
      bookName: json['book_name'] ?? '',
      soldQuantity: json['sold_quantity'] ?? 0,
      profit: (json['profit'] ?? 0.0).toDouble(),
      stockRemaining: json['stock_remaining'] ?? 0,
    );
  }
}

class CategoryStatistic {
  final int categoryId;
  final String categoryName;
  final List<BookInCategory> books;
  final int totalSold;
  final double totalProfit;
  final int totalStock;

  CategoryStatistic({
    required this.categoryId,
    required this.categoryName,
    required this.books,
    required this.totalSold,
    required this.totalProfit,
    required this.totalStock,
  });

  factory CategoryStatistic.fromJson(Map<String, dynamic> json) {
    return CategoryStatistic(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      books: (json['books'] as List<dynamic>?)
              ?.map((item) => BookInCategory.fromJson(item))
              .toList() ??
          [],
      totalSold: json['total_sold'] ?? 0,
      totalProfit: (json['total_profit'] ?? 0.0).toDouble(),
      totalStock: json['total_stock'] ?? 0,
    );
  }
}

class CategoryStatisticResponse {
  final String period;
  final String startDate;
  final String endDate;
  final List<CategoryStatistic> categories;

  CategoryStatisticResponse({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.categories,
  });

  factory CategoryStatisticResponse.fromJson(Map<String, dynamic> json) {
    return CategoryStatisticResponse(
      period: json['period'] ?? 'day',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => CategoryStatistic.fromJson(item))
              .toList() ??
          [],
    );
  }
}
