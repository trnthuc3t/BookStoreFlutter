import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getStoredToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      print('📝 Token found in storage');
    } else {
      print('📝 No token in storage');
    }
    return token;
  }

  static Future<void> _storeToken(String token) async {
    print('💾 Storing auth token...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('✅ Token stored successfully');
  }

  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('first_name');
    await prefs.remove('last_name');
    await prefs.remove('role');
    await prefs.remove('stored_email');
  }

  // Authentication
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storeToken(data['access_token']);
        return data;
      }

      // Try to parse error detail from response
      String errorMsg = 'Đăng nhập thất bại';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = errorData['detail'] ?? errorMsg;
      } catch (e) {
        print('Could not parse error response');
      }

      throw Exception(errorMsg);
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null) 'phone': phone,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
          // Note: gender field removed from backend
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Try to parse error detail from response
      String errorMsg = 'Đăng ký thất bại';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = errorData['detail'] ?? errorMsg;
      } catch (e) {
        print('Could not parse error response');
      }

      throw Exception(errorMsg);
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    print('🗑️ Removing auth token...');
    await _removeToken();
    print('✅ Auth token removed successfully');
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getStoredToken();
    final isLoggedIn = token != null;
    print(
        '🔍 Checking login status: ${isLoggedIn ? "Logged in" : "Not logged in"}');
    return isLoggedIn;
  }

  // Books
  static Future<List<dynamic>> getBooks({
    int skip = 0,
    int limit = 20,
    int? categoryId,
    String? search,
  }) async {
    try {
      String url = '${ApiConstants.booksUrl}?skip=$skip&limit=$limit';
      if (categoryId != null) url += '&category_id=$categoryId';
      if (search != null) url += '&search=$search';

      print('📡 Calling API: $url'); // Debug log

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      print('📡 API Response Status: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
            '📦 API Response data: ${data.toString().substring(0, data.toString().length > 500 ? 500 : data.toString().length)}'); // Debug log
        final books = data['books'] ?? [];
        print('📚 Number of books returned: ${books.length}'); // Debug log
        if (books.isNotEmpty) {
          print('📸 First book images: ${books[0]['images']}'); // Debug log
        }
        return books;
      }
      return [];
    } catch (e) {
      print('Get books error: $e');
      return [];
    }
  }

  // Get Products (alias for getBooks to match provider usage)
  static Future<List<dynamic>> getProducts({
    int skip = 0,
    int limit = 100,
    int? categoryId,
    bool featuredOnly = false,
    String? search,
  }) async {
    return await getBooks(
      skip: skip,
      limit: limit,
      categoryId: categoryId,
      search: search,
    );
  }

  // Get single Product (alias for getBook)
  static Future<Map<String, dynamic>?> getProduct(int id) async {
    return await getBook(id);
  }

  // Rate product
  static Future<bool> rateProduct(
      int productId, double rate, String? review) async {
    try {
      // This would need to be implemented if rating endpoint exists
      // For now, return true
      return true;
    } catch (e) {
      print('Rate product error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getBook(int bookId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.booksUrl}/$bookId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get book error: $e');
      return null;
    }
  }

  // Categories
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.categoriesUrl),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['categories'] ?? [];
      }
      return [];
    } catch (e) {
      print('Get categories error: $e');
      return [];
    }
  }

  /// Get all authors
  static Future<List<dynamic>> getAuthors() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/authors'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['authors'] ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Get authors error: $e');
      return [];
    }
  }

  /// Create new author
  static Future<Map<String, dynamic>?> createAuthor(String penName) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/authors?pen_name=$penName'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Created author: $penName');
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Create author error: $e');
      return null;
    }
  }

  // Cart
  static Future<Map<String, dynamic>?> getCart(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.cartUrl}/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get cart error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> addToCart({
    required int userId,
    required int bookId,
    int quantity = 1,
  }) async {
    try {
      final url =
          '${ApiConstants.cartUrl}?user_id=$userId&book_id=$bookId&quantity=$quantity';
      print('🛒 POST $url');

      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      print('🛒 Add to cart response: ${response.statusCode}');
      print('🛒 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
            '❌ Add to cart failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Add to cart error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.cartUrl}/$cartItemId'),
        headers: await _getHeaders(),
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Update cart item error: $e');
      return null;
    }
  }

  static Future<bool> removeCartItem(int cartItemId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.cartUrl}/$cartItemId'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Remove cart item error: $e');
      return false;
    }
  }

  // Wishlist
  static Future<Map<String, dynamic>?> getWishlist(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.wishlistUrl}/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get wishlist error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> addToWishlist({
    required int userId,
    required int bookId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConstants.wishlistUrl}?user_id=$userId&book_id=$bookId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Add to wishlist error: $e');
      return null;
    }
  }

  static Future<bool> removeFromWishlist(int wishlistItemId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.wishlistUrl}/$wishlistItemId'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Remove from wishlist error: $e');
      return false;
    }
  }

  // Search
  static Future<List<dynamic>> searchBooks({
    required String query,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'relevance',
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      String url =
          '${ApiConstants.searchUrl}?q=$query&skip=$skip&limit=$limit&sort_by=$sortBy';
      if (categoryId != null) url += '&category_id=$categoryId';
      if (minPrice != null) url += '&min_price=$minPrice';
      if (maxPrice != null) url += '&max_price=$maxPrice';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['books'] ?? [];
      }
      return [];
    } catch (e) {
      print('Search books error: $e');
      return [];
    }
  }

  // Orders

  // User
  static Future<Map<String, dynamic>?> getCurrentUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.usersUrl}/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Addresses
  static Future<List<dynamic>> getUserAddresses(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.usersUrl}/$userId/addresses'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['addresses'] ?? [];
      }
      return [];
    } catch (e) {
      print('Get addresses error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createAddress({
    required int userId,
    required Map<String, dynamic> addressData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.usersUrl}/$userId/addresses'),
        headers: await _getHeaders(),
        body: jsonEncode(addressData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Create address error: $e');
      return null;
    }
  }

  // Review
  static Future<Map<String, dynamic>?> createBookReview({
    required int bookId,
    required int userId,
    required int rating,
    String? title,
    String? comment,
    String? pros,
    String? cons,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.booksUrl}/$bookId/reviews?user_id=$userId'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'rating': rating,
          if (title != null) 'title': title,
          if (comment != null) 'comment': comment,
          if (pros != null) 'pros': pros,
          if (cons != null) 'cons': cons,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Create book review error: $e');
      return null;
    }
  }

  // ============================================
  // ADMIN API METHODS
  // ============================================

  /// Get admin dashboard stats
  static Future<Map<String, dynamic>?> getAdminDashboard() async {
    try {
      print('📊 Calling /api/admin/dashboard...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/dashboard'),
        headers: await _getHeaders(),
      );

      print('📊 Dashboard response status: ${response.statusCode}');
      print('📊 Dashboard response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Dashboard data decoded successfully');
        return data;
      } else {
        print('❌ Dashboard error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ Get admin dashboard error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get all orders for admin
  static Future<List<dynamic>> getAdminOrders({
    int skip = 0,
    int limit = 50,
    String? status,
  }) async {
    try {
      String url =
          '${ApiConstants.baseUrl}/api/admin/orders?skip=$skip&limit=$limit';
      if (status != null) url += '&status=$status';

      print('🛒 Calling $url...');
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      print('🛒 Orders response status: ${response.statusCode}');
      print('🛒 Orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🛒 Orders data decoded: ${data['orders']?.length ?? 0} orders');
        return data['orders'] ?? [];
      } else {
        print('❌ Orders error: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ Get admin orders error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Update order status (admin)
  static Future<bool> updateOrderStatus({
    required int orderId,
    required String status,
    String? paymentStatus,
    String? trackingNumber,
    String? notes,
  }) async {
    try {
      print('🔄 Updating order #$orderId to status: $status');

      final response = await http.put(
        Uri.parse('${ApiConstants.ordersUrl}/$orderId'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'status': status,
          if (paymentStatus != null) 'payment_status': paymentStatus,
          if (trackingNumber != null) 'tracking_number': trackingNumber,
          if (notes != null) 'notes': notes,
        }),
      );

      print('🔄 Update order response status: ${response.statusCode}');
      print('🔄 Update order response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Order status updated successfully');
        return true;
      } else {
        print(
            '❌ Update order error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Update order status error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get all users for admin
  static Future<List<dynamic>> getAdminUsers({
    int skip = 0,
    int limit = 50,
    String? role,
  }) async {
    try {
      String url =
          '${ApiConstants.baseUrl}/api/admin/users?skip=$skip&limit=$limit';
      if (role != null) url += '&role=$role';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['users'] ?? [];
      }
      return [];
    } catch (e) {
      print('Get admin users error: $e');
      return [];
    }
  }

  /// Get all books for admin
  static Future<List<dynamic>> getAdminBooks({
    int skip = 0,
    int limit = 50,
    bool? isActive,
  }) async {
    try {
      String url =
          '${ApiConstants.baseUrl}/api/admin/books?skip=$skip&limit=$limit';
      if (isActive != null) url += '&is_active=$isActive';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['books'] ?? [];
      }
      return [];
    } catch (e) {
      print('Get admin books error: $e');
      return [];
    }
  }

  /// Update book details (admin)
  static Future<bool> updateBook({
    required int bookId,
    String? title,
    String? subtitle,
    String? description,
    double? price,
    double? originalPrice,
    double? discountPercentage,
    int? stockQuantity,
    bool? isActive,
    bool? isFeatured,
    bool? isBestseller,
  }) async {
    try {
      print('📝 Updating book #$bookId...');
      final response = await http.put(
        Uri.parse('${ApiConstants.booksUrl}/$bookId'),
        headers: await _getHeaders(),
        body: jsonEncode({
          if (title != null) 'title': title,
          if (subtitle != null) 'subtitle': subtitle,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (originalPrice != null) 'original_price': originalPrice,
          if (discountPercentage != null)
            'discount_percentage': discountPercentage,
          if (stockQuantity != null) 'stock_quantity': stockQuantity,
          if (isActive != null) 'is_active': isActive,
          if (isFeatured != null) 'is_featured': isFeatured,
          if (isBestseller != null) 'is_bestseller': isBestseller,
        }),
      );

      print('📝 Update book response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Update book error: $e');
      return false;
    }
  }

  /// Upload multiple images for existing book (admin)
  static Future<bool> uploadBookImages({
    required int bookId,
    required List<dynamic> images, // List of XFile
  }) async {
    try {
      print('📸 Uploading ${images.length} images for book #$bookId');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${ApiConstants.baseUrl}/api/books/$bookId/upload-multiple-images'),
      );

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add image files
      for (var image in images) {
        final file = await http.MultipartFile.fromPath(
          'files',
          image.path,
        );
        request.files.add(file);
      }

      print('📤 Sending ${images.length} images...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📸 Upload images response: ${response.statusCode}');
      print('📸 Upload images body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Images uploaded successfully');
        return true;
      } else {
        print(
            '❌ Upload images error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Upload book images error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Create book with images (admin)
  static Future<bool> createBookWithImages({
    required String title,
    String? description,
    String? isbn,
    required double price,
    double? originalPrice,
    required int stockQuantity,
    int? pages,
    int? publicationYear,
    int? categoryId,
    String? language,
    String? coverType,
    double? length,
    double? width,
    double? thickness,
    int? weight,
    List<int>? authorIds, // List of author IDs
    required List<dynamic> images, // List of XFile
  }) async {
    try {
      print('📚 Creating new book: $title');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/books/create-with-image'),
      );

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add fields
      request.fields['title'] = title;
      if (description != null && description.isNotEmpty)
        request.fields['description'] = description;
      if (isbn != null && isbn.isNotEmpty) request.fields['isbn'] = isbn;
      request.fields['price'] = price.toString();
      if (originalPrice != null)
        request.fields['original_price'] = originalPrice.toString();
      request.fields['stock_quantity'] = stockQuantity.toString();
      if (pages != null) request.fields['pages'] = pages.toString();
      if (publicationYear != null)
        request.fields['publication_year'] = publicationYear.toString();
      if (categoryId != null)
        request.fields['category_id'] = categoryId.toString();
      request.fields['language'] = language ?? 'Vietnamese';
      request.fields['cover_type'] = coverType ?? 'paperback';
      if (length != null) request.fields['length'] = length.toString();
      if (width != null) request.fields['width'] = width.toString();
      if (thickness != null) request.fields['thickness'] = thickness.toString();
      if (weight != null) request.fields['weight'] = weight.toString();
      if (authorIds != null && authorIds.isNotEmpty) {
        request.fields['author_ids'] = authorIds.join(',');
      }

      // Add image files
      for (var image in images) {
        final file = await http.MultipartFile.fromPath(
          'files',
          image.path,
        );
        request.files.add(file);
      }

      print('📤 Sending request with ${images.length} images...');
      print(
          '📋 Category ID: $categoryId, Language: $language, Cover: $coverType');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📚 Create book response status: ${response.statusCode}');
      print('📚 Create book response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Book created successfully');
        return true;
      } else {
        print('❌ Create book error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Create book with images error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Update user status (admin)
  static Future<bool> updateUserStatus({
    required int userId,
    required bool isActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/admin/users/$userId/status?is_active=$isActive'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update user status error: $e');
      return false;
    }
  }

  // ============================================
  // ORDER API METHODS
  // ============================================

  /// Create simple order from cart (no address/payment method required)
  static Future<Map<String, dynamic>?> createSimpleOrder({
    required int userId,
    String paymentMethod = 'COD',
    String? notes,
  }) async {
    try {
      print('🛍️ Creating simple order for user $userId...');
      print('💳 Payment method: $paymentMethod');

      final response = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/orders/simple?user_id=$userId&payment_method=$paymentMethod${notes != null ? '&notes=$notes' : ''}'),
        headers: await _getHeaders(),
      );

      print('🛍️ Create order response status: ${response.statusCode}');
      print('🛍️ Create order response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order created successfully: ${data['order_number']}');
        return data;
      } else {
        print(
            '❌ Create order error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Create order error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Create new order (with full details)
  static Future<Map<String, dynamic>?> createOrder({
    required int userId,
    required int shippingAddressId,
    required int paymentMethodId,
    int? voucherId,
    String? notes,
  }) async {
    try {
      print('🛍️ Creating order for user $userId...');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/orders'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'shipping_address_id': shippingAddressId,
          'payment_method_id': paymentMethodId,
          if (voucherId != null) 'voucher_id': voucherId,
          if (notes != null) 'notes': notes,
        }),
      );

      print('🛍️ Create order response status: ${response.statusCode}');
      print('🛍️ Create order response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order created successfully: ${data['order_number']}');
        return data;
      } else {
        print(
            '❌ Create order error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Create order error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get user orders
  static Future<List<dynamic>> getUserOrders({required int userId}) async {
    try {
      print('📦 Getting orders for user $userId...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/orders/$userId'),
        headers: await _getHeaders(),
      );

      print('📦 Orders response status: ${response.statusCode}');
      print('📦 Orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Orders data: ${data['orders']?.length ?? 0} orders');
        return data['orders'] ?? [];
      } else {
        print('❌ Orders error: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ Get user orders error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get order detail by order ID
  static Future<Map<String, dynamic>?> getOrderDetail(
      {required int orderId}) async {
    try {
      print('📦 Getting order detail for order #$orderId...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/orders/$orderId/details'),
        headers: await _getHeaders(),
      );

      print('📦 Order detail response status: ${response.statusCode}');
      print('📦 Order detail response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order detail loaded successfully');
        return data;
      } else {
        print(
            '❌ Order detail error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ Get order detail error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Cancel order (User)
  static Future<bool> cancelOrder({
    required int orderId,
    String? reason,
  }) async {
    try {
      print('🚫 Cancelling order #$orderId...');
      final response = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/orders/$orderId/cancel${reason != null ? '?reason=$reason' : ''}'),
        headers: await _getHeaders(),
      );

      print('🚫 Cancel order response status: ${response.statusCode}');
      print('🚫 Cancel order response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Order cancelled successfully');
        return true;
      } else {
        print(
            '❌ Cancel order error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Cancel order error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}
