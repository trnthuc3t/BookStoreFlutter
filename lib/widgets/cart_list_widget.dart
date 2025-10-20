import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final productId = item['product_id'] as int;
    final name = item['name'] as String? ?? '';
    final price = item['price'] as int? ?? 0;
    final sale = item['sale'] as int? ?? 0;
    final image = item['image'] as String?;
    final quantity = item['quantity'] as int? ?? 1;

    final realPrice = sale > 0 ? price - (price * sale / 100) : price;
    final totalPrice = realPrice * quantity;

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
                        imageUrl: image,
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
                  
                  // Price
                  Row(
                    children: [
                      Text(
                        '${realPrice}k',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (sale > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${price}k',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$sale%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                                  ? () => onQuantityChanged(productId, quantity - 1)
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
                                  vertical: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () => onQuantityChanged(productId, quantity + 1),
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
                      
                      // Total price
                      Text(
                        '${totalPrice}k',
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
              onPressed: () => onRemoveItem(productId),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
