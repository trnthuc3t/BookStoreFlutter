import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class RatingReviewScreen extends StatefulWidget {
  final Product product;

  const RatingReviewScreen({super.key, required this.product});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn điểm đánh giá'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would submit the review to the server
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảm ơn bạn đã đánh giá sản phẩm!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá sản phẩm'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitReview,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gửi'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.product.image != null
                            ? Image.network(
                                widget.product.image!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 80),
                              )
                            : const Icon(Icons.image, size: 80),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name ?? 'Không có tên',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.product.price.toString().replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]},',
                              )} VNĐ',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Rating Section
              const Text(
                'Đánh giá của bạn',
                style: AppTheme.heading3,
              ),
              const SizedBox(height: 16),
              
              Center(
                child: Column(
                  children: [
                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = (index + 1).toDouble();
                            });
                          },
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            size: 48,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rating == 0.0
                          ? 'Chọn điểm đánh giá'
                          : '${_rating.toStringAsFixed(1)} sao',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Comment Section
              const Text(
                'Nhận xét của bạn',
                style: AppTheme.heading3,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm của bạn về sản phẩm này...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nhận xét';
                  }
                  if (value.trim().length < 10) {
                    return 'Nhận xét phải có ít nhất 10 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Rating Guidelines
              Card(
                color: AppTheme.backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hướng dẫn đánh giá',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• 5 sao: Rất hài lòng'),
                      const Text('• 4 sao: Hài lòng'),
                      const Text('• 3 sao: Bình thường'),
                      const Text('• 2 sao: Không hài lòng'),
                      const Text('• 1 sao: Rất không hài lòng'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: 'Gửi đánh giá',
                onPressed: _isLoading ? null : _submitReview,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
