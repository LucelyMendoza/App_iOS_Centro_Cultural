import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/painting.dart';
import '../services/painting_storage.dart';

final paintingsViewModelAsyncProvider = FutureProvider<PaintingsViewModel>((ref) async {
  final storage = await ref.watch(paintingStorageProvider.future);
  return PaintingsViewModel(storage);
});


class PaintingsViewModel extends ChangeNotifier {
  final PaintingStorage storage;
  List<Painting> _paintings = [];
  List<Painting> _allPaintings = []; // Copia de respaldo para búsquedas

  PaintingsViewModel(this.storage) {
    _loadInitialData();
  }

  List<Painting> get paintings => _paintings;

  Future<void> _loadInitialData() async {
    // Cargar pinturas existentes de Hive
    final savedPaintings = storage.getAllPaintings();
    
    // Si no hay datos, cargar ejemplos iniciales
    if (savedPaintings.isEmpty) {
      final examplePaintings = [
        Painting(
          id: '1', // Nuevo campo ID requerido
          imagePath: 'assets/libertad.png',
          title: 'La Libertad',
          details: 'Representación de la libertad en la historia del Perú.',
          gallery: 'Galería 2',
          year: '1821',
          author: 'Juan Pérez',
        ),
        Painting(
          id: '2',
          imagePath: 'assets/misti.png',
          title: 'Volcán Misti',
          details: 'El majestuoso volcán Misti en un atardecer arequipeño.',
          gallery: 'Galería 3',
          year: '2020',
          author: 'María García',
        ),
        Painting(
          id: '3',
          imagePath: 'assets/atardecer.jpg',
          title: 'Atardecer Andino',
          details: 'Un atardecer en los Andes peruanos lleno de color.',
          gallery: 'Galería 1',
          year: '2018',
          author: 'Carlos Huamán',
        ),
      ];
      
      // Guardar en Hive
      for (var painting in examplePaintings) {
        await storage.savePainting(painting);
      }
      _paintings = examplePaintings;
    } else {
      _paintings = savedPaintings;
    }
    
    _allPaintings = List.from(_paintings);
    notifyListeners();
  }

  // Filtrar pinturas
  void filterPaintings(String query) {
    if (query.isEmpty) {
      _paintings = List.from(_allPaintings);
    } else {
      _paintings = _allPaintings.where((painting) =>
        painting.title.toLowerCase().contains(query.toLowerCase()) ||
        painting.author.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  // Añadir nueva pintura
  Future<void> addPainting(Painting newPainting) async {
    await storage.savePainting(newPainting);
    _allPaintings.add(newPainting);
    _paintings = List.from(_allPaintings);
    notifyListeners();
  }

  // Eliminar pintura
  Future<void> deletePainting(String id) async {
    await storage.deletePainting(id);
    _allPaintings.removeWhere((painting) => painting.id == id);
    _paintings = List.from(_allPaintings);
    notifyListeners();
  }
}