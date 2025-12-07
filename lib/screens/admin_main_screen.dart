import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_new.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'admin_product_form_screen.dart';
import 'admin/admin_statistics_screen.dart';
import 'admin/admin_voucher_dashboard_screen.dart';
import 'order_detail_screen.dart';

/// Main screen for Admin with completely different UI
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  List<Widget>? _cachedScreens;

  List<Widget> _getScreens() {
    // Cache screens để tránh recreate mỗi lần build
    if (_cachedScreens != null) {
      return _cachedScreens!;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;

    // Staff không được xem Dashboard (doanh thu)
    if (isAdmin) {
      _cachedScreens = [
        const AdminDashboardTab(),
        const AdminOrdersTab(),
        const AdminProductsTab(),
        const AdminVoucherDashboardScreen(),
        const AdminUsersTab(),
      ];
    } else {
      // Staff chỉ xem Orders, Products, Vouchers, Users
      _cachedScreens = [
        const AdminOrdersTab(),
        const AdminProductsTab(),
        const AdminVoucherDashboardScreen(),
        const AdminUsersTab(),
      ];
    }
    return _cachedScreens!;
  }

  List<BottomNavigationBarItem> _getNavItems() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;

    if (isAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Đơn hàng',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Sản phẩm',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.discount),
          label: 'Voucher',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Người dùng',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Đơn hàng',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Sản phẩm',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.discount),
          label: 'Voucher',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Người dùng',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    final navItems = _getNavItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              }
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: navItems,
      ),
    );
  }
}

// ===== DASHBOARD TAB =====
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    print('🔄 Loading admin dashboard...');
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getAdminDashboard();
      print('✅ Dashboard data received: $data');

      if (data == null) {
        print('❌ Dashboard data is null');
      }

      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dashboardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Không thể tải dữ liệu'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final stats = _dashboardData!['stats'] as Map<String, dynamic>;
    final recentOrders = _dashboardData!['recent_orders'] as List<dynamic>;
    final topBooks = _dashboardData!['top_books'] as List<dynamic>;
    final orderStatuses = _dashboardData!['order_statuses'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 48, color: Colors.orange),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chào mừng Admin!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Quản lý cửa hàng của bạn',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
            children: [
              _buildStatCard(
                'Người dùng',
                stats['total_users'].toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Sản phẩm',
                stats['total_books'].toString(),
                Icons.inventory,
                Colors.green,
              ),
              _buildStatCard(
                'Đơn hàng',
                stats['total_orders'].toString(),
                Icons.shopping_cart,
                Colors.orange,
              ),
              _buildStatCard(
                'Doanh thu',
                '${(stats['total_revenue'] / 1000000).toStringAsFixed(1)}M',
                Icons.attach_money,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistics Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminStatisticsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Xem thống kê chi tiết'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Order Status Distribution
          if (orderStatuses.isNotEmpty) ...[
            _buildSectionTitle('Phân bố đơn hàng'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: orderStatuses.map((status) {
                    final statusName = status['status'];
                    final count = status['count'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(statusName),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_getStatusLabel(statusName))),
                          Text(
                            count.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Recent Orders
          _buildSectionTitle('Đơn hàng gần đây'),
          const SizedBox(height: 12),
          ...recentOrders.map((order) => _buildOrderCard(order)),

          const SizedBox(height: 24),

          // Top Books
          _buildSectionTitle('Sách bán chạy'),
          const SizedBox(height: 12),
          ...topBooks.map((book) => _buildBookCard(book)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final date = DateTime.parse(order['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order['status']),
          child: const Icon(Icons.receipt, color: Colors.white, size: 20),
        ),
        title: Text(
          order['order_number'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${order['user_name']}\n${formatter.format(date)}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(order['total_amount'] / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(order['status']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusLabel(order['status']),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.book, color: Colors.green),
        ),
        title: Text(
          book['title'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Đã bán: ${book['sold_quantity']} cuốn'),
        trailing: Text(
          '${(book['price'] / 1000).toStringAsFixed(0)}k',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

// ===== ORDERS TAB =====
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _selectedStatus;
  bool _hasLoadedOnce = false; // Flag để biết đã load lần đầu chưa

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didUpdateWidget(AdminOrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ reload nếu filter thay đổi, không reload khi widget rebuild
    // (Widget sẽ không bị recreate nếu parent cache screens đúng cách)
  }

  Future<void> _loadOrders({bool forceReload = false}) async {
    // Nếu đã có dữ liệu và không phải force reload, không reload lại
    if (_hasLoadedOnce && _orders.isNotEmpty && !forceReload && !_isLoading) {
      print('⏭️ Skipping reload - data already loaded');
      return;
    }

    print(
        '🔄 Loading admin orders... (status: $_selectedStatus, forceReload: $forceReload)');
    setState(() => _isLoading = true);

    try {
      final orders = await ApiService.getAdminOrders(status: _selectedStatus);
      print('✅ Orders received: ${orders.length} orders');

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      if (mounted) {
        setState(() {
          // Chỉ clear orders nếu chưa load lần nào, nếu không thì giữ lại danh sách cũ
          if (!_hasLoadedOnce) {
            _orders = [];
          }
          _isLoading = false;
          _hasLoadedOnce = true;
        });

        // Chỉ hiển thị lỗi nếu chưa có dữ liệu
        if (_orders.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải đơn hàng: $e'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Thử lại',
                textColor: Colors.white,
                onPressed: () => _loadOrders(forceReload: true),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    // Tìm đơn hàng hiện tại để kiểm tra trạng thái
    final order = _orders.firstWhere(
      (o) => o['id'] == orderId,
      orElse: () => <String, dynamic>{},
    );

    final currentStatus = order['status'] as String?;

    // Không cho phép thay đổi trạng thái đơn hàng đã hoàn thành hoặc đã hoàn tiền
    if (currentStatus == 'delivered' || currentStatus == 'refunded') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus == 'delivered'
                  ? '❌ Đơn hàng đã hoàn thành, không thể thay đổi trạng thái!'
                  : '❌ Đơn hàng đã hoàn tiền, không thể thay đổi trạng thái!',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Không cho phép hủy đơn hàng đã hoàn thành hoặc đã hoàn tiền (double check)
    if (newStatus == 'cancelled' &&
        (currentStatus == 'delivered' || currentStatus == 'refunded')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '❌ Không thể hủy đơn hàng đã hoàn thành hoặc đã hoàn tiền!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    print(
        '📝 Admin: Updating order #$orderId from $currentStatus to: $newStatus');

    final success = await ApiService.updateOrderStatus(
      orderId: orderId,
      status: newStatus,
    );

    if (success) {
      print('✅ Admin: Order #$orderId updated successfully to: $newStatus');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cập nhật đơn hàng #$orderId thành $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders(forceReload: true); // Reload orders list
      }
    } else {
      print('❌ Admin: Failed to update order #$orderId to: $newStatus');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Cập nhật thất bại. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewOrderDetails(Map<String, dynamic> order) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          orderId: order['id'],
          orderNumber: order['order_number'],
        ),
      ),
    )
        .then((_) {
      // Reload orders when returning from detail screen
      _loadOrders(forceReload: true);
    });
  }

  Future<void> _viewOrderHistory(Map<String, dynamic> order) async {
    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final historyData =
          await ApiService.getOrderHistory(orderId: order['id']);

      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng loading

      if (historyData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải lịch sử đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Hiển thị dialog với lịch sử
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => _OrderHistoryDialog(
          orderNumber: order['order_number'],
          history: historyData['history'] as List<dynamic>,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true; // Giữ state khi chuyển tab

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Column(
      children: [
        // Filter
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Lọc theo trạng thái',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(
                        value: 'pending', child: Text('Chờ xử lý')),
                    DropdownMenuItem(
                        value: 'processing', child: Text('Đang xử lý')),
                    DropdownMenuItem(
                        value: 'shipped', child: Text('Đang giao')),
                    DropdownMenuItem(
                        value: 'delivered', child: Text('Hoàn thành')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _loadOrders(forceReload: true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadOrders(forceReload: true),
                tooltip: 'Làm mới',
              ),
            ],
          ),
        ),

        // Orders List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Không có đơn hàng',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadOrders(forceReload: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderItem(order);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final date = DateTime.parse(order['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order['status']),
          child: const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
        ),
        title: Text(
          order['order_number'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${order['user_name']} • ${formatter.format(date)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(order['total_amount'] / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            Text(
              order['payment_status'],
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(order['user_email']),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('${order['items_count']} sản phẩm'),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Cập nhật trạng thái:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Nếu đơn đã hoàn thành hoặc đã hoàn tiền thì không cho phép thay đổi trạng thái
                if (order['status'] == 'delivered' ||
                    order['status'] == 'refunded')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order['status'] == 'delivered'
                                ? 'Đơn hàng đã hoàn thành, không thể thay đổi trạng thái'
                                : 'Đơn hàng đã hoàn tiền, không thể thay đổi trạng thái',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusButton('processing', 'Xử lý', Colors.blue,
                          order['id'], order['status']),
                      _buildStatusButton('shipped', 'Đã giao', Colors.purple,
                          order['id'], order['status']),
                      _buildStatusButton('delivered', 'Hoàn thành',
                          Colors.green, order['id'], order['status']),
                      // Chỉ hiển thị nút Hủy nếu đơn chưa hoàn thành hoặc chưa hoàn tiền
                      if (order['status'] != 'delivered' &&
                          order['status'] != 'refunded')
                        _buildStatusButton('cancelled', 'Hủy', Colors.red,
                            order['id'], order['status']),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewOrderDetails(order),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Xem chi tiết'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // Chỉ hiển thị nút "Xem lịch sử" cho admin
                    if (Provider.of<AuthProvider>(context, listen: false)
                            .currentUser
                            ?.isAdmin ==
                        true) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewOrderHistory(order),
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('Lịch sử'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status, String label, Color color,
      int orderId, String currentStatus) {
    // Không cho phép thay đổi trạng thái đơn đã hoàn thành hoặc đã hoàn tiền
    final bool isDisabled =
        (currentStatus == 'delivered' || currentStatus == 'refunded');

    return ElevatedButton(
      onPressed: isDisabled ? null : () => _updateOrderStatus(orderId, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ===== ORDER HISTORY DIALOG =====
class _OrderHistoryDialog extends StatelessWidget {
  final String orderNumber;
  final List<dynamic> history;

  const _OrderHistoryDialog({
    required this.orderNumber,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lịch sử đơn hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Đơn #$orderNumber',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // History List
            Flexible(
              child: history.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có lịch sử thay đổi',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final record = history[index];
                        final createdBy =
                            record['created_by'] as Map<String, dynamic>?;
                        final createdAt = record['created_at'] != null
                            ? DateTime.parse(record['created_at'])
                            : null;
                        final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColorForHistory(
                                          record['status']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusLabel(record['status']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (createdAt != null)
                                    Text(
                                      formatter.format(createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                              if (record['notes'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  record['notes'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                              if (createdBy != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${createdBy['first_name'] ?? ''} ${createdBy['last_name'] ?? ''} (${createdBy['username'] ?? 'Unknown'})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: createdBy['role'] == 'admin'
                                            ? Colors.orange.shade100
                                            : Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        createdBy['role'] == 'admin'
                                            ? 'ADMIN'
                                            : 'STAFF',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: createdBy['role'] == 'admin'
                                              ? Colors.orange.shade900
                                              : Colors.blue.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColorForHistory(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

// ===== PRODUCTS TAB =====
class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool? _selectedActiveFilter; // null = all, true = active, false = inactive

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final products =
        await ApiService.getAdminBooks(isActive: _selectedActiveFilter);

    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _addProduct() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminProductFormScreen(),
      ),
    );

    if (result == true) {
      _loadProducts(); // Reload if product was added
    }
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    // Load full product details before editing
    setState(() => _isLoading = true);

    try {
      // Get full product details from API
      final fullProduct = await ApiService.getBook(product['id']);

      if (fullProduct == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải thông tin sản phẩm'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Navigate to edit form with full product data
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AdminProductFormScreen(product: fullProduct),
        ),
      );

      if (result == true) {
        _loadProducts(); // Reload if product was updated
      }
    } catch (e) {
      print('Error loading product details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStock(int bookId, int currentStock, String title) async {
    final controller = TextEditingController(text: currentStock.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật tồn kho\n$title',
            style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Số lượng mới',
            border: OutlineInputBorder(),
            suffixText: 'cuốn',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await ApiService.updateBook(
        bookId: bookId,
        stockQuantity: result,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProducts();
      }
    }
  }

  Future<void> _toggleProductStatus(
      int bookId, bool currentStatus, String title) async {
    print(
        '🔄 Toggling product #$bookId from $currentStatus to ${!currentStatus}');

    final success = await ApiService.updateBook(
      bookId: bookId,
      isActive: !currentStatus,
    );

    if (success) {
      print('✅ Product #$bookId toggle successful');

      // Update local state immediately for instant feedback
      setState(() {
        final productIndex = _products.indexWhere((p) => p['id'] == bookId);
        if (productIndex != -1) {
          _products[productIndex]['is_active'] = !currentStatus;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus ? '✅ Đã bật bán: $title' : '⏸️ Đã tắt bán: $title',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('❌ Product #$bookId toggle failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Cập nhật thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewBookHistory(Map<String, dynamic> product) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final historyData =
          await ApiService.getBookHistory(bookId: product['id']);
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        if (historyData == null || historyData['history'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải lịch sử'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final history = historyData['history'] as List;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('📜 Lịch sử sản phẩm: ${product['title']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: history.isEmpty
                  ? const Text('Không có lịch sử thay đổi cho sản phẩm này.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        final creator = entry['created_by'];
                        final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
                        final dateTime = DateTime.parse(entry['created_at']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry['field_label'] ??
                                            entry['field_name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatter.format(dateTime),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (entry['old_value'] != null ||
                                    entry['new_value'] != null)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (entry['old_value'] != null) ...[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Giá trị cũ:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              Text(
                                                entry['old_value'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red.shade700,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (entry['new_value'] != null)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Giá trị mới:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              Text(
                                                entry['new_value'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                if (entry['notes'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    entry['notes'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                                if (creator != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.person,
                                          size: 14,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${creator['first_name']} ${creator['last_name']} (${creator['username']})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: creator['role'] == 'admin'
                                              ? Colors.orange.shade700
                                              : Colors.blue.shade700,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          creator['role'].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tải lịch sử sản phẩm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter & Add Button
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  value: _selectedActiveFilter,
                  decoration: const InputDecoration(
                    labelText: 'Lọc sản phẩm',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('📚 Tất cả')),
                    DropdownMenuItem(value: true, child: Text('✅ Đang bán')),
                    DropdownMenuItem(value: false, child: Text('❌ Ngừng bán')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedActiveFilter = value);
                    _loadProducts();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadProducts,
                tooltip: 'Làm mới',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addProduct,
                tooltip: 'Thêm sản phẩm',
                color: Colors.orange,
              ),
            ],
          ),
        ),

        // Products List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Không có sản phẩm',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final stockStatus = product['stock_quantity'] > 10
                              ? 'Còn hàng'
                              : product['stock_quantity'] > 0
                                  ? 'Sắp hết'
                                  : 'Hết hàng';
                          final stockColor = product['stock_quantity'] > 10
                              ? Colors.green
                              : product['stock_quantity'] > 0
                                  ? Colors.orange
                                  : Colors.red;
                          final isActive = product['is_active'] ?? true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              onTap: () => _editProduct(product),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isActive
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade300,
                                child: Text(
                                  '#${product['id']}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isActive ? Colors.blue : Colors.grey),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      product['title'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          isActive ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isActive ? 'Đang bán' : 'Ngừng bán',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money,
                                          size: 14, color: Colors.grey),
                                      Text(
                                        '${(product['price'] / 1000).toStringAsFixed(0)}k',
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.inventory_2,
                                          size: 14, color: stockColor),
                                      Flexible(
                                        child: Text(
                                          '${product['stock_quantity']} ($stockStatus)',
                                          style: TextStyle(
                                              color: stockColor,
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.sell,
                                          size: 14, color: Colors.grey),
                                      Text(
                                          'Đã bán: ${product['sold_quantity']}'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Chỉ hiển thị nút "Lịch sử" cho admin
                                  if (Provider.of<AuthProvider>(context,
                                              listen: false)
                                          .currentUser
                                          ?.isAdmin ==
                                      true)
                                    IconButton(
                                      icon: const Icon(Icons.history, size: 20),
                                      color: Colors.orange,
                                      tooltip: 'Lịch sử thay đổi',
                                      onPressed: () =>
                                          _viewBookHistory(product),
                                    ),
                                  Switch(
                                    value: isActive,
                                    activeColor: Colors.green,
                                    onChanged: (value) {
                                      _toggleProductStatus(
                                        product['id'],
                                        isActive,
                                        product['title'],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ===== USERS TAB =====
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final users = await ApiService.getAdminUsers();

    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(
      int userId, bool currentStatus, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? 'Vô hiệu hóa user' : 'Kích hoạt user'),
        content: Text(
          currentStatus
              ? 'Bạn có chắc muốn vô hiệu hóa $userName?'
              : 'Bạn có chắc muốn kích hoạt $userName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.red : Colors.green,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.updateUserStatus(
        userId: userId,
        isActive: !currentStatus,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    }
  }

  Future<void> _toggleStaffRole(
      int userId, bool currentIsStaff, String userName, int userIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentIsStaff ? 'Hủy quyền Staff' : 'Cấp quyền Staff'),
        content: Text(
          currentIsStaff
              ? 'Bạn có chắc muốn hủy quyền Staff của $userName?\nUser sẽ trở thành khách hàng thông thường.'
              : 'Bạn có chắc muốn cấp quyền Staff cho $userName?\nUser sẽ có thể truy cập Admin Panel (trừ Dashboard).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentIsStaff ? Colors.orange : Colors.blue,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.toggleStaffRole(
        userId: userId,
        isStaff: !currentIsStaff,
      );

      if (success && mounted) {
        // Cập nhật UI ngay lập tức
        setState(() {
          _users[userIndex]['role'] = currentIsStaff ? 'customer' : 'staff';
          _users[userIndex]['role_id'] = currentIsStaff ? 3 : 2;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentIsStaff
                  ? '✅ Đã hủy quyền Staff của $userName'
                  : '✅ Đã cấp quyền Staff cho $userName',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final formatter = DateFormat('dd/MM/yyyy');
          final createdAt = DateTime.parse(user['created_at']);
          final isAdmin = user['role'] == 'admin';
          final isStaff = user['role'] == 'staff';
          final roleId = user['role_id'] ?? 3;

          // Get current user to check if they're admin
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final currentUserIsAdmin = authProvider.currentUser?.isAdmin ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: user['is_active']
                    ? (isAdmin
                        ? Colors.orange
                        : isStaff
                            ? Colors.blue
                            : Colors.green)
                    : Colors.red,
                child: Text(
                  (user['username'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${user['first_name']} ${user['last_name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  if (isStaff)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'STAFF',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user['email'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Tham gia: ${formatter.format(createdAt)}'),
                    ],
                  ),
                  // Staff toggle for admin only
                  if (currentUserIsAdmin && !isAdmin) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings,
                            size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text('Quyền Staff:',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Switch(
                          value: isStaff,
                          activeColor: Colors.blue,
                          onChanged: (value) => _toggleStaffRole(
                            user['id'],
                            isStaff,
                            '${user['first_name']} ${user['last_name']}',
                            index,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: Switch(
                value: user['is_active'],
                activeColor: Colors.green,
                // Admin không thể bị vô hiệu hóa
                // Staff không thể vô hiệu hóa admin hoặc staff khác
                onChanged:
                    (isAdmin || (!currentUserIsAdmin && (isAdmin || isStaff)))
                        ? null
                        : (value) => _toggleUserStatus(
                              user['id'],
                              user['is_active'],
                              '${user['first_name']} ${user['last_name']}',
                            ),
              ),
            ),
          );
        },
      ),
    );
  }
}
