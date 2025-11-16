import 'package:flutter/material.dart';
import '../models/author.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_grid_widget.dart';
import 'product_detail_api_screen.dart';

class AuthorBooksScreen extends StatefulWidget {
  final Author author;

  const AuthorBooksScreen({
    super.key,
    required this.author,
  });

  @override
  State<AuthorBooksScreen> createState() => _AuthorBooksScreenState();
}

class _AuthorBooksScreenState extends State<AuthorBooksScreen> {
  List<Product> _books = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAuthorBooks();
  }

  Future<void> _loadAuthorBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final booksJson = await ApiService.getBooksByAuthor(widget.author.id);
      setState(() {
        _books = booksJson.map((json) => Product.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải sách của tác giả: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.author.penName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAuthorBooks,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Chưa có sách của tác giả ${widget.author.penName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _getGradientColors(widget.author.id),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.author.getInitials(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.author.penName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_books.length} cuốn sách',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Books grid
          ProductGridWidget(
            products: _books,
            onProductTap: (product) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailApiScreen(
                    bookId: product.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Generate gradient colors based on author ID (same as AuthorsGridWidget)
  List<Color> _getGradientColors(int id) {
    final colorSets = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Pink
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Orange
      [const Color(0xFF30cfd0), const Color(0xFF330867)], // Teal
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // Light
      [const Color(0xFFff9a9e), const Color(0xFFfecfef)], // Rose
    ];

    return colorSets[id % colorSets.length];
  }
}
