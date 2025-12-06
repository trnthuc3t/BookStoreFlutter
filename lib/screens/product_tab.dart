import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider_new.dart' as api_providers;
import '../providers/cart_provider_new.dart';
import '../models/product.dart';
import '../widgets/product_grid_widget.dart';
import 'product_detail_api_screen.dart';
import 'cart_screen_new.dart';

class ProductTab extends StatefulWidget {
  const ProductTab({super.key});

  @override
  State<ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends State<ProductTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceReload = false}) async {
    final productProvider =
        Provider.of<api_providers.ProductApiProvider>(context, listen: false);
    // Only load if not already loaded (cached)
    await productProvider.loadProducts(forceReload: forceReload);
    await productProvider.loadCategories(forceReload: forceReload);
  }

  List<Product> get _filteredProducts {
    final productProvider =
        Provider.of<api_providers.ProductApiProvider>(context, listen: false);
    var products = productProvider.products;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      products = productProvider.searchProducts(_searchQuery);
    }

    // Filter by category
    if (_selectedCategoryId != null) {
      products =
          products.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Search bar
            Expanded(
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Cart icon with badge
            Consumer<CartApiProvider>(
              builder: (context, cartProvider, child) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CartScreenNew(),
                            ),
                          );
                        },
                      ),
                    ),
                    if (cartProvider.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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

          return Column(
            children: [
              // Category filter
              if (productProvider.categories.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: productProvider.categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('Tất cả'),
                            selected: _selectedCategoryId == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                            },
                          ),
                        );
                      }

                      final category = productProvider.categories[index - 1];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.name ?? ''),
                          selected: _selectedCategoryId == category.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId =
                                  selected ? category.id : null;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Products grid
              Expanded(
                child: _filteredProducts.isEmpty
                    ? const Center(
                        child: Text('Không tìm thấy sản phẩm nào'),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadData(forceReload: true),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ProductGridWidget(
                            products: _filteredProducts,
                            onProductTap: (product) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailApiScreen(bookId: product.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

}
