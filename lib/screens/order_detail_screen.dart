import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _orderDetail;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await ApiService.getOrderDetail(orderId: widget.orderId);

      if (mounted) {
        setState(() {
          _orderDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải chi tiết đơn hàng: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng ${widget.orderNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetail,
            tooltip: 'Làm mới',
          ),
        ],
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
                        onPressed: _loadOrderDetail,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _orderDetail == null
                  ? const Center(child: Text('Không tìm thấy đơn hàng'))
                  : RefreshIndicator(
                      onRefresh: _loadOrderDetail,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Status Card
                            _buildOrderStatusCard(),
                            const SizedBox(height: 16),

                            // Order Items
                            _buildOrderItemsSection(),
                            const SizedBox(height: 16),

                            // Order Summary
                            _buildOrderSummaryCard(),
                            const SizedBox(height: 16),

                            // Shipping Information
                            if (_orderDetail!['shipping_address'] != null)
                              _buildShippingInfoCard(),
                            const SizedBox(height: 16),

                            // Cancel Order Button (if order can be cancelled)
                            if (_canCancelOrder()) _buildCancelOrderButton(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  bool _canCancelOrder() {
    if (_orderDetail == null) return false;
    final status = _orderDetail!['status']?.toString().toLowerCase() ?? '';
    return status == 'pending' ||
        status == 'confirmed' ||
        status == 'processing';
  }

  Widget _buildCancelOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showCancelOrderDialog(),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Hủy đơn hàng'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelOrderDialog() async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn hủy đơn hàng này?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (tùy chọn)',
                hintText: 'Nhập lý do hủy đơn hàng...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelOrder(reasonController.text.trim());
    }
  }

  Future<void> _cancelOrder(String reason) async {
    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await ApiService.cancelOrder(
        orderId: widget.orderId,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đơn hàng đã được hủy thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload order detail
        await _loadOrderDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể hủy đơn hàng. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrderStatusCard() {
    final status = _orderDetail!['status'] ?? 'pending';
    final paymentStatus = _orderDetail!['payment_status'] ?? 'pending';
    final createdAt = _orderDetail!['created_at'];

    return Card(
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
                const Text(
                  'Trạng thái đơn hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
            _buildInfoRow('Mã đơn hàng', widget.orderNumber),
            _buildInfoRow('Ngày đặt', _formatDate(createdAt)),
            _buildInfoRow('Thanh toán', _getPaymentStatusText(paymentStatus)),
            if (_orderDetail!['notes'] != null &&
                _orderDetail!['notes'].toString().isNotEmpty)
              _buildInfoRow('Ghi chú', _orderDetail!['notes']),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    final items = _orderDetail!['items'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Không có sản phẩm nào'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildOrderItem(item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 1;
    final unitPrice = item['unit_price'] ?? 0.0;
    final discountAmount = item['discount_amount'] ?? 0.0;
    final totalPrice = item['total_price'] ?? 0.0;
    final book = item['book'] as Map<String, dynamic>?;

    final bookTitle = book?['title'] ?? 'Sản phẩm';
    final bookImages = book?['images'] as List<dynamic>? ?? [];
    final imageUrl = bookImages.isNotEmpty ? bookImages[0]['image_url'] : null;

    // Calculate original price (before discount)
    final originalUnitPrice = unitPrice + (discountAmount / quantity);
    final hasDiscount = discountAmount > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(
                  '${ApiConstants.baseUrl}$imageUrl',
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, color: Colors.grey),
                    );
                  },
                )
              : Container(
                  width: 60,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
        ),
        const SizedBox(width: 12),

        // Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Quantity
              Text(
                'x$quantity',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              // Price
              Row(
                children: [
                  // Original price (if has discount)
                  if (hasDiscount) ...[
                    Text(
                      '${(originalUnitPrice / 1000).toStringAsFixed(0)}k',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Current price
                  Text(
                    '${(unitPrice / 1000).toStringAsFixed(0)}k VNĐ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Show discount amount if exists
              if (hasDiscount) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Giảm ${(discountAmount / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Total Price for this item
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Tổng',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(totalPrice / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard() {
    final subtotal = _orderDetail!['subtotal'] ?? 0.0;
    final discountAmount = _orderDetail!['discount_amount'] ?? 0.0;
    final shippingFee = _orderDetail!['shipping_fee'] ?? 0.0;
    final totalAmount = _orderDetail!['total_amount'] ?? 0.0;
    final voucher = _orderDetail!['voucher'] as Map<String, dynamic>?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng kết đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Tạm tính',
              '${(subtotal / 1000).toStringAsFixed(0)}k VNĐ',
              false,
            ),
            // Hiển thị voucher nếu có
            if (voucher != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.discount,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã giảm giá: ${voucher['code']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                          if (voucher['description'] != null)
                            Text(
                              voucher['description'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (discountAmount > 0)
              _buildSummaryRow(
                'Giảm giá',
                '-${(discountAmount / 1000).toStringAsFixed(0)}k VNĐ',
                false,
                color: Colors.red,
              ),
            _buildSummaryRow(
              'Phí vận chuyển',
              shippingFee > 0
                  ? '${(shippingFee / 1000).toStringAsFixed(0)}k VNĐ'
                  : 'Miễn phí',
              false,
              color: shippingFee > 0 ? null : Colors.green,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Tổng cộng',
              '${(totalAmount / 1000).toStringAsFixed(0)}k VNĐ',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    final address = _orderDetail!['shipping_address'] as Map<String, dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ giao hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Người nhận', address['recipient_name'] ?? 'N/A'),
            _buildInfoRow('Số điện thoại', address['phone'] ?? 'N/A'),
            _buildInfoRow(
              'Địa chỉ',
              _buildFullAddress(address),
            ),
          ],
        ),
      ),
    );
  }

  String _buildFullAddress(Map<String, dynamic> address) {
    final parts = <String>[];

    if (address['address_line1'] != null) parts.add(address['address_line1']);
    if (address['address_line2'] != null &&
        address['address_line2'].toString().isNotEmpty) {
      parts.add(address['address_line2']);
    }
    if (address['ward'] != null) parts.add(address['ward']);
    if (address['district'] != null) parts.add(address['district']);
    if (address['city'] != null) parts.add(address['city']);

    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isBold,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isBold ? Colors.green : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'refunded':
        return 'Đã hoàn tiền';
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
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'partially_refunded':
        return 'Hoàn một phần';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'N/A';

    try {
      final date = DateTime.parse(dateTime);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
