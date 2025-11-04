import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_new.dart' as api_auth;
import 'login_screen.dart';
import 'main_screen.dart';
import 'admin_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Điều hướng sau frame đầu để đảm bảo context sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthStatus());

    // Listen to auth changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          Provider.of<api_auth.AuthProvider>(context, listen: false);
      authProvider.addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    final authProvider =
        Provider.of<api_auth.AuthProvider>(context, listen: false);
    authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;

    try {
      final authProvider =
          Provider.of<api_auth.AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        // Check if user is admin
        final isAdmin = authProvider.currentUser?.isAdmin ?? false;

        if (isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('❌ Error in _onAuthStateChanged: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Wait for auth provider to initialize
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      final authProvider =
          Provider.of<api_auth.AuthProvider>(context, listen: false);

      // Wait for loading to complete with timeout
      int attempts = 0;
      while (authProvider.isLoading && attempts < 20 && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (!mounted) return;

      if (authProvider.isLoggedIn) {
        // Check if user is admin
        final isAdmin = authProvider.currentUser?.isAdmin ?? false;

        print('🔐 Auto-login detected. User is ${isAdmin ? "ADMIN" : "USER"}');

        if (isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('❌ Error in _checkAuthStatus: $e');
      // Always navigate somewhere to prevent app stuck
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'BookSell',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cửa hàng sách trực tuyến',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
