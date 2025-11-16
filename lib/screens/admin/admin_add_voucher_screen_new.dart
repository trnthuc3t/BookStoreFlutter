import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_api_service.dart';

class AdminAddVoucherScreenNew extends StatefulWidget {
  final Map<String, dynamic>? voucher;

  const AdminAddVoucherScreenNew({super.key, this.voucher});

  @override
  State<AdminAddVoucherScreenNew> createState() => _AdminAddVoucherScreenNewState();
}

class _AdminAddVoucherScreenNewState extends State<AdminAddVoucherScreenNew> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _usageLimitController = TextEditingController();
  final _userLimitController = TextEditingController();
  
  // State
  String _discountType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.voucher != null) {
      _loadVoucherData();
    } else {
      // Default values for new voucher
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
      _userLimitController.text = '1';
    }
  }

  void _loadVoucherData() {
    final v = widget.voucher!;
    _codeController.text = v['code'] ?? '';
    _nameController.text = v['name'] ?? '';
    _descriptionController.text = v['description'] ?? '';
    _discountType = v['discount_type'] ?? 'percentage';
    _discountValueController.text = (v['discount_value'] ?? 0).toString();
    _minOrderController.text = (v['min_order_amount'] ?? 0).toString();
    _maxDiscountController.text = (v['max_discount_amount'] ?? '').toString();
    _usageLimitController.text = (v['usage_limit'] ?? '').toString();
    _userLimitController.text = (v['user_limit'] ?? 1).toString();
    _isActive = v['is_active'] ?? true;
    
    if (v['start_date'] != null) {
      _startDate = DateTime.parse(v['start_date']);
    }
    if (v['end_date'] != null) {
      _endDate = DateTime.parse(v['end_date']);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    _userLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và kết thúc')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final voucherData = {
        'code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'discount_type': _discountType,
        'discount_value': double.parse(_discountValueController.text),
        'min_order_amount': _minOrderController.text.isEmpty
            ? 0
            : double.parse(_minOrderController.text),
        'max_discount_amount': _maxDiscountController.text.isEmpty
            ? null
            : double.parse(_maxDiscountController.text),
        'usage_limit': _usageLimitController.text.isEmpty
            ? null
            : int.parse(_usageLimitController.text),
        'user_limit': int.parse(_userLimitController.text),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'is_active': _isActive,
      };

      final isEdit = widget.voucher != null;
      
      final result = isEdit
          ? await AdminApiService.updateVoucher(widget.voucher!['id'], voucherData)
          : await AdminApiService.createVoucher(voucherData);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Cập nhật voucher thành công' : 'Tạo voucher thành công'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          throw Exception(result['error'] ?? 'Lỗi không xác định');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.voucher == null ? 'Tạo voucher mới' : 'Sửa voucher'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveVoucher,
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
              // Code
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã voucher *',
                  hintText: 'VD: WELCOME10',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: widget.voucher == null, // Can't edit code
                validator: (v) => v == null || v.trim().isEmpty ? 'Nhập mã voucher' : null,
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên voucher *',
                  hintText: 'VD: Chào mừng khách hàng mới',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên voucher' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Mô tả chi tiết về voucher',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Discount Type
              DropdownButtonFormField<String>(
                value: _discountType,
                decoration: const InputDecoration(
                  labelText: 'Loại giảm giá *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Giảm % (Percentage)')),
                  DropdownMenuItem(value: 'fixed_amount', child: Text('Giảm cố định (Fixed Amount)')),
                  DropdownMenuItem(value: 'free_shipping', child: Text('Miễn phí ship (Free Shipping)')),
                ],
                onChanged: (v) => setState(() => _discountType = v!),
              ),
              const SizedBox(height: 16),

              // Discount Value
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(
                  labelText: _discountType == 'percentage' ? 'Giảm % *' : 'Giảm (VNĐ) *',
                  hintText: _discountType == 'percentage' ? '10' : '50000',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập giá trị giảm';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Giá trị phải > 0';
                  if (_discountType == 'percentage' && val > 100) return '% giảm phải <= 100';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Min Order & Max Discount
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Đơn tối thiểu (VNĐ)',
                        hintText: '100000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxDiscountController,
                      decoration: const InputDecoration(
                        labelText: 'Giảm tối đa (VNĐ)',
                        hintText: '50000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Usage Limits
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _usageLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Tổng lượt dùng',
                        hintText: '1000 (để trống = không giới hạn)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _userLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Lượt/user *',
                        hintText: '1',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập lượt/user';
                        final val = int.tryParse(v);
                        if (val == null || val <= 0) return 'Phải > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Start Date
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày bắt đầu *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}'
                        : 'Chọn ngày',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Date
              InkWell(
                onTap: _selectEndDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày kết thúc *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _endDate != null
                        ? '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                        : 'Chọn ngày',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active Switch
              SwitchListTile(
                title: const Text('Kích hoạt voucher'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVoucher,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.voucher == null ? 'Tạo voucher' : 'Cập nhật voucher'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
