import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';

class UbicacionPage extends StatefulWidget {
  const UbicacionPage({super.key});

  @override
  _UbicacionPageState createState() => _UbicacionPageState();
}

class _UbicacionPageState extends State<UbicacionPage> {
  final String tuUUID = "b9407f30-f5f8-466e-aff9-25556b57fe6d";
  bool isScanning = false;
  Map<DeviceIdentifier, List<int>> historialRssi = {};
  Map<DeviceIdentifier, int> rssiFiltrado = {};
  StreamSubscription? _subscription;

  final Map<DeviceIdentifier, Offset> coordenadasBeacons = {
    DeviceIdentifier("E0:00:00:00:00:01"): const Offset(0.0, 0.0),
    DeviceIdentifier("E0:00:00:00:00:02"): const Offset(4.0, 0.0),
    DeviceIdentifier("E0:00:00:00:00:03"): const Offset(2.0, 3.0),
  };

  Offset? posicionEstimada;

  @override
  void initState() {
    super.initState();
    solicitarPermisos();
  }

  Future<void> solicitarPermisos() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  void escanearDispositivos() async {
    historialRssi.clear();
    rssiFiltrado.clear();
    setState(() => isScanning = true);

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    _subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (var d in results) {
        final data = d.advertisementData.manufacturerData;
        if (data.isNotEmpty) {
          final raw = data.values.first;
          if (raw.length >= 23) {
            final uuidBytes = raw.sublist(2, 18);
            final uuidStr = _bytesToUuid(uuidBytes);
            if (uuidStr.toLowerCase() == tuUUID.toLowerCase()) {
              actualizarRssiFiltrado(d.device.id, d.rssi);
            }
          }
        }
      }

      if (rssiFiltrado.length >= 3) {
        final beaconsUsados = rssiFiltrado.entries.take(3).toList();
        final posiciones = <Offset>[];
        final distancias = <double>[];

        for (var entry in beaconsUsados) {
          final posicion = coordenadasBeacons[entry.key];
          if (posicion != null) {
            posiciones.add(posicion);
            distancias.add(calcularDistancia(entry.value));
          }
        }

        if (posiciones.length == 3) {
          final pos = trilateracion(
            posiciones[0], distancias[0],
            posiciones[1], distancias[1],
            posiciones[2], distancias[2],
          );

          setState(() => posicionEstimada = pos);
          enviarUbicacionAFirebase(pos.dx, pos.dy);
        }
      }

      setState(() {});
    });

    await Future.delayed(const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();
    _subscription?.cancel();
    setState(() => isScanning = false);
  }

  void actualizarRssiFiltrado(DeviceIdentifier id, int nuevoRssi) {
    const ventana = 5;
    final lista = historialRssi.putIfAbsent(id, () => []);
    lista.add(nuevoRssi);
    if (lista.length > ventana) lista.removeAt(0);
    final promedio = lista.reduce((a, b) => a + b) ~/ lista.length;
    rssiFiltrado[id] = promedio;
  }

  double calcularDistancia(int rssi, {int txPower = -59}) {
  return pow(10, (txPower - rssi) / 20).toDouble();
}


  Offset trilateracion(
    Offset p1, double d1,
    Offset p2, double d2,
    Offset p3, double d3,
  ) {
    final A = 2 * (p2.dx - p1.dx);
    final B = 2 * (p2.dy - p1.dy);
    final C = pow(d1, 2) - pow(d2, 2) - pow(p1.dx, 2) + pow(p2.dx, 2) - pow(p1.dy, 2) + pow(p2.dy, 2);
    final D = 2 * (p3.dx - p2.dx);
    final E = 2 * (p3.dy - p2.dy);
    final F = pow(d2, 2) - pow(d3, 2) - pow(p2.dx, 2) + pow(p3.dx, 2) - pow(p2.dy, 2) + pow(p3.dy, 2);

    final x = (C * E - F * B) / (E * A - B * D);
    final y = (C * D - A * F) / (B * D - A * E);

    return Offset(x.toDouble(), y.toDouble());
  }

  void enviarUbicacionAFirebase(double x, double y) {
    FirebaseDatabase.instance.ref('ubicaciones/usuario1').set({
      'x': x,
      'y': y,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  String _bytesToUuid(List<int> bytes) {
    String hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación - iBeacon')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? null : escanearDispositivos,
            child: Text(isScanning ? 'Escaneando...' : 'Escanear iBeacons'),
          ),
          const SizedBox(height: 20),
          if (posicionEstimada != null)
            Text('Posición estimada: x=${posicionEstimada!.dx.toStringAsFixed(2)}, y=${posicionEstimada!.dy.toStringAsFixed(2)}'),
          Expanded(
            child: ListView(
              children: rssiFiltrado.entries.map((entry) {
                return ListTile(
                  title: Text('Beacon ${entry.key}'),
                  subtitle: Text('RSSI filtrado: ${entry.value} dBm'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
