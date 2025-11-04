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
    // Map API response fields
    final cartItemId = item['id'] as int? ?? 0;
    final name = item['book_title'] as String? ?? '';
    final image = item['book_image'] as String?;

    // Price handling with discount
    final priceValue = item['book_price'];
    final price = priceValue != null ? (priceValue as num).toDouble() : 0.0;

    final originalPriceValue = item['book_original_price'];
    final originalPrice = originalPriceValue != null
        ? (originalPriceValue as num).toDouble()
        : price;

    final discountValue = item['discount_percentage'];
    final discountPercentage =
        discountValue != null ? (discountValue as num).toDouble() : 0.0;

    final quantityValue = item['quantity'];
    final quantity = quantityValue != null ? (quantityValue as num).toInt() : 1;

    // Calculate prices
    final hasDiscount = discountPercentage > 0 && originalPrice > price;
    final totalPrice = price * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with discount badge
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image != null
                        ? CachedNetworkImage(
                            imageUrl: ImageUtils.normalizeImageUrl(image) ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.book,
                                  color: Colors.grey, size: 32),
                            ),
                          )
                        : const Center(
                            child:
                                Icon(Icons.book, color: Colors.grey, size: 32),
                          ),
                  ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price section
                  Row(
                    children: [
                      // Original price (strikethrough if has discount)
                      if (hasDiscount) ...[
                        Text(
                          '${(originalPrice / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Current price
                      Text(
                        '${(price / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(
                          color: hasDiscount
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quantity controls and total
                  Row(
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: quantity > 1
                                  ? () => onQuantityChanged(
                                      cartItemId, quantity - 1)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.remove,
                                  size: 18,
                                  color:
                                      quantity > 1 ? Colors.blue : Colors.grey,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  vertical:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  onQuantityChanged(cartItemId, quantity + 1),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Total price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tổng',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${(totalPrice / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // Remove button
            IconButton(
              onPressed: () => onRemoveItem(cartItemId),
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
