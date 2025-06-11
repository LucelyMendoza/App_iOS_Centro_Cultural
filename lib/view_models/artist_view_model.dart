import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';
import '../services/database_service.dart';

class ArtistViewModel extends Notifier<List<Artist>> {
  final _db = DatabaseService();

  @override
  List<Artist> build() {
    fetchArtists();
    return [];
  }

  Future<void> fetchArtists() async {
    final artists = await _db.getArtists();
    state = artists;
  }

  Future<void> addArtist(Artist artist) async {
    await _db.insertArtist(artist);
    await fetchArtists();
  }

  Future<void> updateArtist(Artist artist) async {
    await _db.updateArtist(artist);
    await fetchArtists();
  }

  Future<void> deleteArtist(int id) async {
    await _db.deleteArtist(id);
    await fetchArtists();
  }
}

final artistProvider =
    NotifierProvider<ArtistViewModel, List<Artist>>(() => ArtistViewModel());
