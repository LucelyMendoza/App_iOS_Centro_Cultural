import 'package:hive/hive.dart';

part 'painting.g.dart';

@HiveType(typeId: 0)

class Painting {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String imagePath;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String details;
  @HiveField(4)
  final String gallery;
  @HiveField(5)
  final String year;
  @HiveField(6)
  final String author;

  Painting({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.details,
    required this.gallery,
    required this.year,
    required this.author,
  });
}