import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class PostService {
  Future<List<Post>> fetchPosts() async {
    final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/posts'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((json) => Post.fromJson(json))
          .toList();
    } else {
      throw Exception('Error al cargar los posts');
    }
  }
}
