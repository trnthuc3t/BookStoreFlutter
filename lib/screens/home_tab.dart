import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../providers/product_provider_new.dart' as api_providers;
import '../providers/cart_provider_new.dart';
import '../providers/author_provider.dart';
import '../widgets/product_grid_widget.dart';
import '../widgets/authors_grid_widget.dart';
import '../utils/image_utils.dart';
import 'product_detail_api_screen.dart';
import 'author_books_screen.dart';
import 'cart_screen_new.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide sections based on tab
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceReload = false}) async {
    final productProvider =
        Provider.of<api_providers.ProductApiProvider>(context, listen: false);
    final authorProvider =
        Provider.of<AuthorProvider>(context, listen: false);
    await productProvider.loadProducts(forceReload: forceReload);
    await authorProvider.fetchAuthors();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookSell'),
        actions: [
          Consumer<CartApiProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CartScreenNew(),
                        ),
                      );
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<api_providers.ProductApiProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(productProvider.errorMessage!),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _loadData(forceReload: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner carousel - show featured products
                  if (productProvider.featuredProducts.isNotEmpty)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 200,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 3),
                        viewportFraction: 1.0,
                      ),
                      items: productProvider.featuredProducts
                          .map((product) {
                        // Build full image URL from relative path
                        final normalizedImageUrl =
                            ImageUtils.buildImageUrl(product.image);

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailApiScreen(bookId: product.id),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade200,
                            ),
                            child: normalizedImageUrl == null
                                ? const Center(
                                    child: Icon(Icons.book,
                                        size: 50, color: Colors.grey),
                                  )
                                : Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          normalizedImageUrl,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.book,
                                                  size: 50, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            product.name ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),

                  // TabBar for Books and Authors
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade700,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                      tabs: const [
                        Tab(
                          child: SizedBox(
                            width: double.infinity,
                            child: Center(child: Text('Sách')),
                          ),
                        ),
                        Tab(
                          child: SizedBox(
                            width: double.infinity,
                            child: Center(child: Text('Tác giả')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TabBarView content - Show authors when Authors tab is selected
                  if (_tabController.index == 1) ...[
                    Consumer<AuthorProvider>(
                      builder: (context, authorProvider, child) {
                        if (authorProvider.isLoading) {
                          return const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (authorProvider.error != null) {
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(authorProvider.error!),
                                  ElevatedButton(
                                    onPressed: () => authorProvider.fetchAuthors(),
                                    child: const Text('Thử lại'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (authorProvider.authors.isEmpty) {
                          return const SizedBox(
                            height: 200,
                            child: Center(
                              child: Text('Chưa có tác giả nào'),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            AuthorsGridWidget(
                              authors: authorProvider.authors,
                              onAuthorTap: (author) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AuthorBooksScreen(
                                      author: author,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20), // Add bottom padding
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Only show product sections when Books tab is selected
                  if (_tabController.index == 0) ...[
                    // Featured products
                    if (productProvider.featuredProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sản phẩm nổi bật',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to all products
                              },
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ProductGridWidget(
                        products:
                            productProvider.featuredProducts.take(6).toList(),
                        onProductTap: (product) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailApiScreen(bookId: product.id),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Bestseller products
                    if (productProvider.bestsellerProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sách bán chạy',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to all bestsellers
                              },
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ProductGridWidget(
                        products:
                            productProvider.bestsellerProducts.take(6).toList(),
                        onProductTap: (product) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailApiScreen(bookId: product.id),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // All products
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tất cả sản phẩm',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to all products
                            },
                            child: const Text('Xem tất cả'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ProductGridWidget(
                      products: productProvider.products.take(6).toList(),
                      onProductTap: (product) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailApiScreen(bookId: product.id),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20), // Add bottom padding for Books tab
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
