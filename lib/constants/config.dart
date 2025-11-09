
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
