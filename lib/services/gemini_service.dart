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
import '../config/gemini_config.dart';

class GeminiService {
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._();

  GeminiService._();

  final http.Client _client = http.Client();
  // Using gemini-2.5-flash (latest stable model)
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<void> initialize() async {
    // Check if API key is configured
    if (GeminiConfig.apiKey.isEmpty) {
      throw Exception(
          'Gemini API key is not configured. Please update lib/config/gemini_config.dart');
    }
    
    // Additional validation: API key should start with "AIza"
    if (!GeminiConfig.apiKey.startsWith('AIza')) {
      throw Exception(
          'Invalid Gemini API key format. API key should start with "AIza"');
    }
    
    print('✅ Gemini API key validated successfully');
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

        // Price info - Show both for debugging
        if (product.sale > 0) {
          buffer.writeln(
              '   💰 Giá hiện tại: ${product.price}k');
          buffer.writeln(
              '   🏷️ Đang giảm ${product.sale}%');
          buffer.writeln(
              '   ✅ Giá khách trả: ${product.realPrice}k 🔥');
        } else {
          buffer.writeln('   💰 Giá: ${product.price}k');
        }

        // Category and rating
        buffer.writeln('   📂 ${product.categoryName ?? "Chưa phân loại"}');
        if (product.countReviews > 0) {
          buffer.writeln(
              '   ⭐ ${product.rate}/5 (${product.countReviews} đánh giá)');
        } else {
          buffer.writeln('   ⭐ Chưa có đánh giá');
        }

        // Book details (NO stock/sold info for regular users)
        if (product.publisher?.isNotEmpty == true) {
          buffer.writeln('   🏢 NXB: ${product.publisher}');
        }
        if (product.supplier?.isNotEmpty == true) {
          buffer.writeln('   🏪 Nhà cung cấp: ${product.supplier}');
        }
        if (product.pageCount != null && product.pageCount! > 0) {
          buffer.writeln('   📄 Số trang: ${product.pageCount}');
        }
        if (product.publishYear != null && product.publishYear! > 0) {
          buffer.writeln('   📅 Năm xuất bản: ${product.publishYear}');
        }
        if (product.language?.isNotEmpty == true) {
          buffer.writeln('   🌐 Ngôn ngữ: ${product.language}');
        }
        if (product.bookSize?.isNotEmpty == true) {
          buffer.writeln('   📏 Kích thước: ${product.bookSize}');
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

    // User orders with detailed information
    if (userOrders != null && userOrders.isNotEmpty) {
      buffer.writeln('=== 📦 LỊCH SỬ ĐƠN HÀNG (${userOrders.length} đơn) ===\n');
      
      // Sort by date (newest first)
      final sortedOrders = List<Order>.from(userOrders);
      sortedOrders.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      for (int i = 0; i < sortedOrders.length && i < 10; i++) {
        final order = sortedOrders[i];
        buffer.writeln('📋 Đơn hàng #${order.id}');
        
        // Status with emoji
        String statusEmoji = '⏳';
        if (order.status == 'completed') statusEmoji = '✅';
        else if (order.status == 'cancelled') statusEmoji = '❌';
        else if (order.status == 'processing') statusEmoji = '🚚';
        buffer.writeln('   $statusEmoji Trạng thái: ${order.statusText}');
        
        buffer.writeln('   💰 Tổng tiền: ${order.totalAmount}k');
        
        if (order.createdAt != null) {
          final date = order.createdAt!;
          buffer.writeln('   📅 Ngày đặt: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}');
        }
        
        if (order.paymentMethod?.isNotEmpty == true) {
          buffer.writeln('   💳 Thanh toán: ${order.paymentMethod}');
        }
        
        if (order.userName?.isNotEmpty == true) {
          buffer.writeln('   👤 Người nhận: ${order.userName}');
        }
        
        if (order.phone?.isNotEmpty == true) {
          buffer.writeln('   📞 SĐT: ${order.phone}');
        }
        
        if (order.address?.isNotEmpty == true) {
          buffer.writeln('   📍 Địa chỉ: ${order.address}');
        }
        
        if (order.notes?.isNotEmpty == true) {
          buffer.writeln('   📝 Ghi chú: ${order.notes}');
        }
        
        buffer.writeln();
      }
      
      if (userOrders.length > 10) {
        buffer.writeln('... và ${userOrders.length - 10} đơn hàng khác\n');
      }
    } else {
      buffer.writeln('=== 📦 LỊCH SỬ ĐƠN HÀNG ===\n❌ Khách hàng chưa có đơn hàng nào.\n');
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

4. THÔNG TIN CHI TIẾT SÁCH:
   - Khi khách hỏi về sách, trả lời ĐẦY ĐỦ:
     📚 Tên sách, tác giả (nếu có)
     🏢 Nhà xuất bản, năm xuất bản
     📄 Số trang, kích thước, ngôn ngữ
     💰 Giá (realPrice là giá CUỐI CÙNG sau giảm, KHÔNG tính lại)
     ⭐ Đánh giá, số lượt đánh giá
     📝 Mô tả ngắn gọn về nội dung
   - Dùng thông tin từ database, KHÔNG bịa đặt
   - KHÔNG hiển thị tồn kho, đã bán (thông tin nội bộ)
   
5. THÔNG TIN ĐƠN HÀNG:
   - Tra cứu lịch sử đơn hàng của khách
   - Hiển thị: Mã đơn, trạng thái, tổng tiền, ngày đặt
   - Thông tin giao hàng: Người nhận, SĐT, địa chỉ
   - Phương thức thanh toán
   - Ghi chú đơn hàng (nếu có)
   
6. VOUCHER & KHUYẾN MÃI:
   - Giải thích voucher: điều kiện, cách dùng
   - Tính toán giá sau khi dùng voucher
   - Gợi ý voucher phù hợp với đơn hàng

7. XỬ LÝ ĐẶC BIỆT:
   - Nếu không tìm thấy: Gợi ý sách tương tự
   - Nếu hết hàng/không có: Thông báo lịch sự + đề xuất thay thế
   - Nếu giá cao: Nhắc voucher, sách rẻ hơn cùng thể loại
   - Nếu khách do dự: Đưa review, rating để thuyết phục

📝 LƯU Ý QUAN TRỌNG:
• Luôn dùng ID-xxx khi nhắc đến sách cụ thể

• ⚠️⚠️⚠️ CỰC KỲ QUAN TRỌNG VỀ GIÁ - ĐỌC KỸ:
  📌 "Giá khách trả" = realPrice = GIÁ CUỐI CÙNG (đã tính giảm giá)
  📌 "Giá hiện tại" = price = GIÁ TRƯỚC KHI GIẢM
  📌 "Đang giảm X%" = sale = PHẦN TRĂM GIẢM GIÁ
  
  🔢 CÔNG THỨC: realPrice = price - (price × sale / 100)
  ⚠️ realPrice ĐÃ ĐƯỢC TÍNH SẴN - KHÔNG TÍNH LẠI!
  
  ✅ ĐÚNG: "Giá: {realPrice}k" hoặc "Giá: {realPrice}k (Giảm {sale}%)"
  ❌ SAI: Tính toán bất kỳ phép tính nào với giá
  
  🚨 KHI KHÁCH HỎI GIÁ:
  - Trả lời: "Giá: {realPrice}k" (đây là giá khách phải trả)
  - Nếu có sale: "Giá: {realPrice}k (Giảm {sale}% từ {price}k)"
  - TUYỆT ĐỐI KHÔNG tính toán lại
  
• Tất cả giá tính bằng "k" (nghìn đồng)
• KHÔNG tiết lộ tồn kho, đã bán cho khách hàng
• Đơn hàng COD hoặc ZaloPay, ship toàn quốc
• Nếu thiếu info: Nói thẳng + gợi ý cách khác

🚫 TUYỆT ĐỐI KHÔNG ĐƯỢC:
• KHÔNG trả lời chung chung kiểu "Bạn có thể xem trong app"
• KHÔNG bảo khách vào giỏ hàng hoặc trang sản phẩm
• KHÔNG nói "Bạn có thể đặt hàng qua website/app"
• KHI KHÁCH MUỐN MUA → BẮT BUỘC hướng dẫn đặt qua CHATBOT

✅ VÍ DỤ TRẢ LỜI ĐÚNG:

VÍ DỤ 1 - Sách có giảm giá:
Data: price=100k, sale=20%, realPrice=80k
Khách: "Đắc Nhân Tâm giá bao nhiêu?"
Bot: "📚 Đắc Nhân Tâm
💰 Giá: 80k (Giảm 20% từ 100k) 🔥
⭐ 4.8/5
🏢 NXB: Trẻ

Muốn đặt ngay không? Gõ 'Mua Đắc Nhân Tâm' nhé! 😊"

VÍ DỤ 2 - Sách không giảm:
Data: price=95004k, sale=0%, realPrice=95004k
Khách: "Sách X giá bao nhiêu?"
Bot: "📚 Sách X
💰 Giá: 95004k
⭐ 4.5/5

Muốn đặt không? Gõ 'Mua Sách X' nhé!"

❌ VÍ DỤ TRẢ LỜI SAI:
"Giá: 100k" (khi realPrice=80k - SAI!)
"Giá: 64k" (tính 80k * 0.8 - SAI!)
"Giá: 76004k" (khi realPrice=95004k - SAI!)
"Bạn có thể vào giỏ hàng để đặt sách nhé!"

❓ CÂU HỎI KHÁCH HÀNG:
$userMessage

💡 HÃY TRẢ LỜI THÔNG MINH, CHÍNH XÁC VÀ HƯỚNG DẪN ĐẶT HÀNG QUA CHATBOT!
    ''';
  }

  Future<String> _generateContent(String prompt) async {
    final url = Uri.parse(_baseUrl);
    
    print('🤖 Calling Gemini API...');
    print('📍 URL: $_baseUrl');
    print('🔑 API Key (first 20 chars): ${GeminiConfig.apiKey.substring(0, 20)}...');

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    try {
      final response = await _client.post(
        url,
        headers: {
          'x-goog-api-key': GeminiConfig.apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'];

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'];

          if (parts != null && parts.isNotEmpty) {
            print('✅ Gemini response received successfully');
            return parts[0]['text'] ?? '';
          }
        }

        throw Exception('Empty response from Gemini API');
      }

      // Log error details
      print('❌ API Error ${response.statusCode}');
      print('❌ Error body: ${response.body}');
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Exception calling Gemini: $e');
      rethrow;
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('api key not configured')) {
      return '❌ Chưa cấu hình API key!\n\nVui lòng:\n1. Vào https://aistudio.google.com/app/apikey\n2. Tạo key mới\n3. Cập nhật vào lib/config/gemini_config.dart';
    } else if (errorStr.contains('api_key_invalid') ||
        errorStr.contains('api key not valid') ||
        errorStr.contains('invalid_argument') ||
        errorStr.contains('400')) {
      return '❌ API key không hợp lệ!\n\nVui lòng:\n1. Kiểm tra API key tại https://aistudio.google.com/app/apikey\n2. Tạo key mới nếu cần\n3. Cập nhật vào lib/config/gemini_config.dart\n\n💡 Lưu ý: API key phải bắt đầu bằng "AIza..."';
    } else if (errorStr.contains('resource_exhausted') ||
        errorStr.contains('429')) {
      return '⏰ Vượt giới hạn requests.\n\n💡 Giải pháp:\n• Đợi 1-2 phút rồi thử lại\n• Hoặc tạo API key mới tại:\n  https://aistudio.google.com/app/apikey';
    } else if (errorStr.contains('permission_denied') ||
        errorStr.contains('403')) {
      return '🔒 API key không có quyền.\n\nKiểm tra:\n1. API key có đúng không?\n2. Gemini API đã được enable chưa?\n3. Tạo key mới tại: https://aistudio.google.com/app/apikey';
    } else if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return '⏱️ Timeout. Mạng chậm hoặc Gemini đang quá tải.\n\nThử lại nhé!';
    } else if (errorStr.contains('unable to resolve host') ||
        errorStr.contains('no internet') ||
        errorStr.contains('network')) {
      return '📡 Không có mạng. Kiểm tra WiFi/Data!';
    } else {
      return '⚠️ Lỗi: ${error.toString()}\n\n💡 Kiểm tra:\n• API key trong lib/config/gemini_config.dart\n• Kết nối mạng\n• Thử lại sau 1 phút';
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
