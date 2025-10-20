import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/order.dart';
import '../models/voucher.dart';
import '../services/firebase_service.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  List<Order> _orders = [];
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  List<Voucher> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filter orders by status
  List<Order> getOrdersByStatus(int status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<Order> getProcessingOrders() {
    return getOrdersByStatus(AppConstants.orderStatusDoing);
  }

  List<Order> getCompletedOrders() {
    return getOrdersByStatus(AppConstants.orderStatusComplete);
  }

  Future<void> loadUserOrders(String userEmail) async {
    _setLoading(true);
    _clearError();

    try {
      final query = _firebaseService.orderByChild('order', 'userEmail')
          .equalTo(userEmail);
      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _orders = data.values
            .map((item) => Order.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        
        // Sort by date (newest first)
        _orders.sort((a, b) => b.id.compareTo(a.id));
      }
      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải đơn hàng: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVouchers() async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firebaseService.getData('voucher');
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _vouchers = data.values
            .map((item) => Voucher.fromJson(Map<String, dynamic>.from(item)))
            .where((voucher) => voucher.isActive)
            .toList();
      }
      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải voucher: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createOrder(Order order) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.setData('order/${order.id}', order.toJson());
      
      // Add to local list
      _orders.insert(0, order);
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Lỗi tạo đơn hàng: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateOrderStatusInt(int orderId, int status) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.updateData('order/$orderId', {'status': status});
      
      // Update local list
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: status.toString());
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Lỗi cập nhật trạng thái đơn hàng: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Order?> getOrderById(int orderId) async {
    try {
      final snapshot = await _firebaseService.getOrderDetailRef(orderId).get();
      if (snapshot.exists) {
        return Order.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
    } catch (e) {
      print('Error getting order by ID: $e');
    }
    return null;
  }

  Voucher? getVoucherByCode(String code) {
    try {
      return _vouchers.firstWhere((voucher) => voucher.code == code);
    } catch (e) {
      return null;
    }
  }

  List<Voucher> getAvailableVouchers(int totalPrice) {
    return _vouchers.where((voucher) {
      return voucher.isActive && totalPrice >= voucher.minPrice;
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

  // Admin functions
  Future<void> loadOrders() async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firebaseService.getData('order');
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _orders = data.values
            .map((item) => Order.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        
        // Sort by date (newest first)
        _orders.sort((a, b) => b.id.compareTo(a.id));
      }
      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải đơn hàng: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.updateData('order/$orderId', {'status': status});
      
      // Update local list
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: status);
        notifyListeners();
      }
    } catch (e) {
      _setError('Lỗi cập nhật trạng thái đơn hàng: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setData(String path, Map<String, dynamic> data) async {
    try {
      await _firebaseService.setData(path, data);
    } catch (e) {
      _setError('Lỗi lưu dữ liệu: ${e.toString()}');
    }
  }

  Future<void> removeData(String path) async {
    try {
      await _firebaseService.removeData(path);
    } catch (e) {
      _setError('Lỗi xóa dữ liệu: ${e.toString()}');
    }
  }

  // Get address reference
  dynamic get addressRef => _firebaseService.getData('address');
}
