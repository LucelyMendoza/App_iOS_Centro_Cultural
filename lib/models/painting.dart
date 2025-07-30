import 'dart:math';

import 'package:mi_app/models/point3d.dart';
import 'point3d.dart';

class Painting {
  final String imagePath;
  final String title;
  final String details;
  final String gallery;
  final String year;
  final String author;
  final Point3D? position; // Nueva propiedad para posición 3D
  final double detectionRadius; // Radio de detección

  Painting({
    required this.imagePath,
    required this.title,
    required this.details,
    required this.gallery,
    required this.year,
    required this.author,
    this.position,
    this.detectionRadius = 1.0, // 1 metro por defecto
  });

  bool isNearby(double x, double y, double z, {double radius = 1.0}) {
    if (position == null) return false;

    final distance = sqrt(
      pow(position!.x - x, 2) +
          pow(position!.y - y, 2) +
          pow(position!.z - z, 2),
    );

    return distance <= (detectionRadius + radius);
  }

  factory Painting.fromMap(Map<String, dynamic> data, String galleryTitle) {
    return Painting(
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      year: data['year'] ?? '',
      details: data['details'] ?? '',
      imagePath: data['imagePath'] ?? '',
      gallery: galleryTitle,
      position: data['position'] != null
          ? Point3D.fromMap(data['position'])
          : null,
      detectionRadius: data['detectionRadius']?.toDouble() ?? 1.0,
    );
  }
}
