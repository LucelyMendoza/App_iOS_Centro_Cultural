import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/painting.dart';

class PaintingService {
  Future<List<Painting>> fetchAllPaintings() async {
    final db = FirebaseFirestore.instance;
    final paintings = <Painting>[];

    final galleriesSnapshot = await db.collection('galerias').get();

    for (final doc in galleriesSnapshot.docs) {
      final galleryTitle = doc.data()['title'];
      final paintingsSnapshot = await doc.reference
          .collection('pinturas')
          .get();

      for (final paintingDoc in paintingsSnapshot.docs) {
        final data = paintingDoc.data();
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
