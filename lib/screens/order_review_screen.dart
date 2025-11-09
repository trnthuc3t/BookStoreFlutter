import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/api_service.dart';
import '../utils/image_utils.dart';

class OrderReviewScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final List<Map<String, dynamic>> products;

  const OrderReviewScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.products,
  });

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  final Map<int, double> _ratings = {}; // bookId -> rating
  final Map<int, TextEditingController> _commentControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and default ratings for each product
    for (var product in widget.products) {
      final bookId = product['book_id'];
      _ratings[bookId] = 5.0; // Default 5 stars
      _commentControllers[bookId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReviews() async {
    print(' _submitReviews called!');
    print(' Order ID: ${widget.orderId}');
    print(' Products count: ${widget.products.length}');

    // Validate: at least one review should have a comment or rating
    bool hasContent = false;
    for (var product in widget.products) {
      final bookId = product['book_id'];
      final comment = _commentControllers[bookId]?.text.trim() ?? '';
      if (comment.isNotEmpty || (_ratings[bookId] ?? 0) > 0) {
        hasContent = true;
        break;
      }
    }

    if (!hasContent) {
      print('⚠No content to submit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đánh giá ít nhất một sản phẩm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print(' Validation passed, submitting reviews...');
    setState(() {
      _isSubmitting = true;
    });

    try {
      int successCount = 0;
      int failCount = 0;

      // Submit all reviews in parallel for better performance
      final futures = <Future<bool>>[];

      for (int i = 0; i < widget.products.length; i++) {
        final product = widget.products[i];
        final bookId = product['book_id'];
        final rating = _ratings[bookId] ?? 5.0;
        final comment = _commentControllers[bookId]?.text.trim();

        print('Preparing review for book #$bookId...');
        print('   - Order ID: ${widget.orderId}');
        print('   - Rating: ${rating.toInt()}');
        print(
            '   - Comment: ${comment?.isNotEmpty == true ? comment : "null"}');

        // Add to futures list
        futures.add(ApiService.submitReview(
          bookId: bookId,
          orderId: widget.orderId,
          rating: rating.toInt(),
          comment: comment?.isNotEmpty == true ? comment : null,
        ));
      }

      // Submit all reviews at once and wait for all to complete
      print(' Submitting ${futures.length} reviews in parallel...');
      final results = await Future.wait(futures);

      // Count successes and failures
      for (var success in results) {
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      print(' Final results: $successCount success, $failCount failed');

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failCount > 0
                    ? ' Đã gửi $successCount đánh giá. $failCount đánh giá thất bại.'
                    : ' Đã gửi $successCount đánh giá thành công!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to refresh orders
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Không thể gửi đánh giá. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print(' Error submitting reviews: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá sản phẩm'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Đang gửi đánh giá...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Order Info Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn hàng: ${widget.orderNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đánh giá ${widget.products.length} sản phẩm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Products List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.products.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final product = widget.products[index];
                      return _buildProductReviewItem(product);
                    },
                  ),
                ),

                // Submit Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReviews,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Gửi đánh giá',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProductReviewItem(Map<String, dynamic> product) {
    final bookId = product['book_id'];
    final bookTitle = product['book_title'] ?? 'N/A';
    final bookImage = product['book_image'];
    final controller = _commentControllers[bookId]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product info (image + title)
        Row(
          children: [
            // Book image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: bookImage != null
                  ? Image.network(
                      ImageUtils.normalizeImageUrl(bookImage) ?? bookImage,
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.book, size: 30),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.book, size: 30),
                    ),
            ),
            const SizedBox(width: 12),

            // Book title
            Expanded(
              child: Text(
                bookTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rating stars
        const Text(
          'Đánh giá:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: RatingBar.builder(
            initialRating: _ratings[bookId] ?? 5.0,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 40,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _ratings[bookId] = rating;
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // Comment text field
        const Text(
          'Nhận xét:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Chia sẻ trải nghiệm của bạn về sản phẩm này...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
