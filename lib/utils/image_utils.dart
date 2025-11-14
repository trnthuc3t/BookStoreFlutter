import '../constants/api_constants.dart';

/// Utilities for handling image URLs from API
class ImageUtils {
  /// Build full image URL from relative path or absolute URL
  ///
  /// Handles:
  /// - Relative paths: /uploads/books/xxx.jpg → baseUrl + path
  /// - Absolute URLs: https://... → return as is
  /// - Legacy absolute URLs with different port → return as is (for backward compatibility)
  /// - Windows backslash (\) to forward slash (/)
  static String? buildImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    // Fix backslash issue (Windows path)
    String normalizedUrl = url.replaceAll('\\', '/');

    // If already absolute URL, return as is
    if (normalizedUrl.startsWith('http://') || normalizedUrl.startsWith('https://')) {
      return normalizedUrl;
    }

    // If relative path, build full URL with current baseUrl
    // Remove leading slash if exists to avoid double slash
    String relativePath = normalizedUrl.startsWith('/')
        ? normalizedUrl.substring(1)
        : normalizedUrl;

    return '${ApiConstants.baseUrl}/$relativePath';
  }

  /// Normalize image URL (deprecated, use buildImageUrl instead)
  @Deprecated('Use buildImageUrl instead')
  static String? normalizeImageUrl(String? url) {
    return buildImageUrl(url);
  }

  /// Get primary image URL from images array
  static String? getPrimaryImageUrl(List<dynamic>? images) {
    if (images == null || images.isEmpty) {
      return null;
    }

    // Try to find primary image first
    for (var image in images) {
      if (image is Map && image['is_primary'] == true) {
        return buildImageUrl(image['url']);
      }
    }

    // If no primary image, return first image
    if (images[0] is Map && images[0]['url'] != null) {
      return buildImageUrl(images[0]['url']);
    }

    return null;
  }

  /// Get all image URLs from images array
  static List<String> getAllImageUrls(List<dynamic>? images) {
    if (images == null || images.isEmpty) {
      return [];
    }

    List<String> urls = [];
    for (var image in images) {
      if (image is Map && image['url'] != null) {
        String? fullUrl = buildImageUrl(image['url']);
        if (fullUrl != null) {
          urls.add(fullUrl);
        }
      }
    }

    return urls;
  }
}
