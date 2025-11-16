import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

/// Admin API Service - Handles all admin-related API calls with JWT authentication
class AdminApiService {
  
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  /// Get all vouchers (admin) with JWT authentication
  static Future<Map<String, dynamic>> getAdminVouchers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/vouchers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'vouchers': data['vouchers'] ?? [],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Unauthorized. Please login again.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'Access denied. Admin privileges required.',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load vouchers: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Create new voucher (admin) with JWT authentication
  static Future<Map<String, dynamic>> createVoucher(Map<String, dynamic> voucherData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/vouchers'),
        headers: headers,
        body: json.encode(voucherData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Voucher created successfully',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'Failed to create voucher',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Update voucher (admin) with JWT authentication
  static Future<Map<String, dynamic>> updateVoucher(int voucherId, Map<String, dynamic> voucherData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/vouchers/$voucherId'),
        headers: headers,
        body: json.encode(voucherData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Voucher updated successfully',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'Failed to update voucher',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Delete voucher (admin) with JWT authentication
  static Future<Map<String, dynamic>> deleteVoucher(int voucherId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/vouchers/$voucherId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Voucher deleted successfully',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'Failed to delete voucher',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}