import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../services/admin_api_service.dart';
import 'admin_add_voucher_screen_new.dart';

class AdminVoucherDashboardScreen extends StatefulWidget {
  const AdminVoucherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminVoucherDashboardScreen> createState() => _AdminVoucherDashboardScreenState();
}

class _AdminVoucherDashboardScreenState extends State<AdminVoucherDashboardScreen> {
  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _filteredVouchers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, expired, expiring_soon
  String _typeFilter = 'all'; // all, percentage, fixed_amount, free_shipping

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await AdminApiService.getAdminVouchers();
      
      if (result['success'] == true) {
        setState(() {
          _vouchers = List<Map<String, dynamic>>.from(result['vouchers'] ?? []);
          _applyFilters();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Lỗi tải dữ liệu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    
    _filteredVouchers = _vouchers.where((voucher) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final code = (voucher['code'] ?? '').toLowerCase();
        final name = (voucher['name'] ?? '').toLowerCase();
        final description = (voucher['description'] ?? '').toLowerCase();
        
        if (!code.contains(query) && !name.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != 'all') {
        final isActive = voucher['is_active'] == true;
        final endDate = DateTime.parse(voucher['end_date']);
        final daysUntilExpiry = endDate.difference(now).inDays;
        
        if (_statusFilter == 'active' && (!isActive || endDate.isBefore(now))) {
          return false;
        }
        if (_statusFilter == 'expired' && (isActive && endDate.isAfter(now))) {
          return false;
        }
        if (_statusFilter == 'expiring_soon' && (daysUntilExpiry > 7 || daysUntilExpiry < 0)) {
          return false;
        }
      }

      // Type filter
      if (_typeFilter != 'all' && voucher['discount_type'] != _typeFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  String _getVoucherStatus(Map<String, dynamic> voucher) {
    final now = DateTime.now();
    final startDate = DateTime.parse(voucher['start_date']);
    final endDate = DateTime.parse(voucher['end_date']);
    final isActive = voucher['is_active'] == true;
    
    if (!isActive) return 'Đã tắt';
    if (endDate.isBefore(now)) return 'Hết hạn';
    if (startDate.isAfter(now)) return 'Chưa bắt đầu';
    
    final daysUntilExpiry = endDate.difference(now).inDays;
    if (daysUntilExpiry <= 7) return 'Sắp hết hạn';
    
    return 'Đang hoạt động';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang hoạt động':
        return Colors.green;
      case 'Sắp hết hạn':
        return Colors.orange;
      case 'Hết hạn':
      case 'Đã tắt':
        return Colors.red;
      case 'Chưa bắt đầu':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Đang hoạt động':
        return Icons.check_circle;
      case 'Sắp hết hạn':
        return Icons.warning;
      case 'Hết hạn':
      case 'Đã tắt':
        return Icons.cancel;
      case 'Chưa bắt đầu':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _getDiscountTypeLabel(String type) {
    switch (type) {
      case 'percentage':
        return '% Giảm giá';
      case 'fixed_amount':
        return 'Số tiền cố định';
      case 'free_shipping':
        return 'Miễn phí ship';
      default:
        return type;
    }
  }

  String _getDiscountValue(Map<String, dynamic> voucher) {
    final type = voucher['discount_type'];
    final value = voucher['discount_value'];
    
    if (type == 'percentage') {
      return '$value%';
    } else if (type == 'fixed_amount') {
      return NumberFormat('#,##0đ').format(value);
    } else {
      return 'Miễn phí';
    }
  }

  Future<void> _deleteVoucher(int voucherId) async {
    try {
      final result = await AdminApiService.deleteVoucher(voucherId);
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa voucher thành công')),
          );
          _loadVouchers();
        }
      } else {
        throw Exception(result['error'] ?? 'Không thể xóa voucher');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _toggleVoucherStatus(Map<String, dynamic> voucher) async {
    try {
      final voucherData = {
        'code': voucher['code'],
        'name': voucher['name'],
        'description': voucher['description'],
        'discount_type': voucher['discount_type'],
        'discount_value': voucher['discount_value'],
        'min_order_amount': voucher['min_order_amount'],
        'max_discount_amount': voucher['max_discount_amount'],
        'usage_limit': voucher['usage_limit'],
        'user_limit': voucher['user_limit'],
        'start_date': voucher['start_date'],
        'end_date': voucher['end_date'],
        'is_active': !(voucher['is_active'] ?? false),
      };
      
      final result = await AdminApiService.updateVoucher(voucher['id'], voucherData);
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật trạng thái thành công')),
          );
          _loadVouchers();
        }
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
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.discount, color: Colors.amber.shade400),
            const SizedBox(width: 8),
            const Text(
              'Quản lý Voucher',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadVouchers,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFilters()),
          SliverToBoxAdapter(child: _buildStatsSummary()),
          _buildVoucherList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAddVoucherScreenNew(),
            ),
          );
          if (result == true) {
            _loadVouchers();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo voucher mới'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tìm mã, tên chương trình hoặc mô tả...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Bộ lọc',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Tất cả',
                isSelected: _statusFilter == 'all',
                onTap: () => _updateStatusFilter('all'),
                color: Colors.grey,
              ),
              _buildFilterChip(
                label: '🔵 Đang hoạt động',
                isSelected: _statusFilter == 'active',
                onTap: () => _updateStatusFilter('active'),
                color: Colors.green,
              ),
              _buildFilterChip(
                label: '🔴 Hết hạn',
                isSelected: _statusFilter == 'expired',
                onTap: () => _updateStatusFilter('expired'),
                color: Colors.red,
              ),
              _buildFilterChip(
                label: '🟡 Sắp hết hạn',
                isSelected: _statusFilter == 'expiring_soon',
                onTap: () => _updateStatusFilter('expiring_soon'),
                color: Colors.orange,
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Tất cả loại',
                isSelected: _typeFilter == 'all',
                onTap: () => _updateTypeFilter('all'),
                color: Colors.grey,
              ),
              _buildFilterChip(
                label: '% Giảm giá',
                isSelected: _typeFilter == 'percentage',
                onTap: () => _updateTypeFilter('percentage'),
                color: Colors.purple,
              ),
              _buildFilterChip(
                label: 'Số tiền',
                isSelected: _typeFilter == 'fixed_amount',
                onTap: () => _updateTypeFilter('fixed_amount'),
                color: Colors.blue,
              ),
              _buildFilterChip(
                label: 'Miễn phí ship',
                isSelected: _typeFilter == 'free_shipping',
                onTap: () => _updateTypeFilter('free_shipping'),
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _updateStatusFilter(String filter) {
    setState(() {
      _statusFilter = filter;
      _applyFilters();
    });
  }

  void _updateTypeFilter(String filter) {
    setState(() {
      _typeFilter = filter;
      _applyFilters();
    });
  }

  Widget _buildStatsSummary() {
    final totalVouchers = _vouchers.length;
    final activeVouchers = _vouchers.where((v) => _getVoucherStatus(v) == 'Đang hoạt động').length;
    final expiredVouchers = _vouchers.where((v) => _getVoucherStatus(v) == 'Hết hạn').length;
    final expiringSoon = _vouchers.where((v) => _getVoucherStatus(v) == 'Sắp hết hạn').length;
    
    final totalUsed = _vouchers.fold<int>(0, (sum, v) => sum + (v['used_count'] as int? ?? 0));
    final totalLimit = _vouchers.fold<int>(0, (sum, v) => sum + (v['usage_limit'] as int? ?? 0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.purple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.amber.shade400),
              const SizedBox(width: 8),
              const Text(
                'Tổng quan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tổng voucher',
                  totalVouchers.toString(),
                  Icons.discount,
                  Colors.blue.shade300,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Đang hoạt động',
                  activeVouchers.toString(),
                  Icons.check_circle,
                  Colors.green.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sắp hết hạn',
                  expiringSoon.toString(),
                  Icons.warning,
                  Colors.orange.shade300,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Hết hạn',
                  expiredVouchers.toString(),
                  Icons.cancel,
                  Colors.red.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng lượt sử dụng',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalUsed / $totalLimit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                CircularProgressIndicator(
                  value: totalLimit > 0 ? totalUsed / totalLimit : 0,
                  backgroundColor: Colors.grey.shade700,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade400),
                  strokeWidth: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_filteredVouchers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 80, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty || _statusFilter != 'all' || _typeFilter != 'all'
                    ? 'Không tìm thấy voucher phù hợp'
                    : 'Chưa có voucher nào',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final voucher = _filteredVouchers[index];
            return _buildVoucherCard(voucher);
          },
          childCount: _filteredVouchers.length,
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final status = _getVoucherStatus(voucher);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final usedCount = voucher['used_count'] ?? 0;
    final usageLimit = voucher['usage_limit'] ?? 0;
    final usagePercent = usageLimit > 0 ? usedCount / usageLimit : 0.0;

    return Card(
      color: const Color(0xFF212121),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminAddVoucherScreenNew(voucher: voucher),
            ),
          );
          if (result == true) {
            _loadVouchers();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                voucher['code'] ?? '',
                                style: TextStyle(
                                  color: Colors.blue.shade200,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: statusColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          voucher['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (voucher['description'] != null && voucher['description'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            voucher['description'],
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                    color: Colors.grey.shade800,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue.shade300, size: 20),
                            const SizedBox(width: 8),
                            const Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              voucher['is_active'] ? Icons.visibility_off : Icons.visibility,
                              color: Colors.orange.shade300,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              voucher['is_active'] ? 'Tắt voucher' : 'Bật voucher',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red.shade300, size: 20),
                            const SizedBox(width: 8),
                            const Text('Xóa', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminAddVoucherScreenNew(voucher: voucher),
                          ),
                        );
                        if (result == true) {
                          _loadVouchers();
                        }
                      } else if (value == 'toggle') {
                        _toggleVoucherStatus(voucher);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.grey.shade900,
                            title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
                            content: Text(
                              'Bạn có chắc muốn xóa voucher "${voucher['code']}"?',
                              style: TextStyle(color: Colors.grey.shade300),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Hủy', style: TextStyle(color: Colors.grey.shade400)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          _deleteVoucher(voucher['id']);
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            Icons.local_offer,
                            'Loại',
                            _getDiscountTypeLabel(voucher['discount_type']),
                            Colors.purple.shade300,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            Icons.confirmation_number,
                            'Giảm',
                            _getDiscountValue(voucher),
                            Colors.green.shade300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildInfoRow(
                            Icons.shopping_cart,
                            'Đơn tối thiểu',
                            voucher['min_order_amount'] != null
                                ? NumberFormat('#,##0').format(voucher['min_order_amount'])
                                : 'Không',
                            Colors.blue.shade300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildInfoRow(
                            Icons.calendar_today,
                            'Hết hạn',
                            DateFormat('dd/MM').format(DateTime.parse(voucher['end_date'])),
                            Colors.orange.shade300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã sử dụng: $usedCount / $usageLimit',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(usagePercent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: usagePercent,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePercent >= 0.9
                            ? Colors.red
                            : usagePercent >= 0.7
                                ? Colors.orange
                                : Colors.green,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
