import 'package:flutter/material.dart';
import '../../models/voucher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class AdminAddVoucherScreen extends StatefulWidget {
  final Voucher? voucher;

  const AdminAddVoucherScreen({super.key, this.voucher});

  @override
  State<AdminAddVoucherScreen> createState() => _AdminAddVoucherScreenState();
}

class _AdminAddVoucherScreenState extends State<AdminAddVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxUsesController = TextEditingController();
  final _expiryDateController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    if (widget.voucher != null) {
      _codeController.text = widget.voucher!.code ?? '';
      _descriptionController.text = widget.voucher!.description ?? '';
      _discountController.text = widget.voucher!.discount.toString();
      _minPriceController.text = widget.voucher!.minPrice.toString();
      _maxUsesController.text = widget.voucher!.maxUses.toString();
      _isActive = widget.voucher!.isActive;
      if (widget.voucher!.expiryDate != null) {
        _expiryDate = widget.voucher!.expiryDate;
        _expiryDateController.text = _formatDate(widget.voucher!.expiryDate!);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minPriceController.dispose();
    _maxUsesController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create voucher object
      Voucher(
        id: widget.voucher?.id ?? 0,
        code: _codeController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim(),
        discount: int.tryParse(_discountController.text) ?? 0,
        minPrice: int.tryParse(_minPriceController.text) ?? 0,
        maxUses: int.tryParse(_maxUsesController.text) ?? 1,
        remainingUses: widget.voucher?.remainingUses ?? (int.tryParse(_maxUsesController.text) ?? 1),
        isActive: _isActive,
        expiryDate: _expiryDate,
      );

      // TODO: Implement save voucher
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.voucher == null ? 'Thêm voucher thành công' : 'Cập nhật voucher thành công'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppTheme.errorColor,
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

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _expiryDate = date;
        _expiryDateController.text = _formatDate(date);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.voucher == null ? 'Thêm voucher' : 'Sửa voucher'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveVoucher,
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
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã voucher *',
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: SALE20',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã voucher';
                  }
                  if (value.trim().length < 3) {
                    return 'Mã voucher phải có ít nhất 3 ký tự';
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
                  hintText: 'Mô tả voucher...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Giảm giá (%) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập % giảm giá';
                        }
                        final discount = int.tryParse(value);
                        if (discount == null || discount <= 0 || discount > 100) {
                          return 'Giảm giá phải từ 1-100%';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Đơn tối thiểu (VNĐ) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập đơn tối thiểu';
                        }
                        final minPrice = int.tryParse(value);
                        if (minPrice == null || minPrice < 0) {
                          return 'Đơn tối thiểu phải >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Số lần sử dụng tối đa *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số lần sử dụng';
                  }
                  final maxUses = int.tryParse(value);
                  if (maxUses == null || maxUses <= 0) {
                    return 'Số lần sử dụng phải > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(
                  labelText: 'Ngày hết hạn',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectExpiryDate,
                  ),
                ),
                readOnly: true,
                onTap: _selectExpiryDate,
              ),
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Kích hoạt voucher'),
                value: _isActive,
                onChanged: (bool? value) {
                  setState(() {
                    _isActive = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              
              CustomButton(
                text: widget.voucher == null ? 'Thêm voucher' : 'Cập nhật voucher',
                onPressed: _isLoading ? null : _saveVoucher,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
