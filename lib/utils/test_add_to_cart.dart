import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Test script để debug vấn đề add to cart
class TestAddToCart {
  static Future<void> runTest() async {
    print('🧪 ========== TEST ADD TO CART ==========');
    
    // 1. Kiểm tra tokens
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final accessToken = prefs.getString('auth_token');
    final refreshToken = prefs.getString('refresh_token');
    
    print('\n📋 Step 1: Check stored credentials');
    print('   User ID: ${userId ?? "NOT FOUND"}');
    print('   Access Token: ${accessToken != null ? "EXISTS (${accessToken.length} chars)" : "NOT FOUND"}');
    print('   Refresh Token: ${refreshToken != null ? "EXISTS (${refreshToken.length} chars)" : "NOT FOUND"}');
    
    if (userId == null) {
      print('\n❌ FAILED: No user_id found. Please login first.');
      return;
    }
    
    if (accessToken == null) {
      print('\n❌ FAILED: No access_token found. Please login first.');
      return;
    }
    
    // 2. Test add to cart với book ID 1
    print('\n📋 Step 2: Test add to cart API');
    print('   Calling ApiService.addToCart(userId: $userId, bookId: 1, quantity: 1)');
    
    try {
      final result = await ApiService.addToCart(
        userId: int.parse(userId),
        bookId: 1,
        quantity: 1,
      );
      
      print('\n📥 Result received:');
      print('   $result');
      
      if (result != null && !result.containsKey('error')) {
        print('\n✅ SUCCESS: Add to cart worked!');
      } else {
        print('\n❌ FAILED: ${result?['message'] ?? 'Unknown error'}');
        if (result?.containsKey('error') == true) {
          print('   Error type: ${result!['error']}');
        }
      }
    } catch (e, stackTrace) {
      print('\n❌ EXCEPTION: $e');
      print('Stack trace: $stackTrace');
    }
    
    print('\n🧪 ========== TEST COMPLETED ==========\n');
  }
  
  /// Test refresh token riêng
  static Future<void> testRefreshToken() async {
    print('🧪 ========== TEST REFRESH TOKEN ==========');
    
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    
    if (refreshToken == null) {
      print('❌ No refresh token found. Please login first.');
      return;
    }
    
    print('Refresh token exists: ${refreshToken.substring(0, 30)}...');
    print('\nCalling refreshAccessToken()...');
    
    final success = await ApiService.refreshAccessToken();
    
    if (success) {
      print('✅ Refresh token SUCCESS');
      
      // Check new access token
      final newAccessToken = prefs.getString('auth_token');
      print('New access token: ${newAccessToken?.substring(0, 30)}...');
    } else {
      print('❌ Refresh token FAILED');
    }
    
    print('\n🧪 ========== TEST COMPLETED ==========\n');
  }
}
