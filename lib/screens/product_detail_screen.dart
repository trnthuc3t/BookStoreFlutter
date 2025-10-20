import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'rating_review_screen.dart';
import 'tracking_order_screen.dart';
import 'receipt_order_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: widget.product.image != null
                  ? CachedNetworkImage(
                      imageUrl: widget.product.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.book, size: 100, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.book, size: 100, color: Colors.grey),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    widget.product.name ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.product.rate,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.product.rate} (${widget.product.countReviews} đánh giá)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Row(
                    children: [
                      Text(
                        '${widget.product.realPrice}k',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      if (widget.product.sale > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${widget.product.price}k',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${widget.product.sale}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category
                  if (widget.product.categoryName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.category, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Danh mục: ${widget.product.categoryName}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (widget.product.description != null) ...[
                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info
                  if (widget.product.info != null) ...[
                    const Text(
                      'Thông tin chi tiết',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.info!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Quantity selector
                  const Text(
                    'Số lượng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Thêm vào giỏ hàng'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.currentUser?.email != null) {
      await cartProvider.addToCart(
        widget.product,
        _quantity,
        authProvider.currentUser!.email!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${widget.product.name} vào giỏ hàng'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
