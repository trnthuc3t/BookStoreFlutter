// ================================
// CONFIG SECRET EXAMPLE FILE
// ================================
// HƯỚNG DẪN SETUP:
// 1. Copy file này thành config_secret.dart
// 2. Thay thế các giá trị placeholder bằng giá trị thật của bạn
// 3. File config_secret.dart sẽ KHÔNG được commit lên Git (đã thêm vào .gitignore)
//
// LƯU Ý:
// - File config_secret.dart chứa các API keys và secrets thật
// - KHÔNG BAO GIỜ commit file config_secret.dart lên GitHub
// - Chỉ commit file config_secret_example.dart này để làm template

class ConfigSecret {
  // ============ Gemini API Configuration ============
  // Lấy API key miễn phí tại: https://aistudio.google.com/app/apikey
  // Hướng dẫn chi tiết: xem file GEMINI_SETUP_GUIDE.md
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // ============ Firebase Configuration ============
  // URL Firebase Realtime Database của bạn
  static const String firebaseUrl = 'YOUR_FIREBASE_URL_HERE';

  // ============ ZaloPay Configuration ============
  // Cấu hình ZaloPay Sandbox cho testing
  // Lấy từ ZaloPay Developer Portal: https://developers.zalopay.vn/
  static const int zalopayAppId = 553; // Sandbox App ID
  static const String zalopayKey1 = 'YOUR_ZALOPAY_KEY1_HERE';
  static const String zalopayCreateUrl =
      'https://sandbox.zalopay.com.vn/v001/tpe/createorder';
  static const String zalopayDeepLinkScheme = 'merchant-deeplink://app';
}


