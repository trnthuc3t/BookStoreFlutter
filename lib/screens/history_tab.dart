import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import 'tracking_order_screen.dart';
import 'receipt_order_screen.dart';
import 'rating_review_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    if (authProvider.currentUser?.email != null) {
      await orderProvider.loadUserOrders(authProvider.currentUser!.email!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(orderProvider.errorMessage!),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(orderProvider.getProcessingOrders()),
              _buildOrderList(orderProvider.getCompletedOrders()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('Chưa có đơn hàng nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status as int),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusText,
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
            Text('Ngày đặt: ${_formatDate(order.createdAt as String?)}'),
            Text('Tổng tiền: ${order.totalAmount}k'),
            Text('Phương thức: ${order.paymentMethod}'),
            
            // products removed from Order model; show nothing for now
            
            if (order.address != null || order.userName != null || order.phone != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Địa chỉ giao hàng:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.userName != null) Text('Tên: ${order.userName}'),
                    if (order.phone != null) Text('SĐT: ${order.phone}'),
                    if (order.address != null) Text('Địa chỉ: ${order.address}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1: // New
        return Colors.blue;
      case 2: // Doing
        return Colors.orange;
      case 3: // Arrived
        return Colors.purple;
      case 4: // Complete
        return Colors.green;
      case 5: // Cancelled
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'N/A';
    
    try {
      final timestamp = int.parse(dateTime);
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateTime;
    }
  }
}
