class Product {
  // Helper method to safely convert Firebase data to Map<String, dynamic>
  static Map<String, dynamic> _convertToMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      // Handle Map<Object?, Object?> and other Map types
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        if (key != null) {
          result[key.toString()] = value;
        }
      });
      return result;
    } else {
      throw Exception(
          'Cannot convert ${data.runtimeType} to Map<String, dynamic>');
    }
  }

  int id;
  String? name;
  String? description;
  int price;
  String? image;
  String? banner;
  int categoryId;
  String? categoryName;
  int sale;
  bool isFeatured;
  bool isBestseller;
  int? soldQuantity;
  List<dynamic>? images;
  String? info;
  Map<String, Rating>? rating;
  double ratingAverage; // From API
  int ratingCount; // From API
  int count;
  int totalPrice;
  int priceOneProduct;
  int? originalPrice; // Add original_price field
  int? stockQuantity; // Add stock_quantity field
  String? bookSize; // Book dimensions
  int? publishYear; // Year of publication
  String? supplier; // Supplier name
  String? publisher; // Publisher name
  int? pageCount; // Number of pages
  String? language; // Book language

  Product({
    this.id = 0,
    this.name,
    this.description,
    this.price = 0,
    this.image,
    this.banner,
    this.categoryId = 0,
    this.categoryName,
    this.sale = 0,
    this.isFeatured = false,
    this.isBestseller = false,
    this.soldQuantity,
    this.images,
    this.info,
    this.rating,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.count = 0,
    this.totalPrice = 0,
    this.priceOneProduct = 0,
    this.originalPrice,
    this.stockQuantity,
    this.bookSize,
    this.publishYear,
    this.supplier,
    this.publisher,
    this.pageCount,
    this.language,
  });

  // Calculate real price after discount
  int get realPrice {
    if (sale <= 0) {
      return price;
    }
    return price - (price * sale / 100).toInt();
  }

  // Count of reviews
  int get countReviews {
    if (rating == null || rating!.isEmpty) return 0;
    return rating!.length;
  }

  // Average rating - prioritize API data
  double get rate {
    // Use rating_average from API if available
    if (ratingAverage > 0) return ratingAverage;
    
    // Fallback to calculating from rating map (legacy)
    if (rating == null || rating!.isEmpty) return 0.0;
    double sum = 0.0;
    for (var ratingEntity in rating!.values) {
      sum += ratingEntity.rate;
    }
    return double.parse((sum / rating!.length).toStringAsFixed(1));
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    Map<String, Rating>? ratingMap;
    if (json['rating'] != null) {
      ratingMap = {};
      final ratingData = json['rating'];
      if (ratingData is Map) {
        ratingData.forEach((key, value) {
          if (key != null && value is Map) {
            ratingMap![key.toString()] =
                Rating.fromJson(Product._convertToMap(value));
          }
        });
      }
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['title'],  // Support both 'name' and 'title'
      description: json['description'],
      price: (json['price'] is double)
          ? (json['price'] as double).toInt()
          : (json['price'] ?? 0),
      image: json['image'],
      banner: json['banner'],
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'],
      sale: (json['sale'] is double)
          ? (json['sale'] as double).toInt()
          : (json['sale'] ?? (json['discount_percentage'] is double
              ? (json['discount_percentage'] as double).toInt()
              : json['discount_percentage'] ?? 0)),
      isFeatured: json['isFeatured'] ?? json['is_featured'] ?? false,
      isBestseller: json['isBestseller'] ?? json['is_bestseller'] ?? false,
      soldQuantity: (json['sold_quantity'] is double)
          ? (json['sold_quantity'] as double).toInt()
          : (json['sold_quantity'] ?? json['soldQuantity'] ?? 0),
      images: json['images'],
      info: json['info'],
      rating: ratingMap,
      ratingAverage: (json['rating_average'] ?? 0.0).toDouble(),
      ratingCount: (json['rating_count'] is double)
          ? (json['rating_count'] as double).toInt()
          : (json['rating_count'] ?? 0),
      count: json['count'] ?? 0,
      totalPrice: json['totalPrice'] ?? 0,
      priceOneProduct: json['priceOneProduct'] ?? 0,
      originalPrice: json['original_price'] != null
          ? (json['original_price'] is double
              ? (json['original_price'] as double).toInt()
              : json['original_price'])
          : null,
      stockQuantity: json['stock_quantity'] != null
          ? (json['stock_quantity'] is double
              ? (json['stock_quantity'] as double).toInt()
              : json['stock_quantity'])
          : null,
      bookSize: json['book_size'],
      publishYear: json['publish_year'] != null
          ? (json['publish_year'] is double
              ? (json['publish_year'] as double).toInt()
              : json['publish_year'])
          : null,
      supplier: json['supplier'],
      publisher: json['publisher'],
      pageCount: json['page_count'] != null
          ? (json['page_count'] is double
              ? (json['page_count'] as double).toInt()
              : json['page_count'])
          : null,
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic>? ratingJson;
    if (rating != null) {
      ratingJson = {};
      rating!.forEach((key, value) {
        ratingJson![key] = value.toJson();
      });
    }

    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'banner': banner,
      'category_id': categoryId,
      'category_name': categoryName,
      'sale': sale,
      'isFeatured': isFeatured,
      'isBestseller': isBestseller,
      'sold_quantity': soldQuantity,
      'images': images,
      'info': info,
      'rating': ratingJson,
      'rating_average': ratingAverage,
      'rating_count': ratingCount,
      'count': count,
      'totalPrice': totalPrice,
      'priceOneProduct': priceOneProduct,
      'original_price': originalPrice,
      'stock_quantity': stockQuantity,
      'book_size': bookSize,
      'publish_year': publishYear,
      'supplier': supplier,
      'publisher': publisher,
      'page_count': pageCount,
      'language': language,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    int? price,
    String? image,
    String? banner,
    int? categoryId,
    String? categoryName,
    int? sale,
    bool? isFeatured,
    bool? isBestseller,
    int? soldQuantity,
    List<dynamic>? images,
    String? info,
    Map<String, Rating>? rating,
    double? ratingAverage,
    int? ratingCount,
    int? count,
    int? totalPrice,
    int? priceOneProduct,
    int? originalPrice,
    int? stockQuantity,
    String? bookSize,
    int? publishYear,
    String? supplier,
    String? publisher,
    int? pageCount,
    String? language,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      banner: banner ?? this.banner,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sale: sale ?? this.sale,
      isFeatured: isFeatured ?? this.isFeatured,
      isBestseller: isBestseller ?? this.isBestseller,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      images: images ?? this.images,
      info: info ?? this.info,
      rating: rating ?? this.rating,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      count: count ?? this.count,
      totalPrice: totalPrice ?? this.totalPrice,
      priceOneProduct: priceOneProduct ?? this.priceOneProduct,
      originalPrice: originalPrice ?? this.originalPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      bookSize: bookSize ?? this.bookSize,
      publishYear: publishYear ?? this.publishYear,
      supplier: supplier ?? this.supplier,
      publisher: publisher ?? this.publisher,
      pageCount: pageCount ?? this.pageCount,
      language: language ?? this.language,
    );
  }
}

class Rating {
  double rate;
  String? comment;
  String? userEmail;
  int timestamp;

  Rating({
    this.rate = 0.0,
    this.comment,
    this.userEmail,
    this.timestamp = 0,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rate: (json['rate'] ?? 0.0).toDouble(),
      comment: json['comment'] ??
          json['review'], // Handle both 'comment' and 'review' fields
      userEmail: json['userEmail'],
      timestamp: json['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'comment': comment,
      'userEmail': userEmail,
      'timestamp': timestamp,
    };
  }
}
