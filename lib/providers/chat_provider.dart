import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/feedback.dart';
import '../services/gemini_service.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';

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

  List<Message> get messages => _messages;
  List<Feedback> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCreatingOrder => _isCreatingOrder;
  int get orderStep => _orderStep;

  Future<void> initialize(String userEmail) async {
    _messages = await _geminiService.loadChatHistory(userEmail);
    
    // Add welcome message if no history
    if (_messages.isEmpty) {
      _addBotMessage('Xin chào! 👋\n\nTôi là trợ lý ảo thông minh của cửa hàng sách. Tôi có thể giúp bạn:\n\n📚 Tìm kiếm và tư vấn sản phẩm\n📦 Kiểm tra đơn hàng\n🛒 Đặt hàng trực tiếp qua chat\n💰 Xem khuyến mãi và voucher\n📊 Phân tích sản phẩm bán chạy\n⭐ Xem đánh giá và phản hồi\n❓ Trả lời các câu hỏi\n\nBạn cần giúp gì không?');
    }
    
    notifyListeners();
  }

  Future<void> sendMessage(String content, String userEmail, {
    ProductProvider? productProvider,
    OrderProvider? orderProvider,
  }) async {
    _addUserMessage(content);
    
    // Check if user wants to create order
    if (content.toLowerCase().contains('đặt hàng') || 
        content.toLowerCase().contains('tạo đơn') ||
        content.toLowerCase().contains('mua sách')) {
      _startOrderCreation();
      return;
    }

    // Check if we're in order creation mode
    if (_isCreatingOrder) {
      _processOrderStep(content, userEmail, orderProvider);
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get context data
      final products = productProvider?.products ?? [];
      final categories = productProvider?.categories ?? [];
      final userOrders = orderProvider?.orders ?? [];
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
    
    _addBotMessage('🛒 Bắt đầu tạo đơn hàng!\n\nBước 1: Vui lòng cho tôi biết họ tên của bạn:');
    notifyListeners();
  }

  void _processOrderStep(String message, String userEmail, OrderProvider? orderProvider) {
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
        _processProductSelection(message);
        break;
      case 5:
        _processQuantitySelection(message);
        break;
      case 6:
        _processVoucherSelection(message);
        break;
      case 7:
        if (message.toLowerCase().contains('có')) {
          _createOrder(userEmail, orderProvider);
        } else if (message.toLowerCase().contains('không')) {
          _addBotMessage('❌ Đã hủy tạo đơn hàng.');
          _resetOrderState();
        } else {
          _addBotMessage('❌ Vui lòng trả lời "có" hoặc "không":');
        }
        break;
    }
  }

  void _processCustomerName(String message) {
    if (message.trim().isNotEmpty) {
      _customerName = message.trim();
      _orderStep = 2;
      _addBotMessage('✅ Đã lưu tên: $_customerName\n\nBước 2: Vui lòng cho tôi biết số điện thoại của bạn:');
    } else {
      _addBotMessage('❌ Vui lòng nhập họ tên hợp lệ:');
    }
  }

  void _processCustomerPhone(String message) {
    final phone = message.trim();
    if (RegExp(r'^[0-9]{10,11}$').hasMatch(phone)) {
      _customerPhone = phone;
      _orderStep = 3;
      _addBotMessage('✅ Đã lưu SĐT: $_customerPhone\n\nBước 3: Vui lòng cho tôi biết địa chỉ giao hàng của bạn:');
    } else {
      _addBotMessage('❌ Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại 10-11 chữ số:');
    }
  }

  void _processCustomerAddress(String message) {
    if (message.trim().isNotEmpty) {
      _customerAddress = message.trim();
      _orderStep = 4;
      _addBotMessage('✅ Đã lưu địa chỉ: $_customerAddress\n\nBước 4: Vui lòng chọn sản phẩm từ danh sách (nhập số thứ tự):');
      // TODO: Show product list
    } else {
      _addBotMessage('❌ Vui lòng nhập địa chỉ hợp lệ:');
    }
  }

  void _processProductSelection(String message) {
    // TODO: Implement product selection logic
    _orderStep = 5;
    _addBotMessage('Bước 5: Vui lòng nhập số lượng cho từng sản phẩm:');
  }

  void _processQuantitySelection(String message) {
    // TODO: Implement quantity selection logic
    _orderStep = 6;
    _addBotMessage('Bước 6: Chọn voucher (nhập số thứ tự) hoặc nhập "không" để bỏ qua:');
  }

  void _processVoucherSelection(String message) {
    if (message.toLowerCase() == 'không') {
      _orderStep = 7;
      _confirmOrder();
    } else {
      // TODO: Implement voucher selection logic
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
    orderSummary.writeln('📚 Sản phẩm:');
    // TODO: Add product details
    orderSummary.writeln('\n💰 Tổng tiền: 0k');
    orderSummary.writeln('💳 Phương thức: Tiền mặt\n');
    orderSummary.writeln('Xác nhận tạo đơn hàng? (có/không):');
    
    _addBotMessage(orderSummary.toString());
  }

  Future<void> _createOrder(String userEmail, OrderProvider? orderProvider) async {
    // TODO: Implement order creation logic
    _addBotMessage('✅ Đơn hàng đã được tạo thành công!');
    _resetOrderState();
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
    await _geminiService.saveChatHistory(_messages, userEmail);
  }

  Future<void> clearChatHistory(String userEmail) async {
    await _geminiService.clearChatHistory(userEmail);
    _messages.clear();
    _addBotMessage('Lịch sử chat đã được xóa! 👋\n\nTôi là trợ lý ảo thông minh của cửa hàng sách. Tôi có thể giúp bạn:\n\n📚 Tìm kiếm và tư vấn sản phẩm\n📦 Kiểm tra đơn hàng\n💰 Xem khuyến mãi và voucher\n📊 Phân tích sản phẩm bán chạy\n⭐ Xem đánh giá và phản hồi\n❓ Trả lời các câu hỏi\n\nBạn cần giúp gì không?');
    notifyListeners();
  }

  void _setLoading(bool loading) {
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
      // TODO: Implement actual feedback loading from Firebase
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
