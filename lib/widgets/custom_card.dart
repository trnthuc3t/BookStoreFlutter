import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool isClickable;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation ?? 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (isClickable || onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

class ProductCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? description;
  final int price;
  final int? originalPrice;
  final int? discount;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showAddButton;

  const ProductCard({
    super.key,
    this.imageUrl,
    this.title,
    this.description,
    required this.price,
    this.originalPrice,
    this.discount,
    this.rating,
    this.reviewCount,
    this.onTap,
    this.onAddToCart,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      isClickable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          const SizedBox(height: 12),
          
          // Product Title
          if (title != null) ...[
            Text(
              title!,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          
          // Product Description
          if (description != null) ...[
            Text(
              description!,
              style: AppTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          // Rating
          if (rating != null) ...[
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  '${rating!.toStringAsFixed(1)} (${reviewCount ?? 0})',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Price and Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (originalPrice != null && discount != null) ...[
                      Text(
                        '${originalPrice!.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                        )} VNĐ',
                        style: AppTheme.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      '${price.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )} VNĐ',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (discount != null && discount! > 0) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$discount%',
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
              ),
              if (showAddButton) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, size: 20),
                  onPressed: onAddToCart,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.dividerColor,
      child: const Icon(
        Icons.image,
        size: 48,
        color: AppTheme.textSecondaryColor,
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final String orderId;
  final String status;
  final int totalAmount;
  final DateTime? createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onTrack;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    this.createdAt,
    this.onTap,
    this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      isClickable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn hàng #$orderId',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tổng tiền: ${totalAmount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )} VNĐ',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ngày tạo: ${_formatDate(createdAt!)}',
              style: AppTheme.bodySmall,
            ),
          ],
          if (onTrack != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onTrack,
                  child: const Text('Theo dõi đơn hàng'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'processing':
        return AppTheme.primaryColor;
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
