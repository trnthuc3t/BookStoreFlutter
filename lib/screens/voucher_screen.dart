import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/voucher.dart';
import '../widgets/voucher_list_widget.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.loadVouchers();
      
      setState(() {
        _vouchers = orderProvider.vouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách voucher: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher & Khuyến mãi'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text('Bỏ qua'),
          ),
        ],
      ),
      body: _buildBody(),
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
              onPressed: _loadVouchers,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_vouchers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có voucher nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Hiện tại chưa có voucher khuyến mãi',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return VoucherListWidget(
      vouchers: _vouchers,
      onVoucherSelected: (voucher) {
        Navigator.of(context).pop(voucher.name);
      },
    );
  }
}
