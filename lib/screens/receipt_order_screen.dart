import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

import '../screens/tracking_order_screen.dart';

class ReceiptOrderScreen extends StatelessWidget {
  final Order order;

  const ReceiptOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Receipt Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'BOOKSELL',
                            style: AppTheme.heading1.copyWith(
                              color: AppTheme.primaryColor,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hệ thống bán sách trực tuyến',
                            style: AppTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Email: support@booksell.com',
                            style: AppTheme.bodySmall,
                          ),
                          Text(
                            'Hotline: 1900 1234',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Order Info
                    _buildReceiptRow('Mã đơn hàng', '#${order.id}'),
                    _buildReceiptRow('Ngày đặt', order.createdAt != null 
                        ? _formatDate(order.createdAt!) 
                        : 'N/A'),
                    _buildReceiptRow('Trạng thái', _getStatusText(order.status)),
                    const SizedBox(height: 16),
                    
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Customer Info
                    const Text(
                      'THÔNG TIN KHÁCH HÀNG',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Tên khách hàng', order.userName ?? 'N/A'),
                    _buildReceiptRow('Số điện thoại', order.phone ?? 'N/A'),
                    _buildReceiptRow('Địa chỉ', order.address ?? 'N/A'),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildReceiptRow('Ghi chú', order.notes!),
                    ],
                    const SizedBox(height: 16),
                    
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Payment Info
                    const Text(
                      'THÔNG TIN THANH TOÁN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Phương thức thanh toán', order.paymentMethod ?? 'N/A'),
                    _buildReceiptRow('Tổng tiền', '${order.totalAmount.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )} VNĐ'),
                    const SizedBox(height: 16),
                    
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Footer
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Cảm ơn bạn đã mua hàng!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hóa đơn này có giá trị pháp lý',
                            style: AppTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ngày in: ${_formatDate(DateTime.now())}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReceipt(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _printReceipt(context),
                    icon: const Icon(Icons.print),
                    label: const Text('In hóa đơn'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Theo dõi đơn hàng',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackingOrderScreen(order: order),
                  ),
                );
              },
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao hàng';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareReceipt(BuildContext context) {
    // Copy receipt text to clipboard
    final receiptText = _generateReceiptText();
    Clipboard.setData(ClipboardData(text: receiptText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hóa đơn đã được sao chép vào clipboard'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _printReceipt(BuildContext context) {
    // In a real app, you would implement actual printing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng in hóa đơn đang được phát triển'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  String _generateReceiptText() {
    return '''
BOOKSELL - Hệ thống bán sách trực tuyến
Email: support@booksell.com
Hotline: 1900 1234

Mã đơn hàng: #${order.id}
Ngày đặt: ${order.createdAt != null ? _formatDate(order.createdAt!) : 'N/A'}
Trạng thái: ${_getStatusText(order.status)}

THÔNG TIN KHÁCH HÀNG
Tên khách hàng: ${order.userName ?? 'N/A'}
Số điện thoại: ${order.phone ?? 'N/A'}
Địa chỉ: ${order.address ?? 'N/A'}
${order.notes != null && order.notes!.isNotEmpty ? 'Ghi chú: ${order.notes!}' : ''}

THÔNG TIN THANH TOÁN
Phương thức thanh toán: ${order.paymentMethod ?? 'N/A'}
Tổng tiền: ${order.totalAmount.toString().replaceAllMapped(
  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
  (Match m) => '${m[1]},',
)} VNĐ

Cảm ơn bạn đã mua hàng!
Hóa đơn này có giá trị pháp lý
Ngày in: ${_formatDate(DateTime.now())}
''';
  }
}
