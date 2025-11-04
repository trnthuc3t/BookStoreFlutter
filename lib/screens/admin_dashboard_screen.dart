import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../providers/auth_provider_new.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getAdminDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Đơn hàng'),
            Tab(icon: Icon(Icons.inventory), text: 'Sản phẩm'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pop(); // Return to main screen
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          const AdminOrdersTab(),
          const AdminProductsTab(),
          const AdminUsersTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dashboardData == null) {
      return const Center(child: Text('Không thể tải dữ liệu'));
    }

    final stats = _dashboardData!['stats'] as Map<String, dynamic>;
    final recentOrders = _dashboardData!['recent_orders'] as List<dynamic>;
    final topBooks = _dashboardData!['top_books'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
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
                '${(stats['total_revenue'] / 1000).toStringAsFixed(0)}k',
                Icons.attach_money,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final date = DateTime.parse(order['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.receipt),
        ),
        title: Text(order['order_number']),
        subtitle: Text('${order['user_name']}\n${formatter.format(date)}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(order['total_amount'] / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(order['status']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order['status'],
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
        leading: const CircleAvatar(
          child: Icon(Icons.book),
        ),
        title: Text(book['title']),
        subtitle: Text('Đã bán: ${book['sold_quantity']}'),
        trailing: Text(
          '${(book['price'] / 1000).toStringAsFixed(0)}k',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

// ===== ORDERS TAB =====
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    final orders = await ApiService.getAdminOrders(status: _selectedStatus);

    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    final success = await ApiService.updateOrderStatus(
      orderId: orderId,
      status: newStatus,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công')),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter
        Padding(
          padding: const EdgeInsets.all(8),
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Lọc theo trạng thái',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý')),
              DropdownMenuItem(value: 'processing', child: Text('Đang xử lý')),
              DropdownMenuItem(value: 'shipped', child: Text('Đã giao')),
              DropdownMenuItem(value: 'delivered', child: Text('Hoàn thành')),
              DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value);
              _loadOrders();
            },
          ),
        ),

        // Orders List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.shopping_bag),
        title: Text(order['order_number']),
        subtitle: Text('${order['user_name']} - ${formatter.format(date)}'),
        trailing: Text(
          '${(order['total_amount'] / 1000).toStringAsFixed(0)}k',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${order['user_email']}'),
                const SizedBox(height: 8),
                Text('Số sản phẩm: ${order['items_count']}'),
                const SizedBox(height: 8),
                Text('Trạng thái thanh toán: ${order['payment_status']}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _updateOrderStatus(order['id'], 'processing'),
                      child: const Text('Xử lý'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _updateOrderStatus(order['id'], 'shipped'),
                      child: const Text('Đã giao'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _updateOrderStatus(order['id'], 'delivered'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('Hoàn thành'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _updateOrderStatus(order['id'], 'cancelled'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Hủy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final products = await ApiService.getAdminBooks();

    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStock(int bookId, int currentStock) async {
    final controller = TextEditingController(text: currentStock.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật số lượng'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số lượng mới',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
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

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công')),
        );
        _loadProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(product['id'].toString()),
              ),
              title: Text(product['title']),
              subtitle: Text(
                'Giá: ${(product['price'] / 1000).toStringAsFixed(0)}k\n'
                'Tồn kho: ${product['stock_quantity']} | Đã bán: ${product['sold_quantity']}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _updateStock(
                  product['id'],
                  product['stock_quantity'],
                ),
              ),
            ),
          );
        },
      ),
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

  Future<void> _toggleUserStatus(int userId, bool currentStatus) async {
    final success = await ApiService.updateUserStatus(
      userId: userId,
      isActive: !currentStatus,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công')),
      );
      _loadUsers();
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
        padding: const EdgeInsets.all(8),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final formatter = DateFormat('dd/MM/yyyy');
          final createdAt = DateTime.parse(user['created_at']);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user['is_active'] ? Colors.green : Colors.red,
                child: Text(user['username'][0].toUpperCase()),
              ),
              title: Text('${user['first_name']} ${user['last_name']}'),
              subtitle: Text(
                '${user['email']}\n'
                'Role: ${user['role']} | Tham gia: ${formatter.format(createdAt)}',
              ),
              isThreeLine: true,
              trailing: Switch(
                value: user['is_active'],
                onChanged: (value) =>
                    _toggleUserStatus(user['id'], user['is_active']),
              ),
            ),
          );
        },
      ),
    );
  }
}
