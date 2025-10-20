import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../screens/login_screen.dart';
import 'admin_voucher_screen.dart';
import 'admin_feedback_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Thống kê'),
          _buildStatCard(
            context,
            'Tổng sản phẩm',
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                return Text(
                  '${productProvider.products.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                );
              },
            ),
            Icons.inventory,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildStatCard(
            context,
            'Tổng đơn hàng',
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return Text(
                  '${orderProvider.orders.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                );
              },
            ),
            Icons.shopping_cart,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildStatCard(
            context,
            'Đơn hàng đang xử lý',
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                final processingOrders = orderProvider.orders
                    .where((order) => order.status == 'pending' || order.status == 'processing')
                    .length;
                return Text(
                  '$processingOrders',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                );
              },
            ),
            Icons.pending_actions,
            Colors.orange,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Quản lý'),
          _buildListTile(
            context,
            'Quản lý voucher',
            Icons.local_offer,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminVoucherScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            'Quản lý phản hồi',
            Icons.feedback,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminFeedbackScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            'Báo cáo doanh thu',
            Icons.analytics,
            () {
              // TODO: Navigate to revenue report
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Tài khoản'),
          _buildListTile(
            context,
            'Đổi mật khẩu',
            Icons.lock,
            () {
              // TODO: Navigate to change password
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _buildListTile(
            context,
            'Đăng xuất',
            Icons.logout,
            () => _showLogoutDialog(context),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    Widget value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  value,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthProvider>().signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
