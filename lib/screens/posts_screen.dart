// lib/screens/posts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';

class PostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Publicaciones")),
      body: postProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: postProvider.posts.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(postProvider.posts[i].title),
                subtitle: Text(postProvider.posts[i].body),
              ),
            ),
    );
  }
}