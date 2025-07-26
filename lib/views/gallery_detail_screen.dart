import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_app/models/painting.dart';

class GalleryDetailScreen extends StatefulWidget {
  final String galleryName;

  const GalleryDetailScreen({super.key, required this.galleryName});

  @override
  State<GalleryDetailScreen> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends State<GalleryDetailScreen> {
  List<Painting> paintings = [];

  @override
  void initState() {
    super.initState();
    fetchPaintings();
  }

  void fetchPaintings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('galerias')
        .doc(widget.galleryName)
        .collection('pinturas')
        .get();

    setState(() {
      paintings = snapshot.docs.map((doc) {
        return Painting.fromMap(doc.data(), widget.galleryName);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pinturas de ${widget.galleryName}')),
      body: paintings.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
                  ),
                  title: Text(painting.title),
                  subtitle: Text('${painting.author} - ${painting.year}'),
                );
              },
            ),
    );
  }
}
