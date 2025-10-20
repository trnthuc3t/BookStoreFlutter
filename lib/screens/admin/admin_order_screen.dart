import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Đã hoàn thành'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('processing'),
          _buildOrderList('completed'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = orderProvider.orders.where((order) {
          if (status == 'processing') {
            return order.status == 'pending' || order.status == 'processing';
          } else {
            return order.status == 'completed' || order.status == 'delivered';
          }
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có đơn hàng nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đơn hàng #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(order.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Khách hàng: ${order.userName ?? 'N/A'}'),
                    Text('Số điện thoại: ${order.phone ?? 'N/A'}'),
                    Text('Địa chỉ: ${order.address ?? 'N/A'}'),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng tiền: ${order.totalAmount.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )} VNĐ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Ngày tạo: ${_formatDate(order.createdAt)}'),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Ghi chú: ${order.notes}'),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (order.status == 'pending') ...[
                          TextButton(
                            onPressed: () => _updateOrderStatus(order, 'processing'),
                            child: const Text('Xác nhận'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (order.status == 'processing') ...[
                          TextButton(
                            onPressed: () => _updateOrderStatus(order, 'completed'),
                            child: const Text('Hoàn thành'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: () => _showOrderDetails(order),
                          child: const Text('Chi tiết'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _updateOrderStatus(Order order, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: Text('Bạn có chắc chắn muốn cập nhật trạng thái đơn hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<OrderProvider>().updateOrderStatus(order.id, newStatus);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật trạng thái thành công')),
              );
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết đơn hàng #${order.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Khách hàng: ${order.userName ?? 'N/A'}'),
              Text('Số điện thoại: ${order.phone ?? 'N/A'}'),
              Text('Địa chỉ: ${order.address ?? 'N/A'}'),
              Text('Phương thức thanh toán: ${order.paymentMethod ?? 'N/A'}'),
              Text('Tổng tiền: ${order.totalAmount.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              )} VNĐ'),
              Text('Ngày tạo: ${_formatDate(order.createdAt)}'),
              if (order.notes != null && order.notes!.isNotEmpty)
                Text('Ghi chú: ${order.notes}'),
            ],
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
}
