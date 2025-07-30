import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:firebase_database/firebase_database.dart';

class BluetoothSensorScreen extends StatefulWidget {
  @override
  State<BluetoothSensorScreen> createState() => _BluetoothSensorScreenState();
}

class _BluetoothSensorScreenState extends State<BluetoothSensorScreen> {
  BluetoothConnection? connection;
  String status = 'Desconectado';
  String? distanciaRecibida;

  final database = FirebaseDatabase.instance.ref();

  void _connectToSensor() async {
    try {
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();

      final sensor = bondedDevices.firstWhere(
        (d) => d.name == 'ESP32_SENSOR',
        orElse: () => throw Exception('ESP32_SENSOR no emparejado.'),
      );

      connection = await BluetoothConnection.toAddress(sensor.address);
      setState(() => status = 'Conectado a ${sensor.name}');

      connection!.input!.listen((data) {
        final valor = String.fromCharCodes(data).trim();

        if (int.tryParse(valor) != null) {
          setState(() => distanciaRecibida = valor);
          print('📥 Distancia: $valor cm');

          // ✅ Subir a Firebase
          database.child('medico/oxigeno/distancia').set(int.parse(valor));
        }
      });
    } catch (e) {
      setState(() => status = 'Error: $e');
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Sensor')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Estado: $status'),
            const SizedBox(height: 20),
            if (distanciaRecibida != null)
              Text('Distancia recibida: $distanciaRecibida cm', style: const TextStyle(fontSize: 22)),
            const Spacer(),
            ElevatedButton(
              onPressed: _connectToSensor,
              child: const Text('Conectar al ESP32'),
            ),
          ],
        ),
      ),
    );
  }
}