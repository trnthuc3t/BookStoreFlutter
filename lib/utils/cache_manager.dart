import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple cache manager for storing API responses
class CacheManager {
  static const String _bookPrefix = 'book_cache_';
  static const String _reviewsPrefix = 'reviews_cache_';
  static const String _featuredBooksPrefix = 'featured_books_cache';
  static const String _timestampPrefix = 'cache_timestamp_';
  static const Duration _defaultExpiry = Duration(minutes: 15);
  static const Duration _featuredExpiry = Duration(hours: 1); // Featured books cache longer

  /// Save book data to cache
  static Future<void> cacheBook(int bookId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString('$_bookPrefix$bookId', jsonString);
      await prefs.setInt(
          '$_timestampPrefix$bookId', DateTime.now().millisecondsSinceEpoch);
      print('💾 Saved book #$bookId to disk cache');
    } catch (e) {
      print('❌ Error saving book to cache: $e');
    }
  }

  /// Get book data from cache
  static Future<Map<String, dynamic>?> getCachedBook(int bookId,
      {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_bookPrefix$bookId');
      final timestamp = prefs.getInt('$_timestampPrefix$bookId');

      if (jsonString == null || timestamp == null) {
        return null;
      }

      // Check if cache is expired
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final expiryDuration = expiry ?? _defaultExpiry;

      if (now.difference(cacheTime) > expiryDuration) {
        print('⏰ Book #$bookId cache expired');
        await clearBookCache(bookId);
        return null;
      }

      print('✅ Retrieved book #$bookId from disk cache');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting cached book: $e');
      return null;
    }
  }

  /// Save reviews data to cache
  static Future<void> cacheReviews(int bookId, List<dynamic> reviews) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(reviews);
      await prefs.setString('$_reviewsPrefix$bookId', jsonString);
      print('💾 Saved ${reviews.length} reviews for book #$bookId to disk cache');
    } catch (e) {
      print('❌ Error saving reviews to cache: $e');
    }
  }

  /// Get reviews data from cache
  static Future<List<dynamic>?> getCachedReviews(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_reviewsPrefix$bookId');

      if (jsonString == null) {
        return null;
      }

      print('✅ Retrieved reviews for book #$bookId from disk cache');
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('❌ Error getting cached reviews: $e');
      return null;
    }
  }

  /// Clear cache for specific book
  static Future<void> clearBookCache(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_bookPrefix$bookId');
      await prefs.remove('$_reviewsPrefix$bookId');
      await prefs.remove('$_timestampPrefix$bookId');
      print('🗑️ Cleared disk cache for book #$bookId');
    } catch (e) {
      print('❌ Error clearing book cache: $e');
    }
  }

  /// Save featured books to cache
  static Future<void> cacheFeaturedBooks(List<dynamic> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(books);
      await prefs.setString(_featuredBooksPrefix, jsonString);
      await prefs.setInt(
          '${_timestampPrefix}featured', DateTime.now().millisecondsSinceEpoch);
      print('💾 Saved ${books.length} featured books to disk cache');
    } catch (e) {
      print('❌ Error saving featured books to cache: $e');
    }
  }

  /// Get featured books from cache
  static Future<List<dynamic>?> getCachedFeaturedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_featuredBooksPrefix);
      final timestamp = prefs.getInt('${_timestampPrefix}featured');

      if (jsonString == null || timestamp == null) {
        return null;
      }

      // Check if cache is expired
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      if (now.difference(cacheTime) > _featuredExpiry) {
        print('⏰ Featured books cache expired');
        await prefs.remove(_featuredBooksPrefix);
        await prefs.remove('${_timestampPrefix}featured');
        return null;
      }

      print('✅ Retrieved featured books from disk cache');
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('❌ Error getting cached featured books: $e');
      return null;
    }
  }

  /// Clear featured books cache
  static Future<void> clearFeaturedBooksCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_featuredBooksPrefix);
      await prefs.remove('${_timestampPrefix}featured');
      print('🗑️ Cleared featured books disk cache');
    } catch (e) {
      print('❌ Error clearing featured books cache: $e');
    }
  }

  /// Clear all cached books
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_bookPrefix) ||
            key.startsWith(_reviewsPrefix) ||
            key.startsWith(_featuredBooksPrefix) ||
            key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }
      
      print('🗑️ Cleared all disk cache');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  /// Get cache size (number of cached items)
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      return keys.where((key) => key.startsWith(_bookPrefix)).length;
    } catch (e) {
      print('❌ Error getting cache size: $e');
      return 0;
    }
  }
}
