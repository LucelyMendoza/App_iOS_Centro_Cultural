import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gallery.dart';
import '../models/painting.dart';

class GalleryService {
  Future<List<Gallery>> fetchGalleries() async {
    final db = FirebaseFirestore.instance;
    final querySnapshot = await db.collection('galerias').get();

    List<Gallery> galleries = [];

    for (var doc in querySnapshot.docs) {
      final galleryData = doc.data();
      final paintingsSnapshot = await doc.reference
          .collection('pinturas')
          .get();
      final paintings = paintingsSnapshot.docs.map((paintingDoc) {
        final p = paintingDoc.data();
        print('Cargando pintura: ${p['title']}'); // <--- Agrega esto

        return Painting(
          title: p['title'],
          author: p['author'],
          year: p['year'],
          details: p['details'],
          imagePath: p['imagePath'], // URL
          gallery: galleryData['title'],
        );
      }).toList();
      print(
        'Galería: ${galleryData['title']}, Pinturas cargadas: ${paintings.length}',
      );

      galleries.add(
        Gallery(
          id: doc.id,
          title: galleryData['title'],
          location: galleryData['location'],
          image: galleryData['image'], // URL
          paintings: paintings,
        ),
      );
    }

    return galleries;
  }
}
