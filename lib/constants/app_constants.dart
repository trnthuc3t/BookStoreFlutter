class AppConstants {
  // Firebase
  static const String firebaseUrl = 'https://booksell-cfee0-default-rtdb.firebaseio.com';
  
  // Order Status
  static const int orderStatusNew = 1;
  static const int orderStatusDoing = 2;
  static const int orderStatusArrived = 3;
  static const int orderStatusComplete = 4;
  static const int orderStatusCancelled = 5;
  
  // ZaloPay
  static const int zalopayAppId = 553;
  static const String zalopayKey1 = '9phuAOYhan4urywHTh0ndEXiV3pKHr5Q';
  static const String zalopayCreateUrl = 'https://sandbox.zalopay.com.vn/v001/tpe/createorder';
  static const String zalopayDeepLinkScheme = 'merchant-deeplink://app';
  
  // Gemini API
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  // SharedPreferences Keys
  static const String userEmailKey = 'user_email';
  static const String isAdminKey = 'is_admin';
  static const String chatHistoryKey = 'chat_history';
  
  // Database Tables
  static const String productTable = 'product';
  static const String cartTable = 'cart';
  
  // App Info
  static const String appName = 'BookSell';
  static const String packageName = 'com.pro.book';
}
