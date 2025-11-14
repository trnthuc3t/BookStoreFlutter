import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider_new.dart';
import '../providers/auth_provider_new.dart';
import '../providers/order_provider_new.dart';
import 'address_screen.dart';
import 'payment_method_screen.dart';
import 'voucher_screen.dart';
import 'payment_screen.dart';
import '../services/api_service.dart';
import '../utils/image_utils.dart';

class CartScreenNew extends StatefulWidget {
  const CartScreenNew({Key? key}) : super(key: key);

  @override
  State<CartScreenNew> createState() => _CartScreenNewState();
}

class _CartScreenNewState extends State<CartScreenNew> {
  String? _selectedPaymentMethod;
  String? _selectedAddress;
  String? _selectedVoucher;
  int _voucherDiscount = 0;
  Set<int> _selectedItems = {}; // Track selected cart items

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
      
      // Don't auto-select items - let user choose
      setState(() {
        _selectedItems = {};
      });
    }
  }

  Future<void> _refreshCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartApiProvider>(context, listen: false);

    if (authProvider.currentUser?.id != null) {
      await cartProvider.clearCache();
      await cartProvider.refresh(authProvider.currentUser!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật giỏ hàng'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.blue.shade400),
            const SizedBox(width: 8),
            const Text(
              'Giỏ hàng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshCart,
          ),
          Consumer<CartApiProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.cartItems.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: _clearCart,
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(color: Colors.red),
                ),
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
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshCart,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...cartProvider.cartItems.map((item) => _buildCartItem(item)),
                      const SizedBox(height: 16),
                      _buildPaymentMethodSection(),
                      const SizedBox(height: 12),
                      _buildAddressSection(),
                      const SizedBox(height: 12),
                      _buildVoucherSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return RefreshIndicator(
      onRefresh: _refreshCart,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 100, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text(
                  'Giỏ hàng trống',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy thêm sản phẩm vào giỏ hàng',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kéo xuống để làm mới',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final bookTitle = item['book_title'] ?? 'Không có tên';
    // API returns 'book_price' not 'price'
    final price = (item['book_price'] ?? item['price'] ?? 0).toDouble();
    final quantity = item['quantity'] ?? 1;
    final subtotal = price * quantity;
    // API returns 'book_image' not 'book_image_url'
    final imageUrl = ImageUtils.buildImageUrl(item['book_image'] ?? item['book_image_url']);
    final itemId = item['id'] as int;
    final isSelected = _selectedItems.contains(itemId);

    return Card(
      color: const Color(0xFF212121),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedItems.add(itemId);
                  } else {
                    _selectedItems.remove(itemId);
                  }
                  
                  // Clear voucher when selection changes
                  if (_selectedVoucher != null) {
                    _selectedVoucher = null;
                    _voucherDiscount = 0;
                  }
                });
              },
              activeColor: Colors.blue,
              shape: const CircleBorder(),
            ),
            // Book image
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 80,
                      color: Colors.grey.shade800,
                      child: Icon(Icons.book, color: Colors.grey.shade600),
                    );
                  },
                ),
              )
            else
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.book, color: Colors.grey.shade600),
              ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat('#,##0đ').format(price),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade300,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => _updateQuantity(itemId, quantity - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: quantity > 1 ? Colors.white : Colors.grey,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateQuantity(itemId, quantity + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.white,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade300, size: 20),
              onPressed: () => _removeItem(itemId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return InkWell(
      onTap: _selectPaymentMethod,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          children: [
            Icon(Icons.payment, color: Colors.blue.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPaymentMethod ?? 'Chọn phương thức thanh toán',
                    style: TextStyle(
                      color: _selectedPaymentMethod != null
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return InkWell(
      onTap: _selectAddress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ giao hàng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAddress ?? 'Chọn địa chỉ giao hàng',
                    style: TextStyle(
                      color: _selectedAddress != null
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return InkWell(
      onTap: _selectVoucher,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _selectedVoucher != null ? Colors.orange : Colors.grey.shade800),
        ),
        child: Row(
          children: [
            Icon(Icons.discount, color: _selectedVoucher != null ? Colors.orange.shade400 : Colors.purple.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mã giảm giá',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedVoucher != null
                        ? '$_selectedVoucher (-${NumberFormat('#,##0đ').format(_voucherDiscount)})'
                        : 'Chọn voucher (không bắt buộc)',
                    style: TextStyle(
                      color: _selectedVoucher != null
                          ? Colors.orange.shade300
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(CartApiProvider cartProvider) {
    // Calculate total only for selected items
    double selectedSubtotal = 0;
    for (var item in cartProvider.cartItems) {
      if (_selectedItems.contains(item['id'] as int)) {
        final price = (item['book_price'] ?? item['price'] ?? 0).toDouble();
        final quantity = item['quantity'] ?? 1;
        selectedSubtotal += price * quantity;
      }
    }
    
    final total = selectedSubtotal - _voucherDiscount;
    final canCheckout = _selectedPaymentMethod != null && 
                       _selectedAddress != null && 
                       _selectedItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tạm tính:',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                Text(
                  NumberFormat('#,##0đ').format(selectedSubtotal),
                  style: TextStyle(color: Colors.grey.shade300),
                ),
              ],
            ),
            if (_voucherDiscount > 0) ...[ 
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giảm giá:',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  Text(
                    '-${NumberFormat('#,##0đ').format(_voucherDiscount)}',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ],
            Divider(color: Colors.grey.shade800, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  NumberFormat('#,##0đ').format(total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canCheckout ? _checkout : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: canCheckout ? Colors.blue.shade700 : Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        canCheckout 
                            ? 'Thanh toán (${_selectedItems.length} sản phẩm)' 
                            : 'Chọn sản phẩm, phương thức & địa chỉ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Future<void> _selectPaymentMethod() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
    );

    if (result != null && mounted) {
      setState(() => _selectedPaymentMethod = result.toString());
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressScreen()),
    );

    if (result != null && mounted) {
      setState(() => _selectedAddress = result.toString());
    }
  }

  Future<void> _selectVoucher() async {
    final cartProvider = Provider.of<CartApiProvider>(context, listen: false);
    double selectedSubtotal = 0;
    
    for (var item in cartProvider.cartItems) {
      if (_selectedItems.contains(item['id'] as int)) {
        final price = (item['book_price'] ?? item['price'] ?? 0).toDouble();
        final quantity = item['quantity'] ?? 1;
        selectedSubtotal += price * quantity;
      }
    }

    if (_selectedItems.isEmpty || selectedSubtotal <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ít nhất 1 sản phẩm để áp dụng voucher'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoucherScreen()),
    );

    if (result != null) {
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final code = result.toString();

      print('🎫 [CART] Selected voucher: $code');
      print('🎫 [CART] User ID: ${authProvider.currentUser?.id}');

      if (authProvider.currentUser?.id == null) {
        print('🎫 [CART] ERROR: User not logged in');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang kiểm tra voucher...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      List<Map<String, dynamic>> selectedCartItems = [];
      for (var item in cartProvider.cartItems) {
        if (_selectedItems.contains(item['id'] as int)) {
          selectedCartItems.add({
            'book_id': item['book_id'],
            'quantity': item['quantity'],
          });
        }
      }

      print('🎫 [CART] Selected items: ${selectedCartItems.length}');
      print('🎫 [CART] Selected items data: $selectedCartItems');
      print('🎫 [CART] Subtotal: $selectedSubtotal');

      final res = await ApiService.validateVoucherWithCart(
        userId: authProvider.currentUser!.id!,
        code: code,
        cartItems: selectedCartItems,
        subtotal: selectedSubtotal,
      );

      print('🎫 [CART] API Response: $res');
      
      if (!mounted) return;
      
      if (res != null) {
        final isValid = res['valid'] == true;
        final discount = ((res['discount_amount'] ?? 0) as num).toDouble();
        final shipDiscount = ((res['shipping_discount'] ?? 0) as num).toDouble();
        final totalDiscount = discount + shipDiscount;
        
        if (isValid && totalDiscount > 0) {
          // Valid and has discount
          if (mounted) {
            setState(() {
              _selectedVoucher = code;
              _voucherDiscount = totalDiscount.round();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Áp dụng voucher $code thành công!\nGiảm ${NumberFormat('#,##0đ').format(totalDiscount)}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Not valid or no discount
          final reason = res['reason']?.toString() ?? 'Voucher không áp dụng được cho đơn hàng này';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(reason),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            setState(() {
              _selectedVoucher = null;
              _voucherDiscount = 0;
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi kết nối. Vui lòng thử lại'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _selectedVoucher = null;
            _voucherDiscount = 0;
          });
        }
      }
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
      
      // Clear voucher when quantity changes
      if (_selectedVoucher != null && mounted) {
        setState(() {
          _selectedVoucher = null;
          _voucherDiscount = 0;
        });
      }
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
      
      // Remove from selected items and clear voucher
      if (mounted) {
        setState(() {
          _selectedItems.remove(cartItemId);
          if (_selectedVoucher != null) {
            _selectedVoucher = null;
            _voucherDiscount = 0;
          }
        });
      }
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Xóa giỏ hàng', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc chắn muốn xóa tất cả sản phẩm?',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
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

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartApiProvider>(context, listen: false);

    if (authProvider.currentUser?.id != null) {
      // Filter only selected items
      final selectedCartItems = cartProvider.cartItems
          .where((item) => _selectedItems.contains(item['id'] as int))
          .toList();
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            cartItems: selectedCartItems,
            paymentMethod: _selectedPaymentMethod!,
            address: _selectedAddress!,
            voucher: _selectedVoucher,
            voucherDiscount: _voucherDiscount,
          ),
        ),
      );

      if (mounted) {
        await _refreshCart();
      }
    }
  }
}
