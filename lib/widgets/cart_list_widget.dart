import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_utils.dart';

class CartListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(int productId, int quantity) onQuantityChanged;
  final Function(int productId) onRemoveItem;

  const CartListWidget({
    super.key,
    required this.cartItems,
    required this.onQuantityChanged,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return _buildCartItem(context, item);
      },
    );
  }

  Widget _buildCartItem(BuildContext context, Map<String, dynamic> item) {
    // Map API response fields to widget fields
    final cartItemId =
        item['id'] as int? ?? 0; // cart_item_id for update/delete
    final bookId = item['book_id'] as int? ?? 0;
    final name = item['book_title'] as String? ?? '';

    // Handle price - API returns double
    final priceValue = item['book_price'];
    final price = priceValue != null ? (priceValue as num).toInt() : 0;

    final sale = 0; // API doesn't return sale info in cart
    final image = item['book_image'] as String?; // May not exist in cart API

    final quantityValue = item['quantity'];
    final quantity = quantityValue != null ? (quantityValue as num).toInt() : 1;

    final realPrice = price; // No sale in cart
    final totalPrice = (realPrice * quantity).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image != null
                    ? CachedNetworkImage(
                        imageUrl: ImageUtils.normalizeImageUrl(image) ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.book, color: Colors.grey),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.book, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Price - format to show properly
                  Text(
                    '${(price / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quantity controls
                  Row(
                    children: [
                      // Quantity buttons
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: quantity > 1
                                  ? () => onQuantityChanged(
                                      cartItemId, quantity - 1)
                                  : null,
                              icon: const Icon(Icons.remove, size: 16),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              width: 40,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  vertical:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  onQuantityChanged(cartItemId, quantity + 1),
                              icon: const Icon(Icons.add, size: 16),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Total price - format properly
                      Text(
                        '${(totalPrice / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Remove button
            IconButton(
              onPressed: () => onRemoveItem(cartItemId),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
