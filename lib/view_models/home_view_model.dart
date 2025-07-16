import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_state.dart';
import '../models/artist.dart';
import '../models/gallery.dart';
import '../services/gallery_service.dart'; // Nuevo import
import '../views/gallery_detail.dart';

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  return HomeViewModel();
});

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel() : super(HomeState.initial()) {
    loadDataFromFirebase();
  }

  final GalleryService _galleryService = GalleryService();

  Future<void> loadDataFromFirebase() async {
    try {
      final galleries = await _galleryService.fetchGalleries();
      state = state.copyWith(
        galleries: galleries,
        featuredArtist: Artist(
          name: 'Vincent van Gogh',
          username: 'Van Gogh',
          image:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZJZsgFnT4zllhftV4Q6BzbiaNUbbSPg68Zg&s',
        ),
      );
    } catch (e) {
      print('Error al cargar datos: $e');
    }
  }

  void goToGalleryDetail(BuildContext context, Gallery gallery) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GalleryDetail(gallery: gallery)),
    );
  }
}
