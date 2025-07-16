import 'dart:math';
import '../models/point3d.dart';
import '../models/painting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HybridLocalizationService {
  final Map<String, Point3D> beaconPositions;
  final Map<String, Map<String, double>> fingerprintDatabase = {};
  List<Painting> _paintings = [];

  HybridLocalizationService({required this.beaconPositions});

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

  Future<void> _loadPaintings() async {
    // Commented out Firebase code - uncomment when Firebase is properly configured
    /*
    final db = FirebaseFirestore.instance;
    final galleriesSnapshot = await db.collection('galerias').get();

    for (final doc in galleriesSnapshot.docs) {
      final galleryTitle = doc.data()['title'];
      final paintingsSnapshot = await doc.reference
          .collection('pinturas')
          .get();

      for (final paintingDoc in paintingsSnapshot.docs) {
        final data = paintingDoc.data();
        _paintings.add(Painting.fromMap(data, galleryTitle));
      }
    }
    */

    // Static paintings for testing
    _paintings = [
      Painting(
        title: "La Mona Lisa",
        author: "Leonardo da Vinci",
        year: "1503",
        details: "Pintura renacentista famosa",
        imagePath: "assets/monalisa.jpg",
        gallery: "Galería Principal",
        position: Point3D(x: 0.5, y: 0.2, z: 1.5), // Cerca del beacon 1
        detectionRadius: 0.8,
      ),
      Painting(
        title: "La Noche Estrellada",
        author: "Vincent van Gogh",
        year: "1889",
        details: "Obra maestra del postimpresionismo",
        imagePath: "assets/starry_night.jpg",
        gallery: "Galería Principal",
        position: Point3D(x: 2.5, y: 0.2, z: 1.5), // Cerca del beacon 2
        detectionRadius: 0.8,
      ),
      Painting(
        title: "El Grito",
        author: "Edvard Munch",
        year: "1893",
        details: "Expresionismo noruego",
        imagePath: "assets/el_grito.jpg",
        gallery: "Galería Principal",
        position: Point3D(x: 1.5, y: 2.7, z: 1.5), // Cerca del beacon 3
        detectionRadius: 0.8,
      ),
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
    // Convertir RSSI a double
    final rssiDouble = beaconRSSI.map((k, v) => MapEntry(k, v.toDouble()));

    // Obtener resultados
    final trilaterationResult = trilaterate3D(beaconDistances);
    final fingerprintResult = fingerprintLocalization(rssiDouble);

    // Combinar con pesos ajustables
    if (trilaterationResult != null && fingerprintResult != null) {
      return Point3D(
        x: (trilaterationResult.x * 0.7 + fingerprintResult.x * 0.3),
        y: (trilaterationResult.y * 0.7 + fingerprintResult.y * 0.3),
        z: 1.5, // Altura fija del usuario
      );
    }

    return trilaterationResult ?? fingerprintResult;
  }

  // Encontrar pinturas cercanas
  List<Painting> getNearbyPaintings(Point3D position, {double radius = 1.0}) {
    return _paintings.where((painting) {
      return painting.isNearby(
        position.x,
        position.y,
        position.z,
        radius: radius,
      );
    }).toList();
  }
}
