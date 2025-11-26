import 'package:shared_preferences/shared_preferences.dart';

/// Helper class to debug cart issues
class CartDebug {
  /// Check if user is properly logged in
  static Future<void> checkLoginStatus() async {
    print('🔍 === CART DEBUG: Checking login status ===');
    
    final prefs = await SharedPreferences.getInstance();
    
    // Check auth token
    final token = prefs.getString('auth_token');
    if (token != null) {
      print('✅ Auth token exists: ${token.substring(0, 20)}...');
    } else {
      print('❌ No auth token found!');
    }
    
    // Check user ID
    final userId = prefs.getString('user_id');
    if (userId != null) {
      print('✅ User ID: $userId');
    } else {
      print('❌ No user ID found!');
    }
    
    // Check username
    final username = prefs.getString('username');
    if (username != null) {
      print('✅ Username: $username');
    } else {
      print('❌ No username found!');
    }
    
    // Check email
    final email = prefs.getString('email');
    if (email != null) {
      print('✅ Email: $email');
    } else {
      print('❌ No email found!');
    }
    
    print('🔍 === END CART DEBUG ===\n');
  }
  
  /// Print all stored preferences for debugging
  static Future<void> printAllPreferences() async {
    print('🔍 === ALL SHARED PREFERENCES ===');
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    if (keys.isEmpty) {
      print('❌ No preferences found!');
    } else {
      for (var key in keys) {
        final value = prefs.get(key);
        if (key.contains('token')) {
          // Only show first 20 chars of token for security
          print('$key: ${value.toString().substring(0, 20)}...');
        } else {
          print('$key: $value');
        }
      }
    }
    
    print('🔍 === END PREFERENCES ===\n');
  }
}
