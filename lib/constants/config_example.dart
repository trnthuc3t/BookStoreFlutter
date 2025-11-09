// ================================
// CONFIG EXAMPLE FILE
// ================================
// Copy nội dung file này sang config.dart và cập nhật các giá trị thực của bạn
//
// Các bước:
// 1. Copy file này thành config.dart
// 2. Thay YOUR_GEMINI_API_KEY_HERE bằng API key thực từ https://aistudio.google.com/app/apikey
// 3. Cập nhật các config khác nếu cần
// 4. Không commit file config.dart lên Git (đã thêm vào .gitignore)

class Config {
  // ============ Gemini API Configuration ============
  // Lấy API key miễn phí tại: https://aistudio.google.com/app/apikey
  // Hướng dẫn chi tiết: xem file GEMINI_SETUP_GUIDE.md
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // ============ Firebase Configuration ============
  // URL Firebase Realtime Database của bạn
  static const String firebaseUrl =
      'https://booksell-cfee0-default-rtdb.firebaseio.com';

  // ============ ZaloPay Configuration ============
  // Cấu hình ZaloPay Sandbox cho testing
  static const int zalopayAppId = 553;
  static const String zalopayKey1 = '9phuAOYhan4urywHTh0ndEXiV3pKHr5Q';
  static const String zalopayCreateUrl =
      'https://sandbox.zalopay.com.vn/v001/tpe/createorder';
  static const String zalopayDeepLinkScheme = 'merchant-deeplink://app';
}








