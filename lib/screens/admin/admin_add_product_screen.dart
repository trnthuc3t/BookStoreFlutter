import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../models/category.dart' as app_models;

class AdminAddProductScreen extends StatefulWidget {
  final Product? product;

  const AdminAddProductScreen({super.key, this.product});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _saleController = TextEditingController();
  final _imageController = TextEditingController();
  final _bannerController = TextEditingController();
  final _infoController = TextEditingController();
  
  int? _selectedCategoryId;
  bool _isFeatured = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name ?? '';
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _saleController.text = widget.product!.sale.toString();
      _imageController.text = widget.product!.image ?? '';
      _bannerController.text = widget.product!.banner ?? '';
      _infoController.text = widget.product!.info ?? '';
      _selectedCategoryId = widget.product!.categoryId;
      _isFeatured = widget.product!.isFeatured;
    }
    
    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _saleController.dispose();
    _imageController.dispose();
    _bannerController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final product = Product(
        id: widget.product?.id ?? 0,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: int.tryParse(_priceController.text) ?? 0,
        image: _imageController.text.trim(),
        banner: _bannerController.text.trim(),
        categoryId: _selectedCategoryId!,
        categoryName: context.read<ProductProvider>().categories
            .firstWhere((cat) => cat.id == _selectedCategoryId).name,
        sale: int.tryParse(_saleController.text) ?? 0,
        isFeatured: _isFeatured,
        info: _infoController.text.trim(),
      );

      if (widget.product == null) {
        await context.read<ProductProvider>().addProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm sản phẩm thành công')),
          );
        }
      } else {
        await context.read<ProductProvider>().updateProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật sản phẩm thành công')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
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
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Giá *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập giá';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Giá phải là số';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _saleController,
                      decoration: const InputDecoration(
                        labelText: 'Giảm giá (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục *',
                      border: OutlineInputBorder(),
                    ),
                    items: productProvider.categories.map((app_models.Category category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name ?? 'N/A'),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Vui lòng chọn danh mục';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'URL hình ảnh',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bannerController,
                decoration: const InputDecoration(
                  labelText: 'URL banner',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _infoController,
                decoration: const InputDecoration(
                  labelText: 'Thông tin thêm',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Sản phẩm nổi bật'),
                value: _isFeatured,
                onChanged: (bool? value) {
                  setState(() {
                    _isFeatured = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.product == null ? 'Thêm sản phẩm' : 'Cập nhật sản phẩm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
