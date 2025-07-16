import '../../models/point3d.dart';

class KalmanFilter3D {
  Point3D? _lastEstimate;
  double _processNoise = 0.1;
  double _measurementNoise = 0.5;
  double _errorCovariance = 1.0;

  Point3D update(Point3D measurement) {
    if (_lastEstimate == null) {
      _lastEstimate = measurement;
      _errorCovariance = 1.0;
      return measurement;
    }

    // Predicción
    final predictedEstimate = _lastEstimate!;
    final predictedErrorCovariance = _errorCovariance + _processNoise;

    // Actualización
    final kalmanGain =
        predictedErrorCovariance /
        (predictedErrorCovariance + _measurementNoise);

    final newEstimate = Point3D(
      x:
          predictedEstimate.x +
          kalmanGain * (measurement.x - predictedEstimate.x),
      y:
          predictedEstimate.y +
          kalmanGain * (measurement.y - predictedEstimate.y),
      z:
          predictedEstimate.z +
          kalmanGain * (measurement.z - predictedEstimate.z),
    );

    _errorCovariance = (1 - kalmanGain) * predictedErrorCovariance;
    _lastEstimate = newEstimate;

    return newEstimate;
  }

  void reset() {
    _lastEstimate = null;
    _errorCovariance = 1.0;
  }
}
