import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_new.dart';
import '../services/api_service.dart';
import 'order_detail_screen.dart';
import 'order_review_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<int, bool> _reviewedOrders = {}; // Track which orders have been reviewed
  Map<int, Map<String, dynamic>> _orderDetailsCache = {}; // Cache order details

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser?.id != null) {
        print('📦 Loading orders for user ${authProvider.currentUser!.id}...');
        final orders = await ApiService.getUserOrders(
            userId: authProvider.currentUser!.id!);
        print('✅ Loaded ${orders.length} orders');

        // Collect all delivered order IDs for batch checking
        final deliveredOrderIds = orders
            .where((order) =>
                order['status']?.toString().toLowerCase() == 'delivered')
            .map((order) => order['id'] as int)
            .toList();

        // Batch check review status for all delivered orders at once
        if (deliveredOrderIds.isNotEmpty) {
          print(
              '⭐ Batch checking review status for ${deliveredOrderIds.length} orders...');
          _reviewedOrders = await ApiService.hasReviewedOrders(
            orderIds: deliveredOrderIds,
            userId: authProvider.currentUser!.id!,
          );
          print('✅ Review status checked for ${_reviewedOrders.length} orders');
        }

        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('User not logged in');
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải lịch sử đơn hàng: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getProcessingOrders() {
    return _orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';
      return status == 'pending' ||
          status == 'processing' ||
          status == 'shipped';
    }).toList();
  }

  List<dynamic> _getCompletedOrders() {
    return _orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';
      return status == 'delivered' || status == 'cancelled';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(_getProcessingOrders()),
                      _buildOrderList(_getCompletedOrders()),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(color: Colors.grey.shade600),
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
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'];
    final orderNumber = order['order_number'] ?? 'N/A';
    final status = order['status'] ?? 'pending';
    final totalAmount = order['total_amount'] ?? 0.0;
    final paymentStatus = order['payment_status'] ?? 'pending';
    final createdAt = order['created_at'];
    final itemsCount = order['items_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itemsCount sản phẩm',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Ngày đặt: ${_formatDate(createdAt)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Tổng tiền: ${(totalAmount / 1000).toStringAsFixed(0)}k VNĐ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payment, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Trạng thái: ${_getPaymentStatusText(paymentStatus)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // View Detail Button and Review Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailScreen(
                          orderId: orderId,
                          orderNumber: orderNumber,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem thêm',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
                // Show Review button only for delivered orders that haven't been reviewed
                if (status.toLowerCase() == 'delivered' &&
                    !(_reviewedOrders[orderId] ?? false)) ...[
                  const SizedBox(width: 24),
                  InkWell(
                    onTap: () => _showReviewDialog(order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Đánh giá',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
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

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ thanh toán';
      case 'paid':
        return 'Đã thanh toán';
      case 'failed':
        return 'Thất bại';
      default:
        return status;
    }
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

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'N/A';

    try {
      final date = DateTime.parse(dateTime);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _showReviewDialog(Map<String, dynamic> order) async {
    final orderId = order['id'];
    final orderNumber = order['order_number'] ?? 'N/A';

    try {
      Map<String, dynamic>? orderDetails;

      // Check cache first
      if (_orderDetailsCache.containsKey(orderId)) {
        print('✅ Using cached order details for order #$orderId');
        orderDetails = _orderDetailsCache[orderId];
      } else {
        // Show loading dialog only if not cached
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Fetch order details to get products list
        print('📥 Fetching order details for order #$orderId...');
        orderDetails = await ApiService.getOrderDetail(orderId: orderId);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
        }

        // Cache the result
        if (orderDetails != null) {
          _orderDetailsCache[orderId] = orderDetails;
        }
      }

      if (mounted) {
        if (orderDetails == null || orderDetails['items'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải thông tin đơn hàng'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final items = orderDetails['items'] as List<dynamic>;

        // Prepare products list for review screen
        final products = items.map((item) {
          final book = item['book'];
          String? bookImage;

          // Get first image if available
          if (book != null && book['images'] != null) {
            final images = book['images'] as List<dynamic>;
            if (images.isNotEmpty) {
              bookImage = images[0]['image_url'];
            }
          }

          return {
            'book_id': item['book_id'],
            'book_title': book?['title'] ?? 'N/A',
            'book_image': bookImage,
            'quantity': item['quantity'],
          };
        }).toList();

        // Navigate to review screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderReviewScreen(
              orderId: orderId,
              orderNumber: orderNumber,
              products: products,
            ),
          ),
        );

        // Reload orders if reviews were submitted
        if (result == true) {
          // Clear cache for this order when review is submitted
          _orderDetailsCache.remove(orderId);
          _loadData();
        }
      }
    } catch (e) {
      print('❌ Error loading order for review: $e');
      if (mounted) {
        // Try to pop loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
