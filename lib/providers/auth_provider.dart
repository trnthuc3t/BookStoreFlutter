import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_models;
import '../services/firebase_service.dart';
import '../constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    // Delay initialization to ensure Firebase is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      // Try auto login first
      final autoLoginSuccess = await autoLogin();

      if (!autoLoginSuccess) {
        // If auto login failed, set current user to null
        _currentUser = null;
      }

      notifyListeners();

      // Sau đó mới subscribe stream để cập nhật theo thời gian thực
      _firebaseService.authStateChanges
          .listen((firebase_auth.User? user) async {
        if (user != null) {
          // Load admin status when user is authenticated
          final isAdminStatus = await isAdmin();
          _currentUser = app_models.User(
            email: user.email,
            isAdmin: isAdminStatus,
          );
        } else {
          _currentUser = null;
        }
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing auth: $e');
      // Set default state if initialization fails
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final userCredential =
          await _firebaseService.signInWithEmailAndPassword(email, password);

      if (userCredential != null) {
        final u = userCredential.user;
        _currentUser = u != null
            ? app_models.User(
                email: u.email,
                isAdmin: false,
              )
            : null;

        // Save user data to SharedPreferences
        await _saveUserData(email, false); // Default to non-admin

        // Check if user is admin
        await _checkAdminStatus(email);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Đăng nhập thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final userCredential = await _firebaseService
          .createUserWithEmailAndPassword(email, password);

      if (userCredential != null) {
        final u = userCredential.user;
        _currentUser = u != null
            ? app_models.User(
                email: u.email,
                isAdmin: false,
              )
            : null;

        // Save user data to SharedPreferences
        await _saveUserData(email, false);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Đăng ký thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _firebaseService.signOut();
      _currentUser = null;

      // Clear user data from SharedPreferences
      await _clearUserData();

      notifyListeners();
    } catch (e) {
      _setError('Đăng xuất thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError('Gửi email đặt lại mật khẩu thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _checkAdminStatus(String email) async {
    try {
      final adminSnapshot = await _firebaseService.getData('admin');
      if (adminSnapshot.exists) {
        final adminData = adminSnapshot.value;

        if (adminData is Map<dynamic, dynamic>) {
          // Firebase returns a Map
          final isAdmin = adminData.values.any((admin) {
            if (admin is Map && admin['email'] == email) {
              return admin['isAdmin'] == true;
            }
            return false;
          });

          if (isAdmin) {
            await _saveUserData(email, true);
          }
        } else if (adminData is List) {
          // Firebase returns a List
          final isAdmin = adminData.any((admin) {
            if (admin is Map && admin['email'] == email) {
              return admin['isAdmin'] == true;
            }
            return false;
          });

          if (isAdmin) {
            await _saveUserData(email, true);
          }
        } else {
          print('Unexpected data type for admin: ${adminData.runtimeType}');
        }
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _saveUserData(String email, bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userEmailKey, email);
    await prefs.setBool(AppConstants.isAdminKey, isAdmin);
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.isAdminKey);
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.isAdminKey) ?? false;
  }

  Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userEmailKey);
  }

  Future<bool> autoLogin() async {
    try {
      final storedEmail = await getStoredEmail();
      if (storedEmail != null) {
        // Check if Firebase user is still authenticated
        final firebaseUser = _firebaseService.currentUser;
        if (firebaseUser != null && firebaseUser.email == storedEmail) {
          // User is still authenticated, load admin status
          final isAdminStatus = await isAdmin();
          _currentUser = app_models.User(
            email: firebaseUser.email,
            isAdmin: isAdminStatus,
          );
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Auto login error: $e');
      return false;
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
}
