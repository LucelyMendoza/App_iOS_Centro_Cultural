import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/painting.dart';

final paintingStorageProvider = FutureProvider<PaintingStorage>((ref) async {
  final storage = PaintingStorage();
  await storage.init();
  return storage;
});

class PaintingStorage {
  static const String _boxName = 'paintingsBox';
  late Box<Painting> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(PaintingAdapter());
    _box = await Hive.openBox<Painting>(_boxName);
  }

  Future<void> savePainting(Painting painting) async {
    await _box.put(painting.id, painting);
  }

  List<Painting> getAllPaintings() {
    return _box.values.toList();
  }

  Future<void> deletePainting(String id) async {
    await _box.delete(id);
  }

  int get paintingCount => _box.length;
}
