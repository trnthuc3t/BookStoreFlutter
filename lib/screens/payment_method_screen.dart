import 'package:flutter/material.dart';
import '../models/payment_method.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  List<PaymentMethod> _paymentMethods = [];
  int _selectedMethodId = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    // Mock data - in real app, load from Firebase
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _paymentMethods = [
        PaymentMethod(
          id: 1,
          name: 'Tiền mặt',
          description: 'Thanh toán khi nhận hàng',
          icon: 'cash',
          isActive: true,
        ),
        PaymentMethod(
          id: 2,
          name: 'ZaloPay',
          description: 'Thanh toán qua ZaloPay',
          icon: 'zalopay',
          isActive: true,
        ),
        PaymentMethod(
          id: 3,
          name: 'Chuyển khoản',
          description: 'Chuyển khoản ngân hàng',
          icon: 'bank',
          isActive: true,
        ),
        PaymentMethod(
          id: 4,
          name: 'Thẻ tín dụng',
          description: 'Visa, Mastercard',
          icon: 'credit_card',
          isActive: true,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phương thức thanh toán'),
        actions: [
          TextButton(
            onPressed: _selectedMethodId != 0 ? _selectMethod : null,
            child: const Text('Chọn'),
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

    if (_paymentMethods.isEmpty) {
      return const Center(
        child: Text('Không có phương thức thanh toán nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final method = _paymentMethods[index];
        return _buildPaymentMethodCard(method);
      },
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedMethodId == method.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethodId = method.id;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getPaymentIcon(method.icon),
                  color: isSelected ? Colors.blue : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Method info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.description ?? '',
                      style: TextStyle(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Radio button
              Radio<int>(
                value: method.id,
                groupValue: _selectedMethodId,
                onChanged: (value) {
                  setState(() {
                    _selectedMethodId = value ?? 0;
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String? icon) {
    switch (icon) {
      case 'cash':
        return Icons.money;
      case 'zalopay':
        return Icons.payment;
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  void _selectMethod() {
    if (_selectedMethodId != 0) {
      final selectedMethod = _paymentMethods.firstWhere(
        (method) => method.id == _selectedMethodId,
      );
      Navigator.of(context).pop(selectedMethod.name);
    }
  }
}
