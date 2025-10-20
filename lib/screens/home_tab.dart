import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_grid_widget.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.loadProducts();
    await productProvider.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookSell'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
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
      body: Consumer<ProductProvider>(
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

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner carousel
                if (productProvider.featuredProducts.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      viewportFraction: 1.0,
                    ),
                    items: productProvider.featuredProducts.take(5).map((product) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: product.image != null
                              ? DecorationImage(
                                  image: NetworkImage(product.image!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey.shade200,
                        ),
                        child: product.image == null
                            ? const Center(
                                child: Icon(Icons.book, size: 50, color: Colors.grey),
                              )
                            : Container(
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
                                child: Align(
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
                              ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),

                // Categories
                if (productProvider.categories.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Danh mục',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: productProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = productProvider.categories[index];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.book,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name ?? '',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

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
                    products: productProvider.featuredProducts.take(6).toList(),
                    onProductTap: (product) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
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
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
