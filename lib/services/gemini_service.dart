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
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  Future<void> initialize() async {
    // Check if API key is configured
    if (Config.geminiApiKey.isEmpty ||
        Config.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
          'Gemini API key is not configured. Please update Config.geminiApiKey');
    }
  }

  Future<String> generateResponse(
    String userMessage, {
    List<Product>? products,
    List<Category>? categories,
    List<Order>? userOrders,
    List<Voucher>? vouchers,
    List<Feedback>? feedbacks,
    String? userEmail,
  }) async {
    try {
      await initialize();

      final prompt = _buildPrompt(
        userMessage,
        products: products,
        categories: categories,
        userOrders: userOrders,
        vouchers: vouchers,
        feedbacks: feedbacks,
        userEmail: userEmail,
      );

      final response = await _generateContent(prompt);
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
    buffer.writeln('🧑 KHÁCH HÀNG: ${userEmail ?? "Khách vãng lai"}\n');

    // App info - comprehensive information
    buffer.writeln('=== 📱 THÔNG TIN ỨNG DỤNG BOOKSTORE ===');
    buffer.writeln('🏪 Cửa hàng sách trực tuyến hàng đầu Việt Nam');
    buffer.writeln('✨ Tính năng nổi bật:');
    buffer.writeln('   • Đặt mua sách online, giao hàng tận nhà toàn quốc');
    buffer.writeln(
        '   • Đa dạng thể loại: văn học, kỹ năng sống, thiếu nhi, giáo khoa, ngoại ngữ, lập trình...');
    buffer
        .writeln('   • Thanh toán linh hoạt: Tiền mặt khi nhận hàng, ZaloPay');
    buffer.writeln(
        '   • Ưu đãi hấp dẫn: Voucher giảm giá, flash sale, miễn phí ship');
    buffer.writeln('   • Đánh giá & review chân thực từ khách hàng');
    buffer.writeln('   • Chatbot AI hỗ trợ 24/7');
    buffer.writeln();

    // Categories with product count
    if (categories != null && categories.isNotEmpty) {
      buffer
          .writeln('=== 📂 DANH MỤC SÁCH (${categories.length} danh mục) ===');
      for (var category in categories) {
        final categoryProductCount =
            products?.where((p) => p.categoryId == category.id).length ?? 0;
        buffer.writeln('📚 ${category.name}');
        if (category.description?.isNotEmpty == true) {
          buffer.writeln('   → ${category.description}');
        }
        if (categoryProductCount > 0) {
          buffer.writeln('   → Có $categoryProductCount đầu sách');
        }
      }
      buffer.writeln();
    }

    // Products with comprehensive details
    if (products != null && products.isNotEmpty) {
      buffer
          .writeln('=== 📖 DANH SÁCH SÁCH (${products.length} đầu sách) ===\n');

      // Sort: featured first, then by rating, then by sale
      final sortedProducts = List<Product>.from(products);
      sortedProducts.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        if (a.sale > 0 && b.sale == 0) return -1;
        if (a.sale == 0 && b.sale > 0) return 1;
        return b.rate.compareTo(a.rate);
      });

      for (int i = 0; i < sortedProducts.length && i < 50; i++) {
        final product = sortedProducts[i];
        buffer.write('📕 ID-${product.id}: "${product.name}"');

        // Badges
        if (product.isFeatured) {
          buffer.write(' 🏆');
        }
        if (product.sale > 0) {
          buffer.write(' 🔥');
        }
        buffer.writeln();

        // Price with sale info
        if (product.sale > 0) {
          buffer.writeln(
              '   💰 ${product.realPrice}k (Giảm ${product.sale}% từ ${product.price}k) - ĐANG SALE!');
        } else {
          buffer.writeln('   💰 ${product.realPrice}k');
        }

        // Category and rating
        buffer.writeln('   📂 ${product.categoryName ?? "Chưa phân loại"}');
        if (product.countReviews > 0) {
          buffer.writeln(
              '   ⭐ ${product.rate}/5 (${product.countReviews} đánh giá)');
        } else {
          buffer.writeln('   ⭐ Chưa có đánh giá');
        }

        // Description
        if (product.description?.isNotEmpty == true) {
          final desc = product.description!.length > 150
              ? '${product.description!.substring(0, 150)}...'
              : product.description!;
          buffer.writeln('   📝 $desc');
        }

        // Content/Info
        if (product.info?.isNotEmpty == true) {
          final info = product.info!.length > 200
              ? '${product.info!.substring(0, 200)}...'
              : product.info!;
          buffer.writeln('   📚 $info');
        }

        buffer.writeln();
      }

      if (products.length > 50) {
        buffer.writeln('... và ${products.length - 50} sách khác\n');
      }
    }

    // User orders
    if (userOrders != null && userOrders.isNotEmpty) {
      buffer.writeln('=== ĐƠN HÀNG ===\n');
      for (var order in userOrders) {
        buffer.writeln('Đơn #${order.id}');
        buffer.writeln('- Tổng: ${order.totalAmount}k');
        buffer.writeln('- Trạng thái: ${order.statusText}');
        buffer.writeln(
            '- Ngày đặt: ${order.createdAt?.toIso8601String() ?? 'N/A'}');
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

    // Vouchers with details
    if (vouchers != null && vouchers.isNotEmpty) {
      buffer.writeln('=== 🎟️ VOUCHER & KHUYẾN MÃI (${vouchers.length}) ===\n');
      for (int i = 0; i < vouchers.length && i < 15; i++) {
        final voucher = vouchers[i];
        buffer.writeln('🎁 ${voucher.name}');
        if (voucher.code?.isNotEmpty == true) {
          buffer.writeln('   📋 Mã: ${voucher.code}');
        }
        buffer.writeln('   💸 Giảm ${voucher.discount}%');
        if (voucher.minPrice > 0) {
          buffer.writeln('   📦 Đơn tối thiểu: ${voucher.minPrice}k');
        }
        if (voucher.maxDiscount > 0) {
          buffer.writeln('   🎯 Giảm tối đa: ${voucher.maxDiscount}k');
        }
        if (voucher.description?.isNotEmpty == true) {
          buffer.writeln('   📝 ${voucher.description}');
        }
        if (voucher.remainingUses > 0) {
          buffer.writeln(
              '   ⏳ Còn ${voucher.remainingUses}/${voucher.maxUses} lượt');
        }
        buffer.writeln();
      }
    } else {
      buffer.writeln(
          '=== 🎟️ VOUCHER & KHUYẾN MÃI ===\n❌ Hiện tại chưa có voucher khả dụng.\n');
    }

    // Feedback with sentiment
    if (feedbacks != null && feedbacks.isNotEmpty) {
      buffer.writeln('=== 💬 PHẢN HỒI KHÁCH HÀNG (${feedbacks.length}) ===\n');
      // Sort by rating
      final sortedFeedbacks = List<Feedback>.from(feedbacks);
      sortedFeedbacks.sort((a, b) => b.rate.compareTo(a.rate));

      for (int i = 0; i < sortedFeedbacks.length && i < 15; i++) {
        final feedback = sortedFeedbacks[i];
        final stars = '⭐' * feedback.rate.toInt();
        buffer.writeln('$stars ${feedback.rate}/5');
        if (feedback.content?.isNotEmpty == true) {
          buffer.writeln('   "${feedback.content}"');
        } else if (feedback.message?.isNotEmpty == true) {
          buffer.writeln('   "${feedback.message}"');
        }
        if (feedback.userEmail?.isNotEmpty == true) {
          buffer.writeln('   👤 ${feedback.userEmail}');
        }
        if (feedback.dateTime?.isNotEmpty == true) {
          buffer.writeln('   📅 ${feedback.dateTime}');
        }
        buffer.writeln();
      }
    } else {
      buffer
          .writeln('=== 💬 PHẢN HỒI KHÁCH HÀNG ===\n❌ Chưa có phản hồi nào.\n');
    }

    return '''
🤖 BẠN LÀ TRỢ LÝ ẢO THÔNG MINH CỦA BOOKSTORE - CỬA HÀNG SÁCH TRỰC TUYẾN

📋 DỮ LIỆU ĐẦY ĐỦ:
${buffer.toString()}

🎯 VAI TRÒ & NĂNG LỰC:
Bạn là chuyên gia tư vấn sách với kiến thức sâu về tất cả sản phẩm.
Bạn có quyền truy cập đầy đủ vào:
• Toàn bộ ${products?.length ?? 0} đầu sách với mô tả chi tiết, nội dung, đánh giá
• ${categories?.length ?? 0} danh mục sách đa dạng
• ${userOrders?.length ?? 0} đơn hàng của khách (nếu có)
• ${vouchers?.length ?? 0} voucher & khuyến mãi
• ${feedbacks?.length ?? 0} phản hồi từ khách hàng

💬 CÁCH TRẢ LỜI:
1. NGẮN GỌN & THÂN THIỆN:
   - Trả lời 2-4 câu, đi thẳng vào vấn đề
   - Dùng emoji phù hợp 📚 💰 🎁
   - Giọng điệu nhiệt tình, chuyên nghiệp

2. ⚠️ ƯU TIÊN HÀNG ĐẦU - NHẬN DIỆN Ý ĐỊNH ĐẶT HÀNG:
   🚨 KHI KHÁCH NÓI: "mua", "đặt", "order", "muốn mua", "đặt hàng", "cho tôi"
   → PHẢI HƯỚNG DẪN ĐẶT QUA CHATBOT NGAY:
   
   📝 Trả lời theo format:
   "Tuyệt! Bạn muốn đặt [Tên sách]? 
   
   Để đặt hàng ngay qua chatbot, bạn chỉ cần gõ:
   🛒 'Mua [Tên sách] X cuốn'
   
   Ví dụ: 'Mua Đắc Nhân Tâm 2 cuốn'
   
   Mình sẽ giúp bạn đặt hàng ngay trong vài giây! 😊"

3. TƯ VẤN THÔNG MINH:
   - Gợi ý sách phù hợp dựa trên: thể loại, rating, sale, trending
   - Ưu tiên: Sách có 🏆 (nổi bật), 🔥 (đang sale), ⭐ cao
   - So sánh, phân tích nếu khách phân vân
   - SAU KHI TƯ VẤN, luôn nhắc: "Muốn đặt ngay không? Gõ 'Mua [tên sách]' nhé!"

4. THÔNG TIN CHI TIẾT:
   - Trả lời về nội dung, tác giả, giá, khuyến mãi
   - Giải thích voucher: điều kiện, cách dùng
   - Tra cứu đơn hàng: trạng thái, sản phẩm, địa chỉ
   - Đọc và trích dẫn mô tả/nội dung sách nếu khách hỏi

5. XỬ LÝ ĐẶC BIỆT:
   - Nếu không tìm thấy: Gợi ý sách tương tự
   - Nếu hết hàng/không có: Thông báo lịch sự + đề xuất thay thế
   - Nếu giá cao: Nhắc voucher, sách rẻ hơn cùng thể loại
   - Nếu khách do dự: Đưa review, rating để thuyết phục

📝 LƯU Ý QUAN TRỌNG:
• Luôn dùng ID-xxx khi nhắc đến sách cụ thể
• Giá đã bao gồm sale (realPrice)
• Tất cả giá tính bằng "k" (nghìn đồng)
• Đơn hàng COD hoặc ZaloPay, ship toàn quốc
• Nếu thiếu info: Nói thẳng + gợi ý cách khác

🚫 TUYỆT ĐỐI KHÔNG ĐƯỢC:
• KHÔNG trả lời chung chung kiểu "Bạn có thể xem trong app"
• KHÔNG bảo khách vào giỏ hàng hoặc trang sản phẩm
• KHÔNG nói "Bạn có thể đặt hàng qua website/app"
• KHI KHÁCH MUỐN MUA → BẮT BUỘC hướng dẫn đặt qua CHATBOT

✅ VÍ DỤ TRẢ LỜI ĐÚNG:

Khách: "Tôi muốn mua Đắc Nhân Tâm"
Bot: "Tuyệt vời! 📚 Đắc Nhân Tâm (ID-5) - 80k, đang sale 10%! ⭐ 4.8/5

Để đặt ngay qua chatbot, bạn gõ:
🛒 'Mua Đắc Nhân Tâm 1 cuốn'

Hoặc nếu muốn nhiều hơn:
🛒 'Mua Đắc Nhân Tâm 3 cuốn'

Mình sẽ xử lý đơn trong 30 giây! 😊"

❌ VÍ DỤ TRẢ LỜI SAI:
"Bạn có thể vào giỏ hàng để đặt sách nhé!"
"Vui lòng xem thêm trong mục sản phẩm"
"Bạn có thể đặt hàng qua app"

❓ CÂU HỎI KHÁCH HÀNG:
$userMessage

💡 HÃY TRẢ LỜI THÔNG MINH, CHÍNH XÁC VÀ HƯỚNG DẪN ĐẶT HÀNG QUA CHATBOT!
    ''';
  }

  Future<String> _generateContent(String prompt) async {
    final url = Uri.parse(_baseUrl);

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
        'x-goog-api-key': Config.geminiApiKey,
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

        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? '';
        }
      }

      throw Exception('Empty response from Gemini API');
    }

    throw Exception('API Error ${response.statusCode}: ${response.body}');
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('api key not configured')) {
      return '❌ Chưa cấu hình API key!\n\nVui lòng:\n1. Vào https://aistudio.google.com/app/apikey\n2. Tạo key mới\n3. Cập nhật vào lib/constants/config.dart';
    } else if (errorStr.contains('api_key_invalid') ||
        errorStr.contains('api key not valid') ||
        errorStr.contains('invalid_argument') ||
        errorStr.contains('400')) {
      return '❌ API key không hợp lệ!\n\nVui lòng:\n1. Vào https://aistudio.google.com/app/apikey\n2. Tạo key mới\n3. Cập nhật vào lib/constants/config.dart';
    } else if (errorStr.contains('resource_exhausted') ||
        errorStr.contains('429')) {
      return '⏰ Vượt giới hạn requests.\n\nĐợi 1 phút nhé!';
    } else if (errorStr.contains('permission_denied') ||
        errorStr.contains('403')) {
      return '🔒 API key không có quyền.\n\nKiểm tra lại cấu hình API key.';
    } else if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return '⏱️ Timeout. Thử lại nhé!';
    } else if (errorStr.contains('unable to resolve host') ||
        errorStr.contains('no internet') ||
        errorStr.contains('network')) {
      return '📡 Không có mạng. Kiểm tra WiFi/Data!';
    } else {
      return '⚠️ Lỗi: ${error.toString()}\n\nThử lại nhé!';
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
