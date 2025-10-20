import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'home_tab.dart';
import 'product_tab.dart';
import 'history_tab.dart';
import 'account_tab.dart';
import 'chat_screen.dart';
import 'cart_screen.dart';
import 'admin/admin_login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _tabs = [
    const HomeTab(),
    const ProductTab(),
    const HistoryTab(),
    const AccountTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (authProvider.currentUser?.email != null) {
      await cartProvider.loadCartItems(authProvider.currentUser!.email!);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Admin Access Button
          FloatingActionButton(
            heroTag: "admin",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminLoginScreen(),
                ),
              );
            },
            child: const Icon(Icons.admin_panel_settings),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            mini: true,
          ),
          const SizedBox(height: 8),
          // Chat Button
          FloatingActionButton(
            heroTag: "chat",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChatScreen(),
                ),
              );
            },
            child: const Icon(Icons.chat),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
