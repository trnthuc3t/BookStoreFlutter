import 'zalopay_platform_service.dart';

class ZaloPayService {
  static ZaloPayService? _instance;
  static ZaloPayService get instance => _instance ??= ZaloPayService._();

  ZaloPayService._();

  Future<Map<String, dynamic>> createOrder(int amountVnd,
      {String? description, String? orderId}) async {
    try {
      // Use Platform Channel for native implementation
      final result = await ZaloPayPlatformService.createOrder(
        amount: amountVnd,
        description: description ?? 'Thanh toán đơn hàng',
        orderId: orderId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );

      if (result != null) {
        return result;
      } else {
        throw Exception('Failed to create order via platform channel');
      }
    } catch (e) {
      print('ZaloPay create order error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> launchZaloPay(String zpTransToken) async {
    try {
      // Use Platform Channel for native implementation
      return await ZaloPayPlatformService.launchZaloPay(zpTransToken);
    } catch (e) {
      print('Launch ZaloPay error: $e');
      return null;
    }
  }

  Future<bool> isZaloPayInstalled() async {
    try {
      return await ZaloPayPlatformService.isZaloPayInstalled();
    } catch (e) {
      print('Check ZaloPay installed error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> queryOrderStatus(String orderId) async {
    try {
      return await ZaloPayPlatformService.queryOrderStatus(orderId);
    } catch (e) {
      print('Query order status error: $e');
      return null;
    }
  }

  Future<bool> refundOrder({
    required String orderId,
    required int amount,
    required String description,
  }) async {
    try {
      return await ZaloPayPlatformService.refundOrder(
        orderId: orderId,
        amount: amount,
        description: description,
      );
    } catch (e) {
      print('Refund order error: $e');
      return false;
    }
  }

  void dispose() {
    // No-op: cleanup handled by platform channel
  }
}
