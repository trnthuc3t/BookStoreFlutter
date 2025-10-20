import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/cart_list_widget.dart';
import 'address_screen.dart';
import 'payment_method_screen.dart';
import 'voucher_screen.dart';
import 'payment_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.currentUser?.email != null) {
      await cartProvider.loadCartItems(authProvider.currentUser!.email!);
      await orderProvider.loadVouchers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return TextButton(
                onPressed: cartProvider.cartItems.isEmpty
                    ? null
                    : () => _clearCart(),
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.cartItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
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
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart items list
              Expanded(
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
                      color: _selectedAddress != null
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
                  Text(
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

  Widget _buildPriceSummary(CartProvider cartProvider) {
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
              Text('-${_voucherDiscount}k', style: TextStyle(color: Colors.green)),
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
    return _selectedPaymentMethod != null && _selectedAddress != null;
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

    if (result != null && mounted) {
      setState(() {
        _selectedVoucher = result.toString();
        _voucherDiscount = 50; // TODO: Calculate actual discount
      });
    }
  }

  Future<void> _updateQuantity(int productId, int quantity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.currentUser?.email != null) {
      await cartProvider.updateQuantity(
        productId,
        quantity,
        authProvider.currentUser!.email!,
      );
    }
  }

  Future<void> _removeItem(int productId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.currentUser?.email != null) {
      await cartProvider.removeFromCart(
        productId,
        authProvider.currentUser!.email!,
      );
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giỏ hàng'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả sản phẩm trong giỏ hàng?'),
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
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (authProvider.currentUser?.email != null) {
        await cartProvider.clearCart(authProvider.currentUser!.email!);
      }
    }
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.currentUser?.email != null) {
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
    }
  }
}
