import 'dart:math';

class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D({required this.x, required this.y, required this.z});

  // Calculate distance between two 3D points
  double distanceTo(Point3D other) {
    return sqrt(
      pow(x - other.x, 2) + pow(y - other.y, 2) + pow(z - other.z, 2),
    );
  }

  // Check if this point is within a certain radius of another point
  bool isNearby(Point3D other, {double radius = 1.0}) {
    return distanceTo(other) <= radius;
  }

  // Create a copy with modified values
  Point3D copyWith({double? x, double? y, double? z}) {
    return Point3D(x: x ?? this.x, y: y ?? this.y, z: z ?? this.z);
  }

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {'x': x, 'y': y, 'z': z};
  }

  // Create from map
  factory Point3D.fromMap(Map<String, dynamic> map) {
    return Point3D(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'Point3D(x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)}, z: ${z.toStringAsFixed(3)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Point3D && other.x == x && other.y == y && other.z == z;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}
