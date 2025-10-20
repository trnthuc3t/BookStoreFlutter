import 'dart:async';
import 'package:flutter/services.dart';

class ZaloPayPlatformService {
  static const MethodChannel _channel = MethodChannel('zalopay_payment');

  static Future<Map<String, dynamic>?> createOrder({
    required int amount,
    required String description,
    required String orderId,
  }) async {
    try {
      final result = await _channel.invokeMethod('createOrder', {
        'amount': amount,
        'description': description,
        'orderId': orderId,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print('ZaloPay create order error: ${e.message}');
      return null;
    }
  }

  static Future<bool> launchZaloPay(String orderUrl) async {
    try {
      final result = await _channel.invokeMethod('launchZaloPay', {
        'orderUrl': orderUrl,
      });
      return result as bool;
    } on PlatformException catch (e) {
      print('ZaloPay launch error: ${e.message}');
      return false;
    }
  }

  static Future<bool> isZaloPayInstalled() async {
    try {
      final result = await _channel.invokeMethod('isZaloPayInstalled');
      return result as bool;
    } on PlatformException catch (e) {
      print('ZaloPay check installed error: ${e.message}');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> queryOrderStatus(String orderId) async {
    try {
      final result = await _channel.invokeMethod('queryOrderStatus', {
        'orderId': orderId,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print('ZaloPay query order error: ${e.message}');
      return null;
    }
  }

  static Future<bool> refundOrder({
    required String orderId,
    required int amount,
    required String description,
  }) async {
    try {
      final result = await _channel.invokeMethod('refundOrder', {
        'orderId': orderId,
        'amount': amount,
        'description': description,
      });
      return result as bool;
    } on PlatformException catch (e) {
      print('ZaloPay refund error: ${e.message}');
      return false;
    }
  }

  static Stream<Map<String, dynamic>> get paymentResultStream {
    return _channel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }
}
