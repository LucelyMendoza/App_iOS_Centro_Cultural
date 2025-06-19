import 'package:flutter/material.dart';
import '../models/painting.dart';
import '../services/painting_service.dart';
import '../views/painting_detail_screen.dart';

class PaintingsViewModel extends ChangeNotifier {
  List<Painting> allPaintings = [];
  final PaintingService _service = PaintingService();

  Future<void> loadPaintings() async {
    allPaintings = await _service.fetchAllPaintings();
    notifyListeners();
  }

  List<Painting> filterPaintings(String query) {
    return allPaintings
        .where(
          (p) =>
              p.title.toLowerCase().contains(query.toLowerCase()) ||
              p.author.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  void goToPaintingDetail(BuildContext context, Painting painting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaintingDetailScreen(painting: painting),
      ),
    );
  }
}
