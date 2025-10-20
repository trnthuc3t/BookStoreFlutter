import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';

class TrackingOrderScreen extends StatefulWidget {
  final Order order;

  const TrackingOrderScreen({super.key, required this.order});

  @override
  State<TrackingOrderScreen> createState() => _TrackingOrderScreenState();
}

class _TrackingOrderScreenState extends State<TrackingOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theo dõi đơn hàng #${widget.order.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share order tracking info
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chia sẻ thông tin đơn hàng')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trạng thái đơn hàng',
                          style: AppTheme.heading3,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.order.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getStatusText(widget.order.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tổng tiền: ${widget.order.totalAmount.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )} VNĐ',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (widget.order.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ngày đặt: ${_formatDate(widget.order.createdAt!)}',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Progress
            const Text(
              'Tiến trình đơn hàng',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            
            _buildOrderProgress(),
            const SizedBox(height: 24),

            // Order Details
            const Text(
              'Chi tiết đơn hàng',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Mã đơn hàng', '#${widget.order.id}'),
                    _buildDetailRow('Khách hàng', widget.order.userName ?? 'N/A'),
                    _buildDetailRow('Số điện thoại', widget.order.phone ?? 'N/A'),
                    _buildDetailRow('Địa chỉ', widget.order.address ?? 'N/A'),
                    _buildDetailRow('Phương thức thanh toán', widget.order.paymentMethod ?? 'N/A'),
                    if (widget.order.notes != null && widget.order.notes!.isNotEmpty)
                      _buildDetailRow('Ghi chú', widget.order.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contact Support
            Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.support_agent,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cần hỗ trợ?',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nếu bạn có bất kỳ câu hỏi nào về đơn hàng, vui lòng liên hệ với chúng tôi.',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Call support
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gọi hỗ trợ')),
                              );
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Gọi điện'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Chat support
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chat hỗ trợ')),
                              );
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text('Chat'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderProgress() {
    final steps = [
      {'status': 'pending', 'title': 'Đơn hàng đã được đặt', 'description': 'Chúng tôi đã nhận được đơn hàng của bạn'},
      {'status': 'processing', 'title': 'Đang xử lý', 'description': 'Đơn hàng đang được chuẩn bị'},
      {'status': 'shipped', 'title': 'Đang giao hàng', 'description': 'Đơn hàng đang trên đường đến bạn'},
      {'status': 'completed', 'title': 'Giao hàng thành công', 'description': 'Đơn hàng đã được giao thành công'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = _isStepCompleted(step['status']!);
        final isCurrent = _isCurrentStep(step['status']!);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppTheme.primaryColor
                    : AppTheme.dividerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : isCurrent
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 16),
            
            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title']!,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted || isCurrent
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['description']!,
                    style: AppTheme.bodySmall.copyWith(
                      color: isCompleted || isCurrent
                          ? AppTheme.textPrimaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (isCurrent && widget.order.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Cập nhật lần cuối: ${_formatDate(widget.order.createdAt!)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }).toList()
        ..insert(1, const SizedBox(height: 16) as Row)
        ..insert(3, const SizedBox(height: 16) as Row)
        ..insert(5, const SizedBox(height: 16) as Row),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  bool _isStepCompleted(String stepStatus) {
    switch (widget.order.status) {
      case 'completed':
        return true;
      case 'shipped':
        return stepStatus == 'pending' || stepStatus == 'processing' || stepStatus == 'shipped';
      case 'processing':
        return stepStatus == 'pending' || stepStatus == 'processing';
      case 'pending':
        return stepStatus == 'pending';
      default:
        return false;
    }
  }

  bool _isCurrentStep(String stepStatus) {
    switch (widget.order.status) {
      case 'pending':
        return stepStatus == 'pending';
      case 'processing':
        return stepStatus == 'processing';
      case 'shipped':
        return stepStatus == 'shipped';
      case 'completed':
        return stepStatus == 'completed';
      default:
        return false;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'processing':
        return AppTheme.primaryColor;
      case 'shipped':
        return AppTheme.accentColor;
      case 'completed':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
