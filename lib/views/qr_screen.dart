import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  bool _isScanning = false;
  String _status = "Presiona el botón para comenzar";
  List<Beacon> _beacons = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<RangingResult>? _rangingStream;

  @override
  void initState() {
    super.initState();
    _initBeacon();
  }

  Future<void> _initBeacon() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();

    try {
      await flutterBeacon.initializeScanning;
      setState(() => _status = "SDK inicializado correctamente");
    } catch (e) {
      setState(() => _status = "Error al inicializar: $e");
    }
  }

  void _toggleScanning() async {
    if (_isScanning) {
      await _rangingStream?.cancel(); // Detiene el escaneo
      setState(() {
        _isScanning = false;
        _status = "Escaneo detenido";
      });
    } else {
      final regions = [Region(identifier: 'mi-region')];

      _rangingStream = flutterBeacon.ranging(regions).listen((result) {
        if (result.beacons.isNotEmpty) {
          setState(() {
            _beacons = result.beacons;
            _status = "Beacons detectados: ${_beacons.length}";
          });
          _saveToFirestore(result.beacons);
        }
      });

      setState(() {
        _isScanning = true;
        _status = "Escaneando beacons...";
      });
    }
  }

  Future<void> _saveToFirestore(List<Beacon> beacons) async {
    try {
      final data = {
        'timestamp': FieldValue.serverTimestamp(),
        'location': 'Ubicación actual', // Personaliza según tu app
        'beacons': beacons
            .map(
              (b) => {
                'uuid': b.proximityUUID,
                'major': b.major,
                'minor': b.minor,
                'rssi': b.rssi,
                'distance': b.accuracy,
              },
            )
            .toList(),
      };

      await _firestore.collection('fingerprints').add(data);
    } catch (e) {
      print("Error guardando en Firestore: $e");
    }
  }

  @override
  void dispose() {
    _rangingStream?.cancel(); // Cancela escaneo al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/beacon.png', height: 150),
            const SizedBox(height: 20),
            const Text(
              "Utiliza nuestro sistema de localización",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleScanning,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84030C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: Text(
                _isScanning ? "DETENER ESCANEO" : "DETERMINAR UBICACIÓN",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(_status),
            const SizedBox(height: 20),
            if (_beacons.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _beacons.length,
                  itemBuilder: (context, index) {
                    final beacon = _beacons[index];
                    return ListTile(
                      title: Text("Beacon ${beacon.major}:${beacon.minor}"),
                      subtitle: Text(
                        "RSSI: ${beacon.rssi}dB\nDistancia: ${beacon.accuracy.toStringAsFixed(2)}m",
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
