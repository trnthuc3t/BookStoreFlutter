import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _userOrders = [];
  List<Order> _allOrders = [];
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get userOrders => _userOrders;
  List<Order> get allOrders => _allOrders;
  List<Voucher> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserOrders({required int userId}) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await ApiService.getUserOrders(userId: userId);
      _userOrders = data.map((item) => Order.fromJson(item)).toList();
      print('Loaded ${_userOrders.length} user orders');
    } catch (e) {
      _setError('Lỗi tải đơn hàng: ${e.toString()}');
      print('Error loading user orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOrders() async {
    _setLoading(true);
    _clearError();

    try {
      // This would need admin endpoint in ApiService
      // Skip for now - user orders will be loaded when needed
    } catch (e) {
      _setError('Lỗi tải đơn hàng: ${e.toString()}');
      print('Error loading orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVouchers({int? userId}) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await ApiService.getVouchers(userId: userId);
      print('Loaded ${data.length} vouchers from API');
      
      _vouchers = data.map<Voucher>((item) {
        // Use Voucher.fromJson for safe parsing
        return Voucher.fromJson(item);
      }).toList();
      print('Successfully parsed ${_vouchers.length} vouchers');
      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải voucher: ${e.toString()}');
      print('Error loading vouchers: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Order?> createOrder({
    required int userId,
    required int shippingAddressId,
    required int paymentMethodId,
    int? voucherId,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await ApiService.createOrder(
        userId: userId,
        shippingAddressId: shippingAddressId,
        paymentMethodId: paymentMethodId,
        voucherId: voucherId,
        notes: notes,
      );
      if (data != null) {
        final order = Order.fromJson(data);
        _userOrders.insert(0, order);
        notifyListeners();
        return order;
      }
      return null;
    } catch (e) {
      _setError('Lỗi tạo đơn hàng: ${e.toString()}');
      print('Error creating order: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateOrderStatus(int orderId, String status,
      {int? userId}) async {
    _setLoading(true);
    _clearError();

    try {
      // This would need admin endpoint in ApiService
      // For now, just reload orders if userId provided
      if (userId != null) {
        await loadUserOrders(userId: userId);
      }
    } catch (e) {
      _setError('Lỗi cập nhật trạng thái đơn hàng: ${e.toString()}');
      print('Error updating order status: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelOrder(int orderId, {int? userId}) async {
    _setLoading(true);
    _clearError();

    try {
      // This would need cancel endpoint in ApiService
      // For now, just reload orders if userId provided
      if (userId != null) {
        await loadUserOrders(userId: userId);
      }
    } catch (e) {
      _setError('Lỗi hủy đơn hàng: ${e.toString()}');
      print('Error cancelling order: $e');
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
