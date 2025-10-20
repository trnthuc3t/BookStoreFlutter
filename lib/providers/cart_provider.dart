import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../providers/auth_provider.dart';

class CartProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cartItems.length;
  
  int get totalPrice {
    return _cartItems.fold(0, (sum, item) {
      final price = item['price'] as int;
      final sale = item['sale'] as int;
      final quantity = item['quantity'] as int;
      final realPrice = sale > 0 ? price - (price * sale / 100) : price;
      return sum + (realPrice * quantity).toInt();
    });
  }

  Future<void> loadCartItems(String userEmail) async {
    _setLoading(true);
    _clearError();

    try {
      _cartItems = await _databaseService.getCartItems(userEmail);
      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải giỏ hàng: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToCart(Product product, int quantity, String userEmail) async {
    _setLoading(true);
    _clearError();

    try {
      await _databaseService.addToCart(product.id, quantity, userEmail);
      await loadCartItems(userEmail);
    } catch (e) {
      _setError('Lỗi thêm vào giỏ hàng: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateQuantity(int productId, int quantity, String userEmail) async {
    _setLoading(true);
    _clearError();

    try {
      await _databaseService.updateCartQuantity(productId, quantity, userEmail);
      await loadCartItems(userEmail);
    } catch (e) {
      _setError('Lỗi cập nhật số lượng: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFromCart(int productId, String userEmail) async {
    _setLoading(true);
    _clearError();

    try {
      await _databaseService.removeFromCart(productId, userEmail);
      await loadCartItems(userEmail);
    } catch (e) {
      _setError('Lỗi xóa khỏi giỏ hàng: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearCart(String userEmail) async {
    _setLoading(true);
    _clearError();

    try {
      await _databaseService.clearCart(userEmail);
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      _setError('Lỗi xóa giỏ hàng: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<int> getCartItemCount(String userEmail) async {
    try {
      return await _databaseService.getCartItemCount(userEmail);
    } catch (e) {
      print('Error getting cart item count: $e');
      return 0;
    }
  }

  bool isInCart(int productId) {
    return _cartItems.any((item) => item['product_id'] == productId);
  }

  int getQuantity(int productId) {
    final item = _cartItems.firstWhere(
      (item) => item['product_id'] == productId,
      orElse: () => {'quantity': 0},
    );
    return item['quantity'] as int;
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
