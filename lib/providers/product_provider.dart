import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as app_models;
import '../services/firebase_service.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<Product> _products = [];
  List<app_models.Category> _categories = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  List<app_models.Category> get categories => _categories;
  List<Product> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firebaseService.getData('product');
      if (snapshot.exists) {
        final data = snapshot.value;

        if (data is Map<dynamic, dynamic>) {
          // Firebase returns a Map
          _products = data.values
              .where((item) => item != null)
              .map((item) {
                try {
                  return Product.fromJson(_convertToMap(item));
                } catch (e) {
                  print('Error parsing product: $e');
                  return null;
                }
              })
              .where((product) => product != null)
              .cast<Product>()
              .toList();
        } else if (data is List) {
          // Firebase returns a List (current structure)
          _products = data
              .where((item) => item != null)
              .map((item) {
                try {
                  return Product.fromJson(_convertToMap(item));
                } catch (e) {
                  print('Error parsing product: $e');
                  return null;
                }
              })
              .where((product) => product != null)
              .cast<Product>()
              .toList();
        } else {
          print('Unexpected data type for products: ${data.runtimeType}');
          _products = [];
        }

        // Filter featured products
        _featuredProducts = _products.where((p) => p.isFeatured).toList();

        print(
            'Loaded ${_products.length} products, ${_featuredProducts.length} featured');
      } else {
        print('No products found in Firebase');
        _products = [];
        _featuredProducts = [];
      }
      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải sản phẩm: ${e.toString()}');
      print('Error loading products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategories() async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firebaseService.getData('category');
      if (snapshot.exists) {
        final data = snapshot.value;

        if (data is Map<dynamic, dynamic>) {
          // Firebase returns a Map
          _categories = data.values
              .where((item) => item != null)
              .map((item) {
                try {
                  return app_models.Category.fromJson(_convertToMap(item));
                } catch (e) {
                  print('Error parsing category: $e');
                  return null;
                }
              })
              .where((category) => category != null)
              .cast<app_models.Category>()
              .toList();
        } else if (data is List) {
          // Firebase returns a List
          _categories = data
              .where((item) => item != null)
              .map((item) {
                try {
                  return app_models.Category.fromJson(_convertToMap(item));
                } catch (e) {
                  print('Error parsing category: $e');
                  return null;
                }
              })
              .where((category) => category != null)
              .cast<app_models.Category>()
              .toList();
        } else {
          print('Unexpected data type for categories: ${data.runtimeType}');
          _categories = [];
        }
      }
      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải danh mục: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final snapshot = await _firebaseService.getProductDetailRef(id).get();
      if (snapshot.exists) {
        return Product.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map));
      }
    } catch (e) {
      print('Error getting product by ID: $e');
    }
    return null;
  }

  List<Product> getProductsByCategory(int categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;

    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) {
      return (product.name?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (product.description?.toLowerCase().contains(lowercaseQuery) ??
              false) ||
          (product.categoryName?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }

  List<Product> getTopRatedProducts({int limit = 10}) {
    final sortedProducts = List<Product>.from(_products);
    sortedProducts.sort((a, b) => b.rate.compareTo(a.rate));
    return sortedProducts.take(limit).toList();
  }

  List<Product> getProductsOnSale({int limit = 10}) {
    final saleProducts = _products.where((p) => p.sale > 0).toList();
    saleProducts.sort((a, b) => b.sale.compareTo(a.sale));
    return saleProducts.take(limit).toList();
  }

  List<Product> getProductsByPriceRange(int minPrice, int maxPrice) {
    return _products.where((p) {
      final realPrice = p.realPrice;
      return realPrice >= minPrice && realPrice <= maxPrice;
    }).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Helper method to safely convert Firebase data to Map<String, dynamic>
  Map<String, dynamic> _convertToMap(dynamic data) {
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

  // Admin functions
  Future<void> addProduct(Product product) async {
    try {
      final newId = await _getNextProductId();
      final productWithId = product.copyWith(id: newId);
      await _firebaseService
          .getProductDetailRef(newId)
          .set(productWithId.toJson());
      await loadProducts(); // Reload to get updated list
    } catch (e) {
      _setError('Lỗi thêm sản phẩm: ${e.toString()}');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _firebaseService
          .getProductDetailRef(product.id)
          .set(product.toJson());
      await loadProducts(); // Reload to get updated list
    } catch (e) {
      _setError('Lỗi cập nhật sản phẩm: ${e.toString()}');
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      await _firebaseService.getProductDetailRef(productId).remove();
      await loadProducts(); // Reload to get updated list
    } catch (e) {
      _setError('Lỗi xóa sản phẩm: ${e.toString()}');
    }
  }

  Future<void> addCategory(app_models.Category category) async {
    try {
      final newId = await _getNextCategoryId();
      final categoryWithId = category.copyWith(id: newId);
      await _firebaseService
          .getCategoryDetailRef(newId)
          .set(categoryWithId.toJson());
      await loadCategories(); // Reload to get updated list
    } catch (e) {
      _setError('Lỗi thêm danh mục: ${e.toString()}');
    }
  }

  Future<void> updateCategory(app_models.Category category) async {
    try {
      await _firebaseService
          .getCategoryDetailRef(category.id)
          .set(category.toJson());
      await loadCategories(); // Reload to get updated list
    } catch (e) {
      _setError('Lỗi cập nhật danh mục: ${e.toString()}');
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await _firebaseService.getCategoryDetailRef(categoryId).remove();
      await loadCategories(); // Reload to get updated list
    } catch (e) {
      _setError('Lỗi xóa danh mục: ${e.toString()}');
    }
  }

  Future<int> _getNextProductId() async {
    try {
      final snapshot = await _firebaseService.getData('product');
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final maxId = data.keys
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .fold(0, (a, b) => a > b ? a : b);
        return maxId + 1;
      }
      return 1;
    } catch (e) {
      return 1;
    }
  }

  Future<int> _getNextCategoryId() async {
    try {
      final snapshot = await _firebaseService.getData('category');
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final maxId = data.keys
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .fold(0, (a, b) => a > b ? a : b);
        return maxId + 1;
      }
      return 1;
    } catch (e) {
      return 1;
    }
  }
}
