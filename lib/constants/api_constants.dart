class ApiConstants {

  static const String baseUrl = 'https://xrjssx4r-8000.asse.devtunnels.ms';


  // API Endpoints
  static const String apiPrefix = '/api';

  // Authentication
  static const String registerUrl = '$baseUrl$apiPrefix/auth/register';
  static const String loginUrl = '$baseUrl$apiPrefix/auth/login';
  static const String checkUsernameUrl =
      '$baseUrl$apiPrefix/auth/check-username';
  static const String checkEmailUrl = '$baseUrl$apiPrefix/auth/check-email';

  // Users
  static const String usersUrl = '$baseUrl$apiPrefix/users';
  static const String userAddressesUrl = '$baseUrl$apiPrefix/users';

  // Books
  static const String booksUrl = '$baseUrl$apiPrefix/books';
  static const String bookReviewsUrl = '$baseUrl$apiPrefix/books';

  // Categories
  static const String categoriesUrl = '$baseUrl$apiPrefix/categories';

  // Cart
  static const String cartUrl = '$baseUrl$apiPrefix/cart';

  // Wishlist
  static const String wishlistUrl = '$baseUrl$apiPrefix/wishlist';

  // Orders
  static const String ordersUrl = '$baseUrl$apiPrefix/orders';

  // Search
  static const String searchUrl = '$baseUrl$apiPrefix/search/books';

  // Admin
  static const String adminUrl = '$baseUrl$apiPrefix/admin';
  static const String adminOrdersUrl = '$adminUrl/orders';
  static const String adminUsersUrl = '$adminUrl/users';
  static const String adminBooksUrl = '$adminUrl/books';
  static const String adminDashboardUrl = '$adminUrl/dashboard';

  // Stats
  static const String statsUrl = '$baseUrl$apiPrefix/stats';

  // Health
  static const String healthUrl = '$baseUrl/health';
  static const String apiHealthUrl = '$baseUrl$apiPrefix/health';
}
