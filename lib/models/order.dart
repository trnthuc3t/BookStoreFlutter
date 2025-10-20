import 'product.dart';
import 'address.dart';
import 'voucher.dart';
import '../constants/app_constants.dart';

class Order {
  int id;
  String? userEmail;
  String? userName;
  String? phone;
  String? address;
  String? notes;
  String? paymentMethod;
  int totalAmount;
  DateTime? createdAt;
  String status;

  Order({
    this.id = 0,
    this.userEmail,
    this.userName,
    this.phone,
    this.address,
    this.notes,
    this.paymentMethod,
    this.totalAmount = 0,
    this.createdAt,
    this.status = 'pending',
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      userEmail: json['userEmail'],
      userName: json['userName'],
      phone: json['phone'],
      address: json['address'],
      notes: json['notes'],
      paymentMethod: json['paymentMethod'],
      totalAmount: json['totalAmount'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'userName': userName,
      'phone': phone,
      'address': address,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'createdAt': createdAt?.toIso8601String(),
      'status': status,
    };
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không rõ';
    }
  }

  Order copyWith({
    int? id,
    String? userEmail,
    String? userName,
    String? phone,
    String? address,
    String? notes,
    String? paymentMethod,
    int? totalAmount,
    DateTime? createdAt,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

class ProductOrder {
  int id;
  String? name;
  String? description;
  int count;
  int price;
  String? image;

  ProductOrder({
    this.id = 0,
    this.name,
    this.description,
    this.count = 0,
    this.price = 0,
    this.image,
  });

  factory ProductOrder.fromJson(Map<String, dynamic> json) {
    return ProductOrder(
      id: json['id'] ?? 0,
      name: json['name'],
      description: json['description'],
      count: json['count'] ?? 0,
      price: json['price'] ?? 0,
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'count': count,
      'price': price,
      'image': image,
    };
  }

  ProductOrder copyWith({
    int? id,
    String? name,
    String? description,
    int? count,
    int? price,
    String? image,
  }) {
    return ProductOrder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      count: count ?? this.count,
      price: price ?? this.price,
      image: image ?? this.image,
    );
  }
}
