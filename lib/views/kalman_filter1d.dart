class KalmanFilter1D {
  double? _lastEstimate;
  double _processNoise = 0.2;
  double _measurementNoise = 0.5;
  double _errorCovariance = 1.0;

  double update(double measurement) {
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

    final newEstimate =
        predictedEstimate + kalmanGain * (measurement - predictedEstimate);

    _errorCovariance = (1 - kalmanGain) * predictedErrorCovariance;
    _lastEstimate = newEstimate;

    return newEstimate;
  }

  void reset() {
    _lastEstimate = null;
    _errorCovariance = 1.0;
  }
}
