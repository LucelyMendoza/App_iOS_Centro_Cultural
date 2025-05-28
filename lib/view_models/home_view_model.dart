import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class HomeState {
  final Artist? featuredArtist;
  final List<Gallery> galleries;

  HomeState({required this.featuredArtist, required this.galleries});

  factory HomeState.initial() {
    return HomeState(featuredArtist: null, galleries: []);
  }

  HomeState copyWith({Artist? featuredArtist, List<Gallery>? galleries}) {
    return HomeState(
      featuredArtist: featuredArtist ?? this.featuredArtist,
      galleries: galleries ?? this.galleries,
    );
  }
}

class Artist {
  final String name;
  final String username;
  final String image;

  Artist({required this.name, required this.username, required this.image});
}

class Gallery {
  final String title;
  final String location;
  final String image;

  Gallery({required this.title, required this.location, required this.image});
}
