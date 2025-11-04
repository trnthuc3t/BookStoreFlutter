// ================================
// PUBLIC CONFIG FILE - ĐƯỢC COMMIT LÊN GIT
// ================================
// File này import từ config_secret.dart (file secret không được commit)
// Nếu không tìm thấy config_secret.dart, app sẽ báo lỗi compile
//
// Để setup:
// 1. Copy config_secret_example.dart thành config_secret.dart
// 2. Điền các giá trị thật của bạn vào config_secret.dart
// 3. File config_secret.dart đã được thêm vào .gitignore

import 'config_secret.dart';

class Config {
  // Gemini API Configuration
  static const String geminiApiKey = ConfigSecret.geminiApiKey;

  // Firebase Configuration
  static const String firebaseUrl = ConfigSecret.firebaseUrl;

  // ZaloPay Configuration
  static const int zalopayAppId = ConfigSecret.zalopayAppId;
  static const String zalopayKey1 = ConfigSecret.zalopayKey1;
  static const String zalopayCreateUrl = ConfigSecret.zalopayCreateUrl;
  static const String zalopayDeepLinkScheme =
      ConfigSecret.zalopayDeepLinkScheme;
}
