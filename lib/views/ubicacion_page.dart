import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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

    _subscription = FlutterBluePlus.scanResults.listen((results) {
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
      setState(() {});
    });

    await Future.delayed(Duration(seconds: 5));
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
      appBar: AppBar(title: Text('Ubicación - iBeacon')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? null : escanearDispositivos,
            child: Text(isScanning ? 'Escaneando...' : 'Escanear iBeacon'),
          ),
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
