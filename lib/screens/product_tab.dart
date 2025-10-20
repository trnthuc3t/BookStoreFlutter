import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../widgets/product_grid_widget.dart';
import 'product_detail_screen.dart';

class ProductTab extends StatefulWidget {
  const ProductTab({super.key});

  @override
  State<ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends State<ProductTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;

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

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.loadProducts();
    await productProvider.loadCategories();
  }

  List<Product> get _filteredProducts {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    var products = productProvider.products;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      products = productProvider.searchProducts(_searchQuery);
    }

    // Filter by category
    if (_selectedCategoryId != null) {
      products = products.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

          return Column(
            children: [
              // Category filter
              if (productProvider.categories.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              _selectedCategoryId = selected ? category.id : null;
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
                    : ProductGridWidget(
                        products: _filteredProducts,
                        onProductTap: (product) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
