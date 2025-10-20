import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'feedback_screen.dart';
import 'cart_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          authProvider.currentUser?.email ?? 'Guest',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authProvider.currentUser?.email ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Menu items
                _buildMenuSection(
                  context,
                  'Thông tin cá nhân',
                  [
                    _buildMenuItem(
                      context,
                      Icons.person_outline,
                      'Chỉnh sửa thông tin',
                      () {
                        // TODO: Navigate to edit profile
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.lock_outline,
                      'Đổi mật khẩu',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                _buildMenuSection(
                  context,
                  'Đơn hàng',
                  [
                    _buildMenuItem(
                      context,
                      Icons.shopping_bag_outlined,
                      'Giỏ hàng',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CartScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.location_on_outlined,
                      'Địa chỉ giao hàng',
                      () {
                        // TODO: Navigate to addresses
                      },
                    ),
                  ],
                ),

                _buildMenuSection(
                  context,
                  'Hỗ trợ',
                  [
                    _buildMenuItem(
                      context,
                      Icons.help_outline,
                      'Trợ giúp',
                      () {
                        // TODO: Navigate to help
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.feedback_outlined,
                      'Phản hồi',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FeedbackScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.info_outline,
                      'Về ứng dụng',
                      () {
                        // TODO: Show about dialog
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Đăng xuất'),
                          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          child: Column(children: items),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
