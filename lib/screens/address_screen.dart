import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_new.dart';
import '../models/address.dart';
import '../services/api_service.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🏠 AddressScreen initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  Future<void> _loadAddresses() async {
    print('🔄 _loadAddresses called');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('✅ AuthProvider found, user ID: ${authProvider.currentUser?.id}');

      if (authProvider.currentUser?.id != null) {
        print('📍 Loading addresses from API...');
        final addressesData =
            await ApiService.getUserAddresses(authProvider.currentUser!.id!);
        print('✅ API returned ${addressesData.length} addresses');

        _addresses =
            addressesData.map((item) => Address.fromJson(item)).toList();
        print('✅ Parsed ${_addresses.length} addresses');
      } else {
        print('❌ No user ID - user not logged in');
        _errorMessage = 'Vui lòng đăng nhập';
      }

      setState(() {
        _isLoading = false;
      });
      print('✅ _loadAddresses completed');
    } catch (e, stackTrace) {
      print('❌ ERROR in _loadAddresses: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách địa chỉ: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 AddressScreen build() called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addAddress,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAddress,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAddresses,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_addresses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có địa chỉ nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Thêm địa chỉ để giao hàng',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(address.recipientName ?? 'Không có tên'),
            subtitle: Text('${address.phone ?? ''}\n${address.fullAddress}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (address.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Mặc định',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Sửa'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editAddress(address);
                    } else if (value == 'delete') {
                      _deleteAddress(address.id);
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).pop(address);
            },
          ),
        );
      },
    );
  }

  Future<void> _addAddress() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditAddressScreen(),
      ),
    );

    if (result == true) {
      _loadAddresses();
    }
  }

  Future<void> _editAddress(Address address) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditAddressScreen(address: address),
      ),
    );

    if (result == true) {
      _loadAddresses();
    }
  }

  Future<void> _deleteAddress(int addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ'),
        content: const Text('Bạn có chắc chắn muốn xóa địa chỉ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement delete address API endpoint
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Chức năng xóa địa chỉ chưa được triển khai trên backend'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi xóa địa chỉ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _recipientNameController.text = widget.address!.recipientName ?? '';
      _phoneController.text = widget.address!.phone ?? '';
      _addressLine1Controller.text = widget.address!.addressLine1 ?? '';
      _addressLine2Controller.text = widget.address!.addressLine2 ?? '';
      _wardController.text = widget.address!.ward ?? '';
      _districtController.text = widget.address!.district ?? '';
      _cityController.text = widget.address!.city ?? '';
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Thêm địa chỉ' : 'Sửa địa chỉ'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAddress,
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
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
              TextFormField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên người nhận',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressLine1Controller,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ (Số nhà, tên đường)',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressLine2Controller,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ bổ sung (Tòa nhà, căn hộ...)',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _wardController,
                      decoration: const InputDecoration(
                        labelText: 'Phường/Xã',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: 'Quận/Huyện',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Tỉnh/Thành phố',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tỉnh/thành phố';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Đặt làm địa chỉ mặc định'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.address == null
                              ? 'Thêm địa chỉ'
                              : 'Cập nhật địa chỉ',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('💾 Starting to save address...');

      // Get AuthProvider before async operations
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      print('✅ Got AuthProvider, user ID: $userId');

      if (userId == null) {
        print('❌ No user ID found');
        throw Exception('Vui lòng đăng nhập');
      }

      final addressData = {
        'recipient_name': _recipientNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address_line1': _addressLine1Controller.text.trim(),
        'address_line2': _addressLine2Controller.text.trim(),
        'ward': _wardController.text.trim(),
        'district': _districtController.text.trim(),
        'city': _cityController.text.trim(),
        'country': 'Vietnam',
        'is_default': _isDefault,
      };

      print('💾 Saving address via API: $addressData');

      final result = await ApiService.createAddress(
        userId: userId,
        addressData: addressData,
      );

      if (!mounted) return; // Check mounted before using context

      if (result != null) {
        print('✅ Address saved successfully: $result');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Địa chỉ đã được lưu thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a bit then pop
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Không thể lưu địa chỉ');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR saving address: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu địa chỉ: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
}
