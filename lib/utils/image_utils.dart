/// Utilities for handling image URLs from API
class ImageUtils {
  /// Normalize image URL by fixing backslashes and ensuring proper format
  ///
  /// Fixes:
  /// - Windows backslash (\) to forward slash (/)
  /// - Ensures proper URL format
  static String? normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    // Fix backslash issue (Windows path)
    String normalizedUrl = url.replaceAll('\\', '/');

    // Ensure URL starts with http:// or https://
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      // If it's a relative path, you might want to add base URL here
      return null;
    }

    return normalizedUrl;
  }

  /// Get primary image URL from images array
  static String? getPrimaryImageUrl(List<dynamic>? images) {
    if (images == null || images.isEmpty) {
      return null;
    }

    // Try to find primary image first
    for (var image in images) {
      if (image is Map && image['is_primary'] == true) {
        return normalizeImageUrl(image['url']);
      }
    }

    // If no primary image, return first image
    if (images[0] is Map && images[0]['url'] != null) {
      return normalizeImageUrl(images[0]['url']);
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
        String? normalizedUrl = normalizeImageUrl(image['url']);
        if (normalizedUrl != null) {
          urls.add(normalizedUrl);
        }
      }
    }

    return urls;
  }
}










