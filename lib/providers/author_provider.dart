import 'package:flutter/foundation.dart';
import '../models/author.dart';
import '../services/api_service.dart';

class AuthorProvider with ChangeNotifier {
  List<Author> _authors = [];
  bool _isLoading = false;
  String? _error;

  List<Author> get authors => _authors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAuthors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> authorsJson = await ApiService.getAuthors();
      _authors = authorsJson.map((json) => Author.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
      _authors = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
