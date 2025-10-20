import 'dart:convert';

class Product {
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
  String? info;
  Map<String, Rating>? rating;
  int count;
  int totalPrice;
  int priceOneProduct;

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
    this.info,
    this.rating,
    this.count = 0,
    this.totalPrice = 0,
    this.priceOneProduct = 0,
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

  // Average rating
  double get rate {
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
      (json['rating'] as Map<String, dynamic>).forEach((key, value) {
        ratingMap![key] = Rating.fromJson(value);
      });
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'],
      description: json['description'],
      price: json['price'] ?? 0,
      image: json['image'],
      banner: json['banner'],
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'],
      sale: json['sale'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      info: json['info'],
      rating: ratingMap,
      count: json['count'] ?? 0,
      totalPrice: json['totalPrice'] ?? 0,
      priceOneProduct: json['priceOneProduct'] ?? 0,
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
      'info': info,
      'rating': ratingJson,
      'count': count,
      'totalPrice': totalPrice,
      'priceOneProduct': priceOneProduct,
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
    String? info,
    Map<String, Rating>? rating,
    int? count,
    int? totalPrice,
    int? priceOneProduct,
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
      info: info ?? this.info,
      rating: rating ?? this.rating,
      count: count ?? this.count,
      totalPrice: totalPrice ?? this.totalPrice,
      priceOneProduct: priceOneProduct ?? this.priceOneProduct,
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
      comment: json['comment'],
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
