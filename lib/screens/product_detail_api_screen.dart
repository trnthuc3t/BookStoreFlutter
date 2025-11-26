import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/image_utils.dart';

class ProductDetailApiScreen extends StatefulWidget {
  final int bookId;

  const ProductDetailApiScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<ProductDetailApiScreen> createState() => _ProductDetailApiScreenState();
}

class _ProductDetailApiScreenState extends State<ProductDetailApiScreen>
    with AutomaticKeepAliveClientMixin {
  int _quantity = 1;
  int _currentImageIndex = 0;
  bool _isLoading = true;
  bool _showFullDescription = false;
  bool _showAllReviews = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  Map<String, dynamic>? _bookData;
  List<dynamic>? _reviewsData;
  List<String> _imageUrls = [];

  // Static cache for book details (shared across all instances)
  static final Map<int, Map<String, dynamic>> _bookCache = {};
  static final Map<int, List<dynamic>> _reviewsCache = {};
  static final Map<int, DateTime> _cacheTimestamps = {};
  static const _cacheExpiry = Duration(minutes: 10); // Cache for 10 minutes

  @override
  bool get wantKeepAlive => true; // Keep state alive

  // Static method to clear cache for specific book or all books
  static void clearCache([int? bookId]) {
    if (bookId != null) {
      _bookCache.remove(bookId);
      _reviewsCache.remove(bookId);
      _cacheTimestamps.remove(bookId);
      print('🗑️ Cleared cache for book #$bookId');
    } else {
      _bookCache.clear();
      _reviewsCache.clear();
      _cacheTimestamps.clear();
      print('🗑️ Cleared all book cache');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBookData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadBookData({bool forceReload = false}) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Check cache first
      final now = DateTime.now();
      final cacheTimestamp = _cacheTimestamps[widget.bookId];
      final isCacheValid = !forceReload &&
          cacheTimestamp != null &&
          now.difference(cacheTimestamp) < _cacheExpiry;

      Map<String, dynamic>? bookData;
      List<dynamic>? reviewsData;

      if (isCacheValid && _bookCache.containsKey(widget.bookId)) {
        print('✅ Using cached book data for book #${widget.bookId}');
        bookData = _bookCache[widget.bookId];
        reviewsData = _reviewsCache[widget.bookId];
      } else {
        print('📥 Fetching book data for book #${widget.bookId}...');

        // Load ONLY book details first for fast display
        bookData = await ApiService.getBook(widget.bookId);

        print('✅ Loaded book data');

        // Store book in cache
        if (bookData != null) {
          _bookCache[widget.bookId] = bookData;
          _cacheTimestamps[widget.bookId] = now;
          print('💾 Cached book #${widget.bookId}');
        }
        
        // Check if reviews are cached
        if (_reviewsCache.containsKey(widget.bookId)) {
          reviewsData = _reviewsCache[widget.bookId];
        }
      }

      // Set state for both cached and freshly loaded data
      if (mounted) {
        setState(() {
          _bookData = bookData;
          _reviewsData = reviewsData;

          // Extract image URLs
          if (bookData != null && bookData['images'] != null) {
            final images = bookData['images'] as List<dynamic>;
            _imageUrls = images.map((img) {
              final url = img['image_url'] ?? img['url'];
              return ImageUtils.normalizeImageUrl(url) ?? url as String;
            }).toList();
          }

          _isLoading = false;
        });
        
        // Lazy load reviews in background if not cached
        if (_reviewsData == null && !forceReload) {
          _loadReviews();
        }
      }
    } catch (e) {
      print('❌ Error loading book data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    
    try {
      print('📥 Lazy loading reviews for book #${widget.bookId}...');
      final reviewsData = await ApiService.getBookReviews(
        bookId: widget.bookId,
        limit: 20,
      );

      print('📊 Reviews data received: ${reviewsData.length} items');

      if (mounted) {
        setState(() {
          _reviewsData = reviewsData;
        });
        // Cache reviews
        _reviewsCache[widget.bookId] = reviewsData;
        print('✅ Reviews loaded: ${reviewsData.length} reviews');
      }
    } catch (e) {
      print('❌ Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bookData == null) {
      return Scaffold(
        body: const Center(child: Text('Không thể tải thông tin sản phẩm')),
      );
    }

    final title = _bookData!['title'] ?? 'N/A';
    final price = (_bookData!['price'] ?? 0) / 1000;
    final originalPrice = _bookData!['original_price'] != null
        ? _bookData!['original_price'] / 1000
        : null;
    final discountPercentage = _bookData!['discount_percentage'] ?? 0;
    final stockQuantity = _bookData!['stock_quantity'] ?? 0;
    final soldQuantity = _bookData!['sold_quantity'] ?? 0;
    final ratingAverage = (_bookData!['rating_average'] ?? 0.0).toDouble();
    final ratingCount = _bookData!['rating_count'] ?? 0;
    final description = _bookData!['description'] ?? '';

    // Calculate opacity for image overlay based on scroll
    final imageHeight = MediaQuery.of(context).size.height * 0.5;
    final opacity = (_scrollOffset / imageHeight).clamp(0.0, 0.7);

    return Scaffold(
      body: Stack(
        children: [
          // Main scrollable content
          RefreshIndicator(
            onRefresh: () => _loadBookData(forceReload: true),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Image header with parallax effect
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.5,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageCarousel(stockQuantity),
                        // Gradient overlay that increases with scroll
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(opacity * 0.3),
                                  Colors.black.withOpacity(opacity * 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Content
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Rating and Sold Quantity
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: ratingAverage,
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
                                '$ratingAverage ($ratingCount đánh giá)',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đã bán: ${soldQuantity.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Book Details (Authors, Cover Type, Dimensions)
                          _buildBookDetails(),
                          const SizedBox(height: 16),

                          // Price
                          Row(
                            children: [
                              Text(
                                '${price.toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              if (discountPercentage > 0 &&
                                  originalPrice != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '${originalPrice.toStringAsFixed(0)}k',
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
                                    '-${discountPercentage.toInt()}%',
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

                          // Description with show more
                          _buildDescription(description),
                          const SizedBox(height: 24),

                          // Reviews Section
                          _buildReviewsSection(),
                          const SizedBox(height: 24),

                          // Quantity selector
                          RepaintBoundary(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                      onPressed: stockQuantity > 0 && _quantity > 1
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
                                      onPressed: stockQuantity > 0
                                          ? () => setState(() => _quantity++)
                                          : null,
                                      icon: const Icon(Icons.add),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.grey.shade200,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Add to cart button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  stockQuantity > 0 ? () => _addToCart() : null,
                              icon: const Icon(Icons.shopping_cart),
                              label: Text(
                                stockQuantity > 0 ? 'Thêm vào giỏ hàng' : 'Hết hàng',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor:
                                    stockQuantity > 0 ? null : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating action buttons (Back and Reload)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Reload button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => _loadBookData(forceReload: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(int stockQuantity) {
    if (_imageUrls.isEmpty) {
      return Container(
        height: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.book, size: 100, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        // Horizontal scrollable image gallery - one image at a time
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: PageView.builder(
            physics: const PageScrollPhysics(),
            itemCount: _imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      // Optional: Show full screen image
                    },
                    child: Hero(
                      tag: 'product_image_$index',
                      child: CachedNetworkImage(
                        imageUrl: _imageUrls[index],
                        // Giữ tỷ lệ gốc, fit theo chiều ngang hoặc dọc
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        memCacheWidth: 800,
                        memCacheHeight: 800,
                        maxWidthDiskCache: 1200,
                        maxHeightDiskCache: 1200,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.book, size: 100, color: Colors.grey),
                        ),
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Image indicator
        if (_imageUrls.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${_imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Out of stock overlay
        if (stockQuantity <= 0)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 3),
                  ),
                  child: const Center(
                    child: Text(
                      'HẾT\nHÀNG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookDetails() {
    if (_bookData == null) return const SizedBox();

    final authors = _bookData!['authors'] as List<dynamic>?;
    final coverType = _bookData!['cover_type'] is String ? _bookData!['cover_type'] as String : null;
    final length = _bookData!['length'] as num?;
    final width = _bookData!['width'] as num?;
    final thickness = _bookData!['thickness'] as num?;
    final weight = _bookData!['weight'] as num?;
    
    // New fields - safe parsing
    final bookSize = _bookData!['book_size'] is String ? _bookData!['book_size'] as String : null;
    final publishYear = _bookData!['publication_year'];
    final supplierName = _bookData!['supplier_name'] is String ? _bookData!['supplier_name'] as String : null;
    final publisherName = _bookData!['publisher_name'] is String ? _bookData!['publisher_name'] as String : null;
    final pageCount = _bookData!['pages'];
    final language = _bookData!['language'] is String ? _bookData!['language'] as String : null;
    final categoryName = _bookData!['category_name'] is String ? _bookData!['category_name'] as String : null;

    // Nếu không có thông tin gì thì không hiển thị
    if ((authors == null || authors.isEmpty) &&
        coverType == null &&
        length == null &&
        width == null &&
        thickness == null &&
        weight == null &&
        bookSize == null &&
        publishYear == null &&
        supplierName == null &&
        publisherName == null &&
        pageCount == null &&
        language == null &&
        categoryName == null) {
      return const SizedBox();
    }

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Thông tin chi tiết',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Authors
            if (authors != null && authors.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.person,
                label: 'Tác giả',
                value: authors.map((a) => a['name']).join(', '),
              ),
              const SizedBox(height: 8),
            ],

            // Cover Type
            if (coverType != null && coverType.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.book,
                label: 'Loại bìa',
                value: _getCoverTypeLabel(coverType),
              ),
              const SizedBox(height: 8),
            ],

            // Dimensions from length/width/thickness
            if (length != null || width != null || thickness != null) ...[
              _buildDetailRow(
                icon: Icons.straighten,
                label: 'Kích thước',
                value: _formatDimensions(length, width, thickness),
              ),
              const SizedBox(height: 8),
            ],
            
            // Weight
            if (weight != null) ...[
              _buildDetailRow(
                icon: Icons.fitness_center,
                label: 'Trọng lượng',
                value: '${weight}g',
              ),
              const SizedBox(height: 8),
            ],
            
            // Book Size (if available separately)
            if (bookSize != null && bookSize.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.straighten,
                label: 'Kích thước sách',
                value: bookSize,
              ),
              const SizedBox(height: 8),
            ],
            
            // Publish Year
            if (publishYear != null) ...[
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Năm xuất bản',
                value: publishYear.toString(),
              ),
              const SizedBox(height: 8),
            ],
            
            // Supplier
            if (supplierName != null && supplierName.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.business,
                label: 'Nhà cung cấp',
                value: supplierName,
              ),
              const SizedBox(height: 8),
            ],
            
            // Publisher
            if (publisherName != null && publisherName.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.apartment,
                label: 'Nhà xuất bản',
                value: publisherName,
              ),
              const SizedBox(height: 8),
            ],
            
            // Page Count
            if (pageCount != null) ...[
              _buildDetailRow(
                icon: Icons.menu_book,
                label: 'Số trang',
                value: pageCount.toString(),
              ),
              const SizedBox(height: 8),
            ],
            
            // Language
            if (language != null && language.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.language,
                label: 'Ngôn ngữ',
                value: language,
              ),
              const SizedBox(height: 8),
            ],
            
            // Category/Genre
            if (categoryName != null && categoryName.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.category,
                label: 'Thể loại',
                value: categoryName,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getCoverTypeLabel(String coverType) {
    switch (coverType.toLowerCase()) {
      case 'paperback':
        return 'Bìa mềm';
      case 'hardcover':
        return 'Bìa cứng';
      default:
        return coverType;
    }
  }

  String _formatDimensions(num? length, num? width, num? thickness) {
    final parts = <String>[];
    if (length != null) parts.add('${length.toStringAsFixed(1)} cm');
    if (width != null) parts.add('${width.toStringAsFixed(1)} cm');
    if (thickness != null) parts.add('${thickness.toStringAsFixed(1)} cm');

    return parts.isNotEmpty ? parts.join(' × ') : 'Không có thông tin';
  }

  Widget _buildDescription(String description) {
    if (description.isEmpty) return const SizedBox();

    final lines = description.split('\n');
    final shouldCollapse = lines.length > 4 || description.length > 200;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.description, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Mô tả sản phẩm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
              maxLines: _showFullDescription ? null : 4,
              overflow: _showFullDescription ? null : TextOverflow.ellipsis,
            ),
            if (shouldCollapse)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _showFullDescription = !_showFullDescription);
                  },
                  icon: Icon(
                    _showFullDescription
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                  label: Text(_showFullDescription ? 'Thu gọn' : 'Xem thêm'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    // Show loading state while reviews are being lazy loaded
    if (_reviewsData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Đang tải đánh giá...',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_reviewsData!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.rate_review, size: 20, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Chưa có đánh giá nào',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final reviews = _reviewsData!;
    final displayReviews = _showAllReviews ? reviews : reviews.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rate_review, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Đánh giá',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${reviews.length} đánh giá',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayReviews.map((review) => _buildReviewItem(review)),
        if (reviews.length > 2 && !_showAllReviews)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => _showAllReviews = true);
              },
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              label: Text('Xem thêm ${reviews.length - 2} bình luận'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
        if (_showAllReviews && reviews.length > 2)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => _showAllReviews = false);
              },
              icon: const Icon(Icons.keyboard_arrow_up, size: 18),
              label: const Text('Thu gọn'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final userName = review['user_name'] ?? 'Anonymous';
    final rating = (review['rating'] ?? 5).toDouble();
    final comment = review['comment'] ?? '';
    final createdAt = review['created_at'];

    return RepaintBoundary(
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 18,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${rating.toStringAsFixed(1)} sao',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comment,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatReviewDate(createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  String _formatReviewDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'Hôm nay';
      } else if (diff.inDays == 1) {
        return 'Hôm qua';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      } else if (diff.inDays < 30) {
        return '${(diff.inDays / 7).floor()} tuần trước';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _addToCart() async {
    try {
      // Get user ID
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id');
      final token = prefs.getString('auth_token');
      
      // Debug logging
      print('🛒 === ADD TO CART DEBUG ===');
      print('User ID: $userIdStr');
      print('Auth token exists: ${token != null}');
      if (token != null) {
        print('Token preview: ${token.substring(0, 20)}...');
      }
      print('Book ID: ${widget.bookId}');
      print('Quantity: $_quantity');
      print('========================');

      if (userIdStr == null) {
        print('❌ No user ID found in SharedPreferences!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Vui lòng đăng nhập để thêm vào giỏ hàng'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      if (token == null) {
        print('❌ No auth token found in SharedPreferences!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Vui lòng đăng nhập lại'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        print('❌ Cannot parse user ID: $userIdStr');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Lỗi định dạng user ID'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang thêm vào giỏ hàng...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Add to cart via API
      print('📤 Calling ApiService.addToCart...');
      print('   Parameters: userId=$userId, bookId=${widget.bookId}, quantity=$_quantity');
      
      final result = await ApiService.addToCart(
        userId: userId,
        bookId: widget.bookId,
        quantity: _quantity,
      );
      
      print('📥 API call completed');
      print('   Result: ${result != null ? "Success" : "Failed (null)"}');
      if (result != null) {
        print('   Response data: $result');
      }

      if (!mounted) return;

      if (result != null && !result.containsKey('error')) {
        print('✅ Successfully added to cart');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã thêm vào giỏ hàng!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Reset quantity
        setState(() => _quantity = 1);
      } else {
        // Handle error response
        String errorMessage = '❌ Không thể thêm vào giỏ hàng';
        if (result != null && result.containsKey('message')) {
          errorMessage = result['message'];
        }
        
        print('❌ Failed to add to cart - ${result?['error'] ?? 'null response'}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Đã xảy ra lỗi'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
