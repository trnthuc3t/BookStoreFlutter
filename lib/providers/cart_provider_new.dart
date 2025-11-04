import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// Cart provider using API backend with local cache and optimistic updates
class CartApiProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  bool _isRefreshing = false; // Separate loading state for background refresh
  String? _errorMessage;
  Timer? _debounceTimer;
  int? _cachedUserId;
  DateTime? _lastSync;

  // Cache keys
  static const String _cacheKey = 'cart_items_cache';
  static const String _cacheTimeKey = 'cart_cache_time';
  static const Duration _cacheExpiry = Duration(minutes: 5);

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cartItems.length;

  int get totalPrice {
    return _cartItems.fold(0, (sum, item) {
      // Handle potential null values safely
      final priceValue = item['book_price'];
      final quantityValue = item['quantity'];

      if (priceValue == null || quantityValue == null) {
        return sum;
      }

      final price = (priceValue as num).toDouble();
      final quantity = (quantityValue as num).toInt();
      return sum + (price * quantity).toInt();
    });
  }

  /// Load cart items from cache first, then sync with API
  Future<void> loadCartItems(int userId, {bool forceRefresh = false}) async {
    _cachedUserId = userId;

    // Try to load from cache first (instant load)
    if (!forceRefresh) {
      final cached = await _loadFromCache(userId);
      if (cached) {
        print('⚡ Loaded cart from cache');
        notifyListeners();

        // Check if cache is still fresh
        if (_isCacheFresh()) {
          print('✅ Cache is fresh, skipping API call');
          return;
        }
      }
    }

    // Load from API in background
    await _syncWithApi(userId);
  }

  /// Load cart from local cache
  Future<bool> _loadFromCache(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('${_cacheKey}_$userId');
      final cacheTime = prefs.getString('${_cacheTimeKey}_$userId');

      if (cachedData != null && cacheTime != null) {
        _cartItems = List<Map<String, dynamic>>.from(
          jsonDecode(cachedData) as List,
        );
        _lastSync = DateTime.parse(cacheTime);
        return true;
      }
    } catch (e) {
      print('❌ Error loading from cache: $e');
    }
    return false;
  }

  /// Save cart to local cache
  Future<void> _saveToCache(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_cacheKey}_$userId',
        jsonEncode(_cartItems),
      );
      await prefs.setString(
        '${_cacheTimeKey}_$userId',
        DateTime.now().toIso8601String(),
      );
      _lastSync = DateTime.now();
    } catch (e) {
      print('❌ Error saving to cache: $e');
    }
  }

  /// Check if cache is still fresh
  bool _isCacheFresh() {
    if (_lastSync == null) return false;
    return DateTime.now().difference(_lastSync!) < _cacheExpiry;
  }

  /// Sync cart with API (background refresh)
  Future<void> _syncWithApi(int userId) async {
    _isRefreshing = true;
    _clearError();
    notifyListeners();

    try {
      print('🔄 Syncing cart with API...');
      final response = await ApiService.getCart(userId);

      if (response != null && response['cart_items'] != null) {
        _cartItems = List<Map<String, dynamic>>.from(response['cart_items']);
        print('✅ Synced ${_cartItems.length} cart items');

        // Save to cache
        await _saveToCache(userId);
      } else {
        _cartItems = [];
        print('📦 Cart is empty');
        await _saveToCache(userId);
      }

      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải giỏ hàng: ${e.toString()}');
      print('❌ Error syncing cart: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Add product to cart with optimistic update
  Future<bool> addToCart(Product product, int quantity, int userId) async {
    _clearError();

    try {
      print('🛒 Adding to cart: ${product.name} x$quantity');

      // Call API (no blocking UI)
      final response = await ApiService.addToCart(
        userId: userId,
        bookId: product.id,
        quantity: quantity,
      );

      if (response != null) {
        print('✅ Successfully added to cart');
        // Refresh cart in background
        await _syncWithApi(userId);
        return true;
      } else {
        _setError('Không thể thêm vào giỏ hàng');
        return false;
      }
    } catch (e) {
      _setError('Lỗi thêm vào giỏ hàng: ${e.toString()}');
      print('❌ Error adding to cart: $e');
      return false;
    }
  }

  /// Update quantity with optimistic update and debounce
  Future<void> updateQuantity(int cartItemId, int quantity, int userId) async {
    _clearError();

    // Optimistic update (update UI immediately)
    final itemIndex = _cartItems.indexWhere((item) => item['id'] == cartItemId);
    if (itemIndex != -1) {
      final oldQuantity = _cartItems[itemIndex]['quantity'];
      _cartItems[itemIndex]['quantity'] = quantity;
      notifyListeners();

      // Update cache immediately
      await _saveToCache(userId);

      // Debounce API call (wait for user to finish changing)
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
        try {
          print('🔄 Updating cart item $cartItemId to quantity $quantity');

          final response = await ApiService.updateCartItem(
            cartItemId: cartItemId,
            quantity: quantity,
          );

          if (response != null) {
            print('✅ Cart item updated on server');
            // Sync with server to get updated totals
            await _syncWithApi(userId);
          } else {
            // Revert optimistic update on failure
            _cartItems[itemIndex]['quantity'] = oldQuantity;
            _setError('Không thể cập nhật số lượng');
            notifyListeners();
          }
        } catch (e) {
          // Revert optimistic update on error
          _cartItems[itemIndex]['quantity'] = oldQuantity;
          _setError('Lỗi cập nhật số lượng: ${e.toString()}');
          print('❌ Error updating quantity: $e');
          notifyListeners();
        }
      });
    }
  }

  /// Remove item from cart with optimistic update
  Future<void> removeFromCart(int cartItemId, int userId) async {
    _clearError();

    // Optimistic update (remove from UI immediately)
    final itemIndex = _cartItems.indexWhere((item) => item['id'] == cartItemId);
    if (itemIndex != -1) {
      final removedItem = _cartItems.removeAt(itemIndex);
      notifyListeners();

      // Update cache immediately
      await _saveToCache(userId);

      try {
        print('🗑️ Removing cart item $cartItemId');

        final success = await ApiService.removeCartItem(cartItemId);

        if (success) {
          print('✅ Cart item removed from server');
        } else {
          // Revert optimistic update on failure
          _cartItems.insert(itemIndex, removedItem);
          _setError('Không thể xóa sản phẩm');
          notifyListeners();
        }
      } catch (e) {
        // Revert optimistic update on error
        _cartItems.insert(itemIndex, removedItem);
        _setError('Lỗi xóa khỏi giỏ hàng: ${e.toString()}');
        print('❌ Error removing from cart: $e');
        notifyListeners();
      }
    }
  }

  /// Clear entire cart with optimistic update
  Future<void> clearCart(int userId) async {
    _clearError();

    // Optimistic update
    final oldCartItems = List<Map<String, dynamic>>.from(_cartItems);
    _cartItems.clear();
    notifyListeners();

    // Update cache immediately
    await _saveToCache(userId);

    try {
      print('🗑️ Clearing cart for user $userId');

      // Delete each item individually
      for (var item in oldCartItems) {
        await ApiService.removeCartItem(item['id']);
      }

      print('✅ Cart cleared on server');
    } catch (e) {
      // Revert optimistic update on error
      _cartItems = oldCartItems;
      _setError('Lỗi xóa giỏ hàng: ${e.toString()}');
      print('❌ Error clearing cart: $e');
      notifyListeners();
    }
  }

  /// Force refresh cart from server
  Future<void> refresh(int userId) async {
    await loadCartItems(userId, forceRefresh: true);
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedUserId != null) {
        await prefs.remove('${_cacheKey}_$_cachedUserId');
        await prefs.remove('${_cacheTimeKey}_$_cachedUserId');
      }
      _lastSync = null;
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Get cart item count
  Future<int> getCartItemCount(int userId) async {
    try {
      final response = await ApiService.getCart(userId);
      if (response != null && response['total_items'] != null) {
        return response['total_items'] as int;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting cart item count: $e');
      return 0;
    }
  }

  /// Check if product is in cart
  bool isInCart(int bookId) {
    try {
      return _cartItems.any((item) => item['book_id'] == bookId);
    } catch (e) {
      print('❌ Error checking if in cart: $e');
      return false;
    }
  }

  /// Get quantity of product in cart
  int getQuantity(int bookId) {
    try {
      final item = _cartItems.firstWhere(
        (item) => item['book_id'] == bookId,
        orElse: () => {'quantity': 0},
      );
      return (item['quantity'] ?? 0) as int;
    } catch (e) {
      print('❌ Error getting quantity: $e');
      return 0;
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
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
