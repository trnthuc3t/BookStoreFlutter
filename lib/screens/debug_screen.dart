import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Debug screen to check authentication status and cart functionality
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, String> _prefs = {};
  bool _isLoading = true;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    Map<String, String> prefsMap = {};
    for (var key in keys) {
      final value = prefs.get(key);
      if (key.contains('token') && value != null) {
        // Only show first 20 chars for security
        prefsMap[key] = value.toString().substring(0, 20) + '...';
      } else {
        prefsMap[key] = value.toString();
      }
    }
    
    setState(() {
      _prefs = prefsMap;
      _isLoading = false;
    });
  }

  Future<void> _testAddToCart() async {
    setState(() => _testResult = 'Testing...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id');
      final token = prefs.getString('auth_token');
      
      if (userIdStr == null) {
        setState(() => _testResult = '❌ No user_id found! Please login first.');
        return;
      }
      
      if (token == null) {
        setState(() => _testResult = '❌ No auth_token found! Please login first.');
        return;
      }
      
      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        setState(() => _testResult = '❌ Invalid user_id format: $userIdStr');
        return;
      }
      
      // Test add to cart with book ID 1
      print('🧪 Testing addToCart: userId=$userId, bookId=1, quantity=1');
      final result = await ApiService.addToCart(
        userId: userId,
        bookId: 1,
        quantity: 1,
      );
      
      if (result != null) {
        setState(() => _testResult = '✅ Success! Added to cart.\nResponse: ${result.toString()}');
      } else {
        setState(() => _testResult = '❌ Failed! API returned null.\nCheck console logs for details.');
      }
    } catch (e) {
      setState(() => _testResult = '❌ Error: $e');
    }
  }

  Future<void> _testRefreshToken() async {
    setState(() => _testResult = 'Testing refresh token...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) {
        setState(() => _testResult = '❌ No refresh_token found! Please login first.');
        return;
      }
      
      print('🧪 Testing refreshAccessToken()...');
      final success = await ApiService.refreshAccessToken();
      
      if (success) {
        // Get new access token
        await _loadPreferences();
        setState(() => _testResult = '✅ Success! Token refreshed.\nCheck console for details.');
      } else {
        setState(() => _testResult = '❌ Failed! Could not refresh token.\nCheck console logs for details.');
      }
    } catch (e) {
      setState(() => _testResult = '❌ Error: $e');
    }
  }

  Future<void> _clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _loadPreferences();
    setState(() => _testResult = 'All preferences cleared!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPreferences,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Authentication Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatusRow(
                            'User ID',
                            _prefs['user_id'] ?? 'NOT FOUND',
                            _prefs.containsKey('user_id'),
                          ),
                          _buildStatusRow(
                            'Auth Token',
                            _prefs['auth_token'] ?? 'NOT FOUND',
                            _prefs.containsKey('auth_token'),
                          ),
                          _buildStatusRow(
                            'Refresh Token',
                            _prefs['refresh_token'] ?? 'NOT FOUND',
                            _prefs.containsKey('refresh_token'),
                          ),
                          _buildStatusRow(
                            'Username',
                            _prefs['username'] ?? 'NOT FOUND',
                            _prefs.containsKey('username'),
                          ),
                          _buildStatusRow(
                            'Email',
                            _prefs['email'] ?? 'NOT FOUND',
                            _prefs.containsKey('email'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // All Preferences
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All SharedPreferences',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_prefs.isEmpty)
                            const Text(
                              'No preferences found',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ..._prefs.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Test Result
                  if (_testResult.isNotEmpty)
                    Card(
                      color: _testResult.contains('✅')
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Test Result',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_testResult),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testAddToCart,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Test Add to Cart (Book ID: 1)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testRefreshToken,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Test Refresh Token'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearPreferences,
                      icon: const Icon(Icons.delete),
                      label: const Text('Clear All Preferences'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Instructions
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('1. Check if user_id and auth_token exist'),
                          Text('2. If missing, login first'),
                          Text('3. Click "Test Add to Cart" button'),
                          Text('4. Check console logs for detailed output'),
                          Text('5. Check test result above'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool exists) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            exists ? Icons.check_circle : Icons.cancel,
            color: exists ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: exists ? Colors.black : Colors.red,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
