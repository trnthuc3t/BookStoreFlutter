import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/category.dart';
import '../models/voucher.dart';
import '../models/feedback.dart';
import '../constants/app_constants.dart';
import '../constants/config.dart';

class GeminiService {
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._();
  
  GeminiService._();

  final http.Client _client = http.Client();
  String? _apiKey;

  Future<void> initialize() async {
    // Load API key from config
    _apiKey = Config.geminiApiKey;
  }

  Future<String> generateResponse(
    String userMessage,
    {
    List<Product>? products,
    List<Category>? categories,
    List<Order>? userOrders,
    List<Voucher>? vouchers,
    List<Feedback>? feedbacks,
    String? userEmail,
  }) async {
    try {
      final prompt = _buildPrompt(
        userMessage,
        products: products,
        categories: categories,
        userOrders: userOrders,
        vouchers: vouchers,
        feedbacks: feedbacks,
        userEmail: userEmail,
      );

      final response = await _callGeminiAPI(prompt);
      return response;
    } catch (e) {
      print('Gemini API error: $e');
      return _getErrorMessage(e);
    }
  }

  String _buildPrompt(
    String userMessage, {
    List<Product>? products,
    List<Category>? categories,
    List<Order>? userOrders,
    List<Voucher>? vouchers,
    List<Feedback>? feedbacks,
    String? userEmail,
  }) {
    final buffer = StringBuffer();

    // User info
    buffer.writeln('Khách hàng: ${userEmail ?? "Guest"}\n');

    // Categories
    if (categories != null && categories.isNotEmpty) {
      buffer.writeln('=== DANH MỤC ===');
      for (var category in categories) {
        buffer.writeln('- ${category.name}');
      }
      buffer.writeln();
    }

    // Products
    if (products != null && products.isNotEmpty) {
      buffer.writeln('=== SẢN PHẨM ===\n');
      for (int i = 0; i < products.length && i < 20; i++) {
        final product = products[i];
        buffer.writeln('${i + 1}. ${product.name}');
        buffer.write('   Giá: ${product.realPrice}k');
        if (product.sale > 0) {
          buffer.write(' (Giảm ${product.sale}%)');
        }
        buffer.writeln();
        buffer.writeln('   Danh mục: ${product.categoryName}');
        buffer.writeln('   Đánh giá: ${product.rate}⭐ (${product.countReviews} đánh giá)');
        if (product.isFeatured) {
          buffer.writeln('   ⭐ SẢN PHẨM NỔI BẬT');
        }
        if (product.description?.isNotEmpty == true) {
          buffer.writeln('   📖 Mô tả: ${product.description}');
        }
        if (product.info?.isNotEmpty == true) {
          buffer.writeln('   📚 Nội dung: ${product.info}');
        }
        buffer.writeln();
      }
    }

    // User orders
    if (userOrders != null && userOrders.isNotEmpty) {
      buffer.writeln('=== ĐƠN HÀNG ===\n');
      for (var order in userOrders) {
        buffer.writeln('Đơn #${order.id}');
        buffer.writeln('- Tổng: ${order.totalAmount}k');
        buffer.writeln('- Trạng thái: ${order.statusText}');
        buffer.writeln('- Ngày đặt: ${order.createdAt?.toIso8601String() ?? 'N/A'}');
        buffer.writeln('- Phương thức thanh toán: ${order.paymentMethod}');
        
        // Note: Order model doesn't have products field, this would need to be implemented
        // if (order.products?.isNotEmpty == true) {
        //   buffer.writeln('- Sản phẩm đã mua:');
        //   for (var product in order.products!) {
        //     buffer.writeln('  • ${product.name} (SL: ${product.count}, Giá: ${product.price}k)');
        //   }
        // }
        
        if (order.address != null) {
          buffer.writeln('- Địa chỉ giao hàng:');
          buffer.writeln('  • Địa chỉ: ${order.address}');
        }
        buffer.writeln();
      }
    } else {
      buffer.writeln('=== ĐƠN HÀNG ===\nChưa có đơn hàng.\n');
    }

    // Vouchers
    if (vouchers != null && vouchers.isNotEmpty) {
      buffer.writeln('=== VOUCHER & KHUYẾN MÃI ===\n');
      for (int i = 0; i < vouchers.length && i < 10; i++) {
        final voucher = vouchers[i];
        buffer.writeln('${i + 1}. ${voucher.name}');
        buffer.writeln('   Giảm giá: ${voucher.discount}%');
        buffer.writeln('   Mô tả: ${voucher.description}\n');
      }
    } else {
      buffer.writeln('=== VOUCHER & KHUYẾN MÃI ===\nHiện tại chưa có voucher nào.\n');
    }

    // Feedback
    if (feedbacks != null && feedbacks.isNotEmpty) {
      buffer.writeln('=== PHẢN HỒI KHÁCH HÀNG ===\n');
      for (int i = 0; i < feedbacks.length && i < 10; i++) {
        final feedback = feedbacks[i];
        buffer.writeln('${i + 1}. ${feedback.content}');
        buffer.writeln('   Đánh giá: ${feedback.rate}⭐');
        buffer.writeln('   Từ: ${feedback.userEmail}\n');
      }
    } else {
      buffer.writeln('=== PHẢN HỒI KHÁCH HÀNG ===\nChưa có phản hồi nào.\n');
    }

    return '''
Bạn là trợ lý ảo thông minh của cửa hàng sách trực tuyến.
Trả lời bằng tiếng Việt, ngắn gọn (2-3 câu), thân thiện.

${buffer.toString()}

HƯỚNG DẪN:
- Trả lời ngắn gọn, dễ hiểu
- Dùng emoji phù hợp 😊
- Ưu tiên sản phẩm có khuyến mãi
- Gợi ý sản phẩm phù hợp với nhu cầu
- Có thể phân tích sản phẩm bán chạy/ít bán (không nói số lượng cụ thể)
- Xem được voucher và khuyến mãi hiện có
- Đọc được phản hồi khách hàng
- CÓ THỂ TRẢ LỜI CHI TIẾT VỀ ĐƠN HÀNG:
  • Sách nào đã mua trong đơn hàng
  • Địa chỉ giao hàng (tên, SĐT, địa chỉ)
  • Trạng thái đơn hàng
  • Phương thức thanh toán
  • Ngày đặt hàng
- CÓ THỂ ĐỌC NỘI DUNG SÁCH:
  • Mô tả chi tiết của sách
  • Nội dung, tóm tắt sách
  • Thông tin về tác giả, nhà xuất bản
  • Giới thiệu về cuốn sách
  • Trả lời câu hỏi về nội dung sách
- Nếu không có thông tin, thừa nhận lịch sự

Câu hỏi: $userMessage
    ''';
  }

  Future<String> _callGeminiAPI(String prompt) async {
    final url = Uri.parse(AppConstants.geminiApiUrl);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    final response = await _client.post(
      url,
      headers: {
        'x-goog-api-key': _apiKey!,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'];
      
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'];
        
        if (parts.isNotEmpty) {
          return parts[0]['text'];
        }
      }
    }

    throw Exception('API Error ${response.statusCode}: ${response.body}');
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('api_key_invalid') || 
        errorStr.contains('api key not valid') ||
        errorStr.contains('400')) {
      return '❌ API key không hợp lệ!\n\nVui lòng:\n1. Vào https://aistudio.google.com/app/apikey\n2. Tạo key mới\n3. Cập nhật API key trong ứng dụng';
    } else if (errorStr.contains('resource_exhausted') || 
               errorStr.contains('429')) {
      return '⏰ Vượt giới hạn 60 requests/phút.\n\nĐợi 1 phút nhé!';
    } else if (errorStr.contains('permission_denied') || 
               errorStr.contains('403')) {
      return '🔒 API key không có quyền.\n\nEnable Generative Language API trong Google Cloud Console.';
    } else if (errorStr.contains('timeout')) {
      return '⏱️ Timeout. Thử lại nhé!';
    } else if (errorStr.contains('unable to resolve host')) {
      return '📡 Không có mạng. Kiểm tra WiFi/Data!';
    } else {
      return '⚠️ Lỗi: $error\n\nThử lại nhé!';
    }
  }

  // Chat history management
  Future<void> saveChatHistory(List<Message> messages, String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = '${AppConstants.chatHistoryKey}_$userEmail';
    
    final historyJson = messages.map((msg) => msg.toJson()).toList();
    await prefs.setString(historyKey, jsonEncode(historyJson));
  }

  Future<List<Message>> loadChatHistory(String userEmail) async {
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
  }

  void dispose() {
    _client.close();
  }
}
