import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_models;
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    // Initialize auth on startup
    Future.delayed(const Duration(milliseconds: 100), () {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    print('🔄 Starting auth initialization...');
    _setLoading(true);

    try {
      // Try auto login first - with timeout
      print('🔍 Attempting auto login...');

      // Add timeout to prevent hanging
      final autoLoginSuccess =
          await autoLogin().timeout(const Duration(seconds: 5), onTimeout: () {
        print('⏰ Auto login timeout');
        return false;
      });

      if (autoLoginSuccess) {
        print('✅ Auto login successful!');
      } else {
        print('❌ Auto login failed - user needs to login');
        _currentUser = null;
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error initializing auth: $e');
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
      print('✅ Auth initialization completed');
    }
  }

  Future<bool> autoLogin() async {
    try {
      print('🔐 Checking if user is logged in...');

      // Require valid token for auto login
      final hasToken = await ApiService.isLoggedIn();
      if (!hasToken) {
        print('❌ No token found, skip auto login');
        return false;
      }

      // Load minimal user info from storage
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id');
      final email = prefs.getString('email');
      final role = prefs.getString('role');
      final firstName = prefs.getString('first_name');
      final lastName = prefs.getString('last_name');

      if (userIdStr == null || email == null) {
        print('❌ Missing user data despite token, skip auto login');
        return false;
      }

      final userId = int.tryParse(userIdStr);
      _currentUser = app_models.User(
        id: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        isAdmin: role == 'admin',
        isStaff: role == 'staff',
      );

      print('✅ Auto login successful with token - ID: $userId');
      return true;
    } catch (e) {
      print('❌ Auto login error: $e');
      return false;
    }
  }

  Future<bool> signIn(String usernameOrEmail, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.login(usernameOrEmail, password);
      if (result != null && result['user'] != null) {
        // Get user info from response
        final userData = result['user'];

        // If backend returns verification status, enforce it here
        final dynamic verifiedFlag = userData['is_verified'] ??
            userData['email_verified'] ??
            userData['isEmailVerified'];
        if (verifiedFlag is bool && verifiedFlag == false) {
          await ApiService.logout(); // remove stored token if any
          _setError('Email chưa được xác thực. Vui lòng kiểm tra email.');
          return false;
        }

        // Store user ID and all info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userData['id'].toString());
        await prefs.setString('username', userData['username'] ?? '');
        await prefs.setString('email', userData['email'] ?? '');
        await prefs.setString('first_name', userData['first_name'] ?? '');
        await prefs.setString('last_name', userData['last_name'] ?? '');
        await prefs.setString('role', userData['role'] ?? '');

        _currentUser = app_models.User(
          id: userData['id'],
          email: userData['email'] ?? '',
          firstName: userData['first_name'],
          lastName: userData['last_name'],
          role: userData['role'],
          isAdmin: userData['role'] == 'admin',
          isStaff: userData['role'] == 'staff',
        );

        // Store email for auto login
        await _storeEmail(userData['email'] ?? usernameOrEmail);
        notifyListeners();
        return true;
      }

      _setError('Tên đăng nhập/email hoặc mật khẩu không đúng');
      return false;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _setError(msg);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? gender, // Currently not used by backend
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      if (result != null) {
        // Do NOT log the user in after registration.
        // Only store email to support resend verification later.
        await _storeEmail(result['email'] ?? email);

        // Ensure not logged in yet
        _currentUser = null;
        notifyListeners();
        print('✅ Registered successfully. Awaiting email verification.');
        return true;
      } else {
        _setError('Đăng ký thất bại. Username hoặc email đã được sử dụng.');
        return false;
      }
    } catch (e) {
      _setError('Lỗi đăng ký: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    print('🚪 Signing out...');
    try {
      await ApiService.logout();
      print('✅ Token removed');

      // Clear all stored data
      await _clearStoredEmail();
      await _clearAllUserData();

      _currentUser = null;
      print('✅ User data cleared');
      notifyListeners();
    } catch (e) {
      print('❌ Sign out error: $e');
    }
  }

  // Đổi mật khẩu khi đang đăng nhập
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (!isLoggedIn) {
        _setError('Bạn chưa đăng nhập.');
        return false;
      }

      int? uid = _currentUser?.id;
      if (uid == null) {
        final prefs = await SharedPreferences.getInstance();
        uid = int.tryParse(prefs.getString('user_id') ?? '');
      }
      if (uid == null) {
        _setError('Không xác định được người dùng.');
        return false;
      }

      final result = await ApiService.changePassword(
        userId: uid,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result['ok'] == true) {
        return true;
      } else {
        _setError(result['message']?.toString() ?? 'Đổi mật khẩu thất bại.');
        return false;
      }
    } catch (e) {
      _setError('Lỗi: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('first_name');
      await prefs.remove('last_name');
      await prefs.remove('stored_email');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  Future<bool> isAdmin() async {
    if (_currentUser == null) return false;
    return _currentUser!.isAdmin;
  }

  Future<String?> getStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('stored_email');
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stored_email', email);
    } catch (e) {
      print('Error storing email: $e');
    }
  }

  Future<void> _clearStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('stored_email');
    } catch (e) {
      print('Error clearing stored email: $e');
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

  // Gửi email quên mật khẩu
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.forgotPassword(email);
      if (result != null) {
        print('✅ Forgot password email sent');
        return true;
      }

      _setError('Gửi email thất bại');
      return false;
    } catch (e) {
      _setError('Lỗi: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Đặt lại mật khẩu với token
  Future<bool> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      if (result != null) {
        print('✅ Password reset successful');
        return true;
      }

      _setError('Đặt lại mật khẩu thất bại');
      return false;
    } catch (e) {
      _setError('Lỗi: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Xác thực email
  Future<bool> verifyEmail(String token) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.verifyEmail(token);
      if (result != null) {
        print('✅ Email verified successfully');
        return true;
      }

      _setError('Xác thực email thất bại');
      return false;
    } catch (e) {
      _setError('Lỗi: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Gửi lại email xác thực
  Future<bool> resendVerification(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.resendVerification(email);
      if (result != null) {
        print('✅ Verification email resent');
        return true;
      }

      _setError('Gửi lại email thất bại');
      return false;
    } catch (e) {
      _setError('Lỗi: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
