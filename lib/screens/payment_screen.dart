import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String paymentMethod;
  final String address;
  final String? voucher;
  final int voucherDiscount;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.paymentMethod,
    required this.address,
    this.voucher,
    this.voucherDiscount = 0,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildProcessingView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary
          _buildOrderSummary(),
          const SizedBox(height: 24),

          // Payment method
          _buildPaymentMethodSection(),
          const SizedBox(height: 24),

          // Address
          _buildAddressSection(),
          const SizedBox(height: 24),

          // Voucher
          if (widget.voucher != null) _buildVoucherSection(),
          if (widget.voucher != null) const SizedBox(height: 24),

          // Total
          _buildTotalSection(),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),

          if (_errorMessage != null) const SizedBox(height: 16),

          // Payment button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Xác nhận thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Đang xử lý thanh toán...',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng đợi trong giây lát',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đơn hàng của bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.cartItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['name']} x${item['quantity']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${item['price'] * item['quantity']}k',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.payment, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.paymentMethod),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ giao hàng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.address),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voucher đã áp dụng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${widget.voucher} - Giảm ${widget.voucherDiscount}k'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final subtotal = widget.cartItems.fold<int>(
      0,
      (sum, item) => sum + ((item['price'] * item['quantity']) as int),
    );
    final total = subtotal - widget.voucherDiscount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính:'),
                Text('${subtotal}k'),
              ],
            ),
            if (widget.voucherDiscount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giảm giá:'),
                  Text(
                    '-${widget.voucherDiscount}k',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${total}k',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (authProvider.currentUser?.email != null) {
        // Calculate total amount
        final totalAmount = widget.cartItems.fold<int>(
          0,
          (sum, item) => sum + ((item['price'] * item['quantity']) as int),
        ) - widget.voucherDiscount;

        // Create order
        final order = Order(
          id: DateTime.now().millisecondsSinceEpoch,
          userEmail: authProvider.currentUser!.email!,
          createdAt: DateTime.now(),
          totalAmount: totalAmount,
          paymentMethod: widget.paymentMethod,
          status: 'processing', // Changed from 2 to 'processing'
        );

        // Save order to Firebase
        final success = await orderProvider.createOrder(order);

        if (success) {
          // Clear cart
          await cartProvider.clearCart(authProvider.currentUser!.email!);

          // Navigate to success screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PaymentSuccessScreen(orderId: order.id),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Có lỗi xảy ra khi tạo đơn hàng. Vui lòng thử lại.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi thanh toán: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
