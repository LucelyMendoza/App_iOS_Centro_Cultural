import 'artist.dart';
import 'gallery.dart';

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