import '../models/painting.dart';

class PaintingsViewModel {
  List<Painting> allPaintings = [
    Painting(
      imagePath: 'assets/libertad.png',
      title: 'La Libertad',
      details: 'Representación de la libertad en la historia del Perú.',
      gallery: 'Galería 2',
      year: '1821',
      author: 'Juan Pérez',
    ),
    Painting(
      imagePath: 'assets/misti.png',
      title: 'Volcán Misti',
      details: 'El majestuoso volcán Misti en un atardecer arequipeño.',
      gallery: 'Galería 3',
      year: '2020',
      author: 'María García',
    ),
    Painting(
      imagePath: 'assets/atardecer.jpg',
      title: 'Atardecer Andino',
      details: 'Un atardecer en los Andes peruanos lleno de color.',
      gallery: 'Galería 1',
      year: '2018',
      author: 'Carlos Huamán',
    ),
  ];

  List<Painting> filterPaintings(String query) {
    return allPaintings.where((painting) =>
      painting.title.toLowerCase().contains(query.toLowerCase()) ||
      painting.author.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}