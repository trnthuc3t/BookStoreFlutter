import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/voucher.dart';
import '../../theme/app_theme.dart';
import 'admin_add_voucher_screen.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadVouchers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Voucher> _getFilteredVouchers(List<Voucher> vouchers) {
    if (_searchQuery.isEmpty) return vouchers;
    return vouchers.where((voucher) =>
        (voucher.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (voucher.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý voucher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAddVoucherScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm voucher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vouchers = _getFilteredVouchers(orderProvider.vouchers);

                if (vouchers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Chưa có voucher nào'
                              : 'Không tìm thấy voucher',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: voucher.isActive ? AppTheme.successColor : AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          voucher.code ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (voucher.description != null)
                              Text(voucher.description!),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Giảm: ${voucher.discount}%'),
                                const SizedBox(width: 16),
                                Text('Tối thiểu: ${voucher.minPrice.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},',
                                )} VNĐ'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Còn lại: ${voucher.remainingUses} lần'),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: voucher.isActive ? AppTheme.successColor : AppTheme.errorColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    voucher.isActive ? 'Hoạt động' : 'Không hoạt động',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminAddVoucherScreen(
                                      voucher: voucher,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(voucher),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAddVoucherScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa voucher'),
        content: Text('Bạn có chắc chắn muốn xóa voucher "${voucher.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete voucher
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xóa voucher thành công')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
