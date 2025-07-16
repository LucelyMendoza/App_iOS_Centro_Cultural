import 'dart:math';
import '../models/point3d.dart';
import '../models/painting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../views/kalman_filter.dart';

class HybridLocalizationService {
  final Map<String, Point3D> beaconPositions;
  final Map<String, Map<String, double>> fingerprintDatabase = {};
  List<Painting> _paintings = [];
  final KalmanFilter3D _kalmanFilter = KalmanFilter3D();

  HybridLocalizationService({required this.beaconPositions});

  List<MapEntry<String, double>> _findKNearestNeighbors(
    Map<String, double> currentRSSI,
    int k,
  ) {
    final distances = <String, double>{};

    for (final entry in fingerprintDatabase.entries) {
      double distance = 0;
      for (final beaconId in currentRSSI.keys) {
        if (entry.value.containsKey(beaconId)) {
          distance += pow(currentRSSI[beaconId]! - entry.value[beaconId]!, 2);
        }
      }
      distances[entry.key] = sqrt(distance);
    }

    final sortedDistances = distances.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sortedDistances.take(k).toList();
  }

  Point3D? knnFingerprintLocalization(
    Map<String, double> currentRSSI, {
    int k = 3,
  }) {
    final neighbors = _findKNearestNeighbors(currentRSSI, k);

    if (neighbors.isEmpty) return null;

    double x = 0, y = 0, z = 0;
    double totalWeight = 0;

    for (final neighbor in neighbors) {
      final coords = neighbor.key.split('_');
      final weight = 1 / (neighbor.value + 0.0001); // Evitar división por cero

      x += double.parse(coords[0]) * weight;
      y += double.parse(coords[1]) * weight;
      z += double.parse(coords[2]) * weight;
      totalWeight += weight;
    }

    return Point3D(x: x / totalWeight, y: y / totalWeight, z: z / totalWeight);
  }

  // Fase offline: Construir base de datos de fingerprints
  Future<void> buildFingerprintDatabase() async {
    // Aquí puedes agregar puntos de referencia conocidos con sus RSSI
    // Por ejemplo, para cada pintura, registrar los valores RSSI esperados
    await _loadPaintings();

    // Ejemplo de fingerprints para algunas posiciones conocidas
    _addFingerprintData();
  }

  void _addFingerprintData() {
    // Ejemplos de fingerprints para posiciones conocidas
    // Formato: posición -> {beaconId: rssi_promedio}

    fingerprintDatabase['0.5_2.0_1.8'] = {
      'F5:15:6D:1E:BE:64': -65.0,
      'C8:FC:FC:6D:94:75': -75.0,
      'EB:01:6C:5F:23:82': -55.0,
    };

    fingerprintDatabase['1.0_2.5_1.5'] = {
      'F5:15:6D:1E:BE:64': -70.0,
      'C8:FC:FC:6D:94:75': -60.0,
      'EB:01:6C:5F:23:82': -80.0,
    };

    // Agregar más fingerprints según tu espacio
  }

  // En HybridLocalizationService
  Future<void> loadFingerprintsFromFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fingerprints')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final position = doc.id; // Formato "x_y_z"
        final rssiValues = Map<String, double>.from(data['rssi_values']);

        fingerprintDatabase[position] = rssiValues;
      }
    } catch (e) {
      print("Error loading fingerprints: $e");
      // Mantener datos hardcodeados como fallback
      _addFingerprintData();
    }
  }

  Future<void> loadPaintingsFromFirestore() async {
    try {
      _paintings = [];
      final db = FirebaseFirestore.instance;

      // Obtener todas las galerías
      final galleriesSnapshot = await db.collection('galerias').get();

      for (final galleryDoc in galleriesSnapshot.docs) {
        final paintingsSnapshot = await galleryDoc.reference
            .collection('pinturas')
            .get();

        for (final paintingDoc in paintingsSnapshot.docs) {
          final data = paintingDoc.data();
          _paintings.add(Painting.fromMap(data, galleryDoc.id));
        }
      }
    } catch (e) {
      print("Error cargando pinturas: $e");
      // Cargar datos de respaldo si es necesario
      _loadBackupPaintings();
    }
  }

  Future<void> _loadPaintings() async {
    try {
      _paintings = []; // Limpiar lista antes de cargar

      final db = FirebaseFirestore.instance;
      final gallerySnapshot = await db
          .collection('galerias')
          .doc('galeria1')
          .get();

      if (gallerySnapshot.exists) {
        final paintingsSnapshot = await gallerySnapshot.reference
            .collection('pinturas')
            .orderBy(
              'posicion',
            ) // Asume que tienes un campo 'posicion' para orden
            .get();

        for (final paintingDoc in paintingsSnapshot.docs) {
          final data = paintingDoc.data();
          final positionData = data['posicion'] as Map<String, dynamic>;

          _paintings.add(
            Painting(
              title: data['titulo'] ?? 'Sin título',
              author: data['autor'] ?? 'Autor desconocido',
              year: data['año']?.toString() ?? 'Año desconocido',
              details: data['descripcion'] ?? 'Descripción no disponible',
              imagePath: data['imagen_url'] ?? 'assets/default_painting.jpg',
              gallery: 'Galería 1',
              position: Point3D(
                x: (positionData['x'] as num).toDouble(),
                y: (positionData['y'] as num).toDouble(),
                z: (positionData['z'] as num).toDouble(),
              ),
              detectionRadius:
                  (data['radio_deteccion'] as num?)?.toDouble() ?? 0.8,
            ),
          );
        }
      }
    } catch (e) {
      print("Error cargando pinturas: $e");
      // Opcional: cargar datos de respaldo
      _loadBackupPaintings();
    }
  }

  void _loadBackupPaintings() {
    _paintings = [
      // Datos de respaldo por si falla Firestore
      Painting(
        title: "Pintura de respaldo 1",
        author: "Artista desconocido",
        year: "2023",
        details: "Descripción de ejemplo",
        imagePath: "assets/default_painting.jpg",
        gallery: "Galería 1",
        position: Point3D(x: 0.5, y: 0.5, z: 1.5),
        detectionRadius: 0.8,
      ),
      // ... otras pinturas de respaldo
    ];
  }

  // Trilateración 3D (solo necesitas 3 beacons para posición aproximada)
  Point3D? trilaterate3D(Map<String, double> beaconDistances) {
    if (beaconDistances.length < 2)
      return null; // Cambiar de 3 a 2 beacons mínimos

    final beacons = beaconDistances.keys.take(3).toList();
    final positions = beacons
        .map((id) => beaconPositions[id])
        .where((p) => p != null)
        .cast<Point3D>()
        .toList();
    final distances = beacons.map((id) => beaconDistances[id]!).toList();

    if (positions.length < 2) return null;

    try {
      if (positions.length == 2) {
        // CASO DE 2 BEACONS: calcular punto medio ponderado
        final p1 = positions[0];
        final p2 = positions[1];
        final d1 = distances[0];
        final d2 = distances[1];

        final totalDistance = d1 + d2;
        final weight1 = 1.0 - (d1 / totalDistance);
        final weight2 = 1.0 - (d2 / totalDistance);

        return Point3D(
          x: (p1.x * weight1 + p2.x * weight2) / (weight1 + weight2),
          y: (p1.y * weight1 + p2.y * weight2) / (weight1 + weight2),
          z: 1.5, // Altura fija
        );
      } else {
        // CASO DE 3+ BEACONS: trilateración normal
        final p1 = positions[0];
        final p2 = positions[1];
        final p3 = positions[2];

        final d1 = distances[0];
        final d2 = distances[1];
        final d3 = distances[2];

        final A = 2 * (p2.x - p1.x);
        final B = 2 * (p2.y - p1.y);
        final C = 2 * (p2.z - p1.z);

        final D =
            pow(d1, 2) -
            pow(d2, 2) -
            pow(p1.x, 2) +
            pow(p2.x, 2) -
            pow(p1.y, 2) +
            pow(p2.y, 2) -
            pow(p1.z, 2) +
            pow(p2.z, 2);

        final E = 2 * (p3.x - p2.x);
        final F = 2 * (p3.y - p2.y);

        final H =
            pow(d2, 2) -
            pow(d3, 2) -
            pow(p2.x, 2) +
            pow(p3.x, 2) -
            pow(p2.y, 2) +
            pow(p3.y, 2) -
            pow(p2.z, 2) +
            pow(p3.z, 2);

        final denominator = A * F - B * E;
        if (denominator.abs() < 0.001) return null;

        final x = (D * F - B * H) / denominator;
        final y = (A * H - D * E) / denominator;
        final z = 1.5; // Altura fija más simple

        return Point3D(x: x, y: y, z: z);
      }
    } catch (e) {
      print("Error en trilateración 3D: $e");
      return null;
    }
  }

  // Fingerprinting: Encontrar posición más similar
  Point3D? fingerprintLocalization(Map<String, double> currentRSSI) {
    double bestMatch = double.infinity;
    String? bestPosition;

    for (final entry in fingerprintDatabase.entries) {
      final fingerprint = entry.value;
      double distance = 0;

      // Calcular distancia euclidiana entre fingerprints
      for (final beaconId in currentRSSI.keys) {
        if (fingerprint.containsKey(beaconId)) {
          distance += pow(currentRSSI[beaconId]! - fingerprint[beaconId]!, 2);
        }
      }

      distance = sqrt(distance);
      if (distance < bestMatch) {
        bestMatch = distance;
        bestPosition = entry.key;
      }
    }

    if (bestPosition != null) {
      final coords = bestPosition.split('_');
      return Point3D(
        x: double.parse(coords[0]),
        y: double.parse(coords[1]),
        z: double.parse(coords[2]),
      );
    }

    return null;
  }

  // Técnica híbrida: Combinar trilateración y fingerprinting
  // En hybrid_localization_service.dart
  Point3D? hybridLocalization(
    Map<String, double> beaconDistances,
    Map<String, int> beaconRSSI,
  ) {
    final filteredRSSI = <String, double>{};
    beaconRSSI.forEach((id, rssi) {
      // Aquí podrías aplicar otro filtro Kalman para RSSI si es necesario
      filteredRSSI[id] = rssi.toDouble();
    });

    final rssiDouble = beaconRSSI.map((k, v) => MapEntry(k, v.toDouble()));

    // Obtener resultados
    final trilaterationResult = trilaterate3D(beaconDistances);
    final fingerprintResult = knnFingerprintLocalization(rssiDouble);

    Point3D? combinedResult;

    if (trilaterationResult != null && fingerprintResult != null) {
      combinedResult = Point3D(
        x: (trilaterationResult.x * 0.6 + fingerprintResult.x * 0.4),
        y: (trilaterationResult.y * 0.6 + fingerprintResult.y * 0.4),
        z: 1.5, // Altura fija del usuario
      );
    } else {
      combinedResult = trilaterationResult ?? fingerprintResult;
    }

    // Aplicar filtro de Kalman si tenemos resultado
    return combinedResult != null ? _kalmanFilter.update(combinedResult) : null;
  }

  // Encontrar pinturas cercanas
  List<Painting> getNearbyPaintings(Point3D position, {double radius = 1.0}) {
    return _paintings.where((painting) {
      if (painting.position == null) return false;

      final distance = position.distanceTo(painting.position!);
      final effectiveRadius = painting.detectionRadius * 1.2; // Pequeño margen

      return distance <= effectiveRadius;
    }).toList();
  }
}
