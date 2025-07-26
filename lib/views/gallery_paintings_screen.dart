import 'package:flutter/material.dart';
import '../models/painting.dart';
import 'painting_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryPaintingsScreen extends StatelessWidget {
  final String galleryTitle;
  final List<Painting> paintings;

  const GalleryPaintingsScreen({
    Key? key,
    required this.galleryTitle,
    required this.paintings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(galleryTitle)),
      body: paintings.isEmpty
          ? Center(
              child: Text(
                'No hay pinturas disponibles en esta galería.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: paintings.length,
              itemBuilder: (context, index) {
                final painting = paintings[index];
                return ListTile(
                  leading: Image.network(
                    painting.imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.broken_image),
                  ),
                  title: Text(painting.title),
                  subtitle: Text(painting.author),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PaintingDetailScreen(painting: painting),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
