// lib/models/gallery.dart
import 'painting.dart';

class Gallery {
  final String id;
  final String title;
  final String location;
  final String image;
  final List<Painting> paintings;

  Gallery({
    required this.id,
    required this.title,
    required this.location,
    required this.image,
    required this.paintings,
  });

  factory Gallery.fromMap(
    String id,
    Map<String, dynamic> data,
    List<Painting> paintings,
  ) {
    return Gallery(
      id: id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      image: data['image'] ?? '',
      paintings: paintings,
    );
  }
}
