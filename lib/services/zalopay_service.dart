import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import 'zalopay_platform_service.dart';

class ZaloPayService {
  static ZaloPayService? _instance;
  static ZaloPayService get instance => _instance ??= ZaloPayService._();
  
  ZaloPayService._();

  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> createOrder(int amountVnd, {String? description, String? orderId}) async {
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

  Future<bool> launchZaloPay(String orderUrl) async {
    try {
      // Use Platform Channel for native implementation
      return await ZaloPayPlatformService.launchZaloPay(orderUrl);
    } catch (e) {
      print('Launch ZaloPay error: $e');
      return false;
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

  Stream<Map<String, dynamic>> get paymentResultStream {
    return ZaloPayPlatformService.paymentResultStream;
  }

  Future<bool> handleDeepLink(String url) async {
    if (url.startsWith(AppConstants.zalopayDeepLinkScheme)) {
      // Handle ZaloPay callback
      print('ZaloPay deep link received: $url');
      // Parse the callback and handle payment result
      return true;
    }
    return false;
  }

  String _hmacSha256(String key, String data) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    return digest.toString();
  }

  String _getDatePart() {
    final now = DateTime.now();
    return '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  int _generateRandomNumber() {
    return 100000 + (DateTime.now().millisecondsSinceEpoch % 900000);
  }

  void dispose() {
    _client.close();
  }
}
