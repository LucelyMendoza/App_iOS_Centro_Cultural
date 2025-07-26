import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/painting.dart';

class PaintingService {
  Future<List<Painting>> fetchPaintingsFromGallery(String galleryId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('galerias')
        .doc(galleryId)
        .collection('pinturas')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Painting.fromMap(
        data,
        galleryId,
      ); // Asegúrate de que `fromMap` exista
    }).toList();
  }

  Future<List<Painting>> fetchAllPaintings() async {
    final db = FirebaseFirestore.instance;
    final paintings = <Painting>[];

    final galleriesSnapshot = await db.collection('galerias').get();
    print('🔍 Número de galerías: ${galleriesSnapshot.docs.length}');

    for (final doc in galleriesSnapshot.docs) {
      final galleryTitle = doc.data()['title'];
      print('🎨 Galería encontrada: $galleryTitle');

      final paintingsSnapshot = await doc.reference
          .collection('pinturas')
          .get();
      print('🖼️ Pinturas en $galleryTitle: ${paintingsSnapshot.docs.length}');

      for (final paintingDoc in paintingsSnapshot.docs) {
        final data = paintingDoc.data();
        print('✅ Pintura cargada: ${data['title']} por ${data['author']}');

        paintings.add(
          Painting(
            title: data['title'],
            author: data['author'],
            year: data['year'],
            details: data['details'],
            imagePath: data['imagePath'],
            gallery: galleryTitle,
          ),
        );
      }
    }

    return paintings;
  }
}
