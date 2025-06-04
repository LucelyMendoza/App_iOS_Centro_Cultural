// lib/providers/post_provider.dart
import 'package:flutter/material.dart';
import 'package:chopper/chopper.dart';
import '../api/post_service.dart';
import '../models/post_model.dart';

class PostProvider with ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final service = PostService.create();
      final response = await service.getPosts();
      
      if (response.isSuccessful) {
        _posts = response.body ?? [];
      } else {
        _error = "Error HTTP ${response.statusCode}: ${response.error}";
      }
    } on FormatException catch (e) {
      _error = "Error de formato: ${e.message}";
    } catch (e) {
      _error = "Error desconocido: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}