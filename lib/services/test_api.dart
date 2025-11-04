import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class TestApi {
  static Future<void> testConnection() async {
    try {
      print('🔍 Testing API connection...');

      // Test health endpoint
      final healthResponse = await http.get(
        Uri.parse(ApiConstants.healthUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print('Health Status: ${healthResponse.statusCode}');
      print('Health Response: ${healthResponse.body}');

      if (healthResponse.statusCode == 200) {
        print('✅ API connection successful!');

        // Test books endpoint
        final booksResponse = await http.get(
          Uri.parse('${ApiConstants.booksUrl}?limit=5'),
          headers: {'Content-Type': 'application/json'},
        );

        print('Books Status: ${booksResponse.statusCode}');
        if (booksResponse.statusCode == 200) {
          final data = jsonDecode(booksResponse.body);
          print('Books found: ${data['books']?.length ?? 0}');
        }

        // Test categories endpoint
        final categoriesResponse = await http.get(
          Uri.parse(ApiConstants.categoriesUrl),
          headers: {'Content-Type': 'application/json'},
        );

        print('Categories Status: ${categoriesResponse.statusCode}');
        if (categoriesResponse.statusCode == 200) {
          final data = jsonDecode(categoriesResponse.body);
          print('Categories found: ${data['categories']?.length ?? 0}');
        }
      } else {
        print('❌ API connection failed!');
      }
    } catch (e) {
      print('❌ Error testing API: $e');
    }
  }

  static Future<void> testRegister() async {
    try {
      print('🔍 Testing register API...');

      final response = await http.post(
        Uri.parse(ApiConstants.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'testuser${DateTime.now().millisecondsSinceEpoch}',
          'email': 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
          'password': 'password123',
          'first_name': 'Test',
          'last_name': 'User',
          'phone': '0123456789',
          'gender': 'male',
        }),
      );

      print('Register Status: ${response.statusCode}');
      print('Register Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Register test successful!');
      } else {
        print('❌ Register test failed!');
      }
    } catch (e) {
      print('❌ Error testing register: $e');
    }
  }

  static Future<void> testLogin() async {
    try {
      print('🔍 Testing login API...');

      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'testuser',
          'password': 'password123',
        }),
      );

      print('Login Status: ${response.statusCode}');
      print('Login Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Login test successful!');
      } else {
        print('❌ Login test failed!');
      }
    } catch (e) {
      print('❌ Error testing login: $e');
    }
  }
}


