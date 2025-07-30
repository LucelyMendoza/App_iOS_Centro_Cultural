import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedGalleryProvider = StateProvider<String?>((ref) => null);

class SelectedGalleryProvider extends ChangeNotifier {
  String? _selectedGallery;

  String? get selectedGallery => _selectedGallery;

  void setGallery(String gallery) {
    _selectedGallery = gallery;
    notifyListeners();
  }

  void clearGallery() {
    _selectedGallery = null;
    notifyListeners();
  }
}
