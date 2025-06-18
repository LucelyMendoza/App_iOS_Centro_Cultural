import 'package:flutter/material.dart';
import '../models/painting.dart';
import '../views/painting_detail_screen.dart';

class PaintingsViewModel {
  List<Painting> allPaintings = [
    Painting(
      imagePath: 'assets/libertad.png',
      title: 'La Libertad',
      details: 'Representación de la libertad en la historia del Perú.',
      gallery: 'Galería II',
      year: '1821',
      author: 'Juan Pérez',
    ),
    Painting(
      imagePath: 'assets/misti.png',
      title: 'Volcán Misti',
      details: 'El majestuoso volcán Misti en un atardecer arequipeño.',
      gallery: 'Galería III',
      year: '2020',
      author: 'María García',
    ),
    Painting(
      imagePath: 'assets/atardecer.jpg',
      title: 'Atardecer Andino',
      details: 'Un atardecer en los Andes peruanos lleno de color.',
      gallery: 'Galería I',
      year: '2018',
      author: 'Carlos Huamán',
    ),
  ];

  List<Painting> filterPaintings(String query) {
    return allPaintings
        .where(
          (painting) =>
              painting.title.toLowerCase().contains(query.toLowerCase()) ||
              painting.author.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  void goToPaintingDetail(BuildContext context, Painting painting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaintingDetailScreen(painting: painting),
      ),
    );
  }
}
