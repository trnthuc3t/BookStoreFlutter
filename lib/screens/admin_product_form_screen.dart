import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../utils/image_utils.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product; // null = add new, not null = edit

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isActive = true;

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _discountPercentageController;
  late TextEditingController _stockController;
  late TextEditingController _pagesController;
  late TextEditingController _yearController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _thicknessController;
  late TextEditingController _weightController;

  // Dropdowns
  List<dynamic> _categories = [];
  List<dynamic> _authors = [];
  List<dynamic> _publishers = [];
  List<dynamic> _suppliers = [];
  int? _selectedCategoryId;
  int? _selectedPublisherId;
  int? _selectedSupplierId;
  List<int> _selectedAuthorIds = []; // Selected author IDs
  String _selectedLanguage = 'Vietnamese';
  String _selectedCoverType = 'paperback';

  // Images
  List<XFile> _newImages = []; // New images to upload
  List<String> _existingImageUrls = []; // Existing images from server
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    final product = widget.product;
    _titleController = TextEditingController(text: product?['title'] ?? '');
    _descriptionController =
        TextEditingController(text: product?['description'] ?? '');
    _priceController =
        TextEditingController(text: product?['price']?.toString() ?? '');
    _originalPriceController = TextEditingController(
        text: product?['original_price']?.toString() ?? '');
    _discountPercentageController = TextEditingController(
        text: product?['discount_percentage']?.toString() ?? '0');
    _stockController = TextEditingController(
        text: product?['stock_quantity']?.toString() ?? '0');
    _pagesController =
        TextEditingController(text: product?['pages']?.toString() ?? '');
    _yearController = TextEditingController(
        text: product?['publication_year']?.toString() ?? '');
    _lengthController = TextEditingController(
        text: product?['length']?.toString() ?? '');
    _widthController = TextEditingController(
        text: product?['width']?.toString() ?? '');
    _thicknessController = TextEditingController(
        text: product?['thickness']?.toString() ?? '');
    _weightController = TextEditingController(
        text: product?['weight']?.toString() ?? '');

    _isActive = product?['is_active'] ?? true;

    // Load category - handle both direct id and nested object
    if (product?['category_id'] != null) {
      _selectedCategoryId = product!['category_id'] is int
          ? product['category_id']
          : int.tryParse(product['category_id'].toString());
    } else if (product?['category'] != null && product!['category'] is Map) {
      _selectedCategoryId = product['category']['id'] is int
          ? product['category']['id']
          : int.tryParse(product['category']['id'].toString());
    }

    // Load publisher and supplier
    if (product?['publisher'] != null && product!['publisher'] is Map) {
      _selectedPublisherId = product['publisher']['id'] is int
          ? product['publisher']['id']
          : int.tryParse(product['publisher']['id'].toString());
    }
    if (product?['supplier'] != null && product!['supplier'] is Map) {
      _selectedSupplierId = product['supplier']['id'] is int
          ? product['supplier']['id']
          : int.tryParse(product['supplier']['id'].toString());
    }

    // Load language and cover_type
    _selectedLanguage = product?['language'] ?? 'Vietnamese';
    _selectedCoverType = product?['cover_type'] ?? 'paperback';

    // Load existing images if editing
    if (product != null && product['images'] != null) {
      final images = product['images'] as List<dynamic>;
      _existingImageUrls = images
          .map((img) {
            if (img is Map<String, dynamic>) {
              return img['url'] as String;
            } else if (img is String) {
              return img;
            }
            return '';
          })
          .where((url) => url.isNotEmpty)
          .toList();

      print('📸 Loaded ${_existingImageUrls.length} existing images');
    }

    // Load existing authors if editing
    if (product != null && product['authors'] != null) {
      final authors = product['authors'] as List<dynamic>;
      _selectedAuthorIds = authors
          .map((author) => author['id'] as int)
          .toList();
      print('👤 Loaded ${_selectedAuthorIds.length} existing authors');
    }

    _loadCategories();
    _loadAuthors();
    _loadPublishers();
    _loadSuppliers();
  }

  Future<void> _loadCategories() async {
    final categories = await ApiService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
      });
      print('📋 Loaded ${categories.length} categories');
    }
  }

  Future<void> _loadAuthors() async {
    final authors = await ApiService.getAuthors();
    if (mounted) {
      setState(() {
        _authors = authors;
      });
      print('👤 Loaded ${authors.length} authors');
    }
  }

  Future<void> _loadPublishers() async {
    final publishers = await ApiService.getPublishers();
    if (mounted) {
      setState(() {
        _publishers = publishers;
      });
      print('🏢 Loaded ${publishers.length} publishers');
    }
  }

  Future<void> _loadSuppliers() async {
    final suppliers = await ApiService.getSuppliers();
    if (mounted) {
      setState(() {
        _suppliers = suppliers;
      });
      print('🚚 Loaded ${suppliers.length} suppliers');
    }
  }

  Future<void> _showAddAuthorDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tác giả mới'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên tác giả (bút danh)',
            border: OutlineInputBorder(),
            hintText: 'VD: Nguyễn Nhật Ánh',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final authorData = await ApiService.createAuthor(result);
      if (authorData != null) {
        await _loadAuthors(); // Reload authors list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Đã thêm tác giả: $result')),
          );
        }
      }
    }
  }

  Future<void> _showAddPublisherDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm nhà xuất bản mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên nhà xuất bản *',
                  border: OutlineInputBorder(),
                  hintText: 'VD: NXB Kim Đồng',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email liên hệ',
                  border: OutlineInputBorder(),
                  hintText: 'VD: contact@kimdong.com.vn',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  hintText: 'VD: 0123456789',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên nhà xuất bản')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result == true) {
      final publisherData = await ApiService.createPublisher(
        name: nameController.text.trim(),
        contactEmail: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        contactPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      );
      
      if (publisherData != null) {
        await _loadPublishers();
        if (mounted) {
          setState(() {
            _selectedPublisherId = publisherData['id'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Đã thêm nhà xuất bản: ${nameController.text.trim()}')),
          );
        }
      }
    }
  }

  Future<void> _showAddSupplierDialog() async {
    final nameController = TextEditingController();
    final contactPersonController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm nhà cung cấp mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên nhà cung cấp *',
                  border: OutlineInputBorder(),
                  hintText: 'VD: Công ty TNHH Sách ABC',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Người liên hệ',
                  border: OutlineInputBorder(),
                  hintText: 'VD: Nguyễn Văn A',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'VD: contact@abc.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  hintText: 'VD: 0123456789',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                  hintText: 'VD: 123 Đường ABC, Quận 1, TP.HCM',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên nhà cung cấp')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result == true) {
      final supplierData = await ApiService.createSupplier(
        name: nameController.text.trim(),
        contactPerson: contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
      );
      
      if (supplierData != null) {
        await _loadSuppliers();
        if (mounted) {
          setState(() {
            _selectedSupplierId = supplierData['id'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Đã thêm nhà cung cấp: ${nameController.text.trim()}')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _discountPercentageController.dispose();
    _stockController.dispose();
    _pagesController.dispose();
    _yearController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _thicknessController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      setState(() {
        _newImages.addAll(images);
      });
      print('📸 Added ${images.length} new images');
    } catch (e) {
      print('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _pickCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _newImages.add(image);
        });
        print('📸 Added camera image');
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if has images (new or existing)
    if (_newImages.isEmpty &&
        _existingImageUrls.isEmpty &&
        widget.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ảnh sản phẩm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.product == null) {
        // Add new product
        await _createProduct();
      } else {
        // Update existing product
        await _updateProduct();
      }
    } catch (e) {
      print('Error submitting form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createProduct() async {
    final success = await ApiService.createBookWithImages(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      isbn: null, // Auto-generated or optional
      price: double.tryParse(_priceController.text) ?? 0,
      originalPrice: double.tryParse(_originalPriceController.text),
      stockQuantity: int.tryParse(_stockController.text) ?? 0,
      pages: int.tryParse(_pagesController.text),
      publicationYear: int.tryParse(_yearController.text),
      categoryId: _selectedCategoryId,
      publisherId: _selectedPublisherId,
      supplierId: _selectedSupplierId,
      language: _selectedLanguage,
      coverType: _selectedCoverType,
      length: double.tryParse(_lengthController.text),
      width: double.tryParse(_widthController.text),
      thickness: double.tryParse(_thicknessController.text),
      weight: int.tryParse(_weightController.text),
      authorIds: _selectedAuthorIds.isEmpty ? null : _selectedAuthorIds,
      images: _newImages,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Thêm sản phẩm thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Return true to reload products
    }
  }

  Future<void> _updateProduct() async {
    final bookId = widget.product!['id'];

    // Step 1: Update book details with ALL fields
    print('📝 Updating book with full details...');
    final success = await ApiService.updateBook(
      bookId: bookId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text),
      originalPrice: double.tryParse(_originalPriceController.text),
      discountPercentage: double.tryParse(_discountPercentageController.text),
      stockQuantity: int.tryParse(_stockController.text),
      isActive: _isActive,
      // Additional fields
      categoryId: _selectedCategoryId,
      publisherId: _selectedPublisherId,
      supplierId: _selectedSupplierId,
      language: _selectedLanguage,
      coverType: _selectedCoverType,
      pages: int.tryParse(_pagesController.text),
      publicationYear: int.tryParse(_yearController.text),
      length: double.tryParse(_lengthController.text),
      width: double.tryParse(_widthController.text),
      thickness: double.tryParse(_thicknessController.text),
      weight: int.tryParse(_weightController.text),
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Cập nhật thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 2: Update authors
    if (_selectedAuthorIds.isNotEmpty) {
      print('👤 Updating ${_selectedAuthorIds.length} authors...');
      final authorsSuccess = await ApiService.updateBookAuthors(
        bookId: bookId,
        authorIds: _selectedAuthorIds,
      );

      if (!authorsSuccess) {
        print('⚠️ Failed to update authors');
      } else {
        print('✅ Authors updated successfully');
      }
    }

    // Step 3: Upload new images if any
    if (_newImages.isNotEmpty) {
      print('📸 Uploading ${_newImages.length} new images...');
      final uploadSuccess = await ApiService.uploadBookImages(
        bookId: bookId,
        images: _newImages,
      );

      if (!uploadSuccess) {
        print('⚠️ Failed to upload some images');
      } else {
        print('✅ All images uploaded successfully');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_newImages.isNotEmpty
              ? '✅ Cập nhật sản phẩm và ${_newImages.length} ảnh thành công'
              : '✅ Cập nhật sản phẩm thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images Section
                    _buildImagesSection(),
                    const SizedBox(height: 24),

                    // Active/Inactive Toggle
                    Card(
                      child: SwitchListTile(
                        title: const Text('Kích hoạt sản phẩm'),
                        subtitle: Text(_isActive
                            ? 'Sản phẩm đang được bán'
                            : 'Sản phẩm không được bán'),
                        value: _isActive,
                        activeColor: Colors.green,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên sách *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên sách';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<int?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Thể loại',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      hint: const Text('-- Chọn thể loại --'),
                      items: _categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category['id'],
                          child: Text(category['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Publisher Dropdown
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Nhà xuất bản',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Thêm', style: TextStyle(fontSize: 13)),
                                  onPressed: _showAddPublisherDialog,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              value: _selectedPublisherId,
                              decoration: const InputDecoration(
                                labelText: 'Chọn nhà xuất bản',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business),
                              ),
                              hint: const Text('-- Không chọn --'),
                              items: _publishers.map((publisher) {
                                return DropdownMenuItem<int>(
                                  value: publisher['id'],
                                  child: Text(publisher['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedPublisherId = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Supplier Dropdown
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Nhà cung cấp',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Thêm', style: TextStyle(fontSize: 13)),
                                  onPressed: _showAddSupplierDialog,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              value: _selectedSupplierId,
                              decoration: const InputDecoration(
                                labelText: 'Chọn nhà cung cấp',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_shipping),
                              ),
                              hint: const Text('-- Không chọn --'),
                              items: _suppliers.map((supplier) {
                                return DropdownMenuItem<int>(
                                  value: supplier['id'],
                                  child: Text(supplier['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedSupplierId = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Authors Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tác giả',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm tác giả mới'),
                                  onPressed: _showAddAuthorDialog,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _authors.map((author) {
                                final authorId = author['id'] as int;
                                final isSelected =
                                    _selectedAuthorIds.contains(authorId);

                                return FilterChip(
                                  label: Text(author['pen_name']),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedAuthorIds.add(authorId);
                                      } else {
                                        _selectedAuthorIds.remove(authorId);
                                      }
                                    });
                                  },
                                  selectedColor: Colors.orange.shade200,
                                );
                              }).toList(),
                            ),
                            if (_selectedAuthorIds.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Đã chọn: ${_selectedAuthorIds.length} tác giả',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Price & Original Price
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Giá bán *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                              suffixText: 'VNĐ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nhập giá';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Giá không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _originalPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Giá gốc',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.money_off),
                              suffixText: 'VNĐ',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Discount Percentage
                    TextFormField(
                      controller: _discountPercentageController,
                      decoration: const InputDecoration(
                        labelText: 'Phần trăm giảm giá',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                        suffixText: '%',
                        helperText: 'VD: 20 = giảm 20%',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final discount = double.tryParse(value);
                          if (discount == null ||
                              discount < 0 ||
                              discount > 100) {
                            return 'Giảm giá phải từ 0-100%';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Stock Quantity
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng tồn kho *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nhập số lượng';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Số lượng không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dimensions & Weight
                    const Text(
                      'Thông số sản phẩm',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _lengthController,
                            decoration: const InputDecoration(
                              labelText: 'Dài',
                              border: OutlineInputBorder(),
                              suffixText: 'cm',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('×', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _widthController,
                            decoration: const InputDecoration(
                              labelText: 'Rộng',
                              border: OutlineInputBorder(),
                              suffixText: 'cm',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('×', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _thicknessController,
                            decoration: const InputDecoration(
                              labelText: 'Dày',
                              border: OutlineInputBorder(),
                              suffixText: 'cm',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Weight
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Trọng lượng',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                        suffixText: 'gram',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Pages & Year
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pagesController,
                            decoration: const InputDecoration(
                              labelText: 'Số trang',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pages),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            decoration: const InputDecoration(
                              labelText: 'Năm xuất bản',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Language Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: 'Ngôn ngữ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Vietnamese', child: Text('Tiếng Việt')),
                        DropdownMenuItem(
                            value: 'English', child: Text('Tiếng Anh')),
                        DropdownMenuItem(
                            value: 'Chinese', child: Text('Tiếng Trung')),
                        DropdownMenuItem(
                            value: 'Japanese', child: Text('Tiếng Nhật')),
                        DropdownMenuItem(
                            value: 'Korean', child: Text('Tiếng Hàn')),
                        DropdownMenuItem(
                            value: 'French', child: Text('Tiếng Pháp')),
                        DropdownMenuItem(value: 'Other', child: Text('Khác')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLanguage = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Cover Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCoverType,
                      decoration: const InputDecoration(
                        labelText: 'Loại bìa',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.auto_stories),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'paperback', child: Text('Bìa mềm')),
                        DropdownMenuItem(
                            value: 'hardcover', child: Text('Bìa cứng')),
                        DropdownMenuItem(
                            value: 'leather', child: Text('Bìa da')),
                        DropdownMenuItem(value: 'other', child: Text('Khác')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCoverType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitForm,
                        icon: Icon(isEdit ? Icons.save : Icons.add),
                        label: Text(
                          isEdit ? 'Cập nhật sản phẩm' : 'Thêm sản phẩm',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info note
                    if (isEdit)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lưu ý: Khi cập nhật giá, lịch sử đơn hàng vẫn giữ giá cũ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagesSection() {
    final totalImages = _existingImageUrls.length + _newImages.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hình ảnh sản phẩm ($totalImages)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _pickCamera,
                      tooltip: 'Chụp ảnh',
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: _pickImages,
                      tooltip: 'Chọn từ thư viện',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (totalImages == 0)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Thêm ảnh sản phẩm',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing images from server
                    ..._existingImageUrls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final imageUrl = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl:
                                    ImageUtils.normalizeImageUrl(imageUrl) ??
                                        '',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (index == 0 && _newImages.isEmpty)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Ảnh chính',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    // New images to upload
                    ..._newImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final image = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(image.path),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeNewImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (index == 0 && _existingImageUrls.isEmpty)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Ảnh chính',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Mới',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
