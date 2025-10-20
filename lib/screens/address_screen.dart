import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/address.dart';
import '../widgets/address_list_widget.dart';

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
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (authProvider.currentUser?.email != null) {
        // Load addresses from Firebase
        final snapshot = await orderProvider.addressRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          _addresses = data.values
              .map((item) => Address.fromJson(Map<String, dynamic>.from(item)))
              .where((address) => address.userEmail == authProvider.currentUser!.email)
              .toList();
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách địa chỉ: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return AddressListWidget(
      addresses: _addresses,
      onAddressSelected: (address) {
        Navigator.of(context).pop('${address.name} - ${address.address}');
      },
      onAddressDeleted: (addressId) {
        _deleteAddress(addressId);
      },
      onAddressEdited: (address) {
        _editAddress(address);
      },
    );
  }

  Future<void> _addAddress() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(),
      ),
    );

    if (result == true) {
      _loadAddresses();
    }
  }

  Future<void> _editAddress(Address address) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(address: address),
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
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.removeData('address/$addressId');
        _loadAddresses();
      } catch (e) {
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

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _nameController.text = widget.address!.name ?? '';
      _phoneController.text = widget.address!.phone ?? '';
      _addressController.text = widget.address!.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
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
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ chi tiết',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.address == null ? 'Thêm địa chỉ' : 'Cập nhật địa chỉ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);

        if (authProvider.currentUser?.email != null) {
          final address = Address(
            id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            userEmail: authProvider.currentUser!.email!,
          );

          await orderProvider.setData('address/${address.id}', address.toJson());

          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi lưu địa chỉ: ${e.toString()}'),
              backgroundColor: Colors.red,
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
}
