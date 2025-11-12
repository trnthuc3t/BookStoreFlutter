import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_new.dart';
import '../providers/cart_provider_new.dart';
import '../services/api_service.dart';
import '../services/zalopay_service.dart';
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
            ...widget.cartItems.map((item) {
              // Map API fields safely
              final title = item['book_title'] as String? ?? 'Sản phẩm';
              final priceValue = item['book_price'];
              final price =
                  priceValue != null ? (priceValue as num).toDouble() : 0.0;

              final originalPriceValue = item['book_original_price'];
              final originalPrice = originalPriceValue != null
                  ? (originalPriceValue as num).toDouble()
                  : price;

              final discountValue = item['discount_percentage'];
              final discountPercentage = discountValue != null
                  ? (discountValue as num).toDouble()
                  : 0.0;

              final quantityValue = item['quantity'];
              final quantity =
                  quantityValue != null ? (quantityValue as num).toInt() : 1;

              final hasDiscount =
                  discountPercentage > 0 && originalPrice > price;
              final totalPrice = price * quantity;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title x$quantity',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (hasDiscount)
                            Text(
                              '${(price / 1000).toStringAsFixed(0)}k (giảm ${discountPercentage.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasDiscount)
                          Text(
                            '${(originalPrice * quantity / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          '${(totalPrice / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasDiscount
                                ? Colors.red.shade700
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
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
    // Calculate subtotal safely from API data
    final subtotal = widget.cartItems.fold<int>(
      0,
      (sum, item) {
        final priceValue = item['book_price'];
        final price = priceValue != null ? (priceValue as num).toDouble() : 0.0;
        final quantityValue = item['quantity'];
        final quantity =
            quantityValue != null ? (quantityValue as num).toInt() : 1;
        return sum + (price * quantity).toInt();
      },
    );
    final total =
        subtotal - (widget.voucherDiscount * 1000); // Convert k to actual value

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính:'),
                Text('${(subtotal / 1000).toStringAsFixed(0)}k'),
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
                  '${(total / 1000).toStringAsFixed(0)}k',
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
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartApiProvider>(context, listen: false);

      if (authProvider.currentUser?.email == null ||
          authProvider.currentUser?.id == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final userId = authProvider.currentUser!.id!;

      print('💳 Processing payment...');
      print('👤 User ID: $userId');
      print('📦 Cart items: ${widget.cartItems.length}');
      print('💰 Payment method: ${widget.paymentMethod}');

      // Calculate total amount safely from API data
      final totalAmount = widget.cartItems.fold<int>(
            0,
            (sum, item) {
              final priceValue = item['book_price'];
              final price =
                  priceValue != null ? (priceValue as num).toDouble() : 0.0;
              final quantityValue = item['quantity'];
              final quantity =
                  quantityValue != null ? (quantityValue as num).toInt() : 1;
              return sum + (price * quantity).toInt();
            },
          ) -
          (widget.voucherDiscount * 1000); // Convert k to actual value

      print('💰 Total amount: $totalAmount VND');

      // Check if payment method is ZaloPay
      final isZaloPay = widget.paymentMethod.toLowerCase().contains('zalopay');

      if (isZaloPay) {
        // Handle ZaloPay payment
        await _processZaloPayPayment(totalAmount, userId, cartProvider);
      } else {
        // Handle COD and other payment methods
        await _processCODPayment(totalAmount, userId, cartProvider);
      }
    } catch (e, stackTrace) {
      print('❌ Payment error: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi thanh toán: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processCODPayment(
    int totalAmount,
    int userId,
    CartApiProvider cartProvider,
  ) async {
    print('📝 Creating COD order via API...');

    final orderData = await ApiService.createSimpleOrder(
      userId: userId,
      paymentMethod: widget.paymentMethod,
      notes: widget.address,
      voucherCode: widget.voucher,
    );

    if (orderData != null) {
      print('✅ Order created successfully!');
      print('📦 Order number: ${orderData['order_number']}');
      print('🆔 Order ID: ${orderData['id']}');

      await cartProvider.loadCartItems(userId, forceRefresh: true);
      print('✅ Cart refreshed');

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            orderId: orderData['id'],
            totalAmount: totalAmount,
            paymentMethod: widget.paymentMethod,
            orderDate: DateTime.parse(orderData['created_at']),
          ),
        ),
      );
    } else {
      throw Exception('Không thể tạo đơn hàng. Vui lòng thử lại.');
    }
  }

  Future<void> _processZaloPayPayment(
    int totalAmount,
    int userId,
    CartApiProvider cartProvider,
  ) async {
    print('💳 Processing ZaloPay payment...');

    // Step 1: Check if ZaloPay is installed
    final isInstalled = await ZaloPayService.instance.isZaloPayInstalled();
    if (!isInstalled) {
      if (!mounted) return;

      // Show dialog to install ZaloPay
      final shouldInstall = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ZaloPay chưa được cài đặt'),
          content: const Text(
            'Bạn cần cài đặt ứng dụng ZaloPay để thanh toán.\n\n'
            'Bạn có muốn chuyển sang thanh toán COD không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Thanh toán COD'),
            ),
          ],
        ),
      );

      if (shouldInstall == true) {
        // Switch to COD
        await _processCODPayment(totalAmount, userId, cartProvider);
      }
      return;
    }

    // Step 2: Create order in backend first
    print('📝 Creating order in backend...');
    final orderData = await ApiService.createSimpleOrder(
      userId: userId,
      paymentMethod: widget.paymentMethod,
      notes: widget.address,
      voucherCode: widget.voucher,
    );

    if (orderData == null) {
      throw Exception('Không thể tạo đơn hàng. Vui lòng thử lại.');
    }

    final orderId = orderData['id'].toString();
    print('✅ Order created with ID: $orderId');

    // Step 3: Create ZaloPay order
    print('💳 Creating ZaloPay order...');
    final zaloPayOrderResult = await ZaloPayService.instance.createOrder(
      totalAmount,
      description: 'Thanh toán đơn hàng BookStore #$orderId',
      orderId: orderId,
    );

    if (zaloPayOrderResult['return_code'] != 1) {
      throw Exception(
          'Không thể tạo đơn ZaloPay: ${zaloPayOrderResult['return_message']}');
    }

    print('✅ ZaloPay order created');

    // Step 4: Launch ZaloPay app with zpTransToken
    final zpTransToken = zaloPayOrderResult['zptranstoken'] as String?;
    if (zpTransToken != null && zpTransToken.isNotEmpty) {
      print('🚀 Launching ZaloPay app with token: $zpTransToken');
      final paymentResult =
          await ZaloPayService.instance.launchZaloPay(zpTransToken);

      if (paymentResult != null) {
        print('✅ ZaloPay payment result: $paymentResult');

        final paymentStatus = paymentResult['status'] as String?;

        if (paymentStatus == 'success') {
          // Payment successful
          print('✅ Payment successful!');

          // Clear cart
          await cartProvider.loadCartItems(userId, forceRefresh: true);

          if (!mounted) return;

          // Navigate to success screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                orderId: orderData['id'],
                totalAmount: totalAmount,
                paymentMethod: widget.paymentMethod,
                orderDate: DateTime.parse(orderData['created_at']),
              ),
            ),
          );
        } else if (paymentStatus == 'canceled') {
          // Payment canceled
          print('❌ Payment canceled by user');

          if (!mounted) return;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Thanh toán bị hủy'),
              content: const Text(
                  'Bạn đã hủy thanh toán. Đơn hàng vẫn được lưu và bạn có thể thanh toán sau.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Back to previous screen
                  },
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        } else {
          // Payment error
          throw Exception('Lỗi thanh toán ZaloPay');
        }
      } else {
        throw Exception('Không thể mở ZaloPay. Vui lòng thử lại.');
      }
    } else {
      throw Exception('Không nhận được token thanh toán từ ZaloPay');
    }
  }
}
