import 'package:flutter/foundation.dart' as foundation;
import '../models/product.dart';
import '../models/category.dart' as app_models;
import '../services/api_service.dart';
import '../utils/image_utils.dart';
import '../utils/cache_manager.dart';

// Rename to avoid conflict with product_provider.dart
class ProductApiProvider with foundation.ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _bestsellerProducts = [];
  List<app_models.Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _productsLoaded = false;
  bool _categoriesLoaded = false;

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get bestsellerProducts => _bestsellerProducts;
  List<app_models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts({
    int skip = 0,
    int limit = 100,
    int? categoryId,
    bool featuredOnly = false,
    String? search,
    bool forceReload = false,
  }) async {
    // Return cached data if already loaded and not forcing reload
    if (_productsLoaded && !forceReload && _products.isNotEmpty) {
      print('✅ Using cached products data');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Try to load featured books from cache first
      if (!forceReload && featuredOnly) {
        final cachedFeatured = await CacheManager.getCachedFeaturedBooks();
        if (cachedFeatured != null && cachedFeatured.isNotEmpty) {
          print('✅ Using cached featured books (${cachedFeatured.length} items)');
          _featuredProducts = cachedFeatured.map((item) => _mapBookToProduct(item)).toList();
          _productsLoaded = true;
          _setLoading(false);
          return;
        }
      }

      final data = await ApiService.getProducts(
        skip: skip,
        limit: limit,
        categoryId: categoryId,
        featuredOnly: featuredOnly,
        search: search,
      );

      // Map API response to Product model
      _products = data.map((item) => _mapBookToProduct(item)).toList();

      // Filter featured products
      _featuredProducts = _products.where((p) => p.isFeatured).toList();

      // Cache featured books for faster loading next time
      if (_featuredProducts.isNotEmpty) {
        final featuredData = data.where((item) => item['is_featured'] == true).toList();
        await CacheManager.cacheFeaturedBooks(featuredData);
        print('💾 Cached ${_featuredProducts.length} featured books');
      }

      // Filter bestseller products and sort by sold quantity
      _bestsellerProducts = _products.where((p) => p.isBestseller).toList()
        ..sort((a, b) => (b.soldQuantity ?? 0).compareTo(a.soldQuantity ?? 0));

      _productsLoaded = true;
      print(
          '✅ Loaded ${_products.length} products, ${_featuredProducts.length} featured, ${_bestsellerProducts.length} bestsellers');
    } catch (e) {
      _setError('Lỗi tải sản phẩm: ${e.toString()}');
      print('❌ Error loading products: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to map API Book data to Product model
  Product _mapBookToProduct(dynamic bookData) {
    try {
      print('Mapping book data: $bookData'); // Debug log

      // Get first image if exists using helper
      String? imageUrl = ImageUtils.getPrimaryImageUrl(bookData['images']);
      if (imageUrl != null) {
        print('📸 Image URL mapped: $imageUrl'); // Debug log
      } else {
        print('⚠️ No images found for book ${bookData['id']}'); // Debug log
      }

      // Get category info
      int categoryId = 0;
      String? categoryName;
      if (bookData['category'] != null) {
        if (bookData['category'] is Map) {
          categoryId = bookData['category']['id'] ?? 0;
          categoryName = bookData['category']['name']?.toString() ?? '';
        } else {
          categoryId = int.tryParse(bookData['category'].toString()) ?? 0;
          categoryName = bookData['category'].toString();
        }
      }

      return Product(
        id: bookData['id'] ?? 0,
        name: bookData['title']?.toString() ?? 'Unknown',
        description: bookData['description']?.toString() ?? '',
        price: ((bookData['price'] ?? 0) as num).toInt(),
        originalPrice: bookData['original_price'] != null 
            ? ((bookData['original_price'] ?? 0) as num).toInt()
            : null,
        image: imageUrl,
        categoryId: categoryId,
        categoryName: categoryName ?? '',
        sale: ((bookData['discount_percentage'] ?? 0) as num).toInt(),
        isFeatured: bookData['is_featured'] ?? false,
        isBestseller: bookData['is_bestseller'] ?? false,
        soldQuantity: bookData['sold_quantity'],
        ratingAverage: ((bookData['rating_average'] ?? 0.0) as num).toDouble(),
        ratingCount: bookData['rating_count'] ?? 0,
        count: bookData['stock_quantity'] ?? 0,
        stockQuantity: bookData['stock_quantity'],
        images: bookData['images'],
      );
    } catch (e) {
      print('Error mapping book data: $e');
      print('Book data: $bookData');
      return Product(
        id: bookData['id'] ?? 0,
        name: bookData['title']?.toString() ?? 'Unknown',
        price: 0,
        ratingAverage: 0.0,
        ratingCount: 0,
      );
    }
  }

  Future<void> loadCategories({bool forceReload = false}) async {
    // Return cached data if already loaded and not forcing reload
    if (_categoriesLoaded && !forceReload && _categories.isNotEmpty) {
      print('Using cached categories data');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final data = await ApiService.getCategories();
      _categories =
          data.map((item) => app_models.Category.fromJson(item)).toList();
      _categoriesLoaded = true;
      print('Loaded ${_categories.length} categories');
    } catch (e) {
      _setError('Lỗi tải danh mục: ${e.toString()}');
      print('Error loading categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final data = await ApiService.getProduct(id);
      if (data != null) {
        return _mapBookToProduct(data);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
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
              false);
    }).toList();
  }

  Future<bool> rateProduct(int productId, double rate, String? review) async {
    try {
      return await ApiService.rateProduct(productId, rate, review);
    } catch (e) {
      print('Error rating product: $e');
      return false;
    }
  }

  // Admin functions
  Future<void> addProduct(Product product) async {
    _setLoading(true);
    _clearError();

    try {
      // This would need to be implemented in ApiService for admin
      // For now, just reload products
      await loadProducts();
    } catch (e) {
      _setError('Lỗi thêm sản phẩm: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProduct(Product product) async {
    _setLoading(true);
    _clearError();

    try {
      // This would need to be implemented in ApiService for admin
      // For now, just reload products
      await loadProducts();
    } catch (e) {
      _setError('Lỗi cập nhật sản phẩm: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(int productId) async {
    _setLoading(true);
    _clearError();

    try {
      // This would need to be implemented in ApiService for admin
      // For now, just reload products
      await loadProducts();
    } catch (e) {
      _setError('Lỗi xóa sản phẩm: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCategory(app_models.Category category) async {
    _setLoading(true);
    _clearError();

    try {
      // This would need to be implemented in ApiService for admin
      // For now, just reload categories
      await loadCategories();
    } catch (e) {
      _setError('Lỗi thêm danh mục: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
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
}
