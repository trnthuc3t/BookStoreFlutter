import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_api_service.dart';
import 'admin_add_voucher_screen_new.dart';

class AdminVoucherScreenNew extends StatefulWidget {
  const AdminVoucherScreenNew({super.key});

  @override
  State<AdminVoucherScreenNew> createState() => _AdminVoucherScreenNewState();
}

class _AdminVoucherScreenNewState extends State<AdminVoucherScreenNew> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      final result = await AdminApiService.getAdminVouchers();
      
      if (result['success'] == true) {
        setState(() {
          _vouchers = List<Map<String, dynamic>>.from(result['vouchers'] ?? []);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Lỗi tải voucher'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải voucher: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredVouchers() {
    if (_searchQuery.isEmpty) return _vouchers;
    return _vouchers.where((v) {
      final code = (v['code'] ?? '').toString().toLowerCase();
      final name = (v['name'] ?? '').toString().toLowerCase();
      final desc = (v['description'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return code.contains(query) || name.contains(query) || desc.contains(query);
    }).toList();
  }

  Future<void> _deleteVoucher(Map<String, dynamic> voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa voucher'),
        content: Text('Bạn có chắc muốn xóa voucher "${voucher['code']}"?\n\nLưu ý: Không thể xóa voucher đã được sử dụng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await AdminApiService.deleteVoucher(voucher['id']);
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa voucher thành công'), backgroundColor: Colors.green),
          );
          _loadVouchers();
        }
      } else {
        throw Exception(result['error'] ?? 'Không thể xóa voucher');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> voucher) async {
    final newActive = !(voucher['is_active'] ?? true);
    try {
      final voucherData = {...voucher, 'is_active': newActive};
      final result = await AdminApiService.updateVoucher(voucher['id'], voucherData);
      
      if (result['success'] == true) {
        _loadVouchers();
      } else {
        throw Exception(result['error'] ?? 'Không thể cập nhật voucher');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVouchers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm mã, tên voucher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Voucher list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildVoucherList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAddVoucherScreenNew()),
          );
          if (result == true) _loadVouchers();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo voucher'),
      ),
    );
  }

  Widget _buildVoucherList() {
    final filtered = _getFilteredVouchers();
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Chưa có voucher' : 'Không tìm thấy voucher',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildVoucherCard(filtered[index]),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final isActive = voucher['is_active'] ?? false;
    final discountType = voucher['discount_type'] ?? 'percentage';
    final discountValue = (voucher['discount_value'] ?? 0).toDouble();
    final usedCount = voucher['used_count'] ?? 0;
    final usageLimit = voucher['usage_limit'];
    final remainingUses = voucher['remaining_uses'];
    
    // Format dates
    String formatDate(String? dateStr) {
      if (dateStr == null) return '';
      try {
        final date = DateTime.parse(dateStr);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        return '';
      }
    }

    final startDate = formatDate(voucher['start_date']);
    final endDate = formatDate(voucher['end_date']);
    final isExpired = voucher['end_date'] != null && DateTime.parse(voucher['end_date']).isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminAddVoucherScreenNew(voucher: voucher),
            ),
          );
          if (result == true) _loadVouchers();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Code + Status
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.orange : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            voucher['code'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isExpired ? Colors.red : AppTheme.successColor)
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isExpired ? 'Hết hạn' : (isActive ? 'Hoạt động' : 'Tắt'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminAddVoucherScreenNew(voucher: voucher),
                          ),
                        ).then((result) {
                          if (result == true) _loadVouchers();
                        });
                      } else if (value == 'toggle') {
                        _toggleActive(voucher);
                      } else if (value == 'delete') {
                        _deleteVoucher(voucher);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                voucher['name'] ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (voucher['description'] != null && voucher['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  voucher['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),

              // Discount info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.discount, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          discountType == 'percentage'
                              ? 'Giảm ${discountValue.toStringAsFixed(0)}%'
                              : discountType == 'fixed_amount'
                                  ? 'Giảm ${(discountValue / 1000).toStringAsFixed(0)}k'
                                  : 'Miễn phí ship',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Đơn tối thiểu: ${((voucher['min_order_amount'] ?? 0) / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (voucher['max_discount_amount'] != null)
                          Text(
                            'Giảm tối đa: ${((voucher['max_discount_amount']) / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Usage & Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 Đã dùng: $usedCount${usageLimit != null ? '/$usageLimit' : ''}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (remainingUses != null)
                          Text(
                            'Còn lại: $remainingUses lần',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('📅 $startDate - $endDate', style: const TextStyle(fontSize: 12)),
                      Text(
                        'User limit: ${voucher['user_limit']}/người',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
