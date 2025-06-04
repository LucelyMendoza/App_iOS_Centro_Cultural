import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_state.dart';
import '../models/artist.dart';
import '../models/gallery.dart';

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel();
});

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel() : super(HomeState.initial()) {
    _loadMockData();
  }

  void _loadMockData() {
    state = state.copyWith(
      featuredArtist: Artist(
        name: 'Rommel Paredes',
        username: '@rommelparedes',
        image: 'assets/prueba.jpg',
      ),
      galleries: [
        Gallery(title: 'Galería I', location: 'Primer patio', image: 'assets/prueba.jpg'),
        Gallery(title: 'Galería II', location: 'Primer patio', image: 'assets/prueba.jpg'),
        Gallery(title: 'Galería III', location: 'Primer patio', image: 'assets/prueba.jpg'),
        Gallery(title: 'Galería IV', location: 'Primer patio', image: 'assets/prueba.jpg'),
        Gallery(title: 'Galería V', location: 'Pasadillo II', image: 'assets/prueba.jpg'),
        Gallery(title: 'Galería VI', location: 'Segundo patio', image: 'assets/prueba.jpg'),
        Gallery(title: 'Galería VII', location: 'Tercer patio', image: 'assets/prueba.jpg'),
      ],
    );
  }
}