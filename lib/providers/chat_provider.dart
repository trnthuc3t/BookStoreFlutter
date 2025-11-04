import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/feedback.dart';
import '../services/gemini_service.dart';
import '../services/api_service.dart';
import '../providers/product_provider_new.dart' as api_providers;
import '../providers/order_provider_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ChatProvider with ChangeNotifier {
  final GeminiService _geminiService = GeminiService.instance;

  List<Message> _messages = [];
  List<Feedback> _feedbacks = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCreatingOrder = false;
  int _orderStep = 0;

  // Order creation state
  String _customerName = '';
  String _customerPhone = '';
  String _customerAddress = '';
  List<Map<String, dynamic>> _selectedProducts = [];
  int? _userId;

  List<Message> get messages => _messages;
  List<Feedback> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCreatingOrder => _isCreatingOrder;
  int get orderStep => _orderStep;

  Future<void> initialize(String userEmail, {int? userId}) async {
    _userId = userId;
    _isLoading = false; // Reset loading state
    _errorMessage = null; // Clear any errors
    _messages = await _loadChatHistory(userEmail);

    // Add welcome message if no history
    if (_messages.isEmpty) {
      _addBotMessage('Chào bạn! 👋 Mình là trợ lý AI của BookStore.\n\n'
          '✨ Mình có thể giúp bạn:\n\n'
          '📚 Tìm & tư vấn sách hay\n'
          '🛒 Đặt hàng siêu nhanh (chỉ cần nói: "Mua Đắc Nhân Tâm 2 cuốn")\n'
          '📦 Kiểm tra đơn hàng\n'
          '💰 Xem voucher & khuyến mãi\n'
          '⭐ Đọc review & đánh giá\n\n'
          'Bạn muốn tìm sách gì? 😊');
    }

    notifyListeners();
  }

  Future<void> sendMessage(
    String content,
    String userEmail, {
    int? userId,
    api_providers.ProductApiProvider? productProvider,
    OrderProvider? orderProvider,
  }) async {
    print('📨 ChatProvider: sendMessage called with: "$content"');
    print(
        '👤 User ID: $userId, Is Creating Order: $_isCreatingOrder, Loading: $_isLoading');

    _userId = userId;
    _addUserMessage(content);

    // Check if we're in order creation mode
    if (_isCreatingOrder) {
      print('🛒 Processing order step: $_orderStep');
      await _processOrderStep(
          content, userEmail, orderProvider, productProvider);
      return;
    }

    // Check if user wants to create order using AI
    final lowerContent = content.toLowerCase();
    if (lowerContent.contains('đặt hàng') ||
        lowerContent.contains('tạo đơn') ||
        lowerContent.contains('mua sách') ||
        lowerContent.contains('đặt mua') ||
        lowerContent.contains('mua')) {
      _startSmartOrderCreation(content, productProvider);
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get context data
      final products = productProvider?.products ?? [];
      final categories = productProvider?.categories ?? [];
      final userOrders = orderProvider?.userOrders ?? [];
      final vouchers = orderProvider?.vouchers ?? [];
      final feedbacks = <Feedback>[]; // TODO: Load feedbacks

      final response = await _geminiService.generateResponse(
        content,
        products: products,
        categories: categories,
        userOrders: userOrders,
        vouchers: vouchers,
        feedbacks: feedbacks,
        userEmail: userEmail,
      );

      _addBotMessage(response);
      await _saveChatHistory(userEmail);
    } catch (e) {
      _addBotMessage('Xin lỗi, có lỗi xảy ra. Vui lòng thử lại!');
    } finally {
      _setLoading(false);
    }
  }

  void _startOrderCreation() {
    _isCreatingOrder = true;
    _orderStep = 1;
    _selectedProducts.clear();

    _addBotMessage(
        '🛒 Bắt đầu tạo đơn hàng!\n\nBước 1: Vui lòng cho tôi biết họ tên của bạn:');
    notifyListeners();
  }

  Future<void> _startSmartOrderCreation(String userMessage,
      api_providers.ProductApiProvider? productProvider) async {
    _isCreatingOrder = true;
    _orderStep = 1;
    _selectedProducts.clear();

    _setLoading(true);

    try {
      // Use both regex and AI for better accuracy
      final products = productProvider?.products ?? [];
      final parsedProducts =
          await _parseProductsFromMessage(userMessage, products);

      if (parsedProducts.isNotEmpty) {
        _selectedProducts = parsedProducts;
        _addBotMessage('✅ Mình hiểu rồi! Bạn muốn đặt:\n\n'
            '${_formatSelectedProducts()}\n\n'
            'Để hoàn tất, cho mình biết:\n'
            '📝 Họ tên của bạn:');
      } else {
        _addBotMessage('🛒 OK! Bắt đầu đặt hàng nhé.\n\n'
            '📝 Họ tên của bạn:');
      }
    } catch (e) {
      _addBotMessage('🛒 Bắt đầu tạo đơn hàng!\n\n'
          '📝 Họ tên của bạn:');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _parseProductsFromMessage(
      String message, List<dynamic> products) async {
    final result = <Map<String, dynamic>>[];
    final lowerMessage = message.toLowerCase();

    // Method 1: Simple string matching (fast, works for exact names)
    // Search for ALL matching products in the message
    for (var product in products) {
      if (product.name == null) continue;

      final productName = product.name!.toLowerCase();

      if (lowerMessage.contains(productName)) {
        int quantity = 1;

        // Try to find quantity near the product name
        // Patterns: "2 cuốn", "3 quyển", "5 bộ", etc.
        final quantityPattern = RegExp(
          r'(\d+)\s*(?:cuốn|quyển|cái|bộ|cuon|quyen)',
          caseSensitive: false,
        );
        final matches = quantityPattern.allMatches(message);

        // Use the first number found as quantity, default to 1
        if (matches.isNotEmpty) {
          quantity = int.tryParse(matches.first.group(1) ?? '1') ?? 1;
        }

        result.add({
          'id': product.id,
          'name': product.name,
          'price': product.realPrice ?? 0,
          'quantity': quantity,
          'image': product.image ?? '',
        });
        break; // Found product, stop searching (avoid duplicates)
      }
    }

    // Method 2: If no exact match, use AI to understand intent
    if (result.isEmpty && products.isNotEmpty) {
      try {
        final aiResult = await _parseOrderWithAI(message, products);
        result.addAll(aiResult);
      } catch (e) {
        print('AI parsing failed: $e');
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _parseOrderWithAI(
      String message, List<dynamic> products) async {
    final result = <Map<String, dynamic>>[];

    // Build compact product list (top 30 products)
    final productList = StringBuffer();
    for (int i = 0; i < products.length && i < 30; i++) {
      final product = products[i];
      productList
          .writeln('ID${product.id}:"${product.name}" ${product.realPrice}k');
    }

    final prompt = '''
Phân tích đơn hàng: "$message"

Sách có sẵn:
$productList

Trả về JSON (chỉ JSON, không giải thích):
{"books":[{"id":123,"qty":2}]}

Nếu không tìm thấy: {"books":[]}
''';

    try {
      final response = await _geminiService.generateResponse(
        prompt,
        products: [],
        categories: [],
        userOrders: [],
        vouchers: [],
        feedbacks: [],
        userEmail: '',
      );

      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[^\}]*"books"[^\}]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr =
            jsonMatch.group(0)!.replaceAll('"', '"').replaceAll('"', '"');
        final data = jsonDecode(jsonStr);

        if (data['books'] is List) {
          for (var item in data['books']) {
            final productId = item['id'];
            final product = products.firstWhere(
              (p) => p.id == productId,
              orElse: () => null,
            );

            if (product != null) {
              result.add({
                'id': product.id,
                'name': product.name ?? 'Sản phẩm',
                'price': product.realPrice ?? 0,
                'quantity': item['qty'] ?? item['quantity'] ?? 1,
                'image': product.image ?? '',
              });
            }
          }
        }
      }
    } catch (e) {
      print('AI order parsing error: $e');
    }

    return result;
  }

  String _formatSelectedProducts() {
    final buffer = StringBuffer();
    buffer.writeln('📚 Sản phẩm:');
    int total = 0;

    for (var product in _selectedProducts) {
      final price = product['price'] as int;
      final quantity = product['quantity'] as int;
      final subtotal = price * quantity;
      total += subtotal;

      buffer.writeln('• ${product['name']} x$quantity - ${subtotal}k');
    }

    buffer.writeln('\n💰 Tổng tạm tính: ${total}k');
    return buffer.toString();
  }

  Future<void> _processOrderStep(
      String message,
      String userEmail,
      OrderProvider? orderProvider,
      api_providers.ProductApiProvider? productProvider) async {
    try {
      switch (_orderStep) {
        case 1:
          _processCustomerName(message);
          break;
        case 2:
          _processCustomerPhone(message);
          break;
        case 3:
          _processCustomerAddress(message);
          break;
        case 4:
          await _processProductSelection(message, productProvider);
          break;
        case 5:
          await _processQuantitySelection(message, productProvider);
          break;
        case 6:
          _processVoucherSelection(message);
          break;
        case 7:
          if (message.toLowerCase().contains('có')) {
            await _createOrderViaAPI(userEmail, orderProvider);
          } else if (message.toLowerCase().contains('không')) {
            _addBotMessage('❌ Đã hủy tạo đơn hàng.');
            _resetOrderState();
          } else {
            _addBotMessage('❌ Vui lòng trả lời "có" hoặc "không":');
          }
          break;
      }
    } catch (e) {
      print('Error in _processOrderStep: $e');
      _addBotMessage('❌ Có lỗi xảy ra. Vui lòng thử lại!');
      _setLoading(false);
    }
  }

  void _processCustomerName(String message) {
    if (message.trim().isNotEmpty) {
      _customerName = message.trim();
      _orderStep = 2;
      _addBotMessage(
          '✅ Đã lưu tên: $_customerName\n\nBước 2: Vui lòng cho tôi biết số điện thoại của bạn:');
    } else {
      _addBotMessage('❌ Vui lòng nhập họ tên hợp lệ:');
    }
  }

  void _processCustomerPhone(String message) {
    final phone = message.trim();
    if (RegExp(r'^[0-9]{10,11}$').hasMatch(phone)) {
      _customerPhone = phone;
      _orderStep = 3;
      _addBotMessage(
          '✅ Đã lưu SĐT: $_customerPhone\n\nBước 3: Vui lòng cho tôi biết địa chỉ giao hàng của bạn:');
    } else {
      _addBotMessage(
          '❌ Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại 10-11 chữ số:');
    }
  }

  void _processCustomerAddress(String message) {
    if (message.trim().isNotEmpty) {
      _customerAddress = message.trim();

      // If products already selected, skip to voucher
      if (_selectedProducts.isNotEmpty) {
        _orderStep = 6;
        _addBotMessage('✅ Đã lưu địa chỉ: $_customerAddress\n\n'
            'Bạn có voucher không? Nhập "có" nếu có voucher, "không" để bỏ qua:');
      } else {
        _orderStep = 4;
        _addBotMessage('✅ Đã lưu địa chỉ: $_customerAddress\n\n'
            '📚 Bạn muốn đặt sách gì?\n'
            'Ví dụ: "Đắc Nhân Tâm 2 cuốn" hoặc "Tôi muốn mua Nhà Giả Kim"\n\n'
            'Gõ "hủy" để hủy đơn hàng:');
      }
    } else {
      _addBotMessage('❌ Vui lòng nhập địa chỉ hợp lệ:');
    }
  }

  Future<void> _processProductSelection(
      String message, api_providers.ProductApiProvider? productProvider) async {
    if (message.toLowerCase() == 'bỏ qua' || message.toLowerCase() == 'hủy') {
      _addBotMessage('❌ Đã hủy tạo đơn hàng.');
      _resetOrderState();
      return;
    }

    if (message.toLowerCase() == 'xong') {
      if (_selectedProducts.isEmpty) {
        _addBotMessage(
            '❌ Chưa chọn sản phẩm nào. Vui lòng chọn ít nhất 1 sản phẩm:');
        return;
      }
      _orderStep = 6;
      _addBotMessage(
          'Bạn có voucher không? Nhập "có" nếu có voucher, "không" để bỏ qua:');
      return;
    }

    _setLoading(true);

    try {
      // Parse products from user's natural language message
      final products = productProvider?.products ?? [];
      final parsedProducts = await _parseProductsFromMessage(message, products);

      if (parsedProducts.isNotEmpty) {
        _selectedProducts.addAll(parsedProducts);
        _orderStep = 5; // Move to step 5 to allow adding more products
        _addBotMessage('✅ Đã thêm:\n'
            '${_formatSelectedProducts()}\n\n'
            'Bạn muốn đặt thêm sách nào không?\n'
            'Hoặc gõ "xong" để tiếp tục:');
      } else {
        _addBotMessage('❌ Không tìm thấy sách bạn muốn.\n\n'
            'Vui lòng thử lại với tên sách khác hoặc gõ "hủy" để hủy đơn:');
      }
    } catch (e) {
      print('Error parsing products: $e');
      _addBotMessage('❌ Có lỗi khi xử lý. Vui lòng thử lại:');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _processQuantitySelection(
      String message, api_providers.ProductApiProvider? productProvider) async {
    if (message.toLowerCase() == 'xong') {
      if (_selectedProducts.isEmpty) {
        _addBotMessage(
            '❌ Chưa chọn sản phẩm nào. Vui lòng chọn ít nhất 1 sản phẩm:');
        return;
      }
      _orderStep = 6;
      _addBotMessage(
          'Bạn có voucher không? Nhập "có" nếu có voucher, "không" để bỏ qua:');
      return;
    }

    if (message.toLowerCase() == 'hủy') {
      _addBotMessage('❌ Đã hủy tạo đơn hàng.');
      _resetOrderState();
      return;
    }

    // Parse more products from natural language
    _setLoading(true);

    try {
      final products = productProvider?.products ?? [];
      final parsedProducts = await _parseProductsFromMessage(message, products);

      if (parsedProducts.isNotEmpty) {
        _selectedProducts.addAll(parsedProducts);
        _addBotMessage('✅ Đã thêm:\n'
            '${_formatSelectedProducts()}\n\n'
            'Bạn muốn đặt thêm sách nào không?\n'
            'Hoặc gõ "xong" để tiếp tục:');
      } else {
        _addBotMessage('❌ Không tìm thấy sách bạn muốn.\n\n'
            'Vui lòng thử lại với tên sách khác hoặc gõ "xong" để tiếp tục:');
      }
    } catch (e) {
      print('Error parsing products: $e');
      _addBotMessage('❌ Có lỗi khi xử lý. Vui lòng thử lại:');
    } finally {
      _setLoading(false);
    }
  }

  void _processVoucherSelection(String message) {
    if (message.toLowerCase() == 'không') {
      _orderStep = 7;
      _confirmOrder();
    } else if (message.toLowerCase() == 'có') {
      _addBotMessage('Vui lòng nhập mã voucher:');
      _orderStep = 6; // Stay at voucher step to get code
    } else {
      // Assume this is the voucher code
      _addBotMessage('✅ Đã lưu mã voucher: $message');
      _orderStep = 7;
      _confirmOrder();
    }
  }

  void _confirmOrder() {
    final orderSummary = StringBuffer();
    orderSummary.writeln('📋 Tóm tắt đơn hàng:\n');
    orderSummary.writeln('👤 Khách hàng: $_customerName');
    orderSummary.writeln('📞 SĐT: $_customerPhone');
    orderSummary.writeln('📍 Địa chỉ: $_customerAddress\n');

    if (_selectedProducts.isNotEmpty) {
      orderSummary.writeln('📚 Sản phẩm:');
      int total = 0;
      for (var product in _selectedProducts) {
        final price = (product['price'] as int?) ?? 0;
        final quantity = (product['quantity'] as int?) ?? 1;
        final subtotal = price * quantity;
        total += subtotal;

        orderSummary.writeln(
            '• ${product['name'] ?? 'Sản phẩm #${product['id']}'} x$quantity - ${subtotal}k');
      }
      orderSummary.writeln('\n💰 Tổng tiền: ${total}k');
    } else {
      orderSummary.writeln('📚 Sản phẩm: Chưa chọn');
      orderSummary.writeln('\n💰 Tổng tiền: 0k');
    }

    orderSummary.writeln('💳 Phương thức: Tiền mặt (COD)\n');
    orderSummary.writeln('Xác nhận tạo đơn hàng? (có/không):');

    _addBotMessage(orderSummary.toString());
  }

  Future<void> _createOrderViaAPI(
      String userEmail, OrderProvider? orderProvider) async {
    if (_userId == null) {
      _addBotMessage('❌ Lỗi: Vui lòng đăng nhập để đặt hàng!');
      _resetOrderState();
      return;
    }

    if (_selectedProducts.isEmpty) {
      _addBotMessage('❌ Không có sản phẩm nào để đặt hàng!');
      _resetOrderState();
      return;
    }

    _setLoading(true);
    _addBotMessage('⏳ Đang xử lý đơn hàng...');

    try {
      print('🛒 Starting order creation via API...');
      print('👤 User ID: $_userId');
      print('📚 Products: ${_selectedProducts.length} items');

      // Log product details
      for (var i = 0; i < _selectedProducts.length; i++) {
        final product = _selectedProducts[i];
        print(
            '📦 Product ${i + 1}: ID=${product['id']}, Name="${product['name']}", Qty=${product['quantity']}, Price=${product['price']}');
      }

      // Step 1: Add all products to cart
      for (var product in _selectedProducts) {
        final productId = product['id'] as int;
        final quantity = product['quantity'] as int;
        final productName = product['name'] as String;

        print(
            '➕ Adding to cart: Product #$productId "$productName" x$quantity');

        try {
          final cartResult = await ApiService.addToCart(
            userId: _userId!,
            bookId: productId,
            quantity: quantity,
          );

          if (cartResult == null) {
            throw Exception(
                'API không trả về kết quả khi thêm sản phẩm "$productName" (ID: $productId)');
          }

          print('✅ Added to cart successfully: $cartResult');
        } catch (e) {
          print('❌ Error adding product #$productId to cart: $e');
          throw Exception(
              'Không thể thêm sản phẩm "$productName" vào giỏ hàng.\n'
              'Chi tiết: ${e.toString()}');
        }
      }

      print('🛍️ Creating order from cart...');

      // Step 2: Create order from cart via API
      final orderResult = await ApiService.createSimpleOrder(
        userId: _userId!,
        paymentMethod: 'COD',
        notes:
            'Đơn hàng từ chatbot AI\nKhách hàng: $_customerName\nSĐT: $_customerPhone\nĐịa chỉ: $_customerAddress',
      );

      if (orderResult != null) {
        print('✅ Order created successfully!');
        print('📦 Order data: $orderResult');

        // Calculate total for display
        int totalAmount = 0;
        for (var product in _selectedProducts) {
          final price = (product['price'] as int?) ?? 0;
          final quantity = (product['quantity'] as int?) ?? 1;
          totalAmount += price * quantity;
        }

        final orderNumber = orderResult['order_number'] ?? 'N/A';
        final orderId = orderResult['id'] ?? 0;

        _addBotMessage('🎉 Đơn hàng đã được tạo thành công!\n\n'
            '📋 Mã đơn: #$orderNumber\n'
            '🆔 ID: $orderId\n'
            '📚 Sản phẩm: ${_selectedProducts.length} cuốn sách\n'
            '💰 Tổng tiền: ${totalAmount}k\n'
            '📍 Địa chỉ: $_customerAddress\n'
            '📞 SĐT: $_customerPhone\n\n'
            'Chúng tôi sẽ liên hệ với bạn sớm nhất! 🚚\n\n'
            'Cần giúp gì thêm không? 😊');

        // Reload orders if provider available
        if (orderProvider != null && _userId != null) {
          print('🔄 Reloading user orders...');
          await orderProvider.loadUserOrders(userId: _userId!);
        }
      } else {
        throw Exception('API không trả về dữ liệu đơn hàng');
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      _addBotMessage('❌ Có lỗi xảy ra khi tạo đơn hàng:\n'
          '${e.toString()}\n\n'
          'Vui lòng thử lại sau hoặc liên hệ với chúng tôi! 📞');
    } finally {
      _setLoading(false);
      _resetOrderState();
    }
  }

  void _resetOrderState() {
    _isCreatingOrder = false;
    _orderStep = 0;
    _customerName = '';
    _customerPhone = '';
    _customerAddress = '';
    _selectedProducts.clear();
    notifyListeners();
  }

  void _addUserMessage(String content) {
    _messages.add(Message(content: content, isFromUser: true));
    notifyListeners();
  }

  void _addBotMessage(String content) {
    _messages.add(Message(content: content, isFromUser: false));
    notifyListeners();
  }

  Future<void> _saveChatHistory(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = '${AppConstants.chatHistoryKey}_$userEmail';

    final historyJson = _messages.map((msg) => msg.toJson()).toList();
    await prefs.setString(historyKey, jsonEncode(historyJson));
  }

  Future<List<Message>> _loadChatHistory(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = '${AppConstants.chatHistoryKey}_$userEmail';

    final historyStr = prefs.getString(historyKey);
    if (historyStr != null) {
      try {
        final historyList = jsonDecode(historyStr) as List;
        return historyList.map((json) => Message.fromJson(json)).toList();
      } catch (e) {
        print('Error loading chat history: $e');
      }
    }

    return [];
  }

  Future<void> clearChatHistory(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = '${AppConstants.chatHistoryKey}_$userEmail';
    await prefs.remove(historyKey);

    _messages.clear();
    _addBotMessage('Đã xóa lịch sử! 🔄\n\n'
        'Chào bạn! Mình là trợ lý AI của BookStore.\n\n'
        'Mình có thể giúp bạn:\n'
        '📚 Tìm sách\n'
        '🛒 Đặt hàng nhanh\n'
        '📦 Kiểm tra đơn\n'
        '💰 Xem khuyến mãi\n\n'
        'Bạn cần gì nhỉ? 😊');
    notifyListeners();
  }

  void _setLoading(bool loading) {
    print('🔄 ChatProvider: Setting loading = $loading');
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  Future<void> loadFeedbacks() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implement actual feedback loading from API
      // For now, return empty list
      _feedbacks = [];
      notifyListeners();
    } catch (e) {
      _setError('Lỗi khi tải phản hồi: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
}
