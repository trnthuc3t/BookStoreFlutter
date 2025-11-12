import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider_new.dart';
import '../providers/auth_provider_new.dart';
import '../providers/order_provider_new.dart';
import '../widgets/cart_list_widget.dart';
import 'address_screen.dart';
import 'payment_method_screen.dart';
import 'voucher_screen.dart';
import 'payment_screen.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _selectedPaymentMethod;
  String? _selectedAddress;
  String? _selectedVoucher;
  int _voucherDiscount = 0;
  bool _isValidatingVoucher = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartApiProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.currentUser?.id != null) {
      await cartProvider.loadCartItems(authProvider.currentUser!.id!);
      await orderProvider.loadVouchers(userId: authProvider.currentUser!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          Consumer<CartApiProvider>(
            builder: (context, cartProvider, child) {
              return Row(
                children: [
                  // Refresh indicator
                  if (cartProvider.isRefreshing)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  TextButton(
                    onPressed: cartProvider.cartItems.isEmpty
                        ? null
                        : () => _clearCart(),
                    child: const Text(
                      'Xóa tất cả',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<CartApiProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading && cartProvider.cartItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.cartItems.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refreshCart(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 100, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Giỏ hàng trống',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hãy thêm sản phẩm vào giỏ hàng',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Kéo xuống để làm mới',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Cart items list with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refreshCart(),
                  child: CartListWidget(
                    cartItems: cartProvider.cartItems,
                    onQuantityChanged: (productId, quantity) {
                      _updateQuantity(productId, quantity);
                    },
                    onRemoveItem: (productId) {
                      _removeItem(productId);
                    },
                  ),
                ),
              ),

              // Order summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Payment method
                    _buildPaymentMethodSection(),
                    const SizedBox(height: 12),

                    // Address
                    _buildAddressSection(),
                    const SizedBox(height: 12),

                    // Voucher
                    _buildVoucherSection(),
                    const SizedBox(height: 16),

                    // Price summary
                    _buildPriceSummary(cartProvider),
                    const SizedBox(height: 16),

                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canCheckout() ? _checkout : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Thanh toán'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return InkWell(
      onTap: () => _selectPaymentMethod(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
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
                  Text(
                    _selectedPaymentMethod ?? 'Chọn phương thức thanh toán',
                    style: TextStyle(
                      color: _selectedPaymentMethod != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return InkWell(
      onTap: () => _selectAddress(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
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
                  Text(
                    _selectedAddress ?? 'Chọn địa chỉ giao hàng',
                    style: TextStyle(
                      color:
                          _selectedAddress != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return InkWell(
      onTap: () => _selectVoucher(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voucher',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _isValidatingVoucher
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Đang kiểm tra...',
                                style: TextStyle(color: Colors.blue)),
                          ],
                        )
                      : Text(
                          _selectedVoucher ?? 'Chọn voucher (không bắt buộc)',
                          style: TextStyle(
                            color: _selectedVoucher != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(CartApiProvider cartProvider) {
    final subtotal = cartProvider.totalPrice;
    final total = subtotal - _voucherDiscount;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tạm tính:'),
            Text('${subtotal}k'),
          ],
        ),
        if (_voucherDiscount > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giảm giá:'),
              Text('-${_voucherDiscount}k',
                  style: TextStyle(color: Colors.green)),
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
    );
  }

  bool _canCheckout() {
    return _selectedPaymentMethod != null &&
           _selectedAddress != null &&
           !_isValidatingVoucher;  // Không cho thanh toán khi đang validate voucher
  }

  Future<void> _selectPaymentMethod() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedPaymentMethod = result.toString();
      });
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddressScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAddress = result.toString();
      });
    }
  }

  Future<void> _selectVoucher() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const VoucherScreen()),
    );

    print('🎫 [DEBUG] Selected voucher result: $result');

    if (result != null && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final code = result.toString();
      print('🎫 [DEBUG] Voucher code: $code');
      print('🎫 [DEBUG] User ID: ${authProvider.currentUser?.id}');

      setState(() {
        _selectedVoucher = code;
        _isValidatingVoucher = true;
      });

      if (authProvider.currentUser?.id != null) {
        print('🎫 [DEBUG] Calling validateVoucher API...');
        final res = await ApiService.validateVoucher(userId: authProvider.currentUser!.id!, code: code);

        print('🎫 [DEBUG] API Response: $res');
        print('🎫 [DEBUG] Valid: ${res?['valid']}');
        print('🎫 [DEBUG] Discount amount: ${res?['discount_amount']}');
        print('🎫 [DEBUG] Shipping discount: ${res?['shipping_discount']}');

        if (!mounted) return;

        setState(() {
          _isValidatingVoucher = false;
        });

        if (res != null && (res['valid'] == true)) {
          print('🎫 [DEBUG] Voucher is VALID!');
          // Backend trả về discount_amount và shipping_discount theo đơn vị VND
          // Cần chuyển sang đơn vị k (1k = 1000 VND)
          final discountInVnd = ((res['discount_amount'] ?? 0) as num).toDouble();
          final shipDiscountInVnd = ((res['shipping_discount'] ?? 0) as num).toDouble();
          final totalDiscountInK = ((discountInVnd + shipDiscountInVnd) / 1000).round();

          print('🎫 [DEBUG] Discount in VND: $discountInVnd');
          print('🎫 [DEBUG] Shipping discount in VND: $shipDiscountInVnd');
          print('🎫 [DEBUG] Total discount in K: $totalDiscountInK');

          setState(() {
            _voucherDiscount = totalDiscountInK;
          });
          print('🎫 [DEBUG] Set _voucherDiscount to: $_voucherDiscount');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Áp dụng mã giảm giá thành công: -${totalDiscountInK}k'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (res != null) {
          // API trả về error với reason cụ thể
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['reason']?.toString() ?? 'Voucher không hợp lệ'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _selectedVoucher = null;
            _voucherDiscount = 0;
          });
        } else {
          // Network error hoặc API timeout
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lỗi kết nối. Vui lòng thử lại.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _selectedVoucher = null;
            _voucherDiscount = 0;
          });
        }
      } else {
        setState(() {
          _isValidatingVoucher = false;
        });
      }
    }
  }

  // Revalidate voucher khi cart thay đổi
  Future<void> _revalidateVoucher() async {
    if (_selectedVoucher == null || _selectedVoucher!.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.id == null) return;

    setState(() {
      _isValidatingVoucher = true;
    });

    final res = await ApiService.validateVoucher(
      userId: authProvider.currentUser!.id!,
      code: _selectedVoucher!
    );

    if (!mounted) return;

    setState(() {
      _isValidatingVoucher = false;
    });

    if (res != null && (res['valid'] == true)) {
      final discountInVnd = ((res['discount_amount'] ?? 0) as num).toDouble();
      final shipDiscountInVnd = ((res['shipping_discount'] ?? 0) as num).toDouble();
      final totalDiscountInK = ((discountInVnd + shipDiscountInVnd) / 1000).round();
      setState(() {
        _voucherDiscount = totalDiscountInK;
      });
    } else {
      // Voucher không còn hợp lệ (có thể do thay đổi giỏ hàng)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['reason']?.toString() ?? 'Mã giảm giá không còn hợp lệ với giỏ hàng hiện tại'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _selectedVoucher = null;
        _voucherDiscount = 0;
      });
    }
  }

  Future<void> _updateQuantity(int cartItemId, int quantity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartApiProvider>(context, listen: false);

    if (authProvider.currentUser?.id != null) {
      await cartProvider.updateQuantity(
        cartItemId,
        quantity,
        authProvider.currentUser!.id!,
      );
      // Revalidate voucher sau khi thay đổi số lượng
      await _revalidateVoucher();
    }
  }

  Future<void> _removeItem(int cartItemId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartApiProvider>(context, listen: false);

    if (authProvider.currentUser?.id != null) {
      await cartProvider.removeFromCart(
        cartItemId,
        authProvider.currentUser!.id!,
      );
      // Revalidate voucher sau khi xóa sản phẩm
      await _revalidateVoucher();
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giỏ hàng'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa tất cả sản phẩm trong giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartApiProvider>(context, listen: false);

      if (authProvider.currentUser?.id != null) {
        await cartProvider.clearCart(authProvider.currentUser!.id!);
      }
    }
  }

  Future<void> _refreshCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartApiProvider>(context, listen: false);

    if (authProvider.currentUser?.id != null) {
      // Clear cache và force refresh từ server
      await cartProvider.clearCache();
      await cartProvider.refresh(authProvider.currentUser!.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật giỏ hàng'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartApiProvider>(context, listen: false);

    if (authProvider.currentUser?.id != null) {
      // Navigate to payment screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            cartItems: cartProvider.cartItems,
            paymentMethod: _selectedPaymentMethod!,
            address: _selectedAddress!,
            voucher: _selectedVoucher,
            voucherDiscount: _voucherDiscount,
          ),
        ),
      );

      // Refresh cart after returning from payment
      if (mounted) {
        await _refreshCart();
      }
    }
  }
}
