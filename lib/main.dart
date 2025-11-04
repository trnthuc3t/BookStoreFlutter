import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider_new.dart' as api_auth; // API-based auth
import 'providers/cart_provider_new.dart';
import 'providers/product_provider_new.dart'
    as api_providers; // API-based provider
import 'providers/order_provider_new.dart' as api_order; // API-based order
import 'providers/chat_provider.dart';
import 'services/firebase_service.dart';
import 'services/database_service.dart';
import 'services/gemini_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Initialize services with error handling
    await FirebaseService.instance.initialize();
    print('✅ FirebaseService initialized successfully');

    await DatabaseService.instance.database; // Initialize database
    print('✅ DatabaseService initialized successfully');

    // Initialize Gemini service (optional, won't crash if fails)
    try {
      await GeminiService.instance.initialize();
      print('✅ GeminiService initialized successfully');
    } catch (e) {
      print('⚠️ Warning: Gemini service initialization failed: $e');
    }

    runApp(const BookSellApp());
  } catch (e) {
    print('❌ Error during app initialization: $e');
    // Run app anyway with basic functionality
    runApp(const BookSellApp());
  }
}

class BookSellApp extends StatelessWidget {
  const BookSellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => api_auth.AuthProvider()), // Use API auth
        ChangeNotifierProvider(
            create: (_) => CartApiProvider()), // Use API cart
        ChangeNotifierProvider(
            create: (_) =>
                api_providers.ProductApiProvider()), // Use API provider
        ChangeNotifierProvider(
            create: (_) => api_order.OrderProvider()), // Use API order
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'BookSell',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
