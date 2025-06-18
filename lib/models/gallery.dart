import 'painting.dart';

class Gallery {
  final String title;
  final String location;
  final String image;
  final List<Painting> paintings;

  Gallery({
    required this.title,
    required this.location,
    required this.image,
    this.paintings = const [],
  });
}
